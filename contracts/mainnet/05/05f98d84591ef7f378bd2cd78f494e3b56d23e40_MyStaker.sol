// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "IERC20.sol";
import "SafeERC20.sol";
import "Address.sol";
import "SafeMath.sol";


contract MyStaker {

	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	uint256 public number;

	address public immutable token;

	constructor(uint256 _number, address _token) {
		number = _number;
		token = _token;
	}
}