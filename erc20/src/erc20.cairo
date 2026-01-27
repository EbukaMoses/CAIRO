#[starknet::contract]
mod EbuksToken {
    use openzeppelin_token::erc20::{ERC20Component, ERC20HooksEmptyImpl};
    use starknet::ContractAddress;
    
    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    
    // ERC20 Mixin
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;
    
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }
    
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }
    
    #[constructor]
    fn constructor(
        ref self: ContractState,
        recipient: ContractAddress
    ) {
        let name = "EbuksToken";
        let symbol = "EBUKS";
        let initial_supply: u256 = 1000000_u256 * 1000000000000000000_u256; 
        
        self.erc20.initializer(name, symbol);
        self.erc20.mint(recipient, initial_supply);
    }
}