#[starknet::interface]
pub trait IRegistry<TContractState>{
    fn register_use(ref self: TContractState, user_fname: felt252, user_lname: felt252);
    fn is_user_registered(self: @TContractState, user_id: u8) -> bool;  
    fn blacklist_user(ref self: TContractState, user_id: u8);
}

#[starknet::component]
pub mod RegistryComponent{
    use starknet::ContractAddress;
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StorageAsPath, Vec, MutableVecTrait, VecTrait};


    #[storage]
    pub struct Storage{

    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{

    }

    #[derive(Drop, starknet::Event)]
    pub struct UserRegisterd{
        user: ContractAddress,
        timestamp: u64, 
    }

    #[derive(Drop, starknet::Event)]
    pub struct UserBlacklisted{
        user: ContractAddress,
        timestamp: u64,
    }

    impl RegistryComponentImpl of IRegistry{

    }
} 