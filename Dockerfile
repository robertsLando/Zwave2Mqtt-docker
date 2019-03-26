# ----------------
# STEP 1:
# build files
FROM alpine:latest AS build

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
      libusb-dev \
      linux-headers \
      wget \
      tar  \
      make \
      openssl

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

RUN mkdir -p /usr/local/etc/openzwave
RUN apk update && apk add --no-cache \
    libstdc++  \
    libgcc \
    libusb \
    eudev 

COPY --from=build /root/open-zwave/config/ /usr/local/etc/openzwave/ 
COPY --from=build /lib/openzwave/ /lib/

# Set enviroment
ENV LD_LIBRARY_PATH /lib

WORKDIR /usr/src/app

COPY pkg/ ./

EXPOSE 8091

CMD ["/usr/src/app/zwave2mqtt"]