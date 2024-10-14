# Undying City Smart Contracts
These smart contracts are for our game Undying City.

## About the Game
Undying City is a mobile-first Roguelike game where players have to survive against hordes of enemies coming at you. Kill enemies to gain experience and level up to learn more abilities.
Equipment is completely NFT based and players can level up their equipment to make it stronger.

## Relationship to Aptos
The game is built on the Aptos blockchain. It originally started from a hackathon project but has since grown into a full game with more features being added. We are also an Aptos grant recipient.

## Socials
- [Website](https://undyingcity.zabavalabs.com)
- [Twitter](https://twitter.com/UndyingCity)
- [Telegram](https://t.me/ZabavaCommunity/27676)

## Architecture

### admin
This holds permissions to change some settings for the game. It will eventually follow a governance model.

### daily_spins
This allows the user to spin the wheel once daily. Points are stored and incremented on the leaderboard smart contract.

### eigen_shard
This is the smart contract for the Eigen Shard fungible token. It is meant to be unlimited in supply. The buyback address will eventually be updated to benefit the community.

### equipment
This is the smart contract to add new equipment to the game. Users interact with it to upgrade or refine their equipment. Some shards are spent to improve the equipment stats.

### leaderboard
This is the on-chain leaderboard for players' scores. Currently, only the scores from the daily_spins are stored here. The admin has the permission to reset the leaderboard at the end of every season.

### omni_cache
The omni cache is the where players go to open the equipment chest to get new equipment. Some equipment are rarer, so they are added to the special equipment cache. It uses randomness to ensure fair mint of equipment.

Players can spend lesser amount of shards to open the omni cache if they open it x10. 

During special events, eg: free mints, players interact with the omni_cache to get new equipment for free. The admin has the right to whitelist addresses.

### token_lock
This smart contract locks the tokens, so users can be assured of transparent and accountable token distribution.

### und
This serves as the governance coin representing the game. 

### bcd & pseudorandom
These are deprecated as they were used prior to randomness being introduced.