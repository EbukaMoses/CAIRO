use starknet::ContractAddress;

/// Enum representing the state of an election
#[derive(Drop, Serde, starknet::Store, PartialEq, Copy)]
pub enum ElectionState {
    #[default]
    NotStarted,
    Ongoing,
    Ended,
}

/// Struct representing a candidate
#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct Candidate {
    pub id: u32,
    pub vote_count: u32,
}

/// Interface for the Voting Contract
#[starknet::interface]
pub trait IVotingContract<TContractState> {
    /// Start the election manually
    fn start_election(ref self: TContractState);
    
    /// End the election
    fn end_election(ref self: TContractState);
    
    /// Get votes for a specific candidate
    fn get_candidate_votes(self: @TContractState, candidate_id: u32) -> u32;
    
    /// Get all votes (returns array of vote counts for all candidates)
    fn calculate_votes(self: @TContractState) -> Array<(u32, u32)>;
    
    /// Add a new candidate
    fn add_candidate(ref self: TContractState, candidate_id: u32);
    
    /// Vote for a candidate
    fn vote(ref self: TContractState, candidate_id: u32);
    
    /// Get current election state
    fn get_election_state(self: @TContractState) -> ElectionState;
    
    /// Get the number of candidates
    fn get_candidate_count(self: @TContractState) -> u32;
    
    /// Check if a candidate exists
    fn candidate_exists(self: @TContractState, candidate_id: u32) -> bool;
    
    /// Check if a voter has already voted
    fn has_voted(self: @TContractState, voter: ContractAddress) -> bool;
    
    /// Get the winning candidate (only after election ends)
    fn get_winner(self: @TContractState) -> (u32, u32);
}

/// Voting Contract implementation
#[starknet::contract]
mod VotingContract {
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess,
        Map, StoragePathEntry
    };
    use starknet::{ContractAddress, get_caller_address};
    use super::{ElectionState, Candidate};

    const MAX_CANDIDATES_AUTO_START: u32 = 5;

    #[storage]
    struct Storage {
        // Election state
        election_state: ElectionState,
        
        // Candidate storage
        candidate_count: u32,
        candidates: Map<u32, Candidate>,         // candidate_id -> Candidate
        candidate_exists: Map<u32, bool>,        // candidate_id -> exists
        candidate_ids: Map<u32, u32>,            // index -> candidate_id (for iteration)
        
        // Voter tracking
        has_voted: Map<ContractAddress, bool>,   // voter address -> has voted
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ElectionStarted: ElectionStarted,
        ElectionEnded: ElectionEnded,
        CandidateAdded: CandidateAdded,
        VoteCast: VoteCast,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ElectionStarted {
        pub candidate_count: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ElectionEnded {
        pub total_candidates: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CandidateAdded {
        pub candidate_id: u32,
        pub total_candidates: u32,
    }

    #[derive(Drop, starknet::Event)]
    pub struct VoteCast {
        pub voter: ContractAddress,
        pub candidate_id: u32,
    }

    #[abi(embed_v0)]
    impl VotingContractImpl of super::IVotingContract<ContractState> {
        /// Start the election manually
        fn start_election(ref self: ContractState) {
            let current_state = self.election_state.read();
            assert(current_state == ElectionState::NotStarted, 'Election already started');
            
            let candidate_count = self.candidate_count.read();
            assert(candidate_count > 0, 'No candidates added');
            
            self.election_state.write(ElectionState::Ongoing);
            
            self.emit(ElectionStarted { candidate_count });
        }
        
        /// End the election
        fn end_election(ref self: ContractState) {
            let current_state = self.election_state.read();
            assert(current_state == ElectionState::Ongoing, 'Election not ongoing');
            
            self.election_state.write(ElectionState::Ended);
            
            self.emit(ElectionEnded { total_candidates: self.candidate_count.read() });
        }
        
        /// Get votes for a specific candidate
        fn get_candidate_votes(self: @ContractState, candidate_id: u32) -> u32 {
            assert(self.candidate_exists.entry(candidate_id).read(), 'Candidate does not exist');
            self.candidates.entry(candidate_id).read().vote_count
        }
        
        /// Calculate and return all votes (only when election is ongoing or ended)
        fn calculate_votes(self: @ContractState) -> Array<(u32, u32)> {
            let current_state = self.election_state.read();
            assert(
                current_state == ElectionState::Ongoing || current_state == ElectionState::Ended,
                'Election not started'
            );
            
            let mut results: Array<(u32, u32)> = ArrayTrait::new();
            let candidate_count = self.candidate_count.read();
            
            let mut i: u32 = 0;
            while i < candidate_count {
                let candidate_id = self.candidate_ids.entry(i).read();
                let candidate = self.candidates.entry(candidate_id).read();
                results.append((candidate_id, candidate.vote_count));
                i += 1;
            };
            
            results
        }
        
        /// Add a new candidate (only before election starts)
        fn add_candidate(ref self: ContractState, candidate_id: u32) {
            let current_state = self.election_state.read();
            assert(current_state == ElectionState::NotStarted, 'Cannot add during election');
            assert(!self.candidate_exists.entry(candidate_id).read(), 'Candidate already exists');
            
            // Create new candidate with 0 votes
            let new_candidate = Candidate {
                id: candidate_id,
                vote_count: 0,
            };
            
            // Store the candidate
            let current_count = self.candidate_count.read();
            self.candidates.entry(candidate_id).write(new_candidate);
            self.candidate_exists.entry(candidate_id).write(true);
            self.candidate_ids.entry(current_count).write(candidate_id);
            self.candidate_count.write(current_count + 1);
            
            self.emit(CandidateAdded { 
                candidate_id, 
                total_candidates: current_count + 1 
            });
            
            // Auto-start election when 5 candidates are added
            if current_count + 1 == MAX_CANDIDATES_AUTO_START {
                self.election_state.write(ElectionState::Ongoing);
                self.emit(ElectionStarted { candidate_count: MAX_CANDIDATES_AUTO_START });
            }
        }
        
        /// Vote for a candidate (only during ongoing election)
        fn vote(ref self: ContractState, candidate_id: u32) {
            let current_state = self.election_state.read();
            assert(current_state == ElectionState::Ongoing, 'Election not ongoing');
            assert(self.candidate_exists.entry(candidate_id).read(), 'Candidate does not exist');
            
            let caller = get_caller_address();
            assert(!self.has_voted.entry(caller).read(), 'Already voted');
            
            // Mark voter as having voted
            self.has_voted.entry(caller).write(true);
            
            // Increment candidate's vote count
            let mut candidate = self.candidates.entry(candidate_id).read();
            candidate.vote_count += 1;
            self.candidates.entry(candidate_id).write(candidate);
            
            self.emit(VoteCast { voter: caller, candidate_id });
        }
        
        /// Get current election state
        fn get_election_state(self: @ContractState) -> ElectionState {
            self.election_state.read()
        }
        
        /// Get the number of candidates
        fn get_candidate_count(self: @ContractState) -> u32 {
            self.candidate_count.read()
        }
        
        /// Check if a candidate exists
        fn candidate_exists(self: @ContractState, candidate_id: u32) -> bool {
            self.candidate_exists.entry(candidate_id).read()
        }
        
        /// Check if a voter has already voted
        fn has_voted(self: @ContractState, voter: ContractAddress) -> bool {
            self.has_voted.entry(voter).read()
        }
        
        /// Get the winning candidate (only after election ends)
        fn get_winner(self: @ContractState) -> (u32, u32) {
            let current_state = self.election_state.read();
            assert(current_state == ElectionState::Ended, 'Election not ended');
            
            let candidate_count = self.candidate_count.read();
            assert(candidate_count > 0, 'No candidates');
            
            let mut winner_id: u32 = 0;
            let mut max_votes: u32 = 0;
            
            let mut i: u32 = 0;
            while i < candidate_count {
                let candidate_id = self.candidate_ids.entry(i).read();
                let candidate = self.candidates.entry(candidate_id).read();
                if candidate.vote_count > max_votes {
                    max_votes = candidate.vote_count;
                    winner_id = candidate_id;
                }
                i += 1;
            };
            
            (winner_id, max_votes)
        }
    }
}
