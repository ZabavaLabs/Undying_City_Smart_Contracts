/// This module implements the the und tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::token_lock_test {
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::error;
    use std::option;
    use std::signer;
    use std::vector;

    use std::string::{Self};
    use aptos_framework::timestamp;

 /// The token does not exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 1;
    /// The provided signer is not the creator
    const ENOT_FINALIZED: u64 = 2;

    const ECLIFF_NOT_PASSED: u64 = 3;
    const EBALANCE_ZERO: u64 = 4;

    const EPERIOD_NOT_PASSED: u64 = 5;

    // The caller is not the admin
    const ENOT_ADMIN: u64 = 8;
    // The minimum mintable amount requirement is not met.
    const ENOT_MINIMUM_MINT_AMOUNT: u64 = 9;

    const ENOT_EVEN: u64 = 10;

    const EINVALID_DATA: u64 = 11;

    const ETOKEN_CONFIG_FINALIZED: u64 = 12;

    const UND_COLLECTION_NAME: vector<u8> = b"Undying City Token Collection";
    /// The collection description
    const UND_COLLECTION_DESCRIPTION: vector<u8> = b"This collection stores the Undying City Token.";
    /// The collection URI
    const UND_COLLECTION_URI: vector<u8> = b"https://doc.undyingcity.zabavalabs.com";

    /// The token name
    const UND_TOKEN_NAME: vector<u8> = b"Undying City Token";
    const UND_TOKEN_DESCRIPTION: vector<u8> = b"The Undying City Token controls the governance of the game.";
    const UND_ASSET_NAME: vector<u8> = b"Undying City Token";
    const UND_MAX_SUPPLY: u64 = 100_000_000;

    const UND_ASSET_SYMBOL: vector<u8> = b"UND";
    //Point to project website or app
    const PROJECT_URI: vector<u8> = b"https://undyingcity.zabavalabs.com";
    //Point to Image
    // TODO: Point to the image once it's uploaded.
    const PROJECT_ICON_URI: vector<u8> = b"ipfs://bafybeiee6ziwznlaullflnzeqpvvdtweb7pehp572xcafkwawvtun2me4y";
    const URI: vector<u8> = b"ipfs://bafybeiee6ziwznlaullflnzeqpvvdtweb7pehp572xcafkwawvtun2me4y";

    use main::und::{Self, UNDCapability, UNDCollectionCapability};
    use main::admin::{Self};

    use main::token_lock::{Self, TokenLockCapability};


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_token_lock(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100);
        assert!(und::und_balance(creator_addr) == 100, 0);

        let deposit_amount = 40;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        assert!(und::und_balance(creator_addr) == 60, 0);
        timestamp::update_global_time_for_test(101_000);   
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = ECLIFF_NOT_PASSED, location = main::token_lock)]
    public fun test_claim_before_cliff(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100);
        assert!(und::und_balance(creator_addr) == 100, 0);

        let deposit_amount = 40;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        assert!(und::und_balance(creator_addr) == 60, 0);
        timestamp::update_global_time_for_test(50_000);
        token_lock::claim(user1, 0)
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_claim_after_cliff(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100_000_000);
        assert!(und::und_balance(creator_addr) == 100_000_000, 0);

        let deposit_amount = 40_000_000;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        assert!(und::und_balance(creator_addr) == 60_000_000, 0);
        timestamp::update_global_time_for_test(300_000);
        token_lock::claim(user1, 0);
        assert!(und::und_balance(user1_addr) == 40_000_000, 0);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_claim_multiple(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100_000_000);
        assert!(und::und_balance(creator_addr) == 100_000_000, 0);

        let deposit_amount = 40_000_000;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        timestamp::update_global_time_for_test(110_000);
        token_lock::claim(user1, 0);
        assert!(und::und_balance(user1_addr) == 4_000_000, 0);
        timestamp::update_global_time_for_test(120_000);
        token_lock::claim(user1, 0);
        timestamp::update_global_time_for_test(130_000);
        token_lock::claim(user1, 0);
        timestamp::update_global_time_for_test(140_000);
        token_lock::claim(user1, 0);
        timestamp::update_global_time_for_test(150_000);
        token_lock::claim(user1, 0);
        timestamp::update_global_time_for_test(300_000);
        token_lock::claim(user1, 0);
        assert!(und::und_balance(user1_addr) == 40_000_000, 0);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_add_multiple_locks(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100_000_000);
        assert!(und::und_balance(creator_addr) == 100_000_000, 0);

        let deposit_amount = 1_000_000;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        let locks = token_lock::get_token_locks_by_token_address(und::und_token_address());
        assert!(vector::length(&locks) == 15, 0);
        let claimant_locks = token_lock::get_token_locks_by_user(claimant_address);
        let user2_locks = token_lock::get_token_locks_by_user(user2_addr);
        assert!(vector::length(&claimant_locks) == 4, 0);
        assert!(vector::length(&user2_locks) == 11, 0);

    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = EPERIOD_NOT_PASSED, location = main::token_lock)]
    public fun test_claim_period_not_passed(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100_000_000);
        assert!(und::und_balance(creator_addr) == 100_000_000, 0);

        let deposit_amount = 40_000_000;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, user2_addr 
            );
        timestamp::update_global_time_for_test(110_000);
        token_lock::claim(user1, 0);
        assert!(und::und_balance(user1_addr) == 4_000_000, 0);
        token_lock::claim(user1, 0);
        
        timestamp::update_global_time_for_test(120_000);
        
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = EINVALID_DATA, location = main::token_lock)]
    public fun test_wrong_claimant(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        token_lock::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100);

        let deposit_amount = 40;
        let cliff_timestamp = 100_000;
        let vesting_duration = 100_000;
        let periodicity = 1000;
        let claimant_address = user1_addr;

        token_lock::add_token_lock(
            creator, und::und_token_address(),
            deposit_amount, cliff_timestamp,
            vesting_duration, periodicity, claimant_address 
            );
        timestamp::update_global_time_for_test(200_000);
        token_lock::claim(user2, 0)
    }

    // #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    // public fun test_und_mint_100m(
    //     creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    // ) {
    //     assert!(signer::address_of(creator) == @main, 0);

    //     und::initialize_for_test(creator);

    //     let user1_addr = signer::address_of(user1);
    //     let creator_addr = signer::address_of(creator);

    //     und::mint_und(creator, 100_000_000);

    //     assert!(und::und_balance(creator_addr) == 100_000_000, 0);
    // }

    // #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    // #[expected_failure(abort_code = 131077, location = aptos_framework::fungible_asset)]
    // public fun test_und_mint_excess(
    //     creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    // ) {
    //     assert!(signer::address_of(creator) == @main, 0);

    //     und::initialize_for_test(creator);

    //     let user1_addr = signer::address_of(user1);
    //     let creator_addr = signer::address_of(creator);

    //     und::mint_und(creator, 100_000_001);

    //     assert!(und::und_balance(creator_addr) == 100_000_001, 0);
    // }

    // #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    // public fun test_set_token_name(
    //     creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    // ) {
    //     und::initialize_for_test(creator);
    //     let creator_addr = signer::address_of(creator);
    //     let user1_addr = signer::address_of(user1);
    //     let user2_addr = signer::address_of(user2);

    //     und::mint_und(creator, 50);

    //     let und_token = object::address_to_object<UNDCapability>(und::und_token_address());

    //     assert!(token::name(und_token) == string::utf8(UND_TOKEN_NAME), EINVALID_DATA);
    //     let new_name = string::utf8(b"New Token Name");
    //     und::set_token_name(creator, new_name);
    //     assert!(token::name(und_token) == new_name, EINVALID_DATA);

    //     assert!(token::uri(und_token) == string::utf8(URI), EINVALID_DATA);
    //     let new_uri = string::utf8(b"www.google.com");
    //     und::set_token_uri(creator, new_uri);
    //     assert!(token::uri(und_token) == new_uri, EINVALID_DATA);
    // }

    // #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    // public fun test_set_collection(
    //     creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    // ) {
    //     und::initialize_for_test(creator);


    //     let creator_addr = signer::address_of(creator);
    //     let user1_addr = signer::address_of(user1);
    //     let user2_addr = signer::address_of(user2);

    //     und::mint_und(creator, 50);

    //     let und_collection = object::address_to_object<UNDCollectionCapability>(
    //         und::und_collection_address()
    //     );

    //     assert!(
    //         collection::uri(und_collection) == string::utf8(UND_COLLECTION_URI),
    //         EINVALID_DATA,
    //     );
    //     let new_uri = string::utf8(b"https://new_google.com");
    //     und::set_collection_uri(creator, new_uri);
    //     assert!(collection::uri(und_collection) == new_uri, EINVALID_DATA);

    //     assert!(
    //         collection::description(und_collection)
    //         == string::utf8(UND_COLLECTION_DESCRIPTION),
    //         EINVALID_DATA,
    //     );
    //     let new_description = string::utf8(b"This is a new description!!!");
    //     und::set_collection_description(creator, new_description);
    //     assert!(collection::description(und_collection) == new_description, EINVALID_DATA);
    // }
}
