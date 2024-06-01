use snforge_std::{
    declare, ContractClassTrait, cheat_caller_address, CheatSpan, spy_events, SpyOn, EventSpy,
    EventAssertions
};
use voting::IVotingTraitDispatcher;
use voting::IVotingTraitDispatcherTrait;
use voting::Voting;
use starknet::ContractAddress;
use core::traits::TryInto;


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let admin_address: ContractAddress = 'admin'.try_into().unwrap();
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@array![admin_address.into()]).unwrap();
    contract_address
}
