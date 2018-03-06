#!/bin/bash

echo =================================================
echo Run db2 container
echo =================================================

docker run -d -it \
   --privileged \
   --name=db2c \
   --env-file=./bin/config/db2c.env \
   -h db2chost \
   -p 50000-50001:50000-50001 \
   ibm/db2:v11.1.2.2
