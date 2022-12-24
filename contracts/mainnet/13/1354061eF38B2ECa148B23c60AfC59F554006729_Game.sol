/**
 *Submitted for verification at FtmScan.com on 2022-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

uint constant ENTRY_PRICE = 100 ether;
uint constant START_DELAY = 2 days;

struct Stats {
	uint totalTaps;
	uint deployTimestamp;
}

struct PlayerState {
	uint taps;
	uint claimed;
	uint lastClaimId;
}

contract Game {
	event DidBuy(address player);
	event DidClaim(address player, uint amount);

	mapping (address => PlayerState) public players;
	Stats public stats;

	constructor() {
		stats.deployTimestamp = block.timestamp;
	}

	function buy() _gameStarted public payable {
		require(msg.value == ENTRY_PRICE, "Entry price not respected");
		if (getRewards(msg.sender) > 0)
			claim();
		stats.totalTaps += 1;
		players[msg.sender].taps += 1;
		if (players[msg.sender].lastClaimId == 0)
			players[msg.sender].lastClaimId = stats.totalTaps - 1;
		emit DidBuy(msg.sender);
	}

	function claim() public {
		uint rewards = getRewards(msg.sender);
		require(rewards > 0, "Nothing to claim");
		transfer(payable(msg.sender), rewards);
		players[msg.sender].claimed += rewards;
		players[msg.sender].lastClaimId = stats.totalTaps;
		emit DidClaim(msg.sender, rewards);
	}

	function getRewards(address player) view public returns (uint) {
		if (players[player].taps == 0)
			return 0;
		uint result = 0;
		for (uint i = players[player].lastClaimId + 1; i <= stats.totalTaps; ++i) {
			result += (ENTRY_PRICE / i) * players[player].taps;
		}
		return result;
	}

	function transfer(address payable _to, uint _amount) private {
		(bool success, ) = _to.call{value: _amount}("");
		require(success, "Failed to send Ether");
	}
	
	function hasGameStarted() view public returns (bool) {
		return block.timestamp > stats.deployTimestamp + START_DELAY;
	}

	modifier _gameStarted() {
		require(hasGameStarted(), "Game has not started yet");
		_;
	}
}