/**
 *Submitted for verification at FtmScan.com on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Sources flattened with hardhat v2.8.3 https://hardhat.org

// File @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File @openzeppelin/contracts/access/IOwnable.sol

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

interface IOwnable {
    function owner() external view returns (address);

    function pushOwnership(address newOwner) external;

    function pullOwnership() external;

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;
}

// File @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
abstract contract Ownable is IOwnable, Context {
    address private _owner;
    address private _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
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
     * @dev Sets up a push of the ownership of the contract to the specified
     * address which must subsequently pull the ownership to accept it.
     */
    function pushOwnership(address newOwner) public virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipPushed(_owner, newOwner);
        _newOwner = newOwner;
    }

    /**
     * @dev Accepts the push of ownership of the contract. Must be called by
     * the new owner.
     */
    function pullOwnership() public virtual override {
        require(msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File contracts/interfaces/IBlockTimeTracker.sol

interface IBlockTimeTracker {
    function PRECISION() external view returns (uint8);

    function startBlock() external view returns (uint256);

    function startTimestamp() external view returns (uint256);

    function average() external view returns (uint256);

    function reset() external;

    function VERSION() external view returns (uint256);
}

// File contracts/BlockTimeTracker/BlockTimeTracker.sol

contract BlockTimeTracker is IBlockTimeTracker, Ownable {
    uint256 public constant VERSION = 2022021401;
    uint8 public constant PRECISION = 6;
    uint256 public startBlock;
    uint256 public startTimestamp;

    constructor() {
        startBlock = currentBlock();
        startTimestamp = currentTimestamp();
    }

    /**
     * @dev internal method that does quick division using the set precision
     */
    function divide(
        uint256 a,
        uint256 b,
        uint8 precision
    ) internal pure returns (uint256) {
        return (a * (10**precision)) / b;
    }

    function currentTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function currentBlock() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev returns the time weighted average blocks per second
     * PRECISION defines the number of digits required to represent
     * the fixed floating point representation of the value
     */
    function average() public view returns (uint256) {
        return
            divide(
                (currentBlock() - startBlock),
                (currentTimestamp() - startTimestamp),
                PRECISION
            );
    }

    /**
     * @dev resets the start block and start timestamp
     */
    function reset() public onlyOwner {
        startBlock = currentBlock();
        startTimestamp = currentTimestamp();
    }
}