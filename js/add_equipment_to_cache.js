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
const cache_id = 0;
const start_equipment_id = 36;
const end_equipment_id_inclusive = 47;

const read_account_data = () => {
    let doc;
    try {
        doc = yaml.load(fs.readFileSync('../.aptos/config.yaml', 'utf8'));
    } catch (e) {
        console.log(e);
    }
    return doc;
}

const add_equipment_to_cache = async () => {
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let account_data = read_account_data();
    const privateKey = new Ed25519PrivateKey(account_data.profiles.default.private_key);
    const main = await Account.fromPrivateKey({ privateKey });

    // Call the function with the file path
    // let { headers, rowData } = await readCSV(filePath);

    // console.log(`rowData ${rowData}`);
    for (let i = start_equipment_id; i <= end_equipment_id_inclusive; i++) {
        const transaction = await aptos.transaction.build.simple({
            sender: main.accountAddress,
            data: {
                function: `${account_data.profiles.default.account}::omni_cache::add_equipment_to_cache`,
                typeArguments: [],
                functionArguments: [cache_id, i],
            },
        });
        console.log(`Sending add_equipment_to_cache transaction`);

        const committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
        console.log(`Transaction hash: ${committedTransaction.hash}`);
        const status = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash })
        if (!status.success) {
            console.log(`Transaction failed at: ${i}`);
            break;
        }
    }
};

add_equipment_to_cache();