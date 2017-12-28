#!/bin/bash

if [ -z "$1" ]
then
    clusters=3
else
    clusters=$1
fi
echo "Starting ${clusters} clusters"

sentinelPort=26379

docker build -t redis-cluster .

./stopClusters.sh $clusters

docker run -d -p 6379:6379 -p ${sentinelPort}:26379 --name redis-master redis-cluster

for (( i=1; i<=$clusters; i++ ))
do
    port=$(($sentinelPort-$i))
    docker run -d -e SLAVE=true -e SENTINEL_MASTER_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master) -p ${port}:26379 --name redis-slave-${i} redis-cluster
done