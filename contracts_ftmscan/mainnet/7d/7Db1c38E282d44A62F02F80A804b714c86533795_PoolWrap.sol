/**
 *Submitted for verification at FtmScan.com on 2022-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity 0.6.12;

interface IPool {
    function stopReward() external;
    function emergencyRewardWithdraw(uint256 _amount) external;
    function updateRewardPerBlock(uint256 _rewardPerBlock) external;
    function updateBonusEndBlock(uint256 _bonusEndBlock) external;
    function updateStartBlock(uint256 _startBlock) external;
    function setLockupDuration(uint256 _lockupDuration) external;
    function setWithdrawalFeeBP(uint256 _withdrawalFeeBP) external;

    function updateDepositFeeBP(uint256 _pid, uint16 _depositFeeBP) external;
    function emergencyRewardWithdraw(uint256 _pid, uint256 _amount) external;
    function updateWithdrawalFeeBP(uint256 _pid, uint16 _withdrawalFeeBP) external;
}


pragma solidity 0.6.12;

contract PoolWrap is Ownable {

    IPool public pool;
    
    constructor(IPool _pool) public {
        pool = _pool;
    }

    function stopReward() public onlyOwner {
        pool.stopReward();
    }

    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        pool.emergencyRewardWithdraw(_amount);
    }
    
    function updateRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        pool.updateRewardPerBlock(_rewardPerBlock);
    } 
    
    function updateBonusEndBlock(uint256 _bonusEndBlock) public onlyOwner {
        pool.updateBonusEndBlock(_bonusEndBlock);
    }   
    
    function updateStartBlock(uint256 _startBlock) public onlyOwner {
        pool.updateStartBlock(_startBlock);
    }   
    
    function setLockupDuration(uint256 _lockupDuration) public onlyOwner {
        pool.setLockupDuration(_lockupDuration);
    }
    
    function setWithdrawalFeeBP(uint256 _withdrawalFeeBP) public onlyOwner {
        require(_withdrawalFeeBP <= 300, "withdrawal fee to high");
        pool.setWithdrawalFeeBP(_withdrawalFeeBP);
    }
    
    function updateDepositFeeBP(uint256 _pid, uint16 _depositFeeBP) public onlyOwner {
        require(_depositFeeBP <= 300, "deposit fee to high");
        pool.updateDepositFeeBP(_pid, _depositFeeBP);
    }

    function emergencyRewardWithdraw(uint256 _pid, uint256 _amount) public onlyOwner {
        pool.emergencyRewardWithdraw(_pid, _amount);
    }

    function updateWithdrawalFeeBP(uint256 _pid, uint16 _withdrawalFeeBP) public onlyOwner {
        require(_withdrawalFeeBP <= 300, "withdrawal fee to high");
        pool.updateWithdrawalFeeBP(_pid, _withdrawalFeeBP);
    }
}