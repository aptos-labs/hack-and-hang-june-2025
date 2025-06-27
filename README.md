## Permissionless 2025 Hack and Hang

Welcome to the Pig Game challenge! Build your own implementation of the classic Pig dice game on Aptos using Move smart contracts.

## 🎮 Game Overview
Pig is a simple dice game where players try to reach a score of 50 points:

Goal: Reach a score of 50 points in as few turns as possible
Setup: 1 player, 1 die
Gameplay:

- Each turn, roll the die repeatedly until you roll a 1 or decide to "hold"
- If you roll 1: you score nothing and your turn ends ("bust")
- If you roll 2-6: add that number to your turn total and continue rolling
- If you "hold": your turn total is added to your score and your turn ends
- If the player calls complete game, the game ends, complete_game is called in pig master with the results.
- If the game has been completed, then it can be reset, and a new game started.

## 🎯 Challenge Requirements
What You Need to Build
You'll implement your own version of the Pig game contract in contract/pig-game/sources/pig_game.move. The starter code provides the exact function signatures you must implement - do not change these signatures as the UI depends on them. Deploy your contract on testnet & once deployed, your contract will work with the provided UI at https://hack-and-hang-june-2025.vercel.app/

## 🏗️ Project Structure
contract/
├── pig-game/          # 👈 Implement your game logic here
│   ├── sources/
│   │   └── pig_game.move    # Your implementation
│   ├── Move.toml
│   └── tests/
└── pig-master/        # 👈 Global scoring system (pre-built)
    ├── sources/
    │   └── pig_master.move  # Tracks all players' stats
    └── Move.toml

website/               # React frontend (already deployed)
├── src/
└── package.json

## Setup your Environment

- [Fork this repository](https://github.com/aptos-labs/hack-and-hang-june-2025/fork)
- [Clone your forked repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)
- Install the [Aptos CLI](https://aptos.dev/en/build/cli)
- Initialize your account on testnet with the following command:

`aptos init --network testnet`

- Fund your account with testnet tokens from the [faucet](https://aptos.dev/en/network/faucet)

- Setup move project in your directory:

`aptos move init --name pig-game`

- **Configure your Move.toml file:**
  
  Before compiling, you need to update `contract/pig-game/Move.toml`:
  
  1. Set `pig_game_addr` to your wallet address (the same address from `aptos init`)
  2. Remove the `[dev-addresses]` section - it will be generated automatically
  
  Example:
  ```toml
  [addresses]
  pig_game_addr = "0x1234567890abcdef1234567890abcdef12345678"  # Your wallet address
  
  # Remove this section entirely:
  # [dev-addresses]
  ```

- Compile & deploy your contract:

`aptos move compile` 

`aptos move publish`

- Test your contract:

`aptos move test`

* Visit the [website](https://hack-and-hang-june-2025.vercel.app/)
    * Connect your Aptos connect wallet to the website.
    * Fund the account with some testnet APT using the [Faucet](https://aptos.dev/en/network/faucet).
    * Enter your contract address in the input field (who deployed it).
    * Play the Pig game by rolling the die, holding, and completing the game.


## Additional Notes

- Linking to Pig Master: The pig_master contract tracks global leaderboards and statistics. When your game completes, report the result to the master contract for global tracking. 
- For secure dice rolls, use Aptos's on-chain randomness API. Refer the [randomness docs](https://aptos.dev/en/build/smart-contracts/randomness) for more.

## 📚 Learning Resources
Core Aptos Development

🏗️ Smart Contracts Guide: https://aptos.dev/en/build/smart-contracts
📖 ToDo Move Contract Tutorial: https://aptos.dev/en/build/guides/build-e2e-dapp/1-create-smart-contract
🎓 Aptos Learn: https://learn.aptoslabs.com/en/code-examples
