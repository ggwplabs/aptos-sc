module staking::staking {
    use std::signer;
    use std::vector;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;

    use coin::ggwp::GGWPCoin;

    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_INVALID_ROYALTY: u64 = 0x1003;
    const ERR_INVALID_APR: u64 = 0x1004;
    const ERR_INVALID_EPOCH_PERIOD: u64 = 0x1005;
    const ERR_INVALID_MIN_STAKE_AMOUNT: u64 = 0x1006;
    const ERR_INVALID_HOLD_PERIOD: u64 = 0x1007;
    const ERR_MIN_STAKE_AMOUNT_EXCEEDED: u64 = 0x1008;
    const ERR_ADDITIONAL_STAKE_NOT_ALLOWED: u64 = 0x1009;
    const ERR_UNKNOWN_APR_VAL: u64 = 0x1010;
    const ERR_NOTHING_TO_WITHDRAW: u64 = 0x1011;

    struct StakingInfo has key, store {
        accumulative_fund: address,
        staking_fund: Coin<GGWPCoin>,

        total_staked: u64,
        start_time: u64,
        epoch_period: u64,
        min_stake_amount: u64,
        hold_period: u64,
        hold_royalty: u8,
        royalty: u8,
        apr_start: u8,
        apr_step: u8,
        apr_end: u8,
    }

    struct UserInfo has key, store {
        amount: u64,
        stake_time: u64,
    }

    /// Initialize new staking info account with params.
    public entry fun initialize(staking: &signer,
        accumulative_fund: address,
        epoch_period: u64,
        min_stake_amount: u64,
        hold_period: u64,
        hold_royalty: u8,
        royalty: u8,
        apr_start: u8,
        apr_step: u8,
        apr_end: u8,
    ) {
        let staking_addr = signer::address_of(staking);
        assert!(!exists<StakingInfo>(staking_addr), ERR_ALREADY_INITIALIZED);

        assert!(epoch_period != 0, ERR_INVALID_EPOCH_PERIOD);
        assert!(min_stake_amount != 0, ERR_INVALID_MIN_STAKE_AMOUNT);
        assert!(hold_period != 0, ERR_INVALID_HOLD_PERIOD);
        assert!(hold_royalty != 0, ERR_INVALID_ROYALTY);
        assert!(hold_royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(royalty != 0, ERR_INVALID_ROYALTY);
        assert!(royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(apr_start != 0, ERR_INVALID_APR);
        assert!(apr_step != 0, ERR_INVALID_APR);
        assert!(apr_end != 0, ERR_INVALID_APR);

        let now = timestamp::now_seconds();
        let staking_info = StakingInfo {
            accumulative_fund: accumulative_fund,
            staking_fund: coin::zero<GGWPCoin>(),

            total_staked: 0,
            start_time: now,
            epoch_period: epoch_period,
            min_stake_amount: min_stake_amount,
            hold_period: hold_period,
            hold_royalty: hold_royalty,
            royalty: royalty,
            apr_start: apr_start,
            apr_step: apr_step,
            apr_end: apr_end,
        };
        move_to(staking, staking_info);
    }

    /// Update staking params.
    public entry fun update_params(staking: &signer,
        epoch_period: u64,
        min_stake_amount: u64,
        hold_period: u64,
        hold_royalty: u8,
        royalty: u8,
    ) acquires StakingInfo {
        let staking_addr = signer::address_of(staking);
        assert!(exists<StakingInfo>(staking_addr), ERR_NOT_INITIALIZED);

        assert!(epoch_period != 0, ERR_INVALID_EPOCH_PERIOD);
        assert!(min_stake_amount != 0, ERR_INVALID_MIN_STAKE_AMOUNT);
        assert!(hold_period != 0, ERR_INVALID_HOLD_PERIOD);
        assert!(hold_royalty != 0, ERR_INVALID_ROYALTY);
        assert!(hold_royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(royalty != 0, ERR_INVALID_ROYALTY);
        assert!(royalty <= 100, ERR_INVALID_ROYALTY);

        let staking_info = borrow_global_mut<StakingInfo>(staking_addr);
        staking_info.epoch_period = epoch_period;
        staking_info.min_stake_amount = min_stake_amount;
        staking_info.hold_period = hold_period;
        staking_info.hold_royalty = hold_royalty;
        staking_info.royalty = royalty;
    }

    /// User can stake amount of GGWP to earn extra GGWP.
    public entry fun stake(user: &signer, staking_addr: address, amount: u64) acquires StakingInfo, UserInfo {
        let user_addr = signer::address_of(user);
        assert!(exists<StakingInfo>(staking_addr), ERR_NOT_INITIALIZED);

        let staking_info = borrow_global_mut<StakingInfo>(staking_addr);
        assert!(amount > staking_info.min_stake_amount, ERR_MIN_STAKE_AMOUNT_EXCEEDED);

        if (!exists<UserInfo>(user_addr)) {
            let user_info = UserInfo {
                amount: 0,
                stake_time: 0,
            };
            move_to(user, user_info);
        };

        let user_info = borrow_global_mut<UserInfo>(user_addr);
        assert!(user_info.amount == 0, ERR_ADDITIONAL_STAKE_NOT_ALLOWED);

        // TODO: Mint NFT

        // Transfer royalty into accumulative fund.
        let royalty_amount = calc_royalty_amount(amount, staking_info.royalty);
        coin::transfer<GGWPCoin>(user, staking_info.accumulative_fund, royalty_amount);

        let amount = amount - royalty_amount;

        // Transfer amount into staking_fund
        let amount_coins = coin::withdraw<GGWPCoin>(user, amount);
        coin::merge(&mut staking_info.staking_fund, amount_coins);

        let now = timestamp::now_seconds();
        user_info.amount = amount;
        user_info.stake_time = now;
        staking_info.total_staked = staking_info.total_staked + amount;
    }

    /// User can withdraw full amount of GGWP with extra reward.
    public entry fun withdraw(user: &signer, staking_addr: address) acquires StakingInfo, UserInfo {
        let user_addr = signer::address_of(user);
        assert!(exists<StakingInfo>(staking_addr), ERR_NOT_INITIALIZED);
        assert!(exists<UserInfo>(user_addr), ERR_NOT_INITIALIZED);

        let staking_info = borrow_global_mut<StakingInfo>(staking_addr);
        let user_info = borrow_global_mut<UserInfo>(user_addr);

        let amount = user_info.amount;
        assert!(amount != 0, ERR_NOTHING_TO_WITHDRAW);

        let now = timestamp::now_seconds();
        let user_reward_amount = calc_user_reward_amount(
            staking_info.epoch_period,
            staking_info.start_time,
            staking_info.apr_start,
            staking_info.apr_step,
            staking_info.apr_end,
            amount,
            user_info.stake_time,
            now,
        );

        // Get withdraw royalty if needed and transfer
        if (is_withdraw_royalty(now, user_info.stake_time, staking_info.hold_period)) {
            let withdraw_royalty_amount = calc_royalty_amount(amount, staking_info.hold_royalty);
            // Transfer royalty from staking_fund to accumulative fund
            let royalty_coins = coin::extract(&mut staking_info.staking_fund, withdraw_royalty_amount);
            coin::deposit(staking_info.accumulative_fund, royalty_coins);
            amount = amount - withdraw_royalty_amount;
        };

        // Transfer GGWP reward to user from staking fund
        let reward_coins = coin::extract(&mut staking_info.staking_fund, user_reward_amount);
        coin::deposit(user_addr, reward_coins);

        // Transfer GGWP staked tokens to user from staking_fund
        let amount_coins = coin::extract(&mut staking_info.staking_fund, amount);
        coin::deposit(user_addr, amount_coins);

        staking_info.total_staked = staking_info.total_staked - user_info.amount;
        user_info.amount = 0;
        user_info.stake_time = 0;
    }

    // Getters
    // TODO: get_current_epoch (calculated)

    // Utils

    /// Get the percent value.
    public fun calc_royalty_amount(amount: u64, royalty: u8): u64 {
        amount / 100 * (royalty as u64)
    }

    /// Checks stake time for withdraw royalty.
    public fun is_withdraw_royalty(time: u64, stake_time: u64, hold_period: u64): bool {
        if (stake_time > time) {
            return true
        };

        let spent_time = time - stake_time;
        if (spent_time >= hold_period) {
            false
        } else {
            true
        }
    }

    /// Get number of epoch.
    public fun get_epoch_by_time(
        staking_start_time: u64,
        time: u64,
        epoch_period: u64
    ): (u64, bool) {
        let spent_time = time - staking_start_time;
        let epoch = spent_time / epoch_period;

        if (spent_time % epoch_period == 0) {
            (epoch + 1, true)
        } else {
            (epoch + 1, false)
        }
    }

    /// Get the current APR by epoch.
    public fun get_apr_by_epoch(epoch: u64, start_apr: u8, step_apr: u8, end_apr: u8): u8 {
        let apr = (step_apr as u64) * (epoch - 1);
        if ((start_apr as u64) > apr) {
            apr = (start_apr as u64) - apr;
        }
        else {
            apr = (end_apr as u64);
        };

        if (apr < (end_apr as u64)) {
            end_apr
        }
        else {
            (apr as u8)
        }
    }

    /// Get the vector of epoch past since start time
    public fun calc_user_past_epochs(
        staking_start_time: u64,
        user_stake_time: u64,
        current_time: u64,
        epoch_period: u64,
    ): vector<u64> {
        let epochs: vector<u64> = vector::empty();
        let (user_start_epoch, is_user_start_epoch_full)
            = get_epoch_by_time(staking_start_time, user_stake_time, epoch_period);
        let (user_end_epoch, _) =
            get_epoch_by_time(staking_start_time, current_time, epoch_period);

        if (is_user_start_epoch_full == false) {
            user_start_epoch = user_start_epoch + 1;
        };

        let elem = user_start_epoch;
        while (elem < user_end_epoch) {
            vector::push_back(&mut epochs, elem);
            elem = elem + 1;
        };

        epochs
    }

    const FLOAT_DECIMALS: u128  = 10000000000; // 10 digits
    const AMOUNT_DECIMALS: u128 = 100000000; // 8 digits

    /// Calc user reward amount by user stake amount, epoch staked.
    public fun calc_user_reward_amount(
        epoch_period: u64,
        staking_start_time: u64,
        staking_start_apr: u8,
        staking_step_apr: u8,
        staking_end_apr: u8,
        user_staked_amount: u64,
        user_stake_time: u64,
        current_time: u64,
    ): u64 {
        let epochs = calc_user_past_epochs(
            staking_start_time,
            user_stake_time,
            current_time,
            epoch_period,
        );
        let epochs_len = vector::length(&epochs);
        let epoch_period_days = epoch_period / (24 * 60 * 60);

        let i = 0;
        let user_new_amount: u128 = (user_staked_amount as u128) * (FLOAT_DECIMALS / AMOUNT_DECIMALS);
        while (i < epochs_len) {
            let epoch = vector::borrow(&epochs, i);
            let current_apr =
                get_apr_by_epoch(*epoch, staking_start_apr, staking_step_apr, staking_end_apr);
            let current_apr: u128 = get_apr_val(current_apr);

            // pow(current_apr, epoch_period_days)
            let deg = epoch_period_days;
            let current_apr_deg = current_apr;
            while (deg != 1) {
                current_apr_deg = (current_apr_deg * current_apr) / FLOAT_DECIMALS;
                deg = deg - 1;
            };
            current_apr = current_apr_deg;

            user_new_amount = (user_new_amount * current_apr) / FLOAT_DECIMALS;
            i = i + 1;
        };

        let user_new_amount: u64 = ((user_new_amount / (FLOAT_DECIMALS / AMOUNT_DECIMALS)) as u64);
        user_new_amount - user_staked_amount
    }

    /// return 1.0 + ((apr / 100.0) / 365.0)
    public fun get_apr_val(apr: u8): u128 {
        assert!(apr <= 100, ERR_UNKNOWN_APR_VAL);
        assert!(apr != 0, ERR_UNKNOWN_APR_VAL);
        if (apr == 1) {
            10000273972
        } else if (apr == 2) {
            10000547945
        } else if (apr == 3) {
            10000821917
        } else if (apr == 4) {
            10001095890
        } else if (apr == 5) {
            10001369863
        } else if (apr == 6) {
            10001643835
        } else if (apr == 7) {
            10001917808
        } else if (apr == 8) {
            10002191780
        } else if (apr == 9) {
            10002465753
        } else if (apr == 10) {
            10002739726
        } else if (apr == 11) {
            10003013698
        } else if (apr == 12) {
            10003287671
        } else if (apr == 13) {
            10003561643
        } else if (apr == 14) {
            10003835616
        } else if (apr == 15) {
            10004109589
        } else if (apr == 16) {
            10004383561
        } else if (apr == 17) {
            10004657534
        } else if (apr == 18) {
            10004931506
        } else if (apr == 19) {
            10005205479
        } else if (apr == 20) {
            10005479452
        } else if (apr == 21) {
            10005753424
        } else if (apr == 22) {
            10006027397
        } else if (apr == 23) {
            10006301369
        } else if (apr == 24) {
            10006575342
        } else if (apr == 25) {
            10006849315
        } else if (apr == 26) {
            10007123287
        } else if (apr == 27) {
            10007397260
        } else if (apr == 28) {
            10007671232
        } else if (apr == 29) {
            10007945205
        } else if (apr == 30) {
            10008219178
        } else if (apr == 31) {
            10008493150
        } else if (apr == 32) {
            10008767123
        } else if (apr == 33) {
            10009041095
        } else if (apr == 34) {
            10009315068
        } else if (apr == 35) {
            10009589041
        } else if (apr == 36) {
            10009863013
        } else if (apr == 37) {
            10010136986
        } else if (apr == 38) {
            10010410958
        } else if (apr == 39) {
            10010684931
        } else if (apr == 40) {
            10010958904
        } else if (apr == 41) {
            10011232876
        } else if (apr == 42) {
            10011506849
        } else if (apr == 43) {
            10011780821
        } else if (apr == 44) {
            10012054794
        } else if (apr == 45) {
            10012328767
        } else if (apr == 46) {
            10012602739
        } else if (apr == 47) {
            10012876712
        } else if (apr == 48) {
            10013150684
        } else if (apr == 49) {
            10013424657
        } else if (apr == 50) {
            10013698630
        } else if (apr == 51) {
            10013972602
        } else if (apr == 52) {
            10014246575
        } else if (apr == 53) {
            10014520547
        } else if (apr == 54) {
            10014794520
        } else if (apr == 55) {
            10015068493
        } else if (apr == 56) {
            10015342465
        } else if (apr == 57) {
            10015616438
        } else if (apr == 58) {
            10015890410
        } else if (apr == 59) {
            10016164383
        } else if (apr == 60) {
            10016438356
        } else if (apr == 61) {
            10016712328
        } else if (apr == 62) {
            10016986301
        } else if (apr == 63) {
            10017260273
        } else if (apr == 64) {
            10017534246
        } else if (apr == 65) {
            10017808219
        } else if (apr == 66) {
            10018082191
        } else if (apr == 67) {
            10018356164
        } else if (apr == 68) {
            10018630136
        } else if (apr == 69) {
            10018904109
        } else if (apr == 70) {
            10019178082
        } else if (apr == 71) {
            10019452054
        } else if (apr == 72) {
            10019726027
        } else if (apr == 73) {
            10020000000
        } else if (apr == 74) {
            10020273972
        } else if (apr == 75) {
            10020547945
        } else if (apr == 76) {
            10020821917
        } else if (apr == 77) {
            10021095890
        } else if (apr == 78) {
            10021369863
        } else if (apr == 79) {
            10021643835
        } else if (apr == 80) {
            10021917808
        } else if (apr == 81) {
            10022191780
        } else if (apr == 82) {
            10022465753
        } else if (apr == 83) {
            10022739726
        } else if (apr == 84) {
            10023013698
        } else if (apr == 85) {
            10023287671
        } else if (apr == 86) {
            10023561643
        } else if (apr == 87) {
            10023835616
        } else if (apr == 88) {
            10024109589
        } else if (apr == 89) {
            10024383561
        } else if (apr == 90) {
            10024657534
        } else if (apr == 91) {
            10024931506
        } else if (apr == 92) {
            10025205479
        } else if (apr == 93) {
            10025479452
        } else if (apr == 94) {
            10025753424
        } else if (apr == 95) {
            10026027397
        } else if (apr == 96) {
            10026301369
        } else if (apr == 97) {
            10026575342
        } else if (apr == 98) {
            10026849315
        } else if (apr == 99) {
            10027123287
        } else { // apr == 100
            10027397260
        }
    }
}
