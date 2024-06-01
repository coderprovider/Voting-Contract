use starknet::ContractAddress;

#[starknet::interface]
trait IVoting<T> {
    fn register_voter(ref self: T, voter: ContractAddress) -> bool;
    fn add_candidate(ref self: T, name: felt252) -> bool;
    fn vote(ref self: T, candidate_index: u8);
    fn get_candidates(self: @T) -> u8;
    fn get_candidate_vote(self: @T, index: u8);
    fn winner(self: @T);
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
