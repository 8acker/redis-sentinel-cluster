#!/bin/bash

if [ -z "$1" ]
then
    clusters=3
else
    clusters=$1
fi

docker kill redis-master
docker rm redis-master
for (( i=1; i<=$clusters; i++ ))
do
    docker kill redis-slave-${i}
    docker rm redis-slave-${i}
done