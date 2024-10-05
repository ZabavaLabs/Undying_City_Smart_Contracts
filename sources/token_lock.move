/// This module implements the the shard tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::token_lock {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_token_objects::token::{Self, Token};
    use aptos_framework::coin;
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use std::error;
    use std::option;
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::timestamp;
    use std::vector;

    use std::string::utf8;
    use aptos_std::debug;
    use aptos_std::debug::print;

    /// The token does not exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 1;
    /// The provided signer is not the creator
    const ENOT_FINALIZED: u64 = 2;

    const ECLIFF_NOT_PASSED: u64 = 3;
    const EBALANCE_ZERO: u64 = 4;

    const EPERIOD_NOT_PASSED: u64 = 5;

    // The caller is not the admin
    const ENOT_ADMIN: u64 = 8;
    // The minimum mintable amount requirement is not met.
    const ENOT_MINIMUM_MINT_AMOUNT: u64 = 9;

    const ENOT_EVEN: u64 = 10;

    const EINVALID_DATA: u64 = 11;

    const ETOKEN_CONFIG_FINALIZED: u64 = 12;

    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"TOKEN_LOCK_SIGNER_CAPABILITY";

    const DAY_IN_MICROSECONDS: u64 = 24 * 60 * 60 * 1000_000;

    // TODO: ADD EVENT FOR TOKEN LOCK ROW ADDED
    // TODO: ADD EVENT FOR TOKENS CLAIMED


    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct TokenLockCapability has key {
        signer_cap: SignerCapability,
        token_lock_table: SmartTable<u64, LockedTokenRow>,
        user_address_map: SimpleMap<address, SmartTable<u64, u64>>,
        token_address_map: SimpleMap<address, SmartTable<u64, u64>>
    }

    struct LockedTokenRow has store, copy, drop {
        row_id: u64,
        token_address: address,
        cliff_timestamp: u64,
        vesting_duration: u64,
        periodicity: u64,
        initial_amount: u64,
        balance_amount: u64,
        last_claimed_timestamp: u64,
        claimant_address: address,
        admin_address: address,
        deposit_timestamp: u64
    }

    #[event]
    struct LockEvent has drop, store {
        row_id: u64,
        admin_address: address,
        claimant_address: address,
        amount: u64
    }

    #[event]
    struct ClaimEvent has drop, store {
        row_id: u64,
        claimant_address: address,
        amount: u64,
        timestamp: u64
    }

    /// Initializes the module, creating the shard collection.
    fun init_module(caller: &signer) {
        let (signer_resource, signer_cap) =
            account::create_resource_account(caller, APP_SIGNER_CAPABILITY_SEED);

        move_to(
            &signer_resource,
            TokenLockCapability {
                signer_cap,
                token_lock_table: smart_table::new<u64, LockedTokenRow>(),
                user_address_map: simple_map::new<address, SmartTable<u64, u64>>(),
                token_address_map: simple_map::new<address, SmartTable<u64, u64>>(),
            },
        )
    }

    public entry fun add_token_lock(
        from: &signer,
        token_address: address,
        amount: u64,
        cliff_timestamp: u64,
        vesting_duration: u64,
        periodicity: u64,
        claimant_address: address
    ) acquires TokenLockCapability {

        let token_obj = object::address_to_object<token::Token>(token_address);
        primary_fungible_store::transfer(from, token_obj, capability_address(), amount);
        let token_lock_table =
            &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_lock_table;


        let token_lock_table_length = aptos_std::smart_table::length(token_lock_table);
        let caller_addr = signer::address_of(from);
        let locked_tokens = LockedTokenRow {
            row_id: token_lock_table_length,
            token_address,
            cliff_timestamp,
            vesting_duration,
            periodicity,
            initial_amount: amount,
            balance_amount: amount,
            last_claimed_timestamp: 0,
            claimant_address,
            admin_address: caller_addr,
            deposit_timestamp: timestamp::now_microseconds()
        };

        smart_table::add(token_lock_table, token_lock_table_length, locked_tokens);

        let user_address_map =
            &mut borrow_global_mut<TokenLockCapability>(capability_address()).user_address_map;

        if (simple_map::contains_key(user_address_map, &claimant_address)) {
            let user_smart_table = simple_map::borrow_mut(
                user_address_map, &claimant_address
            );
            let user_smart_table_length = aptos_std::smart_table::length(user_smart_table);
            smart_table::add(
                user_smart_table, user_smart_table_length, token_lock_table_length
            );
        } else {
            let user_smart_table = smart_table::new<u64, u64>();
            smart_table::add(&mut user_smart_table, 0, token_lock_table_length);
            simple_map::add(user_address_map, claimant_address, user_smart_table);
        };

        let token_address_map =
            &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_address_map;
        if (simple_map::contains_key(token_address_map, &token_address)) {
            let token_smart_table = simple_map::borrow_mut(
                token_address_map, &token_address
            );
            let token_smart_table_length = aptos_std::smart_table::length(
                token_smart_table
            );
            smart_table::add(
                token_smart_table, token_smart_table_length, token_lock_table_length
            );
        } else {
            let token_smart_table = smart_table::new<u64, u64>();
            smart_table::add(&mut token_smart_table, 0, token_lock_table_length);
            simple_map::add(token_address_map, token_address, token_smart_table);
        };

        let lock_event = LockEvent {
            row_id: token_lock_table_length,
            admin_address: caller_addr,
            claimant_address,
            amount
        };

        0x1::event::emit(lock_event);

    }

    public entry fun claim(caller: &signer, row_id: u64) acquires TokenLockCapability {
        // assert!(is_finalized(token_address), ENOT_FINALIZED);
        let token_lock_table =
            &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_lock_table;
        let caller_addr = signer::address_of(caller);
        let locked_token_row = smart_table::borrow_mut(token_lock_table, row_id);
        let claimant_address = locked_token_row.claimant_address;

        assert!(claimant_address == caller_addr, EINVALID_DATA);
        assert!(
            timestamp::now_microseconds() > locked_token_row.cliff_timestamp,
            ECLIFF_NOT_PASSED,
        );
        assert!(locked_token_row.balance_amount > 0, EBALANCE_ZERO);

        let token_obj =
            object::address_to_object<token::Token>(locked_token_row.token_address);
        let claimed_amount =
            locked_token_row.initial_amount - locked_token_row.balance_amount;
        let target_claim_amount =
            (
                ((timestamp::now_microseconds() - locked_token_row.cliff_timestamp) * locked_token_row.initial_amount) / locked_token_row.vesting_duration
            ) ;
        if (target_claim_amount > locked_token_row.initial_amount) {
            target_claim_amount = locked_token_row.initial_amount
        };

        let amount = target_claim_amount - claimed_amount;
        let min_claim_amount = locked_token_row.initial_amount * locked_token_row.periodicity / locked_token_row.vesting_duration;
        // debug::print(&utf8(b"timeDiff:"));
        // debug::print(&(timestamp::now_microseconds() - locked_token_row.cliff_timestamp));
        // debug::print(&utf8(b"vesting duration:"));
        // debug::print(&locked_token_row.vesting_duration);
        // debug::print(&utf8(b"initial amount:"));
        // debug::print(&locked_token_row.initial_amount);
        // debug::print(&utf8(b"target_claim_amount:"));
        // debug::print(&target_claim_amount);
        // debug::print(&utf8(b"amount:"));
        // debug::print(&amount);
        // debug::print(&utf8(b"min_claim_amount:"));
        // debug::print(&min_claim_amount);
        
        assert!(amount >= min_claim_amount, EPERIOD_NOT_PASSED);


        locked_token_row.balance_amount = locked_token_row.balance_amount - amount;
        locked_token_row.last_claimed_timestamp = timestamp::now_microseconds();

        primary_fungible_store::transfer(
            &get_signer(), token_obj, claimant_address, amount
        );

        let claim_event = ClaimEvent {
            row_id,
            claimant_address: caller_addr,
            amount,
            timestamp: timestamp::now_microseconds()
        };

        0x1::event::emit(claim_event);
    }

    // entry fun finalize(token_address: address) acquires TokenLockCapability {
    //     let token_address_map =
    //         &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_address_map;
    //     if (!simple_map::contains_key(token_address_map, &token_address)) {
    //         assert!(false, ETOKEN_DOES_NOT_EXIST);
    //     };
    //     let locked_tokens_config = simple_map::borrow_mut(
    //         token_address_map, &token_address
    //     );
    //     locked_tokens_config.finalized = true;
    // }

 

    fun get_signer(): signer acquires TokenLockCapability {
        account::create_signer_with_capability(
            &borrow_global<TokenLockCapability>(capability_address()).signer_cap
        )
    }

    #[view]
    public fun capability_address(): address {
        account::create_resource_address(&@main, APP_SIGNER_CAPABILITY_SEED)
    }

    #[view]
    public fun get_token_locks_by_user(user_addr: address): vector<LockedTokenRow> acquires TokenLockCapability {
        let user_address_map = &borrow_global<TokenLockCapability>(capability_address()).user_address_map;
        let user_smart_table = simple_map::borrow(user_address_map, &user_addr);
        let row_ids = smart_table::keys(user_smart_table);
        let user_smart_table_length = smart_table::length(user_smart_table);
        let output: vector<LockedTokenRow> = vector::empty();
        let i = 0;
        
        while (i < user_smart_table_length) {
            let row_id = smart_table::borrow(user_smart_table, i);
            let token_lock_table = &borrow_global<TokenLockCapability>(capability_address()).token_lock_table;
            let locked_token_row = *smart_table::borrow(token_lock_table, *row_id);
            vector::push_back(&mut output, locked_token_row);
            i = i + 1;
        };
        output
    }

    #[view]
    public fun get_token_locks_by_token_address(token_addr: address): vector<LockedTokenRow> acquires TokenLockCapability {
        let token_address_map = &borrow_global<TokenLockCapability>(capability_address()).token_address_map;
        let token_smart_table = simple_map::borrow(token_address_map, &token_addr);
        // let keys = smart_table::keys(token_smart_table);
        let token_smart_table_length = smart_table::length(token_smart_table);
        let output: vector<LockedTokenRow> = vector::empty();
        let i = 0;
        // let len = vector::length(&keys);
        
        while (i < token_smart_table_length) {
            let row_id = smart_table::borrow(token_smart_table, i);
            let token_lock_table = &borrow_global<TokenLockCapability>(capability_address()).token_lock_table;
            let locked_token_row = *smart_table::borrow(token_lock_table, *row_id);
            // let locked_token_row = get_token_lock_row(*row_id);
            vector::push_back(&mut output, locked_token_row);
            i = i + 1;
        };
        output
    }

    #[view]
    public fun get_token_lock_row(row_id: u64): LockedTokenRow acquires TokenLockCapability {
        let token_lock_table = &borrow_global<TokenLockCapability>(capability_address()).token_lock_table;
        *smart_table::borrow(token_lock_table, row_id)
    }

    // #[view]
    // public fun is_finalized(token_address: address): bool acquires TokenLockCapability {
    //     let token_address_map =
    //         &borrow_global<TokenLockCapability>(capability_address()).token_address_map;
    //     if (!simple_map::contains_key(token_address_map, &token_address)) { false }
    //     else {
    //         let locked_tokens_config = simple_map::borrow(
    //             token_address_map, &token_address
    //         );
    //         locked_tokens_config.finalized
    //     }
    // }

    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }
}
