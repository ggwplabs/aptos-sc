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

function update_ggwp_core {
    local file_content="[package]
name = 'ggwp_core'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'main'
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
rev = 'main'
subdir = 'aptos-move/framework/aptos-framework'
[dependencies]
ggwpcoin = { local = \"../ggwp_coin\" }
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
rev = 'main'
subdir = 'aptos-move/framework/aptos-framework'
[addresses]
faucet = \"$1\""
    echo "$file_content" > $2
}

function update_games {
    local file_content="[package]
name = 'games'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'main'
subdir = 'aptos-move/framework/aptos-framework'
[dependencies]
ggwpcoin = { local = \"../ggwp_coin\" }
ggwp_core = { local = \"../core\" }
[addresses]
games = \"$1\""
    echo "$file_content" > $2
}

function update_ggwp_coin {
    local file_content="[package]
name = 'ggwpcoin'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'main'
subdir = 'aptos-move/framework/aptos-framework'
[addresses]
coin = \"$1\""
    echo "$file_content" > $2
}

function update_staking {
    local file_content="[package]
name = 'staking'
version = '1.0.0'
[dependencies.AptosFramework]
git = 'https://github.com/aptos-labs/aptos-core.git'
rev = 'main'
subdir = 'aptos-move/framework/aptos-framework'
[dependencies]
ggwpcoin = { local = \"../ggwp_coin\" }
[addresses]
staking = \"$1\""
    echo "$file_content" > $2
}
