use crate::config::{RoyaltyConfig, SenderConfig};
use anyhow::{Context, Result};
use aptos_sdk::coin_client::CoinClient;
use aptos_sdk::crypto::ed25519::Ed25519PrivateKey;
use aptos_sdk::{
    bcs,
    move_types::{identifier::Identifier, language_storage::ModuleId},
    rest_client::{error::RestError, Client as AptosClient, PendingTransaction},
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

pub struct TokenClient {
    aptos_client: AptosClient,
    options: Options,
    sender: LocalAccount,
}

pub struct Options {
    timeout_sec: u64,
    max_gas_amount: u64,
    gas_unit_price: u64,
}

impl TokenClient {
    pub async fn new(rpc_url: String, sender: SenderConfig) -> Result<Self, RestError> {
        let client = AptosClient::new(Url::from_str(rpc_url.as_str()).expect("Invalid rpc url"));

        let sender_addr =
            AccountAddress::from_str(&sender.account_addr).expect("Failed parse account address");
        let sender_sn: u64 = Self::get_sequence_number(&client, sender_addr).await?;

        let key_bytes = hex::decode(&sender.private_key).unwrap();
        let sender_pk: Ed25519PrivateKey = (&key_bytes[..]).try_into().unwrap();

        let sender_account = LocalAccount::new(sender_addr, sender_pk.clone(), sender_sn);

        Ok(Self {
            aptos_client: client,
            options: Options {
                timeout_sec: 10,
                max_gas_amount: 5_000,
                gas_unit_price: 100,
            },
            sender: sender_account,
        })
    }

    // Instructions

    pub async fn create_collection(
        &mut self,
        collection_name: String,
        collection_description: String,
        collection_uri: String,
        collection_max_supply: u64,
    ) -> Result<(PendingTransaction, u64)> {
        let chain_id = self.get_chain_id().await?;
        let coin_client = CoinClient::new(&self.aptos_client);
        let balance_before = coin_client
            .get_account_balance(&self.sender.address())
            .await?;

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
        .sender(self.sender.address())
        .sequence_number(self.sender.sequence_number())
        .max_gas_amount(self.options.max_gas_amount)
        .gas_unit_price(self.options.gas_unit_price);

        let signed_txn = self
            .sender
            .sign_with_transaction_builder(transaction_builder);

        let pending_tx = self
            .aptos_client
            .submit(&signed_txn)
            .await
            .context("Failed to submit transfer transaction")?
            .into_inner();

        let balance_after = coin_client
            .get_account_balance(&self.sender.address())
            .await?;
        let cost = balance_before.checked_sub(balance_after).unwrap_or(0);

        Ok((pending_tx, cost))
    }

    pub async fn create_token(
        &mut self,
        collection_name: String,
        token_name: String,
        token_description: String,
        token_uri: String,
        royalty: RoyaltyConfig,
    ) -> Result<(PendingTransaction, u64)> {
        let chain_id = self.get_chain_id().await?;
        let coin_client = CoinClient::new(&self.aptos_client);
        let balance_before = coin_client
            .get_account_balance(&self.sender.address())
            .await?;

        let empty_vec: Vec<String> = Vec::new();
        let token_address = AccountAddress::from_str("0x03").expect("Token addr parse error");
        let transaction_builder = TransactionBuilder::new(
            TransactionPayload::EntryFunction(EntryFunction::new(
                ModuleId::new(token_address, Identifier::new("token").unwrap()),
                Identifier::new("create_token_script").unwrap(),
                vec![],
                vec![
                    bcs::to_bytes(&collection_name).unwrap(),
                    bcs::to_bytes(&token_name).unwrap(),
                    bcs::to_bytes(&token_description).unwrap(),
                    bcs::to_bytes(&1).unwrap(), // balance
                    bcs::to_bytes(&1).unwrap(), // maximum
                    bcs::to_bytes(&token_uri).unwrap(),
                    bcs::to_bytes(&royalty.royalty_payee_address).unwrap(),
                    bcs::to_bytes(&royalty.royalty_points_denominator).unwrap(),
                    bcs::to_bytes(&royalty.royalty_points_numerator).unwrap(),
                    // mutate_settings: [maximum, uri, royalty, description, properties]
                    bcs::to_bytes(&vec![false, false, false, false, false]).unwrap(),
                    // property_keys
                    bcs::to_bytes(&empty_vec).unwrap(),
                    // property_values
                    bcs::to_bytes(&empty_vec).unwrap(),
                    // property_types
                    bcs::to_bytes(&empty_vec).unwrap(),
                ],
            )),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs()
                + self.options.timeout_sec,
            ChainId::new(chain_id),
        )
        .sender(self.sender.address())
        .sequence_number(self.sender.sequence_number())
        .max_gas_amount(self.options.max_gas_amount)
        .gas_unit_price(self.options.gas_unit_price);

        let signed_txn = self
            .sender
            .sign_with_transaction_builder(transaction_builder);

        let pending_tx = self
            .aptos_client
            .submit(&signed_txn)
            .await
            .context("Failed to submit transfer transaction")?
            .into_inner();

        let balance_after = coin_client
            .get_account_balance(&self.sender.address())
            .await?;
        let cost = balance_before.checked_sub(balance_after).unwrap_or(0);

        Ok((pending_tx, cost))
    }

    pub async fn offer_token(
        &mut self,
        to: String,
        creator: String,
        collection_name: String,
        token_name: String,
    ) -> Result<(PendingTransaction, u64)> {
        let chain_id = self.get_chain_id().await?;
        let coin_client = CoinClient::new(&self.aptos_client);
        let balance_before = coin_client
            .get_account_balance(&self.sender.address())
            .await?;

        let token_address = AccountAddress::from_str("0x03").expect("Token addr parse error");
        let transaction_builder = TransactionBuilder::new(
            TransactionPayload::EntryFunction(EntryFunction::new(
                ModuleId::new(token_address, Identifier::new("token_transfers").unwrap()),
                Identifier::new("offer_script").unwrap(),
                vec![],
                vec![
                    bcs::to_bytes(&to).unwrap(),
                    bcs::to_bytes(&creator).unwrap(),
                    bcs::to_bytes(&collection_name).unwrap(),
                    bcs::to_bytes(&token_name).unwrap(),
                    // token property version
                    bcs::to_bytes(&0).unwrap(),
                    // amount
                    bcs::to_bytes(&1).unwrap(),
                ],
            )),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs()
                + self.options.timeout_sec,
            ChainId::new(chain_id),
        )
        .sender(self.sender.address())
        .sequence_number(self.sender.sequence_number())
        .max_gas_amount(self.options.max_gas_amount)
        .gas_unit_price(self.options.gas_unit_price);

        let signed_txn = self
            .sender
            .sign_with_transaction_builder(transaction_builder);

        let pending_tx = self
            .aptos_client
            .submit(&signed_txn)
            .await
            .context("Failed to submit transfer transaction")?
            .into_inner();

        let balance_after = coin_client
            .get_account_balance(&self.sender.address())
            .await?;
        let cost = balance_before.checked_sub(balance_after).unwrap_or(0);

        Ok((pending_tx, cost))
    }

    pub async fn claim_token(
        &mut self,
        sender: String,
        creator: String,
        collection_name: String,
        token_name: String,
    ) -> Result<(PendingTransaction, u64)> {
        let chain_id = self.get_chain_id().await?;
        let coin_client = CoinClient::new(&self.aptos_client);
        let balance_before = coin_client
            .get_account_balance(&self.sender.address())
            .await?;

        let token_address = AccountAddress::from_str("0x03").expect("Token addr parse error");
        let transaction_builder = TransactionBuilder::new(
            TransactionPayload::EntryFunction(EntryFunction::new(
                ModuleId::new(token_address, Identifier::new("token_transfers").unwrap()),
                Identifier::new("claim_script").unwrap(),
                vec![],
                vec![
                    bcs::to_bytes(&sender).unwrap(),
                    bcs::to_bytes(&creator).unwrap(),
                    bcs::to_bytes(&collection_name).unwrap(),
                    bcs::to_bytes(&token_name).unwrap(),
                    // token property version
                    bcs::to_bytes(&0).unwrap(),
                ],
            )),
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_secs()
                + self.options.timeout_sec,
            ChainId::new(chain_id),
        )
        .sender(self.sender.address())
        .sequence_number(self.sender.sequence_number())
        .max_gas_amount(self.options.max_gas_amount)
        .gas_unit_price(self.options.gas_unit_price);

        let signed_txn = self
            .sender
            .sign_with_transaction_builder(transaction_builder);

        let pending_tx = self
            .aptos_client
            .submit(&signed_txn)
            .await
            .context("Failed to submit transfer transaction")?
            .into_inner();

        let balance_after = coin_client
            .get_account_balance(&self.sender.address())
            .await?;
        let cost = balance_before.checked_sub(balance_after).unwrap_or(0);

        Ok((pending_tx, cost))
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
