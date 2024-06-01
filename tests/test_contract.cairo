use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, start_cheat_caller_address,
    stop_cheat_caller_address, CheatSpan, spy_events, SpyOn, EventSpy, EventAssertions
};
use voting::voting::Voting;
use voting::voting::IVotingDispatcherTrait;
use voting::voting::IVotingDispatcher;
use starknet::ContractAddress;
use core::traits::TryInto;


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let admin_address: ContractAddress = 'admin'.try_into().unwrap();
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@array![admin_address.into()]).unwrap();
    contract_address
}

#[test]
fn test_initial_owner() {
    let admin_address: ContractAddress = 'admin'.try_into().unwrap();
    let contract_address = deploy_contract("Voting");
    let dispatcher = IVotingDispatcher { contract_address };

    let initial_owner = dispatcher.get_owner();

    assert(initial_owner == admin_address, 'incorrect admin');
}

#[test]
fn test_for_voter_registration() {
    let admin_address: ContractAddress = 'admin'.try_into().unwrap();
    let contract_address = deploy_contract("Voting");
    let dispatcher = IVotingDispatcher { contract_address };

    cheat_caller_address(contract_address, admin_address, CheatSpan::Indefinite);
    let first_voter: ContractAddress = 'first_voter'.try_into().unwrap();

    let is_registered = dispatcher.register_voter(first_voter);

    assert(is_registered, 'Did not registered');
}

#[test]
fn test_for_candidate_registration() {
    let admin_address: ContractAddress = 'admin'.try_into().unwrap();
    let contract_address = deploy_contract("Voting");
    let dispatcher = IVotingDispatcher { contract_address };

    cheat_caller_address(contract_address, admin_address, CheatSpan::Indefinite);
    let candidate_name: felt252 = 'Peter Obi';

    let has_added = dispatcher.add_candidate(candidate_name);
    assert(has_added, 'Did not add');
}

#[test]
fn test_for_voting() {
    let admin_address: ContractAddress = 'admin'.try_into().unwrap();
    let contract_address = deploy_contract("Voting");
    let dispatcher = IVotingDispatcher { contract_address };

    start_cheat_caller_address(contract_address, admin_address);

    let first_voter: ContractAddress = 'first_voter'.try_into().unwrap();
    let is_registered = dispatcher.register_voter(first_voter);
    assert(is_registered, 'Did not registered');

    let candidate_name: felt252 = 'Peter Obi';
    let has_added = dispatcher.add_candidate(candidate_name);
    assert(has_added, 'Did not add');

    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, first_voter);

    let has_voted = dispatcher.vote(1);
    assert(has_voted, 'Voting not proccessed');
}
