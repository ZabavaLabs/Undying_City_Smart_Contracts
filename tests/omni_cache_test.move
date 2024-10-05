 #[test_only]
module main::omni_cache_test{
    // use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object;
    // use aptos_std::smart_table::{Self, SmartTable};
    // use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::timestamp;
    use aptos_framework::block;
    use aptos_framework::account;



    // use aptos_token_objects::collection;
    // use aptos_token_objects::token::{Self, Token};
    // use aptos_token_objects::property_map;

    // use std::error;
    // use std::option;
    use std::signer;
   
    use std::string::{Self};
    // use aptos_std::string_utils::{to_string};


    use main::eigen_shard::{Self, EigenShardCapability};
    use main::omni_cache;
    use main::admin;
    use main::equipment;

    use aptos_framework::randomness;
    #[test_only]
    use aptos_std::crypto_algebra::enable_cryptography_algebra_natives;

    const EINVALID_TABLE_LENGTH: u64 = 1;
    const EWHITELIST_AMOUNT: u64 = 2;
    const EINVALID_SPECIAL_EVENT_DETAIL: u64 = 3;


    const EEVENT_ID_NOT_FOUND: u64 = 4;
    const EINVALID_DATA: u64 = 5;



    const EINSUFFICIENT_BALANCE: u64 = 65540;


    #[test(creator = @main)]
    public fun initialize_omni_cache_for_test_2(creator: &signer) {
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_event_addition_to_table(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);

        // randomness::initialize_for_testing(aptos_framework);
        // randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        let timestamp: u64 = timestamp::now_microseconds();

        let event_name = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let creator_addr = signer::address_of(creator);
        
        
        omni_cache::modify_special_event_struct(creator, event_name, timestamp, timestamp + 100_000_000);
        omni_cache::upsert_whitelist_address(creator, signer::address_of(user1),5);

        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==5, EWHITELIST_AMOUNT);
        omni_cache::upsert_whitelist_address(creator, signer::address_of(user1),10);
        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==10, EWHITELIST_AMOUNT);
       
        let event_name_2 = string::utf8(b"Second Mint Event");
        let new_start_time = timestamp + 200_000_000;
        let new_end_time = timestamp + 300_000_000;

        omni_cache::reset_event_and_add_addresses(creator, event_name_2, 
            new_start_time, new_end_time, 
            vector[user1_addr, user2_addr, user3_addr], vector[1,2,3]);
        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==1, EWHITELIST_AMOUNT);
        assert!(omni_cache::get_special_event_struct_amount(user2_addr)==2, EWHITELIST_AMOUNT);
        assert!(omni_cache::get_special_event_struct_amount(user3_addr)==3, EWHITELIST_AMOUNT);
        assert!(omni_cache::get_special_event_struct_amount(creator_addr)==0, EWHITELIST_AMOUNT);
        let (returned_event_name, returned_start_time, returned_end_time) = omni_cache::get_special_event_struct_details();
        assert!(returned_event_name ==event_name_2, EINVALID_SPECIAL_EVENT_DETAIL);
        assert!(returned_start_time ==new_start_time, EINVALID_SPECIAL_EVENT_DETAIL);
        assert!(returned_end_time ==new_end_time, EINVALID_SPECIAL_EVENT_DETAIL);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(arithmetic_error, location = aptos_framework::randomness)]
    public fun test_unlock_cache_no_equipment_added(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let _ = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        eigen_shard::mint_shard(creator,100);
        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        omni_cache::unlock_cache(creator);
        
        // omni_cache::unlock_cache(creator, shard_token);
   
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_multiple_equipment_added_to_cache(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        let timestamp: u64 = timestamp::now_microseconds();

        let event_name = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let creator_addr = signer::address_of(creator);
        
        
        omni_cache::modify_special_event_struct(creator, event_name, timestamp, timestamp + 100_000_000);
        omni_cache::upsert_whitelist_address(creator, signer::address_of(user1),5);

        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==5, EWHITELIST_AMOUNT);
        omni_cache::upsert_whitelist_address(creator, signer::address_of(user1),10);
        assert!(omni_cache::get_special_event_struct_amount(user1_addr)==10, EWHITELIST_AMOUNT);
       
        let event_name_2 = string::utf8(b"Second Mint Event");
        let new_start_time = timestamp + 200_000_000;
        let new_end_time = timestamp + 300_000_000;
        
        assert!(omni_cache::get_table_length_from_cache(0)==0, EINVALID_TABLE_LENGTH);
        assert!(omni_cache::get_table_length_from_cache(1)==0, EINVALID_TABLE_LENGTH);

        omni_cache::add_equipment_to_cache(creator,0,0);
        omni_cache::add_equipment_to_cache(creator,0,1);
        assert!(omni_cache::get_table_length_from_cache(0)==2, EINVALID_TABLE_LENGTH);

        omni_cache::reset_cache_and_add_equipment_ids(creator, 0, vector[0,1,2,3,4], vector[0,1,2,3,4]);
        assert!(omni_cache::get_table_length_from_cache(0)==5, EINVALID_TABLE_LENGTH);

        omni_cache::add_equipment_to_cache(creator,1,0);
        omni_cache::add_equipment_to_cache(creator,1,1);
        assert!(omni_cache::get_table_length_from_cache(1)==2, EINVALID_TABLE_LENGTH);

        omni_cache::reset_cache_and_add_equipment_ids(creator, 1, vector[0,1,2,3,4,5,6], vector[0,1,2,3,4,5,6]);
        assert!(omni_cache::get_table_length_from_cache(1)==7, EINVALID_TABLE_LENGTH);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        eigen_shard::mint_shard(user1,500);
        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment 2"), 
        string::utf8(b"Equipment Description 2"),
        string::utf8(b"Equipment uri 2"),
        equipment_part_id,
        affinity_id,
        grade,
        120, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment 3"), 
        string::utf8(b"Equipment Description 3"),
        string::utf8(b"Equipment uri 3"),
        equipment_part_id,
        affinity_id,
        grade,
        130, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::add_equipment_to_cache(creator, 0, 1);
        omni_cache::add_equipment_to_cache(creator, 0, 2);

        omni_cache::unlock_cache(user1);
        omni_cache::unlock_cache(user1);
        omni_cache::unlock_cache(user1);

        assert!(eigen_shard::shard_balance(user1_addr) == 200, 0);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 9, location = main::eigen_shard)]
    public fun test_unlock_cache_insufficient_shard(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let _ = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        eigen_shard::mint_shard(user1, 2);
        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::unlock_cache(user1);
        omni_cache::unlock_cache(user1);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache_via_event(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);

        omni_cache::upsert_whitelist_address(creator, user1_addr, 2);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,10000 );
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);


    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache_via_event_2(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 1"), 
        string::utf8(b"Equipment Description 1"),
        string::utf8(b"Equipment uri 1"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 2"), 
        string::utf8(b"Equipment Description 2"),
        string::utf8(b"Equipment uri 2"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 3"), 
        string::utf8(b"Equipment Description 3"),
        string::utf8(b"Equipment uri 3"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 4"), 
        string::utf8(b"Equipment Description 4"),
        string::utf8(b"Equipment uri 4"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::add_equipment_to_cache(creator, 0, 1);
        omni_cache::add_equipment_to_cache(creator, 0, 2);
        omni_cache::add_equipment_to_cache(creator, 1, 3);


        omni_cache::add_whitelist_addresses(creator, vector[user1_addr,user2_addr,user3_addr], vector[2,3,4]);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,10000 );
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);

        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);
        // omni_cache::unlock_cache_via_event(user3);
        // omni_cache::unlock_cache_via_event(user3);
        // omni_cache::unlock_cache_via_event(user3);
        // omni_cache::unlock_cache_via_event(user3);
    }


    
    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache_x10(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework,100_00_000_000);
        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);


        eigen_shard::mint_shard(user1,5000);
        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment 2"), 
        string::utf8(b"Equipment Description 2"),
        string::utf8(b"Equipment uri 2"),
        equipment_part_id,
        affinity_id,
        grade,
        120, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment 3"), 
        string::utf8(b"Equipment Description 3"),
        string::utf8(b"Equipment uri 3"),
        equipment_part_id,
        affinity_id,
        grade,
        130, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::add_equipment_to_cache(creator, 0, 1);
        omni_cache::add_equipment_to_cache(creator, 0, 2);

        omni_cache::unlock_cache_10x(user1);
        assert!(eigen_shard::shard_balance(user1_addr) == 4120, 0);
        omni_cache::unlock_cache_10x(user1);
        assert!(eigen_shard::shard_balance(user1_addr) == 3240, 0);

    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_modify_omni_cache(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let (shards_to_mint, normal_weight, special_weight)  = omni_cache::get_omni_cache_data();
        assert!(shards_to_mint==100,1);
        assert!(normal_weight==100,1);
        assert!(special_weight==0,1);
        omni_cache::modify_omni_cache_data(creator,50,30,22);
        (shards_to_mint, normal_weight, special_weight)  = omni_cache::get_omni_cache_data();
        assert!(shards_to_mint==50,1);
        assert!(normal_weight==30,1);
        assert!(special_weight==22,1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_modify_omni_cache_mint(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 1"), 
        string::utf8(b"Equipment Description 1"),
        string::utf8(b"Equipment uri 1"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 2"), 
        string::utf8(b"Equipment Description 2"),
        string::utf8(b"Equipment uri 2"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 3"), 
        string::utf8(b"Equipment Description 3"),
        string::utf8(b"Equipment uri 3"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name 4"), 
        string::utf8(b"Equipment Description 4"),
        string::utf8(b"Equipment uri 4"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::add_equipment_to_cache(creator, 0, 1);
        omni_cache::add_equipment_to_cache(creator, 0, 2);
        omni_cache::add_equipment_to_cache(creator, 1, 3);


        omni_cache::add_whitelist_addresses(creator, vector[user1_addr,user2_addr,user3_addr], vector[200,300,400]);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,10000 );
        omni_cache::modify_omni_cache_data(creator,1,0,30);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);
        omni_cache::unlock_cache_via_event(user2);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=6, location=main::omni_cache)]
    public fun test_unlock_extra_cache_via_event(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);

        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);

        omni_cache::upsert_whitelist_address(creator, user1_addr, 2);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,10000 );
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
        omni_cache::unlock_cache_via_event(user1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=8, location=main::omni_cache)]
    public fun test_unlock_cache_via_event_past_time(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        omni_cache::add_equipment_to_cache(creator, 0, 0);

        omni_cache::upsert_whitelist_address(creator, user1_addr, 2);
        omni_cache::modify_special_event_struct(creator, string::utf8(b"Mint Event"),0,500 );
        omni_cache::unlock_cache_via_event(user1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_unlock_cache_view_function(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        equipment::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        account::create_account_for_test(@aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
        block::initialize_for_test(aptos_framework, 5);
        
        let _: u64 = timestamp::now_microseconds();
        let _ = string::utf8(b"First Mint Event");
        let user1_addr = signer::address_of(user1);
        let _ = signer::address_of(user2);
        let _ = signer::address_of(user3);
        let _ = signer::address_of(creator);
        
        timestamp::update_global_time_for_test(1000);

        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);


        assert!(omni_cache::get_table_length_from_cache(0)==0,EINVALID_DATA);

        omni_cache::add_equipment_to_cache(creator, 0, 0);
        omni_cache::add_equipment_to_cache(creator, 0, 1);
        omni_cache::add_equipment_to_cache(creator, 0, 2);
        omni_cache::add_equipment_to_cache(creator, 0, 3);

        omni_cache::add_equipment_to_cache(creator, 1, 0);
        omni_cache::add_equipment_to_cache(creator, 1, 1);



        assert!(omni_cache::get_equipment_id_from_cache_row_id(0, 0)==0,EINVALID_DATA);
        assert!(omni_cache::get_equipment_id_from_cache_row_id(0, 1)==1,EINVALID_DATA);
        assert!(omni_cache::get_equipment_id_from_cache_row_id(0, 2)==2,EINVALID_DATA);
        assert!(omni_cache::get_equipment_id_from_cache_row_id(0, 3)==3,EINVALID_DATA);
        assert!(omni_cache::get_equipment_id_from_cache_row_id(1, 0)==0,EINVALID_DATA);
        assert!(omni_cache::get_equipment_id_from_cache_row_id(1, 1)==1,EINVALID_DATA);

    }
}