contract;

mod events;

use events::{Deposit, Withdraw};
use std::{
    auth::msg_sender,
    call_frames::msg_asset_id,
    context::msg_amount,
    token::{mint_to, burn},
}
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
    name: StorageMap<AssetId, StorageKey<StorageString>> = StorageMap {},
    symbol: StorageMap<AssetId, StorageKey<StorageString>> = StorageMap {},
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
    fn managed_assets(asset: AssetId) -> u64;
    #[storage(read)]
    fn convert_to_shares(asset: AssetId, assets: u64) -> u64;
    #[storage(read)]
    fn convert_to_assets(asset: AssetId, shares: u64) -> u64;
    #[storage(read)]
    fn preview_deposit(asset: AssetId, assets: u64) -> u64;
    #[storage(read)]
    fn preview_withdraw(asset: AssetId, assets: u64) -> u64;

    // Deposit/Withdrawal Limits
    #[storage(read)]
    fn max_depositable(asset: AssetId) -> Option<u64>;
    #[storage(read)]
    fn max_withdrawable(asset: AssetId) -> Option<u64>;
}

impl SRC6 for Contract {
    fn managed_assets(asset: AssetId) -> u64 {
        managed_assets(asset) // In this implementation managed_assets and max_withdrawable are the same. However in case of lending out of assets, managed_assets should be greater than max_withdrawable.
    }

    #[storage(read, write)]
    fn deposit(receiver: Identity) {
        let assets = msg_amount();
        let asset = msg_asset_id();
        let shares = preview_deposit(asset, assets);
        assert!(shares != 0, "ZERO_SHARES");
        
        mint_to(receiver, asset.into(), shares); // Using the asset_id as the sub_id for shares.
        storage.total_supply.insert(asset, storage.total_supply.get(asset) + shares);
        after_deposit();

        log(Deposit {
            caller: msg_sender().unwrap(),
            reciever: receiver,
            asset: asset,
            assets: assets,
            shares: shares,
        })
    }

    #[storage(read, write)]
    fn withdraw(asset: AssetId, receiver: Identity) {
        let shares = msg_amount();
        assert!(shares != 0, "ZERO_SHARES");
        assert(msg_asset_id() == AssetId::default(asset.into()), "INVALID_ASSET_ID");
        let assets = preview_withdraw(asset, shares);
        
        burn(shares);
        storage.total_supply.insert(asset, storage.total_supply.get(asset) - shares);
        after_withdraw();

        transfer(receiver, asset, assets);

        log(Withdraw {
            caller: msg_sender().unwrap(),
            reciever: receiver,
            asset: asset,
            assets: assets,
            shares: shares,
        })
    }

    #[storage(read)]
    fn convert_to_shares(assets: u64) -> u64 {
        preview_deposit(assets)
    }

    #[storage(read)]
    fn convert_to_assets(shares: u64) -> u64 {
        preview_withdraw(shares)
    }

    #[storage(read)]
    fn preview_deposit(assets: u64) -> u64 {
        preview_deposit(assets)
    }

    #[storage(read)]
    fn preview_withdraw(assets: u64) -> u64 {
        preview_withdraw(assets)
    }

    #[storage(read)]
    fn max_depositable() -> u64 {
        18_446_744_073_709_551_615 // This is the max value of u64 
    }

    #[storage(read)]
    fn max_withdrawable() -> u64 {
        total_assets() // In this implementation total_assets and max_withdrawable are the same. However in case of lending out of assets, total_assets should be greater than max_withdrawable.
    }
}

fn managed_assets(asset: AssetId) -> u64 {
    std::context::this_balance(asset)
}

#[storage(read)]
fn preview_deposit(assets: u64) -> u64 {
    let supply = storage.total_supply.read();
    if supply == 0 {
        assets
    } else {
        assets * supply / total_assets()
    }
}

#[storage(read)]
fn preview_withdraw(assets: u64) -> u64 {
    let supply = storage.total_supply.read();
    if supply == 0 {
        assets
    } else {
        assets * supply / total_assets()
    }
}

fn after_deposit() {
    // Does nothing, only for demonstration purposes.
}

fn after_withdraw() {
    // Does nothing, only for demonstration purposes.
}