# ----------------
# STEP 1:
# https://lobradov.github.io/Building-docker-multiarch-images/
# Build Openzwave and Zwave2Mqtt pkg
# All result files will be put in /dist folder
FROM node:erbium-alpine AS build

ARG Z2M_GIT_SHA1=ba709b0a6b52b3d2c3a84072d90b2b654626de8e
# Latest stable 1.4
ARG OPENZWAVE_GIT_SHA1=449f89f063effb048f5dd6348d509a6c54fd942d

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
      python2-dev~=2.7 \
      bash \
      libusb-dev \
      linux-headers \
      wget \
      tar  \
      openssl \
      make

# Move binaries in /dist/lib and devices db on /dist/db
RUN cd /root \
    && wget https://github.com/OpenZWave/open-zwave/archive/${OPENZWAVE_GIT_SHA1}.tar.gz -O - \
    | tar -zxf - \
    && cd open-zwave-${OPENZWAVE_GIT_SHA1} && make && make install \
    && mkdir -p /dist/lib \
    && mv libopenzwave.so* /dist/lib/ \
    && mkdir -p /dist/db \
    && mv config/* /dist/db

RUN cd /root \
    && wget https://github.com/OpenZWave/Zwave2Mqtt/archive/${Z2M_GIT_SHA1}.tar.gz -O - \
    | tar -zxf - \
    && cd Zwave2Mqtt-${Z2M_GIT_SHA1} \
    && npm config set unsafe-perm true \
    && npm install \
    && npm run build \
    && mkdir -p /dist/app \
    && mv /root/Zwave2Mqtt-${Z2M_GIT_SHA1}/* /dist/app

# ----------------
# STEP 2:
FROM node:erbium-alpine

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
