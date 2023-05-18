module nft_market::nft_market {
    use std::signer;
    use std::error;
    use std::vector;
    use std::table::{Self, Table};
    use std::string::{Self, String};

    use aptos_token::token::{Self, TokenId, create_token_id_raw};
    use aptos_token::token_transfers;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::event::{Self, EventHandle};

    use gateway::gateway;

    // Errors
    const ERR_NOT_AUTHORIZED: u64 = 0x1000;
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_NOTHING_TO_CLAIM: u64 = 0x1003;
    const ERR_SELLER_IS_NOT_CONTRIBUTOR: u64 = 0x1004;
    const ERR_PROJECT_BLOCKED_OR_REMOVED: u64 = 0x1005;
    const ERR_INVALID_COLLECTION_NAME: u64 = 0x1006;
    const ERR_INVALID_TOKEN_NAME: u64 = 0x1006;

    struct MarketInfo has key, store {
        accumulative_fund: address,
        listing_offers: vector<ListingOfferData>,
        listing: Table<address, vector<ListingData>>,
    }

    struct ListingOfferData has store, drop {
        seller: address,
        token_id: TokenId,
        price: u64,
    }

    struct ListingData has store, drop {
        token_id: TokenId,
        price: u64,
    }

    struct Events has key {
        listing_events: EventHandle<ListingEvent>,
        delisting_events: EventHandle<DelistingEvent>,
        buy_events: EventHandle<BuyEvent>,
    }

    struct ListingEvent has drop, store {
        seller: address,
        creator: address,
        collection: String,
        token_name: String,
        price: u64,
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
                listing_offers: vector::empty<ListingOfferData>(),
                listing: table::new<address, vector<ListingData>>(),
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

    public entry fun listing_claim(nft_market: &signer,
        seller_addr: address,
        creator_addr: address,
        collection: String,
        token_name: String,
    ) acquires MarketInfo {
        let nft_market_addr = signer::address_of(nft_market);
        assert!(nft_market_addr == @nft_market, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<MarketInfo>(nft_market_addr), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(nft_market_addr), ERR_NOT_INITIALIZED);

        let market_info = borrow_global_mut<MarketInfo>(nft_market_addr);
        assert!(vector::is_empty(&market_info.listing_offers) == false, ERR_NOTHING_TO_CLAIM);

        while (vector::is_empty(&market_info.listing_offers) == false) {
            let offer_data = vector::swap_remove(&mut market_info.listing_offers, 0);
            token_transfers::claim(nft_market, offer_data.seller, offer_data.token_id);

            if (table::contains(&market_info.listing, offer_data.seller) == false) {
                table::add(&mut market_info.listing, offer_data.seller, vector::empty<ListingData>());
            };

            let listing_data = table::borrow_mut(&mut market_info.listing, offer_data.seller);
            vector::push_back(listing_data, ListingData {
                token_id: offer_data.token_id,
                price: offer_data.price,
            });
        };
    }

    // Public API

    public entry fun listing(seller: &signer,
        creator_addr: address,
        collection: String,
        token_name: String,
        price: u64,
    ) acquires MarketInfo, Events {
        let seller_addr = signer::address_of(seller);
        assert!(exists<MarketInfo>(@nft_market), ERR_NOT_INITIALIZED);
        assert!(exists<Events>(@nft_market), ERR_NOT_INITIALIZED);
        assert!(gateway::get_project_is_blocked(seller_addr), ERR_PROJECT_BLOCKED_OR_REMOVED);
        assert!(gateway::get_project_is_removed(seller_addr), ERR_PROJECT_BLOCKED_OR_REMOVED);
        assert!(validate_name(&collection), ERR_INVALID_COLLECTION_NAME);
        assert!(validate_name(&token_name), ERR_INVALID_COLLECTION_NAME);

        let market_info = borrow_global_mut<MarketInfo>(@nft_market);
        let token_id = create_token_id_raw(creator_addr, collection, token_name, 0);
        token_transfers::offer(seller, @nft_market, token_id, 1);
        vector::push_back(&mut market_info.listing_offers, ListingOfferData {
            seller: seller_addr,
            token_id: token_id,
            price: price,
        });

        let events = borrow_global_mut<Events>(@nft_market);
        let now = timestamp::now_seconds();
        event::emit_event<ListingEvent>(
            &mut events.listing_events,
            ListingEvent {
                seller: seller_addr,
                creator: creator_addr,
                collection: collection,
                token_name: token_name,
                price: price,
                date: now,
            },
        );
    }

    // TODO:
    // public entry fun delisting(seller: &signer,
    // ) acquires MarketInfo {
    //     // TODO: check seller is contributor
    //     // check has rights to this nft
    //     // check NFT naming format

    //     // Direct transfer to contributor?
    // }

    // public entry fun buy(buyer: &signer,
    // ) acquires MarketInfo {
    //     // TODO: check token is in listing

    //     // Direct transfer to buyer?
    // }

    // // Views

    // #[view]
    // public fun get_price(): u64 {
    //     return 0
    // }

    // #[view]
    // public fun get_list(project_id: u64): u64 {
    //     return 0
    // }

    // Utils

    fun validate_name(name: &String): bool {
        if (string::is_empty(name)) {
            return false
        };
        let sub = string::sub_string(name, 0, 5);
        if (sub != string::utf8(b"GGWP ")) {
            return false
        };
        return true
    }
}
