use starknet::ContractAddress;
// use starknet::storage::Array;
use crate::types::Book;

#[starknet::interface]
pub trait ILibrary<TContractState>{
    fn add_book(ref self: TContractState, book_name: felt252, author: felt252, weight: u256);
    fn remove_book(ref self: TContractState, book_id: u8);
    fn borrow_book(ref self: TContractState, book_id: u8);
    fn return_book(ref self: TContractState, book_id: u8);
    fn is_borrowed(self: @TContractState, book_id: u8) -> bool;
    fn get_book(self: @TContractState, book_id: u8) -> Book;
    fn get_current_book_holder(self: @TContractState, book_id: u8) -> ContractAddress;
    fn get_all_books(self: @TContractState) -> Array<Book>;
    fn close_down_library(ref self: TContractState);
    
}

#[starknet::contract]
pub mod Library{
    // use starknet::syscalls::get_execution_info_syscall;
    use super::{Book, ILibrary, ContractAddress};
    use starknet::storage::{Map, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess};
    use starknet::{get_caller_address, get_contract_address};
    use crate::components::user_registration_component::RegistryComponent;
    use crate::contracts::factory::{IFactoryDispatcher, IFactoryDispatcherTrait};

    #[storage]
    struct Storage{
        books: Map::<u8, Book>,
        librarian: ContractAddress,
        book_count: u8,
        #[substorage(v0)]
        registry: RegistryComponent::Storage,
        factory: ContractAddress,
    }

    component!(path: RegistryComponent, storage: registry, event: RegistryEvent);

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event{
        BookAdded: BookAdded,
        BookRemoved: BookRemoved,
        BookBorrowed: BookBorrowed,
        BookReturned: BookReturned,
        #[flat]
        RegistryEvent: RegistryComponent::Event,
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
    fn constructor(ref self: ContractState, librarian: ContractAddress, user_weight: u256){
        self.librarian.write(librarian);
        self.book_count.write(0);
        self.registry.initializer(user_weight);
    }

    impl RegistryImpl = RegistryComponent::RegistryImpl<ContractState>;

    impl RegistryInternalImpl = RegistryComponent::InternalFunctions<ContractState>;

    #[abi(embed_v0)]
    impl LibraryImpl of ILibrary<ContractState>{

        fn add_book(ref self: ContractState, book_name: felt252, author: felt252, weight: u256){
            let caller = get_caller_address();
            let librarian = self.librarian.read();
            assert(caller == librarian, 'Only librarian can add books');
            let book_id = self.book_count.read() + 1;

            let new_book = Book{
                book_id: book_id, 
                book_name,
                author, 
                current_holder: librarian, 
                borrowed: false,
                deleted: false,
                weight,
            };

            self.books.entry(book_id).write(new_book); // or self.books.write(book_id, new_book) or self.book.write(book_id, Book{book_id, book_name, author, current_holder: ContractAddress::ZERO, borrowed: false});
            self.book_count.write(book_id);

            self.emit(
                BookAdded{
                    book_name,
                    book_id,
                }
            )
            
        }

        fn remove_book(ref self: ContractState, book_id: u8){
            let caller = get_caller_address();
            let librarian = self.librarian.read();
            assert(caller != librarian, 'Caller not permitted');

            let mut book = self.books.entry(book_id).read();
            assert(book.author != 0, 'Book does not exit');
            assert(book.current_holder == librarian, 'Book not available');

            book.deleted = true;

            self.books.entry(book_id).write(book);

            self.emit(
                BookRemoved{
                    book_id,
                }
            )
        }

        fn borrow_book(ref self: ContractState, book_id: u8){
            let borrower = get_caller_address();
            let user_registered = self.registry.is_user_registered();
            assert(user_registered, 'User not registered');

            // TODO: assert that user has enough weight
            // TODO: if user has enough weight, deduct the weight from the user
            // TODO: if user does not have enough weight, revert the transaction
            // TODO: emit an event for the user consuming weight
            // TODO: emit an event for the book being borrowed
            // TODO: emit an event for the book being borrowed
            
            let mut book = self.books.entry(book_id).read();

            assert(!book.deleted, 'Book has been deleted');
            assert(book.book_name != 0, 'Book does not exit');
            assert(!book.borrowed, 'Book has being Borrowed');

            book.current_holder = borrower;
            book.borrowed = true;

            self.books.entry(book_id).write(book);

            self.emit(
                BookBorrowed{
                    book_id,
                    borrower,
                }
            )

        }

        fn return_book(ref self: ContractState, book_id: u8){
            let caller =  get_caller_address();
            let mut book = self.books.entry(book_id).read();

            assert(book.book_name != 0, 'Book does not exit');
            assert(book.current_holder == caller, 'Not current holder');

            book.current_holder = self.librarian.read();
            book.borrowed = false;


            self.books.entry(book_id).write(book);

            self.emit(
                BookReturned{
                    book_id,
                    borrower: caller,
                }
            )

        }

        fn is_borrowed(self: @ContractState, book_id: u8) -> bool{
            let book = self.books.entry(book_id).read();

            book.borrowed
        }


        fn get_current_book_holder(self: @ContractState, book_id: u8) -> ContractAddress{
            let book = self.books.entry(book_id).read();

            book.current_holder
        }

        fn get_book(self: @ContractState, book_id: u8) -> Book{
            let book = self.books.entry(book_id).read();

            assert(book.book_name != 0, 'Book doesnt exist');
            assert(!book.deleted,  'Book deleted');

            book

        }


        fn get_all_books(self: @ContractState) -> Array<Book>{
            let mut book_array = array![];

            for i in 1..=self.book_count.read() {
                let current_book = self.books.entry(i).read();

                if !current_book.deleted{
                    
                    book_array.append(current_book);
                }
            }

            book_array
        }

        fn close_down_library(ref self: ContractState){
            let library_address = get_contract_address();
            let factory_dispatcher = IFactoryDispatcher { contract_address: self.factory.read() };
            factory_dispatcher.close_library(library_address);
        }

    }
}