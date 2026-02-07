use starknet::ContractAddress;

#[starknet::interface]
pub trait IRegistry<TContractState>{
    fn register_use(ref self: TContractState, user_fname: felt252, user_lname: felt252);
    fn is_user_registered(self: @TContractState)-> bool;  
    fn blacklist_user(ref self: TContractState, user_id: u8);
    fn get_user_weight(self: @TContractState, address: ContractAddress) -> u256;
    fn use_weight(ref self: TContractState, address: ContractAddress, weight: u256);
}

#[starknet::component]
pub mod RegistryComponent{
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use starknet::storage::{Map, StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Vec, MutableVecTrait, VecTrait};
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use crate::types::User;
    use super::IRegistry;
   
    #[storage]
    pub struct Storage{
        pub users: Map::<ContractAddress, User>,
        pub user_count: u8,
        pub user_weight: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{
        UserRegisterd: UserRegisterd,
        UserBlacklisted: UserBlacklisted,
        ERC20Event: ERC20Component::Event,
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

    //TODO EVENT FOR USER CONSUMING WEIGHT

    #[embeddable_as(RegistryImpl)]
    impl RegistryComponentImpl<
    TContractState, +HasComponent<TContractState>
    > of IRegistry<ComponentState<TContractState>>{

         fn register_use(ref self: ComponentState<TContractState>, user_fname: felt252, user_lname: felt252){
            let user_address = get_caller_address();
            let user_id = self.user_count.read() + 1;

            let user = User{
                id: user_id,
                // address: user_address,
                fname: user_fname,
                lname: user_lname,
                total_weight: self.user_weight.read(),
                used_weight: 0,
            };

            self.users.entry(user_address).write(user);

            self.emit(
                UserRegisterd{
                    user: user_address,
                    timestamp: get_block_timestamp(),
                }
            )
         }

        fn is_user_registered(self: @ComponentState<TContractState>) -> bool {
            let user_address = get_caller_address();
            let user = self.users.entry(user_address).read();

            if user == Default::default(){
                false
            }else{
                true
            }
        }  

        fn blacklist_user(ref self: ComponentState<TContractState>, user_id: u8){
            
        }

        fn get_user_weight(self: @ComponentState<TContractState>, address: ContractAddress ) -> u256 {
            let user = self.users.entry(address).read();
            // if user == Default::default(){
            //     0
            // }else{
            //     user.total_weight
            // }
            user.total_weight - user.used_weight
        }

        fn use_weight(ref self: ComponentState<TContractState>, address: ContractAddress, weight: u256){
            let mut user = self.users.entry(address).read();
            user.used_weight += weight;
            self.users.entry(address).write(user);
        }

    }

    #[generate_trait]
    pub impl InternalFunctions<
    TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState>{
        fn initializer(ref self: ComponentState<TContractState>, user_weight: u256){
            self.user_weight.write(user_weight);
            self.user_count.write(0);
        }
    }
} 