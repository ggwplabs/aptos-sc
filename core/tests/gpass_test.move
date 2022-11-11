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
}
