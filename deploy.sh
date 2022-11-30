REGENERATE_KEYS="OFF" # ON/OFF
AIRDROP="OFF" # ON/OFF
PUBLISH="OFF" # ON/OFF
FAUCET_INIT="OFF" # ON/OFF
STAKING_INIT="OFF" # ON/OFF
CORE_INIT="OFF" # ON/OFF
GAMES_INIT="OFF" # ON/OFF
FUNDS_REGISTER="OFF" # ON/OFF
DISTRIBUTION_INIT="OFF" # ON/OFF

if [[ $REGENERATE_KEYS == "ON" ]]
then
    echo "Regenarate keys..."
    aptos init --network devnet --profile core --assume-yes
    aptos init --network devnet --profile faucet --assume-yes
    aptos init --network devnet --profile coin --assume-yes
    aptos init --network devnet --profile staking --assume-yes
    aptos init --network devnet --profile games --assume-yes
    aptos init --network devnet --profile distribution --assume-yes
    aptos init --network devnet --profile company_fund --assume-yes
    aptos init --network devnet --profile team_fund --assume-yes
fi

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

parse_yaml .aptos/config.yaml > keys.sh
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

ACCUMULATIVE_FUND="0x$profiles_distribution_account"
DISTRIBUTION_INITIALIZE="$ACCUMULATIVE_FUND::distribution::initialize"

PLAY_TO_EARN_FUND="0x$profiles_games_account"
STAKING_FUND="0x$profiles_staking_account"
COMPANY_FUND="0x$profiles_company_fund_account"
TEAM_FUND="0x$profiles_team_fund_account"

if [[ $AIRDROP == "ON" ]]
then
    echo "Airdropping..."
    aptos account fund-with-faucet --account coin
    aptos account fund-with-faucet --account faucet
    aptos account fund-with-faucet --account staking
    aptos account fund-with-faucet --account core
    aptos account fund-with-faucet --account distribution
    aptos account fund-with-faucet --account games
    aptos account fund-with-faucet --account company_fund
    aptos account fund-with-faucet --account team_fund
fi

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

    # TODO: publish games sc
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
    ARGS="u64:500000000000 u64:5"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes
    ARGS="u64:1000000000000 u64:10"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes
    ARGS="u64:1500000000000 u64:15"
    aptos move run --function-id $GGWP_CORE_ADD_REWARD_TABLE_ROW --args $ARGS --profile core --assume-yes

    # TODO: set up burners games sc
fi

# if [[ $GAMES_INIT == "ON" ]]
# then
#     # TODO: games init
# fi

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
