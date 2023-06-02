contract;

mod events;

use events::{Deposit, Withdraw};
use std::{
    auth::msg_sender,
    call_frames::msg_asset_id,
    context::msg_amount,
    token::{mint_to, burn},
}

configurable {
    ASSET_ID: ContractId = std::constants::BASE_ASSET_ID,
}

storage {
    total_supply: u64 = 0,
}

abi MyContract {
    // SRC-20
    #[storage(read)]
    fn total_supply() -> u64;
    fn decimals() -> u8;
    fn name() -> str[7];
    fn symbol() -> str[2];

    // SRC-4626
    // Deposit/Withdrawal
    fn deposit(receiver: Identity);
    fn withdraw(receiver: Identity);
    
    // Accounting
    fn total_assets() -> u64;
    #[storage(read)]
    fn convert_to_shares(assets: u64) -> u64;
    #[storage(read)]
    fn convert_to_assets(shares: u64) -> u64;
    #[storage(read)]
    fn preview_deposit(assets: u64) -> u64;
    #[storage(read)]
    fn preview_withdraw(assets: u64) -> u64;

    // Deposit/Withdrawal Limits
    #[storage(read)]
    fn max_depositable() -> u64;
    #[storage(read)]
    fn max_withdrawable() -> u64;
}

impl MyContract for Contract {
    #[storage(read)]
    fn total_supply() -> u64 {
        storage.total_supply.read()
    }
    fn decimals() -> u8 {
        9
    }
    fn name() -> str[7] {
        "Example"
    }
    fn symbol() -> str[2] {
        "Eg"
    }

    fn total_assets() -> u64 {
        total_assets() // In this implementation total_assets and max_withdrawable are the same. However in case of lending out of assets, total_assets should be greater than max_withdrawable.
    }

    #[storage(read, write)]
    fn deposit(receiver: Identity) {
        let assets = msg_amount();
        assert(msg_asset_id() == ASSET_ID, "INVALID_ASSET_ID");
        let shares = preview_deposit(assets);
        assert!(shares != 0, "ZERO_SHARES");
        
        mint_to(shares, receiver);
        storage.total_supply.write(storage.total_supply.read() + shares);
        after_deposit();

        log(Deposit {
            caller: msg_sender().unwrap(),
            reciever: receiver,
            assets: assets,
            shares: shares,
        })
    }

    #[storage(read, write)]
    fn withdraw(receiver: Identity) {
        let shares = msg_amount();
        assert!(shares != 0, "ZERO_SHARES");
        assert(msg_asset_id() == std::call_frames::contract_id(), "INVALID_ASSET_ID");
        let assets = preview_withdraw(shares);
        
        burn(shares);
        storage.total_supply.write(storage.total_supply.read() - shares);
        after_withdraw();

        transfer(assets, ASSET_ID, receiver);

        log(Withdraw {
            caller: msg_sender().unwrap(),
            reciever: receiver,
            assets: assets,
            shares: shares,
        })
    }

    #[storage(read)]
    fn convert_to_shares(assets: u64) -> u64 {
        let supply = storage.total_supply.read();
        if supply == 0 {
            assets
        } else {
            assets * supply / total_assets()
        }
    }

    #[storage(read)]
    fn convert_to_assets(shares: u64) -> u64 {
        let supply = storage.total_supply.read();
        if supply == 0 {
            shares
        } else {
            shares * total_assets() / supply
        }
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

    #[storage(read)]
    fn max_depositable() -> u64 {
        18_446_744_073_709_551_615 // This is the max value of u64 
    }

    #[storage(read)]
    fn max_withdrawable() -> u64 {
        total_assets() // In this implementation total_assets and max_withdrawable are the same. However in case of lending out of assets, total_assets should be greater than max_withdrawable.
    }
}

fn total_assets() -> u64 {
    std::context::this_balance(ASSET_ID)
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