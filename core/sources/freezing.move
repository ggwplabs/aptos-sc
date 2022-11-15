module ggwp_core::freezing {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_INVALID_PERIOD: u64 = 0x1003;
    const ERR_INVALID_ROYALTY: u64 = 0x1004;
    const ERR_ZERO_FREEZING_AMOUNT: u64 = 0x1005;

    struct RewardTableRow has store, drop {
        ggwp_amount: u64,
        gpass_amount: u64
    }

    /// Common data struct with info.
    struct FreezingInfo has key, store {
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

    struct UserInfo has key, store {
        freezed_amount: u64,
        freezed_time: u64,       // UnixTimestamp
        last_getting_gpass: u64, // UnixTimestamp
    }

    /// Initialize freezing with params.
    public entry fun initialize(freezing_account: &signer,
        reward_period: u64,
        royalty: u8,
        unfreeze_royalty: u8,
        unfreeze_lock_period: u64,
        reward_table: vector<RewardTableRow>,
    ) {
        let freezing_addr = signer::address_of(freezing_account);
        assert!(!exists<FreezingInfo>(freezing_addr), ERR_ALREADY_INITIALIZED);

        assert!(reward_period != 0, ERR_INVALID_PERIOD);
        assert!(royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(unfreeze_royalty <= 100, ERR_INVALID_ROYALTY);

        let now = timestamp::now_seconds();
        let freezing_info = FreezingInfo {
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
        move_to(freezing_account, freezing_info);
    }

    /// Update freezing parameters.
    public entry fun update_params(freezing_account: &signer,
        reward_period: u64,
        royalty: u8,
        unfreeze_royalty: u8,
        unfreeze_lock_period: u64,
        reward_table: vector<RewardTableRow>,
    ) acquires FreezingInfo {
        let freezing_addr = signer::address_of(freezing_account);
        assert!(exists<FreezingInfo>(freezing_addr), ERR_NOT_INITIALIZED);

        assert!(reward_period != 0, ERR_INVALID_PERIOD);
        assert!(royalty <= 100, ERR_INVALID_ROYALTY);
        assert!(unfreeze_royalty <= 100, ERR_INVALID_ROYALTY);

        let freezing_info = borrow_global_mut<FreezingInfo>(freezing_addr);
        freezing_info.reward_period = reward_period;
        freezing_info.royalty = royalty;
        freezing_info.unfreeze_royalty = unfreeze_royalty;
        freezing_info.unfreeze_lock_period = unfreeze_lock_period;
        freezing_info.reward_table = reward_table;
    }

    /// User freezes his amount of GGWP token to get the GPASS.
    public entry fun freeze_tokens(user: &signer, freezing_info: address, freeze_amount: u64) {
        assert!(exists<FreezingInfo>(freezing_info), ERR_NOT_INITIALIZED);
        assert!(freeze_amount != 0, ERR_ZERO_FREEZING_AMOUNT);

        if (!exists<UserInfo>(freezing_info)) {
            let user_info = UserInfo {
                freezed_amount: 0,
                freezed_time: 0,
                last_getting_gpass: 0,
            };
            move_to(user, user_info);
        }

        // TODO: royalty amount
        // Pay amount of GPASS earned by user immediately

    }

    fun earned_gpass_immediately(reward_table: &vector<RewardTableRow>, freezed_amount: u64): u64 {
        let earned_gpass = 0;
        let i = 0;
        while (i < vector::length(reward_table)) {
            let row = vector::borrow(reward_table, i);
            if (freezed_amount >= row.ggwp_amount) {
                earned_gpass = row.gpass_amount;
            } else {
                break
            }
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
}
