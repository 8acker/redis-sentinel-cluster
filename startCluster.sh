#!/bin/bash

if [ -z "$1" ]
then
    clusters=3
else
    clusters=$1
fi
echo "Starting ${clusters} clusters"

docker build -t redis-cluster .

stopCluster.sh $clusters

docker run -d -p 6379:6379 -p 26379:26379 --name redis-master redis-cluster

for (( i=1; i<=$clusters; i++ ))
do
    redis=$((6379-$i))
    sentinel=$((26379-$i))
    echo "Starting slave on redis server port ${redis} and sentinel port ${sentinel}..."
    docker run -d -e SLAVE=true -e SENTINEL_MASTER_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master) -p ${sentinel}:26379 -p ${redis}:6379 --name redis-slave-${i} redis-cluster
done