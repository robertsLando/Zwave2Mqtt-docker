# ----------------
# STEP 1:
# https://lobradov.github.io/Building-docker-multiarch-images/
# Build Openzwave and Zwave2Mqtt pkg
# All result files will be put in /dist folder
FROM node:carbon-alpine AS build

# Set the commit of Zwave2Mqtt to checkout when cloning the repo
ENV Z2M_VERSION=ba709b0a6b52b3d2c3a84072d90b2b654626de8e

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
      python2-dev~=2.7 \
      bash \
      libusb-dev \
      linux-headers \
      wget \
      tar  \
      openssl \
      make 

# Clone 1.4 branch and move binaries in /dist/lib and devices db on /dist/db
RUN cd /root \
    && git clone -b 1.4 https://github.com/OpenZWave/open-zwave.git \
    && cd open-zwave && make && make install \
    && mkdir -p /dist/lib \
    && mv libopenzwave.so* /dist/lib/ \
    && mkdir -p /dist/db \
    && mv config/* /dist/db

# Clone Zwave2Mqtt build pkg files and move them to /dist/pkg
RUN cd /root \
    && git clone https://github.com/OpenZWave/Zwave2Mqtt.git  \
    && cd Zwave2Mqtt \
    && git checkout ${Z2M_VERSION} \
    && npm config set unsafe-perm true \
    && npm install \
    && npm run build \
    && mkdir -p /dist/app \
    && mv /root/Zwave2Mqtt/* /dist/app

# Clean up
RUN rm -R /root/* && apk del .build-deps

# ----------------
# STEP 2:
FROM node:carbon-alpine

LABEL maintainer="robertsLando"

RUN apk update && apk add --no-cache \
    libstdc++  \
    libgcc \
    libusb \
    tzdata \
    eudev 

# Copy files from previous build stage
COPY --from=build /dist/lib/ /lib/
COPY --from=build /dist/db/ /usr/local/etc/openzwave/ 
COPY --from=build /dist/app/ /usr/src/app/

# Set enviroment
ENV LD_LIBRARY_PATH /lib

WORKDIR /usr/src/app

EXPOSE 8091

CMD ["node", "bin/www"]