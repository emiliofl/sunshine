# Support material for HLF Administrator session 02
In this example we are going to extend the existing network with TLS. We will discuss One-Way and Two-Way TLS.

## Configuring TLS for peers nodes
To enable TLS on a peer node set the following peer configuration properties:

```bash
# enable one-way TLS
CORE_PEER_TLS_ENABLED=true

# fully qualified path of the file that contains the TLS server certificate
CORE_PEER_TLS_CERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/peers/peer0.producer.sunshine.com/tls/server.crt

# fully qualified path of the file that contains the TLS server private key
CORE_PEER_TLS_KEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/peers/peer0.producer.sunshine.com/tls/server.key

# fully qualified path of the file that contains the certificate chain of the certificate authority(CA) that issued TLS server certificate
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/peers/peer0.producer.sunshine.com/tls/ca.crt
```

## Configuring TLS for orderer nodes
To enable TLS on an orderer node, set the following orderer configuration properties:

```bash
# enable one-way TLS
ORDERER_GENERAL_TLS_ENABLED=true

# fully qualified path of the file that contains the server private key
ORDERER_GENERAL_TLS_PRIVATEKEY=/var/hyperledger/orderer/tls/server.key

# fully qualified path of the file that contains the server certificate
ORDERER_GENERAL_TLS_CERTIFICATE=/var/hyperledger/orderer/tls/server.crt

# fully qualified path of the file that contains the certificate chain of the CA that issued TLS server certificate
ORDERER_GENERAL_TLS_ROOTCAS=[/var/hyperledger/orderer/tls/ca.crt]
```

## Configuring TLS for the peer CLI
The following environment variables must be set when running peer CLI commands against a TLS enabled peer node:

```bash
# enable one-way TLS
CORE_PEER_TLS_ENABLED = true

# fully qualified path of the file that contains cert chain of the CA that issued the TLS server cert
TLS_ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/sunshine.com/tlsca/tlsca.sunshine.com-cert.pem
```

## Start/Stop the network

```bash
# start
docker-compose up

# stop
docker-compose down
```

```bash
# Execute the cli container
docker exec -it cli bash

# these variables depends on the peer
export CHANNEL_NAME=mychannel 
export TLS_ORDERER_CA="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/sunshine.com/tlsca/tlsca.sunshine.com-cert.pem"

# needed for two-way TLS
export CORE_PEER_TLS_CLIENTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/users/Admin@producer.sunshine.com/tls/client.crt"
export CORE_PEER_TLS_CLIENTKEY_FILE="/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/users/Admin@producer.sunshine.com/tls/client.key"

# create channel
peer channel create -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel_$CHANNEL_NAME.tx --tls --cafile $TLS_ORDERER_CA --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE


# join channel peer0
peer channel join -b $CHANNEL_NAME.block  

# update anchor peer
peer channel update -o orderer.sunshine.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls --cafile $TLS_ORDERER_CA --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE

# join channel peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

peer channel join -b $CHANNEL_NAME.block
peer channel list

# install chaincode peer0
export CORE_PEER_ADDRESS="peer0.producer.sunshine.com:7051"
peer chaincode install -n mycc -v 1  -p github.com/chaincode/sacc 

# instantiate chaincode peer 0
peer chaincode instantiate -o orderer.sunshine.com:7050 -C $CHANNEL_NAME -n mycc  -v 1 -c '{"Args":["msg1","hello"]}' -P "AND ('ProducerMSP.peer')" --tls --cafile $TLS_ORDERER_CA --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE

# switch to peer1
export CORE_PEER_ADDRESS="peer1.producer.sunshine.com:8051"

# install chaincode peer1
peer chaincode install -n mycc -v 1  -p github.com/chaincode/sacc  

```

## Query and invoke the chaincode
```bash
# query the chaincode
peer chaincode query -n mycc -c '{"Args":["query","msg1"]}' -C $CHANNEL_NAME 

# invoke the chaincode one-way tls
peer chaincode invoke -n mycc -c '{"Args":["set","msg1","One-Way TLS enabled"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE

# invoke the chaincode two-way tls
peer chaincode invoke -n mycc -c '{"Args":["set","msg6","Two-Way TLS enabled as well"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA  --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE
```
## Let another user to interact
```bash
export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/users/User1@producer.sunshine.com/msp
export CORE_PEER_TLS_CLIENTKEY_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/users/User1@producer.sunshine.com/tls/client.key
export CORE_PEER_TLS_CLIENTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/producer.sunshine.com/users/User1@producer.sunshine.com/tls/client.crt

peer chaincode query -n mycc -c '{"Args":["query","msg1"]}' -C $CHANNEL_NAME 
peer chaincode invoke -n mycc -c '{"Args":["set","msg2","User1 Two-Way TLS enabled as well"]}' -C $CHANNEL_NAME --tls --cafile $TLS_ORDERER_CA  --clientauth --keyfile $CORE_PEER_TLS_CLIENTKEY_FILE --certfile $CORE_PEER_TLS_CLIENTCERT_FILE
```

## Logging

```bash
docker logs orderer.sunshine.com 2>&1 |grep error
```

## Inspect some certs

```bash
# check orderer TLS cert structure
openssl x509 -noout -text -in crypto-config/ordererOrganizations/sunshine.com/tlsca/tlsca.sunshine.com-cert.pem
openssl x509 -noout -text -in crypto-config/ordererOrganizations/sunshine.com/orderers/orderer.sunshine.com/tls/server.crt


# check peers TLS cert structure
openssl x509 -noout -text -in crypto-config/peerOrganizations/producer.sunshine.com/tlsca/tlsca.producer.sunshine.com-cert.pem
openssl x509 -noout -text -in crypto-config/peerOrganizations/producer.sunshine.com/peers/peer0.producer.sunshine.com/tls/server.crt
```
