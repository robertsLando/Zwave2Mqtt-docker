# ----------------
# STEP 1:
# Build Openzwave and Zwave2Mqtt pkg
FROM node:8.15.1-alpine AS build

# Install required dependencies
RUN apk update && apk --no-cache add \
      gnutls \
      gnutls-dev \
      libusb \
      eudev \
      # Install build dependencies
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

# Build binaries and move them to /lib/openzwave
RUN cd /root \
    && wget http://old.openzwave.com/downloads/openzwave-1.4.1.tar.gz \
    && tar zxvf openzwave-*.gz \
    && cd openzwave-* && make && make install \
    && mkdir -p /dist/lib \
    && mv libopenzwave.so* /dist/lib/

# Clone repo and build pkg files
COPY bin/package.sh /root/package.sh
RUN npm install -g pkg \
    && cd /root && chmod +x package.sh && ./package.sh \
    && mkdir -p /dist/pkg \
    && mv /root/Zwave2Mqtt/pkg/* /dist/pkg

# Get last config DB from main repo
RUN cd /root \
    && git clone https://github.com/OpenZWave/open-zwave.git \
    && cd open-zwave \
    && mkdir -p /dist/db \
    && mv config/* /dist/db

# Clean up
RUN rm -R /root/* && apk del .build-deps

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

COPY --from=build /dist/lib/ /lib/
COPY --from=build /dist/db/ /usr/local/etc/openzwave/ 
COPY --from=build /dist/pkg /usr/src/app

# Set enviroment
ENV LD_LIBRARY_PATH /lib

WORKDIR /usr/src/app

EXPOSE 8091

CMD ["/usr/src/app/zwave2mqtt"]