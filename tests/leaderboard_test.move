 #[test_only]
module main::leaderboard_test{
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
    use aptos_framework::randomness::{Self};


    use main::eigen_shard::{Self, EigenShardCapability};
    use main::omni_cache::{Self};
    use main::admin::{Self};
    use main::pseudorandom::{Self};
    use main::equipment::{Self};
    use main::leaderboard::{Self};
    use main::daily_spins::{Self};
    #[test_only]
    use aptos_std::crypto_algebra::enable_cryptography_algebra_natives;

    const EINVALID_TABLE_LENGTH: u64 = 1;
    const EWHITELIST_AMOUNT: u64 = 2;
    const EINVALID_SPECIAL_EVENT_DETAIL: u64 = 3;


    const EEVENT_ID_NOT_FOUND: u64 = 4;
    const EINVALID_DATA: u64 = 5;



    const EINSUFFICIENT_BALANCE: u64 = 65540;
    const TIME_BETWEEN_SPINS: u64 = 24 * 60 * 60 * 1_000_000; 


    #[test(creator = @main)]
    public fun initialize_leaderboard_for_test(creator: &signer) {
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);

    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_daily_spin(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");

        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 100);
        daily_spins::add_result_entry(creator,1, 200);
        daily_spins::add_result_entry(creator,2, 300);
        daily_spins::add_result_entry(creator,3, 400);
        timestamp::update_global_time_for_test(TIME_BETWEEN_SPINS + 1);
        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + 100_000_000);
        daily_spins::spin_wheel_for_test(user1);

    }

   

}