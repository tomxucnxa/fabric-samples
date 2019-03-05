
# ./byfn.sh up

docker exec -it cli bash

# test
source ./scripts/setparas.sh peerenv 0 1
peer chaincode query -C "$CHANNEL_NAME" -n mycc -c '{"Args":["query","a"]}'

##################### Install fabcar chaincode
export CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/fabcar/javascript"
export VERSION="1.0"
export CC_NAME="fabcar" 
export LANGUAGE="node"

# peer chaincode install -n fabcar -v 1.0 -p "$CC_SRC_PATH" -l "$CC_RUNTIME_LANGUAGE"
source ./scripts/setparas.sh peerenv 0 1
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
source ./scripts/setparas.sh peerenv 0 2
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
source ./scripts/setparas.sh peerenv 1 1
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
source ./scripts/setparas.sh peerenv 1 2
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
# need to verify
peer chaincode instantiate -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA \
-C $CHANNEL_NAME -n $CC_NAME -l $LANGUAGE -v $VERSION -c '{"Args":[]}' -P "$DEFAULT_POLICY"

# Original fine script
cat <<EOF
peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n fabcar -l "$LANGUAGE" \
--tls --cafile $ORDERER_CA \
-v 1.0 -c '{"Args":[]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
EOF

source ./scripts/setparas.sh peerconn 0 1 0 2
peer chaincode invoke -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME \
$PEER_CONN_PARMS -c '{"function":"initLedger","Args":[]}'

source ./scripts/setparas.sh peerenv 0 1
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"queryAllCars","Args":[]}'
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"queryCar","Args":["CAR8"]}'


################################# Install fabcarns chaincode
export CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/fabcarns/javascript"
export VERSION="1.2"
export CC_NAME="fabcarns" 
export LANGUAGE="node"

# peer chaincode install -n fabcar -v 1.0 -p "$CC_SRC_PATH" -l "$CC_RUNTIME_LANGUAGE"
source ./scripts/setparas.sh peerenv 0 1
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
source ./scripts/setparas.sh peerenv 0 2
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
source ./scripts/setparas.sh peerenv 1 1
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"
source ./scripts/setparas.sh peerenv 1 2
peer chaincode install -n "$CC_NAME" -v $VERSION -l "$LANGUAGE" -p "$CC_SRC_PATH"

# Instantiate
peer chaincode instantiate -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA \
-C $CHANNEL_NAME -n $CC_NAME -l $LANGUAGE -v $VERSION -c '{"Args":[]}' -P "$DEFAULT_POLICY"

source ./scripts/setparas.sh peerenv 0 1
source ./scripts/setparas.sh peerconn 0 1 0 2
peer chaincode invoke -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA -C $CHANNEL_NAME -n $CC_NAME \
$PEER_CONN_PARMS -c '{"function":"initLedger","Args":[]}'

source ./scripts/setparas.sh peerenv 0 1
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"queryAllCars","Args":[]}'
peer chaincode query -C $CHANNEL_NAME -n $CC_NAME -c '{"function":"queryCar","Args":["CAR0"]}'

##################################### Upgrade
peer chaincode upgrade -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA \
-C $CHANNEL_NAME -n $CC_NAME -v $VERSION -c '{"Args":[]}' -P "$DEFAULT_POLICY"

## 
peer channel getinfo -c mychannel 

source ./scripts/setparas.sh peerconn 0 1
peer channel fetch newest -c $CHANNEL_NAME -o $ORDERER_ADDRESS --tls --cafile $ORDERER_CA 

# In host fabric/fabric-samples/first-network
configtxgen --inspectBlock channel-artifacts/mychannel_newest.block

# The transaction id from application is identical with what from block.
