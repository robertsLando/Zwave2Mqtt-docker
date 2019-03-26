# Zwave2Mqtt-docker

Docker container for Zwave2Mqtt Gateway and Control Panel app using pkg

Image size acually is lower than 80MB:

```bash
daniel@daniel-innovation:/media/daniel/DATA/Git-Projects/Zwave2Mqtt-docker$ docker images
REPOSITORY                TAG                 IMAGE ID            CREATED             SIZE
robertslando/zwave2mqtt   latest              90f8521faab4        51 seconds ago      77.5MB
```

## Install

Run the following command

```bash
docker volume create zwave2mqtt
docker run --rm -it -p 8091:8091 --device=/dev/ttyACM0 --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest
```

> Replace `/dev/ttyACM0` with your serial device

Check files inside volume

```bash
docker run -it --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest find /usr/src/app
```

Delete Volume

```bash
docker volume rm zwave2mqtt
```

## Build

```bash
docker build -t robertslando/zwave2mqtt .
```

## SSH inside container

```bash
docker run -p 8091:8091 --device=/dev/ttyACM0 -it --mount source=zwave2mqtt,target=/usr/src/app robertslando/zwave2mqtt:latest sh
```