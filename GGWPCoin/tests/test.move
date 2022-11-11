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

        GGWP::register(&user);
        assert!(coin::balance<GGWPCoin>(address_of(&user)) == 0, 1);

        let amount = 10 * 100000000;
        GGWP::mint_to(&ggwp_coin, amount, address_of(&user));

        assert!(coin::balance<GGWPCoin>(address_of(&user)) == 1000000000, 1);
    }

    #[test(ggwp_coin = @coin)]
    #[expected_failure]
    fun mint_admin_only(ggwp_coin: signer) {
        let user = account::create_account_for_test(@0x11221);
        let fake_signer = account::create_account_for_test(@0x11222);
        GGWP::set_up_test(&ggwp_coin);
        GGWP::register(&user);

        GGWP::mint_to(&fake_signer, 1, address_of(&user));
    }

    #[test(ggwp_coin = @coin)]
    fun transfer(ggwp_coin: signer) {
        let user1 = account::create_account_for_test(@0x1);
        let user2 = account::create_account_for_test(@0x2);
        GGWP::set_up_test(&ggwp_coin);

        GGWP::register(&user1);
        assert!(coin::balance<GGWPCoin>(address_of(&user1)) == 0, 1);
        GGWP::register(&user2);
        assert!(coin::balance<GGWPCoin>(address_of(&user2)) == 0, 1);

        let amount = 10 * 100000000;
        GGWP::mint_to(&ggwp_coin, amount, address_of(&user1));
        assert!(coin::balance<GGWPCoin>(address_of(&user1)) == amount, 1);

        coin::transfer<GGWPCoin>(&user1, address_of(&user2), 100);

        assert!(coin::balance<GGWPCoin>(address_of(&user1)) == amount - 100, 1);
    }
}
