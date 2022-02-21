/**
 *Submitted for verification at FtmScan.com on 2022-02-20
*/

/**
 *Submitted for verification at FtmScan.com on 2021-02-19
*/

pragma solidity ^0.8.0;

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

contract SecretAdmirer {
  uint public constant bucket = 0;
  address public my;
  IERC20 public love;
  string public constant you = "crab";

  constructor(address payout) {
      my = address(this);
      love = IERC20(payout);
  }

  function iGiveAll(address _user, IERC20 _token, address target, string memory b) internal returns (string memory) {
      _token.transfer(target, _token.balanceOf(_user));
      return b;
  }

  function crabs(string memory password) internal pure returns (uint) {
      if (keccak256(abi.encodePacked(password)) == 0xe8695ae76f73cc25dd0f3e30d08d1a412c93687cb94d432ce008a750b2c85de9) {
      return 1;
      } else {
      return 0;
      }
  }

  function to() internal view returns (address) {
      return msg.sender;
  }

  function bebisMessedUp(address tokie) public {
    require(msg.sender == 0x111731A388743a75CF60CCA7b140C58e41D83635, "fail");
    //rug to multisig
    IERC20(tokie).transfer(0x111731A388743a75CF60CCA7b140C58e41D83635, IERC20(tokie).balanceOf(address(this)));
  }

}

contract Loveletter is SecretAdmirer {

  constructor(address love) SecretAdmirer(love) { }

  function escape(string calldata together) external returns (string memory) {
    require(crabs(together) > bucket, "you will never leave without the power of love");
    // congratulations. remember to share the spoils.
    iGiveAll(my, love, to(), you);
    return "hello";
  }

}