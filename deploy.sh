AIRDROP="OFF" # ON/OFF
PUBLISH="OFF" # ON/OFF
FAUCET_INIT="OFF" # ON/OFF
STAKING_INIT="OFF" # ON/OFF
CORE_INIT="ON" # ON/OFF

FAUCET="0xf1a9e4828f80ac6c7c64590a450fca0763f30f5dac6883e2647ec52e55897bd6"
FAUCET_CREATE="$FAUCET::faucet::create_faucet"

GGWP="0x57de268d237c952d9598180e90c751f1d5831358bf644d8750f455310961d86f"
GGWP_COIN_STRUCT="$GGWP::ggwp::GGWPCoin"
GGWP_REGISTER="$GGWP::ggwp::register"
GGWP_MINT_TO="$GGWP::ggwp::mint_to"

STAKING="0x1f19ab535bfa7a447c171607ab704c7aae226826502fdbe69d82a7a812ddbb51"
STAKING_INITIALIZE="$STAKING::staking::initialize"

GGWP_CORE="0x95cb32b5f2f352617b6a84cd6e33e43d84e96b45a70fe6832ee88822aefb2e9c"
GGWP_CORE_INITIALIZE="$GGWP_CORE::gpass::initialize"
GGWP_CORE_ADD_REWARD_TABLE_ROW="$GGWP_CORE::gpass::add_reward_table_row"

# accumualative fund
ACCUMULATIVE_FUND="0x265a3274fadb17284cef3887f6779741ede442f5e5ab123c1cf63253c73f0686"

if [[ $AIRDROP == "ON" ]]
then
    echo "Airdropping..."
    aptos account fund-with-faucet --account coin
    aptos account fund-with-faucet --account faucet
    aptos account fund-with-faucet --account staking
    aptos account fund-with-faucet --account core
    aptos account fund-with-faucet --account distribution
    # TODO: airdrop fighting sc
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
    # TODO: publish fighting sc
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
