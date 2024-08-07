/// This module implements the the shard tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::token_lock {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::coin;
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::error;
    use std::option;
    use std::signer;
    use std::string::{Self, String};
    use aptos_framework::timestamp;

    use main::admin;

    /// The token does not exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 1;
    /// The provided signer is not the creator
    const ENOT_FINALIZED:u64 = 2;

    const ECLIFF_NOT_PASSED:u64 = 3;
    const EBALANCE_ZERO:u64 = 4;


    // The caller is not the admin
    const ENOT_ADMIN: u64 = 8;
    // The minimum mintable amount requirement is not met.
    const ENOT_MINIMUM_MINT_AMOUNT: u64 = 9;

    const ENOT_EVEN: u64 = 10;

    const EINVALID_DATA: u64 = 11;

    const ETOKEN_CONFIG_FINALIZED:u64 = 12;

    const APP_SIGNER_CAPABILITY_SEED: vector<u8> = b"TOKEN_LOCK_SIGNER_CAPABILITY";

    const DAY_IN_MICROSECONDS:u64 =  24 * 60 * 60 * 1000_000;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct TokenLockCapability has key {
        token_address_map: SimpleMap<address,LockedTokensConfig>
    }

    struct LockedTokensConfig has store, copy, drop {
        user_address_map:SimpleMap<address,LockedTokens>,
        finalized: bool,
        admin_address: address
    }
    
    struct LockedTokens has store, copy, drop {
        cliff_timestamp: u64,
        vesting_period: u64,
        initial_amount: u64,
        balance_amount: u64,
        last_claimed_timestamp: u64
    }

    /// Initializes the module, creating the shard collection.
    fun init_module(caller: &signer) {
        let (signer_resource, token_signer_cap) = account::create_resource_account(
            caller,
            APP_SIGNER_CAPABILITY_SEED,
        );
        move_to(
            &signer_resource,
            TokenLockCapability { token_address_map: simple_map::new() }
        )
    }
 
    entry fun set_whitelist(caller: &signer, whitelist_address: address, token_address: address, cliff_timestamp: u64, vesting_period: u64, initial_amount: u64) acquires TokenLockCapability{
        let token_address_map = &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_address_map;
        let caller_addr = signer::address_of(caller);
        if (!simple_map::contains_key(token_address_map, &token_address)){
            let lockedTokens = LockedTokens{
                cliff_timestamp,
                vesting_period,
                initial_amount,
                balance_amount: initial_amount,
                last_claimed_timestamp: 0
            };

            let user_address_map = simple_map::new();
            simple_map::upsert(&mut user_address_map, whitelist_address, lockedTokens);

            let lockedTokensForAddress = LockedTokensConfig{
                user_address_map: user_address_map,
                finalized: false,
                admin_address: caller_addr
            };
            simple_map::upsert(token_address_map, token_address ,lockedTokensForAddress );
        }
        else{
            // Check that it is not finalized
            let token_address_map = &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_address_map;
            let locked_tokens_config = simple_map::borrow_mut(token_address_map, &token_address);
            assert!(!locked_tokens_config.finalized, ETOKEN_CONFIG_FINALIZED);
            
            // Check that it is the admin address
            assert!(locked_tokens_config.admin_address == caller_addr, ENOT_ADMIN);

            // Proceed with changing the values
            let lockedTokens = LockedTokens{
                cliff_timestamp,
                vesting_period,
                initial_amount,
                balance_amount: initial_amount,
                last_claimed_timestamp: 0,
            };
            simple_map::upsert(&mut locked_tokens_config.user_address_map, whitelist_address, lockedTokens);
        };
    }

    entry fun finalize(token_address:address) acquires TokenLockCapability {
        let token_address_map = &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_address_map;
        if (!simple_map::contains_key(token_address_map, &token_address)){
            assert!(false,ETOKEN_DOES_NOT_EXIST);
        };
        let locked_tokens_config = simple_map::borrow_mut(token_address_map, &token_address);
        locked_tokens_config.finalized = true;
    }



    entry fun claim(caller: &signer, token_address:address) acquires TokenLockCapability {
        assert!(is_finalized(token_address), ENOT_FINALIZED);
        let token_address_map = &mut borrow_global_mut<TokenLockCapability>(capability_address()).token_address_map;
        let caller_addr = signer::address_of(caller);
        
        assert!(simple_map::contains_key(token_address_map, &token_address), EINVALID_DATA);
        let locked_tokens_config = simple_map::borrow_mut(token_address_map, &token_address);
        let locked_tokens = simple_map::borrow_mut(&mut locked_tokens_config.user_address_map, &caller_addr);
        assert!(timestamp::now_microseconds() > locked_tokens.cliff_timestamp, ECLIFF_NOT_PASSED);
        assert!(locked_tokens.balance_amount > 0, EBALANCE_ZERO);
        

    }

    #[view]
    public fun capability_address(): address {
        account::create_resource_address(&@main, APP_SIGNER_CAPABILITY_SEED)
    }

    #[view]
    public fun is_finalized(token_address:address): bool acquires TokenLockCapability{
        let token_address_map = &borrow_global<TokenLockCapability>(capability_address()).token_address_map;
        if (!simple_map::contains_key(token_address_map, &token_address)){
            false
        } else {
            let locked_tokens_config = simple_map::borrow(token_address_map, &token_address);
            locked_tokens_config.finalized
        }
    }

    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

}