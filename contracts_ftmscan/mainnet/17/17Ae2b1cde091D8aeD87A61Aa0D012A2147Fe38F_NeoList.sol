/**
 *Submitted for verification at FtmScan.com on 2022-01-30
*/

// SPDX-License-Identifier: GPL-3.0
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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


pragma solidity >=0.7.0 <0.9.0;

struct UserInfo {
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}

contract NeoPool {
    mapping (address => UserInfo) public userInfo;
}

contract NeoList is Ownable {
    uint8 public NULL = 0;
    address[] public pools;

    function balanceOf(address wallet) public view returns (uint balance) {
        balance = 0;

        for(uint j = 0; j < pools.length; j++) {
            NeoPool pool = NeoPool(pools[j]);
            (uint256 amount,) = pool.userInfo(wallet);

            balance += amount;
        }
    }

    function _getPoolIndex(address _address) private view returns (uint index) {
        for(uint j = 0; j < pools.length; j++) {
            if(pools[j] != _address) continue;
            index = j + 1;
            break;
        }
    }

    function addPool(address _address) external onlyOwner {
        require(_getPoolIndex(_address) == NULL, "Pool already in list!");
        pools.push(_address);
    }

    function removePool(address _address) external onlyOwner {
        uint index = _getPoolIndex(_address);
        require(index != NULL, "Pool is not in list!");
        delete pools[index - 1];
    }
    
    function getPools() external view returns(address[] memory) {
        return pools;
    }
}