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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IFrogMinters.sol";

contract FrogMinters is IFrogMinters, Ownable {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(uint256 => uint256)) private _minterTokens;

    mapping(uint256 => address) private _minters;

    function setMinters(
        uint256[] calldata tokenIds,
        address[] calldata minters
    ) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            address minter = minters[i];
            _minters[tokenId] = minter;
            _minterTokens[minter][_balances[minter]] = tokenId;
            _balances[minter] += 1;
        }
    }

    function balanceOf(
        address minter
    ) public view returns(uint256) {
        return _balances[minter];
    }

    function minterOf(
        uint256 tokenId
    ) public view returns (address) {
        address minter = _minters[tokenId];
        require(minter != address(0), "minter for nonexistent token");
        return minter;
    }

    function tokenOfMinterByIndex(
        address minter,
        uint256 index
    ) public view returns (uint256) {
        require(index < balanceOf(minter), "minter index out of bounds");
        return _minterTokens[minter][index];
    }

    function tokensOfMinter(
        address minter
    ) public view returns (uint256[] memory) {
        uint256 balance = balanceOf(minter);
        uint256[] memory tokenIds = new uint256[](balance);
        for (uint256 i = 0; i < balance; i++) {
            tokenIds[i] = tokenOfMinterByIndex(minter, i);
        }
        return tokenIds;
    }

    function isMinter(
        uint256 tokenId,
        address minter
    ) public view returns (bool) {
        return _minters[tokenId] == minter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFrogMinters {
    function balanceOf(address minter) external view returns (uint256 balance);

    function minterOf(uint256 tokenId) external view returns (address);

    function tokenOfMinterByIndex(address minter, uint256 index) external view returns (uint256);

    function tokensOfMinter(address minter) external view returns (uint256[] memory);

    function isMinter(uint256 tokenId, address minter) external view returns (bool);
}