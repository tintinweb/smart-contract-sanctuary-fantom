// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './interfaces/IOracle.sol';
import './interfaces/IChainlinkOracle.sol';

contract OracleV2 is IOracle {
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

	function getPriceUSD(address token_) external view override returns (uint256 price) {
		PriceData[] memory prices = allPrices[token_];
		return prices[prices.length - 1].price;
	}

	function pushPrice(address token_, uint256 price_) external {
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

pragma solidity ^0.8.10;

interface IOracle {
    function getPriceUSD(address token) external view returns (uint);
}

pragma solidity ^0.8.10;

interface IChainlinkOracle {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}