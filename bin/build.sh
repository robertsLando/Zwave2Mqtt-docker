#!/bin/bash
set -e

# Run this to build, tag and create fat-manifest for your images
# Inspired to: https://lobradov.github.io/Building-docker-multiarch-images/

# Register quemu headers
sudo docker run --rm --privileged multiarch/qemu-user-static:register

# Build info
REPO="robertslando"
IMAGE_NAME="zwave2mqtt"
IMAGE_VERSION="latest"
TARGET_ARCHES="amd64 arm32v6 arm32v7 arm64v8"

cd ..

for docker_arch in ${TARGET_ARCHES}; do
    echo INFO: Creating Dockerfile for ${docker_arch}
    cp Dockerfile.cross Dockerfile.${docker_arch}
    case ${docker_arch} in
        amd64   ) qemu_arch="x86_64" build_arch="amd64";;
        arm32v6 ) qemu="arm" build_arch="arm32v6";;
        arm32v7 ) qemu="arm" build_arch="arm32v6";;
        arm64v8     ) qemu="aarch64" build_arch="arm64v8";;
        *)
        echo ERROR: Unknown target arch.
        exit 1
    esac

    sed -i "s|__BUILD_ARCH__|${build_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__QEMU__|${qemu}|g" Dockerfile.${docker_arch}
    sed -i "s|__DOCKER_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}

    if [[ ${docker_arch} == "amd64" ]]; then
      sed -i "/__CROSS_/d" Dockerfile.${docker_arch}
    else
      sed -i "s/__CROSS_//g" Dockerfile.${docker_arch}
    fi

    echo INFO: Building of ${REPO}/${IMAGE_NAME}:${docker_arch}-latest
    docker build -f Dockerfile.${docker_arch} -t ${REPO}/${IMAGE_NAME}:${docker_arch}-latest .

    echo INFO: Successfully built ${REPO}/${IMAGE_NAME}:${docker_arch}-latest
    echo INFO: Pushing to ${REPO}/${IMAGE_NAME}

    docker push ${REPO}/${IMAGE_NAME}:${docker_arch}-latest

    arch_images="${arch_images} ${REPO}/${IMAGE_NAME}:${docker_arch}-${IMAGE_VERSION}"
    rm Dockerfile.${docker_arch}
done

echo INFO: Creating fat manifest

# Remove previously created manifest data
if [ -d ~/.docker/manifests/docker.io_${REPO}_${IMAGE_NAME}-${IMAGE_VERSION} ]; then
  rm -rf ~/.docker/manifests/docker.io_${REPO}_${IMAGE_NAME}-${IMAGE_VERSION}
fi

# Include latest to manifest for amd64 that is builded with auto-builds in docker-hub
docker manifest create --amend ${REPO}/${IMAGE_NAME}:${IMAGE_VERSION} ${arch_images}

for docker_arch in ${TARGET_ARCHES}; do
  case ${docker_arch} in
    amd64       ) annotate_flags="" ;;
    arm32v6 ) annotate_flags="--os linux --arch arm --variant armv6" ;;
    arm32v7 ) annotate_flags="--os linux --arch arm --variant armv7" ;;
    arm64v8 ) annotate_flags="--os linux --arch arm64 --variant armv8" ;;
  esac
  echo INFO: Annotating arch: ${docker_arch} with \"${annotate_flags}\"
  docker manifest annotate ${REPO}/${IMAGE_NAME}:${IMAGE_VERSION} ${REPO}/${IMAGE_NAME}:${docker_arch}-${IMAGE_VERSION} ${annotate_flags}
done

echo INFO: Pushing ${REPO}/${IMAGE_NAME}:${IMAGE_VERSION}
docker manifest push ${REPO}/${IMAGE_NAME}:${IMAGE_VERSION}
