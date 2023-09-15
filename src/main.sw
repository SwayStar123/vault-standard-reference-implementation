contract;

mod events;

use events::{Deposit, Withdraw};
use std::{
    auth::msg_sender,
    call_frames::msg_asset_id,
    context::msg_amount,
    hash::Hash,
    storage::{storage_map::*, storage_string::StorageString},
    token::{mint_to, burn, transfer},
};

use token::{
    _total_assets, 
    _total_supply,
    _name,
    _symbol,
    _decimals
};

use src_20::SRC20;
use std::string::String;

storage {
    total_assets: u64 = 0,
    total_supply: StorageMap<AssetId, u64> = StorageMap {},
    name: StorageMap<AssetId, StorageString> = StorageMap {},
    symbol: StorageMap<AssetId, StorageString> = StorageMap {},
    decimals: StorageMap<AssetId, u8> = StorageMap {},
}

impl SRC20 for Contract {
    #[storage(read)]
    fn total_assets() -> u64 {
        _total_assets(storage.total_assets)
    }

    #[storage(read)]
    fn total_supply(asset: AssetId) -> Option<u64> {
        _total_supply(storage.total_supply, asset)
    }

    #[storage(read)]
    fn name(asset: AssetId) -> Option<String> {
        _name(storage.name, asset)
    }

    #[storage(read)]
    fn symbol(asset: AssetId) -> Option<String> {
        _symbol(storage.symbol, asset)
    }

    #[storage(read)]
    fn decimals(asset: AssetId) -> Option<u8> {
        _decimals(storage.decimals, asset)
    }
}

abi SRC6 {
    // SRC-6
    // Deposit/Withdrawal
    #[storage(read, write)]
    fn deposit(receiver: Identity);
    #[storage(read, write)]
    fn withdraw(asset: AssetId, receiver: Identity);
    
    // Accounting
    #[storage(read)]
    fn managed_assets(asset: AssetId) -> u64;
    #[storage(read)]
    fn convert_to_shares(asset: AssetId, assets: u64) -> u64;
    #[storage(read)]
    fn convert_to_assets(asset: AssetId, shares: u64) -> u64;
    #[storage(read)]
    fn preview_deposit(asset: AssetId, assets: u64) -> u64;
    #[storage(read)]
    fn preview_withdraw(asset: AssetId, shares: u64) -> u64;

    // Deposit/Withdrawal Limits
    #[storage(read)]
    fn max_depositable(asset: AssetId) -> Option<u64>;
    #[storage(read)]
    fn max_withdrawable(asset: AssetId) -> Option<u64>;
}

impl SRC6 for Contract {
    #[storage(read)]
    fn managed_assets(asset: AssetId) -> u64 {
        managed_assets(asset) // In this implementation managed_assets and max_withdrawable are the same. However in case of lending out of assets, managed_assets should be greater than max_withdrawable.
    }

    #[storage(read, write)]
    fn deposit(receiver: Identity) {
        let assets = msg_amount();
        let asset = msg_asset_id();
        let shares = preview_deposit(asset, assets);
        require(shares != 0, "ZERO_SHARES");
        
        mint_to(receiver, asset.into(), shares); // Using the asset_id as the sub_id for shares.
        storage.total_supply.insert(asset, storage.total_supply.get(asset).read() + shares);
        after_deposit();

        log(Deposit {
            caller: msg_sender().unwrap(),
            receiver: receiver,
            asset: asset,
            assets: assets,
            shares: shares,
        })
    }

    #[storage(read, write)]
    fn withdraw(asset: AssetId, receiver: Identity) {
        let shares = msg_amount();
        require(shares != 0, "ZERO_SHARES");
        require(msg_asset_id() == AssetId::new(ContractId::this(), asset.into()), "INVALID_ASSET_ID");
        let assets = preview_withdraw(asset, shares);
        
        burn(asset.into(), shares);
        storage.total_supply.insert(asset, storage.total_supply.get(asset).read() - shares);
        after_withdraw();

        transfer(receiver, asset, assets);

        log(Withdraw {
            caller: msg_sender().unwrap(),
            receiver: receiver,
            asset: asset,
            assets: assets,
            shares: shares,
        })
    }

    #[storage(read)]
    fn convert_to_shares(asset: AssetId, assets: u64) -> u64 {
        preview_deposit(asset, assets)
    }

    #[storage(read)]
    fn convert_to_assets(asset: AssetId, shares: u64) -> u64 {
        preview_withdraw(asset, shares)
    }

    #[storage(read)]
    fn preview_deposit(asset: AssetId, assets: u64) -> u64 {
        preview_deposit(asset, assets)
    }

    #[storage(read)]
    fn preview_withdraw(asset: AssetId, shares: u64) -> u64 {
        preview_withdraw(asset, shares)
    }

    #[storage(read)]
    fn max_depositable(asset: AssetId) -> Option<u64> {
        Option::Some(18_446_744_073_709_551_615 - managed_assets(asset)) // This is the max value of u64 minus the current managed_assets. Ensures that the sum will always be lower than u64::MAX.
    }

    #[storage(read)]
    fn max_withdrawable(asset: AssetId) -> Option<u64> {
        Option::Some(managed_assets(asset)) // In this implementation total_assets and max_withdrawable are the same. However in case of lending out of assets, total_assets should be greater than max_withdrawable.
    }
}

fn managed_assets(asset: AssetId) -> u64 {
    std::context::this_balance(asset)
}

#[storage(read)]
fn preview_deposit(asset: AssetId, assets: u64) -> u64 {
    let shares_supply = storage.total_supply.get(AssetId::new(ContractId::this(), asset.into())).read();
    if shares_supply == 0 {
        assets
    } else {
        assets * shares_supply / managed_assets(asset)
    }
}

#[storage(read)]
fn preview_withdraw(asset: AssetId, shares: u64) -> u64 {
    let supply = storage.total_supply.get(AssetId::new(ContractId::this(), asset.into())).read();
    if supply == shares {
        managed_assets(asset)
    } else {
        shares * (managed_assets(asset) / supply)
    }
}

fn after_deposit() {
    // Does nothing, only for demonstration purposes.
}

fn after_withdraw() {
    // Does nothing, only for demonstration purposes.
}