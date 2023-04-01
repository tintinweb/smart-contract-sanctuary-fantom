/**
 *Submitted for verification at FtmScan.com on 2023-03-26
*/

// SPDX-License-Identifier: MIT
// File: NFTWhitelist/interfaces/IBarbarianConquerors.sol

pragma solidity ^0.8.0;

interface IBarbarianConquerors {
    function getBarbarianId(uint256 _tokenId) external view returns (uint8);
}

// File: NFTWhitelist/interfaces/ICollectionWhitelistChecker.sol


pragma solidity ^0.8.0;

interface ICollectionWhitelistChecker {
    function canList(uint256 _tokenId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: NFTWhitelist/NFTWhitelistChecker.sol


pragma solidity ^0.8.0;




contract BarbarianConquerorsWhitelistChecker is Ownable, ICollectionWhitelistChecker {
    IBarbarianConquerors public barbarianConquerors;

    mapping(uint8 => bool) public isBarbarianIdRestricted;

    event NewRestriction(uint8[] barbarianIds);
    event RemoveRestriction(uint8[] barbarianIds);

    /**
     * @notice Constructor
     * @param _barbarianConquerorsAddress: BarbarianConquerors contract
     */
    constructor(address _barbarianConquerorsAddress) {
        barbarianConquerors = IBarbarianConquerors(_barbarianConquerorsAddress);
    }

    /**
     * @notice Restrict tokens with specific barbarianIds to be sold
     * @param _barbarianIds: barbarianIds to restrict for trading on the market
     */
    function addRestrictionForBarbarian(uint8[] calldata _barbarianIds) external onlyOwner {
        for (uint8 i = 0; i < _barbarianIds.length; i++) {
            require(!isBarbarianIdRestricted[_barbarianIds[i]], "Operations: Already restricted");
            isBarbarianIdRestricted[_barbarianIds[i]] = true;
        }

        emit NewRestriction(_barbarianIds);
    }

    /**
     * @notice Remove restrictions tokens with specific barbarianIds to be sold
     * @param _barbarianIds: barbarianIds to restrict for trading on the market
     */
    function removeRestrictionForBarbarian(uint8[] calldata _barbarianIds) external onlyOwner {
        for (uint8 i = 0; i < _barbarianIds.length; i++) {
            require(isBarbarianIdRestricted[_barbarianIds[i]], "Operations: Not restricted");
            isBarbarianIdRestricted[_barbarianIds[i]] = false;
        }

        emit RemoveRestriction(_barbarianIds);
    }

    /**
     * @notice Check whether token can be listed
     * @param _tokenId: tokenId of the NFT to list
     */
    function canList(uint256 _tokenId) external view override returns (bool) {
        uint8 barbarianId = barbarianConquerors.getBarbarianId(_tokenId);

        return !isBarbarianIdRestricted[barbarianId];
    }
}