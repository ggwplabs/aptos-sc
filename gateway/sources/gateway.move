module gateway::gateway {
    use std::signer;
    use std::error;
    use std::string::{Self, String};
    use std::table::{Self, Table};
    use std::vector;

    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::event::{Self, EventHandle};

    use coin::ggwp::GGWPCoin;
    use ggwp_core::gpass;

    // Errors
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
    const ERR_INVALID_GAME_SESSION_STATUS: u64 = 0x1015;
    const ERR_MISSING_GAME_SESSION: u64 = 0x1016;
    const ERR_GAME_SESSION_ALREADY_FINALIZED: u64 = 0x1017;
    const ERR_EMPTY_GAMES_REWARD_FUND: u64 = 0x1018;
    const ERR_GAME_SESSION_ALREADY_STARTED: u64 = 0x1019;
    const ERR_TIME_FRAME_NOT_PASSED: u64 = 0x1020;
    const ERR_INVALID_BURN_PERIOD: u64 = 0x1021;
    const ERR_INVALID_ERASE_HISTORY: u64 = 0x1022;

    // CONST
    const MAX_PROJECT_NAME_LEN: u64 = 128;

    const GAME_STATUS_DRAW: u8 = 0;
    const GAME_STATUS_WIN:  u8 = 1;
    const GAME_STATUS_LOSS: u8 = 2;
    const GAME_STATUS_NONE: u8 = 3;
    const GAME_STATUS_NULL: u8 = 4;

    struct GatewayInfo has key, store {
        accumulative_fund: address,
        games_reward_fund: Coin<GGWPCoin>,
        royalty: u8,
        reward_coefficient: u64,
        project_counter: u64,

        time_frame: u64,
        last_distribute: u64,
        // <projectd_id, GamesInFrame>
        games_in_frame: Table<u64, GamesInFrame>,
        total_gpass_spent_in_frame: u64,

        burn_period: u64,
        last_burn: u64,
        histoty_length: u64,
        // <project_id, RewardsHistory>
        time_frames_history: vector<FrameHistory>,
    }

    struct GamesInFrame has drop, store {
        contributor: address,
        gpass_spent: u64,
        wins: u64,
    }

    struct FrameHistory has store {
        games_reward_fund_share: u64,
        // todo: share for contributors?
        // <project_id, win_cost>
        projects_win_cost: Table<u64, u64>,
    }

    struct ProjectInfo has key, store {
        id: u64,
        contributor: address,
        name: String,
        is_blocked: bool,
        is_removed: bool,
        gpass_cost: u64,
    }

    struct PlayerInfo has key, store {
        is_blocked: bool,
        las_get_reward: u64,
        // <project_id, game_session_status>
        game_sessions: Table<u64, u8>,
        time_frames_history: vector<PlayerFrameHistory>,

        start_game_events: EventHandle<StartGameEvent>,
        finalize_game_events: EventHandle<FinalizeGameEvent>,
    }

    struct PlayerFrameHistory has store {
        // <project_id, wins>
        projects_wins: Table<u64, u64>,
    }

    struct Events has key {
        deposit_events: EventHandle<DepositEvent>,

        block_project_events: EventHandle<BlockProjectEvent>,
        block_player_events: EventHandle<BlockPlayerEvent>,
        unblock_project_events: EventHandle<UnblockProjectEvent>,
        unblock_player_events: EventHandle<UnblockPlayerEvent>,

        sign_up_events: EventHandle<SignUpEvent>,
        remove_events: EventHandle<RemoveEvent>,

        new_player_events: EventHandle<NewPlayerEvent>,

        calculate_rewards_events: EventHandle<CalculateRewardsEvent>,
    }

    struct DepositEvent has drop, store {
        funder: address,
        amount: u64,
        date: u64,
    }

    struct BlockProjectEvent has drop, store {
        project_id: u64,
        contributor: address,
        reason: String,
        date: u64,
    }

    struct BlockPlayerEvent has drop, store {
        player: address,
        reason: String,
        date: u64,
    }

    struct UnblockProjectEvent has drop, store {
        project_id: u64,
        contributor: address,
        date: u64,
    }

    struct UnblockPlayerEvent has drop, store {
        player: address,
        date: u64,
    }

    struct SignUpEvent has drop, store {
        name: String,
        contributor: address,
        project_id: u64,
        date: u64,
    }

    struct RemoveEvent has drop, store {
        project_id: u64,
        contributor: address,
        date: u64,
    }

    struct CalculateRewardsEvent has drop, store {
        players_share: u64,
        contributors_share: u64,
        total_wins: u64,
        total_gpass_spent: u64,
        // TODO: more fields?
        date: u64,
    }

    struct NewPlayerEvent has drop, store {
        player: address,
        date: u64,
    }

    struct StartGameEvent has drop, store {
        project_id: u64,
        date: u64,
    }

    struct FinalizeGameEvent has drop, store {
        project_id: u64,
        status: u8,
        reward: u64,
        royalty: u64,
        date: u64,
    }

    public entry fun initialize(gateway: &signer,
        accumulative_fund_addr: address,
        reward_coefficient: u64,
        royalty: u8,
        time_frame: u64,
        burn_period: u64,
    ) {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));

        if (exists<GatewayInfo>(gateway_addr) && exists<Events>(gateway_addr)) {
            assert!(false, ERR_ALREADY_INITIALIZED);
        };

        if (!exists<GatewayInfo>(gateway_addr)) {
            assert!(burn_period % time_frame == 0, ERR_INVALID_BURN_PERIOD);
            let histoty_length = burn_period / time_frame;
            let time_frames_history = vector::empty<FrameHistory>();
            let i = 0;
            while (i < histoty_length) {
                vector::push_back(&mut time_frames_history, FrameHistory {
                    games_reward_fund_share: 0,
                    projects_win_cost: table::new<u64, u64>(),
                });
                i = i + 1;
            };
            assert!(vector::length(&time_frames_history) == histoty_length, ERR_NOT_INITIALIZED);

            let now = timestamp::now_seconds();
            let gateway_info = GatewayInfo {
                accumulative_fund: accumulative_fund_addr,
                games_reward_fund: coin::zero<GGWPCoin>(),
                royalty: royalty,
                reward_coefficient: reward_coefficient,
                project_counter: 0,

                time_frame: time_frame,
                last_distribute: now,
                games_in_frame: table::new<u64, GamesInFrame>(),
                total_gpass_spent_in_frame: 0,

                burn_period: burn_period,
                last_burn: now,
                histoty_length: histoty_length,
                time_frames_history: time_frames_history,
            };
            move_to(gateway, gateway_info);
        };

        if (!exists<Events>(gateway_addr)) {
            move_to(gateway, Events {
                deposit_events: account::new_event_handle<DepositEvent>(gateway),

                block_project_events: account::new_event_handle<BlockProjectEvent>(gateway),
                block_player_events: account::new_event_handle<BlockPlayerEvent>(gateway),
                unblock_project_events: account::new_event_handle<UnblockProjectEvent>(gateway),
                unblock_player_events: account::new_event_handle<UnblockPlayerEvent>(gateway),

                sign_up_events: account::new_event_handle<SignUpEvent>(gateway),
                remove_events: account::new_event_handle<RemoveEvent>(gateway),

                new_player_events: account::new_event_handle<NewPlayerEvent>(gateway),

                calculate_rewards_events: account::new_event_handle<CalculateRewardsEvent>(gateway),
            });
        };
    }

    // Private API

    public entry fun update_params(gateway: &signer,
        reward_coefficient: u64,
        royalty: u8,
        time_frame: u64,
        burn_period: u64,
    ) acquires GatewayInfo {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);

        let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        gateway_info.reward_coefficient = reward_coefficient;
        gateway_info.royalty = royalty;
        gateway_info.time_frame = time_frame;
        gateway_info.burn_period = burn_period;
    }

    public entry fun update_accumulative_fund(gateway: &signer,
        accumulative_fund: address,
    ) acquires GatewayInfo {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);

        let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        gateway_info.accumulative_fund = accumulative_fund;
    }

    public entry fun games_reward_fund_deposit(funder: &signer, gateway_addr: address, amount: u64) acquires GatewayInfo, Events {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(amount != 0, ERR_ZERO_DEPOSIT_AMOUNT);

        let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        let deposit_coins = coin::withdraw<GGWPCoin>(funder, amount);
        coin::merge(&mut gateway_info.games_reward_fund, deposit_coins);

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<DepositEvent>(
            &mut events.deposit_events,
            DepositEvent { funder: signer::address_of(funder), amount: amount, date: now },
        );
    }

    public entry fun block_project(gateway: &signer, contributor_addr: address, project_id: u64, reason: String) acquires ProjectInfo, Events {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<ProjectInfo>(contributor_addr), ERR_PROJECT_NOT_EXISTS);
        let project_info = borrow_global_mut<ProjectInfo>(contributor_addr);
        assert!(project_info.id == project_id, ERR_INVALID_PROJECT_ID);
        assert!(project_info.is_removed == false, ERR_ALREADY_REMOVED);
        assert!(project_info.is_blocked == false, ERR_ALREADY_BLOCKED);

        project_info.is_blocked = true;

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<BlockProjectEvent>(
            &mut events.block_project_events,
            BlockProjectEvent {
                project_id: project_id,
                contributor: contributor_addr,
                reason: reason,
                date: now
            }
        );
    }

    public entry fun block_player(gateway: &signer, player_addr: address, reason: String) acquires PlayerInfo, Events {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<PlayerInfo>(player_addr), ERR_PLAYER_INFO_NOT_EXISTS);
        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        assert!(player_info.is_blocked == false, ERR_ALREADY_BLOCKED);

        player_info.is_blocked = true;

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<BlockPlayerEvent>(
            &mut events.block_player_events,
            BlockPlayerEvent {
                player: player_addr,
                reason: reason,
                date: now
            }
        );
    }

    public entry fun unblock_project(gateway: &signer, contributor_addr: address, project_id: u64) acquires ProjectInfo, Events {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<ProjectInfo>(contributor_addr), ERR_PROJECT_NOT_EXISTS);
        let project_info = borrow_global_mut<ProjectInfo>(contributor_addr);
        assert!(project_info.id == project_id, ERR_INVALID_PROJECT_ID);
        assert!(project_info.is_removed == false, ERR_ALREADY_REMOVED);
        assert!(project_info.is_blocked == true, ERR_NOT_BLOCKED);

        project_info.is_blocked = false;

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<UnblockProjectEvent>(
            &mut events.unblock_project_events,
            UnblockProjectEvent {
                project_id: project_info.id,
                contributor: contributor_addr,
                date: now
            }
        );
    }

    public entry fun unblock_player(gateway: &signer, player_addr: address) acquires PlayerInfo, Events {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<PlayerInfo>(player_addr), ERR_PLAYER_INFO_NOT_EXISTS);
        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        assert!(player_info.is_blocked == true, ERR_NOT_BLOCKED);

        player_info.is_blocked = false;

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<UnblockPlayerEvent>(
            &mut events.unblock_player_events,
            UnblockPlayerEvent {
                player: player_addr,
                date: now
            }
        );
    }

    public entry fun calculate_time_frame(gateway: &signer) acquires GatewayInfo, Events {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();

        let since_last_distribute = now - gateway_info.last_distribute;
        assert!(since_last_distribute >= gateway_info.time_frame, ERR_TIME_FRAME_NOT_PASSED);

        let since_burn = now - gateway_info.last_burn;
        if (since_burn >= gateway_info.burn_period) {
            let spent_frames = since_burn / gateway_info.time_frame;
            assert!(spent_frames >= gateway_info.histoty_length, ERR_INVALID_ERASE_HISTORY);
            erase_history(&mut gateway_info.time_frames_history, gateway_info.histoty_length, gateway_info.project_counter);
            gateway_info.last_burn = gateway_info.last_burn + (spent_frames * gateway_info.time_frame);
        };

        let since_burn = now - gateway_info.last_burn;
        let history_index = since_burn / gateway_info.time_frame;
        let frame_history_entry = vector::borrow_mut<FrameHistory>(&mut gateway_info.time_frames_history, history_index);

        // TODO: write into history table
        let games_reward_fund_amount = coin::value<GGWPCoin>(&gateway_info.games_reward_fund);
        let games_reward_fund_share = games_reward_fund_amount / gateway_info.reward_coefficient;
        frame_history_entry.games_reward_fund_share = games_reward_fund_share;

        // 20% to contributors
        let games_reward_fund_contributors_share = games_reward_fund_share / 100 * 20;
        // TODO: every contributor share calc and save it into table

        games_reward_fund_share = games_reward_fund_share - games_reward_fund_contributors_share;

        let total_wins = 0;
        let project_id = 0;
        while (project_id < gateway_info.project_counter) {
            if (table::contains(&gateway_info.games_in_frame, project_id) == false) {
                project_id = project_id + 1;
                continue
            };

            let games_in_frame = table::borrow(&gateway_info.games_in_frame, project_id);
            let project_win_cost = calculate_project_win_cost(games_in_frame, games_reward_fund_share, gateway_info.total_gpass_spent_in_frame);

            let win_cost_val = table::borrow_mut(&mut frame_history_entry.projects_win_cost, project_id);
            *win_cost_val = project_win_cost;

            total_wins = total_wins + games_in_frame.wins;
            project_id = project_id + 1;

            table::remove(&mut gateway_info.games_in_frame, project_id);
        };

        event::emit_event<CalculateRewardsEvent>(
            &mut events.calculate_rewards_events,
            CalculateRewardsEvent {
                players_share: games_reward_fund_share,
                contributors_share: games_reward_fund_contributors_share,
                // TODO: fix values
                total_gpass_spent: gateway_info.total_gpass_spent_in_frame,
                total_wins: total_wins,
                date: now
            },
        );

        // Clean up tables except history table
        // Set counters up
        gateway_info.last_distribute = now;
        gateway_info.total_gpass_spent_in_frame = 0;
    }

    // Public API

    public entry fun sign_up(contributor: &signer,
        gateway_addr: address,
        project_name: String,
        gpass_cost: u64,
    ) acquires GatewayInfo, Events, ProjectInfo {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        let contributor_addr = signer::address_of(contributor);
        assert!(!string::is_empty(&project_name), ERR_INVALID_PROJECT_NAME);
        assert!(string::length(&project_name) <= MAX_PROJECT_NAME_LEN, ERR_INVALID_PROJECT_NAME);
        assert!(gpass_cost != 0, ERR_INVALID_GPASS_COST);

        let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        let new_project_id = gateway_info.project_counter + 1;

        // if project is removed, create new project in this resource
        if (exists<ProjectInfo>(contributor_addr)) {
            let project_info = borrow_global_mut<ProjectInfo>(contributor_addr);
            assert!(project_info.is_removed == true, ERR_ALREADY_INITIALIZED);

            project_info.id = new_project_id;
            project_info.name = project_name;
            project_info.is_blocked = false;
            project_info.is_removed = false;
            project_info.gpass_cost = gpass_cost;
        }
        else {
            move_to(contributor, ProjectInfo {
                id: new_project_id,
                contributor: contributor_addr,
                name: project_name,
                is_blocked: false,
                is_removed: false,
                gpass_cost: gpass_cost,
            });
        };

        gateway_info.project_counter = new_project_id;

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<SignUpEvent>(
            &mut events.sign_up_events,
            SignUpEvent {
                name: project_name,
                contributor: contributor_addr,
                project_id: new_project_id,
                date: now
            }
        );
    }

    public entry fun remove(contributor: &signer, gateway_addr: address) acquires ProjectInfo, Events {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        let contributor_addr = signer::address_of(contributor);
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);

        let project_info = borrow_global_mut<ProjectInfo>(contributor_addr);
        assert!(project_info.is_blocked == false, ERR_ALREADY_BLOCKED);
        assert!(project_info.is_removed == false, ERR_ALREADY_REMOVED);

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<RemoveEvent>(
            &mut events.remove_events,
            RemoveEvent {
                project_id: project_info.id,
                contributor: contributor_addr,
                date: now
            }
        );

        project_info.is_removed = true;
        project_info.id = 0;
        project_info.name = string::utf8(b"");
        project_info.gpass_cost = 0;
    }

    public entry fun start_game(player: &signer,
        gateway_addr: address,
        ggwp_core_addr: address,
        contributor_addr: address,
        project_id: u64,
    ) acquires GatewayInfo, ProjectInfo, PlayerInfo, Events {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<ProjectInfo>(contributor_addr), ERR_PROJECT_NOT_EXISTS);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        assert!(project_info.id == project_id, ERR_INVALID_PROJECT_ID);
        assert!(project_info.is_blocked == false, ERR_PROJECT_BLOCKED);

        let now = timestamp::now_seconds();
        let player_addr = signer::address_of(player);
        // Create PlayerInfo if not exists
        if (exists<PlayerInfo>(player_addr) == false) {
            let gateway_info = borrow_global<GatewayInfo>(gateway_addr);
            let time_frames_history = vector::empty<PlayerFrameHistory>();
            let i = 0;
            while (i < gateway_info.histoty_length) {
                vector::push_back(&mut time_frames_history, PlayerFrameHistory {
                    projects_wins: table::new<u64, u64>(),
                });
            };

            move_to(player, PlayerInfo {
                is_blocked: false,
                las_get_reward: 0,
                game_sessions: table::new<u64, u8>(),
                time_frames_history: time_frames_history,
                start_game_events: account::new_event_handle<StartGameEvent>(player),
                finalize_game_events: account::new_event_handle<FinalizeGameEvent>(player),
            });

            let events = borrow_global_mut<Events>(gateway_addr);
            event::emit_event<NewPlayerEvent>(
                &mut events.new_player_events,
                NewPlayerEvent {
                    player: player_addr,
                    date: now,
                }
            );
        };

        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        assert!(player_info.is_blocked == false, ERR_PLAYER_BLOCKED);
        assert!(gpass::get_burn_period_passed(ggwp_core_addr, player_addr) == false, ERR_NOT_ENOUGH_GPASS);
        assert!(gpass::get_balance(player_addr) >= project_info.gpass_cost, ERR_NOT_ENOUGH_GPASS);

        // TODO: check burn_period and erase reward_history vector

        // Check already opened sessions in this project
        if (table::contains(&player_info.game_sessions, project_id)) {
            let game_session_status = table::borrow(&player_info.game_sessions, project_id);
            assert!(*game_session_status == GAME_STATUS_NULL, ERR_GAME_SESSION_ALREADY_STARTED);
        };

        // Burn gpass_cost GPASS from user wallet
        gpass::burn(player, ggwp_core_addr, project_info.gpass_cost);

        // Create game session in table if not exists
        if (!table::contains(&player_info.game_sessions, project_id)) {
            table::add(&mut player_info.game_sessions,
                project_id,
                GAME_STATUS_NULL,
            );
        };

        // Update game status to NONE - session created
        let game_session_status = table::borrow_mut(&mut player_info.game_sessions, project_id);
        *game_session_status = GAME_STATUS_NONE;

        event::emit_event<StartGameEvent>(
            &mut player_info.start_game_events,
            StartGameEvent {
                project_id: project_id,
                date: now,
            }
        );
    }

    public entry fun finalize_game(player: &signer,
        gateway_addr: address,
        contributor_addr: address,
        project_id: u64,
        status: u8,
    ) acquires ProjectInfo, PlayerInfo {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<ProjectInfo>(contributor_addr), ERR_PROJECT_NOT_EXISTS);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        assert!(project_info.id == project_id, ERR_INVALID_PROJECT_ID);
        assert!(project_info.is_blocked == false, ERR_PROJECT_BLOCKED);

        let player_addr = signer::address_of(player);
        assert!(exists<PlayerInfo>(player_addr), ERR_PLAYER_INFO_NOT_EXISTS);
        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        assert!(player_info.is_blocked == false, ERR_PLAYER_BLOCKED);

        assert!(status < 3, ERR_INVALID_GAME_SESSION_STATUS);

        // Check game session status
        assert!(table::contains(&player_info.game_sessions, project_id), ERR_MISSING_GAME_SESSION);
        let game_session_status = table::borrow_mut(&mut player_info.game_sessions, project_id);
        assert!(*game_session_status == GAME_STATUS_NONE, ERR_GAME_SESSION_ALREADY_FINALIZED);
        *game_session_status = GAME_STATUS_NULL;

        // Finalize game session
        let reward_amount = 0;
        let royalty_amount = 0;

        // TODO: check burn_period and erase reward_history vector

        // TODO: not pay reward, save info in history table instead
        // TODO: find index in history_table
        // If player win pay rewards
        // if (status == GAME_STATUS_WIN) {
        //     let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        //     let games_reward_fund_amount = coin::value<GGWPCoin>(&gateway_info.games_reward_fund);
        //     assert!(games_reward_fund_amount != 0, ERR_EMPTY_GAMES_REWARD_FUND);

        //     reward_amount = calc_reward_amount(
        //         games_reward_fund_amount,
        //         gpass::get_total_users_freezed(ggwp_core_addr),
        //         gateway_info.reward_coefficient,
        //         gpass::get_daily_gpass_reward(ggwp_core_addr),
        //         gateway_info.gpass_daily_reward_coefficient,
        //     );

        //     royalty_amount = calc_royalty_amount(reward_amount, gateway_info.royalty);
        //     // Transfer reward_amount - royalty_amount to player from games_reward_fund
        //     let reward_coins = coin::extract(&mut gateway_info.games_reward_fund, reward_amount - royalty_amount);
        //     coin::deposit(player_addr, reward_coins);
        //     // Transfer royalty_amount to accumulative fund from games_reward_fund
        //     let royalty_coins = coin::extract(&mut gateway_info.games_reward_fund, royalty_amount);
        //     coin::deposit(gateway_info.accumulative_fund, royalty_coins);
        // };

        let now = timestamp::now_seconds();
        event::emit_event<FinalizeGameEvent>(
            &mut player_info.finalize_game_events,
            FinalizeGameEvent {
                project_id: project_id,
                status: status,
                reward: reward_amount,
                royalty: royalty_amount,
                date: now,
            }
        );
    }

    public entry fun get_reward(player: &signer,
        gateway_addr: address,
    ) acquires PlayerInfo {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        let player_addr = signer::address_of(player);
        assert!(exists<PlayerInfo>(player_addr), ERR_PLAYER_INFO_NOT_EXISTS);
        let player_info = borrow_global_mut<PlayerInfo>(player_addr);
        assert!(player_info.is_blocked == false, ERR_PLAYER_BLOCKED);

        // TODO:
        // NEED: games_reward_fund_share, user_project_n_wins (all projects), project_n_win_cost (all projects)
        // IN player resources: user_project_n_wins (all projects), - 244 rows
        // IN gateway resources: games_reward_fund_share, project_n_win_cost (all projects) - 244 rows
        // TODO: decrease games_reward_fund_share in table
        // FOR by reward_history and collects all reward for user

        // user_reward = sum_n (project_n_win_cost * user_project_n_wins)
        // games_reward_fund_share = games_reward_fund_share - user_reward

        // 1. Check burn_period and burn all rewards (cleanup history table)
        // 1.1 Retransfer burned rewards into accumulative_fund
        // 2. Check history tables for rewards
        // 3. Pay all rewards to player (royalty??)

        // Send event GetRewardEvent into player res
    }

    // Getters

    #[view]
    public fun get_accumulative_fund_addr(gateway_addr: address): address acquires GatewayInfo {
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        let gateway_info = borrow_global<GatewayInfo>(gateway_addr);
        gateway_info.accumulative_fund
    }

    #[view]
    public fun games_reward_fund_balance(gateway_addr: address): u64 acquires GatewayInfo {
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        let gateway_info = borrow_global<GatewayInfo>(gateway_addr);
        coin::value<GGWPCoin>(&gateway_info.games_reward_fund)
    }

    #[view]
    public fun get_project_counter(gateway_addr: address): u64 acquires GatewayInfo {
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        let gateway_info = borrow_global<GatewayInfo>(gateway_addr);
        gateway_info.project_counter
    }

    #[view]
    public fun get_project_id(contributor_addr: address): u64 acquires ProjectInfo {
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.id
    }

    #[view]
    public fun get_project_gpass_cost(contributor_addr: address): u64 acquires ProjectInfo {
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.gpass_cost
    }

    #[view]
    public fun get_project_name(contributor_addr: address): String acquires ProjectInfo {
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.name
    }

    #[view]
    public fun get_project_is_blocked(contributor_addr: address): bool acquires ProjectInfo {
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.is_blocked
    }

    #[view]
    public fun get_project_is_removed(contributor_addr: address): bool acquires ProjectInfo {
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.is_removed
    }

    #[view]
    public fun get_player_is_blocked(player_addr: address): bool acquires PlayerInfo {
        assert!(exists<PlayerInfo>(player_addr), ERR_NOT_INITIALIZED);
        let player_info = borrow_global<PlayerInfo>(player_addr);
        player_info.is_blocked
    }

    #[view]
    public fun get_session_status(player_addr: address, project_id: u64): u8 acquires PlayerInfo {
        if (exists<PlayerInfo>(player_addr) == false) {
            return GAME_STATUS_NULL
        };

        let player_info = borrow_global<PlayerInfo>(player_addr);
        if (!table::contains(&player_info.game_sessions, project_id)) {
            return GAME_STATUS_NULL
        };

        let game_session_status = table::borrow(&player_info.game_sessions, project_id);
        return *game_session_status
    }

    #[view]
    public fun get_is_open_session(player_addr: address, project_id: u64): bool acquires PlayerInfo {
        if (exists<PlayerInfo>(player_addr) == false) {
            return false
        };

        let player_info = borrow_global<PlayerInfo>(player_addr);
        if (!table::contains(&player_info.game_sessions, project_id)) {
            return false
        };

        let game_session_status = table::borrow(&player_info.game_sessions, project_id);
        if (*game_session_status == GAME_STATUS_NONE) {
            return true
        };
        return false
    }

    // Utils.
    const DECIMALS: u64 = 100000000;

    // TODO: unit tests for this function
    public fun calculate_project_win_cost(
        games_in_frame: &GamesInFrame,
        games_reward_fund_share: u64,
        total_gpass_spent: u64
    ): u64 {
        let gpass_spent_128_dec: u128 = (games_in_frame.gpass_spent as u128) * (DECIMALS as u128);
        let total_gpass_spent_128: u128 = (total_gpass_spent as u128);
        let games_reward_fund_share_128_dec = (games_reward_fund_share as u128);
        let wins_u128_dec = (games_in_frame.wins as u128) * (DECIMALS as u128);

        let project_all_rewards_share: u128 = games_reward_fund_share_128_dec * (gpass_spent_128_dec / total_gpass_spent_128);
        let project_win_cost = project_all_rewards_share / wins_u128_dec;

        return (project_win_cost as u64)
    }

    // TODO: unit tests
    public fun erase_history(history: &mut vector<FrameHistory>, histoty_length: u64, project_counter: u64) {
        let i = 0;
        while (i < histoty_length) {
            let elem = vector::borrow_mut<FrameHistory>(history, i);
            elem.games_reward_fund_share = 0;
            let j = 0;
            while (j < project_counter) {
                if (table::contains(&elem.projects_win_cost, j)) {
                    table::remove(&mut elem.projects_win_cost, j);
                };
                j = j + 1;
            };
            i = i + 1;
        };
    }

    /// Get the percent value.
    public fun calc_royalty_amount(amount: u64, royalty: u8): u64 {
        amount / 100 * (royalty as u64)
    }
}
