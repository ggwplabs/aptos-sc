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
    local balance=`aptos account list --query balance --account $account | python3 -c "import sys, json; print(json.load(sys.stdin)['Result'][0]['coin']['value'])"`
    echo $balance
}

function update_ggwp_core {
    local file_content="[package]
name = 'ggwp_core'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'testnet'
subdir = 'aptos-move/framework/aptos-framework'
[dependencies]
ggwpcoin = { local = \"../ggwp_coin\" }
[addresses]
ggwp_core = \"$1\""
    echo "$file_content" > $2
}

function update_distribution {
    local file_content="[package]
name = 'accumulative_fund'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'testnet'
subdir = 'aptos-move/framework/aptos-framework'
[dependencies]
ggwpcoin = { local = \"../ggwp_coin\" }
gateway = { local = \"../gateway\" }
[addresses]
accumulative_fund = \"$1\""
    echo "$file_content" > $2
}

function update_faucet {
    local file_content="[package]
name = 'faucet'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'testnet'
subdir = 'aptos-move/framework/aptos-framework'
[addresses]
faucet = \"$1\""
    echo "$file_content" > $2
}

function update_gateway {
    local file_content="[package]
name = 'gateway'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'testnet'
subdir = 'aptos-move/framework/aptos-framework'
[dependencies]
ggwpcoin = { local = \"../ggwp_coin\" }
ggwp_core = { local = \"../core\" }
[addresses]
gateway = \"$1\""
    echo "$file_content" > $2
}

function update_ggwp_coin {
    local file_content="[package]
name = 'ggwpcoin'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'testnet'
subdir = 'aptos-move/framework/aptos-framework'
[addresses]
coin = \"$1\""
    echo "$file_content" > $2
}
