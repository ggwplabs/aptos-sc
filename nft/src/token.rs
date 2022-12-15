use anyhow::{anyhow, Context, Result};
use aptos_sdk::crypto::ed25519::Ed25519PrivateKey;
use aptos_sdk::{
    bcs,
    move_types::{identifier::Identifier, language_storage::ModuleId},
    rest_client::{error::RestError, Client as AptosClient, PendingTransaction, Response},
    transaction_builder::TransactionBuilder,
    types::account_address::AccountAddress,
    types::{
        chain_id::ChainId,
        transaction::{EntryFunction, TransactionPayload},
        LocalAccount,
    },
};
use std::str::FromStr;
use std::time::{SystemTime, UNIX_EPOCH};
use url::Url;

use crate::config::{AdminConfig, AptosConfig};

pub struct TokenClient {
    aptos_client: AptosClient,
    options: Options,
    admin: LocalAccount,
}

pub struct Options {
    timeout_sec: u64,
    max_gas_amount: u64,
    gas_unit_price: u64,
}

impl TokenClient {
    pub async fn new(rpc_url: String, admin: AdminConfig) -> Result<Self, RestError> {
        let client = AptosClient::new(Url::from_str(rpc_url.as_str()).expect("Invalid rpc url"));

        let admin_addr =
            AccountAddress::from_str(&admin.account_addr).expect("Failed parse account address");
        let admin_sn: u64 = Self::get_sequence_number(&client, admin_addr).await?;

        let key_bytes = hex::decode(&admin.private_key).unwrap();
        let admin_pk: Ed25519PrivateKey = (&key_bytes[..]).try_into().unwrap();

        let admin_account = LocalAccount::new(admin_addr, admin_pk.clone(), admin_sn);

        Ok(Self {
            aptos_client: client,
            options: Options {
                timeout_sec: 10,
                max_gas_amount: 5_000,
                gas_unit_price: 100,
            },
            admin: admin_account,
        })
    }

    // Instructions

    pub async fn create_collection(
        &mut self,
        collection_name: String,
        collection_description: String,
        collection_uri: String,
        collection_max_supply: u64,
    ) -> Result<PendingTransaction> {
        let chain_id = self.get_chain_id().await?;

        let token_address = AccountAddress::from_str("0x03").expect("Token addr parse error");
        let transaction_builder = TransactionBuilder::new(
            TransactionPayload::EntryFunction(EntryFunction::new(
                ModuleId::new(token_address, Identifier::new("token").unwrap()),
                Identifier::new("create_collection_script").unwrap(),
                vec![],
                vec![
                    bcs::to_bytes(&collection_name).unwrap(),
                    bcs::to_bytes(&collection_description).unwrap(),
                    bcs::to_bytes(&collection_uri).unwrap(),
                    bcs::to_bytes(&collection_max_supply).unwrap(),
                    // mutate_settings: [description_mut, uri_mut, max_sup_mut]
                    bcs::to_bytes(&vec![false, false, false]).unwrap(),
                ],
            )),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs()
                + self.options.timeout_sec,
            ChainId::new(chain_id),
        )
        .sender(self.admin.address())
        .sequence_number(self.admin.sequence_number())
        .max_gas_amount(self.options.max_gas_amount)
        .gas_unit_price(self.options.gas_unit_price);

        let signed_txn = self
            .admin
            .sign_with_transaction_builder(transaction_builder);

        Ok(self
            .aptos_client
            .submit(&signed_txn)
            .await
            .context("Failed to submit transfer transaction")?
            .into_inner())
    }

    // Getters

    // Utils

    async fn get_chain_id(&self) -> Result<u8> {
        Ok(self
            .aptos_client
            .get_index()
            .await
            .context("Failed to get chain ID")?
            .inner()
            .chain_id)
    }

    async fn get_sequence_number(
        client: &AptosClient,
        addr: AccountAddress,
    ) -> Result<u64, RestError> {
        let number = client.get_account(addr).await?.inner().sequence_number;
        Ok(number)
    }
}
