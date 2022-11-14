/// Module for GPass tickets.
module ggwp_core::GPass {
    use std::signer;
    use std::vector;
    use aptos_framework::timestamp;

    const ERR_NOT_INITIALIZED: u64 = 0x1001;
    const ERR_ALREADY_INITIALIZED: u64 = 0x1002;
    const ERR_INVALID_BURN_PERIOD: u64 = 0x1003;
    const ERR_WALLET_NOT_INITIALIZED: u64 = 0x1004;
    const ERR_INVALID_AMOUNT: u64 = 0x1005;
    const ERR_INVALID_MINT_AUTH: u64 = 0x1006;
    const ERR_INVALID_BURN_AUTH: u64 = 0x1007;

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

    /// Initialize gpass info with params.
    public entry fun initialize(gpass_account: &signer, burn_period: u64) {
        let gpass_addr = signer::address_of(gpass_account);
        assert!(!exists<GpassInfo>(gpass_addr), ERR_ALREADY_INITIALIZED);

        assert!(burn_period != 0, ERR_INVALID_BURN_PERIOD);

        let gpass_info = GpassInfo {
            burn_period: burn_period,
            total_amount: 0,
            burners: vector::empty(),
        };
        move_to(gpass_account, gpass_info);
    }

    public entry fun add_burner(gpass_account: &signer, burner: address) acquires GpassInfo {
        let gpass_addr = signer::address_of(gpass_account);
        assert!(exists<GpassInfo>(gpass_addr), ERR_NOT_INITIALIZED);

        let gpass_info = borrow_global_mut<GpassInfo>(gpass_addr);
        vector::push_back(&mut gpass_info.burners, burner);
    }

    /// Update burn period.
    public entry fun update_burn_period(gpass_account: &signer, burn_period: u64) acquires GpassInfo {
        let gpass_addr = signer::address_of(gpass_account);
        assert!(exists<GpassInfo>(gpass_addr), ERR_NOT_INITIALIZED);

        let gpass_info = borrow_global_mut<GpassInfo>(gpass_addr);
        gpass_info.burn_period = burn_period;
    }

    /// User creates new wallet.
    public entry fun create_wallet(user_account: &signer) {
        let user_addr = signer::address_of(user_account);
        assert!(!exists<Wallet>(user_addr), ERR_ALREADY_INITIALIZED);

        let now = timestamp::now_seconds();
        let wallet = Wallet {
            amount: 0,
            last_burned: now,
        };
        move_to(user_account, wallet);
    }

    /// Mint the amount of GPASS to user wallet. Available only for minters.
    /// There is trying to burn overdues before minting.
    public entry fun mint_to(minter: &signer, gpass_info: address, to: address, amount: u64) acquires Wallet, GpassInfo {
        assert!(exists<Wallet>(to), ERR_WALLET_NOT_INITIALIZED);
        assert!(amount != 0, ERR_INVALID_AMOUNT);
        // Note: minter is the ggwp_core contract.
        assert!(exists<GpassInfo>(signer::address_of(minter)), ERR_INVALID_MINT_AUTH);

        let gpass_info = borrow_global_mut<GpassInfo>(gpass_info);
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
    public entry fun burn(burner: &signer, gpass_info: address, from: address, amount: u64) acquires Wallet, GpassInfo {
        assert!(exists<Wallet>(from), ERR_WALLET_NOT_INITIALIZED);
        assert!(amount != 0, ERR_INVALID_AMOUNT);
        assert!(exists<GpassInfo>(gpass_info), ERR_NOT_INITIALIZED);

        let gpass_info = borrow_global_mut<GpassInfo>(gpass_info);
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

    // Getters.
    public fun get_burn_period(gpass_info: address): u64 acquires GpassInfo {
        borrow_global<GpassInfo>(gpass_info).burn_period
    }

    public fun get_total_amount(gpass_info: address): u64 acquires GpassInfo {
        borrow_global<GpassInfo>(gpass_info).total_amount
    }

    public fun get_balance(wallet: address): u64 acquires Wallet {
        borrow_global<Wallet>(wallet).amount
    }

    public fun get_last_burned(wallet: address): u64 acquires Wallet {
        borrow_global<Wallet>(wallet).last_burned
    }
}
