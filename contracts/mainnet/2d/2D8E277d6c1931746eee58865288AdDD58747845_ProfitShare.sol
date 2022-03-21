//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./interfaces/ERC20Interface.sol";
import "./libraries/TransferHelper.sol";

contract ProfitShare {
  struct Investor {
    address addr;
    uint256 percent;
  }
  address public owner;
  Investor[] public investors;
  address public token;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );
  modifier onlyOwner() {
    require(msg.sender == owner, "oo");
    _;
  }
  modifier notInvestor(address addr) {
    uint256 length = investors.length;
    bool bExist = false;
    for (uint256 _id = 0; _id < length; _id++) {
      if (investors[_id].addr == addr) {
        bExist = true;
      }
    }
    require(bExist == false, "already added investor list");
    _;
  }
  modifier investor(address addr) {
    uint256 length = investors.length;
    bool bExist = false;
    for (uint256 _id = 0; _id < length; _id++) {
      if (investors[_id].addr == addr) {
        bExist = true;
      }
    }
    require(bExist == true, "not investor");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  // verified
  function transaferOwnership(address newOwner) public onlyOwner {
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function investorCount() external view returns (uint256) {
    return investors.length;
  }

  function addInvestor(address addr, uint256 percent)
    external
    onlyOwner
    notInvestor(addr)
  {
    investors.push(Investor(addr, percent));
  }

  function updateInfo(
    uint256 _id,
    address addr,
    uint256 percent
  ) external onlyOwner {
    uint256 length = investors.length;
    require(_id < length, "invalid id");
    investors[_id].addr = addr;
    investors[_id].percent = percent;
  }

  function removeInvestor(uint256 _id) external onlyOwner {
    uint256 length = investors.length;
    require(_id < length, "invalid id");
    investors[_id] = investors[length - 1];
    investors.pop();
  }

  function setToken(address _token) external onlyOwner {
    token = _token;
  }

  function divide() external {
    uint256 totalShare = 0;
    uint256 length = investors.length;
    uint256 _id;
    uint256 sendAmount;
    for (_id = 0; _id < length; _id++) {
      totalShare += investors[_id].percent;
    }
    require(totalShare > 0, "invalid share");

    uint256 tokenBlance = getBalance();
    for (_id = 0; _id < length; _id++) {
      sendAmount = (tokenBlance * investors[_id].percent) / totalShare;
      sendToken(investors[_id].addr, sendAmount);
    }
  }

  function getBalance() public view returns(uint256) {
    uint256 balance;
    if (token == address(0)) {
      address payable self = payable(address(this));
      balance = self.balance;
    } else {
      balance = ERC20Interface(token).balanceOf(address(this));
    }
    return balance;
  }

  function sendToken(address addr, uint256 amount) private {
    uint256 curBalance = getBalance();
    if (amount > curBalance) {
      amount = curBalance;
    }
    if (token == address(0)) {
      TransferHelper.safeTransferETH(addr, amount);
    } else {
      TransferHelper.safeTransfer(token, addr, amount);
    }
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface ERC20Interface {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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