#[test_only]
module gateway::gateway_test {
    use std::signer;
    use std::string;
    use aptos_framework::genesis;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::account::create_account_for_test;

    use gateway::gateway;
    use coin::ggwp::GGWPCoin;
    use ggwp_core::gpass;

    // Errors from gateway module
    const ERR_NOT_AUTHORIZED: u64 = 0x1000;
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_ZERO_DEPOSIT_AMOUNT: u64 = 0x1003;
    const ERR_PROJECT_NOT_EXISTS: u64 = 0x1004;
    const ERR_PROJECT_BLOCKED: u64 = 0x1005;
    const ERR_INVALID_PROJECT_ID: u64 = 0x1006;
    const ERR_INVALID_PROJECT_NAME: u64 = 0x1007;
    const ERR_INVALID_GPASS_COST: u64 = 0x1008;
    const ERR_ALREADY_REMOVED: u64 = 0x1009;
    const ERR_ALREADY_BLOCKED: u64 = 0x1010;
    const ERR_NOT_BLOCKED: u64 = 0x1011;
    const ERR_NOT_ENOUGH_GPASS: u64 = 0x1012;
    const ERR_PLAYER_INFO_NOT_EXISTS: u64 = 0x1013;
    const ERR_PLAYER_BLOCKED: u64 = 0x1014;

    // CONST
    const MAX_PROJECT_NAME_LEN: u64 = 128;

    // TODO: start_game_test, finalize_game_test

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    public entry fun block_unblock_player_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, ggwp_core_addr, ac_fund_addr, contributor_addr, player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"test project game");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);

        gpass::mint_to(ggwp_core_addr, player_addr, 5);

        gateway::start_game(player, gateway_addr, ggwp_core_addr, contributor_addr, 1);
        assert!(gateway::get_player_is_blocked(player_addr) == false, 1);

        let reason = string::utf8(b"Test reason");
        gateway::block_player(gateway, player_addr, reason);
        assert!(gateway::get_player_is_blocked(player_addr) == true, 1);

        gateway::unblock_player(gateway, player_addr);
        assert!(gateway::get_player_is_blocked(player_addr) == false, 1);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    #[expected_failure(abort_code = ERR_PLAYER_BLOCKED, location = gateway::gateway)]
    public entry fun blocked_player_start_game_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, ggwp_core_addr, ac_fund_addr, contributor_addr, player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"test project game");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);

        gpass::mint_to(ggwp_core_addr, player_addr, 5);

        gateway::start_game(player, gateway_addr, ggwp_core_addr, contributor_addr, 1);
        assert!(gateway::get_player_is_blocked(player_addr) == false, 1);

        let reason = string::utf8(b"Test reason");
        gateway::block_player(gateway, player_addr, reason);
        assert!(gateway::get_player_is_blocked(player_addr) == true, 1);

        // Blocked player start the game
        gateway::start_game(player, gateway_addr, ggwp_core_addr, contributor_addr, 1);
    }


    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    public entry fun block_unblock_project_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, _ggwp_core_addr, ac_fund_addr, contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"test project game");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);
        assert!(gateway::get_project_is_blocked(contributor_addr) == false, 1);

        // Block project
        let reason = string::utf8(b"Test reason");
        gateway::block_project(gateway, contributor_addr, 1, reason);
        assert!(gateway::get_project_is_blocked(contributor_addr) == true, 1);

        // Unblock project
        gateway::unblock_project(gateway, contributor_addr, 1);
        assert!(gateway::get_project_is_blocked(contributor_addr) == false, 1);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    #[expected_failure(abort_code = ERR_PROJECT_BLOCKED, location = gateway::gateway)]
    public entry fun start_game_in_blocked_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, ggwp_core_addr, ac_fund_addr, contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"test project game");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);
        assert!(gateway::get_project_is_blocked(contributor_addr) == false, 1);

        // Block project
        let reason = string::utf8(b"Test reason");
        gateway::block_project(gateway, contributor_addr, 1, reason);
        assert!(gateway::get_project_is_blocked(contributor_addr) == true, 1);

        // player try to start game in blocked project
        gateway::start_game(player, gateway_addr, ggwp_core_addr, contributor_addr, 1);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    #[expected_failure(abort_code = ERR_INVALID_PROJECT_NAME, location = gateway::gateway)]
    public entry fun invalid_project_name_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, _ggwp_core_addr, ac_fund_addr, _contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"");
        while (string::length(&project_name) != MAX_PROJECT_NAME_LEN + 1) {
            string::append(&mut project_name, string::utf8(b"a"));
        };
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    #[expected_failure(abort_code = ERR_INVALID_PROJECT_NAME, location = gateway::gateway)]
    public entry fun invalid_project_name_test2(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, _ggwp_core_addr, ac_fund_addr, _contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    public entry fun sign_up_remove_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, _ggwp_core_addr, ac_fund_addr, contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);
        assert!(gateway::get_project_counter(gateway_addr) == 0, 1);

        let gpass_cost = 5;
        let project_name = string::utf8(b"test game project");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);
        assert!(gateway::get_project_counter(gateway_addr) == 1, 1);
        assert!(gateway::get_project_id(contributor_addr) == 1, 1);
        assert!(gateway::get_project_gpass_cost(contributor_addr) == gpass_cost, 1);
        assert!(gateway::get_project_name(contributor_addr) == project_name, 1);
        assert!(gateway::get_project_is_blocked(contributor_addr) == false, 1);
        assert!(gateway::get_project_is_removed(contributor_addr) == false, 1);

        gateway::remove(contributor, gateway_addr);
        assert!(gateway::get_project_id(contributor_addr) == 0, 1);
        assert!(gateway::get_project_gpass_cost(contributor_addr) == 0, 1);
        assert!(gateway::get_project_name(contributor_addr) == string::utf8(b""), 1);
        assert!(gateway::get_project_is_blocked(contributor_addr) == false, 1);
        assert!(gateway::get_project_is_removed(contributor_addr) == true, 1);

        let gpass_cost = 10;
        let project_name = string::utf8(b"another test game project");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);
        assert!(gateway::get_project_counter(gateway_addr) == 2, 1);
        assert!(gateway::get_project_id(contributor_addr) == 2, 1);
        assert!(gateway::get_project_gpass_cost(contributor_addr) == gpass_cost, 1);
        assert!(gateway::get_project_name(contributor_addr) == project_name, 1);
        assert!(gateway::get_project_is_blocked(contributor_addr) == false, 1);
        assert!(gateway::get_project_is_removed(contributor_addr) == false, 1);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    public entry fun play_to_earn_fund_deposit_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, _ggwp_core_addr, ac_fund_addr, contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);
        assert!(gateway::play_to_earn_fund_balance(gateway_addr) == 0, 1);

        coin::ggwp::register(contributor);
        coin::ggwp::mint_to(ggwp_coin, 500000000000, contributor_addr);
        assert!(coin::balance<GGWPCoin>(contributor_addr) == 500000000000, 1);

        let fund_amount = 250000000000;
        gateway::play_to_earn_fund_deposit(contributor, gateway_addr, fund_amount);
        assert!(gateway::play_to_earn_fund_balance(gateway_addr) == fund_amount, 1);
        assert!(coin::balance<GGWPCoin>(contributor_addr) == 250000000000, 1);

        let fund_amount = 250000000000;
        gateway::play_to_earn_fund_deposit(contributor, gateway_addr, fund_amount );
        assert!(gateway::play_to_earn_fund_balance(gateway_addr) == fund_amount * 2, 1);
        assert!(coin::balance<GGWPCoin>(contributor_addr) == 0, 1);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    #[expected_failure(abort_code = ERR_PROJECT_NOT_EXISTS, location = gateway::gateway)]
    public entry fun unexists_project_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, ggwp_core_addr, ac_fund_addr, contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        // player start game in unexists project
        gateway::start_game(player, gateway_addr, ggwp_core_addr, contributor_addr, 1);
    }

    #[test(gateway = @gateway, ggwp_coin = @coin, ggwp_core = @ggwp_core, accumulative_fund = @0x11223344, contributor = @0x2222, player = @0x1111)]
    #[expected_failure(abort_code = ERR_NOT_ENOUGH_GPASS, location = gateway::gateway)]
    public entry fun not_enough_gpass_test(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer) {
        let (gateway_addr, ggwp_core_addr, ac_fund_addr, contributor_addr, _player_addr)
            = fixture_setup(gateway, ggwp_coin, ggwp_core, accumulative_fund, contributor, player);

        let reward_coefficient = 20000;
        let gpass_daily_reward_coefficient = 10;
        let royalty = 8;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, gpass_daily_reward_coefficient, royalty);

        let gpass_cost = 5;
        let project_name = string::utf8(b"test game project");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);

        // Player start game without GPASS
        gateway::start_game(player, gateway_addr, ggwp_core_addr, contributor_addr, 1);
    }

    fun fixture_setup(gateway: &signer, ggwp_coin: &signer, ggwp_core: &signer, accumulative_fund: &signer, contributor: &signer, player: &signer)
    : (address, address, address, address, address) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let gateway_addr = signer::address_of(gateway);
        create_account_for_test(gateway_addr);
        let ggwp_core_addr = signer::address_of(ggwp_core);
        create_account_for_test(ggwp_core_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let contributor_addr = signer::address_of(contributor);
        create_account_for_test(contributor_addr);
        let player_addr = signer::address_of(player);
        create_account_for_test(player_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(gateway);
        assert!(coin::balance<GGWPCoin>(gateway_addr) == 0, 1);
        coin::ggwp::register(player);
        assert!(coin::balance<GGWPCoin>(player_addr) == 0, 1);

        gpass::initialize(ggwp_core, ac_fund_addr, 5000, 5000, 8, 15, 300);
        gpass::create_wallet(player);

        (gateway_addr, ggwp_core_addr, ac_fund_addr, contributor_addr, player_addr)
    }
}
