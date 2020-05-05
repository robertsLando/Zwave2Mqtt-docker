wget -O package.json https://raw.githubusercontent.com/OpenZWave/Zwave2Mqtt/master/package.json
VERSION=$(node -p "require('./package.json').version")
rm package.json

DOCKER_TAGS=($(wget -q https://registry.hub.docker.com/v1/repositories/robertslando/zwave2mqtt/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}'))

# always build dev tag
TAGS="-t robertslando/zwave2mqtt:dev"

# check if there is an image with this version, if not create new tags latest and $VERSION
if [[ " ${DOCKER_TAGS[@]} " =~ " ${VERSION} " ]]; then 
    TAGS="$TAGS -t robertslando/zwave2mqtt:latest -t robertslando/zwave2mqtt:$VERSION" # make a new release
fi

docker buildx build \
      --platform linux/arm64/v8,linux/amd64,linux/arm/v6,linux/arm/v7,linux/386 \
      --file ../Dockerfile \
      --push \
      $TAGS \
      ../