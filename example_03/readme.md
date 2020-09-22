# Support material for HLF Administrator session 03
In this example we will expand the existing network with a three node RAFT ordering system.

## Preparation for RAFT ordering service

### In a more general way
- create proper artefacts
- enable TLS for the network
- start the network
- create and join channel
- install and instantiate chaincode

### Which files are involved?
- adapt crypto-config.yaml
- adapt configtx.yaml
- generate the crypto material
- adapt peer-base.yaml
- adapt docker-compose.yaml


##  crypto-config.yaml
Add two more orderers to the **OrdererOrgs** section.
```bash
Specs:
  - Hostname: orderer
  - Hostname: orderer2
  - Hostname: orderer3
```

##  configtx.yaml
We have to add the following configuration to the **Orderer: &OrdererDefaults** section. Note: Make sure you don't use tabs, use spaces in the yaml file to prevent yaml parse error.

```bash
  # EtcdRaft defines configuration which must be set when the "etcdraft"
  # orderertype is chosen.
  EtcdRaft:
    # The set of Raft replicas for this network. For the etcd/raft-based
    # implementation, we expect every replica to also be an OSN. Therefore,
    # a subset of the host:port items enumerated in this list should be
    # replicated under the Orderer.Addresses key above.
    Consenters:
      - Host: orderer.sunshine.com
        Port: 7050
        ClientTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer.sunshine.com/tls/server.crt
        ServerTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer.sunshine.com/tls/server.crt
      - Host: orderer2.sunshine.com
        Port: 7050
        ClientTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer2.sunshine.com/tls/server.crt
        ServerTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer2.sunshine.com/tls/server.crt
      - Host: orderer3.sunshine.com
        Port: 7050
        ClientTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer3.sunshine.com/tls/server.crt
        ServerTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer3.sunshine.com/tls/server.crt
```
Add a new profile to the **Profiles** section.

```bash
OneOrgMultiNodeEtcdRaft:
  <<: *ChannelDefaults
  Capabilities:
      <<: *ChannelCapabilities
  Orderer:
      <<: *OrdererDefaults
      OrdererType: etcdraft
      EtcdRaft:
          Consenters:
          - Host: orderer.sunshine.com
            Port: 7050
            ClientTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer.sunshine.com/tls/server.crt
            ServerTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer.sunshine.com/tls/server.crt
          - Host: orderer2.sunshine.com
            Port: 7050
            ClientTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer2.sunshine.com/tls/server.crt
            ServerTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer2.sunshine.com/tls/server.crt
          - Host: orderer3.sunshine.com
            Port: 7050
            ClientTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer3.sunshine.com/tls/server.crt
            ServerTLSCert: crypto-config/ordererOrganizations/sunshine.com/orderers/orderer3.sunshine.com/tls/server.crt
      Addresses:
          - orderer.sunshine.com:7050
          - orderer2.sunshine.com:7050
          - orderer3.sunshine.com:7050
      Organizations:
          - *OrdererOrg
      Capabilities:
          <<: *OrdererCapabilities
  Application:
      <<: *ApplicationDefaults
      Organizations:
      - <<: *OrdererOrg
  Consortiums:
      Sunshine:
          Organizations:
          - *Producer
```

## Generate the crypto material
Notice, in the script the new profiles is used!
```bash
./init.sh
```

## Adopt peer-base.yaml
Add the following to the **peer-base** service.

```bash 
  - CORE_PEER_GOSSIP_USELEADERELECTION=true
  - CORE_PEER_GOSSIP_ORGLEADER=false
  # enable one way tls
  - CORE_PEER_TLS_ENABLED=true
  - CORE_PEER_TLS_CERT_FILE=/etc/hyperledger/fabric/tls/server.crt
  - CORE_PEER_TLS_KEY_FILE=/etc/hyperledger/fabric/tls/server.key
  - CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/fabric/tls/ca.crt

  # enable two way TLS
  - CORE_PEER_TLS_CLIENTAUTHREQUIRED=true
  - CORE_PEER_TLS_CLIENTCERT_FILE=/etc/hyperledger/fabric/tls/server.crt
  - CORE_PEER_TLS_CLIENTKEY_FILE=/etc/hyperledger/fabric/tls/server.key

```

Add the following to the **orderer-base** service.
```bash
# enable one way TLS
  - ORDERER_GENERAL_TLS_ENABLED=true
  - ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key
  - ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt
  - ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]

  # enable two way TLS
  - ORDERER_GENERAL_TLS_CLIENTAUTHREQUIRED=true
  - ORDERER_GENERAL_TLS_CLIENTROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
  - ORDERER_GENERAL_CLUSTER_CLIENTCERTIFICATE=/var/hyperledger/orderer/tls/server.crt
  - ORDERER_GENERAL_CLUSTER_CLIENTPRIVATEKEY=/var/hyperledger/orderer/tls/server.key
  - ORDERER_GENERAL_CLUSTER_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
```

## Adopt docker-compose.yaml
Add two more volumes under the **volumes** section.
```bash 
volumes:
  orderer2.sunshine.com:
  orderer3.sunshine.com:
```

Add two more services for the docker services.
```bash
 orderer2.sunshine.com:
    container_name: orderer2.sunshine.com
    extends:
      file: peer-base.yaml
      service: orderer-base
    volumes:
      - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config/ordererOrganizations/sunshine.com/orderers/orderer2.sunshine.com/msp:/var/hyperledger/orderer/msp
      - ./crypto-config/ordererOrganizations/sunshine.com/orderers/orderer2.sunshine.com/tls:/var/hyperledger/orderer/tls
      - orderer2.sunshine.com:/var/hyperledger/production/orderer
    ports:
      - 8050:7050
    networks:
      - sunshine

  orderer3.sunshine.com:
    container_name: orderer3.sunshine.com
    extends:
      file: peer-base.yaml
      service: orderer-base
    volumes:
      - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config/ordererOrganizations/sunshine.com/orderers/orderer3.sunshine.com/msp:/var/hyperledger/orderer/msp
      - ./crypto-config/ordererOrganizations/sunshine.com/orderers/orderer3.sunshine.com/tls:/var/hyperledger/orderer/tls
      - orderer3.sunshine.com:/var/hyperledger/production/orderer
    ports:
      - 9050:7050
    networks:
      - sunshine
```

## Start/Stop the network

```bash
# start
docker-compose up

# stop
docker-compose down
```
## Create and join channel
```bash
# Execute the cli container
docker exec -it cli bash

# these variables depends on the peer
export CHANNEL_NAME=mychannel 
export TLS_ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/sunshine.com/tlsca/tlsca.sunshine.com-cert.pem"

# create channel
peer channel create -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel_$CHANNEL_NAME.tx --tls --cafile $TLS_ORDERER_CA 

# join channel peer0
peer channel join -b $CHANNEL_NAME.block  

# update anchor peer
peer channel update -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $TLS_ORDERER_CA 

# join channel peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

peer channel join -b $CHANNEL_NAME.block
peer channel list
```

## Install and instantiate the chaincode
```bash
# install chaincode peer0
export CORE_PEER_ADDRESS="peer0.producer.sunshine.com:7051"
peer chaincode install -n mycc -v 1  -p github.com/chaincode/sacc 

# instantiate chaincode peer 0
peer chaincode instantiate -o orderer.sunshine.com:7050 -C $CHANNEL_NAME -n mycc  -v 1 -c '{"Args":["msg1","hello"]}' -P "AND ('ProducerMSP.peer')" --tls --cafile $TLS_ORDERER_CA 

# switch to peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

# install chaincode peer1
peer chaincode install -n mycc -v 1  -p github.com/chaincode/sacc  
```

## Query and invoke the chaincode
```bash
export CORE_PEER_ADDRESS="peer0.producer.sunshine.com:7051"

# query the chaincode
peer chaincode query -n mycc -c '{"Args":["query","msg1"]}' -C $CHANNEL_NAME 

# invoke the chaincode two-way tls
peer chaincode invoke -n mycc -c '{"Args":["set","msg2","super test"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA 

peer chaincode invoke -n mycc -c '{"Args":["set","msg1","Two-Way TLS enabled"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA 

# invoke the chaincode two-way tls
peer chaincode invoke -n mycc -c '{"Args":["set","msg1","Two-Way TLS enabled as well"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA  --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE
```

## Logging

```bash
docker logs orderer.sunshine.com 2>&1 |grep error
```

## Clean up
```
docker rm $(docker ps -a -f status=exited -q)
```


