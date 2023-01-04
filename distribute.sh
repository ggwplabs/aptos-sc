config_path=".aptos/config.yaml"

source utils.sh
parse_yaml $config_path > keys.sh
source keys.sh

GGWP="0x$profiles_coin_account"
GGWP_COIN_STRUCT="$GGWP::ggwp::GGWPCoin"

ACCUMULATIVE_FUND="0x$profiles_distribution_account"
DISTRIBUTION_DISTRIBUTE="$ACCUMULATIVE_FUND::distribution::distribute"

PLAY_TO_EARN_FUND="0x$profiles_games_account"
STAKING_FUND="0x$profiles_staking_account"
COMPANY_FUND="0x$profiles_company_fund_account"
TEAM_FUND="0x$profiles_team_fund_account"

echo "------------------------------"
echo "APTOS accumulative fund balance before:"

distribution_initial_balance=$(get_balance distribution)
echo "balance: $distribution_initial_balance"
echo "------------------------------"

aptos move run --function-id $DISTRIBUTION_DISTRIBUTE --profile distribution --assume-yes

echo "------------------------------"
echo "Distribution APTOS cost:"

distribution_balance=$(get_balance distribution)
let distribution_cost=$distribution_initial_balance-$distribution_balance
echo "cost: $distribution_cost"
