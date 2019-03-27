# Zwave2Mqtt-docker

Docker container for Zwave2Mqtt Gateway and Control Panel app using pkg

** Image size acually is lower than 80MB **

```bash
daniel@daniel:~/Zwave2Mqtt-docker$ docker images
REPOSITORY                      TAG                 IMAGE ID            CREATED             SIZE
robertslando/zwave2mqtt         latest              043a0d327ad6        2 minutes ago       76.7MB
```

## Install

Run the following command

```bash
# Pull the image from DockerHub
docker pull robertslando/zwave2mqtt:latest
# Create a volume for presistence data
docker volume create zwave2mqtt
# Start the container
docker run --rm -it -p 8091:8091 --device=/dev/ttyACM0 --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest
```

> Replace `/dev/ttyACM0` with your serial device

Check files inside volume

```bash
docker run --rm -it --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest find /usr/src/app
```

Delete Volume

```bash
docker volume rm zwave2mqtt
```

## Build

```bash
docker build -t robertslando/zwave2mqtt .
```

Build `build` container

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