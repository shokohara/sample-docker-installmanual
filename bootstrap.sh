#!/bin/bash
docker-machine rm manager0consul0 --force
docker-machine rm manager1 --force
docker-machine rm node0 --force
docker-machine rm node1 --force
docker-machine create -d virtualbox manager0consul0 &
docker-machine create -d virtualbox manager1 &
docker-machine create -d virtualbox node0 &
docker-machine create -d virtualbox node1 &
wait %1 %2 %3 %4

eval $(docker-machine env manager0consul0)
clusterId=$(docker run --rm swarm create | tail -n1)

docker-machine ssh manager0consul0 "docker run -d -p 3376:3376 -t -v /var/lib/boot2docker:/certs:ro swarm manage -H 0.0.0.0:3376 --tlsverify --tlscacert=/certs/ca.pem --tlscert=/certs/server.pem --tlskey=/certs/server-key.pem token://$clusterId"

eval $(docker-machine env node0)
docker-machine config node0
docker run -d swarm join --addr=$(docker-machine ip node0):2376 token://$clusterId

eval $(docker-machine env node1)
docker-machine config node1
docker run -d swarm join --addr=$(docker-machine ip node1):2376 token://$clusterId

eval $(docker-machine env manager0consul0)
DOCKER_HOST=$(docker-machine ip manager0consul0):3376
docker info
docker ps
docker run hello-world
docker ps -a

#docker-machine rm manager0consul0 --force
#docker-machine rm node0 --force
#docker-machine rm node1 --force
