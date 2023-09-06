library;

pub struct Deposit {
    caller: Identity,
    receiver: Identity,
    asset: AssetId,
    assets: u64,
    shares: u64,
}

pub struct Withdraw {
    caller: Identity,
    receiver: Identity,
    asset: AssetId,
    assets: u64,
    shares: u64,
}