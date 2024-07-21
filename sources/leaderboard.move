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


    struct LeaderboardStruct has key, store {
        leaderboard_vector: vector<LeaderboardElement>,
        score_map: SimpleMap<address, u64>,
    }

    struct LeaderboardElement has store, copy, drop {
        addr: address,
        score: u64
    }

    fun init_module(deployer: &signer) {
        let score_map = aptos_std::simple_map::new<address, u64>();
        let leaderboard_vector = vector::empty<LeaderboardElement>();

        let leaderboardStruct = LeaderboardStruct { leaderboard_vector, score_map};
        move_to(deployer, leaderboardStruct);
    }

    fun add_score(user_addr: address, score: u64) acquires LeaderboardStruct {
        let leaderboardStruct = borrow_global<LeaderboardStruct>(@main);
        let current_score = *simple_map::get(&leaderboardStruct.score_map, &user_addr);
        let new_score = current_score + score;
        simple_map::insert(&mut leaderboardStruct.score_map, &user_addr, new_score);

        let leaderboard_vector = &mut leaderboardStruct.leaderboard_vector;
        let length = vector::length(leaderboard_vector);
        let i = 0;

        while (i < length && vector::length(&result) < 20) {
            let LeaderboardElement = *vector::borrow(leaderboard_vector, i);
            let entry_score = LeaderboardElement.score;
            if (new_score > entry_score){
                break;
            } ;
            i = i + 1;
        };
        if (i < 20) {
            let new_entry = LeaderboardElement { addr: user_addr, score: new_score };
            vector::insert<LeaderboardElement>(new_entry, i, leaderboard_vector);
        };
        //Keep only top 20
        while(vector::length(leaderboard_vector) > 20) {
            vector::pop_back(leaderboard_vector);
        };
    }

    entry fun reset_leaderboard(account: &signer) acquires LeaderboardStruct {
        admin::assert_is_admin(signer::address_of(account));
        
        let leaderboardStruct = borrow_global<LeaderboardStruct>(@main);
        let current_score = *simple_map::get(&leaderboardStruct.score_map, &user_addr);
        let new_score = current_score + score;
        simple_map::insert(&mut leaderboardStruct.score_map, &user_addr, new_score);

        let leaderboard_vector = &mut leaderboardStruct.leaderboard_vector;
        let length = vector::length(leaderboard_vector);
        let i = 0;

        while (i < length && vector::length(&result) < 20) {
            let LeaderboardElement = *vector::borrow(leaderboard_vector, i);
            let entry_score = LeaderboardElement.score;
            if (new_score > entry_score){
                break;
            } ;
            i = i + 1;
        };
        if (i < 20) {
            let new_entry = LeaderboardElement { addr: user_addr, score: new_score };
            vector::insert<LeaderboardElement>(new_entry, i, leaderboard_vector);
        };
        //Keep only top 20
        while(vector::length(leaderboard_vector) > 20) {
            vector::pop_back(leaderboard_vector);
        };
    }

    #[view]
    public fun leaderboard_top_20(): vector<LeaderboardElement> acquires LeaderboardStruct {
        let leaderboard_vector = &borrow_global<LeaderboardStruct>(@main).leaderboard_vector;
        // let length = vector:length(leaderboard_vector);
        // let result = vector::empty<LeaderboardElement>();
        // let i = 0;
        // while (i < length && vector::length(&result) < 20) {
        //     let LeaderboardElement = *vector::borrow(leaderboard_vector, i);
        //     vector::push_back(&mut result, LeaderboardElement)
        // };        
        // result
        *leaderboard_vector
    }

    #[view]
    public fun user_score(user_addr:address): u64 acquires LeaderboardStruct {
        let leaderboardStruct = borrow_global<LeaderboardStruct>(@main);
        *simple_map::borrow(&leaderboardStruct.score_map, &user_addr)

    }

    // Testing functions
    #[test_only]
    public fun initialize_for_testing(creator: &signer) {
        init_module(creator);
    }

}
