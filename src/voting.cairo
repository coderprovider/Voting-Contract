use starknet::ContractAddress;

#[starknet::interface]
trait IVoting<T> {
    fn register_voter(ref self: T, voter: ContractAddress) -> bool;
    fn add_candidate(ref self: T, name: felt252) -> bool;
    fn vote(ref self: T, candidate_index: u8);
    fn get_candidate(self: @T, index: u8) -> Voting::Candidate;
    fn get_candidate_vote(self: @T, index: u8) -> u32;
    fn check_voter_eligibility(self: @T, voter_address: ContractAddress) -> bool;
    fn winner(self: @T) -> Voting::Candidate;
}

#[starknet::contract]
mod Voting {
    use core::starknet::event::EventEmitter;
    use super::ContractAddress;
    use starknet::get_caller_address;

    #[storage]
    struct Storage {
        candidates: LegacyMap<u8, Candidate>,
        candidateId: u8,
        owner: ContractAddress,
        voters: LegacyMap<ContractAddress, Voter>
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Candidate {
        id: u8,
        name: felt252,
        vote_count: u32
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Voter {
        has_voted: bool,
        is_registered: bool,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        self.owner.write(initial_owner)
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        VoterRegistered: VoterRegistered,
        CandidateAdded: CandidateAdded,
        Voted: Voted,
    }

    #[derive(Drop, starknet::Event)]
    struct VoterRegistered {
        #[key]
        addr: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CandidateAdded {
        #[key]
        id: u8,
        #[key]
        name: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Voted {
        #[key]
        voted_id: u8,
        voter_address: ContractAddress,
    }

    #[abi(embed_v0)]
    impl VotingImpl of super::IVoting<ContractState> {
        // register voter
        fn register_voter(ref self: ContractState, voter: ContractAddress) -> bool {
            self.only_owner();

            let already_registered: bool = self.voters.read(voter).is_registered;
            assert(!already_registered, 'Already registered');

            let voter_data = Voter { has_voted: false, is_registered: true };

            self.voters.write(voter, voter_data);
            //event
            self.emit(VoterRegistered { addr: voter });
            true
        }

        //add candidate
        fn add_candidate(ref self: ContractState, name: felt252) -> bool {
            self.only_owner();

            let id = self.candidateId.read();
            let current_candidate_id = id + 1;

            let candidate_data = Candidate { id: current_candidate_id, name: name, vote_count: 0 };
            self.candidates.write(current_candidate_id, candidate_data);

            self.candidateId.write(current_candidate_id);

            //event
            self.emit(CandidateAdded { id: current_candidate_id, name: name });

            true
        }

        //vote
        fn vote(ref self: ContractState, candidate_index: u8) {
            //check if registered
            let user_address = get_caller_address();
            let check_registered = self.voters.read(user_address).is_registered;
            assert(check_registered, 'Not registered');

            //check whether user has voted already
            let check_has_voted = self.voters.read(user_address).has_voted;
            assert(!check_has_voted, 'Already voted');

            //allow voting
            let mut candidate = self.candidates.read(candidate_index);
            candidate.vote_count += 1;
            self.candidates.write(candidate_index, candidate);

            //update voter's data
            let mut voter = self.voters.read(user_address);
            voter.has_voted = true;
            self.voters.write(user_address, voter);

            //event
            self.emit(Voted { voted_id: candidate_index, voter_address: user_address });
        }

        //get candidate by index
        fn get_candidate(self: @ContractState, index: u8) -> Candidate {
            let candidate = self.candidates.read(index);
            candidate
        }

        //get candidate's vote
        fn get_candidate_vote(self: @ContractState, index: u8) -> u32 {
            let candidate_vote = self.candidates.read(index).vote_count;
            candidate_vote
        }

        //check if voter has VoterRegistered
        fn check_voter_eligibility(self: @ContractState, voter_address: ContractAddress) -> bool {
            let voter_is_registered = self.voters.read(voter_address).is_registered;
            voter_is_registered
        }

        //winning candidate 
        fn winner(self: @ContractState) -> Candidate {
            let mut highest_votes = 0;
            let mut winning_candidate = Option::None;

            let total_candidates = self.candidateId.read();
            let mut index: u8 = 1;

            while index < total_candidates
                + 1 {
                    let candidate = self.candidates.read(index);
                    if candidate.vote_count > highest_votes {
                        highest_votes = candidate.vote_count;
                        winning_candidate = Option::Some(candidate);
                    }
                    index += 1;
                };

            match winning_candidate {
                Option::Some(candidate) => candidate,
                Option::None => panic!("No candidates found"),
            }
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'Not the owner');
        }
    }
}
