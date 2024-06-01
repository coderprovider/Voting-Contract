# Voting Smart Contract

This repository contains the source code for a Voting smart contract written in Cairo, specifically for the Starknet blockchain.

## Overview

The Voting smart contract allows users to register as voters, add candidates, and vote for their preferred candidates. It ensures secure and transparent voting, preventing double voting and allowing only registered voters to participate.

### Contract Address
Deployed to starknet with the contract address - [0x065305b233e56dd71946a51b41b3cf8a02486310cd796cd620906f3eb9289b2f](https://sepolia.starkscan.co/contract/0x065305b233e56dd71946a51b41b3cf8a02486310cd796cd620906f3eb9289b2f)

### Features

- **Voter Registration**: Only the contract owner can register voters.
- **Candidate Addition**: Only the contract owner can add new candidates.
- **Voting**: Registered voters can vote for their preferred candidates.
- **Results**: Retrieve the candidate with the highest votes.

## Contract Structure

### Storage

- `candidates`: A mapping from candidate ID to `Candidate` struct.
- `candidateId`: A counter for the total number of candidates.
- `owner`: The address of the contract owner.
- `voters`: A mapping from voter address to `Voter` struct.

### Structs

- **Candidate**: Represents a candidate with an ID, name, and vote count.
  ```rust
  #[derive(Drop, Serde, starknet::Store)]
  pub struct Candidate {
      id: u8,
      name: felt252,
      vote_count: u32
  }
  ```
- **Voter**: Represents a voter with `has_voted` and `is_registered` flags.
  ```rust
  #[derive(Drop, Serde, starknet::Store)]
  pub struct Voter {
      has_voted: bool,
      is_registered: bool,
  }
  ```

## Functions

### Public Interface

#### `register_voter(voter: ContractAddress) -> bool`
Registers a new voter. Only the contract owner can call this function.

#### `add_candidate(name: felt252) -> bool`
Adds a new candidate. Only the contract owner can call this function.

#### `vote(candidate_index: u8)`
Allows a registered voter to vote for a candidate by index.

#### `get_candidate(index: u8) -> Candidate`
Retrieves candidate details by index.

#### `get_candidate_vote(index: u8) -> u32`
Gets the vote count of a candidate by index.

#### `check_voter_eligibility(voter_address: ContractAddress) -> bool`
Checks if a voter is registered.

#### `winner() -> Candidate`
Returns the candidate with the highest number of votes.

### Private Functions

#### `only_owner()`
Asserts that the caller is the contract owner.

## Events

### `VoterRegistered`

- `addr`: The address of the registered voter.

### `CandidateAdded`

- `id`: The ID of the added candidate.
- `name`: The name of the added candidate.

### `Voted`

- `voted_id`: The ID of the candidate voted for.
- `voter_address`: The address of the voter.

## Usage

### Deployment

1. Deploy the contract to the Starknet blockchain.
2. Set the initial owner during contract deployment.

### Registering Voters

Only the owner can register voters using the `register_voter` function.

### Adding Candidates

Only the owner can add candidates using the `add_candidate` function.

### Voting

Registered voters can vote for candidates using the `vote` function. A voter can only vote once.

### Checking Results

- Use `get_candidate` to get candidate details.
- Use `get_candidate_vote` to get the vote count of a candidate.
- Use `winner` to get the candidate with the highest votes.

## Example

Here's an example of how to use the contract:

```rust
// Deploy the contract and set the initial owner
let contract = Voting::deploy(initial_owner);

// Register voters
contract.register_voter(voter_address);

// Add candidates
contract.add_candidate("Candidate 1");
contract.add_candidate("Candidate 2");

// Voting
contract.vote(1); // Vote for candidate 1
contract.vote(2); // Vote for candidate 2

// Check results
let candidate1 = contract.get_candidate(1);
let votes_candidate1 = contract.get_candidate_vote(1);
let winner = contract.winner();
```

## License

This project is licensed under the MIT License.
