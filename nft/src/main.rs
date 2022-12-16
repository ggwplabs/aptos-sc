use clap::{crate_description, crate_name, crate_version, value_t_or_exit};
use token::TokenClient;

mod app;
mod config;
mod token;

#[tokio::main]
async fn main() {
    let app_matches =
        app::get_clap_app(crate_name!(), crate_description!(), crate_version!()).get_matches();

    let config = if let Some(config_path) = app_matches.value_of("config") {
        config::AptosConfig::load(config_path).expect("Config loading error")
    } else {
        config::AptosConfig::default()
    };

    let (sub_command, cmd_matches) = app_matches.subcommand();
    match (sub_command, cmd_matches) {
        (app::CMD_INIT_COLLECTION, Some(_)) => {
            println!("Initialize collection: {:?}", config.collection);
            let mut token_client = TokenClient::new(config.rpc_url, config.sender)
                .await
                .expect("Failed create token client");

            let (tx, cost) = token_client
                .create_collection(
                    config.collection.name,
                    config.collection.description,
                    config.collection.uri,
                    config.collection.max_supply,
                )
                .await
                .expect("Creating collection error");

            println!("APT Cost: {} ({})", cost, amount_to_ui_amount(cost));
            println!("{}", tx.hash);
        }

        (app::CMD_MINT_NFT, Some(cmd_matches)) => {
            println!("Create new token in collection: {}", config.collection.name);
            let to_addr = value_t_or_exit!(cmd_matches, "to", String);
            let name = value_t_or_exit!(cmd_matches, "name", String);
            let description = value_t_or_exit!(cmd_matches, "description", String);
            let uri = value_t_or_exit!(cmd_matches, "uri", String);

            let collection_creator = config.sender.account_addr.clone();
            let mut token_client = TokenClient::new(config.rpc_url, config.sender)
                .await
                .expect("Failed create token client");

            let (tx, cost) = token_client
                .create_token(
                    config.collection.name.clone(),
                    name.clone(),
                    description,
                    uri,
                    config.royalty,
                )
                .await
                .expect("Creating token error");

            println!(
                "Token created, cost: {} ({})",
                cost,
                amount_to_ui_amount(cost)
            );
            println!("tx: {}", tx.hash);

            println!("Offer token to: {}", to_addr);
            let (tx, cost) = token_client
                .offer_token(to_addr, collection_creator, config.collection.name, name)
                .await
                .expect("Offer token error");

            println!(
                "Token offered, cost: {} ({})",
                cost,
                amount_to_ui_amount(cost)
            );
            println!("tx: {}", tx.hash);
        }

        (app::CMD_CLAIM_NFT, Some(cmd_matches)) => {
            println!("Claim the token in collection: {}", config.collection.name);
            let creator = value_t_or_exit!(cmd_matches, "creator", String);
            let name = value_t_or_exit!(cmd_matches, "name", String);

            let mut token_client = TokenClient::new(config.rpc_url, config.sender)
                .await
                .expect("Failed create token client");

            let (tx, cost) = token_client
                .claim_token(creator.clone(), creator, config.collection.name, name)
                .await
                .expect("Claim token error");

            println!(
                "Token claimed, cost: {} ({})",
                cost,
                amount_to_ui_amount(cost)
            );
            println!("tx: {}", tx.hash);
        }

        // TODO: get_collections_info
        _ => {
            println!("{}", app_matches.usage());
        }
    }
}

pub fn amount_to_ui_amount(amount: u64) -> f64 {
    amount as f64 / 10_usize.pow(8u32) as f64
}
