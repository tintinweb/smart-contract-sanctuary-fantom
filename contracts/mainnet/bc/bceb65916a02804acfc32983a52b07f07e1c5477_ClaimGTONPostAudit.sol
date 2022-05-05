/**
 *Submitted for verification at FtmScan.com on 2022-05-05
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/interfaces/InitializableOwnable.sol

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

contract InitializableOwnable {

    address public owner;
    address public newOwner;

    bool internal initialized;

    // ============ Events ============

    event OwnerTransferRequested(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed oldOwner, 
        address indexed newOwner
    );

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initOwner(address _newOwner) public notInitialized {
        initialized = true;
        owner = _newOwner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerTransferRequested(owner, _newOwner);
        newOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == newOwner, "Claim from wrong address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    /* ========== MODIFIERS ========== */

    modifier notInitialized() {
        require(!initialized, "Not initialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}


// File contracts/misc/PreAuditStaking.sol


pragma solidity 0.8.13;

interface PreAuditStaking {

    /* ========== HELPER STRUCTURES ========== */

    struct UserInfo {
        uint amount;
        uint rewardDebt;
        uint accumulatedReward;
        uint lastHarvestTimestamp;
    }

    /* ========== STATE VARIABLES ========== */

    function accumulatedRewardPerShare() external view returns(uint);
    function lastRewardTimestamp() external view returns(uint);
    function userInfo(address address_) external view returns(UserInfo memory);
    function balanceOf(address user_) external view returns(uint);
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
}


// File @openzeppelin/contracts/security/[email protected]

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


// File contracts/misc/ClaimGTONPostAudit.sol


pragma solidity 0.8.13;




contract ClaimGTONPostAudit is InitializableOwnable, ReentrancyGuard {

    /* ========== CONSTANTS ========== */
    // Testnet - 0x314650ac2876c6B6f354499362Df8B4DC95E4750
    // Fantom  - 0xB0dAAb4eb0C23aFFaA5c9943d6f361b51479ac48
    PreAuditStaking public immutable stakingContract;
    IERC20 public immutable gton;

    uint public constant calcDecimals = 1e14;

    // These values are all hardcoded to related numbers for payouts to avoid
    // possibility of calculation issues on this simple contract
    uint public constant pauseTimestamp = 1651595669;
    uint public constant accumulatedRewardPerShare = 5474781204318;
    
    /* ========== STATE VARIABLES ========== */
    mapping(address => bool) public withdrawals;

    constructor(
        PreAuditStaking stakingContract_,
        IERC20 gton_
    ) {
        initOwner(msg.sender);
        stakingContract = stakingContract_;
        gton = gton_;
    }

    function withdrawGton() external nonReentrant {
        require(withdrawals[msg.sender] == false, "User already withdrawn");
        require(stakingContract.balanceOf(msg.sender) != 0, "Zero balance");
        PreAuditStaking.UserInfo memory user = stakingContract.userInfo(msg.sender);
        // user.lastHarvestTimestamp = block.timestamp;
        uint pendingReward = accumulatedRewardPerShare * user.amount / calcDecimals;
        uint accumulatedReward = user.accumulatedReward + pendingReward - user.rewardDebt;
        uint amount = user.amount + accumulatedReward;

        withdrawals[msg.sender] = true;
        require(gton.transfer(msg.sender, amount), "Staking: transfer failed");
        emit Withdraw(msg.sender, amount);
    }

    function withdrawToken(
        IERC20 tokenToWithdraw, 
        address to, 
        uint amount
    ) external onlyOwner {
        require(tokenToWithdraw.transfer(to, amount));
    }

    event Withdraw(address indexed user, uint indexed amount);
}