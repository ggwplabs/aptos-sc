//! Cli configuration
use serde::{Deserialize, Serialize};
use std::fs::File;

/// Config for aptos integration
#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct AptosConfig {
    pub rpc_url: String,
    pub sender: SenderConfig,
    pub collection: CollectionConfig,
    pub royalty: RoyaltyConfig,
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct SenderConfig {
    pub account_addr: String,
    pub private_key: String,
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct CollectionConfig {
    pub name: String,
    pub description: String,
    pub uri: String,
    pub max_supply: u64,
}

#[derive(Serialize, Deserialize, Debug, PartialEq, Clone)]
pub struct RoyaltyConfig {
    pub royalty_payee_address: String,
    pub royalty_points_denominator: u64,
    pub royalty_points_numerator: u64,
}

impl Default for AptosConfig {
    fn default() -> Self {
        let rpc_url = "https://fullnode.devnet.aptoslabs.com".to_string();
        let sender_account_addr =
            "1344ced5b73165303b9a2bc9a7db783e517f50686bc3fdd38f1996500250f305".to_string();
        let sender_private_key =
            "0x2d4be9e4fa53e1925b0419353da55768285ad34a7f8599e662e52eef77f003f5".to_string();

        Self {
            rpc_url,
            sender: SenderConfig {
                account_addr: sender_account_addr,
                private_key: sender_private_key,
            },
            collection: CollectionConfig {
                name: "GGWP NFT Test".to_string(),
                description: "Test NFT Collection".to_string(),
                uri: "https://test.collection.com".to_string(),
                max_supply: 100,
            },
            royalty: RoyaltyConfig {
                royalty_payee_address:
                    "1344ced5b73165303b9a2bc9a7db783e517f50686bc3fdd38f1996500250f305".to_string(),
                royalty_points_denominator: 1,
                royalty_points_numerator: 10,
            },
        }
    }
}

impl AptosConfig {
    /// Loading Server Config from file
    pub fn load(config_file: &str) -> Result<Self, std::io::Error> {
        let file = File::open(config_file)?;
        let config: Self = serde_json::from_reader(file)
            .map_err(|err| std::io::Error::new(std::io::ErrorKind::Other, format!("{:?}", err)))?;
        Ok(config)
    }
}
