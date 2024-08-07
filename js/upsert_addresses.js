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


// Path to the CSV file
const filePath = './data/whitelist_addresses_8.csv';

const read_account_data = () => {
    let doc;
    try {
        doc = yaml.load(fs.readFileSync('../.aptos/config.yaml', 'utf8'));
    } catch (e) {
        console.log(e);
    }
    return doc;
}


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

        headers = rows[0].split(',');
        rowsData = rows.slice(1).map(row => row.split(','));
        newRowsData = rowsData.map(row => row.map(cell => cell.trim()));

    } catch (err) {
        console.error('Error reading the file:', err);
    }
    return { rowData: newRowsData };
}


const upsert_addresses = async () => {
    console.log("This will read the equipment data from file and add them to the network.");
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let account_data = read_account_data();
    const privateKey = new Ed25519PrivateKey(account_data.profiles.default.private_key);
    const main = await Account.fromPrivateKey({ privateKey });

    // Call the function with the file path
    let { rowData } = await readCSV(filePath);

    let transaction;
    let committedTransaction;

    for (let i = 0; i < rowData.length; i++) {
        transaction = await aptos.transaction.build.simple({
            sender: main.accountAddress,
            data: {
                function: `${account_data.profiles.default.account}::omni_cache::upsert_whitelist_address`,
                typeArguments: [],
                functionArguments: [rowData[i][0], rowData[i][1]],
            },
        });
        console.log(`Upsert Whitelist Address ${rowData[i][0]}`);

        committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
        console.log(`Transaction hash: ${committedTransaction.hash}`);
        const status = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash })
        if (!status.success) {
            console.log(`Transaction failed at: ${i}`);
            break;
        }
    }

};

upsert_addresses();