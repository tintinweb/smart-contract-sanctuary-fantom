/**
 *Submitted for verification at FtmScan.com on 2022-09-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
    @title Contract that manages locking and unlocking of tokens for voting rights
    @author RadialFinance
 */
contract VoteLock {
    //----------------------------------- Declarations ----------------------------------------//
    struct Lock {
        uint256 unlocksAtWeek;
        uint256 amount;
    }

    //----------------------------------- Constants ----------------------------------------//
    uint256 constant WEEK = 60*60*24*7;
    uint256 immutable public LOCK_WEEKS;
    uint256 immutable public START_TIME;

    //----------------------------------- State variables ----------------------------------------//
    mapping(address => Lock[]) public locks;
    mapping(address => uint256) public lockIndexToStartWithdraw;

    //----------------------------------- Events ----------------------------------------//
    event LockForVoting(address user, uint256 amount, uint256 unlockWeek);
    event UnlockFromVoting(address user, uint256 amount);

    //----------------------------------- Initialize ----------------------------------------//
    constructor(uint256 _lockWeeks, uint256 _startTime) {
        LOCK_WEEKS = _lockWeeks;
        START_TIME = _startTime;
    }

    //----------------------------------- Lock tokens ----------------------------------------//
    function _lock(address _user, uint256 _amount) internal {
        require(_amount != 0, "0 deposit");
        uint256 _unlocksAtWeek = getWeek() + LOCK_WEEKS;
        uint256 _totalLocks = locks[_user].length;
        emit LockForVoting(_user, _amount, _unlocksAtWeek);
        if(_totalLocks == 0) {
            locks[_user].push(Lock(_unlocksAtWeek, _amount));
            return;
        }

        Lock storage _lastLock = locks[_user][_totalLocks - 1];
        if(_lastLock.unlocksAtWeek == _unlocksAtWeek) {
            _lastLock.amount += _amount;
        } else {
            locks[_user].push(Lock(_unlocksAtWeek, _amount));
        }
    }

    //----------------------------------- Unlock tokens ----------------------------------------//
    function _unlock(address _user, uint256 _amount) internal {
        uint256 _locksLength = locks[_user].length;
        uint256 _currentWeek = getWeek();
        uint256 _indexToWithdraw = lockIndexToStartWithdraw[_user];
        emit UnlockFromVoting(_user, _amount);
        for(uint256 i = _indexToWithdraw; i < _locksLength; i++) {
            Lock memory _lockInfo = locks[_user][i];

            require(_lockInfo.unlocksAtWeek < _currentWeek, "Not yet unlocked");

            if(_lockInfo.amount > _amount) {
                locks[_user][i].amount = _lockInfo.amount - _amount;
                lockIndexToStartWithdraw[_user] = i;
                return;
            } else if(_lockInfo.amount == _amount) {
                delete locks[_user][i];
                lockIndexToStartWithdraw[_user] = i+1;
                return;
            } else {
                delete locks[_user][i];
                _amount -= _lockInfo.amount;
            }
        }
        revert("Insufficient amount to unlock");
    }

    //----------------------------------- Getter functions ----------------------------------------//
    function unlockableBalance(address _user) external view returns(uint256) {
        uint256 _locksLength = locks[_user].length;
        uint256 _currentWeek = getWeek();
        uint256 _indexToWithdraw = lockIndexToStartWithdraw[_user];
        uint256 _amount;
        for(uint256 i = _indexToWithdraw; i < _locksLength; i++) {
            Lock memory _lockInfo = locks[_user][i];
            if(_lockInfo.unlocksAtWeek >= _currentWeek) {
                break;
            }
            _amount += _lockInfo.amount;
        }
        return _amount;
    }

    function isAmountUnlockable(address _user, uint256 _amount) external view returns(bool) {
        if(_amount == 0) return true;
        uint256 _locksLength = locks[_user].length;
        uint256 _currentWeek = getWeek();
        uint256 _indexToWithdraw = lockIndexToStartWithdraw[_user];
        for(uint256 i = _indexToWithdraw; i < _locksLength; i++) {
            Lock memory _lockInfo = locks[_user][i];
            if(_lockInfo.unlocksAtWeek >= _currentWeek) {
                return false;
            }
            if(_lockInfo.amount >= _amount) {
                return true;
            } else {
                _amount -= _lockInfo.amount;
            }
        }
        return false;
    }

    function getWeek() public view returns (uint256) {
        return (block.timestamp - START_TIME) / WEEK;
    }
}


pragma solidity 0.8.15;

interface IRadialVoting {
    function balanceOfLP(address user) external returns(uint256);
    function receiveLP(address from, uint256 amount) external;
    function withdrawLP(address _from, uint256 _amount) external;
    function receiveRDL(address user, uint256 amount) external;
    function withdrawRDL(address user, uint256 amount) external;
    function getVotingPower(address user) external returns(uint256);
}


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}



// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
}


pragma solidity 0.8.15;

contract RDLManager is VoteLock, ReentrancyGuard {
    //----------------------------------- Constants ----------------------------------------//
    IERC20 immutable RDL;
    IRadialVoting immutable RADIAL_VOTING;

    //----------------------------------- State variables ----------------------------------------//
    mapping(address => uint256) public deposits;

    //----------------------------------- Initialize ----------------------------------------//
    constructor(
        address _rdlToken, 
        address _radialVoting, 
        uint256 _startTime, 
        uint256 _lockWeeks
    ) VoteLock(_lockWeeks, _startTime) ReentrancyGuard() {
        RDL = IERC20(_rdlToken);
        RADIAL_VOTING = IRadialVoting(_radialVoting);
    }

    //----------------------------------- Lock RDL ----------------------------------------//
    function lock(uint256 _amount) external nonReentrant {
        RDL.transferFrom(msg.sender, address(this), _amount);
        RADIAL_VOTING.receiveRDL(msg.sender, _amount);
        _lock(msg.sender, _amount);
        deposits[msg.sender] += _amount;
    }

    //----------------------------------- Withdraw RDL ----------------------------------------//
    function unlock(uint256 _amount) external nonReentrant {
        deposits[msg.sender] -= _amount;

        _unlock(msg.sender, _amount);

        // inform radial voting about tokens locked
        RADIAL_VOTING.withdrawRDL(msg.sender, _amount);
        RDL.transfer(msg.sender, _amount);
    }
}