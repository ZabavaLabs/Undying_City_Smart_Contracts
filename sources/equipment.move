module main::equipment{

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::simple_map::{Self, SimpleMap};


    use aptos_token_objects::collection;
    use aptos_token_objects::token::{Self, Token};
    use aptos_token_objects::royalty::{Self, Royalty};
    use aptos_token_objects::property_map;

    // use aptos_framework::fungible_asset::{Self, Metadata};
    // use aptos_framework::primary_fungible_store;

    // use std::error;
    use std::option;
    use std::signer;
    use std::vector;
    use std::bcs;
    // use std::signer::address_of;
    use std::string::{Self, String};
    // use aptos_std::string_utils::{to_string};

    use main::eigen_shard::{Self, EigenShardCapability};

    use main::admin::{Self, ENOT_ADMIN};
    use main::omni_cache;

    // use std::debug::print;
    // use std::vector;

    friend omni_cache;

    #[test_only]
    friend main::equipment_test;

    const ENOT_OWNER: u64 = 2;
    const ECHAR_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EMAX_LEVEL: u64 = 7;
    const EINVALID_COLLECTION: u64 = 8;
    const EINVALID_EQUIPMENT: u64 = 9;
    const EINSUFFICIENT_BALANCE: u64 = 65540;
    

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentData has key {
        max_equipment_level: u64
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentCapability has key {
        mutator_ref: token::MutatorRef,
        burn_ref: token::BurnRef,
        property_mutator_ref: property_map::MutatorRef,
    }

    struct EquipmentInfoEntry has store, copy, drop {
        name: String,
        description: String,
        uri: String,
        equipment_id: u64,
        equipment_part_id:u64,
        affinity_id: u64,
        grade: u64,
        hp:u64,
        atk:u64,
        def:u64,
        atk_spd:u64,
        mv_spd:u64,
        growth_hp:u64,
        growth_atk:u64,
        growth_def:u64,
        growth_atk_spd:u64,
        growth_mv_spd:u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentInfo has key {
        table: SmartTable<u64, EquipmentInfoEntry>
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentEnhanceInfo has key {
        map: SimpleMap<String, String>
    }

    // Tokens require a signer to create, so this is the signer for the collection
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct ResourceCapability has key, drop {
        capability: SignerCapability,
        burn_signer_capability: SignerCapability,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct EquipmentCollectionCapability has key {
        collection_mutator_ref: collection::MutatorRef
    }

    #[event]
    struct EquipmentMintEvent has drop, store {
        receiver: address,
        token_address: address, 
        equipment_id: u64,
        name: String,
        uri: String,
        equipment_part_id: u64,
        affinity_id: u64,
        grade: u64,
    }

    #[event]
    struct EquipmentEnhanceEvent has drop, store {
        token_address: address, 
        equipment_id: u64,
        uri: String,
        grade: u64,
        hp: u64,
        atk: u64,
        def: u64,
        atk_spd: u64,
        mv_spd: u64
    }

    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_EQUIPMENT_COLLECTION_NAME: vector<u8> = b"Undying City Equipment Collection";
    const UC_EQUIPMENT_COLLECTION_DESCRIPTION: vector<u8> = b"Contains all the Undying City equipment";
    const UC_EQUIPMENT_UPGRADE_SEED: vector<u8> = b"UC_EQUIPMENT_UPGRADE_SEED";
    
    const ROYALTY_ADDRESS: address = @main;

    const UC_EQUIPMENT_COLLECTION_URI: vector<u8> = b"ipfs://bafybeiau6cmsuglb6gtdp3g3rnmzvvjfchfsvpzcthnpg7kzfyofy4qwt4";
   
    fun init_module(account: &signer) {
        let (signer_resource, token_signer_cap) = account::create_resource_account(
            account,
            APP_SIGNER_CAPABILITY_SEED,
        );
        let (_, burn_signer_capability) = account::create_resource_account(
            account,
            BURN_SIGNER_CAPABILITY_SEED,
        );

        let description = string::utf8(UC_EQUIPMENT_COLLECTION_DESCRIPTION);
        let name = string::utf8(UC_EQUIPMENT_COLLECTION_NAME);
        let uri = string::utf8(UC_EQUIPMENT_COLLECTION_URI);

        let collection_signer = create_equipment_collection(&signer_resource, description, name, uri);
        
        move_to(&collection_signer, ResourceCapability {
            capability: token_signer_cap,
            burn_signer_capability,
        });

        
        let equipment_info_table = aptos_std::smart_table::new();

        let equipment_info = EquipmentInfo{
            table: equipment_info_table
        };
        move_to(&collection_signer, equipment_info);

        let gameData =  EquipmentData{
            max_equipment_level: 50
        };

        move_to(&collection_signer, gameData);
    }

    public(friend) entry fun init_upgrade_equipment_capability(account: &signer) {
        let caller_address = signer::address_of(account);
        admin::assert_is_admin(caller_address);
        let (object_signer, signer_cap) = account::create_resource_account(account, UC_EQUIPMENT_UPGRADE_SEED);

        move_to(&object_signer, EquipmentEnhanceInfo {
            map: simple_map::new(),
        });
    }

    public entry fun set_max_weapon_level(caller: &signer, new_max_level: u64) acquires  EquipmentData {
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let game_data = borrow_global_mut< EquipmentData>(equipment_collection_address());
        game_data.max_equipment_level = new_max_level;
    }

    fun get_token_signer(): signer acquires ResourceCapability {
        account::create_signer_with_capability(&borrow_global<ResourceCapability>(equipment_collection_address()).capability)
    }

    fun create_equipment_collection(signer_resource: &signer, description: String, name: String, uri: String): signer {
        let expected_royalty = royalty::create(5_000, 100_000, ROYALTY_ADDRESS);
        let collection_constructor_ref = collection::create_unlimited_collection(
            signer_resource,
            description,
            name,
            option::some(expected_royalty),
            uri,
        );
        let object_signer = object::generate_signer(&collection_constructor_ref);
        let collection_mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);

        let collection_capability = EquipmentCollectionCapability{
            collection_mutator_ref
        };

        move_to(&object_signer, collection_capability);
        object_signer
    }

    public(friend) fun mint_equipment(user: &signer, equipment_id: u64) acquires ResourceCapability, EquipmentInfo {
        assert!(equipment_id_exists(equipment_id), ECHAR_ID_NOT_FOUND);
        let equipment_info_entry = get_equipment_info_entry(equipment_id);        
        let level = 1;
        let equipment_token = create_equipment(user, 
        equipment_id, equipment_info_entry.name, 
        equipment_info_entry.description, equipment_info_entry.uri, 
        equipment_info_entry.equipment_part_id, equipment_info_entry.affinity_id,
        equipment_info_entry.grade, level,
        equipment_info_entry.hp, 
        equipment_info_entry.atk, equipment_info_entry.def,
        equipment_info_entry.atk_spd, equipment_info_entry.mv_spd,
        equipment_info_entry.growth_hp, 
        equipment_info_entry.growth_atk, equipment_info_entry.growth_def,
        equipment_info_entry.growth_atk_spd, equipment_info_entry.growth_mv_spd
        );
        let address = signer::address_of(user);
        let event = EquipmentMintEvent {
            receiver: address,
            token_address: object::object_address(&equipment_token), 
            equipment_id: equipment_id,
            name: equipment_info_entry.name,
            uri: equipment_info_entry.uri,
            equipment_part_id: equipment_info_entry.equipment_part_id,
            affinity_id: equipment_info_entry.affinity_id,
            grade: equipment_info_entry.grade,
            // level: level,
            // hp: equipment_info_entry.hp,
            // atk: equipment_info_entry.atk,
            // def: equipment_info_entry.def,
            // atk_spd: equipment_info_entry.atk_spd,
            // mv_spd: equipment_info_entry.mv_spd,
            // growth_hp: equipment_info_entry.growth_hp,
            // growth_atk: equipment_info_entry.growth_atk,
            // growth_def: equipment_info_entry.growth_def,
            // growth_atk_spd: equipment_info_entry.growth_atk_spd,
            // growth_mv_spd: equipment_info_entry.growth_mv_spd,
        };
     
        0x1::event::emit(event);
  
    }

    fun create_equipment(
        user: &signer, 
        equipment_id: u64, token_name: String, 
        token_description: String, token_uri: String, 
        equipment_part_id: u64, affinity_id: u64,
        grade: u64, level:u64,
        hp: u64, atk: u64, def: u64,
        atk_spd: u64, mv_spd: u64,
        growth_hp: u64, growth_atk: u64, growth_def: u64,
        growth_atk_spd: u64, growth_mv_spd: u64
    ): Object<EquipmentCapability> acquires ResourceCapability {

        let constructor_ref = token::create(
            &get_token_signer(),
            string::utf8(UC_EQUIPMENT_COLLECTION_NAME),
            token_description,
            token_name,
            option::none(),
            token_uri,
        );

        let token_signer = object::generate_signer(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);
        let burn_ref = token::generate_burn_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Initialize the property map.
        // name: String,
        // description: String,
        // uri: String,
        // equipment_id: u64,
        // equipment_part_id: u64,
        // affinity_id: u64,
        // grade: u64,
        // hp:u64,
        // atk:u64,
        // def:u64,
        // atk_spd:u64,
        // mv_spd:u64,
        // growth_hp:u64,
        // growth_atk:u64,
        // growth_def:u64,
        // growth_atk_spd:u64,
        // growth_mv_spd:u64,

        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"EQUIPMENT_ID"),
            equipment_id
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"EQUIPMENT_PART_ID"),
            equipment_part_id
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"AFFINITY_ID"),
            affinity_id
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GRADE"),
            grade
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"LEVEL"),
            level
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"HP"),
            hp
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"ATK"),
            atk
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"DEF"),
            def
        );

        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"ATK_SPD"),
            atk_spd
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"MV_SPD"),
            mv_spd
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_HP"),
            growth_hp
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_ATK"),
            growth_atk
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_DEF"),
            growth_def
        );

        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_ATK_SPD"),
            growth_atk_spd
        );
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"GROWTH_MV_SPD"),
            growth_mv_spd
        );

        let new_equipment = EquipmentCapability {
            mutator_ref,
            burn_ref,
            property_mutator_ref
        };

        move_to(&token_signer, new_equipment);
        let created_token = object::object_from_constructor_ref<Token>(&constructor_ref);
        object::transfer(&get_token_signer() , created_token, signer::address_of(user));
        object::address_to_object(signer::address_of(&token_signer))
    }
   
    // TODO: Need to remove friend for testnet because signature
    public(friend) entry fun upgrade_equipment(from: &signer, equipment_object: Object<EquipmentCapability>, amount: u64) acquires EquipmentCapability,  EquipmentData {
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        assert!(amount>0, EINVALID_PROPERTY_VALUE);
        let collection = token::collection_object(equipment_object);
        assert!(object::object_address(&collection) == equipment_collection_address(), EINVALID_COLLECTION);
        let shard_object = object::address_to_object(eigen_shard::shard_token_address());
        let equipment_token_address = object::object_address(&equipment_object);
        let equipment = borrow_global_mut<EquipmentCapability>(equipment_token_address);
        // Gets `property_mutator_ref` to update the attack point in the property map.
        let property_mutator_ref = &equipment.property_mutator_ref;
        // Updates the attack point in the property map.
        let current_lvl = property_map::read_u64(&equipment_object, &string::utf8(b"LEVEL"));
        let cost = 10/2 * amount * (current_lvl + current_lvl + amount -1);
        eigen_shard::burn_shard(from, shard_object, cost);
        // Prevents upgrading beyond a certain level.
        let game_data = borrow_global< EquipmentData>(equipment_collection_address());
        assert!( current_lvl + amount <= game_data.max_equipment_level, EMAX_LEVEL);

        let current_hp = property_map::read_u64(&equipment_object, &string::utf8(b"HP"));
        let current_atk = property_map::read_u64(&equipment_object, &string::utf8(b"ATK"));
        let current_def = property_map::read_u64(&equipment_object, &string::utf8(b"DEF"));
        let current_atk_spd = property_map::read_u64(&equipment_object, &string::utf8(b"ATK_SPD"));
        let current_mv_spd = property_map::read_u64(&equipment_object, &string::utf8(b"MV_SPD"));

        let growth_hp = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_HP"));
        let growth_atk = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_ATK"));
        let growth_def = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_DEF"));
        let growth_atk_spd = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_ATK_SPD"));
        let growth_mv_spd = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_MV_SPD"));

        property_map::update_typed(property_mutator_ref, &string::utf8(b"LEVEL"), current_lvl + (amount));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"HP"), current_hp + (amount * growth_hp));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK"), current_atk + (amount * growth_atk));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"DEF"), current_def + (amount * growth_def));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK_SPD"), current_atk_spd + (amount * growth_atk_spd));
        property_map::update_typed(property_mutator_ref, &string::utf8(b"MV_SPD"), current_mv_spd + (amount * growth_mv_spd));
    }

    public(friend) entry fun enhance_equipment(from: &signer, equipment_object: Object<EquipmentCapability>, equipment_object_to_destroy: Object<EquipmentCapability>) acquires EquipmentCapability, EquipmentEnhanceInfo, ResourceCapability {
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        assert!(object::is_owner(equipment_object_to_destroy, signer::address_of(from)), ENOT_OWNER);
        
        let collection = token::collection_object(equipment_object);
        let collection2 = token::collection_object(equipment_object_to_destroy);

        assert!(object::object_address(&collection) == equipment_collection_address(), EINVALID_COLLECTION);
        assert!(object::object_address(&collection2) == equipment_collection_address(), EINVALID_COLLECTION);

        let shard_object = object::address_to_object(eigen_shard::shard_token_address());

        // Reads the some values of the property map.
        let current_lvl = property_map::read_u64(&equipment_object, &string::utf8(b"LEVEL"));
        let current_grade = property_map::read_u64(&equipment_object, &string::utf8(b"GRADE"));
        let current_grade_2 = property_map::read_u64(&equipment_object_to_destroy, &string::utf8(b"GRADE"));

        let equipment_id = property_map::read_u64(&equipment_object, &string::utf8(b"EQUIPMENT_ID"));
        let current_equipment_id_2 = property_map::read_u64(&equipment_object_to_destroy, &string::utf8(b"EQUIPMENT_ID"));
        assert!(equipment_id == current_equipment_id_2, EINVALID_EQUIPMENT);
        assert!(current_grade == current_grade_2, EINVALID_EQUIPMENT);

        assert!( current_grade + 1 < 6, EMAX_LEVEL);

        // Burning and destroying
        let cost = current_grade * 300;
        eigen_shard::burn_shard(from, shard_object, cost);
        destroy_equipment(from, equipment_object_to_destroy);

        // Property Mutation
        let current_hp = property_map::read_u64(&equipment_object, &string::utf8(b"HP"));
        let current_atk = property_map::read_u64(&equipment_object, &string::utf8(b"ATK"));
        let current_def = property_map::read_u64(&equipment_object, &string::utf8(b"DEF"));
        let current_atk_spd = property_map::read_u64(&equipment_object, &string::utf8(b"ATK_SPD"));
        let current_mv_spd = property_map::read_u64(&equipment_object, &string::utf8(b"MV_SPD"));

        let growth_hp = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_HP"));
        let growth_atk = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_ATK"));
        let growth_def = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_DEF"));
        let growth_atk_spd = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_ATK_SPD"));
        let growth_mv_spd = property_map::read_u64(&equipment_object, &string::utf8(b"GROWTH_MV_SPD"));
       
        let equipment_token_address = object::object_address(&equipment_object);
        let equipment = borrow_global_mut<EquipmentCapability>(equipment_token_address);
        let property_mutator_ref = &equipment.property_mutator_ref;
        let amount = 10;

        let new_grade = current_grade + 1;
        let new_hp = current_hp + (amount * growth_hp);
        let new_atk = current_atk + (amount * growth_atk);
        let new_def = current_def + (amount * growth_def);
        let new_atk_spd = current_atk_spd + (amount * growth_atk_spd);
        let new_mv_spd = current_mv_spd + (amount * growth_mv_spd);
        property_map::update_typed(property_mutator_ref, &string::utf8(b"HP"), new_hp);
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK"), new_atk);
        property_map::update_typed(property_mutator_ref, &string::utf8(b"DEF"), new_def);
        property_map::update_typed(property_mutator_ref, &string::utf8(b"ATK_SPD"), new_atk_spd);
        property_map::update_typed(property_mutator_ref, &string::utf8(b"MV_SPD"), new_mv_spd);
        property_map::update_typed(property_mutator_ref, &string::utf8(b"GRADE"), new_grade);

        let equipment_upgrade_info = borrow_global_mut<EquipmentEnhanceInfo>(equipment_upgrade_info_address());
        let equipment_upgrade_map = equipment_upgrade_info.map;

        let next_grade = current_grade + 1;
        let equipment_bytes = bcs::to_bytes(&equipment_id);
        let next_grade_bytes = bcs::to_bytes(&next_grade);

        let key_string = string::utf8(equipment_bytes);
        string::append(&mut key_string, string::utf8(b"_"));
        string::append(&mut key_string, string::utf8(next_grade_bytes));
        let new_uri = *simple_map::borrow(&equipment_upgrade_map, &key_string);

        let mutator_ref = &equipment.mutator_ref;
        token::set_uri(mutator_ref, new_uri);

        let event = EquipmentEnhanceEvent {
            token_address: object::object_address(&equipment_object), 
            equipment_id: equipment_id,
            uri: new_uri,
            grade: new_grade,
            hp: new_hp,
            atk: new_atk,
            def: new_def,
            atk_spd: new_atk_spd,
            mv_spd: new_mv_spd
        };
        0x1::event::emit(event);
    }
    
    public entry fun destroy_equipment(from: &signer, equipment_object: Object<EquipmentCapability>) acquires EquipmentCapability, ResourceCapability{
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        object::transfer(from , equipment_object, capability_address());
        burn_equipment(&get_token_signer(), equipment_object);
    }

    fun burn_equipment(from: &signer, equipment_object: Object<EquipmentCapability>) acquires EquipmentCapability{
        assert!(object::is_owner(equipment_object, signer::address_of(from)), ENOT_OWNER);
        let equipment_token = move_from<EquipmentCapability>(object::object_address(&equipment_object));
        let EquipmentCapability {
            mutator_ref,
            burn_ref,
            property_mutator_ref
        } = equipment_token;
        token::burn(burn_ref);
        
    }

    public entry fun set_collection_uri(caller: &signer, new_uri: String) acquires EquipmentCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<EquipmentCollectionCapability>(equipment_collection_address());
        collection::set_uri(&collection_capability.collection_mutator_ref, new_uri);
    }

    public entry fun set_collection_description(caller: &signer, new_description: String) acquires EquipmentCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<EquipmentCollectionCapability>(equipment_collection_address());
        collection::set_description(&collection_capability.collection_mutator_ref, new_description);
    }

    // ANCHOR Aptos Utility Functions

    public entry fun add_equipment_entry(
        account: &signer, 
        name: String, 
        description: String, 
        uri: String,
        equipment_part_id: u64,
        affinity_id: u64, 
        grade: u64,
        hp: u64, 
        atk: u64,
        def: u64, 
        atk_spd: u64, 
        mv_spd: u64,
        growth_hp:u64,
        growth_atk:u64,
        growth_def:u64,
        growth_atk_spd:u64,
        growth_mv_spd:u64,
        ) acquires EquipmentInfo {

        admin::assert_is_admin(signer::address_of(account));

        let equipment_info_table = &mut borrow_global_mut<EquipmentInfo>(equipment_collection_address()).table;
        let table_length = aptos_std::smart_table::length(equipment_info_table);
        let equipment_info_entry = EquipmentInfoEntry{
            name,
            description,
            uri,
            equipment_id: table_length,
            equipment_part_id,
            affinity_id,
            grade,
            hp,
            atk,
            def,
            atk_spd,
            mv_spd,
            growth_hp,
            growth_atk,
            growth_def,
            growth_atk_spd,
            growth_mv_spd,
        };
        smart_table::add(equipment_info_table, table_length, equipment_info_entry);
    }

    public entry fun set_equipment_entry(
        account: &signer, 
        equipment_id: u64,
        name: String, 
        description: String, 
        uri: String,
        equipment_part_id: u64,
        affinity_id: u64, 
        grade: u64,
        hp: u64, 
        atk: u64,
        def: u64, 
        atk_spd: u64, 
        mv_spd: u64,
        growth_hp:u64,
        growth_atk:u64,
        growth_def:u64,
        growth_atk_spd:u64,
        growth_mv_spd:u64,
        ) acquires EquipmentInfo {

        admin::assert_is_admin(signer::address_of(account));

        let equipment_info_table = &mut borrow_global_mut<EquipmentInfo>(equipment_collection_address()).table;
       

        let equipment_info_entry = EquipmentInfoEntry{
            name,
            description,
            uri,
            equipment_id: equipment_id,
            equipment_part_id,
            affinity_id,
            grade,
            hp,
            atk,
            def,
            atk_spd,
            mv_spd,
            growth_hp,
            growth_atk,
            growth_def,
            growth_atk_spd,
            growth_mv_spd,
        };
        smart_table::upsert(equipment_info_table, equipment_id, equipment_info_entry);
    }

    public entry fun clear_equipment_info_table(
        account: &signer, 
        ) acquires EquipmentInfo {
        admin::assert_is_admin(signer::address_of(account));

        let equipment_info_table = &mut borrow_global_mut<EquipmentInfo>(equipment_collection_address()).table;
        smart_table::clear(equipment_info_table);
    }

    public entry fun upsert_equipment_enhancement_info(
        account: &signer, 
        equipment_id: u64,
        grade: u64,
        new_url: String
        ) acquires EquipmentEnhanceInfo {

        admin::assert_is_admin(signer::address_of(account));

        let equipment_upgrade_info_map = &mut borrow_global_mut<EquipmentEnhanceInfo>(equipment_upgrade_info_address()).map;
       
        let equipment_bytes = bcs::to_bytes(&equipment_id);
        let grade_bytes = bcs::to_bytes(&grade);

        let key_string = string::utf8(equipment_bytes);
        string::append(&mut key_string, string::utf8(b"_"));
        string::append(&mut key_string, string::utf8(grade_bytes));
        simple_map::upsert(equipment_upgrade_info_map, key_string, new_url);
    }

    public entry fun add_all_equipment_enhancement_info(
        account: &signer, 
        equipment_id_vector: vector<u64>,
        grade_vector: vector<u64>,
        new_url_vector: vector<String>
        ) acquires EquipmentEnhanceInfo {

        admin::assert_is_admin(signer::address_of(account));

        let equipment_upgrade_info_map = &mut borrow_global_mut<EquipmentEnhanceInfo>(equipment_upgrade_info_address()).map;
       
        let string_vector = vector::empty<string::String>();
        let i = 0;
        let length = vector::length(&equipment_id_vector);

        while (i < length) {
            let equipment_id = vector::borrow(&equipment_id_vector,i);
            let grade = vector::borrow(&grade_vector,i);

            let equipment_bytes = bcs::to_bytes(equipment_id);
            let grade_bytes = bcs::to_bytes(grade);
            
            let key_string = string::utf8(equipment_bytes);
            string::append(&mut key_string, string::utf8(b"_"));
            string::append(&mut key_string, string::utf8(grade_bytes));
            vector::push_back(&mut string_vector, key_string);
            i = i + 1;
        };

        simple_map::add_all(equipment_upgrade_info_map, string_vector, new_url_vector);
    }

    public entry fun remove_equipment_upgrade_info(
        account: &signer, 
        equipment_id: u64,
        grade: u64
        ) acquires EquipmentEnhanceInfo {

        admin::assert_is_admin(signer::address_of(account));

        let equipment_upgrade_info_map = &mut borrow_global_mut<EquipmentEnhanceInfo>(equipment_upgrade_info_address()).map;
       
        let equipment_bytes = bcs::to_bytes(&equipment_id);
        let grade_bytes = bcs::to_bytes(&grade);

        let key_string = string::utf8(equipment_bytes);
        string::append(&mut key_string, string::utf8(b"_"));
        string::append(&mut key_string, string::utf8(grade_bytes));
        simple_map::remove(equipment_upgrade_info_map, &key_string);
    }

    // ANCHOR Aptos View Functions
    #[view]
    public fun equipment_id_exists(equipment_id: u64): bool acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(equipment_collection_address()).table;
        smart_table::contains(equipment_info_table, equipment_id)
    }

    #[view]
    public fun capability_address(): address {
        account::create_resource_address(&@main, APP_SIGNER_CAPABILITY_SEED)
    }

    #[view]
    public fun equipment_collection_address(): address {
        // collection_create(&capability_address(), UC_EQUIPMENT_COLLECTION_NAME)
        collection::create_collection_address(&capability_address(), &string::utf8(UC_EQUIPMENT_COLLECTION_NAME))
    }

    #[view]
    public fun equipment_upgrade_info_address(): address {
        // collection_create(&capability_address(), UC_EQUIPMENT_COLLECTION_NAME)
        // collection::create_collection_address(&capability_address(), &string::utf8(UC_EQUIPMENT_COLLECTION_NAME))
        account::create_resource_address(&@main, UC_EQUIPMENT_UPGRADE_SEED)
    }

    #[view]
    public fun get_equipment_info_entry(equipment_id: u64): EquipmentInfoEntry acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(equipment_collection_address()).table;
        *smart_table::borrow(equipment_info_table, equipment_id)
    }

    #[view]
    public fun get_equipment_table_length(): u64 acquires EquipmentInfo {
        let equipment_info_table = &borrow_global<EquipmentInfo>(equipment_collection_address()).table;
        aptos_std::smart_table::length(equipment_info_table)
    } 


    // ANCHOR TESTING

   
    // TODO: Viewing Function of properties of object
    // TODO: Test if properties of minted equipment is the same as that stored in table.
    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test_only]
    public fun create_equipment_for_test(
        user: &signer, 
        equipment_id: u64, token_name: String, 
        token_description: String, token_uri: String, 
        equipment_part_id: u64, affinity_id: u64,
        grade: u64, level:u64,
        hp: u64, atk: u64, def: u64,
        atk_spd: u64, mv_spd: u64,
        growth_hp: u64, growth_atk: u64, growth_def: u64,
        growth_atk_spd: u64, growth_mv_spd: u64
    ): Object<EquipmentCapability> acquires ResourceCapability{
        create_equipment(
        user, 
        equipment_id, token_name,
        token_description, token_uri, 
        equipment_part_id, affinity_id,
        grade, level,
        hp, atk, def,
        atk_spd, mv_spd,
        growth_hp, growth_atk, growth_def,
        growth_atk_spd, growth_mv_spd)
    }
 
    #[test_only]
    public fun mint_equipment_for_test(user: &signer, equipment_id: u64) acquires ResourceCapability, EquipmentInfo {
        mint_equipment(user,equipment_id);
    }

}