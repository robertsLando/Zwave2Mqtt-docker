#!/bin/bash

APP="zwave2mqtt"
PKG_FOLDER="pkg"

echo "## Clone and build application $APP"
cd /root
git clone https://github.com/robertsLando/Zwave2Mqtt.git
cd Zwave2Mqtt
git checkout ${Z2M_VERSION}
npm install
npm run build

echo "Destination folder: $PKG_FOLDER"
echo "App-name: $APP"

VERSION=$(node -p "require('./package.json').version")
echo "Version: $VERSION"

echo "## Creating application package in $PKG_FOLDER folder"

build_uname_arch=$(uname -m | tr '[:upper:]' '[:lower:]' )

echo Build Arch: ${build_uname_arch}

case ${build_uname_arch} in
  x86_64  ) pkg_arch=x64 ;;
  aarch64 ) pkg_arch=arm64 
            wget https://github.com/robertsLando/pkg-binaries/raw/master/arm64/fetched-v8.11.3-linux-arm64 -O fetched-v8.11.3-linux-arm64
            mv fetched-v8.11.3-linux-arm64 ~/.pkg-cache/
            ;;
  arm*    ) pkg_arch=armv7
            wget https://github.com/robertsLando/pkg-binaries/raw/master/arm32/fetched-v8.11.3-linux-armv7 -O fetched-v8.11.3-linux-armv7
            mv fetched-v8.11.3-linux-armv7 ~/.pkg-cache/
            fix=--public-packages=*
            ;;
  *)
    echo ERROR: Sorry, unsupported architecture ${build_uname_arch};
    exit 1
    ;;
esac

# Node version MUST be the same of the container
pkg package.json -t node8-alpine-${pkg_arch} --out-path $PKG_FOLDER ${fix}

cp ./node_modules/@serialport/bindings/build/Release/bindings.node $PKG_FOLDER
cp ./node_modules/openzwave-shared/build/Release/openzwave_shared.node $PKG_FOLDER

echo "## Create folders needed"
cd $PKG_FOLDER
mkdir store -p