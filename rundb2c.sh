#!/bin/bash

echo =================================================
echo Run db2 container
echo =================================================

docker run -d -it \
 --privileged=true \
 -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
 -v /db2mount:/db2mount \
 --name=db2c \
 --tmpfs /run/systemd/system \
 --cap-add SYS_ADMIN \
 --env-file=./bin/config/db2c.env \
 -h db2chost \
 ibm/db2:v11.1.3.3
