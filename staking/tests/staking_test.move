#[test_only]
module staking::staking_test {
    use std::vector;
    use staking::staking::{
        get_epoch_by_time, get_apr_by_epoch, calc_user_past_epochs,
        calc_user_reward_amount, is_withdraw_royalty
    };

    const TIME: u64 = 1660032700;
    const DAY: u64 = 24 * 60 * 60;

    #[test]
    public entry fun is_withdraw_royalty_test() {
        assert!(is_withdraw_royalty(1660032700, 1660032700, 100) == true, 1);
        assert!(is_withdraw_royalty(1660032700, 1660032650, 100) == true, 1);
        assert!(is_withdraw_royalty(1660032700, 1660032800, 100) == true, 1);
        assert!(is_withdraw_royalty(1660032700, 1660032500, 100) == false, 1);
        assert!(is_withdraw_royalty(1660032700, 1660032300, 100) == false, 1);
    }

    #[test]
    public entry fun get_epoch_by_time_test() {
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME, 10 * DAY);
        assert!(epoch == 1, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 5 * DAY, 10 * DAY);
        assert!(epoch == 1, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 10 * DAY, 10 * DAY);
        assert!(epoch == 2, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 15 * DAY, 10 * DAY);
        assert!(epoch == 2, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 20 * DAY, 10 * DAY);
        assert!(epoch == 3, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 299 * DAY, 10 * DAY);
        assert!(epoch == 30, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 300 * DAY, 10 * DAY);
        assert!(epoch == 31, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 301 * DAY, 10 * DAY);
        assert!(epoch == 31, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 3000 * DAY, 10 * DAY);
        assert!(epoch == 301, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 3001 * DAY, 10 * DAY);
        assert!(epoch == 301, 1);
        assert!(is_epoch_start == false, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 2 * 6 * 60 * 60, 6 * 60 * 60);
        assert!(epoch == 3, 1);
        assert!(is_epoch_start == true, 1);
        let (epoch, is_epoch_start) = get_epoch_by_time(TIME, TIME + 2 * 6 * 60 * 60 + 1, 6 * 60 * 60);
        assert!(epoch == 3, 1);
        assert!(is_epoch_start == false, 1);
    }

    #[test]
    public entry fun get_apr_by_epoch_test() {
        assert!(get_apr_by_epoch(1, 45, 1, 5) == 45, 1);
        assert!(get_apr_by_epoch(1, 45, 2, 5) == 45, 1);
        assert!(get_apr_by_epoch(1, 45, 10, 5) == 45, 1);
        assert!(get_apr_by_epoch(1, 45, 10, 40) == 45, 1);
        assert!(get_apr_by_epoch(2, 45, 1, 5) == 44, 1);
        assert!(get_apr_by_epoch(3, 45, 1, 5) == 43, 1);
        assert!(get_apr_by_epoch(10, 45, 1, 5) == 36, 1);
        assert!(get_apr_by_epoch(2, 45, 2, 5) == 43, 1);
        assert!(get_apr_by_epoch(3, 45, 2, 5) == 41, 1);
        assert!(get_apr_by_epoch(40, 45, 1, 5) == 6, 1);
        assert!(get_apr_by_epoch(41, 45, 1, 5) == 5, 1);
        assert!(get_apr_by_epoch(42, 45, 1, 5) == 5, 1);
        assert!(get_apr_by_epoch(43, 45, 1, 5) == 5, 1);
        assert!(get_apr_by_epoch(44, 45, 1, 5) == 5, 1);
        assert!(get_apr_by_epoch(700, 45, 1, 5) == 5, 1);
    }

    #[test]
    public fun calc_user_past_epoch_test() {
        // User starts with staking
        let vec: vector<u64> = vector::empty();
        assert!(calc_user_past_epochs(TIME, TIME, TIME, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 5 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 9 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 10 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 11 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 19 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 2);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 20 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 21 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 3);
        assert!(calc_user_past_epochs(TIME, TIME, TIME + 30 * DAY, 10 * DAY) == vec, 1);

        // User starts later in first epoch
        let vec: vector<u64> = vector::empty();
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 5 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 10 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 15 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 2);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 20 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 25 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 3);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 30 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 35 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 4);
        assert!(calc_user_past_epochs(TIME, TIME + 5 * DAY, TIME + 40 * DAY, 10 * DAY) == vec, 1);
        let vec: vector<u64> = vector::empty();
        assert!(calc_user_past_epochs(TIME, TIME + 9 * DAY, TIME + 10 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 2);
        assert!(calc_user_past_epochs(TIME, TIME + 9 * DAY, TIME + 20 * DAY, 10 * DAY) == vec, 1);

        // User starts in next (4) epoch
        let vec: vector<u64> = vector::empty();
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 30 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 35 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 4);
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 40 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 45 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 5);
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 50 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 55 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 6);
        assert!(calc_user_past_epochs(TIME, TIME + 30 * DAY, TIME + 60 * DAY, 10 * DAY) == vec, 1);

        // User starts in half of epoch (4)
        let vec: vector<u64> = vector::empty();
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 35 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 40 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 45 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 5);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 50 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 55 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 6);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 60 * DAY, 10 * DAY) == vec, 1);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 65 * DAY, 10 * DAY) == vec, 1);
        vector::push_back(&mut vec, 7);
        assert!(calc_user_past_epochs(TIME, TIME + 35 * DAY, TIME + 70 * DAY, 10 * DAY) == vec, 1);
    }

    #[test]
    public fun calc_user_reward_amount_zero_epochs_test() {
        let amount = 10000000000;
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 5 * DAY) == 0, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 5 * DAY) == 0, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 10 * DAY) == 0, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 15 * DAY) == 0, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 10 * DAY, TIME + 10 * DAY) == 0, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 15 * DAY, TIME + 15 * DAY) == 0, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 15 * DAY, TIME + 20 * DAY) == 0, 1);
    }

    #[test]
    public fun calc_user_reward_amount_test() {
        let amount = 1000000000; // 10.0
        // User rewards before epoch
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 5 * DAY) == 0, 1);
        // User rewards for first epoch
        assert!(calc_user_reward_amount(DAY, TIME, 10, 1, 5, amount, TIME, TIME + DAY) == 273972, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 10 * DAY) == 2743105, 1); // 0.02743105
        // User stake in half epoch
        let amount = 1000000000;
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 15 * DAY) == 12397391, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 83, 1, 5, amount, TIME, TIME + 15 * DAY) == 22973835, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 99, 1, 5, amount, TIME, TIME + 15 * DAY) == 27456745, 1);
        // Amounts less than 1 GGWP
        let amount = 50000000; // 0.5
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 1233402, 1);
        let amount = 80; // 0.000008
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 1, 1);
        let amount = 800; // 0.00008
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 19, 1);
        // User stake in next epoch
        let amount = 1900000000;
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY) == 46869294, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 30 * DAY) == 69926986, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 40 * DAY) == 92712373, 1);
        // User stake in half next epoch
        let amount = 129950000000;
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 25 * DAY) == 3205613072, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 35 * DAY) == 4782637807, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 45 * DAY) == 6341038356, 1);
        // Check min apr limit
        let amount = 500000000;
        assert!(calc_user_reward_amount(10 * DAY, TIME, 6, 1, 5, amount, TIME, TIME + 50 * DAY) == 3574100, 1);
        // Big amounts check overflow
        let amount = 10000000000000; // 100000.0
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 100 * DAY) == 1172799009396, 1);
        assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 1000 * DAY) == 4355105852568, 1);
    }
}
