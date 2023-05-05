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

DISTRIBUTION="0x$profiles_distribution_account"
DISTRIBUTION_DISTRIBUTE="$DISTRIBUTION::distribution::distribute"

echo "------------------------------"
echo "APTOS accumulative fund balance before:"

distribution_initial_balance=$(get_balance distribution)
echo "balance: $distribution_initial_balance"
echo "------------------------------"

/usr/local/bin/aptos move run --function-id $DISTRIBUTION_DISTRIBUTE --profile distribution --assume-yes

echo "------------------------------"
echo "Distribution APTOS cost:"

distribution_balance=$(get_balance distribution)
let distribution_cost=$distribution_initial_balance-$distribution_balance
echo "cost: $distribution_cost"
