/**
  * SPDX-License-Identifier: Apache-2.0
 */

/**
 * This is an example based on fabric-sdk-node, it refers content of:
 * https://fabric-sdk-node.github.io/master/index.html
 * https://github.com/hyperledger/fabric-sdk-node
 * https://fabric-sdk-node.github.io/master/tutorial-network-config.html
 * 
 * This program uses connprofile.json, what is a common connection profile.
 * It will utilze FileSystemWallet and Gateway, what is from fabric-network module.
 */

'use strict';
const os = require('os');
const fs = require('fs');
const path = require('path');
const winston = require('winston');
const {Gateway, FileSystemWallet, X509WalletMixin, DefaultEventHandlerStrategies } = require('fabric-network');

var logger = new (winston.Logger)({transports: [new (winston.transports.Console)()]});

// Call the only test function.

let arg = process.argv[2];
switch (arg) {
    case 'query' : testQuery();; break;
    case 'invoke' : testInvoke(); break;
    default: logger.error(`Please run command likes: 'node fabcarnstest.js query' or 'node fabcarnstest.js invoke'`);
}

async function testQuery() {
    const identityLabel = 'Admin@org1.example.com';
    const wallet = await initAdminWallet(identityLabel);
    const gateway = new Gateway();

    await gateway.connect(path.join(__dirname, './connprofile.json'),
        {
            wallet: wallet,
            identity: identityLabel
        });

    logger.info('Gateway connects get succeed.');

    const network = await gateway.getNetwork('mychannel');
    //const contract = await network.getContract('fabcarns');
    //const result = await contract.evaluateTransaction('queryAllCars');

    const contract = await network.getContract('fabcarns', 'org.example.fabrcarvipns');
    const result = await contract.evaluateTransaction('queryAllCars');

    gateway.disconnect();
    logger.info('Result', JSON.parse(Buffer.from(result).toString()));
}

async function testInvoke() {
    const identityLabel = 'Admin@org1.example.com';
    const wallet = await initAdminWallet(identityLabel);
    const gateway = new Gateway();

    await gateway.connect(path.join(__dirname, './connprofile.json'),
        {
            wallet: wallet,
            identity: identityLabel,
            discovery: {
				enabled: false,
			},
            // eventHandlerOptions: {
            //     //strategy: DefaultEventHandlerStrategies.MSPID_SCOPE_ALLFORTX
            //     strategy: DefaultEventHandlerStrategies.NETWORK_SCOPE_ALLFORTX
            // }
            eventHandlerOptions: {
                commitTimeout: 100,
                strategy: DefaultEventHandlerStrategies.NETWORK_SCOPE_ALLFORTX
            }
        });

    logger.info('Gateway connects get succeed.');

    try {
        const network = await gateway.getNetwork('mychannel');
        const contract = await network.getContract('fabcarns', 'org.example.fabrcarvipns');

        //const result = await contract.submitTransaction('initLedger');

        const transaction = contract.createTransaction('initLedger');
        const transactionId = transaction.getTransactionID().getTransactionID();    
        logger.info('Create a transaction ID: ', transactionId);        
        const result = await transaction.submit();

        gateway.disconnect();
        logger.info('Result', Buffer.from(result).toString());
    } 
    catch (err) {
		logger.error('Failed to invoke transaction chaincode on channel. ' + err.stack ? err.stack : err);
    } 
    finally {
		gateway.disconnect();
		logger.info('Gateway disconnected.');
	}
}

async function initAdminWallet(identityLabel) {
    // Hardcode crypto materials of Admin@org1.example.com.
    const keyPath = path.join(__dirname, "../../fabric-samples/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/2e4d1384aee68374b7d2ccd9e53bc207ca7ee72bcff678d6b5ba24794da21bae_sk");
    const keyPEM = Buffer.from(fs.readFileSync(keyPath)).toString();
    const certPath = path.join(__dirname, "../../fabric-samples/first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem");
    const certPEM = Buffer.from(fs.readFileSync(certPath)).toString();

    const mspId = 'Org1MSP';
    const identity = X509WalletMixin.createIdentity(mspId, certPEM, keyPEM)

    const wallet = new FileSystemWallet('/tmp/wallet/test1');
    await wallet.import(identityLabel, identity);

    if (await wallet.exists(identityLabel)) {
        logger.info('Identity %s exists.', identityLabel);
    }
    else {
        logger.error('Identity %s does not exist.', identityLabel);
    }
    return wallet;
}