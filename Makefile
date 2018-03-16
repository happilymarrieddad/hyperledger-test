#-----------------------------
#	Example
#-----------------------------
CHANNEL_NAME=mychannel

run:
	make build
	make start

start:
	docker-compose -f docker-compose-cli.yaml up
clean:
	docker stop $(docker ps -a -q)
	docker rm $(docker ps -a -q)
	docker rmi -f $(docker images -q)
	make create_artifact_folder

build:
	make certs
	make artifacts

certs:
	echo "\nBuilding Cert Files\n"
	make clean_certs
	make generate_certs
generate_certs:
	./cryptogen generate --config=./crypto-config.yaml
clean_certs:
	rm -rf ./crypto-config


# Artifacts
artifacts:
	echo "\nBuilding Artifact Files\n"
	make create_artifact_folder
	make generate_genesis_block
	make generate_channel_configuration_transaction
	make generate_channel_peer
create_artifact_folder:
	rm -rf channel-artifacts
	mkdir channel-artifacts
generate_genesis_block:
	./configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
generate_channel_configuration_transaction:
	./configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
generate_channel_peer:
	./configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
	./configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP


# Chaincodes
test_building_chaincodes:
	echo "\nBuilding Chaincodes\n"
	make example_chaincode
example_chaincode:
	go build -tags "nopkcs11" chaincodes/example.go
	rm chaincodes/example