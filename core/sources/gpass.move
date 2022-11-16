/// Module for gpass tickets.
module ggwp_core::gpass {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};

    use coin::ggwp::GGWPCoin;

    // Common errors.
    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    // GPASS errors.
    const ERR_INVALID_BURN_PERIOD: u64 = 0x1011;
    const ERR_WALLET_NOT_INITIALIZED: u64 = 0x1012;
    const ERR_INVALID_AMOUNT: u64 = 0x1013;
    const ERR_INVALID_BURN_AUTH: u64 = 0x1014;
    // Freezing errors.
    const ERR_INVALID_PERIOD: u64 = 0x1021;
    const ERR_INVALID_ROYALTY: u64 = 0x1022;
    const ERR_ZERO_FREEZING_AMOUNT: u64 = 0x1023;

    /// Initialize module.
    public entry fun initialize(
        ggwp_core: &signer,
        accumulative_fund: address,
        burn_period: u64,
        burners: vector<address>,
        reward_period: u64,
        royalty: u8,
        unfreeze_royalty: u8,
        unfreeze_lock_period: u64,
        reward_table: vector<RewardTableRow>,
    ) {
        let ggwp_core_addr = signer::address_of(ggwp_core);
        assert!(!exists<GpassInfo>(ggwp_core_addr), ERR_ALREADY_INITIALIZED);
        assert!(!exists<FreezingInfo>(ggwp_core_addr), ERR_ALREADY_INITIALIZED);

        assert!(burn_period != 0, ERR_INVALID_BURN_PERIOD);
        assert!(reward_period != 0, ERR_INVALID_PERIOD);
        assert!(royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(unfreeze_royalty <= 100, ERR_INVALID_ROYALTY);

        let gpass_info = GpassInfo {
            burn_period: burn_period,
            total_amount: 0,
            burners: burners,
        };
        move_to(ggwp_core, gpass_info);

        let now = timestamp::now_seconds();
        let freezing_info = FreezingInfo {
            treasury: coin::zero<GGWPCoin>(),
            accumulative_fund: accumulative_fund,
            total_freezed: 0,
            total_users_freezed: 0,
            reward_period: reward_period,
            royalty: royalty,

            daily_gpass_reward: 0,
            daily_gpass_reward_last_reset: now,

            unfreeze_royalty: unfreeze_royalty,
            unfreeze_lock_period: unfreeze_lock_period,

            reward_table: reward_table,
        };
        move_to(ggwp_core, freezing_info);
    }

    // GPASS

    /// Users accounts data.
    struct Wallet has key, store {
        // Amount with no decimals!
        amount: u64,
        last_burned: u64,
    }

    /// Common data struct with info.
    struct GpassInfo has key, store {
        burn_period: u64,
        total_amount: u64,
        burners: vector<address>,
    }

    /// Adding the new burner in burners list.
    public entry fun add_burner(ggwp_core: &signer, burner: address) acquires GpassInfo {
        let ggwp_core_addr = signer::address_of(ggwp_core);
        assert!(exists<GpassInfo>(ggwp_core_addr), ERR_NOT_INITIALIZED);

        let gpass_info = borrow_global_mut<GpassInfo>(ggwp_core_addr);
        vector::push_back(&mut gpass_info.burners, burner);
    }

    /// Update burn period.
    public entry fun update_burn_period(ggwp_core: &signer, burn_period: u64) acquires GpassInfo {
        let ggwp_core_addr = signer::address_of(ggwp_core);
        assert!(exists<GpassInfo>(ggwp_core_addr), ERR_NOT_INITIALIZED);

        let gpass_info = borrow_global_mut<GpassInfo>(ggwp_core_addr);
        gpass_info.burn_period = burn_period;
    }

    /// User creates new wallet.
    public entry fun create_wallet(user: &signer) {
        let user_addr = signer::address_of(user);
        assert!(!exists<Wallet>(user_addr), ERR_ALREADY_INITIALIZED);

        let now = timestamp::now_seconds();
        let wallet = Wallet {
            amount: 0,
            last_burned: now,
        };
        move_to(user, wallet);
    }

    /// Mint the amount of GPASS to user wallet.
    /// There is trying to burn overdues before minting.
    public fun mint_to(ggwp_core: address, to: address, amount: u64) acquires Wallet, GpassInfo {
        assert!(exists<Wallet>(to), ERR_WALLET_NOT_INITIALIZED);
        assert!(amount != 0, ERR_INVALID_AMOUNT);

        let gpass_info = borrow_global_mut<GpassInfo>(ggwp_core);
        let wallet = borrow_global_mut<Wallet>(to);

        let now = timestamp::now_seconds();
        if (now - wallet.last_burned >= gpass_info.burn_period) {
            gpass_info.total_amount = gpass_info.total_amount - wallet.amount;
            wallet.amount = 0;
            wallet.last_burned = now;
        };

        wallet.amount = wallet.amount + amount;
        gpass_info.total_amount = gpass_info.total_amount + amount;
    }

    /// Burn the amount of GPASS from user wallet. Available only for burners.
    /// There is trying to burn overdues before burning.
    public entry fun burn(burner: &signer, ggwp_core: address, from: address, amount: u64) acquires Wallet, GpassInfo {
        assert!(exists<Wallet>(from), ERR_WALLET_NOT_INITIALIZED);
        assert!(amount != 0, ERR_INVALID_AMOUNT);
        assert!(exists<GpassInfo>(ggwp_core), ERR_NOT_INITIALIZED);

        let gpass_info = borrow_global_mut<GpassInfo>(ggwp_core);
        // Note: burner is the ggwp_games contract.
        assert!(vector::contains(&gpass_info.burners, &signer::address_of(burner)), ERR_INVALID_BURN_AUTH);

        let wallet = borrow_global_mut<Wallet>(from);

        // Try to burn amount before mint
        let now = timestamp::now_seconds();
        if (now - wallet.last_burned >= gpass_info.burn_period) {
            gpass_info.total_amount = gpass_info.total_amount - wallet.amount;
            wallet.amount = 0;
            wallet.last_burned = now;
        };

        if (wallet.amount != 0) {
            wallet.amount = wallet.amount - amount;
            gpass_info.total_amount = gpass_info.total_amount - amount;
        }
    }

    // GPASS Getters.
    public fun get_burn_period(ggwp_core_addr: address): u64 acquires GpassInfo {
        borrow_global<GpassInfo>(ggwp_core_addr).burn_period
    }

    public fun get_total_amount(ggwp_core_addr: address): u64 acquires GpassInfo {
        borrow_global<GpassInfo>(ggwp_core_addr).total_amount
    }

    public fun get_balance(wallet: address): u64 acquires Wallet {
        borrow_global<Wallet>(wallet).amount
    }

    public fun get_last_burned(wallet: address): u64 acquires Wallet {
        borrow_global<Wallet>(wallet).last_burned
    }

    // Freezing
    /// Reward table row.
    struct RewardTableRow has store, drop, copy {
        ggwp_amount: u64,
        gpass_amount: u64
    }

    /// Common data struct with freezing info.
    struct FreezingInfo has key, store {
        treasury: Coin<GGWPCoin>,
        accumulative_fund: address,
        total_freezed: u64,
        total_users_freezed: u64,
        reward_period: u64,
        royalty: u8,

        daily_gpass_reward: u64,
        daily_gpass_reward_last_reset: u64,

        unfreeze_royalty: u8,
        unfreeze_lock_period: u64,

        reward_table: vector<RewardTableRow>,
    }

    /// Freezing user info data.
    struct UserInfo has key, store {
        freezed_amount: u64,
        freezed_time: u64,       // UnixTimestamp
        last_getting_gpass: u64, // UnixTimestamp
    }

    /// Update freezing parameters.
    public entry fun update_freezing_params(
        ggwp_core: &signer,
        reward_period: u64,
        royalty: u8,
        unfreeze_royalty: u8,
        unfreeze_lock_period: u64,
        reward_table: vector<RewardTableRow>,
    ) acquires FreezingInfo {
        let ggwp_core_addr = signer::address_of(ggwp_core);
        assert!(exists<FreezingInfo>(ggwp_core_addr), ERR_NOT_INITIALIZED);

        assert!(reward_period != 0, ERR_INVALID_PERIOD);
        assert!(royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(unfreeze_royalty <= 100, ERR_INVALID_ROYALTY);

        let freezing_info = borrow_global_mut<FreezingInfo>(ggwp_core_addr);
        freezing_info.reward_period = reward_period;
        freezing_info.royalty = royalty;
        freezing_info.unfreeze_royalty = unfreeze_royalty;
        freezing_info.unfreeze_lock_period = unfreeze_lock_period;
        freezing_info.reward_table = reward_table;
    }

    /// User freezes his amount of GGWP token to get the GPASS.
    public entry fun freeze_tokens(user: &signer, ggwp_core_addr: address, freezed_amount: u64) acquires FreezingInfo, GpassInfo, UserInfo, Wallet {
        assert!(exists<FreezingInfo>(ggwp_core_addr), ERR_NOT_INITIALIZED);
        assert!(exists<GpassInfo>(ggwp_core_addr), ERR_NOT_INITIALIZED);
        assert!(freezed_amount != 0, ERR_ZERO_FREEZING_AMOUNT);

        let user_addr = signer::address_of(user);
        if (!exists<UserInfo>(user_addr)) {
            let user_info = UserInfo {
                freezed_amount: 0,
                freezed_time: 0,
                last_getting_gpass: 0,
            };
            move_to(user, user_info);
        };

        let user_info = borrow_global_mut<UserInfo>(user_addr);
        let freezing_info = borrow_global_mut<FreezingInfo>(ggwp_core_addr);

        // Pay amount of GPASS earned by user immediately
        let gpass_earned = earned_gpass_immediately(&freezing_info.reward_table, freezed_amount);

        // Try to reset gpass daily reward
        let now = timestamp::now_seconds();
        let spent_time = now - freezing_info.daily_gpass_reward_last_reset;
        if (spent_time >= 24 * 60 * 60) {
            freezing_info.daily_gpass_reward = 0;
            freezing_info.daily_gpass_reward_last_reset = now;
        };

        if (gpass_earned > 0) {
            freezing_info.daily_gpass_reward = freezing_info.daily_gpass_reward + gpass_earned;
            user_info.last_getting_gpass = now;
            mint_to(ggwp_core_addr, user_addr, gpass_earned);
        };

        // Transfer Freezed GGWP amount to treasury
        let freezed_coins = coin::withdraw<GGWPCoin>(user, freezed_amount);
        coin::merge(&mut freezing_info.treasury, freezed_coins);

        // Transfer royalty amount into accumulative fund
        let royalty_amount = calc_royalty_amount(freezed_amount, freezing_info.royalty);
        coin::transfer<GGWPCoin>(user, freezing_info.accumulative_fund, royalty_amount);

        freezing_info.total_freezed = freezing_info.total_freezed + freezed_amount;
        freezing_info.total_users_freezed = freezing_info.total_users_freezed + 1;
        user_info.freezed_amount = freezed_amount;
        user_info.freezed_time = now;
    }

    // Freezing Getters.

    public fun get_treasury_balance(ggwp_core_addr: address): u64 acquires FreezingInfo {
        let freezing_info = borrow_global<FreezingInfo>(ggwp_core_addr);
        coin::value<GGWPCoin>(&freezing_info.treasury)
    }

    public fun get_reward_period(ggwp_core_addr: address): u64 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).reward_period
    }

    public fun get_royalty(ggwp_core_addr: address): u8 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).royalty
    }

    public fun get_unfreeze_royalty(ggwp_core_addr: address): u8 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).unfreeze_royalty
    }

    public fun get_unfreeze_lock_period(ggwp_core_addr: address): u64 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).unfreeze_lock_period
    }

    public fun get_total_freezed(ggwp_core_addr: address): u64 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).total_freezed
    }

    public fun get_total_users_freezed(ggwp_core_addr: address): u64 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).total_users_freezed
    }

    public fun get_daily_gpass_reward(ggwp_core_addr: address): u64 acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).daily_gpass_reward
    }

    public fun get_reward_table(ggwp_core_addr: address): vector<RewardTableRow> acquires FreezingInfo {
        borrow_global<FreezingInfo>(ggwp_core_addr).reward_table
    }

    // Freezing utils

    fun earned_gpass_immediately(reward_table: &vector<RewardTableRow>, freezed_amount: u64): u64 {
        let earned_gpass = 0;
        let i = 0;
        while (i < vector::length(reward_table)) {
            let row = vector::borrow(reward_table, i);
            if (freezed_amount >= row.ggwp_amount) {
                earned_gpass = row.gpass_amount;
            } else {
                break
            };
            i = i + 1;
        };

        earned_gpass
    }

    fun calc_earned_gpass(
        reward_table: &vector<RewardTableRow>,
        freezed_amount: u64,
        current_time: u64,
        last_getting_gpass: u64,
        reward_period: u64
    ): u64 {
        let spent_time = current_time - last_getting_gpass;
        if (spent_time < reward_period) {
            return 0
        };

        let reward_periods_spent = spent_time / reward_period;
        let earned_gpass = earned_gpass_immediately(reward_table, freezed_amount);
        earned_gpass * reward_periods_spent
    }

    public fun calc_royalty_amount(freezed_amount: u64, royalty: u8): u64 {
        freezed_amount / 100 * (royalty as u64)
    }

    #[test_only]
    public fun get_test_reward_table(): vector<RewardTableRow> {
        let reward_table: vector<RewardTableRow> = vector::empty();
        vector::push_back(&mut reward_table, RewardTableRow {
            ggwp_amount: 5000 * 100000000,
            gpass_amount: 5,
        });
        vector::push_back(&mut reward_table, RewardTableRow {
            ggwp_amount: 10000 * 100000000,
            gpass_amount: 10,
        });
        vector::push_back(&mut reward_table, RewardTableRow {
            ggwp_amount: 15000 * 100000000,
            gpass_amount: 15,
        });
        reward_table
    }

    #[test]
    public fun earned_gpass_immediately_test() {
        let reward_table = get_test_reward_table();
        assert!(earned_gpass_immediately(&reward_table, 5000) == 0, 1);
        assert!(earned_gpass_immediately(&reward_table, 5000 * 100000000) == 5, 1);
        assert!(earned_gpass_immediately(&reward_table, 6000 * 100000000) == 5, 1);
        assert!(earned_gpass_immediately(&reward_table, 10000 * 100000000) == 10, 1);
        assert!(earned_gpass_immediately(&reward_table, 14999 * 100000000) == 10, 1);
        assert!(earned_gpass_immediately(&reward_table, 15000 * 100000000) == 15, 1);
    }

    #[test_only]
    use aptos_framework::genesis;

    #[test]
    public fun calc_earned_gpass_test() {
        genesis::setup();
        let reward_period = 24 * 60 * 60;
        let half_period = 12 * 60 * 60;
        let reward_table = get_test_reward_table();
        let now = timestamp::now_seconds();

        // 0 periods
        assert!(calc_earned_gpass(&reward_table, 5000, now, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 5000 * 100000000, now, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 6000 * 100000000, now, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 10000 * 100000000, now, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 14999 * 100000000, now, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 15000 * 100000000, now, now, reward_period) == 0, 1);

        // 0.5 period
        assert!(calc_earned_gpass(&reward_table, 5000, now + half_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 5000 * 100000000, now + half_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 6000 * 100000000, now + half_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 10000 * 100000000, now + half_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 14999 * 100000000, now + half_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 15000 * 100000000, now + half_period, now, reward_period) == 0, 1);

        // 1 period
        assert!(calc_earned_gpass(&reward_table, 5000, now + reward_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 5000 * 100000000, now + reward_period, now, reward_period) == 5, 1);
        assert!(calc_earned_gpass(&reward_table, 6000 * 100000000, now + reward_period, now, reward_period) == 5, 1);
        assert!(calc_earned_gpass(&reward_table, 10000 * 100000000, now + reward_period, now, reward_period) == 10, 1);
        assert!(calc_earned_gpass(&reward_table, 14999 * 100000000, now + reward_period, now, reward_period) == 10, 1);
        assert!(calc_earned_gpass(&reward_table, 15000 * 100000000, now + reward_period, now, reward_period) == 15, 1);

        // 1.5 period
        assert!(calc_earned_gpass(&reward_table, 5000, now + reward_period + half_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 5000 * 100000000, now + reward_period + half_period, now, reward_period) == 5, 1);
        assert!(calc_earned_gpass(&reward_table, 6000 * 100000000, now + reward_period + half_period, now, reward_period) == 5, 1);
        assert!(calc_earned_gpass(&reward_table, 10000 * 100000000, now + reward_period + half_period, now, reward_period) == 10, 1);
        assert!(calc_earned_gpass(&reward_table, 14999 * 100000000, now + reward_period + half_period, now, reward_period) == 10, 1);
        assert!(calc_earned_gpass(&reward_table, 15000 * 100000000, now + reward_period + half_period, now, reward_period) == 15, 1);

        // 2 periods
        assert!(calc_earned_gpass(&reward_table, 5000, now + reward_period + reward_period, now, reward_period) == 0, 1);
        assert!(calc_earned_gpass(&reward_table, 5000 * 100000000, now + reward_period + reward_period, now, reward_period) == 10, 1);
        assert!(calc_earned_gpass(&reward_table, 6000 * 100000000, now + reward_period + reward_period, now, reward_period) == 10, 1);
        assert!(calc_earned_gpass(&reward_table, 10000 * 100000000, now + reward_period + reward_period, now, reward_period) == 20, 1);
        assert!(calc_earned_gpass(&reward_table, 14999 * 100000000, now + reward_period + reward_period, now, reward_period) == 20, 1);
        assert!(calc_earned_gpass(&reward_table, 15000 * 100000000, now + reward_period + reward_period, now, reward_period) == 30, 1);
    }

    #[test]
    public fun calc_royalty_amount_test() {
        assert!(calc_royalty_amount(500000000, 8) == 40000000, 1);
        assert!(calc_royalty_amount(500000001, 8) == 40000000, 1);
        assert!(calc_royalty_amount(500000010, 8) == 40000000, 1);
        assert!(calc_royalty_amount(500000100, 8) == 40000008, 1);
        assert!(calc_royalty_amount(500000000, 50) == 250000000, 1);
        assert!(calc_royalty_amount(5000000000, 50) == 2500000000, 1);
        assert!(calc_royalty_amount(5100000000, 50) == 2550000000, 1);
        assert!(calc_royalty_amount(5100000000, 0) == 0, 1);
    }

    #[test_only]
    public fun construct_row(ggwp_amount: u64, gpass_amount: u64): RewardTableRow {
        RewardTableRow {
            ggwp_amount: ggwp_amount,
            gpass_amount: gpass_amount,
        }
    }
}
