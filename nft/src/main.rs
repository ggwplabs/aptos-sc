use clap::{crate_description, crate_name, crate_version};
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
        (app::CMD_INIT_COLLECTION, Some(cmd_matches)) => {
            let mut token_client = TokenClient::new(config.rpc_url, config.admin)
                .await
                .expect("Failed create token client");
            token_client
                .create_collection(
                    config.collection.name,
                    config.collection.description,
                    config.collection.uri,
                    config.collection.max_supply,
                )
                .await
                .expect("Creating collection error");
        }

        (app::CMD_MINT_NFT, Some(cmd_matches)) => {
            // TODO
        }

        _ => {
            println!("{}", app_matches.usage());
        }
    }
}
