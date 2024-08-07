module main::equipment_test{

    use aptos_framework::object::{Self};

    use aptos_token_objects::collection;
    use aptos_token_objects::token;

    use aptos_token_objects::property_map::{Self};

    // use aptos_framework::fungible_asset::{Self, Metadata};
    // use aptos_framework::primary_fungible_store;

    // use std::error;
    use std::option;
    use std::signer::{Self};
    // use std::signer::address_of;
    use std::string::{Self};
    // use aptos_std::string_utils::{to_string};

    use main::eigen_shard::{Self, EigenShardCapability};

    use main::admin::{Self, ENOT_ADMIN};
    use main::equipment::{Self, EquipmentCollectionCapability, ResourceCapability, EquipmentInfo, EquipmentCapability};
    // use std::debug::print;
    // use std::vector;

    const ENOT_OWNER: u64 = 2;
    const ECHAR_ID_NOT_FOUND: u64 = 3;
    const EINVALID_TABLE_LENGTH: u64 = 4;
    const EINVALID_PROPERTY_VALUE: u64 = 5;
    const EINVALID_BALANCE: u64 = 6;
    const EMAX_LEVEL: u64 = 7;
    const EINVALID_COLLECTION: u64 = 8;
    const EINVALID_EQUIPMENT: u64 = 9;

    const EINVALID_DATA: u64 = 11;

    const EINSUFFICIENT_BALANCE: u64 = 65540;
    
    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"APP_SIGNER_CAPABILITY";
    const BURN_SIGNER_CAPABILITY_SEED: vector<u8> = b"BURN_SIGNER_CAPABILITY";
    const UC_EQUIPMENT_COLLECTION_NAME: vector<u8> = b"Undying City Equipment Collection";
    const UC_EQUIPMENT_COLLECTION_DESCRIPTION: vector<u8> = b"Contains all the Undying City equipment";
    
    const ROYALTY_ADDRESS: address = @main;

    // TODO: Change the equipment collection uri
    const UC_EQUIPMENT_COLLECTION_URI: vector<u8> = b"ipfs://bafybeiau6cmsuglb6gtdp3g3rnmzvvjfchfsvpzcthnpg7kzfyofy4qwt4";
   



    // ANCHOR TESTING

    #[test(creator = @main)]
    public fun test_equipment_addition_to_table(creator: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
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
        assert!(equipment::get_equipment_table_length()==2, EINVALID_TABLE_LENGTH)
    }

    #[test(creator = @main)]
    public fun test_equipment_addition_to_table_and_clear(creator: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
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
        assert!(equipment::get_equipment_table_length()==2, EINVALID_TABLE_LENGTH);
        equipment::clear_equipment_info_table(creator);
        assert!(equipment::get_equipment_table_length()==0, EINVALID_TABLE_LENGTH);
    }

    #[test(creator = @main, user1 = @0x456 )]
    #[expected_failure(abort_code = ENOT_ADMIN, location = main::admin)]
    public fun test_add_equipment_by_others(creator: &signer, user1: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        equipment::add_equipment_entry(user1, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
    }

    #[test(creator = @main, user1 = @0x456 )]
    public fun test_set_admin(creator: &signer, user1: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
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
        admin::set_admin(creator, signer::address_of(user1));
        equipment::add_equipment_entry(user1, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
    }

    #[test(creator = @main, user1 = @0x456 )]
    #[expected_failure(abort_code = ENOT_ADMIN)]
    public fun test_set_admin_2(creator: &signer, user1: &signer) {
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

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
        admin::set_admin(creator, signer::address_of(user1));
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);
    }

    #[test(creator = @main, user1 = @0x456)]
    public fun test_mint(creator: &signer, user1: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        let equipment_part_id = 1;
        let affinity_id = 2;
        let grade = 3;
        let level = 4;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 6, 7, 8);

        equipment::mint_equipment_for_test(user1, 0);

        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade, 
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);

        equipment::mint_equipment_for_test(user1, 1);

        let user_1_address = signer::address_of(user1);

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        assert!(object::is_owner(char1, user_1_address), ENOT_OWNER);


    }

    #[test(creator = @main, user1 = @0x456)]
    #[expected_failure(abort_code=ECHAR_ID_NOT_FOUND,location=main::equipment)]
    public fun test_mint_unlisted_equipment(creator: &signer, user1: &signer)  {
        equipment::initialize_for_test(creator);
        equipment::mint_equipment_for_test(user1, 1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment 1 Name"), 
            string::utf8(b"Equipment 1 Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 300);


        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let shard_balance = eigen_shard::shard_balance(user1_addr);

        assert!(shard_balance == 300, 0);

        equipment::upgrade_equipment(user1, char1, 6);

        assert!(eigen_shard::shard_balance(user1_addr) == 90, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==7, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"GROWTH_HP"))==10, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==160, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==40, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==41, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==42, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==80, EINVALID_PROPERTY_VALUE);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_multiple(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment 1 Description"),
            string::utf8(b"Equipment uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 6, 7, 8);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 100);


        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        assert!(eigen_shard::shard_balance(user1_addr) == 100, 0);

        equipment::upgrade_equipment(user1, char1, 1);

        assert!(eigen_shard::shard_balance(user1_addr) == 90, EINVALID_BALANCE);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==2, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==110, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==15, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==17, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==19, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==58, EINVALID_PROPERTY_VALUE);

        equipment::upgrade_equipment(user1, char1, 2);

        assert!(property_map::read_u64(&char1, &string::utf8(b"LEVEL"))==4, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"HP"))==130, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK"))==25, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"DEF"))==29, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"ATK_SPD"))==33, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&char1, &string::utf8(b"MV_SPD"))==74, EINVALID_PROPERTY_VALUE);

    }


    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=ENOT_OWNER, location=main::equipment)]
    public fun test_upgrade_equipment_wrong_ownership(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000);

        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        eigen_shard::mint_shard(user1, 10);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        equipment::upgrade_equipment(user2, char1 , 1);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_to_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);

        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        eigen_shard::mint_shard(user1, 20000);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        equipment::upgrade_equipment(user1, char1, 49);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code=EMAX_LEVEL, location=main::equipment)]
    public fun test_upgrade_equipment_past_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);

        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        eigen_shard::mint_shard(user1, 20000);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());

        equipment::upgrade_equipment(user1, char1, 50);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_upgrade_equipment_change_max_level(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer)  {
   
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);

        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let char1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 9000000);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let _ = eigen_shard::shard_balance(user1_addr);

        equipment::set_max_weapon_level(creator, 60);
        equipment::upgrade_equipment(user1, char1, 55);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_set_equipment_collection (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {
        
        admin::initialize_for_test(creator);
        equipment::initialize_for_test(creator);

        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);


        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;
        equipment::add_equipment_entry(creator, 
        string::utf8(b"Equipment Name"), 
        string::utf8(b"Equipment Description"),
        string::utf8(b"Equipment uri"),
        equipment_part_id,
        affinity_id,
        grade,
        100, 10, 11, 12, 50,
        10, 5, 5, 5, 5);


        let equipment_collection_capability = object::address_to_object<EquipmentCollectionCapability>(equipment::equipment_collection_address());
       
        assert!(collection::uri(equipment_collection_capability)==string::utf8(UC_EQUIPMENT_COLLECTION_URI), EINVALID_DATA);
        let new_uri = string::utf8(b"https://new_google.com");
        equipment::set_collection_uri(creator, new_uri);
        assert!(collection::uri(equipment_collection_capability)==new_uri,EINVALID_DATA);

        assert!(collection::description(equipment_collection_capability)==string::utf8(UC_EQUIPMENT_COLLECTION_DESCRIPTION),EINVALID_DATA);
        let new_description = string::utf8(b"This is a new description!!!");
        equipment::set_collection_description(creator, new_description);
        assert!(collection::description(equipment_collection_capability)==new_description,EINVALID_DATA);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_enhance_equipment (creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {       
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);
        equipment::init_upgrade_equipment_capability(creator);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let equip1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip2 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip3 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
                    
        let equip4 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 100000);
        assert!(token::uri(equip1)==string::utf8(b"Equipment Uri"), EINVALID_PROPERTY_VALUE);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let new_uri = string::utf8(b"NEW URL");
        equipment::upsert_equipment_enhancement_info(creator, 0, 2,  new_uri);
        equipment::enhance_equipment(user1, equip1, equip2);
        let shard_balance = eigen_shard::shard_balance(user1_addr);
        assert!(shard_balance == 99700, 0);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==2, EINVALID_PROPERTY_VALUE);
        assert!(!object::is_object(object::object_address(&equip2)), ENOT_OWNER);
        assert!(token::uri(equip1)==new_uri, EINVALID_PROPERTY_VALUE);
        
        
        let new_uri_3 = string::utf8(b"NEW URL 3");
        equipment::upsert_equipment_enhancement_info(creator, 0, 3,  new_uri_3);
        equipment::enhance_equipment(user1, equip3, equip4);
        equipment::enhance_equipment(user1, equip1, equip3);
        assert!(token::uri(equip1)==new_uri_3, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==3, EINVALID_PROPERTY_VALUE);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_enhance_equipment_max(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {       
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);
        equipment::init_upgrade_equipment_capability(creator);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let equip1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip2 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip3 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
                    
        let equip4 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 100000);
        assert!(token::uri(equip1)==string::utf8(b"Equipment Uri"), EINVALID_PROPERTY_VALUE);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let new_uri = string::utf8(b"NEW URL");
        equipment::upsert_equipment_enhancement_info(creator, 0, 2,  new_uri);
        equipment::enhance_equipment(user1, equip1, equip2);
        let shard_balance = eigen_shard::shard_balance(user1_addr);
        assert!(shard_balance == 99700, 0);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==2, EINVALID_PROPERTY_VALUE);
        assert!(!object::is_object(object::object_address(&equip2)), ENOT_OWNER);
        assert!(token::uri(equip1)==new_uri, EINVALID_PROPERTY_VALUE);
        
        
        let new_uri_3 = string::utf8(b"NEW URL 3");
        equipment::upsert_equipment_enhancement_info(creator, 0, 3,  new_uri_3);
        equipment::enhance_equipment(user1, equip3, equip4);
        equipment::enhance_equipment(user1, equip1, equip3);
        assert!(token::uri(equip1)==new_uri_3, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==3, EINVALID_PROPERTY_VALUE);


        let equip5 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            3, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let equip6 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            4, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let equip7 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            5, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let new_uri_4 = string::utf8(b"NEW URL 4");
        equipment::upsert_equipment_enhancement_info(creator, 0, 4,  new_uri_4);
        equipment::enhance_equipment(user1, equip1, equip5);
        let new_uri_5 = string::utf8(b"NEW URL 5");
        equipment::upsert_equipment_enhancement_info(creator, 0, 5,  new_uri_5);
        equipment::enhance_equipment(user1, equip1, equip6);
        assert!(token::uri(equip1)==new_uri_5, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==5, EINVALID_PROPERTY_VALUE);

        // let new_uri_6 = string::utf8(b"NEW URL 6");
        // equipment::upsert_equipment_enhancement_info(creator, 0, 5,  new_uri_5);
        // equipment::enhance_equipment(user1, equip1, equip7);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = EINVALID_EQUIPMENT, location = main::equipment)]
    public fun test_enhance_equipment_different_id(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {       
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);
        equipment::init_upgrade_equipment_capability(creator);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let equip1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip2 = equipment::create_equipment_for_test(user1, 1,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
      

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 100000);
        assert!(token::uri(equip1)==string::utf8(b"Equipment Uri"), EINVALID_PROPERTY_VALUE);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let new_uri = string::utf8(b"NEW URL");
        equipment::upsert_equipment_enhancement_info(creator, 0, 2,  new_uri);
        equipment::enhance_equipment(user1, equip1, equip2);
        let shard_balance = eigen_shard::shard_balance(user1_addr);
        assert!(shard_balance == 99700, 0);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==2, EINVALID_PROPERTY_VALUE);
        assert!(!object::is_object(object::object_address(&equip2)), ENOT_OWNER);
        assert!(token::uri(equip1)==new_uri, EINVALID_PROPERTY_VALUE);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_add_all_equipment_enhancement_info(creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer) {       
        equipment::initialize_for_test(creator);
        admin::initialize_for_test(creator);
        eigen_shard::setup_coin(creator, user1, user2, aptos_framework, 100_000_000_000_000);
        equipment::init_upgrade_equipment_capability(creator);
        eigen_shard::initialize_for_test(creator);
        let equipment_part_id = 1;
        let affinity_id = 1;
        let grade = 1;
        let level = 1;

        let equip1 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip2 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
        
        let equip3 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);
                    
        let equip4 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            grade, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let user1_addr = signer::address_of(user1);
        eigen_shard::mint_shard(user1, 100000);
        assert!(token::uri(equip1)==string::utf8(b"Equipment Uri"), EINVALID_PROPERTY_VALUE);

        let shard_token = object::address_to_object<EigenShardCapability>(eigen_shard::shard_token_address());
        let new_uri = string::utf8(b"NEW URL");
        equipment::add_all_equipment_enhancement_info(creator,vector[0,0,0,0,0], 
        vector[1,2,3,4,5], 
        vector[string::utf8(b"NEW URL 1"),
        string::utf8(b"NEW URL"),
        string::utf8(b"NEW URL 3"),
        string::utf8(b"NEW URL 4"),
        string::utf8(b"NEW URL 5")]);
        equipment::enhance_equipment(user1, equip1, equip2);
        let shard_balance = eigen_shard::shard_balance(user1_addr);
        assert!(shard_balance == 99700, 0);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==2, EINVALID_PROPERTY_VALUE);
        assert!(!object::is_object(object::object_address(&equip2)), ENOT_OWNER);
        assert!(token::uri(equip1)==new_uri, EINVALID_PROPERTY_VALUE);
        
        let new_uri_3 = string::utf8(b"NEW URL 3");
        
        equipment::enhance_equipment(user1, equip3, equip4);
        equipment::enhance_equipment(user1, equip1, equip3);
        assert!(token::uri(equip1)==new_uri_3, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==3, EINVALID_PROPERTY_VALUE);


        let equip5 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            3, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let equip6 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            4, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let equip7 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            3, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

            let equip8 = equipment::create_equipment_for_test(user1, 0,  
            string::utf8(b"Equipment Name"), 
            string::utf8(b"Equipment Description"),
            string::utf8(b"Equipment Uri"),
            equipment_part_id,
            affinity_id,
            3, level,
            100, 10, 11, 12, 50,
            10, 5, 5, 5, 5);

        let new_uri_4 = string::utf8(b"NEW URL 4");
        let new_uri_5 = string::utf8(b"NEW URL 5");

        equipment::enhance_equipment(user1, equip1, equip5);
        equipment::enhance_equipment(user1, equip1, equip6);
        equipment::enhance_equipment(user1, equip7, equip8);

        assert!(token::uri(equip1)==new_uri_5, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&equip1, &string::utf8(b"GRADE"))==5, EINVALID_PROPERTY_VALUE);
        assert!(token::uri(equip7)==new_uri_4, EINVALID_PROPERTY_VALUE);
        assert!(property_map::read_u64(&equip7, &string::utf8(b"GRADE"))==4, EINVALID_PROPERTY_VALUE);

       
    }
}