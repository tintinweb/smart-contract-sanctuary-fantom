// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPoolAdapter.sol";

struct ReserveConfigurationMap {
    uint256 data;
}

struct ReserveData {
    // stores the reserve configuration
    ReserveConfigurationMap configuration;
    // the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    // the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    // variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    // the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    // the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    // timestamp of last update
    uint40 lastUpdateTimestamp;
    // the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    // aToken address
    address aTokenAddress;
    // stableDebtToken address
    address stableDebtTokenAddress;
    // variableDebtToken address
    address variableDebtTokenAddress;
    // address of the interest rate strategy
    address interestRateStrategyAddress;
    // the current treasury balance, scaled
    uint128 accruedToTreasury;
    // the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    // the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
}

interface IAavePoolAddressesProvider {
    function getPool() external view returns (address);
}

interface IAavePoolV3 {
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function getReservesList() external view returns (address[] memory);

    function getReserveData(address asset) external view returns (ReserveData memory);
}

contract AavePoolAdapter is IPoolAdapter {
    address private immutable poolAddress;

    constructor(address poolAddressesProvider) {
        poolAddress = IAavePoolAddressesProvider(poolAddressesProvider).getPool();
    }

    function stakingBalance(address, bytes memory args) external returns (uint256) {
        // args should contain staked token address
        address asset = abi.decode(args, (address));
        ReserveData memory data = IAavePoolV3(poolAddress).getReserveData(asset);
        return IERC20(data.aTokenAddress).balanceOf(address(this));
    }

    function rewardBalance(address, bytes memory) external returns (uint256) {
        return 0;
    }

    function deposit(
        address,
        uint256 amount,
        bytes memory args
    ) external {
        address asset = abi.decode(args, (address));
        IAavePoolV3(poolAddress).supply(
            asset, // asset
            amount, // amount
            address(this), // onBehalfOf
            uint16(0) // referralCode
        );
    }

    function withdraw(
        address,
        uint256 amount,
        bytes memory args
    ) external {
        address asset = abi.decode(args, (address));
        IAavePoolV3(poolAddress).withdraw(
            asset, // asset
            amount, // amount
            address(this) // to
        );
    }

    function withdrawAll(address, bytes memory args) external {
        address asset = abi.decode(args, (address));
        // Pass type(uint256).max for withdrawing all
        IAavePoolV3(poolAddress).withdraw(
            asset, // asset
            type(uint256).max, // amount
            address(this) // to
        );
    }

    function stakedToken(address, bytes memory args) external returns (address) {
        // args should contain staked token address
        address givenToken = abi.decode(args, (address));
        address[] memory aaveTokens = IAavePoolV3(poolAddress).getReservesList();
        for (uint i = 0; i < aaveTokens.length; i++) {
            if (aaveTokens[i] == givenToken) {
                return givenToken;
            }
        }

        return address(0);
    }

    function rewardToken(address, bytes memory args) external returns (address) {
        // args should contain reward token address
        // For all Aave pools stakedToken = rewardToken
        return abi.decode(args, (address));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolAdapter {
    function stakingBalance(address pool, bytes memory) external returns (uint256);

    function rewardBalance(address pool, bytes memory) external returns (uint256);

    function deposit(
        address pool,
        uint256 amount,
        bytes memory args
    ) external;

    function withdraw(
        address pool,
        uint256 amount,
        bytes memory args
    ) external;

    function withdrawAll(address pool, bytes memory args) external;

    function stakedToken(address pool, bytes memory args) external returns (address);

    function rewardToken(address pool, bytes memory args) external returns (address);
}