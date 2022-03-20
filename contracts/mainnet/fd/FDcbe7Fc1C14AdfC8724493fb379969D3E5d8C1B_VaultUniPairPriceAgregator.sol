// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IVault {
    function getPricePerFullShare() external view returns (uint256);

    function want() external view returns (address);
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IAgregator {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 round,
            int256 answer,
            uint256 updatedAt,
            uint256,
            uint80
        );
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract VaultUniPairPriceAgregator is Ownable {
    uint8 public decimals = 18;
    uint256 public updatedAt;

    IVault public vault;
    IUniswapV2Pair public pair;
    IAgregator public agregator0;
    IAgregator public agregator1;

    uint256 public pricePerFullShare;
    uint256 public totalSupply;
    uint112 public reserve0;
    uint112 public reserve1;

    uint8 public decimalsToken0;
    uint8 public decimalsToken1;
    uint8 public decimalsAgregator0;
    uint8 public decimalsAgregator1;

    constructor(
        IVault _vault,
        IAgregator _agregator0,
        IAgregator _agregator1
    ) {
        vault = _vault;
        agregator0 = _agregator0;
        decimalsAgregator0 = _agregator0.decimals();
        agregator1 = _agregator1;
        decimalsAgregator1 = _agregator1.decimals();

        pair = IUniswapV2Pair(_vault.want());
        decimalsToken0 = IERC20(pair.token0()).decimals();
        decimalsToken1 = IERC20(pair.token1()).decimals();

        updateOracle();
    }

    function updateOracle() public onlyOwner {
        uint256 _pricePerFullShare = vault.getPricePerFullShare();
        pricePerFullShare = _pricePerFullShare;

        uint256 _totalSupply = pair.totalSupply();
        totalSupply = _totalSupply;

        (uint112 _reserve0, uint112 _reserve1, ) = pair.getReserves();
        reserve0 = _reserve0;
        reserve1 = _reserve1;

        updatedAt = block.timestamp;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        (, int256 price0, , , ) = agregator0.latestRoundData();
        (, int256 price1, , , ) = agregator1.latestRoundData();

        int256 valuePair = ((int112(reserve0) * price0 * int256(10**(18-decimalsToken0))) /
            int256(10**(decimalsAgregator0))) +
            ((int112(reserve1) * price1 * int256(10**(18-decimalsToken1))) / int256(10**(decimalsAgregator1)));

        int256 priceLPToken = valuePair / int256(totalSupply);

        int256 answer = (priceLPToken * int256(pricePerFullShare)) / 1e18;

        return (uint80(0), answer, updatedAt, updatedAt, uint80(0));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}