REGENERATE_KEYS="OFF"
SCRIPT="OFF"
TESTING_SCRIPT="OFF"

AIRDROP_DEVNET="OFF"
PUBLISH="OFF"

FAUCET_INIT="OFF"
CORE_INIT="OFF"
GATEWAY_INIT="OFF"

FUNDS_REGISTER="OFF"
DISTRIBUTION_INIT="OFF"

NFT_MARKET_INIT="OFF"

config_path=".aptos/config.yaml"

if [[ $REGENERATE_KEYS == "ON" ]]
then
    echo "Regenarate keys..."
    rm $config_path
    yes "" | aptos init --network testnet --assume-yes
    yes "" | aptos init --network testnet --profile core --assume-yes
    yes "" | aptos init --network testnet --profile faucet --assume-yes
    yes "" | aptos init --network testnet --profile coin --assume-yes
    yes "" | aptos init --network testnet --profile distribution --assume-yes
    yes "" | aptos init --network testnet --profile company_fund --assume-yes
    yes "" | aptos init --network testnet --profile team_fund --assume-yes
    yes "" | aptos init --network testnet --profile gateway --assume-yes
    yes "" | aptos init --network testnet --profile fighting_contributor --assume-yes
    yes "" | aptos init --network testnet --profile player --assume-yes
    yes "" | aptos init --network testnet --profile nft_market --assume-yes
fi

source utils.sh
parse_yaml $config_path > keys.sh
source keys.sh

FAUCET="0x$profiles_faucet_account"
FAUCET_CREATE="$FAUCET::faucet::create_faucet"

GGWP="0x$profiles_coin_account"
GGWP_COIN_STRUCT="$GGWP::ggwp::GGWPCoin"
GGWP_REGISTER="$GGWP::ggwp::register"
GGWP_MINT_TO="$GGWP::ggwp::mint_to"

GGWP_CORE="0x$profiles_core_account"
GGWP_CORE_INITIALIZE="$GGWP_CORE::gpass::initialize"
GGWP_CORE_ADD_REWARD_TABLE_ROW="$GGWP_CORE::gpass::add_reward_table_row"
GGWP_CORE_CLEANUP_REWARD_TABLE="$GGWP_CORE::gpass::cleanup_reward_table"
GGWP_CORE_ADD_BURNER="$GGWP_CORE::gpass::add_burner"

ACCUMULATIVE_FUND="0x$profiles_distribution_account"
DISTRIBUTION_INITIALIZE="$ACCUMULATIVE_FUND::distribution::initialize"

GATEWAY="0x$profiles_gateway_account"
GATEWAY_INITIALIZE="$GATEWAY::gateway::initialize"
GATEWAY_GAMES_REWARD_FUND_DEPOSIT="$GATEWAY::gateway::games_reward_fund_deposit"

NFT_MARKET="0x$profiles_nft_market_account"
NFT_MARKET_INITIALIZE="$NFT_MARKET::nft_market::initialize"

GAMES_REWARD_FUND="0x$profiles_gateway_account"
COMPANY_FUND="0x$profiles_company_fund_account"
TEAM_FUND="0x$profiles_team_fund_account"

FIGHTING_CONTRIBUTOR="0x$profiles_fighting_contributor_account"

TESTING="0x$profiles_testing_account"

# Update Move.toml files
update_ggwp_core "$GGWP_CORE" "core/Move.toml"
update_distribution "$ACCUMULATIVE_FUND" "distribution/Move.toml"
update_faucet "$FAUCET" "faucet/Move.toml"
update_ggwp_coin "$GGWP" "ggwp_coin/Move.toml"
update_gateway "$GATEWAY" "gateway/Move.toml"
update_nft_market "$NFT_MARKET" "nft_market/Move.toml"
echo "Keys in Move.toml updated"

if [[ $TESTING_SCRIPT == "ON" ]]
then
    echo "testing contract call"
    # TESTING_ADD="$TESTING::testing::add"
    # ARGS="u64:1 u64:100"
    # aptos move run --function-id $TESTING_ADD --args $ARGS --profile testing --assume-yes

    # TESTING_ADD_HISTORY="$TESTING::testing::add_history"
    # ARGS="u64:1 u64:225"
    # aptos move run --function-id $TESTING_ADD_HISTORY --args $ARGS --profile testing --assume-yes

    # TESTING_UPDATE="$TESTING::testing::update"
    # ARGS="u64:99 u64:555"
    # aptos move run --function-id $TESTING_UPDATE --args $ARGS --profile testing --assume-yes

    # TESTING_PROCESS_HISTORY="$TESTING::testing::process_history"
    #     rm: u64, ins: u64, upd: u64, val: u64
    # ARGS="u64:3 u64:350 u64:50 u64:555"
    # aptos move run --function-id $TESTING_PROCESS_HISTORY --args $ARGS --profile testing --assume-yes
fi

# Place for another script actions
if [[ $SCRIPT == "ON" ]]
then
    # Sctiprt
    echo "Script"

    # GATEWAY_GET_PLAYER_REWARD="$GATEWAY::gateway::get_player_reward"
    # ARGS="address:$GATEWAY"
    # aptos move run --function-id $GATEWAY_GET_PLAYER_REWARD --args $ARGS --profile player --assume-yes

    # DISTRIBUTION_UPDATE_FUNDS="$ACCUMULATIVE_FUND::distribution::update_funds"
    # games_reward_fund="$GAMES_REWARD_FUND"
    # company_fund="$COMPANY_FUND"
    # team_fund="$TEAM_FUND"
    # ARGS="address:$games_reward_fund address:$company_fund address:$team_fund"
    # echo "$ARGS"
    # aptos move run --function-id $DISTRIBUTION_UPDATE_FUNDS --args $ARGS --profile distribution --assume-yes

    # aptos move run --function-id $GGWP_REGISTER --profile fighting_contributor --assume-yes
    # ARGS="u64:2728811381400 address:$FIGHTING_CONTRIBUTOR"
    # aptos move run --function-id $GGWP_MINT_TO --args $ARGS --profile coin --assume-yes

    # GATEWAY_DEPOSIT="$GATEWAY::gateway::games_reward_fund_deposit"
    # ARGS="address:$GATEWAY u64:2728811381400"
    # aptos move run --function-id $GATEWAY_DEPOSIT --args $ARGS --profile fighting_contributor --assume-yes

    # GATEWAY_SIGN_UP="$GATEWAY::gateway::sign_up"
    # ARGS="address:$GATEWAY string:rough_rules u64:1"
    # aptos move run --function-id $GATEWAY_SIGN_UP --args $ARGS --profile fighting_contributor --assume-yes

    # GATEWAY_START_GAME="$GATEWAY::gateway::start_game"
    # ARGS="address:$GATEWAY address:$GGWP_CORE address:$FIGHTING_CONTRIBUTOR u64:1"
    # aptos move run --function-id $GATEWAY_START_GAME --args $ARGS --profile player --assume-yes

    # GATEWAY_FINALIZE_GAME="$GATEWAY::gateway::finalize_game"
    # ARGS="address:$GATEWAY address:$FIGHTING_CONTRIBUTOR u64:1 u8:1"
    # aptos move run --function-id $GATEWAY_FINALIZE_GAME --args $ARGS --profile player --assume-yes

    echo "Script end"
fi

if [[ $AIRDROP_DEVNET == "ON" ]]
then
    echo "Airdropping..."
    for ((i=0; i < 8; i++))
    do
        aptos account fund-with-faucet --account coin --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account faucet --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account core --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account distribution --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account company_fund --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account team_fund --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account fighting_contributor --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account gateway --faucet-url https://faucet.devnet.aptoslabs.com
    done
fi

echo "------------------------------"
echo "Initial balances:"

# coin_initial_balance=$(get_balance coin)
# echo "coin: $coin_initial_balance"

# faucet_initial_balance=$(get_balance faucet)
# echo "faucet: $faucet_initial_balance"

# core_initial_balance=$(get_balance core)
# echo "core: $core_initial_balance"

# distribution_initial_balance=$(get_balance distribution)
# echo "distribution: $distribution_initial_balance"

# gateway_initial_balance=$(get_balance gateway)
# echo "gateway: $gateway_initial_balance"

# company_fund_initial_balance=$(get_balance company_fund)
# echo "company_fund: $company_fund_initial_balance"

# team_fund_initial_balance=$(get_balance team_fund)
# echo "team_fund: $team_fund_initial_balance"
echo "------------------------------"

if [[ $PUBLISH == "ON" ]]
then
    echo "Deploy ggwp_coin.."
    aptos move publish --profile coin --package-dir ggwp_coin --bytecode-version 6 --assume-yes

    echo "Deploy faucet.."
    aptos move publish --profile faucet --package-dir faucet --bytecode-version 6 --assume-yes

    echo "Deploy ggwp_core.."
    aptos move publish --profile core --package-dir core --bytecode-version 6 --assume-yes

    echo "Deploy accumulative fund distribution.."
    aptos move publish --profile distribution --package-dir distribution --bytecode-version 6 --assume-yes

    echo "Deploy gateway sc.."
    aptos move publish --profile gateway --package-dir gateway --assume-yes --bytecode-version 6

    echo "Deploy nft market sc.."
    aptos move publish --profile nft_market --package-dir nft_market --assume-yes --bytecode-version 6
fi

if [[ $FAUCET_INIT == "ON" ]]
then
    # Register coin store for faucet
    echo "Register coin store for faucet"
    aptos move run --function-id $GGWP_REGISTER --profile faucet --assume-yes

    # Mint GGWP token to faucet account (1_000_000)
    echo "Mint GGWP tokens (1_000_000) to faucet account"
    ARGS="u64:100000000000000 address:$FAUCET"
    aptos move run --function-id $GGWP_MINT_TO --args $ARGS --profile coin --assume-yes

    # Initialize faucet
    echo "Initialize faucet"
    ARGS="u64:100000000000000 u64:500000000000 u64:300"
    aptos move run --function-id $FAUCET_CREATE --type-args $GGWP_COIN_STRUCT --args $ARGS --profile faucet --assume-yes
fi

if [[ $CORE_INIT == "ON" ]]
then
    # Initialize ggwp core
    echo "Initialize ggwp core (gpass, freezing)"
    accumulative_fund=$ACCUMULATIVE_FUND
    let burn_period=30*24*60*60
    let reward_period=1*24*60*60
    royalty=8
    unfreeze_royalty=15
    let unfreeze_lock_period=15*24*60*60
    ARGS="address:$accumulative_fund u64:$burn_period u64:$reward_period u8:$royalty u8:$unfreeze_royalty u64:$unfreeze_lock_period"
    aptos move run --function-id $GGWP_CORE_INITIALIZE --args $ARGS --profile core --assume-yes

    # Set up reward table
    echo "Set up reward table..."
    ARGS="u64:100000000000 u64:5"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes
    ARGS="u64:200000000000 u64:10"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes
    ARGS="u64:300000000000 u64:15"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes
    ARGS="u64:400000000000 u64:20"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes
    ARGS="u64:480000000000 u64:25"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes

    # Set burners
    echo "Add gateway sc as burner"
    ARGS="address:$GATEWAY"
    aptos move run --function-id $GGWP_CORE_ADD_BURNER --args $ARGS --profile core --assume-yes
fi


if [[ $FUNDS_REGISTER == "ON" ]]
then
    echo "Register accumulative fund"
    aptos move run --function-id $GGWP_REGISTER --profile distribution --assume-yes
    echo "Register company fund"
    aptos move run --function-id $GGWP_REGISTER --profile company_fund --assume-yes
    echo "Register team fund"
    aptos move run --function-id $GGWP_REGISTER --profile team_fund --assume-yes
fi

if [[ $DISTRIBUTION_INIT == "ON" ]]
then
    echo "Initialize distribution"
    games_reward_fund="$GAMES_REWARD_FUND"
    games_reward_fund_share=45
    company_fund="$COMPANY_FUND"
    company_fund_share=5
    team_fund="$TEAM_FUND"
    team_fund_share=10
    ARGS="address:$games_reward_fund u8:$games_reward_fund_share address:$company_fund u8:$company_fund_share address:$team_fund u8:$team_fund_share"
    aptos move run --function-id $DISTRIBUTION_INITIALIZE --args $ARGS --profile distribution --assume-yes
fi

if [[ $GATEWAY_INIT == "ON" ]]
then
    echo "Publish gateway"
    aptos move publish --profile gateway --package-dir gateway --assume-yes --bytecode-version 6

    echo "Initialize gateway"
    accumulative_fund=$ACCUMULATIVE_FUND
    reward_coefficient=20000
    royalty=8
    time_frame=10800 # 3 * 60 * 60
    burn_period=2592000 # 30 * 24 * 60 * 60
    ARGS="address:$accumulative_fund u64:$reward_coefficient u8:$royalty u64:$time_frame u64:$burn_period"
    aptos move run --function-id $GATEWAY_INITIALIZE --args $ARGS --profile gateway --assume-yes

    echo "Mint GGWP tokens (300_000_000) to games reward fund (through faucet)"
    ARGS="u64:30000000000000000 address:$FAUCET"
    aptos move run --function-id $GGWP_MINT_TO --args $ARGS --profile coin --assume-yes

    echo "Deposit GGWP into games reward fund"
    ARGS="address:$GATEWAY u64:30000000000000000"
    aptos move run --function-id $GATEWAY_GAMES_REWARD_FUND_DEPOSIT --args $ARGS --profile faucet --assume-yes
fi

if [[ $NFT_MARKET_INIT == "ON" ]]
then
    echo "Initialize nft market"
    accumulative_fund=$ACCUMULATIVE_FUND
    royalty=8
    seed="market"
    ARGS="address:$accumulative_fund u8:$royalty string:$seed"
    aptos move run --function-id $NFT_MARKET_INITIALIZE --args $ARGS --profile nft_market --assume-yes
fi
