module main::omni_cache{

    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};


    // use std::error;
    // use std::option;
    use std::signer;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;

   
    use std::string::{Self, String};
    // use aptos_std::string_utils::{to_string};

    use main::eigen_shard::{Self, EigenShardCapability};
    use main::admin::{Self};
    use main::equipment;
    use aptos_framework::randomness;


    #[test_only]
    friend main::omni_cache_test;


    const ENOT_OWNER: u64 = 2;
    const EEVENT_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;

    const EMAX_LEVEL: u64 = 7;
    const EINVALID_PERIOD: u64 = 8;

    const EINSUFFICIENT_BALANCE: u64 = 65540;
    
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct OmniCacheData has key {
        shards_to_unlock_cache: u64,
        normal_equipment_weight: u64,
        special_equipment_weight: u64
    }
   
    struct SpecialEventsInfoEntry has key, store, copy, drop {
        name: String,
        start_time: u64,
        end_time: u64,
        whitelist_map: SimpleMap<address, u64>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct SpecialEvents has key {
        special_events_table: SmartTable<u64, SpecialEventsInfoEntry>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct NormalEquipmentCacheData has key {
        table: SmartTable<u64, u64>
    }
  
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct SpecialEquipmentCacheData has key {
        table: SmartTable<u64, u64>
    }


    fun init_module(account: &signer){
        let special_events_table = aptos_std::smart_table::new();
        let special_events = SpecialEvents{
            special_events_table: special_events_table
        };
        move_to(account, special_events);

        let special_events_info_entry = SpecialEventsInfoEntry{
            name: string::utf8(b"First Mint Event"),
            start_time: 0,
            end_time: 0,
            whitelist_map: simple_map::new<address,u64>()
        };
        move_to(account,special_events_info_entry);

        let omni_cache_data = OmniCacheData{
            shards_to_unlock_cache: 100,
            normal_equipment_weight: 100,
            special_equipment_weight: 0,
        };
        move_to(account, omni_cache_data);
    
        let normal_equipment_cache_table = smart_table::new();
        let normal_equipment_cache_data = NormalEquipmentCacheData{
            table: normal_equipment_cache_table
        };
        move_to(account, normal_equipment_cache_data);

        let special_equipment_cache_table = smart_table::new();
        let special_equipment_cache_data = SpecialEquipmentCacheData{
            table: special_equipment_cache_table
        };
        move_to(account, special_equipment_cache_data);
    }
    
    // public entry fun add_special_event(account:&signer, name: String, start_time:u64, end_time:u64) acquires SpecialEvents{
    //     let account_addr = signer::address_of(account);
    //     admin::assert_is_admin(account_addr);

    //     let special_events_table = &mut borrow_global_mut<SpecialEvents>(@main).special_events_table;
    //     let table_length = aptos_std::smart_table::length(special_events_table);

    //     let whitelist_map = simple_map::new<address,u64>();

    //     let special_events_info_entry = SpecialEventsInfoEntry{
    //         name,
    //         start_time,
    //         end_time,
    //         whitelist_map: whitelist_map
    //     };

    //     smart_table::add(special_events_table, table_length, special_events_info_entry);
    // }

  
    #[randomness]
    public(friend) entry fun unlock_cache(account:&signer) acquires OmniCacheData, SpecialEquipmentCacheData, NormalEquipmentCacheData{
        let omni_cache_data = borrow_global<OmniCacheData>(@main);
        let shards_spend = omni_cache_data.shards_to_unlock_cache;
        let shard_object = object::address_to_object(eigen_shard::shard_token_address());
        eigen_shard::burn_shard(account, shard_object, shards_spend);
        random_mint(account);
    }

    #[randomness]
    public(friend) entry fun unlock_cache_10x(account:&signer) acquires OmniCacheData, SpecialEquipmentCacheData, NormalEquipmentCacheData{
        let omni_cache_data = borrow_global<OmniCacheData>(@main);
        // TODO: Temporary adjust this to 20 for testing. Final should be 880
        // let shards_spend = 20;
        let shards_spend = omni_cache_data.shards_to_unlock_cache * 10 - 120; 

        let shard_object = object::address_to_object(eigen_shard::shard_token_address());
        eigen_shard::burn_shard(account, shard_object, shards_spend);
        for (i in 0..10) {
            random_mint(account);
        };
    }

    #[randomness]
    public(friend) entry fun unlock_cache_via_event(account:&signer) acquires OmniCacheData, SpecialEquipmentCacheData, NormalEquipmentCacheData, SpecialEventsInfoEntry{
        let omni_cache_data = borrow_global<OmniCacheData>(@main);
        
        let account_addr = signer::address_of(account);
        let amount_available_to_mint = get_special_event_struct_amount(account_addr);
        assert!(amount_available_to_mint > 0, EINVALID_BALANCE);
        

        let (_, start_time, end_time) = get_special_event_struct_details();
        let current_timestamp: u64 = timestamp::now_microseconds();

        assert!(current_timestamp >= start_time, EINVALID_PERIOD);
        assert!(current_timestamp <= end_time, EINVALID_PERIOD);
        
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        
        simple_map::upsert(&mut special_events_info_entry.whitelist_map, account_addr, amount_available_to_mint - 1);

        random_mint(account);
    }

    public entry fun add_equipment_to_cache(account:&signer, cache_id:u64, equipment_id:u64) acquires NormalEquipmentCacheData, SpecialEquipmentCacheData{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);

        if (cache_id == 0){
            let normal_equipment_cache_table = &mut borrow_global_mut<NormalEquipmentCacheData>(@main).table;
            let normal_equipment_cache_table_length:u64 = aptos_std::smart_table::length(normal_equipment_cache_table);
            smart_table::add(normal_equipment_cache_table, normal_equipment_cache_table_length, equipment_id);
            
        } else if (cache_id == 1){
            let special_equipment_cache_table = &mut borrow_global_mut<SpecialEquipmentCacheData>(@main).table;
            let special_equipment_cache_table_length:u64 = aptos_std::smart_table::length(special_equipment_cache_table);
            smart_table::add(special_equipment_cache_table, special_equipment_cache_table_length, equipment_id);
        }
       
    }

    public entry fun modify_special_event_struct(account:&signer, name: String, start_time:u64, end_time:u64) acquires SpecialEventsInfoEntry{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);
        assert!(end_time > start_time, EINVALID_PERIOD);
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        special_events_info_entry.name = name;
        special_events_info_entry.start_time = start_time;
        special_events_info_entry.end_time = end_time;
    }

    public entry fun upsert_whitelist_address(account:&signer, modify_address:address, amount: u64) acquires SpecialEventsInfoEntry{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        simple_map::upsert(&mut special_events_info_entry.whitelist_map, modify_address, amount);
    }

    public entry fun add_whitelist_addresses(account:&signer, address_vector:vector<address>, amount_vector: vector<u64>) acquires  SpecialEventsInfoEntry{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        simple_map::add_all(&mut special_events_info_entry.whitelist_map, address_vector, amount_vector);
    }

    public entry fun reset_event_and_add_addresses(account:&signer, name: String, start_time:u64, end_time:u64, address_vector:vector<address>, amount_vector: vector<u64>) acquires  SpecialEventsInfoEntry{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);
        let special_events_info_entry = borrow_global_mut<SpecialEventsInfoEntry>(@main);
        special_events_info_entry.name = name;
        special_events_info_entry.start_time = start_time;
        special_events_info_entry.end_time = end_time;
        special_events_info_entry.whitelist_map = simple_map::new<address,u64>();
        simple_map::add_all(&mut special_events_info_entry.whitelist_map, address_vector, amount_vector);
    }

    public entry fun reset_cache_and_add_equipment_ids(account:&signer, cache_id:u64, row_id_vector:vector<u64>, equipment_id_vector:vector<u64>) acquires NormalEquipmentCacheData, SpecialEquipmentCacheData{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);
        if (cache_id == 0){
            let normal_equipment_cache_table = &mut borrow_global_mut<NormalEquipmentCacheData>(@main).table;
            smart_table::clear(normal_equipment_cache_table);
            // assert!(smart_table::length(normal_equipment_cache_table)==0, EINVALID_TABLE_LENGTH);
            smart_table::add_all(normal_equipment_cache_table, row_id_vector, equipment_id_vector);
        } else if( cache_id == 1){
            let special_equipment_cache_table = &mut borrow_global_mut<SpecialEquipmentCacheData>(@main).table;
            smart_table::clear(special_equipment_cache_table);
            // assert!(smart_table::length(special_equipment_cache_table)==0, EINVALID_TABLE_LENGTH);
            smart_table::add_all(special_equipment_cache_table, row_id_vector, equipment_id_vector);
        } 
    }

    public entry fun modify_omni_cache_data(account:&signer, shards_to_unlock_cache:u64, normal_equipment_weight:u64, special_equipment_weight:u64) acquires OmniCacheData{
        let account_addr = signer::address_of(account);
        admin::assert_is_admin(account_addr);
        let omni_cache_data = borrow_global_mut<OmniCacheData>(@main);
        omni_cache_data.shards_to_unlock_cache = shards_to_unlock_cache;
        omni_cache_data.normal_equipment_weight = normal_equipment_weight;
        omni_cache_data.special_equipment_weight = special_equipment_weight;

    }

    fun random_mint(account:&signer) acquires OmniCacheData, SpecialEquipmentCacheData, NormalEquipmentCacheData{
        let omni_cache_data = borrow_global<OmniCacheData>(@main);
        let account_addr = signer::address_of(account);
        let normal_equipment_weight = omni_cache_data.normal_equipment_weight;
        let special_equipment_weight = omni_cache_data.special_equipment_weight;

        let random_number = randomness::u64_range(1, normal_equipment_weight + special_equipment_weight + 1);
        if (random_number <= normal_equipment_weight){
            let normal_equipment_cache_table = &borrow_global<NormalEquipmentCacheData>(@main).table;
            let normal_equipment_cache_table_length:u64 = aptos_std::smart_table::length(normal_equipment_cache_table);
            let row_id = randomness::u64_range(0, normal_equipment_cache_table_length);

            let random_equipment_id:u64 = *smart_table::borrow(normal_equipment_cache_table, row_id);
            equipment::mint_equipment(account, random_equipment_id);
        } else{
            let special_equipment_cache_table = &borrow_global<SpecialEquipmentCacheData>(@main).table;
            let special_equipment_cache_table_length:u64 = aptos_std::smart_table::length(special_equipment_cache_table);
            let row_id = randomness::u64_range(0, special_equipment_cache_table_length);

            let random_equipment_id:u64 = *smart_table::borrow(special_equipment_cache_table, row_id);
            equipment::mint_equipment(account, random_equipment_id);
        }
    }

    #[view]
    public fun get_special_event_struct_amount(query_address:address):u64 acquires SpecialEventsInfoEntry{
        let special_events_info_entry = borrow_global<SpecialEventsInfoEntry>(@main);
        let whitelist_map = special_events_info_entry.whitelist_map;
        if (simple_map::contains_key(&whitelist_map, &query_address))
        {
            *simple_map::borrow(&whitelist_map, &query_address)
        } else{
            0u64
        }
    }

    #[view]
    public fun get_special_event_struct_details():(String, u64, u64) acquires SpecialEventsInfoEntry{
        let special_events_info_entry = borrow_global<SpecialEventsInfoEntry>(@main);
        (special_events_info_entry.name, special_events_info_entry.start_time, special_events_info_entry.end_time)
    }

    #[view]
    public fun get_equipment_id_from_cache_row_id(cache_id:u64, row_id: u64): u64 acquires SpecialEquipmentCacheData, NormalEquipmentCacheData{
        if (cache_id == 0){
            let normal_equipment_cache_table = &borrow_global<NormalEquipmentCacheData>(@main).table;
            let equipment_id = *smart_table::borrow(normal_equipment_cache_table, row_id);
            equipment_id
        } else if( cache_id == 1){
            let special_equipment_cache_table = &borrow_global<SpecialEquipmentCacheData>(@main).table;
            let equipment_id = *smart_table::borrow(special_equipment_cache_table, row_id);
            equipment_id
        } else{
            18_446_744_073_709_551_615
        }
    }

    #[view]
    public fun get_table_length_from_cache(cache_id:u64): u64 acquires SpecialEquipmentCacheData, NormalEquipmentCacheData{
        if (cache_id == 0){
            let normal_equipment_cache_table = &borrow_global<NormalEquipmentCacheData>(@main).table;
            smart_table::length(normal_equipment_cache_table)
        } else if( cache_id == 1){
            let special_equipment_cache_table = &borrow_global<SpecialEquipmentCacheData>(@main).table;
            smart_table::length(special_equipment_cache_table)

        } else{
            18_446_744_073_709_551_615
        }
    }

    #[view]
    public fun get_omni_cache_data():(u64, u64, u64) acquires OmniCacheData{
        let omni_cache_data = borrow_global<OmniCacheData>(@main);
        (omni_cache_data.shards_to_unlock_cache, omni_cache_data.normal_equipment_weight, omni_cache_data.special_equipment_weight)
    }

    // ANCHOR Test Functions
    #[test_only]
    public fun initialize_for_test(account: &signer){
        init_module(account);
    }


}