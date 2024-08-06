/// This module implements the the shard tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::und {
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::primary_fungible_store;
    use aptos_token_objects::collection;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::error;
    use std::option;
    use std::signer;
    use std::string::{Self, String};

    friend main::equipment;
    friend main::omni_cache;

    use main::admin;

    /// The token does not exist
    const ETOKEN_DOES_NOT_EXIST: u64 = 1;
    /// The provided signer is not the creator
    const ENOT_CREATOR: u64 = 2;
    /// Attempted to mutate an immutable field
    const EFIELD_NOT_MUTABLE: u64 = 3;
    /// Attempted to burn a non-burnable token
    const ETOKEN_NOT_BURNABLE: u64 = 4;
    /// Attempted to mutate a property map that is not mutable
    const EPROPERTIES_NOT_MUTABLE: u64 = 5;
    // The collection does not exist
    const ECOLLECTION_DOES_NOT_EXIST: u64 = 6;

    const EINVALID_BALANCE: u64 = 7;


    // The caller is not the admin
    const ENOT_ADMIN: u64 = 8;
    // The minimum mintable amount requirement is not met.
    const ENOT_MINIMUM_MINT_AMOUNT: u64 = 9;

    const ENOT_EVEN: u64 = 10;

    const EINVALID_DATA: u64 = 11;


    /// The collection name
    const UND_COLLECTION_NAME: vector<u8> = b"Undying City Token Collection";
    /// The collection description
    const UND_COLLECTION_DESCRIPTION: vector<u8> = b"This collection stores the Undying City Token." ;
    /// The collection URI
    const UND_COLLECTION_URI: vector<u8> = b"https://doc.undyingcity.zabavalabs.com";

   /// The token name
    const UND_TOKEN_NAME: vector<u8> = b"Undying City Token";
    const UND_TOKEN_DESCRIPTION: vector<u8> = b"The Undying City Token controls the governance of the game." ;
    const UND_ASSET_NAME: vector<u8> = b"Undying City Token";
    const UND_MAX_SUPPLY: u128 = 100_000_000;
    const UND_COLLECTION_SUPPLY: u64 = 1;

    const UND_ASSET_SYMBOL: vector<u8> = b"UND";
    //Point to project website or app
    const PROJECT_URI: vector<u8> = b"https://undyingcity.zabavalabs.com";
    //Point to Image
    // TODO: Point to the image once it's uploaded.
    const PROJECT_ICON_URI: vector<u8> = b"ipfs://bafybeiee6ziwznlaullflnzeqpvvdtweb7pehp572xcafkwawvtun2me4y";
    const URI: vector<u8> = b"ipfs://bafybeiee6ziwznlaullflnzeqpvvdtweb7pehp572xcafkwawvtun2me4y";


    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    // UND Token
    struct UNDCapability has key {
        mutator_ref: token::MutatorRef,
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
        /// Used to mint fungible assets.
        fungible_asset_mint_ref: fungible_asset::MintRef,
        /// Used to burn fungible assets.
        fungible_asset_burn_ref: fungible_asset::BurnRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct UNDCollectionCapability has key {
        collection_mutator_ref: collection::MutatorRef
    }

    /// Initializes the module, creating the shard collection.
    fun init_module(caller: &signer) {
        // Create a collection for shard tokens.
        create_und_token_collection(caller);

        create_und_token_as_fungible_token(
            caller,
            string::utf8(UND_TOKEN_DESCRIPTION),
            string::utf8(UND_TOKEN_NAME),
            string::utf8(URI),
            string::utf8(UND_ASSET_NAME),
            string::utf8(UND_ASSET_SYMBOL),
            string::utf8(PROJECT_ICON_URI),
            string::utf8(PROJECT_URI),
        );
    }
 
    public entry fun set_token_name(caller: &signer, new_name: String) acquires UNDCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let und_token_capability = borrow_global<UNDCapability>(und_token_address());
        token::set_name(&und_token_capability.mutator_ref, new_name);
    }

    public entry fun set_token_uri(caller: &signer, new_uri: String) acquires UNDCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let und_token_capability = borrow_global<UNDCapability>(und_token_address());
        token::set_uri(&und_token_capability.mutator_ref, new_uri);
    }

    public entry fun set_collection_uri(caller: &signer, new_uri: String) acquires UNDCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<UNDCollectionCapability>(und_collection_address());
        collection::set_uri(&collection_capability.collection_mutator_ref, new_uri);
    }

    public entry fun set_collection_description(caller: &signer, new_description: String) acquires UNDCollectionCapability{
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let collection_capability = borrow_global<UNDCollectionCapability>(und_collection_address());
        collection::set_description(&collection_capability.collection_mutator_ref, new_description);
    }

     fun create_und_token_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(UND_COLLECTION_DESCRIPTION);
        let name = string::utf8(UND_COLLECTION_NAME);
        let uri = string::utf8(UND_COLLECTION_URI);
        let collection_supply = UND_COLLECTION_SUPPLY;
        // Creates the collection with unlimited supply and without establishing any royalty configuration.
        let collection_constructor_ref = collection::create_fixed_collection(
            creator,
            description,
            collection_supply,
            name,
            option::none(),
            uri,
        );

        let object_signer = object::generate_signer(&collection_constructor_ref);

        let collection_mutator_ref = collection::generate_mutator_ref(&collection_constructor_ref);

        let collection_capability = UNDCollectionCapability{
            collection_mutator_ref
        };
        move_to(&object_signer, collection_capability);
    }

    /// Creates the shard token as fungible token.
    fun create_und_token_as_fungible_token(
        creator: &signer,
        description: String,
        token_name: String,
        uri: String,
        fungible_asset_name: String,
        fungible_asset_symbol: String,
        icon_uri: String,
        project_uri: String,
    ) {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(UND_COLLECTION_NAME);
        // Creates the shard token, and get the constructor ref of the token. The constructor ref
        // is used to generate the refs of the token.
        let constructor_ref = token::create_named_token(
            creator,
            collection,
            description,
            token_name,
            option::none(),
            uri,
        );

        // Generates the object signer and the refs. The refs are used to manage the token.
        let object_signer = object::generate_signer(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);
        let mutator_ref = token::generate_mutator_ref(&constructor_ref);

        let decimals = 0;

        let max_supply = option::some(UND_MAX_SUPPLY);
        // Creates the fungible asset.
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            &constructor_ref,
            max_supply,
            fungible_asset_name,
            fungible_asset_symbol,
            decimals,
            icon_uri,
            project_uri,
        );
        let fungible_asset_mint_ref = fungible_asset::generate_mint_ref(&constructor_ref);
        let fungible_asset_burn_ref = fungible_asset::generate_burn_ref(&constructor_ref);

        // Publishes the UNDCapability resource with the refs.
        let und_token = UNDCapability {
            mutator_ref,
            property_mutator_ref,
            fungible_asset_mint_ref,
            fungible_asset_burn_ref,
        };
        move_to(&object_signer, und_token);
    }

    public entry fun mint_und( caller: &signer, amount: u64) acquires UNDCapability {
        let caller_address = signer::address_of(caller);
        admin::assert_is_admin(caller_address);
        let und_token = object::address_to_object<UNDCapability>(und_token_address());
        mint_internal( und_token, signer::address_of(caller), amount);
    }

    /// The internal mint function.
    fun mint_internal(token: Object<UNDCapability>, receiver: address, amount: u64) acquires UNDCapability {
        let und_token = authorized_borrow<UNDCapability>( &token);
        let fungible_asset_mint_ref = &und_token.fungible_asset_mint_ref;
        let fa = fungible_asset::mint(fungible_asset_mint_ref, amount);
        primary_fungible_store::deposit(receiver, fa);
    }

    inline fun authorized_borrow<T: key>(token: &Object<T>): &UNDCapability {
        let token_address = object::object_address(token);
        assert!(
            exists<UNDCapability>(token_address),
            error::not_found(ETOKEN_DOES_NOT_EXIST),
        );

        borrow_global<UNDCapability>(token_address)
    }

    // ANCHOR View Functions
    #[view]
    /// Returns the balance of the shard token of the owner
    public fun und_balance(owner_addr: address): u64 {
        let shard_object = object::address_to_object(und_token_address());
        let metadata = object::convert<UNDCapability, Metadata>(shard_object);
        let store = primary_fungible_store::ensure_primary_store_exists(owner_addr, metadata);
        fungible_asset::balance(store)
    }
    
    #[view]
    /// Returns the und collection address
    public fun und_collection_address(): address {
        collection::create_collection_address(&@main, &string::utf8(UND_COLLECTION_NAME))
    }

    #[view]
    /// Returns the und token address
    public fun und_token_address(): address {
        und_token_address_by_name(string::utf8(UND_TOKEN_NAME))
    }

    #[view]
    /// Returns the und token address by name
    public fun und_token_address_by_name(und_token_name: String): address {
        token::create_token_address(&@main, &string::utf8(UND_COLLECTION_NAME), &und_token_name)
    }


    #[test_only]
    public fun initialize_for_test(creator: &signer) {
        init_module(creator);
    }

}