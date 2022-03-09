/**
 *Submitted for verification at FtmScan.com on 2022-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;


/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address payable internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        // Owner's address
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable) {
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
    function transferOwnership(address payable newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



/**
 * @title SendlifyAirdrop
 * @dev SendlifyAirdrop is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract SendlifyAirdrop is Ownable{
  using SafeMath for uint256;

    
    // amount of the token distributed
    uint256 public amountClaimed;
    
    // token interface
    IBEP20 public token;
    
    // token decimal
    uint256 tokenDecimal;

    // airdrop amount
    uint256 public airdropAmt;

    // distribution state
    bool public isDistributionFinished = false;
    
    // airdrop winners
    mapping(address => bool) public airdropWinners;

    //uint256 private constant _DECIMALFACTOR = 10 ** uint256(_DECIMALS);
    

  /**
   * @dev Event for airdrop token claim logging
   * @param claimer Address of the airdrop winner
   * @param amount Amount of tokens claimed
   */
  event TokenClaimed(
    address indexed claimer,
    uint256 amount
  );

  /**
   * @param _airdropAmt Number of tokens for the airdrop
   * @param _tokenAddress Address of the airdrop token
   * @param _decimal Decimal of the airdrop token
   */
  constructor(uint256 _airdropAmt, address _tokenAddress, uint256 _decimal) public {
    require(_airdropAmt > 0, "constructor: _rate must be greater than zero");
    require(_tokenAddress != address(0), "constructor: _tokenAddress can not be zero");
    require(_decimal > 0, "constructor: _decimal must be greater than zero");

    // set the amount of token for airdrop
    airdropAmt = _airdropAmt * 10 ** _decimal;

    // set the token decimal
    tokenDecimal = _decimal;

    // instantiate airdrop token
    token = IBEP20(_tokenAddress);
    
  }

 
 
  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------


  
  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount > 0);
    require(!(isDistributionFinished), "Aidrop has ended.");
    
  }

    /**
   * @dev Check if a user qualifies for the airdrop
   * @param _user Address to check if it is eligible for the airdrop
   */
  function checkEligibility(address _user) public view returns(bool){
      require(_user != address(0), "checkEligibility: user address can not be zero");
      return airdropWinners[_user];
  }

    /**
   * @dev Add winners' addresses that qualifies for the airdrop
   * @param _winners Array of addresses that qualifies for the airdrop
   */
  function addAirdropWinners(address[] memory _winners) public onlyOwner{
      for(uint i = 0; i < _winners.length; i++){
          if(_winners[i] != address(0)){
              if(!airdropWinners[_winners[i]]){
                  airdropWinners[_winners[i]] = true;
              }
          }
      }      
  }
  
  /*
  * @dev Allows _beneficiary to possess the airdrop token
  * @param _beneficiary Address of the airdrop winner
  */
  function claimAirdrop(address _beneficiary) public{
      require(airdropWinners[_beneficiary], "claimAirdrop: _beneficiary");
      require(!isDistributionFinished, "claimAirdrop: airdrop has ended");

      airdropWinners[_beneficiary] = false;
      token.transfer(_beneficiary, airdropAmt);
      amountClaimed = amountClaimed.add(airdropAmt);
      TokenClaimed(_beneficiary, airdropAmt);
  }

  /*
  *@dev Ends the airdrop distribution
  */
  function endAirdrop() public onlyOwner{
      require(!isDistributionFinished, "endAirdrop: airdrop is off");
      isDistributionFinished = true;
  }
  
  /*
  *@dev Restart the airdrop distribution
  */
  function restartAirdrop() public onlyOwner{
      require(isDistributionFinished, "endAirdrop: airdrop is on");
      isDistributionFinished = false;
  }
  
  
  /*
  *@dev Change the airdrop token to a new a token
  *@param newToken Address of the new airdrop token
  *@param newDecimal Decimal of the new airdrop token
  *@param resetClaimedAmt If the amount of the airdrop claimed should be reset to zero
  */
  function setToken(address newToken, uint256 newDecimal, bool resetClaimedAmt) public onlyOwner{
      require(newToken != address(0), "setToken: Token address can not be zero");
      require(newDecimal > 0, "setToken: decimal value must be greater than zero");
      token = IBEP20(newToken);
      tokenDecimal = newDecimal;
      if(resetClaimedAmt){
          amountClaimed = 0;
      }
  }

  /*
  *@dev Change the airdrop token amount to a new a amount for distribution
  *@param newAmount New amount for the new airdrop token
  */
  function setAirdropAmt(uint256 newAmount) public onlyOwner{
      require(newAmount > 0, "setAirdropAmt: Token amount must be greater than zero");
      airdropAmt = newAmount * 10 ** tokenDecimal;
  }
  
  /*
  *@dev Change the airdrop token amount to a new a amount for distribution
  *@param newDecimal New amount for the new airdrop token
  */
  function setTokenDecimal(uint256 newDecimal) public onlyOwner{
      require(newDecimal > 0, "setTokenDecimal: decimal value must be greater than zero");
      tokenDecimal = newDecimal;
  }
  
  /*
  *@dev Withdraw all the airdrop tokens from the contract
  *@param addr Address to receive the airdrop token
  */
  function withdrawAllTokens(address addr) public onlyOwner{
      require(addr != address(0), "withdrawAllTokens: Withdrawal address can not be zero");
      token.transfer(addr, token.balanceOf(address(this)));
  }
  
  /*
  *@dev Withdrawal all Eth from the contract
  *@param addr Address to receive the Eth
  */
  function WithdrawAllEth(address payable addr) public onlyOwner{
      require(addr != address(0), "withdrawAllEth: Withdrawal address can not be zero");
      addr.transfer(address(this).balance);
  }

}