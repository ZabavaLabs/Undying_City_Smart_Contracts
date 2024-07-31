 #[test_only]
module main::leaderboard_test{
    // use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object;
    // use aptos_std::smart_table::{Self, SmartTable};
    // use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::timestamp;
    use aptos_framework::block;
    use aptos_framework::account;

    use std::signer;
    use std::vector;

    use std::string::utf8;
    use aptos_std::debug;
    use aptos_std::debug::print;

   
    use std::string::{Self};
    // use aptos_std::string_utils::{to_string};
    use aptos_framework::randomness::{Self};


    use main::eigen_shard::{Self, EigenShardCapability};
    use main::omni_cache::{Self};
    use main::admin::{Self};
    use main::pseudorandom::{Self};
    use main::equipment::{Self};
    use main::leaderboard::{Self, LeaderboardElement};
    use main::daily_spins::{Self, EUNABLE_TO_SPIN};
    #[test_only]
    use aptos_std::crypto_algebra::enable_cryptography_algebra_natives;

    const EINVALID_TABLE_LENGTH: u64 = 1;
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
        assert!(daily_spins::spin_result_table_length()==4,EINVALID_DATA);
        timestamp::update_global_time_for_test(TIME_BETWEEN_SPINS + 1);
        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + 100_000_000);
        daily_spins::spin_wheel_for_test(user1);
        let user1_addr = signer::address_of(user1);
        debug::print(&utf8(b"user reward was:"));
        let previous_spin_result = daily_spins::previous_spin_result(user1_addr);
        debug::print(&previous_spin_result);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        debug::print(&utf8(b"previous spin time:"));
        let spin_time = daily_spins::previous_spin_time(user1_addr);
        debug::print(&spin_time);
    }

   

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 2, location = main::daily_spins)]
    public fun test_daily_spin_again(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
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
        assert!(daily_spins::spin_result_table_length()==4,EINVALID_DATA);
        timestamp::update_global_time_for_test(TIME_BETWEEN_SPINS + 1);
        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + 100_000_000);
        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_multiple_daily_spins(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 1);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);
        daily_spins::add_result_entry(creator,4, 400);
        daily_spins::add_result_entry(creator,5, 500);
        daily_spins::add_result_entry(creator,6, 600);
        daily_spins::add_result_entry(creator,7, 700);
        daily_spins::add_result_entry(creator,8, 800);
        daily_spins::add_result_entry(creator,9, 900);

        assert!(daily_spins::spin_result_table_length()==10,EINVALID_DATA);
        timestamp::update_global_time_for_test(TIME_BETWEEN_SPINS + 1);
        let user1_addr = signer::address_of(user1);

        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + (TIME_BETWEEN_SPINS * 1000));
        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 2);
        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 3);
        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 4);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 5);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 6);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 7);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 8);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 9);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS +1) * 10);

        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        daily_spins::spin_wheel_for_test(user3);
        debug::print(&utf8(b"user score:"));
        let user_score = leaderboard::user_score(user1_addr);
        debug::print(&user_score);
        let (spin_result, day_index, timestamp) = daily_spins::last_spin_info(user1_addr);
        assert!( day_index== 3, EINVALID_DATA);
    }
    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, aptos_framework = @aptos_framework)]
    public fun test_daily_spins_bonuses(creator: &signer, user1: &signer, user2:&signer, user3:&signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 0);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);
        daily_spins::add_result_entry(creator,4, 400);
        daily_spins::add_result_entry(creator,5, 500);
        daily_spins::add_result_entry(creator,6, 600);
        daily_spins::add_result_entry(creator,7, 700);
        daily_spins::add_result_entry(creator,8, 800);
        daily_spins::add_result_entry(creator,9, 900);

        assert!(daily_spins::spin_result_table_length()==10,EINVALID_DATA);
        let user1_addr = signer::address_of(user1);

        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + (TIME_BETWEEN_SPINS * 1000));
      
        let prev_score = 0;
        let score = 0;
        for (i in 0..10) {
            timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS + 1) * i + 100);

            daily_spins::spin_wheel_for_test(user1);
            let (spin_result, day_index, timestamp) = daily_spins::last_spin_info(user1_addr);
            let remainder = i % 7;
            // assert!( day_index == remainder, EINVALID_DATA);
            assert!( timestamp == (TIME_BETWEEN_SPINS + 1) * i + 100, EINVALID_DATA);
            prev_score = score;
            score = leaderboard::user_score(user1_addr);
            let reward =0;
            if (day_index == 3){
                reward = spin_result * 100 * 2;
            }else if (day_index == 0){
                reward = spin_result * 100 * 3;
            } else{
                reward = spin_result * 100;
            };
            assert!( score == prev_score + reward, EINVALID_DATA);
        };
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, user4= @0x781, user5= @0x782, user6= @0x783, user7= @0x784, user8= @0x785, user9= @0x849,user10= @0x852, aptos_framework = @aptos_framework)]
    public fun test_leaderboard(creator: &signer, user1: &signer, user2:&signer, user3:&signer, user4: &signer, user5:&signer, user6:&signer, user7: &signer, user8:&signer, user9:&signer, user10: &signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 0);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);
        daily_spins::add_result_entry(creator,4, 400);
        daily_spins::add_result_entry(creator,5, 500);
        daily_spins::add_result_entry(creator,6, 600);
        daily_spins::add_result_entry(creator,7, 700);
        daily_spins::add_result_entry(creator,8, 800);
        daily_spins::add_result_entry(creator,9, 900);

        assert!(daily_spins::spin_result_table_length()==10,EINVALID_DATA);
        let user1_addr = signer::address_of(user1);

        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + (TIME_BETWEEN_SPINS * 1000));
      
        let prev_score = 0;
        let score = 0;
        for (i in 0..10) {
            timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS + 1) * i + 100);

            daily_spins::spin_wheel_for_test(user1);
            daily_spins::spin_wheel_for_test(user2);
            daily_spins::spin_wheel_for_test(user3);
            daily_spins::spin_wheel_for_test(user4);
            daily_spins::spin_wheel_for_test(user5);
            daily_spins::spin_wheel_for_test(user6);
            daily_spins::spin_wheel_for_test(user7);
            daily_spins::spin_wheel_for_test(user8);
            daily_spins::spin_wheel_for_test(user9);
            daily_spins::spin_wheel_for_test(user10);

            
        };
        let top = leaderboard::get_leaderboard_vector();
        for (j in 0..vector::length(&top)){
            let leaderboard_element = vector::borrow(&top, j);
            debug::print(leaderboard_element);
            // Add assertions to ensure that each score is larger than the previous.
        };
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, user4= @0x781, user5= @0x782, user6= @0x783, user7= @0x784, user8= @0x785, user9= @0x849,user10= @0x852, aptos_framework = @aptos_framework)]
    public fun test_leaderboard_reset_score(creator: &signer, user1: &signer, user2:&signer, user3:&signer, user4: &signer, user5:&signer, user6:&signer, user7: &signer, user8:&signer, user9:&signer, user10: &signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 0);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);
        daily_spins::add_result_entry(creator,4, 400);
        daily_spins::add_result_entry(creator,5, 500);
        daily_spins::add_result_entry(creator,6, 600);
        daily_spins::add_result_entry(creator,7, 700);
        daily_spins::add_result_entry(creator,8, 800);
        daily_spins::add_result_entry(creator,9, 900);

        assert!(daily_spins::spin_result_table_length()==10,EINVALID_DATA);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);


        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + (TIME_BETWEEN_SPINS * 1000));
      
        let prev_score = 0;
        let score = 0;
        for (i in 0..10) {
            timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS + 1) * i + 100);
            daily_spins::spin_wheel_for_test(user1);
            daily_spins::spin_wheel_for_test(user2);
            daily_spins::spin_wheel_for_test(user3);
            daily_spins::spin_wheel_for_test(user4);
            daily_spins::spin_wheel_for_test(user5);
            daily_spins::spin_wheel_for_test(user6);
            daily_spins::spin_wheel_for_test(user7);
            daily_spins::spin_wheel_for_test(user8);
            daily_spins::spin_wheel_for_test(user9);
            daily_spins::spin_wheel_for_test(user10);            
        };
        let user_score = leaderboard::user_score(user1_addr);
        let user2_score = leaderboard::user_score(user2_addr);


        assert!(user_score > 0, EINVALID_DATA);
        assert!(user2_score > 0, EINVALID_DATA);

        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + (TIME_BETWEEN_SPINS * 2000));
        user_score = leaderboard::user_score(user1_addr);
        user2_score = leaderboard::user_score(user2_addr);

        assert!(user_score == 0, EINVALID_DATA);
        assert!(user2_score == 0, EINVALID_DATA);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, user4= @0x781, user5= @0x782, user6= @0x783, user7= @0x784, user8= @0x785, user9= @0x849,user10= @0x852, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 2, location = main::daily_spins)]
    public fun test_spin_before_time_between_spins(creator: &signer, user1: &signer, user2:&signer, user3:&signer, user4: &signer, user5:&signer, user6:&signer, user7: &signer, user8:&signer, user9:&signer, user10: &signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 0);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        leaderboard::reset_leaderboard_for_test(creator, timestamp::now_microseconds() + (TIME_BETWEEN_SPINS * 1000));
      
        let prev_score = 0;
        let score = 0;
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS + 1)  + 100);
        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        timestamp::update_global_time_for_test((TIME_BETWEEN_SPINS + 1)  + 100 + TIME_BETWEEN_SPINS);
        daily_spins::spin_wheel_for_test(user1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, user4= @0x781, user5= @0x782, user6= @0x783, user7= @0x784, user8= @0x785, user9= @0x849,user10= @0x852, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 7, location = main::leaderboard)]
    public fun test_spin_after_leaderboard_season(creator: &signer, user1: &signer, user2:&signer, user3:&signer, user4: &signer, user5:&signer, user6:&signer, user7: &signer, user8:&signer, user9:&signer, user10: &signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 0);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);

        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        leaderboard::reset_leaderboard_for_test(creator, TIME_BETWEEN_SPINS * 10 );
      
        let prev_score = 0;
        let score = 0;
        timestamp::update_global_time_for_test(100);
        daily_spins::spin_wheel_for_test(user1);
        daily_spins::spin_wheel_for_test(user2);
        timestamp::update_global_time_for_test(TIME_BETWEEN_SPINS * 11);
        daily_spins::spin_wheel_for_test(user1);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x678, user3= @0x789, user4= @0x781, user5= @0x782, user6= @0x783, user7= @0x784, user8= @0x785, user9= @0x849,user10= @0x852, aptos_framework = @aptos_framework)]
    public fun test_daily_spin_view_functions(creator: &signer, user1: &signer, user2:&signer, user3:&signer, user4: &signer, user5:&signer, user6:&signer, user7: &signer, user8:&signer, user9:&signer, user10: &signer, aptos_framework: &signer) {
        enable_cryptography_algebra_natives(aptos_framework);
        timestamp::set_time_has_started_for_testing(aptos_framework);
      
        randomness::initialize_for_testing(aptos_framework);
        randomness::set_seed(x"0000000000000000000000000000000000000000000000000000000000000001");
        
        admin::initialize_for_test(creator);
        omni_cache::initialize_for_test(creator);
        leaderboard::initialize_for_test(creator);
        daily_spins::initialize_for_test(creator);
        daily_spins::add_result_entry(creator,0, 0);
        daily_spins::add_result_entry(creator,1, 100);
        daily_spins::add_result_entry(creator,2, 200);
        daily_spins::add_result_entry(creator,3, 300);

        let spin_rewards = daily_spins::spin_rewards();
        debug::print(&spin_rewards[0]);

    }
}