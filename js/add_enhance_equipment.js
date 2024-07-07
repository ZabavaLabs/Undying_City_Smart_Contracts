/**
 * This example shows how to use the Aptos client to create accounts, fund them, and transfer between them.
 */
const { getJthColumnAsArray } = require("./common/utility");
const { readCSV } = require("./common/io")

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

const APTOS_COIN = "0x1::aptos_coin::AptosCoin";
const APTOS_NETWORK = NetworkToNetworkName[process.env.APTOS_NETWORK] || Network.MAINNET;


// ANCHOR: PARAMETERS TO MODIFY
const filePath = `./data/enhance_equipment_2.csv`;


const read_account_data = () => {
    let doc;
    try {
        doc = yaml.load(fs.readFileSync('../.aptos/config.yaml', 'utf8'));
    } catch (e) {
        console.log(e);
    }
    return doc;
}

const add_enhance_equipment_info = async () => {
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let account_data = read_account_data();
    const privateKey = new Ed25519PrivateKey(account_data.profiles.default.private_key);
    const main = await Account.fromPrivateKey({ privateKey });

    let { rowData } = await readCSV(filePath, true, false);
    console.log(getJthColumnAsArray(rowData, 1))
    console.log(getJthColumnAsArray(rowData, 2))
    console.log(getJthColumnAsArray(rowData, 3))

    const transaction = await aptos.transaction.build.simple({
        sender: main.accountAddress,
        data: {
            function: `${account_data.profiles.default.account}::equipment::add_all_equipment_enhancement_info`,
            typeArguments: [],
            functionArguments: [getJthColumnAsArray(rowData, 1), getJthColumnAsArray(rowData, 2), getJthColumnAsArray(rowData, 3)],

        },
    });
    console.log(`Sending add_equipment transaction`);

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
    console.log(`Transaction hash: ${committedTransaction.hash}`);
    const status = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash })
    if (!status.success) {
        console.log(`Transaction failed at: ${i}`);

    }
};

add_enhance_equipment_info();