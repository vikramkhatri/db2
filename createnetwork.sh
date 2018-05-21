#!/bin/bash

echo =================================================
echo Create macvlan network
echo =================================================

docker network create -d macvlan -o parent=eth0 \
  --subnet 192.168.142.0/24 \
  --gateway 192.168.142.2 \
  --ip-range 192.168.142.192/27 \
  --aux-address 'host=192.168.142.223' \
  mynet

ip link add mynet-shim link eth0 type macvlan  mode bridge
ip addr add 192.168.142.223/32 dev mynet-shim
ip link set mynet-shim up
ip route add 192.168.142.192/27 dev mynet-shim
