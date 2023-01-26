REGENERATE_KEYS="OFF"
SCRIPT="OFF"

AIRDROP="OFF"
PUBLISH="OFF"

FAUCET_INIT="OFF"
STAKING_INIT="OFF"
CORE_INIT="OFF"
# FIGHTING_INIT="OFF"
GATEWAY_INIT="OFF"

FUNDS_REGISTER="OFF"
DISTRIBUTION_INIT="OFF"

config_path=".aptos/config.yaml"

if [[ $REGENERATE_KEYS == "ON" ]]
then
    echo "Regenarate keys..."
    rm $config_path
    yes "" | aptos init --network devnet --assume-yes
    yes "" | aptos init --network devnet --profile core --assume-yes
    yes "" | aptos init --network devnet --profile faucet --assume-yes
    yes "" | aptos init --network devnet --profile coin --assume-yes
    yes "" | aptos init --network devnet --profile staking --assume-yes
    # yes "" | aptos init --network devnet --profile games --assume-yes
    yes "" | aptos init --network devnet --profile distribution --assume-yes
    yes "" | aptos init --network devnet --profile company_fund --assume-yes
    yes "" | aptos init --network devnet --profile team_fund --assume-yes
    yes "" | aptos init --network devnet --profile gateway --assume-yes
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

STAKING="0x$profiles_staking_account"
STAKING_INITIALIZE="$STAKING::staking::initialize"

GGWP_CORE="0x$profiles_core_account"
GGWP_CORE_INITIALIZE="$GGWP_CORE::gpass::initialize"
GGWP_CORE_ADD_REWARD_TABLE_ROW="$GGWP_CORE::gpass::add_reward_table_row"
GGWP_CORE_CLEANUP_REWARD_TABLE="$GGWP_CORE::gpass::cleanup_reward_table"
GGWP_CORE_ADD_BURNER="$GGWP_CORE::gpass::add_burner"

ACCUMULATIVE_FUND="0x$profiles_distribution_account"
DISTRIBUTION_INITIALIZE="$ACCUMULATIVE_FUND::distribution::initialize"

#GAMES="0x$profiles_games_account"
#FIGHTING_INITIALIZE="$GAMES::fighting::initialize"

PLAY_TO_EARN_FUND="0x$profiles_games_account"
STAKING_FUND="0x$profiles_staking_account"
COMPANY_FUND="0x$profiles_company_fund_account"
TEAM_FUND="0x$profiles_team_fund_account"

# Update Move.toml files
update_ggwp_core "$GGWP_CORE" "core/Move.toml"
update_distribution "$ACCUMULATIVE_FUND" "distribution/Move.toml"
update_faucet "$FAUCET" "faucet/Move.toml"
#update_games "$GAMES" "games/Move.toml"
update_ggwp_coin "$GGWP" "ggwp_coin/Move.toml"
update_staking "$STAKING" "staking/Move.toml"
# TODO: update gateway

# Place for another script actions
if [[ $SCRIPT == "ON" ]]
then
   # Sctiprt
   echo "Script"
fi

if [[ $AIRDROP == "ON" ]]
then
    echo "Airdropping..."
    for ((i=0; i < 8; i++))
    do
        aptos account fund-with-faucet --account coin --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account faucet --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account staking --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account core --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account distribution --faucet-url https://faucet.devnet.aptoslabs.com
        #aptos account fund-with-faucet --account games --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account company_fund --faucet-url https://faucet.devnet.aptoslabs.com
        aptos account fund-with-faucet --account team_fund --faucet-url https://faucet.devnet.aptoslabs.com
    done
fi

echo "------------------------------"
echo "Initial balances:"

coin_initial_balance=$(get_balance coin)
echo "coin: $coin_initial_balance"

faucet_initial_balance=$(get_balance faucet)
echo "faucet: $faucet_initial_balance"

staking_initial_balance=$(get_balance staking)
echo "staking: $staking_initial_balance"

core_initial_balance=$(get_balance core)
echo "core: $core_initial_balance"

distribution_initial_balance=$(get_balance distribution)
echo "distribution: $distribution_initial_balance"

#games_initial_balance=$(get_balance games)
#echo "games: $games_initial_balance"

gateway_initial_balance$(get_balance gateway)
echo "gateway: $gateway_initial_balance"

company_fund_initial_balance=$(get_balance company_fund)
echo "company_fund: $company_fund_initial_balance"

team_fund_initial_balance=$(get_balance team_fund)
echo "team_fund: $team_fund_initial_balance"
echo "------------------------------"

if [[ $PUBLISH == "ON" ]]
then
    echo "Deploy ggwp_coin.."
    aptos move publish --profile coin --package-dir ggwp_coin --assume-yes

    echo "Deploy faucet.."
    aptos move publish --profile faucet --package-dir faucet --assume-yes

    echo "Deploy staking.."
    aptos move publish --profile staking --package-dir staking --assume-yes

    echo "Deploy ggwp_core.."
    aptos move publish --profile core --package-dir core --assume-yes

    echo "Deploy accumulative fund distribution.."
    aptos move publish --profile distribution --package-dir distribution --assume-yes

    # echo "Deploy games sc.."
    # aptos move publish --profile games --package-dir games --assume-yes

    echo "Deploy gateway sc.."
    aptos move publish --profile gateway --package-dir gateway --assume-yes
fi

echo "------------------------------"
echo "Publish cost:"

coin_balance=$(get_balance coin)
let coin_cost=$coin_initial_balance-$coin_balance
echo "coin: $coin_cost"

faucet_balance=$(get_balance faucet)
let faucet_cost=$faucet_initial_balance-$faucet_balance
echo "faucet: $faucet_cost"

staking_balance=$(get_balance staking)
let staking_cost=$staking_initial_balance-$staking_balance
echo "staking: $staking_cost"

core_balance=$(get_balance core)
let core_cost=$core_initial_balance-$core_balance
echo "core: $core_cost"

distribution_balance=$(get_balance distribution)
let distribution_cost=$distribution_initial_balance-$distribution_balance
echo "distribution: $distribution_cost"

# games_balance=$(get_balance games)
# let games_cost=$games_initial_balance-$games_balance
# echo "games: $games_cost"

gateway_balance=$(get_balance gateway)
let gateway_cost=$gateway_initial_balance-$gateway_balance
echo "games: $gateway_cost"
echo "------------------------------"

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

if [[ $STAKING_INIT == "ON" ]]
then
    # Initialize staking
    echo "Initialize staking"
    accumulative_fund=$ACCUMULATIVE_FUND
    let epoch_period=2*24*60*60
    min_stake_amount=300000000000
    let hold_period=1*24*60*60
    hold_royalty=15
    royalty=8
    apr_start=45
    apr_step=1
    apr_end=5
    ARGS="address:$accumulative_fund u64:$epoch_period u64:$min_stake_amount u64:$hold_period u8:$hold_royalty u8:$royalty u8:$apr_start u8:$apr_step u8:$apr_end"
    aptos move run --function-id $STAKING_INITIALIZE --args $ARGS --profile staking --assume-yes
fi

if [[ $CORE_INIT == "ON" ]]
then
    # Initialize ggwp core
    echo "Initialize ggwp core (gpass, freezing)"
    accumulative_fund=$ACCUMULATIVE_FUND
    let burn_period=1*24*60*60
    let reward_period=6*60*60
    royalty=8
    unfreeze_royalty=15
    let unfreeze_lock_period=1*24*60*60
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
    echo "Add games sc as burner"
    ARGS="address:$GAMES"
    aptos move run --function-id $GGWP_CORE_ADD_BURNER --args $ARGS --profile core --assume-yes
fi

if [[ $FIGHTING_INIT == "ON" ]]
then
    echo "Initialize fighting sc"
    accumulative_fund=$ACCUMULATIVE_FUND
    let afk_timeout=1*60*60
    reward_coefficient=20000
    gpass_daily_reward_coefficient=10
    royalty=8
    ARGS="address:$accumulative_fund u64:$afk_timeout u64:$reward_coefficient u64:$gpass_daily_reward_coefficient u8:$royalty"
    aptos move run --function-id $FIGHTING_INITIALIZE --args $ARGS --profile games --assume-yes
fi

if [[ $FUNDS_REGISTER == "ON" ]]
then
    echo "Register accumulative fund"
    aptos move run --function-id $GGWP_REGISTER --profile distribution --assume-yes
    echo "Register play_to_earn fund"
    aptos move run --function-id $GGWP_REGISTER --profile games --assume-yes
    echo "Register staking fund"
    aptos move run --function-id $GGWP_REGISTER --profile staking --assume-yes
    echo "Register company fund"
    aptos move run --function-id $GGWP_REGISTER --profile company_fund --assume-yes
    echo "Register team fund"
    aptos move run --function-id $GGWP_REGISTER --profile team_fund --assume-yes
fi

if [[ $DISTRIBUTION_INIT == "ON" ]]
then
    echo "Initialize distribution"
    play_to_earn_fund="$PLAY_TO_EARN_FUND"
    play_to_earn_fund_share=45
    staking_fund="$STAKING_FUND"
    staking_fund_share=40
    company_fund="$COMPANY_FUND"
    company_fund_share=5
    team_fund="$TEAM_FUND"
    team_fund_share=10
    ARGS="address:$play_to_earn_fund u8:$play_to_earn_fund_share address:$staking_fund u8:$staking_fund_share address:$company_fund u8:$company_fund_share address:$team_fund u8:$team_fund_share"
    aptos move run --function-id $DISTRIBUTION_INITIALIZE --args $ARGS --profile distribution --assume-yes
fi

# TODO: gateway init

echo "------------------------------"
echo "Publish and initialize cost:"

coin_balance=$(get_balance coin)
let coin_cost=$coin_initial_balance-$coin_balance
echo "coin: $coin_cost"

faucet_balance=$(get_balance faucet)
let faucet_cost=$faucet_initial_balance-$faucet_balance
echo "faucet: $faucet_cost"

staking_balance=$(get_balance staking)
let staking_cost=$staking_initial_balance-$staking_balance
echo "staking: $staking_cost"

core_balance=$(get_balance core)
let core_cost=$core_initial_balance-$core_balance
echo "core: $core_cost"

distribution_balance=$(get_balance distribution)
let distribution_cost=$distribution_initial_balance-$distribution_balance
echo "distribution: $distribution_cost"

# games_balance=$(get_balance games)
# let games_cost=$games_initial_balance-$games_balance
# echo "games: $games_cost"

gateway_balance=$(get_balance games)
let gateway_cost=$gateway_initial_balance-$gateway_balance
echo "gateway: $gateway_cost"

company_fund_balance=$(get_balance company_fund)
let company_fund_cost=$company_fund_initial_balance-$company_fund_balance
echo "company_fund: $company_fund_cost"

team_fund_balance=$(get_balance team_fund)
let team_fund_cost=$team_fund_initial_balance-$team_fund_balance
echo "team_fund: $team_fund_cost"
echo "------------------------------"
