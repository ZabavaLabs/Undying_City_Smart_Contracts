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
const APTOS_NETWORK = NetworkToNetworkName[process.env.APTOS_NETWORK] || Network.MAINNET;


// Path to the CSV file
const filePath = './data/new_equipment_data_5.tsv';

async function readTSV(filePath) {
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
        headers = rows[0].split('\t');
        rowsData = rows.slice(1).map(row => row.split('\t'));
        newRowsData = rowsData.map(row => row.slice(1).map(cell => cell.trim()));

        // console.log('Headers:', headers);
        // console.log('Data:', newRowsData);
    } catch (err) {
        console.error('Error reading the file:', err);
    }
    return { headers, rowData: newRowsData };
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

const add_equipment = async () => {
    console.log("This will read the equipment data from file and add them to the network.");
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let account_data = read_account_data();
    const privateKey = new Ed25519PrivateKey(account_data.profiles.default.private_key);
    const main = await Account.fromPrivateKey({ privateKey });

    console.log("=== Addresses ===\n");
    console.log(`Main's address is: ${main.accountAddress}`);

    // Call the function with the file path
    let { headers, rowData } = await readTSV(filePath);

    let transaction;
    let committedTransaction;
    // console.log(`rowData:`);
    // console.log(`${rowData[0][0]}`);
    // console.log(`${rowData[0][1]}`);
    // console.log(`${rowData[0][2]}`);
    // console.log(`${rowData[0][3]}`);
    // console.log(`${rowData[0][4]}`);
    // console.log(`${rowData[0][5]}`);
    // console.log(`${rowData[0][6]}`);
    // console.log(`${rowData[0][7]}`);
    // console.log(`${rowData[0][8]}`);
    // console.log(`length ${rowData[0].length}`);
    // console.log(`Cols ${rowData.length}`);

    for (let i = 0; i < rowData.length; i++) {
        transaction = await aptos.transaction.build.simple({
            sender: main.accountAddress,
            data: {
                function: `${account_data.profiles.default.account}::equipment::add_equipment_entry`,
                typeArguments: [],
                functionArguments: rowData[i],
            },
        });
        console.log(`Sending add_equipment transaction`);

        committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
        console.log(`Transaction hash: ${committedTransaction.hash}`);
        const status = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash })
        if (!status.success) {
            console.log(`Transaction failed at: ${i}`);
            break;
        }
    }

};

add_equipment();