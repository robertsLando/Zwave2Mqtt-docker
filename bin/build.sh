#!/bin/bash
set -e

# Run this to build, tag and create fat-manifest for your images
# Inspired to: https://lobradov.github.io/Building-docker-multiarch-images/

# Register quemu headers
sudo docker run --rm --privileged multiarch/qemu-user-static:register

wget https://raw.githubusercontent.com/OpenZWave/Zwave2Mqtt/master/package.json
LATEST=$(node -p "require('./package.json').version")
rm package.json

# Build info
REPO="robertslando"
IMAGE_NAME="zwave2mqtt"
VERSIONS="$LATEST-dev $LATEST"
TARGET_ARCHES="arm32v6 arm32v7 arm64v8 amd64"

# $1: Manifest version $2: Image version $3: arch_images
createManifest() {

  # Update latest manifest
  if [ -d ~/.docker/manifests/docker.io_${REPO}_${IMAGE_NAME}-$1 ]; then
      rm -rf ~/.docker/manifests/docker.io_${REPO}_${IMAGE_NAME}-$1
  fi

  docker manifest create --amend ${REPO}/${IMAGE_NAME}:$1 $3

  for docker_arch in ${TARGET_ARCHES}; do
    case ${docker_arch} in
      amd64       ) annotate_flags="" ;;
      arm32v6 ) annotate_flags="--os linux --arch arm --variant armv6" ;;
      arm32v7 ) annotate_flags="--os linux --arch arm --variant armv7" ;;
      arm64v8 ) annotate_flags="--os linux --arch arm64 --variant armv8" ;;
    esac
    echo INFO: Annotating arch: ${docker_arch} with \"${annotate_flags}\"
    docker manifest annotate ${REPO}/${IMAGE_NAME}:$1 ${REPO}/${IMAGE_NAME}:${docker_arch}-$2 ${annotate_flags}
  done

  echo INFO: Pushing ${REPO}/${IMAGE_NAME}:$1
  docker manifest push ${REPO}/${IMAGE_NAME}:$1
}

cd ..

for IMAGE_VERSION in ${VERSIONS}; do

  echo INFO: Building $IMAGE_VERSION version

  DOCKER_FILE=""
  arch_images=""

  if [[ ${IMAGE_VERSION} == $LATEST ]]; then
    DOCKER_FILE="Dockerfile.latest"
    MANIFEST_VERSION="latest"
  else
    DOCKER_FILE="Dockerfile.dev"
    MANIFEST_VERSION="latest-dev"
  fi

  for docker_arch in ${TARGET_ARCHES}; do
      echo INFO: Creating Dockerfile for ${docker_arch}
      cp $DOCKER_FILE.cross $DOCKER_FILE.${docker_arch}
      case ${docker_arch} in
          amd64   ) qemu="x86_64" build_arch="amd64";;
          arm32v6 ) qemu="arm" build_arch="arm32v6";;
          arm32v7 ) qemu="arm" build_arch="arm32v6";;
          arm64v8     ) qemu="aarch64" build_arch="arm64v8";;
          *)
          echo ERROR: Unknown target arch.
          exit 1
      esac

      sed -i "s|__BUILD_ARCH__|${build_arch}|g" $DOCKER_FILE.${docker_arch}
      sed -i "s|__QEMU__|${qemu}|g" $DOCKER_FILE.${docker_arch}
      sed -i "s|__DOCKER_ARCH__|${docker_arch}|g" $DOCKER_FILE.${docker_arch}

      if [[ ${docker_arch} == "amd64" ]]; then
        sed -i "/__CROSS_/d" $DOCKER_FILE.${docker_arch}
      else
        sed -i "s/__CROSS_//g" $DOCKER_FILE.${docker_arch}
      fi

      echo INFO: Building of ${REPO}/${IMAGE_NAME}:${docker_arch}-$IMAGE_VERSION
      docker build -f $DOCKER_FILE.${docker_arch} -t ${REPO}/${IMAGE_NAME}:${docker_arch}-$IMAGE_VERSION .

      echo INFO: Successfully built ${REPO}/${IMAGE_NAME}:${docker_arch}-$IMAGE_VERSION
      echo INFO: Pushing to ${REPO}/${IMAGE_NAME}

      docker push ${REPO}/${IMAGE_NAME}:${docker_arch}-$IMAGE_VERSION

      arch_images="${arch_images} ${REPO}/${IMAGE_NAME}:${docker_arch}-${IMAGE_VERSION}"
      rm $DOCKER_FILE.${docker_arch}
  done

  echo INFO: Creating fat manifest

  createManifest $IMAGE_VERSION $IMAGE_VERSION "$arch_images" 

  # Update latest and latest-dev tag to point to latest versions
  createManifest $MANIFEST_VERSION $IMAGE_VERSION "$arch_images"

done
