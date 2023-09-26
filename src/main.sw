contract;

mod events;

use events::{Deposit, Withdraw};
use std::{
    auth::msg_sender,
    call_frames::msg_asset_id,
    context::msg_amount,
    hash::Hash,
    storage::{storage_map::*, storage_string::StorageString},
    token::transfer,
};

use token::{
    _total_assets, 
    _total_supply,
    _name,
    _symbol,
    _decimals,
    _mint,
    _burn,
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

    /// Deposits assets into the contract and mints shares to the receiver.
    ///
    /// # Additional Information
    ///
    /// * Assets must be forwarded to the contract in the contract call.
    ///
    /// # Arguments
    ///
    /// * `receiver`: [Identity] - The receiver of the shares.
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of shares minted.
    ///
    /// # Reverts
    ///
    /// * If the asset is not supported by the contract.
    /// * If the amount of assets is zero.
    /// * The user crosses any global or user specific deposit limits.
    #[storage(read, write)]
    fn deposit(receiver: Identity) -> u64;
    /// Burns shares from the sender and transfers assets to the receiver.
    ///
    /// # Additional Information
    ///
    /// * Shares must be forwarded to the contract in the contract call.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the shares should be burned.
    /// * `receiver`: [Identity] - The receiver of the assets.
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of assets transferred.
    ///
    /// # Reverts
    ///
    /// * If the asset is not supported by the contract.
    /// * If the amount of shares is zero.
    /// * If the transferred shares do not corresspond to the given asset.
    /// * The user crosses any global or user specific withdrawal limits.
    #[storage(read, write)]
    fn withdraw(asset: AssetId, receiver: Identity) -> u64;
    
    // Accounting

    /// Returns the amount of managed assets of the given asset.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the amount of managed assets should be returned.
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of managed assets of the given asset.
    #[storage(read)]
    fn managed_assets(asset: AssetId) -> u64;
    /// Returns how many shares would be minted for the given amount of assets, in an ideal scenario (No accounting for slippage, or any limits).
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the amount of shares should be returned.
    /// * `assets`: [u64] - The amount of assets for which the amount of shares should be returned.
    ///
    /// # Returns
    ///
    /// * [Some(u64)] - The amount of shares that would be minted for the given amount of assets.
    /// * [None] - If the asset is not supported by the contract.
    #[storage(read)]
    fn convert_to_shares(asset: AssetId, assets: u64) -> Option<u64>;
    /// Returns how many assets would be transferred for the given amount of shares, in an ideal scenario (No accounting for slippage, or any limits).
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the amount of assets should be returned.
    /// * `shares`: [u64] - The amount of shares for which the amount of assets should be returned.
    ///
    /// # Returns
    ///
    /// * [Some(u64)] - The amount of assets that would be transferred for the given amount of shares.
    /// * [None] - If the asset is not supported by the contract.
    #[storage(read)]
    fn convert_to_assets(asset: AssetId, shares: u64) -> Option<u64>;
    /// Returns how many shares would have been minted for the given amount of assets, if this was a deposit call.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the amount of shares should be returned.
    /// * `assets`: [u64] - The amount of assets for which the amount of shares should be returned.
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of shares that would have been minted for the given amount of assets.
    ///
    /// # Reverts
    ///
    /// * For any reason a deposit would revert.
    #[storage(read)]
    fn preview_deposit(asset: AssetId, assets: u64) -> u64;
    /// Returns how many assets would have been transferred for the given amount of shares, if this was a withdrawal call.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the amount of assets should be returned.
    /// * `shares`: [u64] - The amount of shares for which the amount of assets should be returned.
    ///
    /// # Returns
    ///
    /// * [u64] - The amount of assets that would have been transferred for the given amount of shares.
    ///
    /// # Reverts
    ///
    /// * For any reason a withdrawal would revert.
    #[storage(read)]
    fn preview_withdraw(asset: AssetId, shares: u64) -> u64;

    // Deposit/Withdrawal Limits

    /// Returns the maximum amount of assets that can be deposited into the contract, for the given asset.
    ///
    /// # Additional Information
    ///
    /// Does not account for any user or global limits.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the maximum amount of depositable assets should be returned.
    ///
    /// # Returns
    ///
    /// * [Some(u64)] - The maximum amount of assets that can be deposited into the contract, for the given asset.
    /// * [None] - If the asset is not supported by the contract.
    #[storage(read)]
    fn max_depositable(asset: AssetId) -> Option<u64>;
    /// Returns the maximum amount of assets that can be withdrawn from the contract, for the given asset.
    ///
    /// # Additional Information
    ///
    /// Does not account for any user or global limits.
    ///
    /// # Arguments
    ///
    /// * `asset`: [AssetId] - The asset for which the maximum amount of withdrawable assets should be returned.
    ///
    /// # Returns
    ///
    /// * [Some(u64)] - The maximum amount of assets that can be withdrawn from the contract, for the given asset.
    /// * [None] - If the asset is not supported by the contract.
    #[storage(read)]
    fn max_withdrawable(asset: AssetId) -> Option<u64>;
}

impl SRC6 for Contract {
    #[storage(read)]
    fn managed_assets(asset: AssetId) -> u64 {
        managed_assets(asset) // In this implementation managed_assets and max_withdrawable are the same. However in case of lending out of assets, managed_assets should be greater than max_withdrawable.
    }
    
    #[storage(read, write)]
    fn deposit(receiver: Identity) -> u64 {
        let assets = msg_amount();
        let asset = msg_asset_id();
        let shares = preview_deposit(asset, assets);
        require(assets != 0, "ZERO_ASSETS");
        
        let _ = _mint(storage.total_assets, storage.total_supply, receiver, asset.into(), shares); // Using the asset_id as the sub_id for shares.
        storage.total_supply.insert(asset, storage.total_supply.get(asset).read() + shares);
        after_deposit();

        log(Deposit {
            caller: msg_sender().unwrap(),
            receiver: receiver,
            asset: asset,
            assets: assets,
            shares: shares,
        });

        shares
    }

    #[storage(read, write)]
    fn withdraw(asset: AssetId, receiver: Identity) -> u64 {
        let shares = msg_amount();
        require(shares != 0, "ZERO_SHARES");
        require(msg_asset_id() == AssetId::new(ContractId::this(), asset.into()), "INVALID_ASSET_ID");
        let assets = preview_withdraw(asset, shares);
        
        _burn(storage.total_supply, asset.into(), shares);
        storage.total_supply.insert(asset, storage.total_supply.get(asset).read() - shares);
        after_withdraw();

        transfer(receiver, asset, assets);

        log(Withdraw {
            caller: msg_sender().unwrap(),
            receiver: receiver,
            asset: asset,
            assets: assets,
            shares: shares,
        });

        assets
    }

    #[storage(read)]
    fn convert_to_shares(asset: AssetId, assets: u64) -> Option<u64> {
        Option::Some(preview_deposit(asset, assets))
    }

    
    #[storage(read)]
    fn convert_to_assets(asset: AssetId, shares: u64) -> Option<u64> {
        Option::Some(preview_withdraw(asset, shares))
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