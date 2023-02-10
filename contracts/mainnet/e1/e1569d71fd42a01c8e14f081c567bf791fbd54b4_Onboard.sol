/**
 *Submitted for verification at FtmScan.com on 2023-02-10
*/

// Onboard.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * This contract is used to onboard new users to Cherrific.io.
 *
 * Instead of:
 *   - buy CHRY tokens on SpookySwap
 *   - allow Cherrific smart contract to spend your CHRY tokens
 *   - fill your internal CHRY balance to use Cherrific
 *
 * You can simply:
 *   - send FTM to this contract
 *   - it will fill your internal CHRY balance for you (= CHRF)
 *
 * This saves you from having to buy CHRY tokens on SpookySwap
 * and the allow step.
 *
 * The contract checks it has enough CHRF tokens to fill your balance.
 * If not, transaction will revert.
 *
 * Anyone can fill the CHRF balance of that contract. (that is, the CHRY
 * balance of this contract inside Cherrific smart contract)
 *
 * Owner powers:
 *   - change ownership of contract
 *   - withdraw FTM from contract
 *
 * For all the details about this contract:
 * https://cherrific.io/0xedB00816FB204b4CD9bCb45FF2EF693E99723484/story/70
 */

// From OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// simplified (not is Context)

abstract contract Ownable {
  // ==== Events      ====
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  // ==== Storage     ====
  // Private so it cannot be changed by inherited contracts
  address private _owner;

  // ==== Constructor ====
  constructor() {
    _transferOwnership(msg.sender);
  }


  // ==== Modifiers   ====
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  // ==== Views       ====
  function owner() public view virtual returns (address) {
    return _owner;
  }


  // ==== Mutators    ====
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner_) public virtual onlyOwner {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner_);
  }


  // ==== Internals   ====
  function _transferOwnership(address newOwner_) internal virtual {
    address oldOwner = owner();
    _owner = newOwner_;
    emit OwnershipTransferred(oldOwner, newOwner_);
  }
}

// From OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
interface IERC20 {
    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply()                             external view returns (uint256);
    function balanceOf(address account)                external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(     address to,                uint256 amount)  external returns (bool);
    function approve(      address spender,           uint256 amount)  external returns (bool);
    function transferFrom( address from,  address to, uint256 amount ) external returns (bool);
}

interface IOracle {
  function epoch()  external view returns(uint32);
  function twap()   external view returns(uint112);
  function update() external      returns(bool);
}

interface ICherrificUser {
  // users as they are written in Storage
  // 1 slot
  struct StorageUser {
    // slot 1
    uint32 id;			       // uint32
    uint32 balance;		     // uint32	current balance of user available for withdraws
    uint32 earned;         // all that he received
    uint32 reputation;	   // sum of all received money -  sum of all negative reactions
    uint32 generosity;	   // sum of all sent money (comments + positive reactions)
    uint32 owner;          // owner of the contract (in case this user is a contract)
    uint32 createdAt;      // moment the account was created
    uint24 nextStoryId;    // current next story id of user
    bool   autoValidate;	 // bool
                           // 217 bits in all = 27 bytes + 1 bit
  }

  // users as they are kept in Memory
  struct MemoryUser {
    address userAddress;
    StorageUser stored;
  }
	function getUser(address address_) external view returns(MemoryUser memory user);
}

contract Onboard is Ownable {

  // ==== Events ====
  event Swaped(address indexed user, uint CHRFamount, uint FTMamount);

  // ==== Constants ====
  address constant cherrific = 0xD022D9AC8bdE380B028682664b5F58d034254BEf;
  address constant oracle    = 0x2bcC8dA3fE1BF5637262c9c05663490f14C981d6;

  // ==== Storage   ====
  // None.
  // The only state is the CHRF balance of this contract in the Cherrific smart contract.

  // ==== Views    ====

  // return the CHRF balance of this contract
  function balance() public view returns (uint) {
    return IERC20(cherrific).balanceOf(address(this));
  }

  // estimage how much CHRF will be bought with the FTM sent
  function estimate(uint value) public view returns (uint) {
    // get the latest CHRY TWAP from oracle
    uint twap = IOracle(oracle).twap();

    // compute how much CHRF will be bought with the FTM sent
    // 15% premium on price
    // this amount is rounded to integer with 18 0 decimals
    uint amount = value / twap * 85 / 100 * 1e18;

    // check if contract has enough CHRY
    require(balance() >= amount, "This contract does not have enough CHRF");

    // check if user already has an accound on Cherrific
    // if not, remove one CHRY from tranfer amount
    // because one CHRF will be taken from this contract balance to create the account
    try ICherrificUser(cherrific).getUser(msg.sender) {
      return amount;
    } catch Error(string memory) {
      // if not, remove one CHRY from tranfer amount
      // because one CHRF will be taken from this contract balance to create the account
      amount -= 1e18;
      return amount;
    }
  }

  // ==== Modifiers ====
  // default receive function
  // will be called when user sends FTM to this contract
  // it cannot return anything
  receive() external payable {

    // transfer CHRF to user on Cherrific smart contract
    uint amount = estimate(msg.value);
    IERC20(cherrific).transfer(msg.sender, amount);

    emit Swaped(msg.sender, amount, msg.value);

  }


  // ==== Governance  ====
  // withdran all FTM from contract
  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

}