use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book{
    book_id: u8,
    book_name: felt252,
    author: felt252,
    publisher: felt252,
    year: u64,
    isbn: felt252,
    genre: felt252,
    current_holder: ContractAddress, 
    borrowed: bool,
}


#[starknet::interface]
pub trait IBookLibrary<TContractState>{
    fn add_book(ref self: TContractState, book_name: felt252, author: felt252, publisher: felt252, year: u64, isbn: felt252, genre: felt252);
    fn remove_book(ref self: TContractState, book_id: u8);
    fn borrow_book(ref self: TContractState, book_id: u8);
    fn return_book(ref self: TContractState, book_id: u8);
    fn get_book(self: @TContractState, book_id: u8) -> Book;
    fn get_current_book_holder(self: @TContractState, book_id: u8) -> ContractAddress;
    fn get_all_books(self: @TContractState) -> Array<Book>;
    fn get_book_by_id(self: @TContractState, book_id: u8) -> Book;
    fn get_book_by_title(self: @TContractState, book_title: felt252) -> Book;
    fn get_book_by_author(self: @TContractState, book_author: felt252) -> Book;
    fn get_book_by_publisher(self: @TContractState, book_publisher: felt252) -> Book;
    fn get_book_by_year(self: @TContractState, book_year: u64) -> Book;
    fn get_book_by_isbn(self: @TContractState, book_isbn: felt252) -> Book;
    fn get_book_by_genre(self: @TContractState, book_genre: felt252) -> Book;
}

#[starknet::contract]
mod BookLibrary{
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess, StoragePointerWriteAccess};
    use super::IBookLibrary;
    use array::ArrayTrait;

    #[storage]
    struct Storage{
        books: Array<Book>,
        book_holders: Map<u8, ContractAddress>,
    }

    #[abi(embed_v0)]
    impl BookLibraryImpl of IBookLibrary<ContractState>{
        fn add_book(ref self: ContractState, book_name: felt252, author: felt252, publisher: felt252, year: u64, isbn: felt252, genre: felt252){
            self.books.append(Book{book_id: self.books.len() as u8, book_name, author, publisher, year, isbn, genre, current_holder: ContractAddress::ZERO, borrowed: false});
        }
    }
}