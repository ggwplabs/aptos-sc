module gateway::gateway {
    use std::signer;
    use std::error;
    use std::string::{Self, String};
    use std::table_with_length::{Self, TableWithLength};

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
    const ERR_INVALID_PROJECT_NAME: u64 = 0x1004;
    const ERR_INVALID_GPASS_COST: u64 = 0x1005;
    const ERR_ALREADY_REMOVED: u64 = 0x1006;
    const ERR_PROJECT_NOT_EXISTS: u64 = 0x1007;
    const ERR_INVALID_PROJECT_ID: u64 = 0x1008;
    const ERR_NOT_ENOUGH_GPASS: u64 = 0x1009;

    // CONST
    const MAX_PROJECT_NAME_LEN: u64 = 128;

    // Project Block reasons

    // Player Block reasons

    struct GatewayInfo has key, store {
        accumulative_fund: address,
        play_to_earn_fund: Coin<GGWPCoin>,
        royalty: u8,
        project_counter: u64,
    }

    struct ProjectInfo has key, store {
        id: u64,
        contributor: address,
        name: String,
        is_blocked: bool,
        is_removed: bool,
        gpass_cost: u64,
    }

    struct UserInfo has key, store {
        is_blocked: bool,
        game_sessions_counter: u64,
        game_sessions: TableWithLength<u64, TableWithLength<u64, GameSessionInfo>>,
    }

    struct GameSessionInfo has store {
        status: u8,
        reward: u64,
        royalty: u64,
    }

    struct Events has key {
        deposit_events: EventHandle<DepositEvent>,

        block_project_events: EventHandle<BlockProjectEvent>,
        block_player_events: EventHandle<BlockPlayerEvent>,
        unblock_project_events: EventHandle<UnblockProjectEvent>,
        unblock_player_events: EventHandle<UnblockPlayerEvent>,

        sign_up_events: EventHandle<SignUpEvent>,
        remove_events: EventHandle<RemoveEvent>,

        start_game_events: EventHandle<StartGameEvent>,
        finalize_game_events: EventHandle<FinalizeGameEvent>,
    }

    struct DepositEvent has drop, store {
        funder: address,
        amount: u64,
        date: u64,
    }

    struct BlockProjectEvent has drop, store {
        project_id: u64,
        reason: u8,
        date: u64,
    }

    struct BlockPlayerEvent has drop, store {
        player: address,
        reason: u8,
        date: u64,
    }

    struct UnblockProjectEvent has drop, store {
        project_id: u64,
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
        date: u64,
    }

    struct StartGameEvent has drop, store {
        player: address,
        project_id: u64,
        session_id: u64,
        date: u64,
    }

    struct FinalizeGameEvent has drop, store {
        player: address,
        project_id: u64,
        session_id: u64,
        reward: u64,
        date: u64,
    }

    public entry fun initialize(gateway: &signer, accumulative_fund_addr: address, royalty: u8) {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));

        if (exists<GatewayInfo>(gateway_addr) && exists<Events>(gateway_addr)) {
            assert!(false, ERR_ALREADY_INITIALIZED);
        };

        if (!exists<GatewayInfo>(gateway_addr)) {
            let gateway_info = GatewayInfo {
                accumulative_fund: accumulative_fund_addr,
                play_to_earn_fund: coin::zero<GGWPCoin>(),
                royalty: royalty,
                project_counter: 0,
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

                start_game_events: account::new_event_handle<StartGameEvent>(gateway),
                finalize_game_events: account::new_event_handle<FinalizeGameEvent>(gateway),
            });
        };
    }

    // Private API

    public entry fun play_to_earn_fund_deposit(funder: &signer, gateway_addr: address, amount: u64) acquires GatewayInfo, Events {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(amount != 0, ERR_ZERO_DEPOSIT_AMOUNT);

        let gateway_info = borrow_global_mut<GatewayInfo>(gateway_addr);
        let deposit_coins = coin::withdraw<GGWPCoin>(funder, amount);
        coin::merge(&mut gateway_info.play_to_earn_fund, deposit_coins);

        let events = borrow_global_mut<Events>(gateway_addr);
        let now = timestamp::now_seconds();
        event::emit_event<DepositEvent>(
            &mut events.deposit_events,
            DepositEvent { funder: signer::address_of(funder), amount: amount, date: now },
        );
    }

    // public entry fun block_project(gateway: &signer) {

    // }

    // public entry fun block_player(gateway: &signer) {

    // }

    // public entry fun unblock_project(gateway: &signer) {

    // }

    // public entry fun unblock_player(gateway: &signer) {

    // }

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
        });
    }

    public entry fun remove(contributor: &signer, gateway_addr: address) acquires ProjectInfo {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        let contributor_addr = signer::address_of(contributor);
        assert!(exists<ProjectInfo>(contributor_addr), ERR_NOT_INITIALIZED);

        let project_info = borrow_global_mut<ProjectInfo>(contributor_addr);
        assert!(project_info.is_removed == false, ERR_ALREADY_REMOVED);

        project_info.is_removed = true;
        project_info.id = 0;
        project_info.name = string::utf8(b"");
        project_info.gpass_cost = 0;
    }

    public entry fun start_game(player: &signer,
        gateway_addr: address,
        contributor_addr: address,
        project_id: u64,
    ) acquires ProjectInfo {
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<GatewayInfo>(gateway_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(gateway_addr), ERR_NOT_INITIALIZED);

        assert!(exists<ProjectInfo>(contributor_addr), ERR_PROJECT_NOT_EXISTS);
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        assert!(project_info.id == project_id, ERR_INVALID_PROJECT_ID);

        let player_addr = signer::address_of(player);
        assert!(gpass::get_balance(player_addr) >= project_info.gpass_cost, ERR_NOT_ENOUGH_GPASS);

        // Create UserInfo if not exists
        if (exists<UserInfo>(player_addr) == false) {
            // table_with_length::new<u64, GameSessionInfo>()
            move_to(player, UserInfo {
                is_blocked: false,
                game_sessions_counter: 0,
                game_sessions: table_with_length::new<u64, TableWithLength<u64, GameSessionInfo>>(),
            });
        };

        // TODO: check already in game? burn gpass, create session, emit event
    }

    // public entry fun finalize_game(player: &signer) {

    // }

    // Getters

    public fun play_to_earn_fund_balance(gateway_addr: address): u64 acquires GatewayInfo {
        let gateway_info = borrow_global<GatewayInfo>(gateway_addr);
        coin::value<GGWPCoin>(&gateway_info.play_to_earn_fund)
    }

    public fun get_project_counter(gateway_addr: address): u64 acquires GatewayInfo {
        let gateway_info = borrow_global<GatewayInfo>(gateway_addr);
        gateway_info.project_counter
    }

    public fun get_project_id(contributor_addr: address): u64 acquires ProjectInfo {
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.id
    }

     public fun get_project_gpass_cost(contributor_addr: address): u64 acquires ProjectInfo {
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.gpass_cost
    }

    public fun get_project_name(contributor_addr: address): String acquires ProjectInfo {
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.name
    }

    public fun get_project_is_blocked(contributor_addr: address): bool acquires ProjectInfo {
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.is_blocked
    }

    public fun get_project_is_removed(contributor_addr: address): bool acquires ProjectInfo {
        let project_info = borrow_global<ProjectInfo>(contributor_addr);
        project_info.is_removed
    }
}
