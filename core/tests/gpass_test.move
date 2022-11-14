#[test_only]
module ggwp_core::gpass_test {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::genesis;

    use ggwp_core::GPass;

    #[test(core_signer = @ggwp_core)]
    #[expected_failure(abort_code = 0x1002)]
    public entry fun double_initialize(core_signer: &signer) {
        let core_addr = signer::address_of(core_signer);
        create_account_for_test(core_addr);

        GPass::initialize(core_signer, 5000);
        assert!(GPass::get_total_amount(core_addr) == 0, 1);
        assert!(GPass::get_burn_period(core_addr) == 5000, 1);

        // Try to initialize twice
        GPass::initialize(core_signer, 6000);
    }

    // invalid mint auth
    #[test(core_signer = @ggwp_core, user = @0x11, invalid_auth = @0x22)]
    #[expected_failure(abort_code = 0x1006)]
    public entry fun mint_to_with_invalid_auth(core_signer: &signer, user: &signer, invalid_auth: &signer) {
        genesis::setup();

        let core_addr = signer::address_of(core_signer);
        let user_addr = signer::address_of(user);
        let invalid_auth_addr = signer::address_of(invalid_auth);
        create_account_for_test(core_addr);
        create_account_for_test(user_addr);
        create_account_for_test(invalid_auth_addr);

        GPass::initialize(core_signer, 50);
        GPass::create_wallet(user);
        assert!(GPass::get_balance(user_addr) == 0, 1);

        GPass::mint_to(invalid_auth, core_addr, user_addr, 5);
    }

    #[test(core_signer = @ggwp_core, user = @0x11)]
    public entry fun mint_to_with_burns(core_signer: &signer, user: &signer) {
        genesis::setup();

        let core_addr = signer::address_of(core_signer);
        let user_addr = signer::address_of(user);
        create_account_for_test(core_addr);
        create_account_for_test(user_addr);

        let now = timestamp::now_seconds();
        let burn_period = 300;
        GPass::initialize(core_signer, burn_period);

        GPass::create_wallet(user);
        assert!(GPass::get_balance(user_addr) == 0, 1);
        assert!(GPass::get_last_burned(user_addr) == now, 2);

        GPass::mint_to(core_signer, core_addr, user_addr, 5);
        assert!(GPass::get_balance(user_addr) == 5, 3);
        assert!(GPass::get_total_amount(core_addr) == 5, 4);

        GPass::mint_to(core_signer, core_addr, user_addr, 10);
        assert!(GPass::get_balance(user_addr) == 15, 5);
        assert!(GPass::get_total_amount(core_addr) == 15, 6);

        timestamp::update_global_time_for_test_secs(now + burn_period);

        GPass::mint_to(core_signer, core_addr, user_addr, 5);
        assert!(GPass::get_balance(user_addr) == 5, 8);
        assert!(GPass::get_total_amount(core_addr) == 5, 9);
    }

    #[test(core_signer = @ggwp_core, burner=@0x1212, user1 = @0x11, user2 = @0x22)]
    public entry fun burn_with_burns(core_signer: &signer, burner: &signer, user1: &signer, user2: &signer) {
        genesis::setup();

        let core_addr = signer::address_of(core_signer);
        let burner_addr = signer::address_of(burner);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        create_account_for_test(core_addr);
        create_account_for_test(burner_addr);
        create_account_for_test(user1_addr);
        create_account_for_test(user2_addr);

        let now = timestamp::now_seconds();
        let burn_period = 300;
        GPass::initialize(core_signer, burn_period);
        GPass::add_burner(core_signer, burner_addr);

        GPass::create_wallet(user1);
        GPass::create_wallet(user2);
        assert!(GPass::get_balance(user1_addr) == 0, 1);
        assert!(GPass::get_last_burned(user1_addr) == now, 2);
        assert!(GPass::get_balance(user2_addr) == 0, 3);
        assert!(GPass::get_last_burned(user2_addr) == now, 4);

        GPass::mint_to(core_signer, core_addr, user1_addr, 10);
        assert!(GPass::get_balance(user1_addr) == 10, 5);
        assert!(GPass::get_total_amount(core_addr) == 10, 6);

        GPass::mint_to(core_signer, core_addr, user2_addr, 15);
        assert!(GPass::get_balance(user2_addr) == 15, 7);
        assert!(GPass::get_total_amount(core_addr) == 25, 8);

        GPass::burn(burner, core_addr, user2_addr, 10);
        assert!(GPass::get_balance(user2_addr) == 5, 9);
        assert!(GPass::get_total_amount(core_addr) == 15, 10);

        timestamp::update_global_time_for_test_secs(now + burn_period);

        GPass::burn(burner, core_addr, user1_addr, 5);
        assert!(GPass::get_balance(user1_addr) == 0, 11);
        assert!(GPass::get_total_amount(core_addr) == 5, 12);

        GPass::burn(burner, core_addr, user2_addr, 5);
        assert!(GPass::get_balance(user1_addr) == 0, 13);
        assert!(GPass::get_total_amount(core_addr) == 0, 14);
    }
}
