module games::fighting_tests {
    use games::fighting;

    #[test]
    public entry fun calc_reward_amount_test() {
        // If daily gpass reward bigger than reward
        assert!(fighting::calc_reward_amount(0, 10, 2, 100, 10) == 0, 1);
        assert!(fighting::calc_reward_amount(0, 0, 2, 100, 10) == 0, 1);
        // 0.00025 GGWP
        assert!(fighting::calc_reward_amount(1000000000, 2, 20000, 100, 10) == 25000, 1);
        // 6.150 GGWP
        assert!(fighting::calc_reward_amount(12300000000, 10, 2, 100, 10) == 615000000, 1);
        // If daily gpass reward less than reward
        // 0.5 GGWP: 5/10
        assert!(fighting::calc_reward_amount(12300000000, 10, 2, 5, 10) == 50000000, 1);
    }
}
