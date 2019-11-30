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

FROM scratch:latest
COPY --from=node_builder /clash_ui /clash_ui