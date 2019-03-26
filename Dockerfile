FROM node:alpine AS build

RUN apk update

# Install required build dependencies
RUN apk --no-cache add \
      gnutls \
      gnutls-dev \
      libusb \
      eudev \
    && apk --no-cache --virtual .build-deps add \
      coreutils \
      eudev-dev \
      build-base \
      git \
      python \
      bash \
      libusb-dev \
      linux-headers \
      wget \
      tar  \
      openssl \
      make 

RUN npm install -g pkg

# Clone repo and build pkg files
COPY bin/package.sh /root/package.sh
RUN cd /root && chmod +x package.sh
RUN [ "/bin/bash", "root/package.sh" ]

# Build binaries and move them to /lib/openzwave
RUN cd /root \
    && wget http://old.openzwave.com/downloads/openzwave-1.4.1.tar.gz \
    && tar zxvf openzwave-*.gz \
    && cd openzwave-* && make \
    && mkdir -p /lib/openzwave \
    && mv libopenzwave.so* /lib/openzwave

# Get last config DB from main repo
RUN cd /root \
    && git clone https://github.com/OpenZWave/open-zwave.git

# ----------------
# STEP 2:
# run with alpine
FROM alpine:latest

LABEL maintainer="robertsLando"

RUN apk update && apk add --no-cache \
    libstdc++  \
    libgcc \
    libusb \
    eudev 

COPY --from=build /root/open-zwave/config/ /usr/local/etc/openzwave/ 
COPY --from=build /lib/openzwave/ /lib/
COPY --from=build root/Zwave2Mqtt/pkg /usr/src/app

# Set enviroment
ENV LD_LIBRARY_PATH /lib

WORKDIR /usr/src/app

EXPOSE 8091

CMD ["/usr/src/app/zwave2mqtt"]