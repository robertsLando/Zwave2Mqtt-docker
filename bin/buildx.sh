wget -O package.json https://raw.githubusercontent.com/OpenZWave/Zwave2Mqtt/master/package.json
VERSION=$(node -p "require('./package.json').version")
rm package.json

docker buildx build \
      --platform linux/arm64/v8,linux/amd64,linux/arm/v6,linux/arm/v7,linux/386 \
      --file ../Dockerfile \
      --push \
      -t robertslando/zwave2mqtt:latest -t "robertslando/zwave2mqtt:$VERSION" \
      ../