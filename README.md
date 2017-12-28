## Build docker image

```bash
docker build -t redis-cluster .
```

## Run master 
```bash
docker run -p 6379:6379 -p 26379:26379 --name redis-master redis-cluster
```

## Run a slave
```bash
docker run -e SLAVE=true -e SENTINEL_MASTER_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master) -p 26378:26379 --name slave-name redis-cluster
```

## Start Cluster
Will start one master and #n slaves
```bash
./startCluster.sh n
```

## Stop Cluster
Will stop all slaves and the master
```bash
./stopCluster.sh n
```