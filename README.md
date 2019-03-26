# Zwave2Mqtt-docker
Docker container for Zwave2Mqtt Gateway and Control Panel app

## Install

Run the following command

```bash
docker run -p 8091:8091 --device=/dev/ttyACM0 robertslando/zwave2mqtt:latest
```

Replace `/dev/ttyACM0` with your serial device

## Test

```bash
docker run -p 8091:8091 --device=/dev/ttyACM0 -it robertslando/zwave2mqtt:latest sh
```