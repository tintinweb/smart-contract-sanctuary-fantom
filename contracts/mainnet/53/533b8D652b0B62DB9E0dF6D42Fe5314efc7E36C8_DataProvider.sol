// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IGrainLGE.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DataProvider is Ownable {
    uint256 public constant MAX_KINK_RELEASES = 8;
    uint256 public constant MAX_RELEASES = 20;
    uint256 public constant maxKinkDiscount = 4e26;
    uint256 public constant maxDiscount = 6e26;
    uint256 public constant PERCENT_DIVISOR = 1e27;
    IGrainLGE public immutable lge;

    constructor(address _lge) {
        lge = IGrainLGE(_lge);
    }

    function getUserShares(address user) public view returns (uint256 totalWeight, uint256) {
        (uint256 usdcValue, uint256 numberOfReleases,,, address nft,) = lge.userShares(user);

        uint256 whitelistedBonuses = lge.whitelistedBonuses(nft);

        uint256 vestingPremium;
        if (numberOfReleases == 0) {
            vestingPremium = 0;
        } else if (numberOfReleases <= MAX_KINK_RELEASES) {
            // range from 0 to 40% discount
            vestingPremium = maxKinkDiscount * numberOfReleases / MAX_KINK_RELEASES;
        } else if (numberOfReleases <= MAX_RELEASES) {
            // range from 40% to 60% discount
            // ex: user goes for 20 (5 years) -> 60%
            vestingPremium = (((maxDiscount - maxKinkDiscount) * (numberOfReleases - MAX_KINK_RELEASES)) / (MAX_RELEASES - MAX_KINK_RELEASES)) + maxKinkDiscount;
        }

        uint256 weight = vestingPremium == 0 ? usdcValue : usdcValue * PERCENT_DIVISOR / (PERCENT_DIVISOR - vestingPremium);

        uint256 bonusWeight = nft == address(0) ? 0 : weight * whitelistedBonuses / PERCENT_DIVISOR;

        totalWeight = weight + bonusWeight;

        return (totalWeight, numberOfReleases);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IGrainLGE {
    function userShares(address user) external view returns (uint256, uint256, uint256, uint256, address, uint256);
    function whitelistedBonuses(address nft) external view returns (uint256);
}