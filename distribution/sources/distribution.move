module accumulative_fund::distribution {
    use std::signer;
    use std::error;
    use aptos_framework::timestamp;
    use aptos_framework::coin;

    use coin::ggwp::GGWPCoin;

    const ERR_NOT_AUTHORIZED: u64 = 0x1000;
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_INVALID_SHARE: u64 = 0x1003;
    const ERR_EMPTY_ACCUMULATIVE_FUND: u64 = 0x1004;

    struct DistributionInfo has key, store {
        last_distribution: u64,
        play_to_earn_fund: address,
        play_to_earn_fund_share: u8,
        staking_fund: address,
        staking_fund_share: u8,
        company_fund: address,
        company_fund_share: u8,
        team_fund: address,
        team_fund_share: u8,
    }

    /// Initialize distribution contract with information abount funds.
    public entry fun initialize(accumulative_fund: &signer,
        play_to_earn_fund: address,
        play_to_earn_fund_share: u8,
        staking_fund: address,
        staking_fund_share: u8,
        company_fund: address,
        company_fund_share: u8,
        team_fund: address,
        team_fund_share: u8,
    ) {
        let accumulative_fund_addr = signer::address_of(accumulative_fund);
        assert!(accumulative_fund_addr == @accumulative_fund, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(!exists<DistributionInfo>(accumulative_fund_addr), ERR_ALREADY_INITIALIZED);
        assert!(play_to_earn_fund_share <= 100, ERR_INVALID_SHARE);
        assert!(staking_fund_share <= 100, ERR_INVALID_SHARE);
        assert!(company_fund_share <= 100, ERR_INVALID_SHARE);
        assert!(team_fund_share <= 100, ERR_INVALID_SHARE);
        assert!((play_to_earn_fund_share + staking_fund_share + company_fund_share + team_fund_share) == 100, ERR_INVALID_SHARE);

        let distribution_info = DistributionInfo {
            last_distribution: 0,
            play_to_earn_fund: play_to_earn_fund,
            play_to_earn_fund_share: play_to_earn_fund_share,
            staking_fund: staking_fund,
            staking_fund_share: staking_fund_share,
            company_fund: company_fund,
            company_fund_share: company_fund_share,
            team_fund: team_fund,
            team_fund_share: team_fund_share,
        };
        move_to(accumulative_fund, distribution_info);
    }

    /// Update shares.
    public entry fun update_shares(accumulative_fund: &signer,
        play_to_earn_fund_share: u8,
        staking_fund_share: u8,
        company_fund_share: u8,
        team_fund_share: u8,
    ) acquires DistributionInfo {
        let accumulative_fund_addr = signer::address_of(accumulative_fund);
        assert!(accumulative_fund_addr == @accumulative_fund, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<DistributionInfo>(accumulative_fund_addr), ERR_NOT_INITIALIZED);
        assert!(play_to_earn_fund_share <= 100, ERR_INVALID_SHARE);
        assert!(staking_fund_share <= 100, ERR_INVALID_SHARE);
        assert!(company_fund_share <= 100, ERR_INVALID_SHARE);
        assert!(team_fund_share <= 100, ERR_INVALID_SHARE);
        assert!((play_to_earn_fund_share + staking_fund_share + company_fund_share + team_fund_share) == 100, ERR_INVALID_SHARE);

        let distribution_info = borrow_global_mut<DistributionInfo>(accumulative_fund_addr);
        distribution_info.play_to_earn_fund_share = play_to_earn_fund_share;
        distribution_info.staking_fund_share = staking_fund_share;
        distribution_info.company_fund_share = company_fund_share;
        distribution_info.team_fund_share = team_fund_share;
    }

    /// Distribute the funds.
    public entry fun distribute(accumulative_fund: &signer) acquires DistributionInfo {
        let accumulative_fund_addr = signer::address_of(accumulative_fund);
        assert!(accumulative_fund_addr == @accumulative_fund, error::permission_denied(ERR_NOT_AUTHORIZED));
        assert!(exists<DistributionInfo>(accumulative_fund_addr), ERR_NOT_INITIALIZED);

        let amount = coin::balance<GGWPCoin>(accumulative_fund_addr);
        assert!(amount != 0, ERR_EMPTY_ACCUMULATIVE_FUND);

        let distribution_info = borrow_global_mut<DistributionInfo>(accumulative_fund_addr);

        // Transfer GGWP to play to earn fund
        let play_to_earn_fund_amount =
            calc_share_amount(amount, distribution_info.play_to_earn_fund_share);
        coin::transfer<GGWPCoin>(accumulative_fund, distribution_info.play_to_earn_fund, play_to_earn_fund_amount);

        // Transfer GGWP to staking fund
        let staking_fund_amount =
            calc_share_amount(amount, distribution_info.staking_fund_share);
        coin::transfer<GGWPCoin>(accumulative_fund, distribution_info.staking_fund, staking_fund_amount);

        // Transfer GGWP to company fund
        let company_fund_amount =
            calc_share_amount(amount, distribution_info.company_fund_share);
        coin::transfer<GGWPCoin>(accumulative_fund, distribution_info.company_fund, company_fund_amount);

        // Transfer GGWP to team fund
        let team_fund_amount = amount - (play_to_earn_fund_amount + staking_fund_amount + company_fund_amount);
        coin::transfer<GGWPCoin>(accumulative_fund, distribution_info.team_fund, team_fund_amount);

        let now = timestamp::now_seconds();
        distribution_info.last_distribution = now;
    }

    // Getters.

    public fun get_play_to_earn_fund_share(accumulative_fund_addr: address): u8 acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).play_to_earn_fund_share
    }

    public fun get_play_to_earn_fund(accumulative_fund_addr: address): address acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).play_to_earn_fund
    }

    public fun get_staking_fund_share(accumulative_fund_addr: address): u8 acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).staking_fund_share
    }

    public fun get_staking_fund(accumulative_fund_addr: address): address acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).staking_fund
    }

    public fun get_company_fund_share(accumulative_fund_addr: address): u8 acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).company_fund_share
    }

    public fun get_company_fund(accumulative_fund_addr: address): address acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).company_fund
    }

    public fun get_team_fund_share(accumulative_fund_addr: address): u8 acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).team_fund_share
    }

    public fun get_team_fund(accumulative_fund_addr: address): address acquires DistributionInfo {
        borrow_global<DistributionInfo>(accumulative_fund_addr).team_fund
    }

    /// Get the percent value.
    public fun calc_share_amount(amount: u64, share: u8): u64 {
        amount / 100 * (share as u64)
    }
}
