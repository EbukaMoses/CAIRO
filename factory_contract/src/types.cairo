
use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct Book{
    pub book_id: u8,
    pub book_name: felt252,
    pub author: felt252,
    pub current_holder: ContractAddress,
    pub borrowed: bool,
    pub deleted: bool,
}

pub struct user{
    addresss: ContractAddress,
}