#[test_only]
module staking::staking_test {
    use std::vector;
    use staking::staking::{
        get_epoch_by_time, get_apr_by_epoch, calc_user_past_epochs,
        calc_user_reward_amount
    };

    const TIME: u64 = 1660032700;
    const DAY: u64 = 24 * 60 * 60;

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

    // TODO: uncomment
    // #[test]
    // public fun calc_user_reward_amount_zero_epochs_test() {
    //     let amount = 10000000000;
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 5 * DAY) == 0, 1);
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 5 * DAY) == 0, 1);
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 10 * DAY) == 0, 1);
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 5 * DAY, TIME + 15 * DAY) == 0, 1);
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 10 * DAY, TIME + 10 * DAY) == 0, 1);
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 15 * DAY, TIME + 15 * DAY) == 0, 1);
    //     assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME + 15 * DAY, TIME + 20 * DAY) == 0, 1);
    // }

    #[test]
    public fun calc_user_reward_amount_test() {
        let amount = 1000000000;
        // User rewards for first epoch
        assert!(calc_user_reward_amount(10 * DAY, TIME, 10, 1, 5, amount, TIME, TIME + 10 * DAY) == 2743106, 1); // 0.02743106

        // // User stake in half epoch
        // let amount = 10_000_000_000;

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 15 * DAY),
        //     Ok(123973918)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 83, 1, 5, amount, TIME, TIME + 15 * DAY),
        //     Ok(229738355)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 99, 1, 5, amount, TIME, TIME + 15 * DAY),
        //     Ok(274567462)
        // );

        // // Amounts less than 1 GGWP
        // let amount = 500_000_000; // 0.5

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY),
        //     Ok(12334025)
        // );

        // let amount = 800; // 0.0000008

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY),
        //     Ok(19)
        // );

        // // User stake in next epoch
        // let amount = 19_000_000_000;

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 20 * DAY),
        //     Ok(468692977)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 30 * DAY),
        //     Ok(699269917)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 40 * DAY),
        //     Ok(927123806)
        // );

        // // User stake in half next epoch
        // let amount = 1299_500_000_000;

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 25 * DAY),
        //     Ok(32056132852)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 35 * DAY),
        //     Ok(47826381988)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 45 * DAY),
        //     Ok(63410388776)
        // );

        // // Check min apr limit
        // let amount = 5_000_000_000;

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 6, 1, 5, amount, TIME, TIME + 50 * DAY),
        //     Ok(35741023)
        // );

        // // Big amounts check overflow
        // println!("-----");
        // let amount = 100000_000_000_000;

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 100 * DAY),
        //     Ok(11727991191434)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 1000 * DAY),
        //     Ok(43551067839644)
        // );

        // assert!(calc_user_reward_amount(10 * DAY, TIME, 45, 1, 5, amount, TIME, TIME + 100000 * DAY),
        //     Ok(18446644073709551615)
        // );
    }
}
