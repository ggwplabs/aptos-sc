#[test_only]
module ggwp_core::gpass_test {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::genesis;

    use ggwp_core::gpass;

    #[test(core_signer = @ggwp_core)]
    #[expected_failure(abort_code = 0x1002)]
    public entry fun double_initialize(core_signer: &signer) {
        genesis::setup();
        
        let core_addr = signer::address_of(core_signer);
        create_account_for_test(core_addr);

        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        gpass::initialize(core_signer, 5000, 5000, 8, 15, 300, reward_table);
        assert!(gpass::get_total_amount(core_addr) == 0, 1);
        assert!(gpass::get_burn_period(core_addr) == 5000, 2);

        // Try to initialize twice
        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        gpass::initialize(core_signer, 6000, 5000, 8, 15, 300, reward_table);
    }

    #[test(core_signer = @ggwp_core)]
    public entry fun update_params(core_signer: &signer) {
        genesis::setup();

        let core_addr = signer::address_of(core_signer);
        create_account_for_test(core_addr);

        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        gpass::initialize(core_signer, 5000, 7000, 8, 15, 300, reward_table);
        assert!(gpass::get_total_amount(core_addr) == 0, 1);
        assert!(gpass::get_burn_period(core_addr) == 5000, 2);

        let new_period = 11223344;
        gpass::update_burn_period(core_signer, new_period);
        assert!(gpass::get_burn_period(core_addr) == new_period, 3);

        // TODO: update freezing params
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
        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        gpass::initialize(core_signer, burn_period, 7000, 8, 15, 300, reward_table);

        gpass::create_wallet(user);
        assert!(gpass::get_balance(user_addr) == 0, 1);
        assert!(gpass::get_last_burned(user_addr) == now, 2);

        gpass::mint_to(core_addr, user_addr, 5);
        assert!(gpass::get_balance(user_addr) == 5, 3);
        assert!(gpass::get_total_amount(core_addr) == 5, 4);

        gpass::mint_to(core_addr, user_addr, 10);
        assert!(gpass::get_balance(user_addr) == 15, 5);
        assert!(gpass::get_total_amount(core_addr) == 15, 6);

        timestamp::update_global_time_for_test_secs(now + burn_period);

        gpass::mint_to(core_addr, user_addr, 5);
        assert!(gpass::get_balance(user_addr) == 5, 8);
        assert!(gpass::get_total_amount(core_addr) == 5, 9);
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
        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        gpass::initialize(core_signer, burn_period, 7000, 8, 15, 300, reward_table);
        gpass::add_burner(core_signer, burner_addr);

        gpass::create_wallet(user1);
        gpass::create_wallet(user2);
        assert!(gpass::get_balance(user1_addr) == 0, 1);
        assert!(gpass::get_last_burned(user1_addr) == now, 2);
        assert!(gpass::get_balance(user2_addr) == 0, 3);
        assert!(gpass::get_last_burned(user2_addr) == now, 4);

        gpass::mint_to(core_addr, user1_addr, 10);
        assert!(gpass::get_balance(user1_addr) == 10, 5);
        assert!(gpass::get_total_amount(core_addr) == 10, 6);

        gpass::mint_to(core_addr, user2_addr, 15);
        assert!(gpass::get_balance(user2_addr) == 15, 7);
        assert!(gpass::get_total_amount(core_addr) == 25, 8);

        gpass::burn(burner, core_addr, user2_addr, 10);
        assert!(gpass::get_balance(user2_addr) == 5, 9);
        assert!(gpass::get_total_amount(core_addr) == 15, 10);

        timestamp::update_global_time_for_test_secs(now + burn_period);

        gpass::burn(burner, core_addr, user1_addr, 5);
        assert!(gpass::get_balance(user1_addr) == 0, 11);
        assert!(gpass::get_total_amount(core_addr) == 5, 12);

        gpass::burn(burner, core_addr, user2_addr, 5);
        assert!(gpass::get_balance(user1_addr) == 0, 13);
        assert!(gpass::get_total_amount(core_addr) == 0, 14);
    }

    // TODO: freeze_tokens, withdraw_gpass, unfreeze_tokens tests
}
