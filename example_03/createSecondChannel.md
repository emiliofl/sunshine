# Create a second channel

## Create the channel artifacts

```bash
# tell the configtxgen tool where to look for the configtx.yaml file
export FABRIC_CFG_PATH=$PWD

# the name of the channel
export CHANNEL_NAME=tracking2 
export SYS_CHANNEL_NAME=sunshine-sys-channel 

configtxgen -profile OneOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel_$CHANNEL_NAME.tx -channelID $CHANNEL_NAME

tree ./channel-artifacts
```

## Create channel and join the peers

```bash
# Execute the cli container
docker exec -it cli bash

# these variables depends on the peer
export CHANNEL_NAME=tracking2 
export TLS_ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/sunshine.com/tlsca/tlsca.sunshine.com-cert.pem"

# create channel
peer channel create -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel_$CHANNEL_NAME.tx --tls --cafile $TLS_ORDERER_CA 

# join channel peer0
peer channel join -b $CHANNEL_NAME.block  

# join channel peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

peer channel join -b $CHANNEL_NAME.block
peer channel list
```

## Install and instantiate chaincode on second channel
```bash
# install chaincode peer0
export CORE_PEER_ADDRESS="peer0.producer.sunshine.com:7051"
peer chaincode install -n tracking2 -v 1  -p github.com/chaincode/tracking2 

# instantiate chaincode peer 0
peer chaincode instantiate -o orderer.sunshine.com:7050 -C $CHANNEL_NAME -n tracking2  -v 1 -c '{"Args":[]}' --tls --cafile $TLS_ORDERER_CA 

# switch to peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

# install chaincode peer1
peer chaincode install -n tracking2 -v 1  -p github.com/chaincode/tracking2  

peer chaincode invoke -n tracking2 -c '{"Args":["set","1","2020-09-09T23:00:00.000Z"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA 

peer chaincode query -n tracking2 -c '{"Args":["history","1"]}' -C $CHANNEL_NAME | jq '.'

```
