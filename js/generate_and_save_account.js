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
const filePath = './data/account.txt';



const generate_and_save_account = async () => {
    console.log("This will write account details to file.");
    // Setup the client
    const config = new AptosConfig({ network: APTOS_NETWORK });
    const sdk = new Aptos(config);
    const aptos = new Aptos(config);

    // Setting up account
    let bob = Account.generate({ scheme: 0 });

    console.log(`Bob's address is: ${bob.accountAddress}`);

    let data = `Account Address: ${bob.accountAddress.toString()} \n 
    Private Key: ${bob.privateKey.toString()} \n
    Public Key: ${bob.publicKey.toString()}`;
    // Write to the file
    fs.writeFile(filePath, data, (err) => {
        if (err) {
            console.error('Error writing to file:', err);
            return;
        }
        console.log('Data has been written to', filePath);
    });


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


};

generate_and_save_account();