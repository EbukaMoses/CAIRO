#[starknet::interface]
pub trait ICounter<TContractState>{
    fn increment(ref self: TContractState, increment_value: u8);
    fn decrement(ref self: TContractState, decrement_value: u8);
    fn get_count(self: @TContractState) -> u8;
}

#[starknet::contract]
pub mod Counter{
    use starknet::event::EventEmitter;
use starknet::{ContractAddress, get_caller_address};
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    use super::ICounter;
    
#[storage]
    struct Storage{
        count: u8,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{
        Incremented: Incremented,
        Decremented: Decremented,
    }

    #[derive(Drop, starknet::Event)]
    struct Incremented {
        increment_value: u8,
        caller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct Decremented {
        decrement_value: u8,
        caller: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_count: u8){
        self.count.write(initial_count);
    }

    #[abi(embed_v0)]
    impl CounterImpl of ICounter<ContractState>{
        fn increment(ref self: ContractState, increment_value: u8){
            let caller = get_caller_address();
            let mut current_count =  self.count.read();
            current_count += increment_value;
            self.count.write(current_count);

            self.emit(
                Incremented {
                    increment_value,
                    caller,
                }
            )
        }

        fn decrement(ref self: ContractState, decrement_value: u8){
            let caller = get_caller_address();
            let mut current_count = self.count.read();
            assert(current_count >= decrement_value, 'Count cannot be negative');
            current_count -= decrement_value;
            self.count.write(current_count);

            self.emit(
                Decremented {
                    decrement_value,
                    caller,
                }
            )
        }

        fn get_count(self: @ContractState) -> u8{
            self.count.read()
        }
    }
}