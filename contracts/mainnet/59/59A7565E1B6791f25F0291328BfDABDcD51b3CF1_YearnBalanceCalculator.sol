// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IBalanceCalculator {
    function getUnderlying(address vault) external view returns (address);

    function calcValue(
        address vault,
        uint256 amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IYearnVault {
    // function deposit(uint256 _amount) external returns (uint256);

    // function withdraw(uint256 maxShares) external returns (uint256);

    function token() external view returns (address);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IBalanceCalculator.sol";
import "./interfaces/IYearnVault.sol";

contract YearnBalanceCalculator is IBalanceCalculator {
    function getUnderlying(address vault) external view returns (address) {
        return IYearnVault(vault).token();
    }

    function calcValue(
        address vault,
        uint256 amount
    ) external view returns (uint256) {
        uint256 totalAssets = IYearnVault(vault).totalAssets();
        uint256 vaultTotalSupply = IYearnVault(vault).totalSupply();
        if (vaultTotalSupply == 0) {
            return 0;
        }
        return (totalAssets * amount) / vaultTotalSupply;
    }
}