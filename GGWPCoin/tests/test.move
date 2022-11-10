#[test_only]
module coin::GGWP_tests {
    use std::signer::{address_of};
    use aptos_framework::coin;
    use aptos_framework::account;

    use coin::GGWP::GGWPCoin;
    use coin::GGWP;

    #[test(ggwp_coin = @coin)]
    fun intialize(ggwp_coin: signer) {
        GGWP::set_up_test(&ggwp_coin);
    }

    #[test(ggwp_coin = @coin)]
    fun mint_to(ggwp_coin: signer) {
        let user = account::create_account_for_test(@0x112233445566);
        GGWP::set_up_test(&ggwp_coin);

        coin::register<GGWPCoin>(&user);
        assert!(coin::balance<GGWPCoin>(address_of(&user)) == 0, 1);

        let amount = 100 ^ 8;
        GGWP::mint_to(&ggwp_coin, amount, address_of(&user));

        assert!(coin::balance<GGWPCoin>(address_of(&user)) == amount, 1);
    }

    #[test(ggwp_coin = @coin)]
    #[expected_failure]
    fun mint_admin_only(ggwp_coin: signer) {
        let user = account::create_account_for_test(@0x11221);
        let fake_signer = account::create_account_for_test(@0x11222);
        GGWP::set_up_test(&ggwp_coin);
        coin::register<GGWPCoin>(&user);

        GGWP::mint_to(&fake_signer, 1, address_of(&user));
    }
}
