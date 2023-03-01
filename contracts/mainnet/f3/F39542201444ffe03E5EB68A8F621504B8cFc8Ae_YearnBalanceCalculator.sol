// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBalanceCalculator {
	function calculateTokenBalance(address baseToken, uint256 lpValue) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./interfaces/IBalanceCalculator.sol";

interface Vault {
	function pricePerShare() external view returns(uint256);
}

contract YearnBalanceCalculator is IBalanceCalculator {
	function calculateTokenBalance(address baseToken, uint256 lpValue) external view returns(uint) {
		Vault vault = Vault(baseToken);

    	return vault.pricePerShare() * lpValue;
	}
}