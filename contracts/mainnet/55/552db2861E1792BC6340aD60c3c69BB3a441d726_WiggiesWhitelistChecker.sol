// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ICollectionWhitelistChecker} from "./interfaces/ICollectionWhitelistChecker.sol";
import {IWiggies} from "./interfaces/IWiggies.sol";

contract WiggiesWhitelistChecker is Ownable, ICollectionWhitelistChecker {
    IWiggies public wiggies;

    mapping(uint8 => bool) public isWiggyIdRestricted;

    event NewRestriction(uint8[] wiggyIds);
    event RemoveRestriction(uint8[] wiggyIds);

    /**
     * @notice Constructor
     * @param _wiggiesAddress: Wiggies contract
     */
    constructor(address _wiggiesAddress) {
        wiggies = IWiggies(_wiggiesAddress);
    }

    /**
     * @notice Restrict tokens with specific wiggyIds to be sold
     * @param _wiggyIds: wiggyIds to restrict for trading on the market
     */
    function addRestrictionForWiggies(uint8[] calldata _wiggyIds) external onlyOwner {
        for (uint8 i = 0; i < _wiggyIds.length; i++) {
            require(!isWiggyIdRestricted[_wiggyIds[i]], "Operations: Already restricted");
            isWiggyIdRestricted[_wiggyIds[i]] = true;
        }

        emit NewRestriction(_wiggyIds);
    }

    /**
     * @notice Remove restrictions tokens with specific wiggyIds to be sold
     * @param _wiggyIds: wiggyIds to restrict for trading on the market
     */
    function removeRestrictionForWiggies(uint8[] calldata _wiggyIds) external onlyOwner {
        for (uint8 i = 0; i < _wiggyIds.length; i++) {
            require(isWiggyIdRestricted[_wiggyIds[i]], "Operations: Not restricted");
            isWiggyIdRestricted[_wiggyIds[i]] = false;
        }

        emit RemoveRestriction(_wiggyIds);
    }

    /**
     * @notice Check whether token can be listed
     * @param _tokenId: tokenId of the NFT to list
     */
    function canList(uint256 _tokenId) external view override returns (bool) {
        uint8 wiggyId = wiggies.getWiggyId(_tokenId);

        return !isWiggyIdRestricted[wiggyId];
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
pragma solidity ^0.8.0;

interface ICollectionWhitelistChecker {
    function canList(uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWiggies {
    function getWiggyId(uint256 _tokenId) external view returns (uint8);
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