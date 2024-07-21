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
    use main::admin;

    const EINVALID_COLLECTION: u64 = 1;
    const ECLAIM_FIRST: u64 = 2;

    // #[test_only]
    // friend main::random_mint_test;

    // #[test_only]
    // friend main::spin_wheel_test;

    // Error Codes


    const EUNABLE_TO_CLAIM: u64 = 6;

    // 1 Day
    const TIME_BETWEEN_SPINS: u64 = 24 * 60 * 60 * 1_000_000;


    struct SpinCapability has key, store {
        address_map: SimpleMap<address, NftSpinInfo>,
        spin_result_table: SmartTable<u64, u64>,
    }

    struct NftSpinInfo has store, copy, drop {
        spin_result: u64,
        day_index: u8,
        timestamp: u64
    }

    fun init_module(deployer: &signer) {
        let address_map = aptos_std::simple_map::new<address, NftSpinInfo>();
        let spin_result_table = aptos_std::smart_table::new<u64, u64>();
        let address_map = SpinCapability { address_map: address_map, spin_result_table};
        move_to(deployer, address_map);
    }

    #[randomness]
    entry fun spin_wheel(user: &signer) acquires SpinCapability {
        let user_addr = signer::address_of(user);
        assert!(able_to_spin(user_addr), ECLAIM_FIRST);
        let spin_result_table_length = spin_result_table_length();
        let random_number = randomness::u64_range(0, spin_result_table_length);
        let user_addr = signer::address_of(user);
        debug::print(&utf8(b"spin random number was:"));
        debug::print(&random_number);
        
        let spin_capability = borrow_global_mut<SpinCapability>(@main);
        let address_map = spin_capability.address_map;
        let nft_spin_info = simple_map::borrow(&address_map,&user_addr);
        let rewards = *smart_table::borrow(&spin_capability.spin_result_table, random_number);

        let day_index = nft_spin_info.day_index;

        if (day_index == 2){
            main::leaderboard::add_score(user_addr, rewards * 2);
            day_index = day_index + 1;
        } else if (day_index == 6){
            main::leaderboard::add_score(user_addr, rewards * 3);
            day_index = 0;
        } else{
            main::leaderboard::add_score(user_addr, rewards);
            day_index = day_index + 1;
        };

        let new_nft_spin_info = NftSpinInfo {
            spin_result: random_number,
            day_index: day_index,
            timestamp: timestamp::now_microseconds()
        };
        aptos_std::simple_map::upsert(&mut address_map, user_addr, new_nft_spin_info);
    }

    public(friend) entry fun add_result_entry(caller:&signer, key: u64, reward:u64) acquires SpinCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let spin_capability = borrow_global_mut<SpinCapability>(@main);
        let spin_result_table = &mut spin_capability.spin_result_table;
        smart_table::add(spin_result_table,key,reward);
    }

    public(friend) entry fun clear_table(caller:&signer) acquires SpinCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let spin_capability = borrow_global_mut<SpinCapability>(@main);
        smart_table::clear(&mut spin_capability.spin_result_table);
    }

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

    #[view]
    public fun spin_reward(key:u64): u64 acquires SpinCapability {
        let spin_capability = borrow_global<SpinCapability>(@main);
        let reward = *smart_table::borrow(&spin_capability.spin_result_table,key);
        reward
    }

    // Testing functions
    #[test_only]
    public fun initialize_for_testing(creator: &signer) {
        init_module(creator);
    }

}
