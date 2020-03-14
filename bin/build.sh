#!/bin/bash
set -e

# Run this to build, tag and create fat-manifest for your images
# Inspired to: https://lobradov.github.io/Building-docker-multiarch-images/

# Register quemu headers
sudo docker run --rm --privileged multiarch/qemu-user-static:register

Z2M_GIT_SHA1=ccd8650471a3fd68595702d7f3e0b65c44072602
OPENZWAVE_16_GIT_SHA1=cf0775a91c12f4aba6d93cd974d0e45bb108dd19
OPENZWAVE_14_GIT_SHA1=449f89f063effb048f5dd6348d509a6c54fd942d

wget -O package.json https://raw.githubusercontent.com/OpenZWave/Zwave2Mqtt/${Z2M_GIT_SHA1}/package.json
LATEST=$(node -p "require('./package.json').version")
rm package.json

# Build info
REPO="robertslando"
IMAGE_NAME="zwave2mqtt"
VERSIONS="$LATEST"
TARGET_ARCHES="arm32v6 arm32v7 arm64v8 arm64-v8 amd64"

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
      arm64-v8 ) annotate_flags="--os linux --arch arm64 --variant v8" ;;
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

  DOCKER_FILE="Dockerfile"
  arch_images=""

  MANIFEST_VERSION="latest"
  OPENZWAVE_GIT_SHA1=${OPENZWAVE_16_GIT_SHA1}

  # if [[ ${IMAGE_VERSION} == $LATEST ]]; then
  #   MANIFEST_VERSION="latest"
  #   OPENZWAVE_GIT_SHA1=${OPENZWAVE_14_GIT_SHA1}
  # else
  #   MANIFEST_VERSION="latest-dev"
  #   OPENZWAVE_GIT_SHA1=${OPENZWAVE_16_GIT_SHA1}
  # fi

  for docker_arch in ${TARGET_ARCHES}; do
      echo INFO: Creating Dockerfile for ${docker_arch}
      cp $DOCKER_FILE.cross $DOCKER_FILE.${docker_arch}
      case ${docker_arch} in
          amd64   ) qemu="x86_64" build_arch="amd64";;
          arm32v6 ) qemu="arm" build_arch="arm32v6";;
          arm32v7 ) qemu="arm" build_arch="arm32v6";;
          arm64v8     ) qemu="aarch64" build_arch="arm64v8";;
          arm64-v8 ) qemu="aarch64" build_arch="arm64v8";;
          *)
          echo ERROR: Unknown target arch.
          exit 1
      esac

      sed -e "s|__BUILD_ARCH__|${build_arch}|g" \
        -e "s|__QEMU__|${qemu}|g" \
        -e "s|__DOCKER_ARCH__|${docker_arch}|g" \
        -i $DOCKER_FILE.${docker_arch}

      if [[ "${qemu}" == "$(uname -m)" ]]; then
        # Same as local architecture; no need for a cross build
        sed -i "/__CROSS_/d" $DOCKER_FILE.${docker_arch}
      else
        sed -i "s/__CROSS_//g" $DOCKER_FILE.${docker_arch}
      fi

      echo INFO: Building of ${REPO}/${IMAGE_NAME}:${docker_arch}-$IMAGE_VERSION
      docker build -f $DOCKER_FILE.${docker_arch} \
        --build-arg=Z2M_GIT_SHA1=${Z2M_GIT_SHA1} \
        --build-arg=OPENZWAVE_GIT_SHA1=${OPENZWAVE_GIT_SHA1} \
        -t ${REPO}/${IMAGE_NAME}:${docker_arch}-$IMAGE_VERSION .

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
