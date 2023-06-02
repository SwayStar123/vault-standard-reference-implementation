library;

pub struct Deposit {
    caller: Identity,
    reciever: Identity,
    assets: u64,
    shares: u64,
}

pub struct Withdraw {
    caller: Identity,
    receiver: Identity,
    assets: u64,
    shares: u64,
}