module games::fighting {
    use std::signer;
    use std::vector;
    use std::table_with_length;
    use std::table_with_length::TableWithLength;
    use aptos_framework::timestamp;
    use aptos_framework::coin;

    use ggwp_core::gpass;
    use coin::ggwp::GGWPCoin;

    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_INVALID_AFK_TIMEOUT: u64 = 0x1003;
    const ERR_STILL_IN_GAME: u64 = 0x1004;
    const ERR_NOT_ENOUGH_GPASS: u64 = 0x1005;
    const ERR_NOT_IN_GAME: u64 = 0x1006;
    const ERR_INVALID_ACTIONS_SIZE: u64 = 0x1007;
    const ERR_EMPTY_PLAY_TO_EARN_FUND: u64 = 0x1008;

    struct FightingSettings has key, store {
        accumulative_fund: address,
        afk_timeout: u64,
        gpass_daily_reward_coefficient: u64,
        reward_coefficient: u64,
        royalty: u8,
    }

    struct UserFightingInfo has key, store {
        in_game: bool,
        in_game_time: u64,
    }

    struct IdentityAction has store, copy, drop {
        who: u8,
        action: u8,
    }

    struct GameInfo has store {
        player: address,
        result: u8,
        actions_log: vector<IdentityAction>,
    }

    struct SavedGames has key, store {
        games: TableWithLength<u64, GameInfo>,
    }

    /// Initialize fighting settings.
    public entry fun initialize(games: &signer,
        accumulative_fund: address,
        afk_timeout: u64,
        reward_coefficient: u64,
        gpass_daily_reward_coefficient: u64,
        royalty: u8,
    ) {
        let games_addr = signer::address_of(games);
        assert!(!exists<FightingSettings>(games_addr), ERR_ALREADY_INITIALIZED);

        assert!(afk_timeout > 0, ERR_INVALID_AFK_TIMEOUT);

        let fighting_settings = FightingSettings {
            accumulative_fund: accumulative_fund,
            afk_timeout: afk_timeout,
            reward_coefficient: reward_coefficient,
            gpass_daily_reward_coefficient: gpass_daily_reward_coefficient,
            royalty: royalty,
        };
        move_to(games, fighting_settings);

        let saved_games = SavedGames {
            games: table_with_length::new<u64, GameInfo>(),
        };
        move_to(games, saved_games);
    }

    public entry fun update_params(games: &signer,
        afk_timeout: u64,
        reward_coefficient: u64,
        gpass_daily_reward_coefficient: u64,
        royalty: u8,
    ) acquires FightingSettings {
        let games_addr = signer::address_of(games);
        assert!(exists<FightingSettings>(games_addr), ERR_NOT_INITIALIZED);

        let fighting_settings = borrow_global_mut<FightingSettings>(games_addr);
        fighting_settings.afk_timeout = afk_timeout;
        fighting_settings.reward_coefficient = reward_coefficient;
        fighting_settings.gpass_daily_reward_coefficient = gpass_daily_reward_coefficient;
        fighting_settings.royalty = royalty;
    }

    /// User starts new game session and pays GPASS for it.
    public entry fun start_game(user: &signer, games_addr: address, ggwp_core_addr: address) acquires FightingSettings, UserFightingInfo {
        assert!(exists<FightingSettings>(games_addr), ERR_NOT_INITIALIZED);
        let fighting_settings = borrow_global<FightingSettings>(games_addr);

        let user_addr = signer::address_of(user);
        if (exists<UserFightingInfo>(user_addr) == false) {
            let user_fighting_info = UserFightingInfo {
                in_game: false,
                in_game_time: 0,
            };
            move_to(user, user_fighting_info);
        };

        let now = timestamp::now_seconds();
        let user_fighting_info = borrow_global_mut<UserFightingInfo>(user_addr);
        if (user_fighting_info.in_game == true && user_fighting_info.in_game_time != 0) {
            let spent_time = now - user_fighting_info.in_game_time;
            assert!(spent_time >= fighting_settings.afk_timeout, ERR_STILL_IN_GAME);
            user_fighting_info.in_game = false;
            user_fighting_info.in_game_time = 0;
            return
        };

        assert!(gpass::get_balance(user_addr) != 0, ERR_NOT_ENOUGH_GPASS);

        // Burn 1 GPASS from user wallet
        gpass::burn(user, ggwp_core_addr, 1);

        user_fighting_info.in_game = true;
        user_fighting_info.in_game_time = now;
    }

    /// User finalize the game.
    public entry fun finalize_game(games: &signer,
        user_addr: address,
        ggwp_core_addr: address,
        game_id: u64,
        game_result: u8,
        actions_log: vector<IdentityAction>
    ) acquires FightingSettings, UserFightingInfo, SavedGames {
        let games_addr = signer::address_of(games);
        assert!(exists<FightingSettings>(games_addr), ERR_NOT_INITIALIZED);
        assert!(exists<SavedGames>(games_addr), ERR_NOT_INITIALIZED);
        assert!(exists<UserFightingInfo>(user_addr), ERR_NOT_INITIALIZED);

        let fighting_settings = borrow_global<FightingSettings>(games_addr);
        let saved_games = borrow_global_mut<SavedGames>(games_addr);
        let user_fighting_info = borrow_global_mut<UserFightingInfo>(user_addr);
        assert!(user_fighting_info.in_game == true, ERR_NOT_IN_GAME);
        assert!(vector::is_empty(&actions_log) == false, ERR_INVALID_ACTIONS_SIZE);

        // Save results
        let game_info = GameInfo {
            player: user_addr,
            result: game_result,
            actions_log: actions_log,
        };
        table_with_length::add(&mut saved_games.games, game_id, game_info);

        // if user Win
        if (game_result == 1) {
            let play_to_earn_fund_amount = coin::balance<GGWPCoin>(games_addr);
            assert!(play_to_earn_fund_amount != 0, ERR_EMPTY_PLAY_TO_EARN_FUND);

            let reward_amount = calc_reward_amount(
                play_to_earn_fund_amount,
                gpass::get_total_users_freezed(ggwp_core_addr),
                fighting_settings.reward_coefficient,
                gpass::get_daily_gpass_reward(ggwp_core_addr),
                fighting_settings.gpass_daily_reward_coefficient,
            );

            let royalty_amount = calc_royalty_amount(reward_amount, fighting_settings.royalty);
            // Transfer reward_amount - royalty_amount to user from play_to_earn_fund
            coin::transfer<GGWPCoin>(games, user_addr, reward_amount - royalty_amount);
            // Transfer royalty_amount to accumulative fund from play_to_earn_fund
            coin::transfer<GGWPCoin>(games, fighting_settings.accumulative_fund, royalty_amount);
        };

        // Set up user status
        user_fighting_info.in_game = false;
        user_fighting_info.in_game_time = 0;
    }

    // Getters.

    public fun get_saved_games_len(games_addr: address): u64 acquires SavedGames {
        let saved_games = borrow_global<SavedGames>(games_addr);
        table_with_length::length(&saved_games.games)
    }

    public fun get_game_player_by_id(games_addr: address, game_id: u64): address acquires SavedGames {
        let saved_games = borrow_global<SavedGames>(games_addr);
        table_with_length::borrow(&saved_games.games, game_id).player
    }

    public fun get_game_result_by_id(games_addr: address, game_id: u64): u8 acquires SavedGames {
        let saved_games = borrow_global<SavedGames>(games_addr);
        table_with_length::borrow(&saved_games.games, game_id).result
    }

    public fun get_game_log_by_id(games_addr: address, game_id: u64): vector<IdentityAction> acquires SavedGames {
        let saved_games = borrow_global<SavedGames>(games_addr);
        table_with_length::borrow(&saved_games.games, game_id).actions_log
    }

    public fun get_in_game(user_addr: address): bool acquires UserFightingInfo {
        borrow_global<UserFightingInfo>(user_addr).in_game
    }

    public fun get_in_game_time(user_addr: address): u64 acquires UserFightingInfo {
        borrow_global<UserFightingInfo>(user_addr).in_game_time
    }

    public fun get_afk_timeout(games_addr: address): u64 acquires FightingSettings {
        borrow_global<FightingSettings>(games_addr).afk_timeout
    }

    public fun get_reward_coefficient(games_addr: address): u64 acquires FightingSettings {
        borrow_global<FightingSettings>(games_addr).reward_coefficient
    }

    public fun get_gpass_daily_reward_coefficient(games_addr: address): u64 acquires FightingSettings {
        borrow_global<FightingSettings>(games_addr).gpass_daily_reward_coefficient
    }

    public fun get_royalty(games_addr: address): u8 acquires FightingSettings {
        borrow_global<FightingSettings>(games_addr).royalty
    }

    // Utils.
    const DECIMALS: u64 = 100000000;

    /// Calculate reward amount for user.
    public fun calc_reward_amount(
        play_to_earn_fund_amount: u64,
        freezed_users: u64,
        reward_coefficient: u64,
        gpass_daily_reward: u64,
        gpass_daily_reward_coefficient: u64,
    ): u64 {
        let reward_amount = 0;
        if (freezed_users != 0) {
            reward_amount = play_to_earn_fund_amount / (freezed_users * reward_coefficient);
        };

        let gpass_daily_reward_amount = gpass_daily_reward * DECIMALS;
        if (reward_amount > gpass_daily_reward_amount) {
            reward_amount = gpass_daily_reward_amount / gpass_daily_reward_coefficient;
        };

        reward_amount
    }

    /// Get the percent value.
    public fun calc_royalty_amount(amount: u64, royalty: u8): u64 {
        amount / 100 * (royalty as u64)
    }

    #[test_only]
    public fun get_test_actions_log(size: u64): vector<IdentityAction> {
        let actions_log: vector<IdentityAction> = vector::empty();
        while (size != 0) {
            vector::push_back(&mut actions_log, IdentityAction {
                who: ((size % 2) as u8),
                action: (size as u8),
            });
            size = size - 1;
        };
        actions_log
    }
}
