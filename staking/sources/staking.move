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

    struct StakingInfo has key, store {
        accumulative_fund: address,
        staking_fund: address,
        treasury: Coin<GGWPCoin>,

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
        staking_fund: address,
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
            staking_fund: staking_fund,
            treasury: coin::zero<GGWPCoin>(),

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

    // TODO: update params instruction

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

        // Transfer amount into treasury
        let amount_coins = coin::withdraw<GGWPCoin>(user, amount);
        coin::merge(&mut staking_info.treasury, amount_coins);

        let now = timestamp::now_seconds();
        user_info.amount = amount;
        user_info.stake_time = now;
        staking_info.total_staked = staking_info.total_staked + amount;
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

    const FLOAT_DECIMALS: u128 = 1000000000000; // 12 digits
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

            // user_new_amount = user_new_amount * (1.0 + current_apr / 365.0).powi(epoch_period_days as i32);
            let current_apr: u128 = (current_apr as u128) * FLOAT_DECIMALS;
            let current_apr: u128 = ((1 * FLOAT_DECIMALS) + (current_apr / 365));

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

        let user_full_amount: u64 = ((user_new_amount / (FLOAT_DECIMALS / AMOUNT_DECIMALS)) as u64);
        user_full_amount - user_staked_amount
    }
}