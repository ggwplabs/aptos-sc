#[test_only]
module staking::staking_test {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::genesis;
    use aptos_framework::coin::{Self};
    use aptos_framework::account::create_account_for_test;

    use staking::staking;
    use coin::ggwp::GGWPCoin;

    const TIME: u64 = 1660032700;
    const DAY: u64 = 24 * 60 * 60;

    #[test(staking = @staking, ggwp_coin = @coin, accumulative_fund = @0x11223344, user1 = @0x11)]
    #[expected_failure(abort_code = 0x1001, location = staking::staking)]
    public entry fun withdraw_before_stake_test(staking: &signer, ggwp_coin: &signer, accumulative_fund: &signer, user1: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(TIME);

        let staking_addr = signer::address_of(staking);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        let user1_addr = signer::address_of(user1);
        create_account_for_test(staking_addr);
        create_account_for_test(ac_fund_addr);
        create_account_for_test(user1_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        coin::ggwp::register(user1);
        let user1_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user1_init_balance, user1_addr);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance, 1);

        let epoch_period = 10 * 24 * 60 * 60;
        let min_stake_amount = 300000000000;
        let hold_period = 12 * 60 * 60;
        let hold_royalty = 15;
        let royalty = 8;
        let apr_start = 45;
        let apr_step = 1;
        let apr_end = 5;

        staking::initialize(staking, ac_fund_addr, epoch_period, min_stake_amount, hold_period, hold_royalty, royalty, apr_start, apr_step, apr_end);
        assert!(staking::get_total_staked(staking_addr) == 0, 1);

        // User1 try to withdraw
        staking::withdraw(user1, staking_addr);
    }

    #[test(staking = @staking, ggwp_coin = @coin, accumulative_fund = @0x11223344, user1 = @0x11)]
    #[expected_failure(abort_code = 0x1009, location = staking::staking)]
    public entry fun additional_stake_test(staking: &signer, ggwp_coin: &signer, accumulative_fund: &signer, user1: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(TIME);

        let staking_addr = signer::address_of(staking);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        let user1_addr = signer::address_of(user1);
        create_account_for_test(staking_addr);
        create_account_for_test(ac_fund_addr);
        create_account_for_test(user1_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        coin::ggwp::register(user1);
        let user1_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user1_init_balance, user1_addr);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance, 1);

        let epoch_period = 10 * 24 * 60 * 60;
        let min_stake_amount = 300000000000;
        let hold_period = 12 * 60 * 60;
        let hold_royalty = 15;
        let royalty = 8;
        let apr_start = 45;
        let apr_step = 1;
        let apr_end = 5;

        staking::initialize(staking, ac_fund_addr, epoch_period, min_stake_amount, hold_period, hold_royalty, royalty, apr_start, apr_step, apr_end);
        assert!(staking::get_total_staked(staking_addr) == 0, 1);

        // User1 stake amount of tokens (3000 GGWP)
        let amount1 = 300000000000;
        let royalty_amount1 = staking::calc_royalty_amount(amount1, royalty);
        staking::stake(user1, staking_addr, amount1);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance - royalty_amount1 - amount1, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == amount1, 1);
        assert!(staking::get_total_staked(staking_addr) == amount1, 1);
        assert!(staking::get_staked(user1_addr) == amount1, 1);

        // User1 additional stake
        staking::stake(user1, staking_addr, amount1);
    }

    #[test(staking = @staking, ggwp_coin = @coin, accumulative_fund = @0x11223344, user1 = @0x11, user2 = @0x22, user3 = @0x33, funder = @0x44)]
    public entry fun functional(staking: &signer, ggwp_coin: &signer, accumulative_fund: &signer, user1: &signer, user2: &signer, user3: &signer, funder: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(TIME);

        let staking_addr = signer::address_of(staking);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        let user1_addr = signer::address_of(user1);
        let user2_addr = signer::address_of(user2);
        let user3_addr = signer::address_of(user3);
        let funder_addr = signer::address_of(funder);
        create_account_for_test(staking_addr);
        create_account_for_test(ac_fund_addr);
        create_account_for_test(user1_addr);
        create_account_for_test(user2_addr);
        create_account_for_test(user3_addr);
        create_account_for_test(funder_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        coin::ggwp::register(user1);
        let user1_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user1_init_balance, user1_addr);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance, 1);

        coin::ggwp::register(user2);
        let user2_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user2_init_balance, user2_addr);
        assert!(coin::balance<GGWPCoin>(user2_addr) == user2_init_balance, 1);

        coin::ggwp::register(user3);
        let user3_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user3_init_balance, user3_addr);
        assert!(coin::balance<GGWPCoin>(user3_addr) == user3_init_balance, 1);

        coin::ggwp::register(funder);
        coin::ggwp::mint_to(ggwp_coin, 20000 * 100000000, funder_addr);

        let epoch_period = 10 * 24 * 60 * 60;
        let min_stake_amount = 300000000000;
        let hold_period = 12 * 60 * 60;
        let hold_royalty = 15;
        let royalty = 8;
        let apr_start = 45;
        let apr_step = 1;
        let apr_end = 5;

        let now = timestamp::now_seconds();
        staking::initialize(staking, ac_fund_addr, epoch_period, min_stake_amount, hold_period, hold_royalty, royalty, apr_start, apr_step, apr_end);
        assert!(staking::get_total_staked(staking_addr) == 0, 1);
        assert!(staking::get_current_epoch_start_time(staking_addr) == now, 1);

        // User1 stake amount of tokens (3000 GGWP)
        let amount1 = 300000000000;
        let royalty_amount1 = staking::calc_royalty_amount(amount1, royalty);
        staking::stake(user1, staking_addr, amount1);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance - royalty_amount1 - amount1, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == amount1, 1);
        assert!(staking::get_total_staked(staking_addr) == amount1, 1);
        assert!(staking::get_staked(user1_addr) == amount1, 1);
        assert!(staking::get_stake_time(user1_addr) == now, 1);

        // User2 stake amount of tokens
        let amount2 = 300000000000;
        let royalty_amount2 = staking::calc_royalty_amount(amount2, royalty);
        staking::stake(user2, staking_addr, amount2);
        assert!(coin::balance<GGWPCoin>(user2_addr) == user2_init_balance - royalty_amount2 - amount2, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == amount1 + amount2, 1);
        assert!(staking::get_total_staked(staking_addr) == amount1 + amount2, 1);
        assert!(staking::get_staked(user2_addr) == amount2, 1);
        assert!(staking::get_stake_time(user2_addr) == now, 1);

        // User2 withdraw with hold royalty
        let hold_royalty_amount2 = staking::calc_royalty_amount(staking::get_staked(user2_addr), hold_royalty);
        staking::withdraw(user2, staking_addr);
        assert!(coin::balance<GGWPCoin>(user2_addr) == user2_init_balance - royalty_amount2 - hold_royalty_amount2, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2 + hold_royalty_amount2, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == amount1, 1);
        assert!(staking::get_total_staked(staking_addr) == amount1, 1);
        assert!(staking::get_staked(user2_addr) == 0, 1);
        assert!(staking::get_stake_time(user2_addr) == 0, 1);

        // Spent 2 epochs
        timestamp::update_global_time_for_test_secs(now + 2 * epoch_period);
        assert!(staking::get_current_epoch_start_time(staking_addr) == now + 2 * epoch_period, 1);
        let now = now + 2 * epoch_period;

        // Mint tokens to staking fund to pay rewards
        staking::deposit_staking_fund(funder, staking_addr, 100000000000);
        assert!(staking::get_staking_fund_balance(staking_addr) == 100000000000 + amount1, 1);
        let staking_fund_balance_before = 100000000000 + amount1;

        // User1 withdraw without hold royalty with 2 epochs reward
        let reward_amount1 = staking::get_user_unpaid_reward(staking_addr, user1_addr);
        staking::withdraw(user1, staking_addr);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance - royalty_amount1 + reward_amount1, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2 + hold_royalty_amount2, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == staking_fund_balance_before - amount1 - reward_amount1, 1);
        assert!(staking::get_total_staked(staking_addr) == 0, 1);
        assert!(staking::get_staked(user1_addr) == 0, 1);
        assert!(staking::get_stake_time(user1_addr) == 0, 1);

        // User3 stake amount of tokens not in 1 epoch
        timestamp::update_global_time_for_test_secs(now + 10 * epoch_period);
        assert!(staking::get_current_epoch_start_time(staking_addr) == now + 10 * epoch_period, 1);

        let staking_fund_balance_before = staking_fund_balance_before - amount1 - reward_amount1;

        let amount3 = 300000000000;
        let royalty_amount3 = staking::calc_royalty_amount(amount3, royalty);
        staking::stake(user3, staking_addr, amount3);
        assert!(coin::balance<GGWPCoin>(user3_addr) == user3_init_balance - royalty_amount3 - amount3, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2 + hold_royalty_amount2 + royalty_amount3, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == staking_fund_balance_before + amount3, 1);
        assert!(staking::get_total_staked(staking_addr) == amount3, 1);
        assert!(staking::get_staked(user3_addr) == amount3, 1);
        assert!(staking::get_stake_time(user3_addr) == now + 10 * epoch_period, 1);

        let now = now + 10 * epoch_period;
        timestamp::update_global_time_for_test_secs(now + 3 * epoch_period);
        assert!(staking::get_current_epoch_start_time(staking_addr) == now + 3 * epoch_period, 1);

        // User3 withdraw reward for 3 epochs
        let reward_amount3 = staking::get_user_unpaid_reward(staking_addr, user3_addr);
        staking::withdraw(user3, staking_addr);
        assert!(coin::balance<GGWPCoin>(user3_addr) == user3_init_balance - royalty_amount3 + reward_amount3, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == royalty_amount1 + royalty_amount2 + hold_royalty_amount2 + royalty_amount3, 1);
        assert!(staking::get_staking_fund_balance(staking_addr) == staking_fund_balance_before - reward_amount3, 1);
        assert!(staking::get_total_staked(staking_addr) == 0, 1);
        assert!(staking::get_staked(user3_addr) == 0, 1);
        assert!(staking::get_stake_time(user3_addr) == 0, 1);
    }

    #[test(staking = @staking, ggwp_coin = @coin, accumulative_fund = @0x11223344, user1 = @0x11)]
    #[expected_failure(abort_code = 0x1008, location = staking::staking)]
    public entry fun min_stake_amount_test(staking: &signer, ggwp_coin: &signer, accumulative_fund: &signer, user1: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(TIME);

        let staking_addr = signer::address_of(staking);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        let user1_addr = signer::address_of(user1);
        create_account_for_test(staking_addr);
        create_account_for_test(ac_fund_addr);
        create_account_for_test(user1_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        coin::ggwp::register(user1);
        let user1_init_balance = 20000 * 100000000;
        coin::ggwp::mint_to(ggwp_coin, user1_init_balance, user1_addr);
        assert!(coin::balance<GGWPCoin>(user1_addr) == user1_init_balance, 1);

        let epoch_period = 24 * 60 * 60;
        let min_stake_amount = 300000000000;
        let hold_period = 12 * 60 * 60;
        let hold_royalty = 15;
        let royalty = 8;
        let apr_start = 45;
        let apr_step = 1;
        let apr_end = 5;

        staking::initialize(staking, ac_fund_addr, epoch_period, min_stake_amount, hold_period, hold_royalty, royalty, apr_start, apr_step, apr_end);

        // User1 stake amount of tokens less than min_stake_amount
        let amount1 = 1000000000;
        staking::stake(user1, staking_addr, amount1);
    }

    #[test(staking = @staking, accumulative_fund = @0x11223344)]
    #[expected_failure(abort_code = 0x1001, location = staking::staking)]
    public entry fun update_before_initialize(staking: &signer, accumulative_fund: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(TIME);

        let staking_addr = signer::address_of(staking);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(staking_addr);
        create_account_for_test(ac_fund_addr);

        let epoch_period = 24 * 60 * 60;
        let min_stake_amount = 300000000000;
        let hold_period = 12 * 60 * 60;
        let hold_royalty = 15;
        let royalty = 8;
        staking::update_params(staking, epoch_period, min_stake_amount, hold_period, hold_royalty, royalty);
    }

    #[test(staking = @staking, accumulative_fund = @0x11223344)]
    public entry fun initialize_update_params_test(staking: &signer, accumulative_fund: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(TIME);

        let staking_addr = signer::address_of(staking);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(staking_addr);
        create_account_for_test(ac_fund_addr);

        let epoch_period = 24 * 60 * 60;
        let min_stake_amount = 300000000000;
        let hold_period = 12 * 60 * 60;
        let hold_royalty = 15;
        let royalty = 8;
        let apr_start = 45;
        let apr_step = 1;
        let apr_end = 5;

        let now = timestamp::now_seconds();
        staking::initialize(staking, ac_fund_addr, epoch_period, min_stake_amount, hold_period, hold_royalty, royalty, apr_start, apr_step, apr_end);
        assert!(staking::get_total_staked(staking_addr) == 0, 1);
        assert!(staking::get_start_time(staking_addr) == now, 1);
        assert!(staking::get_epoch_period(staking_addr) == epoch_period, 1);
        assert!(staking::get_min_stake_amount(staking_addr) == min_stake_amount, 1);
        assert!(staking::get_hold_period(staking_addr) == hold_period, 1);
        assert!(staking::get_hold_royalty(staking_addr) == hold_royalty, 1);
        assert!(staking::get_royalty(staking_addr) == royalty, 1);
        assert!(staking::get_apr_start(staking_addr) == 45, 1);
        assert!(staking::get_apr_step(staking_addr) == 1, 1);
        assert!(staking::get_apr_end(staking_addr) == 5, 1);

        assert!(staking::get_current_epoch_start_time(staking_addr) == now, 1);

        staking::update_params(staking, 100, 200, 300, 1, 2);
        assert!(staking::get_epoch_period(staking_addr) == 100, 1);
        assert!(staking::get_min_stake_amount(staking_addr) == 200, 1);
        assert!(staking::get_hold_period(staking_addr) == 300, 1);
        assert!(staking::get_hold_royalty(staking_addr) == 1, 1);
        assert!(staking::get_royalty(staking_addr) == 2, 1);

        assert!(staking::get_current_epoch_start_time(staking_addr) == now, 1);
    }

    #[test]
    public entry fun is_withdraw_royalty_test() {
        assert!(staking::is_withdraw_royalty(1660032700, 1660032700, 100) == true, 1);
        assert!(staking::is_withdraw_royalty(1660032700, 1660032650, 100) == true, 1);
        assert!(staking::is_withdraw_royalty(1660032700, 1660032800, 100) == true, 1);
        assert!(staking::is_withdraw_royalty(1660032700, 1660032500, 100) == false, 1);
        assert!(staking::is_withdraw_royalty(1660032700, 1660032300, 100) == false, 1);
    }

    #[test]
    public entry fun get_epoch_by_time_test() {
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME, 10 * DAY);
        assert!(epoch == 1, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 5 * DAY, 10 * DAY);
        assert!(epoch == 1, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 10 * DAY, 10 * DAY);
        assert!(epoch == 2, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 15 * DAY, 10 * DAY);
        assert!(epoch == 2, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 20 * DAY, 10 * DAY);
        assert!(epoch == 3, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 299 * DAY, 10 * DAY);
        assert!(epoch == 30, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 300 * DAY, 10 * DAY);
        assert!(epoch == 31, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 301 * DAY, 10 * DAY);
        assert!(epoch == 31, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 3000 * DAY, 10 * DAY);
        assert!(epoch == 301, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 3001 * DAY, 10 * DAY);
        assert!(epoch == 301, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 2 * 6 * 60 * 60, 6 * 60 * 60);
        assert!(epoch == 3, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = staking::get_epoch_by_time(TIME, TIME + 2 * 6 * 60 * 60 + 1, 6 * 60 * 60);
        assert!(epoch == 3, 1);
        assert!(is_epoch_start == false, 1);
    }

    #[test]
    public entry fun get_apr_by_epoch_test() {
        assert!(staking::get_apr_by_epoch(1, 45, 1, 5) == 45, 1);
        assert!(staking::get_apr_by_epoch(1, 45, 2, 5) == 45, 1);
        assert!(staking::get_apr_by_epoch(1, 45, 10, 5) == 45, 1);
        assert!(staking::get_apr_by_epoch(1, 45, 10, 40) == 45, 1);
        assert!(staking::get_apr_by_epoch(2, 45, 1, 5) == 44, 1);
        assert!(staking::get_apr_by_epoch(3, 45, 1, 5) == 43, 1);
        assert!(staking::get_apr_by_epoch(10, 45, 1, 5) == 36, 1);
        assert!(staking::get_apr_by_epoch(2, 45, 2, 5) == 43, 1);
        assert!(staking::get_apr_by_epoch(3, 45, 2, 5) == 41, 1);
        assert!(staking::get_apr_by_epoch(40, 45, 1, 5) == 6, 1);
        assert!(staking::get_apr_by_epoch(41, 45, 1, 5) == 5, 1);
        assert!(staking::get_apr_by_epoch(42, 45, 1, 5) == 5, 1);
        assert!(staking::get_apr_by_epoch(43, 45, 1, 5) == 5, 1);
        assert!(staking::get_apr_by_epoch(44, 45, 1, 5) == 5, 1);
        assert!(staking::get_apr_by_epoch(700, 45, 1, 5) == 5, 1);
    }

    #[test]
    public fun calc_user_past_epoch_test() {
        // User starts with staking
        let vec: vector<u64> = vector::empty();
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 5 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 9 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 10 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 11 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 19 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 2);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 20 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 21 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 3);
        assert!(staking::calc_user_past_epochs(TIME, TIME, TIME + 30 * DAY, 10 * DAY) == vec, 1);

        // User starts later in first epoch
        let vec: vector<u64> = vector::empty();
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 5 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 10 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 15 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 2);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 20 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 25 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 3);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 30 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 35 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 4);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 40 * DAY, 10 * DAY) == vec, 1);
        let vec: vector<u64> = vector::empty();
        assert!(staking::calc_user_past_epochs(TIME, TIME + 9 * DAY, TIME + 10 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 2);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 9 * DAY, TIME + 20 * DAY, 10 * DAY) == vec, 1);

        // User starts in next (4) epoch
        let vec: vector<u64> = vector::empty();
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 30 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 35 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 4);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 40 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 45 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 5);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 50 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 55 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 6);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 60 * DAY, 10 * DAY) == vec, 1);

        // User starts in half of epoch (4)
        let vec: vector<u64> = vector::empty();
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 35 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 40 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 45 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 5);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 50 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 55 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 6);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 60 * DAY, 10 * DAY) == vec, 1);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 65 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 7);
        assert!(staking::calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 70 * DAY, 10 * DAY) == vec, 1);
    }

    #[test]
    public fun calc_user_reward_amount_zero_epochs_test() {
        let amount = 10000000000;
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 5 * DAY) == 0, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 5 * DAY) == 0, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 10 * DAY) == 0, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 15 * DAY) == 0, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 10 * DAY, TIME + 10 * DAY) == 0, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 15 * DAY, TIME + 15 * DAY) == 0, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 15 * DAY, TIME + 20 * DAY) == 0, 1);
    }

    #[test]
    public fun calc_user_reward_amount_test() {
        let amount = 1000000000; // 10.0
        // User rewards before epoch
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 5 * DAY) == 0, 1);
        // User rewards for first epoch
        assert!(staking::calc_user_reward_amount(DAY, TIME, 10, 1, 5, amount, TIME, TIME + DAY) == 273972, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 10 * DAY) == 2743105, 1); // 0.02743105
        // User stake in half epoch
        let amount = 1000000000;
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 15 * DAY) == 12397391, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 83, 1, 5, amount, TIME, TIME + 15 * DAY) == 22973835, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 99, 1, 5, amount, TIME, TIME + 15 * DAY) == 27456745, 1);
        // Amounts less than 1 GGWP
        let amount = 50000000; // 0.5
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 1233402, 1);
        let amount = 80; // 0.000008
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 1, 1);
        let amount = 800; // 0.00008
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 19, 1);
        // User stake in next epoch
        let amount = 1900000000;
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 46869294, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 30 * DAY) == 69926986, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 40 * DAY) == 92712373, 1);
        // User stake in half next epoch
        let amount = 129950000000;
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 25 * DAY) == 3205613072, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 35 * DAY) == 4782637807, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 45 * DAY) == 6341038356, 1);
        // Check min apr limit
        let amount = 500000000;
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 6, 1, 5, amount, TIME, TIME + 50 * DAY) == 3574100, 1);
        // Big amounts check overflow
        let amount = 10000000000000; // 100000.0
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 100 * DAY) == 1172799009396, 1);
        assert!(staking::calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 1000 * DAY) == 4355105852568, 1);
    }
}
