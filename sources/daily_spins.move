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
    use std::vector;

    use main::admin;

    const EINVALID_COLLECTION: u64 = 1;
    const EUNABLE_TO_SPIN: u64 = 2;

    // #[test_only]
    // friend main::random_mint_test;

    #[test_only]
    friend main::leaderboard_test;

    // Error Codes


    const EUNABLE_TO_CLAIM: u64 = 6;

    // 1 Day
    // const TIME_BETWEEN_SPINS: u64 = 24 * 60 * 60 * 1_000_000;
    const TIME_BETWEEN_SPINS: u64 = 60 * 1_000_000;


    #[event]
    struct DailySpinEvent has drop, store {
        receiver: address,
        random_number: u64,
        reward: u64
    }

    struct SpinData has key, store {
        address_map: SimpleMap<address, LastSpinInfo>,
        spin_result_table: SmartTable<u64, u64>,
    }

    struct LastSpinInfo has store, copy, drop {
        spin_result: u64,
        day_index: u8,
        timestamp: u64
    }

    fun init_module(deployer: &signer) {
        let address_map = aptos_std::simple_map::new<address, LastSpinInfo>();
        let spin_result_table = aptos_std::smart_table::new<u64, u64>();
        let address_map = SpinData { address_map: address_map, spin_result_table};
        move_to(deployer, address_map);
    }

    #[randomness]
    entry fun spin_wheel(user: &signer) acquires SpinData {
        let user_addr = signer::address_of(user);
        assert!(able_to_spin(user_addr), EUNABLE_TO_SPIN);
        let spin_result_table_length = spin_result_table_length();
        let random_number = randomness::u64_range(0, spin_result_table_length);
        let user_addr = signer::address_of(user);
        debug::print(&utf8(b"spin random number was:"));
        debug::print(&random_number);
        
        let spin_capability = borrow_global_mut<SpinData>(@main);

        let user_spin_info;
        if (!simple_map::contains_key(&spin_capability.address_map, &user_addr)){
            user_spin_info = LastSpinInfo {
                spin_result: 0,
                day_index: 0,
                timestamp: 0 
            }
        } else{
            user_spin_info = *simple_map::borrow(&spin_capability.address_map,&user_addr);
        };
        let rewards = *smart_table::borrow(&spin_capability.spin_result_table, random_number);
        let total_rewards = rewards;
        let day_index = user_spin_info.day_index;

        if (day_index == 2){
            total_rewards = rewards * 2;
            day_index = day_index + 1;
        } else if (day_index == 6){
            total_rewards = rewards * 3;
            day_index = 0;
        } else{
            day_index = day_index + 1;
        };

        main::leaderboard::add_score(user_addr, total_rewards);

         let event = DailySpinEvent {
            receiver: user_addr,
            random_number: random_number, 
            reward: total_rewards
        };
     
        0x1::event::emit(event);

        let new_spin_info = LastSpinInfo {
            spin_result: random_number,
            day_index: day_index,
            timestamp: timestamp::now_microseconds()
        };
        // debug::print(&new_spin_info.spin_result);
        // debug::print(&new_spin_info.day_index);
        // debug::print(&new_spin_info.timestamp);

        aptos_std::simple_map::upsert(&mut spin_capability.address_map, user_addr, new_spin_info);

    }

    public(friend) entry fun add_result_entry(caller:&signer, key: u64, reward:u64) acquires SpinData{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let spin_capability = borrow_global_mut<SpinData>(@main);
        let spin_result_table = &mut spin_capability.spin_result_table;
        smart_table::add(spin_result_table,key,reward);
    }

    public(friend) entry fun clear_table(caller:&signer) acquires SpinData{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let spin_capability = borrow_global_mut<SpinData>(@main);
        smart_table::clear(&mut spin_capability.spin_result_table);
    }

    // View function
    #[view]
    public fun able_to_spin(user_addr: address): bool acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        let address_map = spin_capability.address_map;

        let output = false;

        let contains_key = aptos_std::simple_map::contains_key(&address_map, &user_addr);
        if (!contains_key) {
            output = true;
        } else {
            let nft_spin_info: LastSpinInfo = *aptos_std::simple_map::borrow(&address_map, &user_addr);
            if (timestamp::now_microseconds() > nft_spin_info.timestamp + TIME_BETWEEN_SPINS) {
                output = true;
            }
            else {
                output = false
            };

        };
        output
    }

    #[view]
    public fun spin_result_table_length(): u64 acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        // let spin_result_table = spin_capability.spin_result_table;
        let length = aptos_std::smart_table::length(&spin_capability.spin_result_table);
        length
    }

    #[view]
    public fun spin_rewards(): vector<u64> acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        let length = aptos_std::smart_table::length(&spin_capability.spin_result_table);
        let results = vector::empty<u64>();
        let i = 0;
        while (i < length) {
            let rewardElement = spin_reward(i);
            vector::push_back(&mut results, rewardElement);
            i = i + 1;
        };
        results
    }

    #[view]
    public fun spin_reward(key:u64): u64 acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        let reward = *smart_table::borrow(&spin_capability.spin_result_table,key);
        reward
    }

    #[view]
    public fun previous_spin_result(user_addr:address): u64 acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        if (!simple_map::contains_key(&spin_capability.address_map, &user_addr)){
            0
        }else{
            let spin_info = *simple_map::borrow(&spin_capability.address_map,&user_addr);
            spin_info.spin_result
        }
    }

    #[view]
    public fun previous_spin_time(user_addr:address): u64 acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        if (!simple_map::contains_key(&spin_capability.address_map, &user_addr)){
            0
        }else{
            let spin_info = *simple_map::borrow(&spin_capability.address_map,&user_addr);
            spin_info.timestamp
        }
    }

  
    #[view]
    public fun last_spin_info(user_addr:address): (u64,u8,u64) acquires SpinData {
        let spin_capability = borrow_global<SpinData>(@main);
        if (!simple_map::contains_key(&spin_capability.address_map, &user_addr)){
            let output = LastSpinInfo{
                spin_result: 0,
                day_index: 0,
                timestamp: 0
            };
            (output.spin_result, output.day_index, output.timestamp)
        }else{
            let spin_info = *simple_map::borrow(&spin_capability.address_map,&user_addr);
            (spin_info.spin_result, spin_info.day_index, spin_info.timestamp)

        }
    }

    // Testing functions
    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test_only]
    public fun spin_wheel_for_test(caller: &signer) acquires SpinData {
        spin_wheel(caller);
    }

}
