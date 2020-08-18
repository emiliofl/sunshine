#!/bin/bash

# tell the configtxgen tool where to look for the configtx.yaml file
export FABRIC_CFG_PATH=$PWD

# the name of the channel
export CHANNEL_NAME=mychannel 
export SYS_CHANNEL_NAME=sunshine-sys-channel 

echo "#################################################"
echo "#########  Cleaning things up      ##############"
echo "#################################################"
echo "done"

if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
fi

if [ -d "channel-artifacts" ]; then
    rm -Rf channel-artifacts
fi

echo "#################################################"
echo "#########  Generate the artifacts  ##############"
echo "#################################################"

cryptogen generate --config=./crypto-config.yaml

echo "#################################################"
echo "#########  Create the orderer genesis block  ####"
echo "#################################################"
mkdir channel-artifacts

configtxgen -profile OneOrgsOrdererGenesis -channelID $SYS_CHANNEL_NAME -outputBlock ./channel-artifacts/genesis.block

echo "###########################################################"
echo "#########  Create a Channel Configuration Transaction  ####"
echo "###########################################################"

configtxgen -profile OneOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel_$CHANNEL_NAME.tx -channelID $CHANNEL_NAME

echo "####################################################"
echo "#########  Define the anchor peer for Producer  ####"
echo "####################################################"

configtxgen -profile OneOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/ProducerMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ProducerMSP

echo "############################"
echo "#########  Step 1 done  ####"
echo "############################"

tree ./crypto-config -L 2
tree ./channel-artifacts

