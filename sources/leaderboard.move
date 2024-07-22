module main::leaderboard {

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

    use main::admin::{Self, ENOT_ADMIN};


    use aptos_framework::timestamp;

    use std::string::utf8;
    use aptos_std::debug;
    use aptos_std::debug::print;

    use std::option;
    use std::signer;

    const EINVALID_COLLECTION: u64 = 1;
    const ECLAIM_FIRST: u64 = 2;

    use std::vector;

    // Error Codes
    const ENOT_DEPLOYER: u64 = 1;
    const ENOT_OWNER: u64 = 2;
    const ENFT_ID_NOT_FOUND: u64 = 3;
    const EUNABLE_TO_MINT: u64 = 4;
    const EWEIGHT_ZERO: u64 = 5;
    const EUNABLE_TO_CLAIM: u64 = 6;
    const ELEADERBOARD_SEASON_ENDED:u64 = 7;

    struct LeaderboardStruct has key, store {
        leaderboard_vector: vector<LeaderboardElement>,
        score_map: SimpleMap<address, u64>,
        end_time: u64,
    }

    struct LeaderboardElement has store, copy, drop {
        addr: address,
        score: u64
    }

    friend main::daily_spins;

    fun init_module(deployer: &signer) {
        let score_map = aptos_std::simple_map::new<address, u64>();
        let leaderboard_vector = vector::empty<LeaderboardElement>();
        let end_time = 0;
        let leaderboardStruct = LeaderboardStruct { leaderboard_vector, score_map, end_time};
        move_to(deployer, leaderboardStruct);
    }

    public(friend) fun add_score(user_addr: address, score: u64) acquires LeaderboardStruct {
        assert_before_end_time();
        let leaderboardStruct = borrow_global_mut<LeaderboardStruct>(@main);
        let current_score = 0;
        if (simple_map::contains_key(&leaderboardStruct.score_map, &user_addr)){
            current_score = *simple_map::borrow(&leaderboardStruct.score_map, &user_addr);
        };

        let new_score = current_score + score;
        simple_map::upsert(&mut leaderboardStruct.score_map, user_addr, new_score);

        let leaderboard_vector = &mut leaderboardStruct.leaderboard_vector;
        let leaderboard_length = vector::length(leaderboard_vector);
        let i = 0;
        let new_highscore = false;
        let insert_index = 0;
        let remove_index = 100;
        let previous_entry_exists = false;

        while (i < leaderboard_length) {
            let leaderboardElement = *vector::borrow(leaderboard_vector, i);
            let entry_score = leaderboardElement.score;
            if (new_score > entry_score && !new_highscore ){
                new_highscore = true;
                insert_index = i;
            } ;
            let entry_addr = leaderboardElement.addr;
            if (entry_addr == user_addr){
                previous_entry_exists = true;
                remove_index = i;
            };
            i = i + 1;
        };

        // Case when the user has a previous record and has broken the record.
        // Case when the user has a previous record and has not broken the record.
        // Case when the user doesn't have a previous record and has broken the record.
        // Case when the user doesn't have a previous record and has not broken the record.

        // Need to remove the previous record and insert the new record.
        if (previous_entry_exists && new_highscore) {
            vector::remove(leaderboard_vector, remove_index);
            let new_entry = LeaderboardElement { addr: user_addr, score: new_score };
            vector::insert(leaderboard_vector, insert_index, new_entry);
        } 
        else if (previous_entry_exists && !new_highscore ) {
            // TODO: Do nothing as we don't want to add additional entry
        }
        else if (!previous_entry_exists && new_highscore ) {
            let new_entry = LeaderboardElement { addr: user_addr, score: new_score };
            vector::insert(leaderboard_vector, insert_index, new_entry);
        } 
        else if (!previous_entry_exists && !new_highscore ) {
            let new_entry = LeaderboardElement { addr: user_addr, score: new_score };
            vector::insert(leaderboard_vector, leaderboard_length, new_entry);
        };

        //Keep only top 20
        let max_leaderboard_length = 20;
        while(vector::length(leaderboard_vector) > max_leaderboard_length) {
            vector::pop_back(leaderboard_vector);
        };
    }

    entry fun reset_leaderboard(account: &signer, end_time: u64) acquires LeaderboardStruct {
        admin::assert_is_admin(signer::address_of(account));
        
        let leaderboardStruct = borrow_global_mut<LeaderboardStruct>(@main);
        leaderboardStruct.score_map = aptos_std::simple_map::new<address, u64>();
        leaderboardStruct.leaderboard_vector = vector::empty<LeaderboardElement>();
        leaderboardStruct.end_time = end_time;
    }

    public fun assert_before_end_time() acquires LeaderboardStruct{
        let end_time = borrow_global<LeaderboardStruct>(@main).end_time;
        assert!(timestamp::now_microseconds() < end_time,ELEADERBOARD_SEASON_ENDED);
    }

    #[view]
    public fun get_leaderboard_vector(): vector<LeaderboardElement> acquires LeaderboardStruct {
        let leaderboard_vector = &borrow_global<LeaderboardStruct>(@main).leaderboard_vector;
        *leaderboard_vector
    }

    #[view]
    public fun user_score(user_addr:address): u64 acquires LeaderboardStruct {
        let leaderboardStruct = borrow_global<LeaderboardStruct>(@main);
        let contains_key = aptos_std::simple_map::contains_key(&leaderboardStruct.score_map, &user_addr);
        if (!contains_key){
            0   
        }else{
            *simple_map::borrow(&leaderboardStruct.score_map, &user_addr)
        }

    }

    // Testing functions
    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

    #[test_only]
    public fun reset_leaderboard_for_test(creator: &signer, end_time:u64) acquires LeaderboardStruct {
        reset_leaderboard(creator, end_time);
    }

}
