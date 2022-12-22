module accumulative_fund::distribution_test {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::coin;
    use aptos_framework::genesis;
    use aptos_framework::account::create_account_for_test;

    use accumulative_fund::distribution;
    use coin::ggwp::GGWPCoin;

    #[test(ac_fund_signer = @accumulative_fund)]
    public fun update_shares_test(ac_fund_signer: &signer) {
        genesis::setup();

        let ac_fund_addr = signer::address_of(ac_fund_signer);
        create_account_for_test(ac_fund_addr);

        let play_to_earn_fund = @0x1111;
        let play_to_earn_fund_share = 45;
        let staking_fund = @0x1122;
        let staking_fund_share = 40;
        let company_fund = @0x1133;
        let company_fund_share = 5;
        let team_fund = @0x1144;
        let team_fund_share = 10;
        distribution::initialize(ac_fund_signer,
            play_to_earn_fund,
            play_to_earn_fund_share,
            staking_fund,
            staking_fund_share,
            company_fund,
            company_fund_share,
            team_fund,
            team_fund_share,
        );

        assert!(distribution::get_play_to_earn_fund(ac_fund_addr) == play_to_earn_fund, 1);
        assert!(distribution::get_play_to_earn_fund_share(ac_fund_addr) == play_to_earn_fund_share, 1);
        assert!(distribution::get_staking_fund(ac_fund_addr) == staking_fund, 1);
        assert!(distribution::get_staking_fund_share(ac_fund_addr) == staking_fund_share, 1);
        assert!(distribution::get_company_fund(ac_fund_addr) == company_fund, 1);
        assert!(distribution::get_company_fund_share(ac_fund_addr) == company_fund_share, 1);
        assert!(distribution::get_team_fund(ac_fund_addr) == team_fund, 1);
        assert!(distribution::get_team_fund_share(ac_fund_addr) == team_fund_share, 1);

        distribution::update_shares(ac_fund_signer, 10, 20, 50, 20);
        assert!(distribution::get_play_to_earn_fund_share(ac_fund_addr) == 10, 1);
        assert!(distribution::get_staking_fund_share(ac_fund_addr) == 20, 1);
        assert!(distribution::get_company_fund_share(ac_fund_addr) == 50, 1);
        assert!(distribution::get_team_fund_share(ac_fund_addr) == 20, 1);
    }

    #[test(ac_fund_signer = @accumulative_fund, ggwp_coin = @coin, play_to_earn_fund = @0x11111, staking_fund = @0x1122, company_fund = @0x1133, team_fund = @0x1144)]
    #[expected_failure(abort_code = 0x1004, location = accumulative_fund::distribution)]
    public fun zero_accumulative_fund_amount(ac_fund_signer: &signer, ggwp_coin: &signer, play_to_earn_fund: &signer, staking_fund: &signer, company_fund: &signer, team_fund: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669292558);

        let ac_fund_addr = signer::address_of(ac_fund_signer);
        create_account_for_test(ac_fund_addr);
        let play_to_earn_fund_addr = signer::address_of(play_to_earn_fund);
        create_account_for_test(play_to_earn_fund_addr);
        let staking_fund_addr = signer::address_of(staking_fund);
        create_account_for_test(staking_fund_addr);
        let company_fund_addr = signer::address_of(company_fund);
        create_account_for_test(company_fund_addr);
        let team_fund_addr = signer::address_of(team_fund);
        create_account_for_test(team_fund_addr);

        let play_to_earn_fund_share = 45;
        let staking_fund_share = 40;
        let company_fund_share = 5;
        let team_fund_share = 10;
        distribution::initialize(ac_fund_signer,
            play_to_earn_fund_addr,
            play_to_earn_fund_share,
            staking_fund_addr,
            staking_fund_share,
            company_fund_addr,
            company_fund_share,
            team_fund_addr,
            team_fund_share,
        );

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(ac_fund_signer);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(play_to_earn_fund);
        assert!(coin::balance<GGWPCoin>(play_to_earn_fund_addr) == 0, 1);
        coin::ggwp::register(staking_fund);
        assert!(coin::balance<GGWPCoin>(staking_fund_addr) == 0, 1);
        coin::ggwp::register(company_fund);
        assert!(coin::balance<GGWPCoin>(company_fund_addr) == 0, 1);
        coin::ggwp::register(team_fund);
        assert!(coin::balance<GGWPCoin>(team_fund_addr) == 0, 1);

        distribution::distribute(ac_fund_signer);
    }

    #[test(ac_fund_signer = @accumulative_fund, ggwp_coin = @coin, play_to_earn_fund = @0x11111, staking_fund = @0x1122, company_fund = @0x1133, team_fund = @0x1144)]
    public fun functional(ac_fund_signer: &signer, ggwp_coin: &signer, play_to_earn_fund: &signer, staking_fund: &signer, company_fund: &signer, team_fund: &signer) {
        genesis::setup();
        timestamp::update_global_time_for_test_secs(1669292558);

        let ac_fund_addr = signer::address_of(ac_fund_signer);
        create_account_for_test(ac_fund_addr);
        let play_to_earn_fund_addr = signer::address_of(play_to_earn_fund);
        create_account_for_test(play_to_earn_fund_addr);
        let staking_fund_addr = signer::address_of(staking_fund);
        create_account_for_test(staking_fund_addr);
        let company_fund_addr = signer::address_of(company_fund);
        create_account_for_test(company_fund_addr);
        let team_fund_addr = signer::address_of(team_fund);
        create_account_for_test(team_fund_addr);

        let play_to_earn_fund_share = 45;
        let staking_fund_share = 40;
        let company_fund_share = 6;
        let team_fund_share = 9;
        distribution::initialize(ac_fund_signer,
            play_to_earn_fund_addr,
            play_to_earn_fund_share,
            staking_fund_addr,
            staking_fund_share,
            company_fund_addr,
            company_fund_share,
            team_fund_addr,
            team_fund_share,
        );

        coin::ggwp::set_up_test(ggwp_coin);

        coin::ggwp::register(ac_fund_signer);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        coin::ggwp::register(play_to_earn_fund);
        assert!(coin::balance<GGWPCoin>(play_to_earn_fund_addr) == 0, 1);
        coin::ggwp::register(staking_fund);
        assert!(coin::balance<GGWPCoin>(staking_fund_addr) == 0, 1);
        coin::ggwp::register(company_fund);
        assert!(coin::balance<GGWPCoin>(company_fund_addr) == 0, 1);
        coin::ggwp::register(team_fund);
        assert!(coin::balance<GGWPCoin>(team_fund_addr) == 0, 1);

        coin::ggwp::mint_to(ggwp_coin, 10000000000, ac_fund_addr);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 10000000000, 1);

        distribution::distribute(ac_fund_signer);

        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        assert!(coin::balance<GGWPCoin>(play_to_earn_fund_addr) == 4500000000, 1);
        assert!(coin::balance<GGWPCoin>(staking_fund_addr) == 4000000000, 1);
        assert!(coin::balance<GGWPCoin>(company_fund_addr) == 600000000, 1);
        assert!(coin::balance<GGWPCoin>(team_fund_addr) == 900000000, 1);

        coin::ggwp::mint_to(ggwp_coin, 700100000001, ac_fund_addr);
        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 700100000001, 1);

        distribution::distribute(ac_fund_signer);

        assert!(coin::balance<GGWPCoin>(ac_fund_addr) == 0, 1);
        assert!(coin::balance<GGWPCoin>(play_to_earn_fund_addr) == 4500000000 + 315045000000, 1);
        assert!(coin::balance<GGWPCoin>(staking_fund_addr) == 4000000000 + 280040000000, 1);
        assert!(coin::balance<GGWPCoin>(company_fund_addr) == 600000000 + 42006000000, 1);
        assert!(coin::balance<GGWPCoin>(team_fund_addr) == 900000000 + 63009000001, 1);
    }
}
