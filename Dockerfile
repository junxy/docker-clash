# 1. build clash dashboard
FROM node as node_builder
# fix https://github.com/conda-forge/pygridgen-feedstock/issues/10#issuecomment-365914605
RUN apt-get update && apt-get install -y libgl1-mesa-glx
WORKDIR /clash-dashboard-src
RUN git clone https://github.com/Dreamacro/clash-dashboard.git --depth=1 /clash-dashboard-src
RUN npm install
RUN npm run build
RUN mv ./dist /clash_ui
# debug
#https://serverfault.com/questions/476485/do-some-debian-builds-not-have-lsb-release
# RUN cat /etc/os-release
# RUN ls -al /clash_ui

# 2. build clash
# https://github.com/Dreamacro/clash/blob/master/Dockerfile
FROM golang:alpine as go_builder
RUN apk add --no-cache make git && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz -O /tmp/GeoLite2-Country.tar.gz && \
    tar zxvf /tmp/GeoLite2-Country.tar.gz -C /tmp && \
    mv /tmp/GeoLite2-Country_*/GeoLite2-Country.mmdb /Country.mmdb
WORKDIR /clash-src
# COPY . /clash-src
RUN git clone https://github.com/Dreamacro/clash.git -b dev /clash-src
# RUN ls -al /clash-src
# add containerd flag
RUN sed -i 's/$(VERSION)/$(VERSION)-containerd/' Makefile
RUN head -n 10 Makefile

RUN go mod download && \
    make linux-amd64 && \
    mv ./bin/clash-linux-amd64 /clash
RUN /clash -v

FROM alpine:latest
# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
RUN apk add --no-cache tzdata ca-certificates \
    # && ls /usr/share/zoneinfo/Asia \
    && cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime \
    && echo "Asia/Taipei" > /etc/timezone \
    && apk del tzdata

COPY --from=go_builder /Country.mmdb /root/.config/clash/
COPY --from=go_builder /clash /
COPY --from=node_builder /clash_ui /clash_ui

# RUN ls -al /root/.config/clash/; ls -al /clash_ui
# VOLUME [ "/root/.config/clash/" ]

ENTRYPOINT ["/clash","-d","/root/.config/clash/"]
