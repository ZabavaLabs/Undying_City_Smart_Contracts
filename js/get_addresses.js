const { getJthColumnAsArray } = require("./common/utility");

const {
    Account,
    Aptos,
    AptosConfig,
    parseTypeTag,
    NetworkToNetworkName,
    Network,
    AccountAddress,
    U64,
    Ed25519PrivateKey,
} = require("@aptos-labs/ts-sdk");


const yaml = require('js-yaml');
const fs = require('fs');

const APTOS_NETWORK = NetworkToNetworkName[process.env.APTOS_NETWORK] || Network.MAINNET;


const get_addresses = async () => {
    console.log("This will read the collection data.");
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const aptos = new Aptos(config);


    await aptos.getCollectionData()
};

get_addresses();