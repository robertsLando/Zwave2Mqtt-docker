FROM alpine:latest

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

# Build binaries
RUN cd /root \
    && wget http://old.openzwave.com/downloads/openzwave-1.4.1.tar.gz \
    && tar zxvf openzwave-*.gz \
    && cd openzwave-* && make \
    && cp libopenzwave.so* /lib

# Get last config DB from main repo
RUN cd /root \
    && git clone https://github.com/OpenZWave/open-zwave.git \
    && cd open-zwave \
    && mkdir -p /usr/local/etc/openzwave \
    && cp -R config/* /usr/local/etc/openzwave/ 
    
# Clean up files
RUN rm -R /root/*

# Remove build dependencies
RUN apk del .build-deps

# Set enviroment
ENV LD_LIBRARY_PATH /lib

WORKDIR /usr/src/app

COPY pkg/ ./

EXPOSE 8091

CMD ["/usr/src/app/zwave2mqtt"]