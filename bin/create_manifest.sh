docker push robertslando/zwave2mqtt:arm32v6-latest
docker push robertslando/zwave2mqtt:arm32v7-latest
docker push robertslando/zwave2mqtt:arm64v8-latest 

docker manifest create -a robertslando/zwave2mqtt:latest \
robertslando/zwave2mqtt:arm32v6-latest \
robertslando/zwave2mqtt:arm32v7-latest \
robertslando/zwave2mqtt:arm64v8-latest 

docker manifest annotate robertslando/zwave2mqtt:latest robertslando/zwave2mqtt:arm32v6-latest --os linux --arch arm
docker manifest annotate robertslando/zwave2mqtt:latest robertslando/zwave2mqtt:arm32v7-latest --os linux --arch arm
docker manifest annotate robertslando/zwave2mqtt:latest robertslando/zwave2mqtt:arm64v8-latest --os linux --arch arm64 --variant armv8
docker manifest push robertslando/zwave2mqtt:latest