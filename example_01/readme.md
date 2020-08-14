# Support material for HLF Administrator session 01
Sunshine.com - the birth of a consortium.

## Setup the network
Open terminal 1 or use a tmux session.

```bash
# create crypto material
init.sh
```
## Start the network

```bash
docker-compose up
```

## Stop the network

```bash
docker-compose down
```

## Build the network and install chaincode inside the cli container
Open terminal 2 in the same folder.

```bash
# Execute the cli container
docker exec -it cli bash
```

Inside of the cli container execute the following commands:

```bash 
# set needed environment variables
export CHANNEL_NAME=mychannel 

# create channel
peer channel create -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel_$CHANNEL_NAME.tx

# join channel peer0
peer channel join -b $CHANNEL_NAME.block

# update anchor peer
peer channel update -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx

# join channel peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"
peer channel join -b $CHANNEL_NAME.block

# install chaincode peer0
export CORE_PEER_ADDRESS="peer0.producer.sunshine.com:7051"
peer chaincode install -n mycc -v 1  -p github.com/chaincode/sacc

# instantiate chaincode peer 0
peer chaincode instantiate -o orderer.sunshine.com:7050 -C $CHANNEL_NAME -n mycc  -v 1 -c '{"Args":["msg1","hello"]}' -P "AND ('ProducerMSP.peer')" 

# switch to peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

# install chaincode peer1
peer chaincode install -n mycc -v 1  -p github.com/chaincode/sacc
```

## Query and invoke the chaincode
```bash
# query the chaincode
peer chaincode query -n mycc -c '{"Args":["query","msg1"]}' -C $CHANNEL_NAME 

# invoke the chaincode
peer chaincode invoke -n mycc -c '{"Args":["set","msg2","sunshine.com"]}' -C $CHANNEL_NAME 
```

## Use the docker exec command
You can also use the peer chaincode commands from outside the cli container.

```bash
export CHANNEL_NAME=mychannel 

docker exec cli peer chaincode query -n mycc -c '{"Args":["query","msg1"]}' -C $CHANNEL_NAME 
docker exec cli peer chaincode invoke -n mycc -c '{"Args":["set","msg3","enter the box"]}' -C $CHANNEL_NAME
docker exec cli peer chaincode query -n mycc -c '{"Args":["query","msg3"]}' -C $CHANNEL_NAME 

# change also some environment vars
docker exec -e "CORE_PEER_ADDRESS=peer1.producer.sunshine.com:8051" cli peer chaincode query -n mycc -c '{"Args":["query","msg3"]}' -C $CHANNEL_NAME 

docker exec -e "CORE_PEER_ADDRESS=peer0.producer.sunshine.com:7051" cli peer chaincode query -n mycc -c '{"Args":["query","msg3"]}' -C $CHANNEL_NAME 
```

## Log the container
You can log a specific container.
```bash
docker logs -f peer0.producer.sunshine.com
```

## Inspect the network
Which container are inside of a network.
```bash
docker network inspect net_sunshine
```

## Cleanup the network
```bash 
# stop thenetwork
docker-compose stop

# delete all persistent volumes
docker volume prune

# remove all exited container
docker rm $(docker ps -a -f status=exited -q)

# remove only chaincode container
docker rm -f $(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
```

