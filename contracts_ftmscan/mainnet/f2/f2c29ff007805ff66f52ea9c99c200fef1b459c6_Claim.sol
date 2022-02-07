/**
 *Submitted for verification at FtmScan.com on 2022-02-06
*/

// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity 0.7.6;

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts/math/[email protected]





/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts/utils/[email protected]





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


// File @openzeppelin/contracts/access/[email protected]





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


// File contracts/interfaces/IRena.sol

interface IRena is IERC20 {
        function approve(address, uint256) external override returns(bool);
        function addressManager() external view returns(address);
        function balanceOf(address) external view override returns(uint256);
        function transfer(address, uint256) external override returns(bool);
        function treasury() external returns(address payable);
        function rebalancer() external returns(address payable);
        function callerRewardDivisor() external returns(uint16);
}


// File contracts/interfaces/IAddressManager.sol

interface IAddressManager {
    function WETH() external view returns(address);
    function renaRouter() external view returns(address);
    function uniRouter() external view returns(address);
    function uniFactory() external view returns(address);
    function uniPair() external view returns(address);
    function renaFactory() external view returns(address);
    function feeDistributor() external view returns(address);
    function claim() external view returns(address);
    function lpStaking() external view returns(address);
}


// File contracts/interfaces/ILPStaking.sol

interface ILPStaking {
    function withdrawFromTo(address owner, uint256 _pid, uint256 _amount, address _to) external;
    function claim(address _from, uint256 _pid) external;
    function pendingrena(uint256 pid_, address account_) external view returns(uint256);
    function addPendingRewards() external;
    function massUpdatePools() external;      
}


// File contracts/interfaces/IRebalancer.sol

interface IRebalancer {
    function rebalance(uint16 callerRewardDivisor, uint16 rebalanceDivisor) external;
    function refill() payable external;
}


// File contracts/Claim.sol

//This contract is intended to act as a second layer to the LP Staking contract.
//The Staking contract requires 100% of claim to be added/removed on withdraw and deposits
//of parent token.
//Our modifaction requires payment for claim.
//Claims from the LP Contract are inteded to accumlulate here recored to the address owed to.
//The purchase and rebalancer refill happen here.

contract Claim is Ownable {
    using SafeMath for uint256;

    event Claimed(address indexed, uint256, uint256);
    event lpSacrificed(address indexed, uint256, uint256);

    uint256 public claimDivisor;    

    IRena rena;

    mapping(address => uint256) unclaimed;

    constructor(address rena_) {
        rena = IRena(rena_);
        claimDivisor = 2;
    }

    function maxClaimable(uint256 pid_, address account_) external view returns( uint256 claimable ) {
        address staking = IAddressManager(rena.addressManager()).lpStaking();
        uint256 pending_ = ILPStaking(staking).pendingrena(pid_, account_);
        claimable = unclaimed[account_].add(pending_);
    }

    function claim(uint256 requested_, uint256 pid_) external payable {
        address lpStaking = IAddressManager(rena.addressManager()).lpStaking();
        if(ILPStaking(lpStaking).pendingrena(pid_, msg.sender) > 0)
            ILPStaking(lpStaking).claim(msg.sender, pid_);

        require(requested_ <= unclaimed[msg.sender], "You don't have that much to claim.");
        unclaimed[msg.sender] = unclaimed[msg.sender].sub(requested_);
        uint256 claimValue = getClaimPrice(requested_);
        require(msg.value >= claimValue, "Insufficient input amount");
        if(claimValue > 0){
            IRebalancer(rena.rebalancer()).refill{value: claimValue}();
        }
        rena.transfer(msg.sender, requested_);
        //send back dust if any
        uint dust = msg.value.sub(claimValue);
        if(dust > 0) {
            msg.sender.transfer(dust);
        }
        emit Claimed(msg.sender, requested_, msg.value);
    }

    //Approval for Claim will be required before calling this.
    function sacrificeLP(uint256 requested_, uint256 pid_) external {
        address lpStaking = IAddressManager(rena.addressManager()).lpStaking();

        if(ILPStaking(lpStaking).pendingrena(pid_, msg.sender) > 0)
            ILPStaking(lpStaking).claim(msg.sender, pid_);
        require(requested_ <= unclaimed[msg.sender], "You don't have that much to claim.");
        uint256 requiredLP = getLPPrice(requested_);
        unclaimed[msg.sender] = unclaimed[msg.sender].sub(requested_);
        ILPStaking(lpStaking).withdrawFromTo(msg.sender, 0, requiredLP, rena.rebalancer());
        rena.transfer(msg.sender, requested_);
        emit lpSacrificed(msg.sender, requiredLP, requested_);
    }

    function getClaimPrice(uint256 _amount) public view returns(uint256 claimPrice) {
        if(claimDivisor == 0) return 0;
        address pair = IAddressManager(rena.addressManager()).uniPair();
        uint256 ethReserves = IERC20(IAddressManager(rena.addressManager()).WETH()).balanceOf(pair);
        uint256 renaReserves = rena.balanceOf(pair);
               
        claimPrice = _amount.mul(ethReserves).div(renaReserves); 
        claimPrice = claimPrice.sub(claimPrice.div(claimDivisor));
    }

    function getLPPrice(uint256 _amount) public view returns(uint256 requiredLP) {
        uint256 eBal = IERC20(IAddressManager(rena.addressManager()).WETH()).balanceOf(IAddressManager(rena.addressManager()).uniPair());
        uint256 lpSupply = IERC20(IAddressManager(rena.addressManager()).uniPair()).totalSupply();
        requiredLP = _amount.mul(eBal).div(lpSupply).div(4);
        requiredLP = requiredLP.sub(requiredLP.div(claimDivisor));
    }

    function setClaim(address _from, uint256 _amount) external {
        require(msg.sender ==  IAddressManager(rena.addressManager()).lpStaking(), "Only Staking can set claims");
        unclaimed[_from] = unclaimed[_from].add(_amount);
    }

    function setClaimDivisor(
        uint256 _amount 
    ) public onlyOwner {
        require(_amount != 0, 'Cannot set that');
        claimDivisor = _amount;
    }
       
}