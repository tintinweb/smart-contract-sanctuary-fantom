// SPDX-License-Identifier: No License

pragma solidity ^0.8.11;

import './interfaces/ISingularityOracle.sol';

/**
 * @title Singularity Oracle
 * @author Revenant Labs
 */
contract SingularityOracle is ISingularityOracle {
	struct PriceData {
		uint256 price;
		uint256 updatedAt;
		uint256 nonce;
	}

	address admin;
	
	mapping(address => bool) public pushers;
	mapping(address => PriceData[]) public allPrices;

	constructor(address _admin) {
		require(_admin != address(0), "SingularityOracle: ADMIN_IS_0");
		admin = _admin;
	}

	/// @dev Does NOT validate returned answers
	/// @dev Need to do data validation in interacting contract
	function getLatestRound(address _token) public view override returns (uint256 price, uint256 updatedAt) {
		PriceData[] memory prices = allPrices[_token];
		price = prices[prices.length - 1].price;
		updatedAt = prices[prices.length - 1].updatedAt;
	}

	function getLatestRounds(address[] calldata tokens) external view returns (uint256[] memory prices, uint256[] memory updatedAts) {
		for (uint256 i; i < tokens.length; i++) {
			(uint256 price, uint256 updatedAt) = getLatestRound(tokens[i]);
			prices[i] = price;
			updatedAts[i] = updatedAt;
		}
	}

	function pushPrice(address _token, uint256 _price) public {
		require(pushers[msg.sender], "SingularityOracle: NOT_PUSHER");
		PriceData[] storage prices = allPrices[_token];
		prices.push(PriceData({ price: _price, updatedAt: block.timestamp, nonce: prices.length }));
	}

	function pushPrices(address[] calldata tokens, uint256[] calldata prices) external {
		require(tokens.length == prices.length, "SingularityOracle: NOT_SAME_LENGTH");
		for(uint256 i; i < tokens.length; i++) {
			pushPrice(tokens[i], prices[i]);
		}
	}

	function setAdmin(address _admin) external {
		require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
		require(_admin != address(0), "SingularityOracle: ADMIN_IS_0");
		admin = _admin;
	}

	function setPusher(address _pusher, bool _allowed) external {
		require(msg.sender == admin, "SingularityOracle: NOT_ADMIN");
		pushers[_pusher] = _allowed;
	}
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.11;

interface ISingularityOracle {
    function getLatestRound(address token) external view returns (uint256, uint256);
}