# Blockchain Paws Platform

## About the Project

This project allows users to buy a cute pet from our branches and mint NFT for buying a pet. The NFT will be used to track the pet info and all related data for a particular pet corresponding to their token ids.
Pet Owner can also Bridge their NFT from one chain to another chain via [`Chainlink CCIP`](https://docs.chain.link/ccip).

The codebase is broken up into 2 contracts (In Scope):

- `PawsConnect.sol`
- `PawsBridge.sol`

## PawsConnect

This contract allows users to buy a cute pet from our branches and mint NFT for buying a pet. The NFT will be used to track the pet info and all related data for a particular pet corresponding to their token ids.

## PawsBridge

This contract allows users to bridge their Paws NFT from one chain to another chain via [`Chainlink CCIP`](https://docs.chain.link/ccip).

## Roles in the Project:

1. Pet Owner
   - User who buys the pet from our branches and mint NFT for buying a pet.
2. Shop Partner
   - Shop partner provide services to the pet owner to buy pet.
3. PawsConnect Owner
   - Owner of the contract who can transfer the ownership of the contract to another address.

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

## Quickstart

```bash
git clone https://github.com/TrustBytes/example_smart_contracts.git
cd example_smart_contracts
make
```

# How this Project Works
## Buying a Pet
A user is required to visit our shop partner to buy a pet. The shop partner will call the function from PawsConnect contract to mint NFT for buying a pet. (This NFT will track all the data related to the pet)

## Bridge Paws NFT from one chain to another chain
User can bridge Paws NFT from one chain to another chain by calling this function from PawsConnect contract. This involves burning of the paws NFT on the source chain and minting on the destination chain. Bridging is powered by chainlink CCIP.

## Transferring Ownership of pet to new owner
Sometimes a user wants to transfer their pet to a new owner, this can be easily done by transferring the Paws NFT to that desired owner.
A user is first required to approve the paws NFT to the new owner, and is then required to visit our shop partner to finally facilitate transfer the ownership of the pet to the new owner.

## Known Issues
there is one known bug while bridging the NFT to another chain, the previousOwners of the pet are not passed because they may cost a large amount of gas.