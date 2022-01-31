/**
 *Submitted for verification at FtmScan.com on 2022-01-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;


// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)



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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)



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


interface ICyber is IERC20 {
    function burnFrom (address account_, uint256 amount_) external;
}

contract Redemption is Ownable {

    ICyber public immutable Cyber;
    IERC20 public immutable Frax;
    uint256 public immutable fraxPerCyber;

    mapping (address => uint256) public redemptions;
    mapping (uint256 => address) public redeemers;
    uint256 public numberOfRedeemers;

    bool public redeemable;

    function makeRedeemable () external onlyOwner {
        require(redeemable == false);
        IERC20(Frax).transferFrom(msg.sender, address(this), IERC20(Frax).balanceOf(msg.sender));
        redeemable = true;
    }

    constructor (address _Cyber, address gCyber, address _Frax, uint256 aCyber) {
        require(_Cyber != address(0));
        Cyber = ICyber(_Cyber);
        require(_Frax != address(0));
        Frax = IERC20(_Frax);
        require(gCyber != address(0));
        uint256 gCyberTotalSupply = IERC20(gCyber).totalSupply();
        uint256 cyberTotalSupply = ICyber(_Cyber).totalSupply();
        uint256 totalCyber = (gCyberTotalSupply / 10) + cyberTotalSupply * 1e9 + (aCyber / 10);
        fraxPerCyber = IERC20(_Frax).balanceOf(msg.sender) * 1e18 / totalCyber;
    }

    function redeem () external isRedeemable {
        uint256 balance = Cyber.balanceOf(msg.sender);
        uint256 claimableAmount = fraxPerCyber * balance / 1e9;

        if (Frax.balanceOf(address(this)) < claimableAmount) {
            claimableAmount = Frax.balanceOf(address(this));
        }

        Cyber.burnFrom(msg.sender, balance);
        Frax.transfer(msg.sender, claimableAmount);
        if (redemptions[msg.sender] == 0) {
            redeemers[numberOfRedeemers] = msg.sender;
            numberOfRedeemers += 1;
        }
        redemptions[msg.sender] += balance;
    }

    modifier isRedeemable () {
        require(redeemable == true, "Not redeemable");
        _;
    }
}