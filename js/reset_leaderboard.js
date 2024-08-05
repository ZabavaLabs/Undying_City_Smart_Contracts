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




// Wednesday 31st Dec 00:00 AM SGT
const endTime = 1735574400_000_000;

const read_account_data = () => {
    let doc;
    try {
        doc = yaml.load(fs.readFileSync('../.aptos/config.yaml', 'utf8'));
    } catch (e) {
        console.log(e);
    }
    return doc;
}



const reset_leaderboard = async () => {
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


    let transaction;
    let committedTransaction;

    transaction = await aptos.transaction.build.simple({
        sender: main.accountAddress,
        data: {
            function: `${account_data.profiles.default.account}::leaderboard::reset_leaderboard`,
            typeArguments: [],
            functionArguments: [endTime],
        },

    });
    console.log(`Sending reset_leaderboard transaction`);

    committedTransaction = await aptos.signAndSubmitTransaction({ signer: main, transaction });
    console.log(`Transaction hash: ${committedTransaction.hash}`);
    const status = await aptos.waitForTransaction({ transactionHash: committedTransaction.hash })
    console.log(`Transaction status: ${status.success}`);

};

reset_leaderboard();