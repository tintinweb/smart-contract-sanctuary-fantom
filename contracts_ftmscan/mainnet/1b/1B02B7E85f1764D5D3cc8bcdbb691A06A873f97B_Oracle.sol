// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import './interfaces/IOracle.sol';

contract Oracle is IOracle {
	struct PriceData {
		uint256 price;
		uint256 updateTime;
		uint256 nonce;
	}
	address admin;
	mapping(address => bool) public pushers;
	mapping(address => PriceData[]) public allPrices;

	constructor() {
		admin = msg.sender;
		pushers[msg.sender] = true;
	}

	function getPriceUSD(address token_) external view override returns (uint256 price, uint256 updateTime) {
		PriceData[] memory prices = allPrices[token_];
		price = prices[prices.length - 1].price;
		updateTime = prices[prices.length - 1].updateTime;
	}

	function pushPrices(address[] calldata tokens, uint256[] calldata prices) external {
		require(tokens.length == prices.length, "!same length");
		for(uint i; i < tokens.length; i++) {
			pushPrice(tokens[i], prices[i]);
		}
	}

	function pushPrice(address token_, uint256 price_) public {
		require(pushers[msg.sender], '!pusher');
		PriceData[] storage prices = allPrices[token_];
		prices.push(PriceData({ price: price_, updateTime: block.timestamp, nonce: prices.length }));
	}

	function setAdmin(address admin_) external {
		require(msg.sender == admin, "!admin");
		admin = admin_;
	}

	function setPusher(address pusher_, bool allowed_) external {
		require(msg.sender == admin, "!admin");
		pushers[pusher_] = allowed_;
	}
}

pragma solidity ^0.8.11;

interface IOracle {
    function getPriceUSD(address token) external view returns (uint, uint);
}