## Build docker image

```bash
docker build -t redis-cluster .
```

## Run master 
```bash
docker run -p 6379:6379 -p 26379:26379 --name redis-master redis-cluster
```

## Run slaves 
```bash
docker run -e SLAVE=true -e SENTINEL_MASTER_HOST=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis-master) -p 26378:26379 --name redis-slave-1 redis-cluster
```