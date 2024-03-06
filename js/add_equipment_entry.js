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
const APTOS_NETWORK = NetworkToNetworkName[process.env.APTOS_NETWORK] || Network.TESTNET;


// Path to the CSV file
const filePath = './data/equipment_data.csv';

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
        headers = rows[0].split(',');
        rowsData = rows.slice(1).map(row => row.split(','));
        newRowsData = rowsData.map(row => row.slice(1).map(cell => cell.trim()));

        // console.log('Headers:', headers);
        // console.log('Data:', newRowsData);
    } catch (err) {
        console.error('Error reading the file:', err);
    }
    return { headers, rowData: newRowsData };
}




/**
 * Prints the balance of an account
 * @param aptos
 * @param name
 * @param address
 * @returns {Promise<*>}
 *
 */
const balance = async (sdk, name, address) => {
    let balance = await sdk.getAccountResource({ accountAddress: address, resourceType: COIN_STORE });

    let amount = Number(balance.coin.value);

    console.log(`${name}'s balance is: ${amount}`);
    return amount;
};

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
    let bob = Account.generate({ scheme: 0 });

    console.log("=== Addresses ===\n");
    console.log(`Main's address is: ${main.accountAddress}`);
    console.log(`Bob's address is: ${bob.accountAddress}`);


    // Call the function with the file path
    let { headers, rowData } = await readCSV(filePath);

    let transaction;
    let committedTransaction;
    console.log(`rowData ${rowData}`);
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

    // Fund the accounts
    // console.log("\n=== Funding accounts ===\n");

    // const aliceFundTxn = await sdk.fundAccount({
    //     accountAddress: main.accountAddress,
    //     amount: ALICE_INITIAL_BALANCE,
    // });
    // console.log("Main's fund transaction: ", aliceFundTxn);

    // const bobFundTxn = await sdk.fundAccount({
    //     accountAddress: bob.accountAddress,
    //     amount: BOB_INITIAL_BALANCE,
    // });
    // console.log("Bob's fund transaction: ", bobFundTxn);

    // // Show the balances
    // console.log("\n=== Balances ===\n");
    // let mainBalance = await balance(sdk, "Main", main.accountAddress);
    // let bobBalance = await balance(sdk, "Bob", bob.accountAddress);

    // if (mainBalance !== ALICE_INITIAL_BALANCE) throw new Error("Main's balance is incorrect");
    // if (bobBalance !== BOB_INITIAL_BALANCE) throw new Error("Bob's balance is incorrect");

    // Transfer between users
    // const txn = await sdk.transaction.build.simple({
    //     sender: alice.accountAddress,
    //     data: {
    //         function: "0x1::coin::transfer",
    //         typeArguments: [parseTypeTag(APTOS_COIN)],
    //         functionArguments: [AccountAddress.from(bob.accountAddress), new U64(TRANSFER_AMOUNT)],
    //     },
    // });

    // console.log("\n=== Transfer transaction ===\n");
    // let committedTxn = await sdk.signAndSubmitTransaction({ signer: alice, transaction: txn });
    // console.log(`Committed transaction: ${committedTxn.hash}`);
    // await sdk.waitForTransaction({ transactionHash: committedTxn.hash });

    // console.log("\n=== Balances after transfer ===\n");
    // let newAliceBalance = await balance(sdk, "Alice", alice.accountAddress);
    // let newBobBalance = await balance(sdk, "Bob", bob.accountAddress);

    // // Bob should have the transfer amount
    // if (newBobBalance !== TRANSFER_AMOUNT + BOB_INITIAL_BALANCE)
    //     throw new Error("Bob's balance after transfer is incorrect");

    // // Alice should have the remainder minus gas
    // if (newAliceBalance >= ALICE_INITIAL_BALANCE - TRANSFER_AMOUNT)
    //     throw new Error("Alice's balance after transfer is incorrect");
};

add_equipment();