FROM debian:bookworm AS build

RUN set -e; export DEBIAN_FRONTEND=noninteractive; \
    apt update; apt install -y git build-essential libssl-dev

WORKDIR /scs
RUN set -e; mkdir /scs/mqttclients; cd /scs/mqttclients; \
    git clone https://github.com/janderholm/paho.mqtt.c.git; \
    cd paho.mqtt.c; make; make install

RUN set -e; mkdir /scs/async; cd /scs/async; \
    git clone https://github.com/papergion/easysocket.git; \
    cd easysocket; mv MakeHelper ..

COPY scs-patches.patch /scs/
RUN set -e; cd /scs/async; \
    git clone https://github.com/papergion/raspy_scsgate_cpp.git; \
    cd raspy_scsgate_cpp; \
    sed 's/-Werror/-Wall/g' -i Makefile; \
    patch -p1 < /scs/scs-patches.patch; \
    make

FROM debian:bookworm
COPY --from=build /usr/local/lib/* /usr/local/lib/
COPY --from=build /scs/async/raspy_scsgate_cpp/bin/release/* /usr/local/bin/
ENV LD_LIBRARY_PATH=/usr/local/lib
WORKDIR /app
