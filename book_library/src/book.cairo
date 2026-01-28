use starknet::ContractAddress;
use starknet::storage::Array;

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book{
    book_id: u8,
    book_name: felt252,
    author: felt252,
    current_holder: ContractAddress,
    borrowed: bool,
}

pub trait IBook<TContractState>{
    fn add_book(ref self: TContractState, book_name: felt252, author: felt252);
    fn remove_book(ref self: TContractState, book_id: u8);
    fn borrow_book(ref self: TContractState, book_id: u8);
    fn return_book(ref self: TContractState, book_id: u8);
    fn is_borrowed(self: @TContractState, book_id: u8) -> bool;
    fn get_book(self: @TContractState, book_id: u8) -> Book;
    fn get_current_book_holder(self: @TContractState, book_id: u8) -> ContractAddress;
    fn get_all_books(self: @TContractState) -> Array<Book>;
    
}

#[starknet::contract]
pub mod Book{

    use super::{Book,  IBook};
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragepathEntry};

    #[storage]
    struct Storage{
        book: Map::<u8, Book>,
        librarian: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{
        BookAdded: BookAdded,
        BookRemoved: BookRemoved,
        BookBorrowed: BookBorrowed,
        BookReturned: BookReturned,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BookAdded{
        book_id: u8,
        book_name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    pub struct BookRemoved{
        book_id: u8,
    }
    
    #[derive(Drop, starknet::Event)]
    pub struct BookBorrowed{
        book_id: u8,
        borrower: ContractAddress,
    }
    
    #[derive(Drop, starknet::Event)]
    pub struct BookReturned{
        book_id: u8,
        borrower: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, librarian: ContractAddress){
        self.librarian.write(librarian);
    }

    #[abi(embed_v0)]
    impl BookImpl of IBook<ContractState>{
        fn add_book(ref self: ContractState, book_name: felt252, author: felt252){
            let book_id = self.book.len();
            self.book.write(book_id, Book{book_id, book_name, author, current_holder: ContractAddress::ZERO, borrowed: false});
        }
    }
}