module nft_market::nft_market {
    use std::signer;
    use std::error;

    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    // Errors
    const ERR_NOT_AUTHORIZED: u64 = 0x1000;
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;

    struct MarketInfo has key, store {
        accumulative_fund: address,
    }

    struct Events has key {
        listing_events: EventHandle<ListingEvent>,
        delisting_events: EventHandle<DelistingEvent>,
        buy_events: EventHandle<BuyEvent>,
    }

    struct ListingEvent has drop, store {
        // TODO: fields
        date: u64,
    }

    struct DelistingEvent has drop, store {
        // TODO: fields
        date: u64,
    }

    struct BuyEvent has drop, store {
        // TODO: fields
        date: u64,
    }

    public entry fun initialize(nft_market: &signer,
        accumulative_fund_addr: address,
    ) {
        let nft_market_addr = signer::address_of(nft_market);
        assert!(nft_market_addr == @nft_market, error::permission_denied(ERR_NOT_AUTHORIZED));

        if (exists<MarketInfo>(nft_market_addr) && exists<Events>(nft_market_addr)) {
            assert!(false, ERR_ALREADY_INITIALIZED);
        };

        if (!exists<MarketInfo>(nft_market_addr)) {
            let market_info = MarketInfo {
                accumulative_fund: accumulative_fund_addr,
            };
            move_to(nft_market, market_info);
        };

        if (!exists<Events>(nft_market_addr)) {
            move_to(nft_market, Events {
                listing_events: account::new_event_handle<ListingEvent>(nft_market),
                delisting_events: account::new_event_handle<DelistingEvent>(nft_market),
                buy_events: account::new_event_handle<BuyEvent>(nft_market),
            });
        };
    }

    // Private API

    public entry fun update_params(nft_market: &signer,
        accumulative_fund_addr: address,
    ) acquires MarketInfo {
        let nft_market_addr = signer::address_of(nft_market);
        assert!(nft_market_addr == @nft_market, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<MarketInfo>(nft_market_addr), ERR_NOT_INITIALIZED);

        let market_info = borrow_global_mut<MarketInfo>(nft_market_addr);
        market_info.accumulative_fund = accumulative_fund_addr;
    }

    // Public API

    public entry fun listing(seller: &signer,
    ) acquires MarketInfo {
        // TODO: check seller is contributor
        // check has rights to this nft
        // check NFT naming format

        // Direct transfer to market?
    }

    public entry fun delisting(seller: &signer,
    ) acquires MarketInfo {
        // TODO: check seller is contributor
        // check has rights to this nft
        // check NFT naming format

        // Direct transfer to contributor?
    }

    public entry fun buy(buyer: &signer,
    ) acquires MarketInfo {
        // TODO: check token is in listing

        // Direct transfer to buyer?
    }

    // Views

    #[view]
    public fun get_price(): u64 {
        return 0
    }

    #[view]
    public fun get_list(project_id: u64): u64 {
        return 0
    }
}
