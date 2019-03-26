#!/bin/bash

APP="zwave2mqtt"
PKG_FOLDER="pkg"

echo "## Clone and build application $APP"
cd /root
git clone https://github.com/robertsLando/Zwave2Mqtt.git
cd Zwave2Mqtt
npm install
npm run build

echo "Destination folder: $PKG_FOLDER"
echo "App-name: $APP"

VERSION=$(node -p "require('./package.json').version")
echo "Version: $VERSION"

echo "## Creating application package in $PKG_FOLDER folder"
/usr/local/bin/pkg package.json -t node8-alpine-x64 --out-path $PKG_FOLDER

echo "## Check for .node files to include in executable folder"
declare TO_INCLUDE=($(find ./node_modules/ -type f -name "*.node"))

TOTAL_INCLUDE=${#TO_INCLUDE[@]}

echo "## Found $TOTAL_INCLUDE files to include"

i=0

while [ "$i" -lt "$TOTAL_INCLUDE" ]
do
  IFS='/' path=(${TO_INCLUDE[$i]})
  file=${path[-1]}
  echo "## Copying $file to $PKG_FOLDER folder"
  cp "${TO_INCLUDE[$i]}" "./$PKG_FOLDER"
  let "i = $i + 1"
done

echo "## Create folders needed"
cd $PKG_FOLDER
mkdir store -p