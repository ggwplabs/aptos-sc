#[test_only]
module nft_market::nft_market_test {
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::genesis;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_token::token;
    use aptos_framework::account::create_account_for_test;

    use nft_market::nft_market;
    use gateway::gateway;
    use coin::ggwp::GGWPCoin;

    // Errors from nft_market module
    const ERR_NOT_AUTHORIZED: u64 = 0x1000;
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_PROJECT_BLOCKED_OR_REMOVED: u64 = 0x1003;
    const ERR_INVALID_COLLECTION_NAME: u64 = 0x1004;
    const ERR_INVALID_TOKEN_NAME: u64 = 0x1005;
    const ERR_ALREADY_IN_LISTING: u64 = 0x1006;
    const ERR_NOT_IN_LISTING: u64 = 0x1007;
    const ERR_INVALID_PRICE: u64 = 0x1008;

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    public entry fun listing_buy_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        coin::ggwp::mint_to(ggwp_coin, 200000000, buyer_addr);
        assert!(coin::balance<GGWPCoin>(buyer_addr) == 200000000, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"GGWP Test collection");
        let token1_name: String = string::utf8(b"GGWP Test token1 name");

        nft_market::listing(contributor, contributor_addr, coll_name, token1_name, 100000000);
        assert!(coin::balance<GGWPCoin>(buyer_addr) == 200000000, 1);
        assert!(coin::balance<GGWPCoin>(contributor_addr) == 0, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);

        nft_market::buy(buyer, contributor_addr, contributor_addr, coll_name, token1_name);
        assert!(coin::balance<GGWPCoin>(buyer_addr) == 100000000, 1);
        assert!(coin::balance<GGWPCoin>(contributor_addr) == 92000000, 1);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 8000000, 1);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    #[expected_failure(abort_code = ERR_NOT_IN_LISTING, location = nft_market::nft_market)]
    public entry fun buy_not_existent_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"GGWP Test collection");
        let token1_name: String = string::utf8(b"GGWP Test token1 name");

        nft_market::buy(buyer, contributor_addr, contributor_addr, coll_name, token1_name);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    #[expected_failure(abort_code = ERR_NOT_IN_LISTING, location = nft_market::nft_market)]
    public entry fun delisting_not_existent_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"GGWP Test collection");
        let token1_name: String = string::utf8(b"GGWP Test token1 name");

        nft_market::delisting(contributor, contributor_addr, coll_name, token1_name);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    #[expected_failure(abort_code = ERR_ALREADY_IN_LISTING, location = nft_market::nft_market)]
    public entry fun listing_double_listing_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"GGWP Test collection");
        let token1_name: String = string::utf8(b"GGWP Test token1 name");

        nft_market::listing(contributor, contributor_addr, coll_name, token1_name, 100000000);
        nft_market::listing(contributor, contributor_addr, coll_name, token1_name, 100000000);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    #[expected_failure(abort_code = ERR_INVALID_TOKEN_NAME, location = nft_market::nft_market)]
    public entry fun listing_invalid_token_name_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"GGWP Test collection");
        let token1_name: String = string::utf8(b"Test token1 name");

        nft_market::listing(contributor, contributor_addr, coll_name, token1_name, 100000000);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    #[expected_failure(abort_code = ERR_INVALID_COLLECTION_NAME, location = nft_market::nft_market)]
    public entry fun listing_invalid_collection_name_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"Test collection");
        let token1_name: String = string::utf8(b"GGWP Test token1 name");

        nft_market::listing(contributor, contributor_addr, coll_name, token1_name, 100000000);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    #[expected_failure(abort_code = ERR_INVALID_PRICE, location = nft_market::nft_market)]
    public entry fun listing_invalid_price_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, _gateway_addr, ac_fund_addr, contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));

        let coll_name: String = string::utf8(b"Test collection");
        let token1_name: String = string::utf8(b"Test token1 name");

        nft_market::listing(contributor, contributor_addr, coll_name, token1_name, 0);
    }

    #[test(nft_market = @nft_market, gateway = @gateway, ggwp_coin = @coin, accumulative_fund = @0x11223344, contributor = @0x2222, buyer = @0x1111)]
    public entry fun update_params_test(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer) {
        let (_nft_market_addr, gateway_addr, ac_fund_addr, _contributor_addr, _buyer_addr)
            = fixture_setup(nft_market, gateway, ggwp_coin, accumulative_fund, contributor, buyer);

        let royalty = 8;
        nft_market::initialize(nft_market, ac_fund_addr, royalty, string::utf8(b"seed"));
        assert!(nft_market::get_accumulative_fund_addr() == ac_fund_addr, 1);
        assert!(nft_market::get_royalty() == royalty, 1);

        nft_market::update_params(nft_market, gateway_addr, 10);
        assert!(nft_market::get_accumulative_fund_addr() == gateway_addr, 1);
        assert!(nft_market::get_royalty() == 10, 1);
    }

    fun fixture_setup(nft_market: &signer, gateway: &signer, ggwp_coin: &signer, accumulative_fund: &signer, contributor: &signer, buyer: &signer)
    : (address, address, address, address, address) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669882762);

        let nft_market_addr = signer::address_of(nft_market);
        create_account_for_test(nft_market_addr);
        let gateway_addr = signer::address_of(gateway);
        create_account_for_test(gateway_addr);
        let ac_fund_addr = signer::address_of(accumulative_fund);
        create_account_for_test(ac_fund_addr);
        let contributor_addr = signer::address_of(contributor);
        create_account_for_test(contributor_addr);
        let buyer_addr = signer::address_of(buyer);
        create_account_for_test(buyer_addr);

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(accumulative_fund);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(buyer);
        assert!(coin::balance<GGWPCoin>(buyer_addr) == 0, 1);

        let reward_coefficient = 20000;
        let royalty = 8;
        let time_frame = 30 * 60;
        let burn_period = time_frame * 244;
        gateway::initialize(gateway, ac_fund_addr, reward_coefficient, royalty, time_frame, burn_period);

        let gpass_cost = 1;
        let project_name = string::utf8(b"test project game 1");
        gateway::sign_up(contributor, gateway_addr, project_name, gpass_cost);

        let coll_name: String = string::utf8(b"GGWP Test collection");
        let coll_desc: String = string::utf8(b"GGWP Test collection description");
        let token1_name: String = string::utf8(b"GGWP Test token1 name");

        let mutate_setting = vector::empty<bool>();
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        token::create_collection_script(contributor, coll_name, coll_desc, coll_desc, 0, mutate_setting);

        let mutate_setting = vector::empty<bool>();
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        vector::push_back(&mut mutate_setting, false);
        token::create_token_script(contributor, coll_name, token1_name, token1_name, 1, 1, token1_name, contributor_addr, 100, 1, mutate_setting, vector::empty<String>(), vector::empty<vector<u8>>(), vector::empty<String>());

        (nft_market_addr, gateway_addr, ac_fund_addr, contributor_addr, buyer_addr)
    }
}
