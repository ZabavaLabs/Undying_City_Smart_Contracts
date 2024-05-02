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

const APTOS_NETWORK = NetworkToNetworkName[process.env.APTOS_NETWORK] || Network.TESTNET;


// Path to the CSV file
const filePath = './data/whitelist_addresses_5_test.csv';
const eventName = "Third Free Mint of Undying City!";
const startTime = 1714614245_000_000;
// Friday 3rd May 10:30 PM SGT
// const startTime = 1714746600_000_000;
// Wednesday 8th May 10:30 PM SGT
const endTime = 1715178600_000_000;

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


const add_special_event_and_addresses = async () => {
    console.log("This will read the equipment data from file and add them to the network.");
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let account_data = read_account_data();
    const privateKey = new Ed25519PrivateKey(account_data.profiles.default.private_key);
    const main = await Account.fromPrivateKey({ privateKey });


    console.log(`Main's address is: ${main.accountAddress}`);

    // Call the function with the file path
    let { rowData } = await readCSV(filePath);

    let transaction;
    let committedTransaction;
    console.log(`rowData ${rowData}`);

    transaction = await aptos.transaction.build.simple({
        sender: main.accountAddress,
        data: {
            function: `${account_data.profiles.default.account}::omni_cache::reset_event_and_add_addresses`,
            typeArguments: [],
            functionArguments: [eventName, startTime, endTime, getJthColumnAsArray(rowData, 0), getJthColumnAsArray(rowData, 1)],
        },
    });
    console.log(`Sending add_special_event_and_addresses transaction`);

    committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
    console.log(`Transaction hash: ${committedTransaction.hash}`);
    const status = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash })
    console.log(`Transaction status: ${status.success}`);


};

add_special_event_and_addresses();