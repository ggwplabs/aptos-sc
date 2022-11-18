#[test_only]
module ggwp_core::gpass_test {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::account::create_account_for_test;
    use aptos_framework::coin::{Self};
    use aptos_framework::genesis;

    use ggwp_core::gpass;
    use coin::ggwp::GGWPCoin;

    #[test(core_signer = @ggwp_core, accumulative_fund = @0x11112222)]
    #[expected_failure(abort_code = 0x1002)]
    public entry fun double_initialize(core_signer: &signer, accumulative_fund: &signer) {
        genesis::setup();

        let ac_fund_addr = signer::address_of(accumulative_fund);
        let core_addr = signer::address_of(core_signer);
        create_account_for_test(core_addr);
        create_account_for_test(ac_fund_addr);

        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        let burners: vector<address> = vector::empty();

        gpass::initialize(core_signer, ac_fund_addr, 5000, burners, 5000, 8, 15, 300, reward_table);
        assert!(gpass::get_total_amount(core_addr) == 0, 1);
        assert!(gpass::get_burn_period(core_addr) == 5000, 2);

        // Try to initialize twice
        gpass::initialize(core_signer, ac_fund_addr, 6000, burners, 5000, 8, 15, 300, reward_table);
    }

    #[test(core_signer = @ggwp_core, accumulative_fund = @0x11112222)]
    public entry fun update_params(core_signer: &signer, accumulative_fund: &signer) {
        genesis::setup();

        let ac_fund_addr = signer::address_of(accumulative_fund);
        let core_addr = signer::address_of(core_signer);
        create_account_for_test(core_addr);

        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        let burners: vector<address> = vector::empty();
        gpass::initialize(core_signer, ac_fund_addr, 5000, burners, 7000, 8, 15, 300, reward_table);
        assert!(gpass::get_total_amount(core_addr) == 0, 1);
        assert!(gpass::get_burn_period(core_addr) == 5000, 2);

        let new_period = 11223344;
        gpass::update_burn_period(core_signer, new_period);
        assert!(gpass::get_burn_period(core_addr) == new_period, 3);

        let new_reward_period = 11223344;
        let new_royalty = 20;
        let new_unfreeze_royalty = 40;
        let new_unfreeze_lock_period = 600;
        gpass::update_freezing_params(core_signer, new_reward_period, new_royalty, new_unfreeze_royalty, new_unfreeze_lock_period, reward_table);
        assert!(gpass::get_reward_period(core_addr) == new_reward_period, 4);
        assert!(gpass::get_royalty(core_addr) == new_royalty, 5);
        assert!(gpass::get_unfreeze_royalty(core_addr) == new_unfreeze_royalty, 6);
        assert!(gpass::get_unfreeze_lock_period(core_addr) == new_unfreeze_lock_period, 7);

        let new_reward_table: vector<gpass::RewardTableRow> = vector::empty();
        vector::push_back(&mut new_reward_table, gpass::construct_row(5000 * 100000000, 5));
        vector::push_back(&mut new_reward_table, gpass::construct_row(10000 * 100000000, 10));
        vector::push_back(&mut new_reward_table, gpass::construct_row(15000 * 100000000, 15));
        gpass::update_freezing_params(core_signer, new_reward_period, new_royalty, new_unfreeze_royalty, new_unfreeze_lock_period, new_reward_table);

        let reward_table = gpass::get_reward_table(core_addr);
        assert!(vector::length(&reward_table) == vector::length(&new_reward_table), 8);
        assert!(reward_table == new_reward_table, 9);
    }

    #[test(core_signer = @ggwp_core, accumulative_fund = @0x11112222, user = @0x11)]
    public entry fun mint_to_with_burns(core_signer: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();

        let ac_fund_addr = signer::address_of(accumulative_fund);
        let core_addr = signer::address_of(core_signer);
        let user_addr = signer::address_of(user);
        create_account_for_test(core_addr);
        create_account_for_test(user_addr);
        create_account_for_test(ac_fund_addr);

        let now = timestamp::now_seconds();
        let burn_period = 300;
        let reward_table: vector<gpass::RewardTableRow> = vector::empty();
        let burners: vector<address> = vector::empty();
        gpass::initialize(core_signer, ac_fund_addr, burn_period, burners, 7000, 8, 15, 300, reward_table);

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

    #[test(core_signer = @ggwp_core, accumulative_fund = @0x11112222, burner=@0x1212, user1 = @0x11, user2 = @0x22)]
    public entry fun burn_with_burns(core_signer: &signer, accumulative_fund: &signer, burner: &signer, user1: &signer, user2: &signer) {
        genesis::setup();

        let ac_fund_addr = signer::address_of(accumulative_fund);
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
        let burners: vector<address> = vector::empty();
        gpass::initialize(core_signer, ac_fund_addr, burn_period, burners, 7000, 8, 15, 300, reward_table);
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

    #[test(core_signer = @ggwp_core, ggwp_coin = @coin, accumulative_fund = @0x11112222, user1 = @0x11, user2 = @0x22)]
    public entry fun functional(core_signer: &signer, ggwp_coin: &signer, accumulative_fund: &signer, user1: &signer, user2: &signer) {
        genesis::setup();

        let ac_fund_addr = signer::address_of(accumulative_fund);
        let core_addr = signer::address_of(core_signer);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        create_account_for_test(ac_fund_addr);
        create_account_for_test(core_addr);
        create_account_for_test(user1_addr);
        create_account_for_test(user2_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        coin::ggwp::register(user1);
        let user1_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user1_init_balance, user1_addr);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance, 1);

        coin::ggwp::register(user2);
        let user2_init_balance = 30000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user2_init_balance, user2_addr);
        assert!(coin::balance<GGWPCoin>(user2_addr) == user2_init_balance, 1);

        let now = timestamp::now_seconds();
        let burn_period = 4 * 24 * 60 * 60;
        let reward_period = 24 * 60 * 60;
        let unfreeze_lock_period = 2 * 24 * 60 * 60;
        let reward_table: vector<gpass::RewardTableRow> = gpass::get_test_reward_table();
        let burners: vector<address> = vector::empty();
        gpass::initialize(core_signer, ac_fund_addr, burn_period, burners, reward_period, 8, 15, unfreeze_lock_period, reward_table);

        gpass::create_wallet(user1);
        gpass::create_wallet(user2);
        assert!(gpass::get_balance(user1_addr) == 0, 1);
        assert!(gpass::get_last_burned(user1_addr) == now, 2);
        assert!(gpass::get_balance(user2_addr) == 0, 3);
        assert!(gpass::get_last_burned(user2_addr) == now, 4);

        // User1 freeze 5000 GGWP
        let freeze_amount1 = 5000 * 100000000;
        let royalty_amount1 = gpass::calc_royalty_amount(freeze_amount1, 8);
        gpass::freeze_tokens(user1, core_addr, freeze_amount1);
        assert!(coin::balance<GGWPCoin>(user1_addr) == (user1_init_balance - freeze_amount1 - royalty_amount1), 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1, 1);
        assert!(gpass::get_balance(user1_addr) == 5, 1);
        assert!(gpass::get_last_getting_gpass(user1_addr) == now, 1);
        assert!(gpass::get_treasury_balance(core_addr) == freeze_amount1, 1);
        assert!(gpass::get_total_freezed(core_addr) == freeze_amount1, 1);
        assert!(gpass::get_total_users_freezed(core_addr) == 1, 1);
        assert!(gpass::get_daily_gpass_reward(core_addr) == 5, 1);

        // User2 freeze 10000 GGWP
        let freeze_amount2 = 10000 * 100000000;
        let royalty_amount2 = gpass::calc_royalty_amount(freeze_amount2, 8);
        gpass::freeze_tokens(user2, core_addr, freeze_amount2);
        assert!(coin::balance<GGWPCoin>(user2_addr) == (user2_init_balance - freeze_amount2 - royalty_amount2), 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2, 1);
        assert!(gpass::get_balance(user2_addr) == 10, 1);
        assert!(gpass::get_last_getting_gpass(user2_addr) == now, 1);
        assert!(gpass::get_treasury_balance(core_addr) == freeze_amount1 + freeze_amount2, 1);
        assert!(gpass::get_total_freezed(core_addr) == freeze_amount1 + freeze_amount2, 1);
        assert!(gpass::get_total_users_freezed(core_addr) == 2, 1);

        // Check virtual gpass earned
        assert!(gpass::get_earned_gpass_in_time(core_addr, user1_addr, now + 2 * reward_period) == 10, 1);
        assert!(gpass::get_earned_gpass_in_time(core_addr, user2_addr, now + 2 * reward_period) == 20, 1);

        // User1 withdraw gpass before burn period
        let now = now + 2 * reward_period;
        timestamp::update_global_time_for_test_secs(now);

        gpass::withdraw_gpass(user1, core_addr);
        assert!(gpass::get_balance(user1_addr) == 15, 1);
        assert!(gpass::get_last_getting_gpass(user1_addr) == now, 1);

        // User1 withdraw gpass after burn period
        // old gpass was burned, new gpass was minted for every reward_period
        let now = now + 2 * reward_period;
        timestamp::update_global_time_for_test_secs(now);

        gpass::withdraw_gpass(user1, core_addr);
        assert!(gpass::get_balance(user1_addr) == 10, 1);
        assert!(gpass::get_last_getting_gpass(user1_addr) == now, 1);

        // User2 unfreeze tokens without unfreeze royalty
        gpass::unfreeze(user2, core_addr);
        assert!(coin::balance<GGWPCoin>(user2_addr) == (user2_init_balance - royalty_amount2), 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2, 1);
        assert!(gpass::get_freezed_amount(user2_addr) == 0, 1);
        assert!(gpass::get_balance(user2_addr) == 40, 1);
        assert!(gpass::get_last_getting_gpass(user2_addr) == now, 1);
        assert!(gpass::get_treasury_balance(core_addr) == freeze_amount1, 1);
        assert!(gpass::get_total_freezed(core_addr) == freeze_amount1, 1);
        assert!(gpass::get_total_users_freezed(core_addr) == 1, 1);

        // User2 freeze and unfreeze tokens with unfreeze royalty
        let now = now + 20 * 24 * 60 * 60;
        timestamp::update_global_time_for_test_secs(now);

        let user2_before_balance = coin::balance<GGWPCoin>(user2_addr);
        let freeze_amount3 = 15000 * 100000000;
        let royalty_amount3 = gpass::calc_royalty_amount(freeze_amount3, 8);
        gpass::freeze_tokens(user2, core_addr, freeze_amount3);

        assert!(coin::balance<GGWPCoin>(user2_addr) == (user2_before_balance - freeze_amount3 - royalty_amount3), 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2 + royalty_amount3, 1);
        assert!(gpass::get_freezed_amount(user2_addr) == freeze_amount3, 1);
        assert!(gpass::get_balance(user2_addr) == 15, 1);
        assert!(gpass::get_last_getting_gpass(user2_addr) == now, 1);
        assert!(gpass::get_treasury_balance(core_addr) == freeze_amount1 + freeze_amount3, 1);
        assert!(gpass::get_total_freezed(core_addr) == freeze_amount1 + freeze_amount3, 1);
        assert!(gpass::get_total_users_freezed(core_addr) == 2, 1);

        let unfreeze_royalty_amount = gpass::calc_royalty_amount(freeze_amount3, 15);
        gpass::unfreeze(user2, core_addr);

        assert!(coin::balance<GGWPCoin>(user2_addr) == (user2_before_balance - royalty_amount3 - unfreeze_royalty_amount), 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2 + royalty_amount3 + unfreeze_royalty_amount, 1);
        assert!(gpass::get_balance(user2_addr) == 15, 1);
        assert!(gpass::get_last_getting_gpass(user2_addr) == now, 1);
        assert!(gpass::get_treasury_balance(core_addr) == freeze_amount1, 1);
        assert!(gpass::get_total_freezed(core_addr) == freeze_amount1, 1);
        assert!(gpass::get_total_users_freezed(core_addr) == 1, 1);
    }
}
