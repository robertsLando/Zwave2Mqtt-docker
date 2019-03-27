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
# Node version MUST be the same of the container
pkg package.json -t node8-alpine-x64 --out-path $PKG_FOLDER

cp ./node_modules/@serialport/bindings/build/Release/bindings.node $PKG_FOLDER
cp ./node_modules/openzwave-shared/build/Release/openzwave_shared.node $PKG_FOLDER

echo "## Create folders needed"
cd $PKG_FOLDER
mkdir store -p