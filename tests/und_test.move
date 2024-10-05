/// This module implements the the und tokens (fungible token). When the module initializes,
/// it creates the collection and two fungible tokens such as Corn and Meat.
module main::und_test {
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
    use std::string::{Self};

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

    const UND_COLLECTION_NAME: vector<u8> = b"Undying City Token Collection";
    /// The collection description
    const UND_COLLECTION_DESCRIPTION: vector<u8> = b"This collection stores the Undying City Token.";
    /// The collection URI
    const UND_COLLECTION_URI: vector<u8> = b"https://doc.undyingcity.zabavalabs.com";

    /// The token name
    const UND_TOKEN_NAME: vector<u8> = b"Undying City Token";
    const UND_TOKEN_DESCRIPTION: vector<u8> = b"The Undying City Token controls the governance of the game.";
    const UND_ASSET_NAME: vector<u8> = b"Undying City Token";
    const UND_MAX_SUPPLY: u64 = 100_000_000;

    const UND_ASSET_SYMBOL: vector<u8> = b"UND";
    //Point to project website or app
    const PROJECT_URI: vector<u8> = b"https://undyingcity.zabavalabs.com";
    //Point to Image
    // TODO: Point to the image once it's uploaded.
    const PROJECT_ICON_URI: vector<u8> = b"ipfs://bafybeiee6ziwznlaullflnzeqpvvdtweb7pehp572xcafkwawvtun2me4y";
    const URI: vector<u8> = b"ipfs://bafybeiee6ziwznlaullflnzeqpvvdtweb7pehp572xcafkwawvtun2me4y";

    use main::und::{Self, UNDCapability, UNDCollectionCapability};
    use main::admin;

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_und_mint(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);

        admin::initialize_for_test(creator);

        let user2_addr = signer::address_of(user2);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 50);

        assert!(und::und_balance(creator_addr) == 50, 0);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_und_mint_100m(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        assert!(signer::address_of(creator) == @main, 0);

        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        let user1_addr = signer::address_of(user1);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100_000_000);

        assert!(und::und_balance(creator_addr) == 100_000_000, 0);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 131077, location = aptos_framework::fungible_asset)]
    public fun test_und_mint_excess(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        assert!(signer::address_of(creator) == @main, 0);

        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        let user1_addr = signer::address_of(user1);
        let creator_addr = signer::address_of(creator);

        und::mint_und(creator, 100_000_001);

        assert!(und::und_balance(creator_addr) == 100_000_001, 0);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 1, location = main::admin)]
    public fun test_unauthorzed_mint(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        assert!(signer::address_of(creator) == @main, 0);

        und::initialize_for_test(creator);
        admin::initialize_for_test(creator);

        let user1_addr = signer::address_of(user1);
        let creator_addr = signer::address_of(creator);

        und::mint_und(user1, 100);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_set_token_name(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);

        admin::initialize_for_test(creator);

        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        und::mint_und(creator, 50);

        let und_token =
            object::address_to_object<UNDCapability>(und::und_token_address());

        assert!(token::name(und_token) == string::utf8(UND_TOKEN_NAME), EINVALID_DATA);
        let new_name = string::utf8(b"New Token Name");
        und::set_token_name(creator, new_name);
        assert!(token::name(und_token) == new_name, EINVALID_DATA);

        assert!(token::uri(und_token) == string::utf8(URI), EINVALID_DATA);
        let new_uri = string::utf8(b"www.google.com");
        und::set_token_uri(creator, new_uri);
        assert!(token::uri(und_token) == new_uri, EINVALID_DATA);
    }

    #[test(creator = @main, user1 = @0x456, user2 = @0x789, aptos_framework = @aptos_framework)]
    public fun test_set_collection(
        creator: &signer, user1: &signer, user2: &signer, aptos_framework: &signer
    ) {
        und::initialize_for_test(creator);

        admin::initialize_for_test(creator);

        let creator_addr = signer::address_of(creator);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);

        und::mint_und(creator, 50);

        let und_collection =
            object::address_to_object<UNDCollectionCapability>(
                und::und_collection_address()
            );

        assert!(
            collection::uri(und_collection) == string::utf8(UND_COLLECTION_URI),
            EINVALID_DATA,
        );
        let new_uri = string::utf8(b"https://new_google.com");
        und::set_collection_uri(creator, new_uri);
        assert!(collection::uri(und_collection) == new_uri, EINVALID_DATA);

        assert!(
            collection::description(und_collection) == string::utf8(
                UND_COLLECTION_DESCRIPTION
            ),
            EINVALID_DATA,
        );
        let new_description = string::utf8(b"This is a new description!!!");
        und::set_collection_description(creator, new_description);
        assert!(collection::description(und_collection) == new_description, EINVALID_DATA);
    }
}
