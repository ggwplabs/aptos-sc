module faucet::faucet {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_framework::coin::{Self, Coin};

    /// When Faucet already exists on account.
    const ERR_FAUCET_EXISTS: u64 = 0x1001;
    /// When Faucet doesn't exists on account.
    const ERR_FAUCET_NOT_EXISTS: u64 = 0x1002;
    /// When user already got coins and currently restricted to request more funds.
    const ERR_RESTRICTED: u64 = 0x1003;

    /// Faucet data.
    struct Faucet<phantom CoinType> has key {
        /// Faucet balance.
        deposit: Coin<CoinType>,
        /// How much coins should be sent to user per request.
        per_request: u64,
        /// Period between requests to faucet in seconds.
        period: u64,
    }

    /// If user has this resource on his account - he's not able to get more funds if (current_timestamp < since + period).
    struct Restricted<phantom Faucet> has key {
        since: u64,
    }

    /// Creates new faucet on `faucet_account` address for coin `CoinType`.
    public entry fun create_faucet<CoinType>(faucet_account: &signer, amount_to_deposit: u64, per_request: u64, period: u64) {
        let faucet_addr = signer::address_of(faucet_account);
        let deposit = coin::withdraw<CoinType>(faucet_account, amount_to_deposit);

        assert!(!exists<Faucet<CoinType>>(faucet_addr), ERR_FAUCET_EXISTS);

        move_to(faucet_account, Faucet<CoinType> {
            deposit,
            per_request,
            period
        });
    }

    /// Change settings of faucet `CoinType`.
    public entry fun change_settings<CoinType>(faucet_account: &signer, per_request: u64, period: u64) acquires Faucet {
        let faucer_addr = signer::address_of(faucet_account);
        assert!(exists<Faucet<CoinType>>(faucer_addr), ERR_FAUCET_NOT_EXISTS);

        let faucet = borrow_global_mut<Faucet<CoinType>>(faucer_addr);
        faucet.per_request = per_request;
        faucet.period = period;
    }

    /// Deposits coins `CoinType` to faucet on `faucet` address, withdrawing funds from user balance.
    public entry fun deposit<CoinType>(account: &signer, faucet_addr: address, amount: u64) acquires Faucet {
        let coins = coin::withdraw<CoinType>(account, amount);
        assert!(exists<Faucet<CoinType>>(faucet_addr), ERR_FAUCET_NOT_EXISTS);

        let faucet = borrow_global_mut<Faucet<CoinType>>(faucet_addr);
        coin::merge(&mut faucet.deposit, coins);
    }

    /// Deposits coins `CoinType` from faucet on user's account.
    public entry fun request<CoinType>(user: &signer, faucet_addr: address) acquires Faucet, Restricted {
        let user_addr = signer::address_of(user);

        assert!(exists<Faucet<CoinType>>(faucet_addr), ERR_FAUCET_NOT_EXISTS);

        if (!coin::is_account_registered<CoinType>(user_addr)) {
            coin::register<CoinType>(user);
        };

        let faucet = borrow_global_mut<Faucet<CoinType>>(faucet_addr);
        let coins_to_user = coin::extract(&mut faucet.deposit, faucet.per_request);

        let now = timestamp::now_seconds();
        if (exists<Restricted<CoinType>>(user_addr)) {
            let restricted = borrow_global_mut<Restricted<CoinType>>(user_addr);
            assert!(restricted.since + faucet.period <= now, ERR_RESTRICTED);
            restricted.since = now;
        } else {
            move_to(user, Restricted<CoinType> {
                since: now,
            });
        };

        coin::deposit(user_addr, coins_to_user);
    }

    // Test
    #[test_only]
    struct TestCoin has store {}
    #[test_only]
    struct TestCoinCaps has key {
        mint_cap: coin::MintCapability<TestCoin>,
        burn_cap: coin::BurnCapability<TestCoin>,
    }

    #[test(faucet_signer = @faucet)]
    public entry fun test_update_settings(faucet_signer: &signer) acquires Faucet {
        use std::string::utf8;
        use aptos_framework::account::create_account_for_test;

        create_account_for_test(signer::address_of(faucet_signer));
        let faucet_addr = signer::address_of(faucet_signer);

        let (burn, freeze, mint) = coin::initialize<TestCoin>(
            faucet_signer,
            utf8(b"TestCoin"),
            utf8(b"TC"),
            8,
            true
        );
        coin::destroy_freeze_cap(freeze);

        let amount = 1000000u64 * 100000000u64;
        let per_request = 1000u64 * 1000000u64;
        let period = 3000u64;

        let coins_minted = coin::mint(amount, &mint);
        coin::register<TestCoin>(faucet_signer);
        coin::deposit(faucet_addr, coins_minted);
        create_faucet<TestCoin>(faucet_signer, amount / 2, per_request, period);

        // Update settings
        let new_per_request = 20u64 * 100000000u64;
        let new_period = 5000u64;
        change_settings<TestCoin>(faucet_signer, new_per_request, new_period);
        let to_check = borrow_global<Faucet<TestCoin>>(faucet_addr);
        assert!(to_check.period == new_period, 1);
        assert!(to_check.per_request == new_per_request, 2);

        move_to(faucet_signer, TestCoinCaps {
            mint_cap: mint,
            burn_cap: burn,
        });
    }
}
