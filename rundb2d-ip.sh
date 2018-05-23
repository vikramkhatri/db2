#!/bin/bash

echo =================================================
echo Run db2 container
echo =================================================

IP=${1:-192.168.142.194}

docker run -d -it \
 --privileged=true \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v /db2d:/db2mount \
 --name=db2d \
 --tmpfs /run/systemd/system \
 --cap-add SYS_ADMIN \
 --env-file=./bin/config/db2d.env \
 --net mynet \
 --ip $IP \
 -h db2d \
 ibm/db2:v11.1.3.3
