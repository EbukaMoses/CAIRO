use starknet::ContractAddress;

#[starknet::interface]
pub trait IFactory<TContractState>{
    fn deploy_library(ref self: TContractState, librarian: ContractAddress, user_weight: u256);
    fn close_library(ref self: TContractState, address: ContractAddress);
}

#[starknet::contract]
pub mod Factory{
    use starknet::SyscallResultTrait;
    use super::{IFactory, ContractAddress};
    use starknet::storage::{Vec, StoragePointerReadAccess, MutableVecTrait};
    use starknet::syscalls::deploy_syscall;
    use starknet::{ClassHash, get_block_timestamp};

    #[storage]
    struct Storage{
        libraries: Vec::<ContractAddress>,
        library_class_hash: ClassHash,
        close_libraries: Vec<ContractAddress>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{
        LibraryDeployed: LibraryDeployed,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LibraryDeployed{
        library: ContractAddress,
        timestamp: u64,
    }

    #[constructor]
    fn constructor(ref self: ContractState){
        // self.libraries.initializer();
    }

    #[abi(embed_v0)]
    impl FactoryImpl of IFactory<ContractState>{
        fn deploy_library(ref self: ContractState, librarian: ContractAddress, user_weight: u256){
            let library_class_hash = self.library_class_hash.read();
            let mut constructor_calldata = array![];

            librarian.serialize(ref constructor_calldata);
            user_weight.serialize(ref constructor_calldata);

            let deploy_result = deploy_syscall(library_class_hash, 1, constructor_calldata.span(), false);
            
            let (library_address, _) = deploy_result.unwrap_syscall();

            self.libraries.push(library_address);

            self.emit(
                LibraryDeployed{
                    library: library_address, 
                    timestamp: get_block_timestamp()
                }
            );
        }

        fn close_library(ref self: ContractState, address: ContractAddress){
            self.close_libraries.push(address);
        }
    }
}