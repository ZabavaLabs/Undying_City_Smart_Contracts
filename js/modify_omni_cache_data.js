/**
 * This example shows how to use the Aptos client to create accounts, fund them, and transfer between them.
 */

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
const COIN_STORE = `0x1::coin::CoinStore<${APTOS_COIN}>`;
const ALICE_INITIAL_BALANCE = 100_000_000;
const BOB_INITIAL_BALANCE = 100;
const TRANSFER_AMOUNT = 100;
const APTOS_NETWORK = NetworkToNetworkName[process.env.APTOS_NETWORK] || Network.MAINNET;


// ANCHOR: PARAMETERS TO MODIFY
const shards_to_unlock_cache = 100;
const normal_equipment_weight = 95;
const special_equipment_weight = 5;

async function readCSV(filePath) {
    let data;
    let headers;
    let rowsData;
    let newRowsData;
    try {
        // Read the CSV file
        data = await fs.promises.readFile(filePath, 'utf8');

        // Split the CSV data into rows
        const rows = data.split('\n');

        // Process each row (assuming the first row contains headers)
        // headers = rows[0].split(',');
        rowsData = rows.map(row => row.split(','));
        newRowsData = rowsData.map(row => row.slice(1).map(cell => cell.trim()));

    } catch (err) {
        console.error('Error reading the file:', err);
    }
    return { rowData: newRowsData };
}


const read_account_data = () => {
    let doc;
    try {
        doc = yaml.load(fs.readFileSync('../.aptos/config.yaml', 'utf8'));
    } catch (e) {
        console.log(e);
    }
    return doc;
}

const modify_omni_cache_data = async () => {
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let account_data = read_account_data();
    const privateKey = new Ed25519PrivateKey(account_data.profiles.default.private_key);
    const main = await Account.fromPrivateKey({ privateKey });

    // Call the function with the file path

    const transaction = await aptos.transaction.build.simple({
        sender: main.accountAddress,
        data: {
            function: `${account_data.profiles.default.account}::omni_cache::modify_omni_cache_data`,
            typeArguments: [],
            functionArguments: [shards_to_unlock_cache, normal_equipment_weight, special_equipment_weight],
        },
    });
    console.log(`Sending modify_omni_cache_data transaction`);

    const committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
    console.log(`Transaction hash: ${committedTransaction.hash}`);

};

modify_omni_cache_data();