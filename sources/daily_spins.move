module main::daily_spins {

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use std::string::{Self, String};
    use aptos_framework::randomness;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_token_objects::property_map;

    use aptos_framework::timestamp;

    use std::string::utf8;
    use aptos_std::debug;
    use aptos_std::debug::print;

    use std::option;
    use std::signer;

    const EINVALID_COLLECTION: u64 = 1;
    const ECLAIM_FIRST: u64 = 2;

    // #[test_only]
    // friend main::random_mint_test;

    // #[test_only]
    // friend main::spin_wheel_test;

    // Error Codes
    const ENOT_DEPLOYER: u64 = 1;
    const ENOT_OWNER: u64 = 2;
    const ENFT_ID_NOT_FOUND: u64 = 3;
    const EUNABLE_TO_MINT: u64 = 4;
    const EWEIGHT_ZERO: u64 = 5;
    const EUNABLE_TO_CLAIM: u64 = 6;

    // const MINT_FEE:u64 = 1_000_000;
    // 1 Day
    const TIME_BETWEEN_SPINS: u64 = 24 * 60 * 60 * 1_000_000;

    const SPIN_SLOTS: u64 = 6;
    const PRIZE_1: u64 = 1_000_000;
    const PRIZE_2: u64 = 2_000_000;
    const PRIZE_3_NFT_ID: u64 = 1;
    const PRIZE_4_NFT_ID_1: u64 = 2;
    const PRIZE_4_NFT_ID_2: u64 = 3;

    struct SpinCapability has key, store {
        address_map: SimpleMap<address, NftSpinInfo>,
        spin_result_table: SmartTable<u64, u64>,
    }

    struct NftSpinInfo has store, copy, drop {
        spin_result: u64,
        timestamp: u64
    }

    fun init_module(deployer: &signer) {
        let address_map = aptos_std::simple_map::new<address, NftSpinInfo>();
        let spin_result_table = aptos_std::smart_table::new<u64, u64>();
        let address_map = SpinCapability { address_map: address_map, spin_result_table};
        move_to(deployer, address_map);
    }

    // Commits the result of the randomness to a map.
    #[randomness]
    entry fun spin_wheel(user: &signer) acquires SpinCapability {
        let user_addr = signer::address_of(user);
        assert!(able_to_spin(user_addr), ECLAIM_FIRST);
        let spin_result_table_length = spin_result_table_length();
        let random_number = randomness::u64_range(0, spin_result_table_length);
        let user_addr = signer::address_of(user);
        debug::print(&utf8(b"spin random number was:"));
        debug::print(&random_number);

        let address_map = &mut borrow_global_mut<SpinCapability>(@main).address_map;
        let nft_spin_info = NftSpinInfo {
            spin_result: random_number,
            timestamp: timestamp::now_microseconds()
        };
        aptos_std::simple_map::upsert(address_map, user_addr, nft_spin_info);
    }

    // Claim Prize.
    // public(friend) entry fun claim_spin_prize(user: &signer, nft: Object<Token>) acquires SpinCapability {
    //     assert!(object::is_owner(nft, signer::address_of(user)), ENOT_OWNER);
    //     let prize_number = prize_number(nft);
    //     assert!(prize_number != 0, EUNABLE_TO_CLAIM);

    //     let nft_addr = object::object_address(&nft);

    //     // Perform the various actions depending prize number
    //     if (prize_number == 1) {
    //         coin::transfer<AptosCoin>(user, @main, PRIZE_1);
    //     }
    //     else if (prize_number == 2) {
    //         coin::transfer<AptosCoin>(user, @main, PRIZE_2);
    //     }
    //     else if (prize_number == 3) {
    //         let nft_info_name = random_mint::get_nft_name(PRIZE_3_NFT_ID);
    //         let nft_info_description = random_mint::get_nft_description(PRIZE_3_NFT_ID);
    //         let nft_info_uri = random_mint::get_nft_uri(PRIZE_3_NFT_ID);

    //         random_mint::create_nft(user, nft_info_name, nft_info_description, nft_info_uri,);
    //     }
    //     else if (prize_number == 4) {
    //         let nft_info_name = random_mint::get_nft_name(PRIZE_4_NFT_ID_1);
    //         let nft_info_description = random_mint::get_nft_description(PRIZE_4_NFT_ID_1);
    //         let nft_info_uri = random_mint::get_nft_uri(PRIZE_4_NFT_ID_1);

    //         random_mint::create_nft(user, nft_info_name, nft_info_description, nft_info_uri,);

    //         let nft_info_name_2 = random_mint::get_nft_name(PRIZE_4_NFT_ID_2);
    //         let nft_info_description_2 = random_mint::get_nft_description(PRIZE_4_NFT_ID_2);
    //         let nft_info_uri_2 = random_mint::get_nft_uri(PRIZE_4_NFT_ID_2);

    //         random_mint::create_nft(user, nft_info_name_2, nft_info_description_2,
    //             nft_info_uri_2,);

    //     };

    //     let simple_map = &mut borrow_global_mut<SpinCapability>(@main).simple_map;
    //     let nft_spin_info = aptos_std::simple_map::borrow_mut(simple_map, &nft_addr);
    //     nft_spin_info.spin_result = 0;
    // }

    // View function
    #[view]
    public fun able_to_spin(user_addr: address): bool acquires SpinCapability {
        let spin_capability = borrow_global<SpinCapability>(@main);
        let address_map = spin_capability.address_map;

        let output = false;

        let contains_key = aptos_std::simple_map::contains_key(&address_map, &user_addr);
        if (!contains_key) {
            output = true;
        } else {
            let nft_spin_info: NftSpinInfo = *aptos_std::simple_map::borrow(&address_map, &user_addr);
            if (timestamp::now_microseconds() > nft_spin_info.timestamp + TIME_BETWEEN_SPINS) {
                output = true;
            }
            else {
                output = false
            };

        };
        output
    }

    // #[view]
    // public fun able_to_claim_spin_prize(caller:&signer): bool acquires SpinCapability {
    //     let spin_capability = borrow_global<SpinCapability>(@main);
    //     let simple_map = spin_capability.simple_map;

    //     let collection = token::collection_object(nft);
    //     assert!(object::object_address(&collection) == random_mint::nft_collection_address(),
    //         EINVALID_COLLECTION);

    //     let output = false;
    //     let contains_key = aptos_std::simple_map::contains_key(&simple_map,caller);
    //     if (!contains_key) {
    //         output = false;
    //     } else {
    //         let nft_spin_info: NftSpinInfo = *aptos_std::simple_map::borrow(&simple_map, &nft_addr);
    //         if (nft_spin_info.spin_result != 0) {
    //             output = true;
    //         };
    //     };
    //     output
    // }

    // #[view]
    // public fun prize_number(nft: Object<Token>): u64 acquires SpinCapability {
    //     let address_map = borrow_global<SpinCapability>(@main);
    //     let simple_map = address_map.simple_map;

    //     let collection = token::collection_object(nft);
    //     assert!(object::object_address(&collection) == random_mint::nft_collection_address(),
    //         EINVALID_COLLECTION);
    //     let nft_addr = object::object_address(&nft);
    //     let output = 0;
    //     let contains_key = aptos_std::simple_map::contains_key(&simple_map, &nft_addr);
    //     if (!contains_key) {
    //         output = 0;
    //     } else {
    //         let nft_spin_info: NftSpinInfo = *aptos_std::simple_map::borrow(&simple_map, &nft_addr);
    //         output = nft_spin_info.spin_result;
    //     };
    //     output
    // }

     #[view]
    public fun spin_result_table_length(): u64 acquires SpinCapability {
        let spin_capability = borrow_global<SpinCapability>(@main);
        // let spin_result_table = spin_capability.spin_result_table;
        let length = aptos_std::smart_table::length(&spin_capability.spin_result_table);
        length
    }

    // Testing functions
    #[test_only]
    public fun initialize_for_testing(creator: &signer) {
        init_module(creator);
    }

}
