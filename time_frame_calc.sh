
# path: /home/snapper/src/distribution_script_testnet or /home/snapper/src/distribution_script
# bin: /usr/local/bin/aptos

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

function get_balance {
    local account=$1
    local balance=`/usr/local/bin/aptos account list --query balance --account $account | python3 -c "import sys, json; print(json.load(sys.stdin)['Result'][0]['coin']['value'])"`
    echo $balance
}

config_path=".aptos/config.yaml"

parse_yaml $config_path > keys.sh
source keys.sh

GATEWAY="0x$profiles_gateway_account"
GATEWAY_CALCULATE_TIME_FRAME="$GATEWAY::gateway::calculate_time_frame"

echo "------------------------------"
echo "APTOS gateway balance before:"

gateway_initial_balance=$(get_balance distribution)
echo "balance: $gateway_initial_balance"
echo "------------------------------"

/usr/local/bin/aptos move run --function-id $GATEWAY_CALCULATE_TIME_FRAME --profile gateway --assume-yes

echo "------------------------------"
echo "Time frame calculation APTOS cost:"

gateway_balance=$(get_balance distribution)
let time_frame_calc_cost=$gateway_initial_balance-$gateway_balance
echo "cost: $time_frame_calc_cost"
