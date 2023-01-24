/**
 *Submitted for verification at FtmScan.com on 2023-01-24
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

// Zion Governance contract
// this contract calculates PILLS staked in Neo Pools, PILLS-FTM on Morpheus Swap, as well as regular PILLS and LP held in wallet.
pragma solidity >=0.7.0 <0.9.0;

struct UserInfo {
    uint256 amount;     // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
}

contract NeoPool {
    mapping (address => UserInfo) public userInfo;
}

interface IERC20 {
    function balanceOf(address _address) external view returns (uint);
}

interface IPair {
    function totalSupply() external view returns (uint);
    function balanceOf(address _address) external view returns (uint);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract IFarm {
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
}

contract ZionGovernance is Ownable {
    address public pillsContract = 0xB66b5D38E183De42F21e92aBcAF3c712dd5d6286;
    address public poolContract = 0xE5343E1eda3dc45E73468F9fa5417F0375f45127;
    address public farmContract = 0xc7dad2e953Dc7b11474151134737A007049f576E;

    uint8 public NULL = 0;
    address[] public pools;

    function balanceOf(address wallet) public view returns (uint balance) {
        balance = IERC20(pillsContract).balanceOf(wallet);

        for(uint j = 0; j < pools.length; j++) {
            NeoPool pool = NeoPool(pools[j]);
            (uint256 amnt,) = pool.userInfo(wallet);

            balance += amnt;
        }

        uint totalSupply = IPair(poolContract).totalSupply();
        (,uint reserve1,) = IPair(poolContract).getReserves();
        (uint256 amount,) = IFarm(farmContract).userInfo(76, wallet);

        balance += (((reserve1 * amount) / totalSupply) * 15) / 10;
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