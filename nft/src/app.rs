use aptos_sdk::types::account_address::AccountAddress;
use clap::{App, AppSettings, Arg, SubCommand};

pub const CMD_INIT_COLLECTION: &str = "init-nft-collection";
pub const CMD_MINT_NFT: &str = "mint-nft";
pub const CMD_CLAIM_NFT: &str = "claim-nft";

pub fn get_clap_app<'a, 'b>(name: &'a str, desc: &'a str, version: &'a str) -> App<'a, 'b> {
    App::new(name)
        .about(desc)
        .version(version)
        .setting(AppSettings::SubcommandRequiredElseHelp)
        .arg(
            Arg::with_name("config")
                .short("c")
                .long("config")
                .value_name("PATH")
                .takes_value(true)
                .global(true)
                .help("Path to configuration file."),
        )
        .subcommand(
            SubCommand::with_name(CMD_INIT_COLLECTION)
                .about("Initialize the new nft collection with meta from config file."),
        )
        .subcommand(
            SubCommand::with_name(CMD_MINT_NFT)
                .about("Mint new nft to address.")
                .arg(
                    Arg::with_name("to")
                        .value_name("ADDR")
                        .validator(is_valid_addr)
                        .required(true)
                        .takes_value(true)
                        .help("The receiver account address."),
                )
                .arg(
                    Arg::with_name("name")
                        .value_name("String")
                        .required(true)
                        .takes_value(true)
                        .help("The token name."),
                )
                .arg(
                    Arg::with_name("description")
                        .value_name("String")
                        .required(true)
                        .takes_value(true)
                        .help("The token description."),
                )
                .arg(
                    Arg::with_name("uri")
                        .value_name("String")
                        .required(true)
                        .takes_value(true)
                        .help("The token uri."),
                ),
        )
        .subcommand(
            SubCommand::with_name(CMD_CLAIM_NFT)
                .about("Claim NFT (called by receiver).")
                .arg(
                    Arg::with_name("creator")
                        .value_name("ADDR")
                        .validator(is_valid_addr)
                        .required(true)
                        .takes_value(true)
                        .help("The collection creator address."),
                )
                .arg(
                    Arg::with_name("name")
                        .value_name("String")
                        .required(true)
                        .takes_value(true)
                        .help("The token name."),
                ),
        )
}

fn is_valid_addr(string: String) -> Result<(), String> {
    match AccountAddress::try_from(string) {
        Ok(_) => Ok(()),
        Err(e) => Err(format!("Error parsing address: {}", e.to_string())),
    }
}
