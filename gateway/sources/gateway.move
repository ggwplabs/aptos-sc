module gateway::gateway {
    use std::signer;
    use std::error;
    use std::string::{Self, String};

    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::event::{Self, EventHandle};

    use coin::ggwp::GGWPCoin;

    const ERR_NOT_AUTHORIZED: u64 = 0x1000;
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_ZERO_DEPOSIT_AMOUNT: u64 = 0x1003;

    // Project Block reasons

    // Player Block reasons

    struct GatewayInfo has key, store {
        accumulative_fund: address,
        play_to_earn_fund: Coin<GGWPCoin>,
        project_counter: u64,
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

    public entry fun initialize(gateway: &signer, accumulative_fund_addr: address) {
        let gateway_addr = signer::address_of(gateway);
        assert!(gateway_addr == @gateway, error::permission_denied(ERR_NOT_AUTHORIZED));

        if (exists<GatewayInfo>(gateway_addr) && exists<Events>(gateway_addr)) {
            assert!(false, ERR_ALREADY_INITIALIZED);
        };

        if (!exists<GatewayInfo>(gateway_addr)) {
            let gateway_info = GatewayInfo {
                accumulative_fund: accumulative_fund_addr,
                play_to_earn_fund: coin::zero<GGWPCoin>(),
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

    public entry fun block_project(gateway: &signer) {

    }

    public entry fun block_player(gateway: &signer) {

    }

    public entry fun unblock_project(gateway: &signer) {

    }

    public entry fun unblock_player(gateway: &signer) {

    }

    // Public API

    public entry fun sign_up(contributor: &signer) {

    }

    public entry fun remove(contributor: &signer) {

    }

    public entry fun start_game(player: &signer) {

    }

    public entry fun finalize_game(player: &signer) {

    }

    // Getters
}
