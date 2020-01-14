#!/bin/bash -e

APP="Zwave2Mqtt"
PKG_FOLDER="pkg"

echo "Destination folder: $PKG_FOLDER"
echo "App-name: $APP"

cd /root/$APP

VERSION=$(node -p "require('./package.json').version")
echo "Version: $VERSION"

echo "## Creating application package in $PKG_FOLDER folder"

build_uname_arch=$(uname -m | tr '[:upper:]' '[:lower:]' )

echo Build Arch: ${build_uname_arch}

mkdir -p ~/.pkg-cache/v2.5

case ${build_uname_arch} in
  x86_64  ) pkg_arch=x64 ;;
  aarch64 ) pkg_arch=arm64
            wget https://github.com/robertsLando/pkg-binaries/raw/master/arm64/fetched-v8.11.3-alpine-arm64 -O fetched-v8.11.3-alpine-arm64
            mv fetched-v8.11.3-alpine-arm64 ~/.pkg-cache/v2.5
            ;;
  arm*    ) pkg_arch=armv7
            wget https://github.com/robertsLando/pkg-binaries/raw/master/arm32/fetched-v8.11.3-alpine-armv7 -O fetched-v8.11.3-alpine-armv7
            mv fetched-v8.11.3-alpine-armv7 ~/.pkg-cache/v2.5
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
