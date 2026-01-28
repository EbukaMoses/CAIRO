use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, start_cheat_caller_address, stop_cheat_caller_address};

use voting_contract::IVotingContractDispatcher;
use voting_contract::IVotingContractDispatcherTrait;
use voting_contract::IVotingContractSafeDispatcher;
use voting_contract::IVotingContractSafeDispatcherTrait;
use voting_contract::ElectionState;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@ArrayTrait::new()).unwrap();
    contract_address
}

fn get_voter_address(id: felt252) -> ContractAddress {
    id.try_into().unwrap()
}

#[test]
fn test_add_candidate() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Initially no candidates
    assert(dispatcher.get_candidate_count() == 0, 'Should have 0 candidates');
    
    // Add a candidate
    dispatcher.add_candidate(1);
    
    assert(dispatcher.get_candidate_count() == 1, 'Should have 1 candidate');
    assert(dispatcher.candidate_exists(1), 'Candidate 1 should exist');
}

#[test]
fn test_manual_start_election() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Add candidates (less than 5 so it doesn't auto-start)
    dispatcher.add_candidate(1);
    dispatcher.add_candidate(2);
    dispatcher.add_candidate(3);
    
    // Election should not be started yet
    assert(dispatcher.get_election_state() == ElectionState::NotStarted, 'Should be NotStarted');
    
    // Start election manually
    dispatcher.start_election();
    
    assert(dispatcher.get_election_state() == ElectionState::Ongoing, 'Should be Ongoing');
}

#[test]
fn test_auto_start_at_5_candidates() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Add 4 candidates - should not auto-start
    dispatcher.add_candidate(1);
    dispatcher.add_candidate(2);
    dispatcher.add_candidate(3);
    dispatcher.add_candidate(4);
    
    assert(dispatcher.get_election_state() == ElectionState::NotStarted, 'Should be NotStarted');
    
    // Add 5th candidate - should auto-start
    dispatcher.add_candidate(5);
    
    assert(dispatcher.get_election_state() == ElectionState::Ongoing, 'Should auto-start at 5');
    assert(dispatcher.get_candidate_count() == 5, 'Should have 5 candidates');
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_add_candidate_during_election() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    let safe_dispatcher = IVotingContractSafeDispatcher { contract_address };
    
    // Add candidates and start election
    dispatcher.add_candidate(1);
    dispatcher.add_candidate(2);
    dispatcher.start_election();
    
    // Try to add candidate during election - should fail
    match safe_dispatcher.add_candidate(3) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Cannot add during election', *panic_data.at(0));
        }
    };
}

#[test]
fn test_vote_for_candidate() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Setup: Add candidates and start election
    dispatcher.add_candidate(1);
    dispatcher.add_candidate(2);
    dispatcher.start_election();
    
    let voter1 = get_voter_address(100);
    let voter2 = get_voter_address(200);
    
    // Vote as voter1
    start_cheat_caller_address(contract_address, voter1);
    dispatcher.vote(1);
    stop_cheat_caller_address(contract_address);
    
    // Vote as voter2
    start_cheat_caller_address(contract_address, voter2);
    dispatcher.vote(1);
    stop_cheat_caller_address(contract_address);
    
    // Check votes
    assert(dispatcher.get_candidate_votes(1) == 2, 'Candidate 1 should have 2 votes');
    assert(dispatcher.get_candidate_votes(2) == 0, 'Candidate 2 should have 0 votes');
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_vote_twice() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    let safe_dispatcher = IVotingContractSafeDispatcher { contract_address };
    
    // Setup
    dispatcher.add_candidate(1);
    dispatcher.start_election();
    
    let voter = get_voter_address(100);
    
    // First vote
    start_cheat_caller_address(contract_address, voter);
    dispatcher.vote(1);
    
    // Second vote should fail
    match safe_dispatcher.vote(1) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Already voted', *panic_data.at(0));
        }
    };
    stop_cheat_caller_address(contract_address);
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_vote_before_election_starts() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    let safe_dispatcher = IVotingContractSafeDispatcher { contract_address };
    
    dispatcher.add_candidate(1);
    // Don't start election
    
    let voter = get_voter_address(100);
    start_cheat_caller_address(contract_address, voter);
    
    match safe_dispatcher.vote(1) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Election not ongoing', *panic_data.at(0));
        }
    };
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_end_election() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Setup and vote
    dispatcher.add_candidate(1);
    dispatcher.add_candidate(2);
    dispatcher.start_election();
    
    let voter = get_voter_address(100);
    start_cheat_caller_address(contract_address, voter);
    dispatcher.vote(1);
    stop_cheat_caller_address(contract_address);
    
    // End election
    dispatcher.end_election();
    
    assert(dispatcher.get_election_state() == ElectionState::Ended, 'Should be Ended');
}

#[test]
fn test_calculate_votes() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Setup
    dispatcher.add_candidate(10);
    dispatcher.add_candidate(20);
    dispatcher.add_candidate(30);
    dispatcher.start_election();
    
    // Cast votes
    let voter1 = get_voter_address(100);
    let voter2 = get_voter_address(200);
    let voter3 = get_voter_address(300);
    
    start_cheat_caller_address(contract_address, voter1);
    dispatcher.vote(10);
    stop_cheat_caller_address(contract_address);
    
    start_cheat_caller_address(contract_address, voter2);
    dispatcher.vote(20);
    stop_cheat_caller_address(contract_address);
    
    start_cheat_caller_address(contract_address, voter3);
    dispatcher.vote(20);
    stop_cheat_caller_address(contract_address);
    
    // Calculate votes
    let results = dispatcher.calculate_votes();
    
    assert(results.len() == 3, 'Should have 3 results');
    
    let (id1, votes1) = *results.at(0);
    let (id2, votes2) = *results.at(1);
    let (id3, votes3) = *results.at(2);
    
    assert(id1 == 10 && votes1 == 1, 'Candidate 10: 1 vote');
    assert(id2 == 20 && votes2 == 2, 'Candidate 20: 2 votes');
    assert(id3 == 30 && votes3 == 0, 'Candidate 30: 0 votes');
}

#[test]
fn test_get_winner() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    // Setup
    dispatcher.add_candidate(1);
    dispatcher.add_candidate(2);
    dispatcher.add_candidate(3);
    dispatcher.start_election();
    
    // Cast votes - candidate 2 wins with 2 votes
    let voter1 = get_voter_address(100);
    let voter2 = get_voter_address(200);
    let voter3 = get_voter_address(300);
    
    start_cheat_caller_address(contract_address, voter1);
    dispatcher.vote(2);
    stop_cheat_caller_address(contract_address);
    
    start_cheat_caller_address(contract_address, voter2);
    dispatcher.vote(2);
    stop_cheat_caller_address(contract_address);
    
    start_cheat_caller_address(contract_address, voter3);
    dispatcher.vote(1);
    stop_cheat_caller_address(contract_address);
    
    // End election and get winner
    dispatcher.end_election();
    
    let (winner_id, winner_votes) = dispatcher.get_winner();
    assert(winner_id == 2, 'Winner should be candidate 2');
    assert(winner_votes == 2, 'Winner should have 2 votes');
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_get_winner_before_election_ends() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    let safe_dispatcher = IVotingContractSafeDispatcher { contract_address };
    
    dispatcher.add_candidate(1);
    dispatcher.start_election();
    
    // Try to get winner while election is ongoing
    match safe_dispatcher.get_winner() {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Election not ended', *panic_data.at(0));
        }
    };
}

#[test]
fn test_has_voted() {
    let contract_address = deploy_contract("VotingContract");
    let dispatcher = IVotingContractDispatcher { contract_address };
    
    dispatcher.add_candidate(1);
    dispatcher.start_election();
    
    let voter = get_voter_address(100);
    
    // Before voting
    assert(!dispatcher.has_voted(voter), 'Should not have voted yet');
    
    // After voting
    start_cheat_caller_address(contract_address, voter);
    dispatcher.vote(1);
    stop_cheat_caller_address(contract_address);
    
    assert(dispatcher.has_voted(voter), 'Should have voted');
}
