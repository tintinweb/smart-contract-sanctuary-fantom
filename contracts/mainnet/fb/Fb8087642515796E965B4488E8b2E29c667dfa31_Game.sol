// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

struct Stats {
	uint claimed;
	uint totalTaps;
	uint deployTimestamp;
	uint totalRewards;
	uint dust;
}

struct PlayerState {
	uint taps;
	uint claimed;
	uint lastClaimId;
	uint lastBuyId;
}

contract Game {
	event DidBuy(address player);
	event DidClaim(address player, uint amount);
	
	uint constant public entryPrice = 10 ether;
	uint constant public startDelay = 2 days;

	mapping (address => PlayerState) public players;
	Stats public stats;

	constructor() {
		stats.deployTimestamp = block.timestamp;
	}

	function buy() _gameStarted public payable {
		require(msg.value == entryPrice, "Entry price not respected");
		if (getRewards(msg.sender) > 0)
			claim();
		stats.totalTaps += 1;
		players[msg.sender].taps += 1;
		players[msg.sender].lastBuyId = stats.totalTaps;
		if (players[msg.sender].lastClaimId == 0)
			players[msg.sender].lastClaimId = stats.totalTaps;
		if (stats.totalTaps == 1) {
			transfer(payable(msg.sender), entryPrice);
			players[msg.sender].claimed += entryPrice;
			stats.claimed += entryPrice;
			stats.totalRewards = entryPrice;
		}
		else {
			stats.totalRewards += getRewardsForTap(stats.totalTaps, stats.totalTaps - 1);
			uint totalExpected = stats.totalTaps * entryPrice;
			stats.dust = totalExpected - stats.totalRewards;
		}
		emit DidBuy(msg.sender);
	}

	function claim() public {
		uint rewards = getRewards(msg.sender) + stats.dust;
		require(rewards > 0, "Nothing to claim");
		transfer(payable(msg.sender), rewards);
		stats.totalRewards += stats.dust;
		stats.dust = 0;
		stats.claimed += rewards;
		players[msg.sender].claimed += rewards;
		players[msg.sender].lastClaimId = stats.totalTaps;
		emit DidClaim(msg.sender, rewards);
	}

	function getRewards(address player) view public returns (uint) {
		if (players[player].taps == 0)
			return 0;
		uint playerTaps = players[player].taps;
		uint result = 0;
		for (uint i = players[player].lastClaimId + 1; i <= stats.totalTaps; ++i) {
			uint taps = playerTaps;
			if (i == players[player].lastBuyId)
				taps -= 1;
			result += getRewardsForTap(i, taps);
		}
		return result;
	}

	function getRewardsForTap(uint round, uint taps) pure private returns (uint) {
		uint tapValue = entryPrice / (round - 1);
		return tapValue * taps;
	}

	function transfer(address payable _to, uint _amount) private {
		(bool success, ) = _to.call{value: _amount}("");
		require(success, "Failed to send Ether");
	}
	
	function hasGameStarted() view public returns (bool) {
		return block.timestamp > stats.deployTimestamp + startDelay;
	}

	modifier _gameStarted() {
		require(hasGameStarted(), "Game has not started yet");
		_;
	}
}