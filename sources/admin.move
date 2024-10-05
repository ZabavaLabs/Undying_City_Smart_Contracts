module main::admin {

    use std::signer;
    const ENOT_ADMIN: u64 = 1;

    struct AdminData has key {
        admin_address: address
    }

    fun init_module(account: &signer) {
        let settings = AdminData { admin_address: signer::address_of(account) };

        move_to(account, settings);
    }

    public entry fun set_admin(caller: &signer, new_admin_addr: address) acquires AdminData {
        let caller_address = signer::address_of(caller);
        assert_is_admin(caller_address);
        let settings_data = borrow_global_mut<AdminData>(@main);
        settings_data.admin_address = new_admin_addr;
    }

    public fun assert_is_admin(addr: address) acquires AdminData {
        let settings_data = borrow_global<AdminData>(@main);
        assert!(addr == settings_data.admin_address, ENOT_ADMIN);
    }

    #[view]
    public fun get_admin_address(): address acquires AdminData {
        let admin_address = &borrow_global<AdminData>(@main).admin_address;
        *admin_address
    }

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        init_module(account);
    }
}
