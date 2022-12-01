module games::fighting_tests {
    use std::signer;
    use std::vector;
    use aptos_framework::genesis;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::account::create_account_for_test;

    use games::fighting;
    use coin::ggwp::GGWPCoin;
    use ggwp_core::gpass;

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    public entry fun functional(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        coin::ggwp::mint_to(ggwp_coin, 10000000000, games_addr);
        assert!(coin::balance<GGWPCoin>(games_addr) == 10000000000, 1);
        coin::ggwp::register(user);
        coin::ggwp::mint_to(ggwp_coin,  1100000000000, user_addr);
        assert!(coin::balance<GGWPCoin>(user_addr) == 1100000000000, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);
        gpass::add_reward_table_row(ggwp_core, 5000 * 100000000, 5);
        gpass::add_reward_table_row(ggwp_core, 10000 * 100000000, 10);
        gpass::add_reward_table_row(ggwp_core, 15000 * 100000000, 15);

        gpass::create_wallet(user);
        gpass::freeze_tokens(user, ggwp_core_addr, 1000000000000);
        assert!(gpass::get_balance(user_addr) == 10, 1);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        let now = timestamp::now_seconds();
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == true, 1);
        assert!(fighting::get_in_game_time(user_addr) == now, 1);

        timestamp::update_global_time_for_test_secs(now + 100);

        // Game finalized, user win
        let game_id = 1;
        let game_result = 1;
        let actions_log = fighting::get_test_actions_log(5);
        fighting::finalize_game(games, user_addr, ggwp_core_addr, game_id, game_result, actions_log);
        assert!(coin::balance<GGWPCoin>(games_addr) == 9999500000, 1);
        assert!(coin::balance<GGWPCoin>(user_addr) == 20000460000, 1);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == false, 1);
        assert!(fighting::get_in_game_time(user_addr) == 0, 1);
        assert!(fighting::get_game_player_by_id(games_addr, game_id) == user_addr, 1);
        assert!(fighting::get_game_result_by_id(games_addr, game_id) == game_result, 1);
        let log = fighting::get_game_log_by_id(games_addr, game_id);
        assert!(vector::length(&log) == 5, 1);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    public entry fun saved_games_max_len_test(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        coin::ggwp::mint_to(ggwp_coin, 10000000000, games_addr);
        assert!(coin::balance<GGWPCoin>(games_addr) == 10000000000, 1);
        coin::ggwp::register(user);
        coin::ggwp::mint_to(ggwp_coin,  1100000000000, user_addr);
        assert!(coin::balance<GGWPCoin>(user_addr) == 1100000000000, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);
        gpass::add_reward_table_row(ggwp_core, 5000 * 100000000, 5);
        gpass::add_reward_table_row(ggwp_core, 10000 * 100000000, 10);
        gpass::add_reward_table_row(ggwp_core, 15000 * 100000000, 15);

        gpass::create_wallet(user);
        gpass::freeze_tokens(user, ggwp_core_addr, 1000000000000);
        assert!(gpass::get_balance(user_addr) == 10, 1);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let now = timestamp::now_seconds();

        // Game start and finalized N times
        let game_id = 1;
        let game_result = 1;
        let actions_log = fighting::get_test_actions_log(5);
        while (game_id != 501) {
            gpass::mint_to(ggwp_core_addr, user_addr, 1);
            fighting::start_game(user, games_addr, ggwp_core_addr);
            now = now + 1;
            timestamp::update_global_time_for_test_secs(now);
            fighting::finalize_game(games, user_addr, ggwp_core_addr, game_id, game_result, actions_log);
            let log = fighting::get_game_log_by_id(games_addr, game_id);
            assert!(vector::length(&log) == 5, 1);
            game_id = game_id + 1;
        };

        assert!(fighting::get_saved_games_len(games_addr) == 500, 1);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    #[expected_failure(abort_code = 0x1007)]
    public entry fun invalid_actions_list_size(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        coin::ggwp::mint_to(ggwp_coin, 10000000000, games_addr);
        assert!(coin::balance<GGWPCoin>(games_addr) == 10000000000, 1);
        coin::ggwp::register(user);
        coin::ggwp::mint_to(ggwp_coin,  1100000000000, user_addr);
        assert!(coin::balance<GGWPCoin>(user_addr) == 1100000000000, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);
        gpass::add_reward_table_row(ggwp_core, 5000 * 100000000, 5);
        gpass::add_reward_table_row(ggwp_core, 10000 * 100000000, 10);
        gpass::add_reward_table_row(ggwp_core, 15000 * 100000000, 15);

        gpass::create_wallet(user);
        gpass::freeze_tokens(user, ggwp_core_addr, 1000000000000);
        assert!(gpass::get_balance(user_addr) == 10, 1);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        let now = timestamp::now_seconds();
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == true, 1);
        assert!(fighting::get_in_game_time(user_addr) == now, 1);

        timestamp::update_global_time_for_test_secs(now + 100);

        // Game finalized, user win
        let game_id = 1;
        let game_result = 1;
        let actions_log = fighting::get_test_actions_log(0);
        fighting::finalize_game(games, user_addr, ggwp_core_addr, game_id, game_result, actions_log);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    #[expected_failure(abort_code = 0x1006)]
    public entry fun not_in_game_test(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        assert!(coin::balance<GGWPCoin>(games_addr) == 0, 1);
        coin::ggwp::register(user);
        assert!(coin::balance<GGWPCoin>(user_addr) == 0, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);

        gpass::create_wallet(user);
        gpass::mint_to(ggwp_core_addr, user_addr, 10);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        let now = timestamp::now_seconds();
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == true, 1);
        assert!(fighting::get_in_game_time(user_addr) == now, 1);

        timestamp::update_global_time_for_test_secs(now + afk_timeout);

        // User tryes to start another game after afk timeout, finalize game
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == false, 1);
        assert!(fighting::get_in_game_time(user_addr) == 0, 1);

        // Game finalized before start game
        let game_id = 1;
        let game_result = 1;
        let actions_log = fighting::get_test_actions_log(5);
        fighting::finalize_game(games, user_addr, ggwp_core_addr, game_id, game_result, actions_log);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    #[expected_failure(abort_code = 0x1001)]
    public entry fun finalize_before_start_test(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        coin::ggwp::mint_to(ggwp_coin, 10000000000, games_addr);
        assert!(coin::balance<GGWPCoin>(games_addr) == 10000000000, 1);
        coin::ggwp::register(user);
        coin::ggwp::mint_to(ggwp_coin,  1100000000000, user_addr);
        assert!(coin::balance<GGWPCoin>(user_addr) == 1100000000000, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);
        gpass::add_reward_table_row(ggwp_core, 5000 * 100000000, 5);
        gpass::add_reward_table_row(ggwp_core, 10000 * 100000000, 10);
        gpass::add_reward_table_row(ggwp_core, 15000 * 100000000, 15);

        gpass::create_wallet(user);
        gpass::freeze_tokens(user, ggwp_core_addr, 1000000000000);
        assert!(gpass::get_balance(user_addr) == 10, 1);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // Game finalized before start game
        let game_id = 1;
        let game_result = 1;
        let actions_log = fighting::get_test_actions_log(5);
        fighting::finalize_game(games, user_addr, ggwp_core_addr, game_id, game_result, actions_log);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    #[expected_failure(abort_code = 0x1008)]
    public entry fun empty_play_to_earn_fund_test(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        assert!(coin::balance<GGWPCoin>(games_addr) == 0, 1);
        coin::ggwp::register(user);
        assert!(coin::balance<GGWPCoin>(user_addr) == 0, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);

        gpass::create_wallet(user);
        gpass::mint_to(ggwp_core_addr, user_addr, 10);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        let now = timestamp::now_seconds();
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == true, 1);
        assert!(fighting::get_in_game_time(user_addr) == now, 1);

        timestamp::update_global_time_for_test_secs(now + 100);

        // Empty reward fund
        let game_id = 1;
        let game_result = 1;
        let actions_log = fighting::get_test_actions_log(5);
        fighting::finalize_game(games, user_addr, ggwp_core_addr, game_id, game_result, actions_log);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    #[expected_failure(abort_code = 0x1004)]
    public entry fun still_in_game_test(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        assert!(coin::balance<GGWPCoin>(games_addr) == 0, 1);
        coin::ggwp::register(user);
        assert!(coin::balance<GGWPCoin>(user_addr) == 0, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);

        gpass::create_wallet(user);
        gpass::mint_to(ggwp_core_addr, user_addr, 10);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        let now = timestamp::now_seconds();
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == true, 1);
        assert!(fighting::get_in_game_time(user_addr) == now, 1);

        timestamp::update_global_time_for_test_secs(now + 100);

        // User still in game
        fighting::start_game(user, games_addr, ggwp_core_addr);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    public entry fun start_game_after_afk_timeout(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        assert!(coin::balance<GGWPCoin>(games_addr) == 0, 1);
        coin::ggwp::register(user);
        assert!(coin::balance<GGWPCoin>(user_addr) == 0, 1);

        let burn_period = 30 * 24 * 60 * 60;
        let reward_period = 60 * 60;
        gpass::initialize(ggwp_core, ac_fund_addr, burn_period, reward_period, 8, 15, 300);

        gpass::create_wallet(user);
        gpass::mint_to(ggwp_core_addr, user_addr, 10);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        let now = timestamp::now_seconds();
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == true, 1);
        assert!(fighting::get_in_game_time(user_addr) == now, 1);

        timestamp::update_global_time_for_test_secs(now + afk_timeout);

        // User tryes to start another game after afk timeout, finalize game
        fighting::start_game(user, games_addr, ggwp_core_addr);
        assert!(gpass::get_balance(user_addr) == 9, 1);
        assert!(fighting::get_in_game(user_addr) == false, 1);
        assert!(fighting::get_in_game_time(user_addr) == 0, 1);
    }

    #[test(games = @games, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, user = @0x1111)]
    #[expected_failure(abort_code = 0x1005)]
    public entry fun not_enough_gpass_test(games: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, user: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let user_addr = signer::address_of(user);
        create_account_for_test(user_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(games);
        assert!(coin::balance<GGWPCoin>(games_addr) == 0, 1);
        coin::ggwp::register(user);
        assert!(coin::balance<GGWPCoin>(user_addr) == 0, 1);

        gpass::create_wallet(user);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // User start game
        fighting::start_game(user, games_addr, ggwp_core_addr);
    }

    #[test(games = @games, accumulative_fund = @0x11223344)]
    public entry fun update_params_test(games: &signer, accumulative_fund: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let games_addr = signer::address_of(games);
        create_account_for_test(games_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);

        let afk_timeout = 1 * 60 * 60;
        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        fighting::initialize(games, ac_fund_addr, afk_timeout, reward_coefficient, gpass_daily_reward_coefficient, royalty);
        assert!(fighting::get_afk_timeout(games_addr) == afk_timeout, 1);
        assert!(fighting::get_reward_coefficient(games_addr) == reward_coefficient, 1);
        assert!(fighting::get_gpass_daily_reward_coefficient(games_addr) == gpass_daily_reward_coefficient, 1);
        assert!(fighting::get_royalty(games_addr) == royalty, 1);

        fighting::update_params(games, 333555, 4455, 20, 18);
        assert!(fighting::get_afk_timeout(games_addr) == 333555, 1);
        assert!(fighting::get_reward_coefficient(games_addr) == 4455, 1);
        assert!(fighting::get_gpass_daily_reward_coefficient(games_addr) == 20, 1);
        assert!(fighting::get_royalty(games_addr) == 18, 1);
    }

    #[test]
    public entry fun calc_reward_amount_test() {
        // If daily gpass reward bigger than reward
        assert!(fighting::calc_reward_amount(0, 10, 2, 100, 10) == 0, 1);
        assert!(fighting::calc_reward_amount(0, 0, 2, 100, 10) == 0, 1);
        // 0.00025 GGWP
        assert!(fighting::calc_reward_amount(1000000000, 2, 20000, 100, 10) == 25000, 1);
        // 6.150 GGWP
        assert!(fighting::calc_reward_amount(12300000000, 10, 2, 100, 10) == 615000000, 1);
        // If daily gpass reward less than reward
        // 0.5 GGWP: 5/10
        assert!(fighting::calc_reward_amount(12300000000, 10, 2, 5, 10) == 50000000, 1);
    }
}
