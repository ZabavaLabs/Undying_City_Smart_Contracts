module main::admin {

    use std::signer;
    const ENOT_ADMIN: u64 = 1;

    struct AdminData has key {
        admin_address: address
    }

    struct AdminMigrationData has key {
        new_admin_address: address
    }

    fun init_module(account: &signer) {
        let settings = AdminData { admin_address: signer::address_of(account) };
        move_to(account, settings);
    }

    entry fun add_admin_migration_data(account: &signer) acquires AdminData {
        let caller_address = signer::address_of(account);
        assert_is_admin(caller_address);
        let settings = AdminMigrationData { new_admin_address: caller_address };
        move_to(account, settings);
    }

    public entry fun set_admin(caller: &signer, new_admin_addr: address) acquires AdminData, AdminMigrationData {
        let caller_address = signer::address_of(caller);
        assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<AdminMigrationData>(@main);
        settings_data.new_admin_address = new_admin_addr;
    }

    public entry fun acknowledge_admin(caller: &signer) acquires AdminData, AdminMigrationData {
        let caller_address = signer::address_of(caller);
        assert_is_new_admin(caller_address);
        let settings_data = borrow_global_mut<AdminData>(@main);
        settings_data.admin_address = caller_address;
    }

    public fun assert_is_admin(addr: address) acquires AdminData {
        let settings_data = borrow_global<AdminData>(@main);
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
    }

    public fun assert_is_new_admin(addr: address) acquires AdminMigrationData {
        let settings_data = borrow_global<AdminMigrationData>(@main);
        assert!(addr == settings_data.new_admin_address, ENOT_ADMIN);
    }

    #[view]
    public fun get_admin_address(): address acquires AdminData {
        let admin_address = &borrow_global<AdminData>(@main).admin_address;
        *admin_address
    }

    #[test_only]
    public fun initialize_for_test(account: &signer) acquires AdminData {
        init_module(account);
        add_admin_migration_data(account);
    }
}
