# Zwave2Mqtt-docker

[![Pulls](https://img.shields.io/docker/pulls/robertslando/zwave2mqtt.svg)](https://hub.docker.com/r/robertslando/zwave2mqtt)
[![Build](https://img.shields.io/docker/cloud/build/robertslando/zwave2mqtt.svg)](https://hub.docker.com/r/robertslando/zwave2mqtt)
[![Image size](https://images.microbadger.com/badges/image/robertslando/zwave2mqtt.svg)](https://hub.docker.com/r/robertslando/zwave2mqtt "Get your own image badge on microbadger.com")

Docker container for Zwave2Mqtt Gateway and Control Panel app using pkg

> **Image size acually is lower than 80MB**

```bash
daniel@daniel:~/Zwave2Mqtt-docker$ docker images
REPOSITORY                      TAG                 IMAGE ID            CREATED             SIZE
robertslando/zwave2mqtt         latest              043a0d327ad6        2 minutes ago       76.7MB
```

## Tags

Supported architectures are:

- `x86_64 amd64` Tag `:amd64-latest`
- `armv6`  Tag `:arm32v6-latest`
- `armv7`  Tag `:arm32v7-latest` (Raspberry PI)
- `arm64` Tag `:arm64v8-latest` (OrangePI NanoPI)

## Install

Here there are 3 different way to start the container and provide data persistence. In all of this solutions **remember to**:

1. Replace `/dev/ttyACM0` with your serial device
2. Add `-e TZ=Europe/Stockholm` to the `docker run` command to set the correct timezone in container

### Run using volumes

```bash
docker run --rm -it -p 8091:8091 --device=/dev/ttyACM0 --mount source=zwave2mqtt,target=/usr/src/app/store robertslando/zwave2mqtt:latest
```

### Run using local folder

Here we will store our data in the current path (`$(pwd)`) named `store`. You can choose the path and the directory name you prefer, a valid alternative (with linux) could be `/var/lib/zwave2mqtt`

```bash
mkdir store
docker run --rm -it -p 8091:8091 --device=/dev/ttyACM0 -v $(pwd)/store:/usr/src/app/store robertslando/zwave2mqtt:latest
```

### Run as a service

To run the app as a service you can use the `docker-compose.yml` file you find on [github repo](https://github.com/robertsLando/Zwave2Mqtt-docker/tree/master/compose/docker-compose.yml). Here is the content:

```yml
version: "3.7"
services:
  zwave2mqtt:
    container_name: zwave2mqtt
    image: robertslando/zwave2mqtt:latest
    restart: always
    tty: true
    stop_signal: SIGINT
    networks:
      - zwave
    devices:
      - "/dev/ttyACM0:/dev/ttyACM0"
    volumes:
      - ./store:/usr/src/app/store
    ports:
      - "8091:8091"
networks:
  zwave:
# volumes:
#   zwave2mqtt:
#     name: zwave2mqtt
```

Like the other solutions, remember to replace device `/dev/ttyACM0` with the path of your USB stick and choose the solution you prefer for data persistence.

### Upgrade from 1.0.0 to 1.1.0

In 1.0.0 version all application data where stored inside the volume. This could cause many problems expectially when upgrading. To prevent this, starting from version 1.1.0 all persistence data have been moved to application `store` folder. If you have all your data stored inside a volume `zwave2mqtt` this is how to backup them:

```bash
APP=$(docker run --rm -it -d --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest)
docker cp $APP:/usr/src/app ./
docker kill $APP
```

This will create a directory `app` with all app data inside. Move all files like `OZW_log.txt zwscene.xml zwcfg_<homehex>.xml` in `app/store` folder and use that folder as volume following [this](#run-using-local-folder) section

### ATTENTION

If you get the error `standard_init_linux.go:207: exec user process caused "exec format error"` probably it's because you previously installed a wrong architecture version of the package so in that case you must delete the existing volume that contains the old executable:

`docker volume rm zwave2mqtt`

Check files inside volume

```bash
docker run --rm -it --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest find /usr/src/app
```

Delete Volume

```bash
docker volume rm zwave2mqtt
```

## Custom builds

Docker images contains latest stable images of [zwave2mqtt](https://github.com/OpenZWave/Zwave2Mqtt) repo. If you want to keep your image updated with latest changes you can build it on your local machine. Just select a commit and replace existing [commit](https://github.com/OpenZWave/Zwave2Mqtt/commits/master) in Dockerfile [here](https://github.com/robertsLando/Zwave2Mqtt-docker/blob/master/Dockerfile#L9)

```bash
git clone git@github.com:robertsLando/Zwave2Mqtt-docker.git
cd Zwave2Mqtt-docker
sed -i "s|<actualCommit>|<newCommit>|g" Dockerfile
docker build -t robertslando/zwave2mqtt:latest .
```

Build just the `build` container

```bash
docker build --target=build -t robertslando/zwave2mqtt_build .

```

## SSH inside container

```bash
docker run --rm -p 8091:8091 --device=/dev/ttyACM0 -it --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest sh
```

```bash
docker run --rm -p 8091:8091 --device=/dev/ttyACM0 -it --mount source=zwave2mqtt,target=/dist/pkg robertslando/zwave2mqtt_build sh
```
