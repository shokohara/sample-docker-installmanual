#!/bin/bash
docker-machine rm manager0consul0 --force
docker-machine rm manager1 --force
docker-machine rm node0 --force
docker-machine rm node1 --force
docker-machine create -d virtualbox manager0consul0
docker-machine create -d virtualbox manager1
docker-machine create -d virtualbox node0
docker-machine create -d virtualbox node1

# Set up an consul discovery backend
eval $(docker-machine env manager0consul0)
docker run -d -p 8500:8500 --name=consul progrium/consul -server -bootstrap
docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise $(docker-machine ip manager0consul0):4000 consul://$(docker-machine ip manager0consul0):8500
docker-machine ssh manager0consul0 docker -H $(docker-machien ip manager0consul0):4000 info

# Create a high-availability Swarm cluster
docker-machine ssh manager1 docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise $(docker-machine ip manager1):4000 consul://$(docker-machine ip manager0consul0):8500
docker-machine ssh manager0consul0 docker -H $(docker-machine ip manager0consul0):4000 info
docker-machine ssh node0 docker run -d swarm join --advertise=$(docker-machine ip node0):2376 consul://$(docker-machine ip manager0consul0):8500
docker-machine ssh manager0consul0 docker -H $(docker-machine ip manager0consul0):4000 info

#docker-machine ssh manager0consul0 docker -H $(docker-machine ip manager0consul0):4000 info
#eval $(docker-machine env node1)
#docker run -d swarm join --advertise=$(docker-machine ip node1):2376 consul://$(docker-machine ip manager0consul0):8500
#docker-machine ssh manager0consul0 docker -H $(docker-machine ip manager0consul0):4000 info

## Communicate with the Swarm
#eval $(docekr-machine env manager0consul0)
#docker-machine ssh manager0consul0 docker -H :4000 info
#docker-machine ssh manager0consul0 docker -H :4000 run hello-world
#docker-machine ssh manager0consul0 docker -H :4000 ps
#
## Test the high-availability Swarm managers
#docker-machine ssh manager0consul0 docker ps
#docker-machine ssh manager0consul0 docker rm -f $(docker ps -q)
#docker-machine ssh manager0consul0 docker run -d -p 4000:4000 swarm manage -H :4000 --replication --advertise $(docker-machine ip manager0consul0):4000  consul://$(docker-machine ip manager0consul0):237
#docker-machine ssh manager0consul0 docker logs $(docker ps -q)
#docker-machine ssh manager0consul0 docker -H :4000 info
