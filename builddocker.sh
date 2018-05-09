#!/bin/bash

echo ======================================================
echo Building Docker container for Db2
echo ======================================================

docker build -t centos:custom -f Dockerfile .
docker build -t ibm/db2:v11.1.3.3 -f Dockerfile2 .
