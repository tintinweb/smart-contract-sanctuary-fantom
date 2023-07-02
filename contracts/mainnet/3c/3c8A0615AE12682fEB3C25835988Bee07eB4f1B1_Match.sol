//SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.17;

// Useful for debugging. Remove when deploying to a live network.
import "./libraries/MatchLibrary.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IMatch.sol";

contract Match is IMatch {
  // State Variables
  address public owner;
  uint8 private unlocked;
  address public bank;
  uint88 public minReward;

  uint256 public constant PRICE_DECIMALS = 1e18;

  /// @dev first address is the user, second address is the token, uint256 is the user balance
  mapping(address => mapping(address => uint256)) public usersBalances;
  /// @dev first address is the token to sell, second address is the token to buy, order is the order information for thes tokens
  mapping(address => mapping(address => MatchLibrary.Order[])) public orders;

  event Deposit(address indexed user, address indexed token, uint256 desiredAmount, uint256 depositedAmount);
  event AddOrder(
    address indexed user,
    address indexed tokenToSell,
    address indexed tokenToBuy,
    uint256 indexOrder,
    MatchLibrary.Order order
  );
  event MatchOrder(
    address indexed userA,
    address indexed tokenToSell,
    address indexed tokenToBuy,
    address userB,
    uint256 indexOrderA,
    uint256 indexOrderB,
    MatchLibrary.Order orderA,
    MatchLibrary.Order orderB
  );
  event Withdraw(address indexed user, address indexed to, uint256 amount);
  event CancelOrder(
    address indexed user,
    address indexed tokenToSell,
    address indexed tokenToBuy,
    uint256 indexOrder,
    MatchLibrary.Order order
  );

  error NotTheOwner();
  error NoAction();
  error UnknownAction();
  error AddressZero();
  error NoAmount();
  error RewardTooLow();
  error InsufficientAmount();
  error OrderInactive();
  error OverflowPrice();
  error PriceTooHigh();
  error OrderAIncorrectlyFulfilled();
  error OrderBIncorrectlyFulfilled();
  error TraderANotEnoughToken();
  error TraderBNotEnoughToken();
  error NotOwner();
  error Locked();
  error SameUser();
  error SameToken();
  error TransferFailed();
  error ETHTransferFailed();
  error TransferFromFailed();

  // Constructor: Called once on contract deployment
  // Check packages/hardhat/deploy/00_deploy_your_contract.ts
  constructor(address _owner, address _bank, uint88 _minReward) {
    owner = _owner;
    bank = _bank;
    minReward = _minReward;
    unlocked = 1;
  }

  modifier lock() {
    if (unlocked == 0) {
      revert Locked();
    }
    unlocked = 0;
    _;
    unlocked = 1;
  }

  // Modifier: used to define a set of rules that must be met before or after a function is executed
  // Check the withdraw() function
  modifier isOwner() {
    // msg.sender: predefined variable that represents address of the account that called the current function
    if (msg.sender != owner) {
      revert NotTheOwner();
    }
    _;
  }

  // External functions

  function changeBank(address newBank) external isOwner lock {
    require(newBank != address(0));
    bank = newBank;
  }

  function transferOwnership(address newOwner) external isOwner lock {
    require(newOwner != address(0));
    owner = newOwner;
  }

  function withdraw() external isOwner lock {
    uint256 amount = usersBalances[bank][MatchLibrary.NATIVE_TOKEN];
    usersBalances[bank][MatchLibrary.NATIVE_TOKEN] -= amount;
    TransferHelper.safeTransferETH(bank, amount);
  }

  function execute(
    MatchLibrary.Action[] calldata actions
  ) external payable lock returns (uint256 amount, uint256 reward) {
    if (actions.length == 0) {
      revert NoAction();
    }
    uint256 nativeAmount = msg.value;
    uint256 i;
    do {
      MatchLibrary.Action memory action = actions[i];
      if (action.actionType == MatchLibrary.ActionType.Deposit) {
        amount += _deposit(action);
      } else if (action.actionType == MatchLibrary.ActionType.AddOrder) {
        amount += _addOrder(action);
      } else if (action.actionType == MatchLibrary.ActionType.Match) {
        reward += _match(action);
      } else if (action.actionType == MatchLibrary.ActionType.Withdraw) {
        _withdraw(action);
      } else if (action.actionType == MatchLibrary.ActionType.WithdrawTo) {
        _withdrawTo(action);
      } else if (action.actionType == MatchLibrary.ActionType.Cancel) {
        _cancel(action);
      } else {
        revert UnknownAction();
      }
      i++;

      if (amount > nativeAmount) {
        revert InsufficientAmount();
      }
    } while (i < actions.length);

    nativeAmount -= amount;

    if (nativeAmount > 0) {
      TransferHelper.safeTransferETH(msg.sender, nativeAmount);
    }
  }

  function fetchPageOrders(
    address tokenToSell,
    address tokenToBuy,
    uint256 cursor,
    uint256 howMany
  ) external view returns (MatchLibrary.Order[] memory values, uint256 newCursor) {
    uint256 length = howMany;
    uint256 orderCount = orders[tokenToSell][tokenToBuy].length;
    if (length > orderCount - cursor) {
      length = orderCount - cursor;
    }

    values = new MatchLibrary.Order[](length);
    for (uint256 i = 0; i < length; i++) {
      values[i] = orders[tokenToSell][tokenToBuy][cursor + i];
    }

    return (values, cursor + length);
  }

  // External functions that are view

  function getOrder(
    address tokenToSell,
    address tokenToBuy,
    uint256 index
  ) external view returns (MatchLibrary.Order memory) {
    return orders[tokenToSell][tokenToBuy][index];
  }

  function countOrders(address tokenToSell, address tokenToBuy) external view returns (uint256) {
    return orders[tokenToSell][tokenToBuy].length;
  }

  // External functions that are pure

  function getActionDeposit(address token, uint256 amount) external pure returns (MatchLibrary.Action memory action) {
    bytes memory data = abi.encode(token, amount);
    action = MatchLibrary.Action(MatchLibrary.ActionType.Deposit, data);
  }

  function getActionAddOrder(
    address tokenToSell,
    address tokenToBuy,
    uint88 reward,
    uint128 amountToSell,
    uint128 amountToBuy
  ) external pure returns (MatchLibrary.Action memory action) {
    bytes memory data = abi.encode(tokenToSell, tokenToBuy, reward, amountToSell, amountToBuy);
    action = MatchLibrary.Action(MatchLibrary.ActionType.AddOrder, data);
  }

  function getActionMatch(
    address tokenToSell,
    address tokenToBuy,
    uint256 indexOrderA,
    uint256 indexOrderB
  ) external pure returns (MatchLibrary.Action memory action) {
    bytes memory data = abi.encode(tokenToSell, tokenToBuy, indexOrderA, indexOrderB);
    action = MatchLibrary.Action(MatchLibrary.ActionType.Match, data);
  }

  function getActionWithdraw(address token, uint256 amount) external pure returns (MatchLibrary.Action memory action) {
    bytes memory data = abi.encode(token, amount);
    action = MatchLibrary.Action(MatchLibrary.ActionType.Withdraw, data);
  }

  function getActionWithdrawTo(
    address token,
    address to,
    uint256 amount
  ) external pure returns (MatchLibrary.Action memory action) {
    bytes memory data = abi.encode(token, to, amount);
    action = MatchLibrary.Action(MatchLibrary.ActionType.WithdrawTo, data);
  }

  function getActionCancel(
    address tokenToSell,
    address tokenToBuy,
    uint256 indexOrder
  ) external pure returns (MatchLibrary.Action memory action) {
    bytes memory data = abi.encode(tokenToSell, tokenToBuy, indexOrder);
    action = MatchLibrary.Action(MatchLibrary.ActionType.Cancel, data);
  }

  // Private functions

  function _deposit(MatchLibrary.Action memory action) private returns (uint256 removeAmount) {
    (address token, uint256 amount) = abi.decode(action.data, (address, uint256));
    uint256 depositedAmount;
    if (token == MatchLibrary.NATIVE_TOKEN) {
      removeAmount = amount;
      usersBalances[msg.sender][token] += amount;
      depositedAmount = amount;
    } else {
      uint256 balanceBefore = IERC20(token).balanceOf(address(this));
      TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
      uint256 balance = IERC20(token).balanceOf(address(this)) - balanceBefore;
      // get the smaller for tax or reflection token
      depositedAmount = balance > amount ? amount : balance;
      usersBalances[msg.sender][token] += depositedAmount;
    }
    emit Deposit(msg.sender, token, amount, depositedAmount);
  }

  function _addOrder(MatchLibrary.Action memory action) private returns (uint256 removeAmount) {
    (address tokenToSell, address tokenToBuy, uint88 reward, uint128 amountToSell, uint128 amountToBuy) = abi.decode(
      action.data,
      (address, address, uint88, uint128, uint128)
    );
    if (tokenToSell == address(0) || tokenToBuy == address(0)) {
      revert AddressZero();
    }
    if (tokenToSell == tokenToBuy) {
      revert SameToken();
    }
    if (amountToBuy == 0 || amountToSell == 0) {
      revert NoAmount();
    }
    if (reward < minReward) {
      revert RewardTooLow();
    }

    removeAmount = reward;
    // 10% commission
    uint88 rewardToBank = (reward * 10) / 100;
    uint88 rewardToBot = reward - rewardToBank;
    usersBalances[bank][MatchLibrary.NATIVE_TOKEN] += rewardToBank;

    uint256 indexOrder = orders[tokenToSell][tokenToBuy].length;

    MatchLibrary.Order memory order = MatchLibrary.Order(
      MatchLibrary.OrderStatus.Active,
      msg.sender,
      rewardToBot,
      amountToSell,
      amountToBuy,
      amountToSell,
      amountToBuy
    );
    // store the orders
    orders[tokenToSell][tokenToBuy].push(order);

    emit AddOrder(msg.sender, tokenToSell, tokenToBuy, indexOrder, order);
  }

  function _match(MatchLibrary.Action memory action) private returns (uint256 totalReward) {
    (address tokenToSell, address tokenToBuy, uint256 indexOrderA, uint256 indexOrderB) = abi.decode(
      action.data,
      (address, address, uint256, uint256)
    );
    if (tokenToSell == address(0) || tokenToBuy == address(0)) {
      revert AddressZero();
    }
    MatchLibrary.Order storage orderA = orders[tokenToSell][tokenToBuy][indexOrderA];
    // the matching order has token inversed
    MatchLibrary.Order storage orderB = orders[tokenToBuy][tokenToSell][indexOrderB];
    if (orderA.status != MatchLibrary.OrderStatus.Active || orderB.status != MatchLibrary.OrderStatus.Active) {
      revert OrderInactive();
    }

    address traderB = orderB.trader;
    address traderA = orderA.trader;

    if (traderA == traderB) {
      revert SameUser();
    }

    uint256 priceByTokenA = (orderA.amountToBuy * PRICE_DECIMALS) / orderA.amountToSell;
    uint256 priceByTokenB = (orderB.amountToSell * PRICE_DECIMALS) / orderB.amountToBuy;
    if (priceByTokenA > priceByTokenB) {
      revert PriceTooHigh();
    }

    uint128 amountTransfered = orderA.amountToBuyRest;
    if (orderA.amountToBuyRest > orderB.amountToSellRest) {
      amountTransfered = orderB.amountToSellRest;
    }

    // we sold as order B price
    uint256 sold = (amountTransfered * orderB.amountToBuy) / orderB.amountToSell;
    if (sold > type(uint128).max) {
      revert OverflowPrice();
    }
    uint128 amountSoldTransfered = uint128(sold);

    if (usersBalances[traderB][tokenToBuy] < amountTransfered) {
      revert TraderBNotEnoughToken();
    }
    if (usersBalances[traderA][tokenToSell] < amountSoldTransfered) {
      revert TraderANotEnoughToken();
    }

    // the token to buy for trader A is the token to sell for trader B
    usersBalances[traderB][tokenToBuy] -= amountTransfered;
    usersBalances[traderA][tokenToBuy] += amountTransfered;

    usersBalances[traderB][tokenToSell] += amountSoldTransfered;
    usersBalances[traderA][tokenToSell] -= amountSoldTransfered;

    orderA.amountToBuyRest -= amountTransfered;
    orderB.amountToSellRest -= amountTransfered;

    orderA.amountToSellRest -= amountSoldTransfered;
    orderB.amountToBuyRest -= amountSoldTransfered;

    if (orderA.amountToBuyRest == 0) {
      orderA.status = MatchLibrary.OrderStatus.Sold;
      // reward the bot
      usersBalances[msg.sender][MatchLibrary.NATIVE_TOKEN] += orderA.reward;
      totalReward += orderA.reward;
      orderA.reward = 0;
    } else if (orderA.amountToSellRest == 0 && orderA.amountToBuyRest > 0) {
      revert OrderAIncorrectlyFulfilled();
    } else {
      // reward the bot from the part completed
      uint88 rewardToBot = uint88((orderA.reward * amountTransfered) / orderA.amountToBuy);
      orderA.reward -= rewardToBot;
      totalReward += rewardToBot;
      usersBalances[msg.sender][MatchLibrary.NATIVE_TOKEN] += rewardToBot;
    }

    if (orderB.amountToBuyRest == 0) {
      orderB.status = MatchLibrary.OrderStatus.Sold;
      // reward the bot
      usersBalances[msg.sender][MatchLibrary.NATIVE_TOKEN] += orderB.reward;
      totalReward += orderB.reward;
      orderB.reward = 0;
    } else if (orderB.amountToSellRest == 0 && orderB.amountToBuyRest > 0) {
      revert OrderBIncorrectlyFulfilled();
    } else {
      // reward the bot from the part completed
      uint88 rewardToBot = uint88((orderB.reward * amountTransfered) / orderB.amountToSell);
      orderB.reward -= rewardToBot;
      totalReward += rewardToBot;
      usersBalances[msg.sender][MatchLibrary.NATIVE_TOKEN] += rewardToBot;
    }

    emit MatchOrder(traderA, tokenToSell, tokenToBuy, traderB, indexOrderA, indexOrderB, orderA, orderB);
  }

  function _withdraw(MatchLibrary.Action memory action) private {
    (address token, uint256 amount) = abi.decode(action.data, (address, uint256));
    if (amount > usersBalances[msg.sender][token]) {
      revert InsufficientAmount();
    }
    usersBalances[msg.sender][token] -= amount;
    TransferHelper.safeTransfer(token, msg.sender, amount);
    emit Withdraw(msg.sender, msg.sender, amount);
  }

  /// Usefull for reimbourse an other account/contract
  /// @param action action data
  function _withdrawTo(MatchLibrary.Action memory action) private {
    (address token, address to, uint256 amount) = abi.decode(action.data, (address, address, uint256));
    if (amount > usersBalances[msg.sender][token]) {
      revert InsufficientAmount();
    }
    usersBalances[msg.sender][token] -= amount;
    TransferHelper.safeTransfer(token, to, amount);
    emit Withdraw(msg.sender, to, amount);
  }

  function _cancel(MatchLibrary.Action memory action) private {
    (address tokenToSell, address tokenToBuy, uint256 indexOrder) = abi.decode(
      action.data,
      (address, address, uint256)
    );
    MatchLibrary.Order storage order = orders[tokenToSell][tokenToBuy][indexOrder];
    if (order.status != MatchLibrary.OrderStatus.Active) {
      revert OrderInactive();
    }
    if (order.trader != msg.sender) {
      revert NotOwner();
    }
    order.status = MatchLibrary.OrderStatus.Canceled;
    usersBalances[msg.sender][MatchLibrary.NATIVE_TOKEN] += order.reward;
    order.reward = 0;
    emit CancelOrder(msg.sender, tokenToSell, tokenToBuy, indexOrder, order);
  }
}

//SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.17;

library MatchLibrary {
  address constant NATIVE_TOKEN = address(1);

  enum ActionType {
    None,
    Deposit,
    AddOrder,
    Match,
    Withdraw,
    WithdrawTo,
    Cancel
  }

  enum OrderStatus {
    None,
    Active,
    Canceled,
    Sold
  }

  struct Order {
    OrderStatus status;
    address trader;
    uint88 reward;
    uint128 amountToSell;
    uint128 amountToBuy;
    uint128 amountToSellRest;
    uint128 amountToBuyRest;
  }

  struct Action{
    ActionType actionType;
    bytes data;
  }

  struct DepositData{
    address token;
    uint256 amount;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    bytes32 constant transferFromFailedSign = keccak256("TransferFromFailed()");
    bytes32 constant transferFailedSign = keccak256("TransferFailed()");
    bytes32 constant ethTransferFailedSign = keccak256("ETHTransferFailed()");

    address public constant NATIVE_TOKEN = address(1);

    bytes4 constant transferSign = 0xa9059cbb;
    bytes4 constant transferFromSign = 0x23b872dd;
    bytes4 constant balanceSign = 0x70a08231;

    error TransferFailed();
    error ETHTransferFailed();
    error TransferFromFailed();

    function safeTransfer(address token, address to, uint256 value) internal {
        if (token == NATIVE_TOKEN) {
            safeTransferETH(to, value);
        } else {
            _safeTransfer(token, to, value);
        }
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        bytes32 errorMsg = transferFailedSign;
        assembly {
            let ptr := mload(0x40)
            // store call parameters
            mstore(ptr, transferSign)
            mstore(add(ptr, 0x4), to)
            mstore(add(ptr, 0x24), value)

            // (bool success, bytes memory data) = token.call(
            //     abi.encodeWithSelector(IERC20.transfer.selector, to, value)
            // );
            let result := call(gas(), token, 0, ptr, 0x44, 0, 0)

            // check if call was succesfull, else revert
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            //     revert TransferFailed();
            // }
            if gt(returndatasize(), 0) {
                returndatacopy(0x80, 0x0, 0x20)
                let data := mload(0x80)
                if iszero(eq(data, 1)) {
                    // signature TransferFailed()
                    mstore(0, errorMsg)
                    revert(0, 0x20)
                }
            }
        }
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        if (token == NATIVE_TOKEN) {
            safeTransferETH(to, value);
        } else {
            _safeTransferFrom(token, from, to, value);
        }
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        bytes32 errorMsg = transferFromFailedSign;
        assembly {
            let ptr := mload(0x40)
            // store call parameters
            mstore(ptr, transferFromSign)
            mstore(add(ptr, 0x4), from)
            mstore(add(ptr, 0x24), to)
            mstore(add(ptr, 0x44), value)

            // (bool success, bytes memory data) = token.call(
            //     abi.encodeWithSelector(IERC20.transferFrom.selector,from, to, value)
            // );
            let result := call(gas(), token, 0, ptr, 0x64, 0, 0)

            // check if call was succesfull, else revert

            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            //  if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            //      revert TransferFromFailed(); }
            if gt(returndatasize(), 0) {
                returndatacopy(0x80, 0x0, 0x20)
                let data := mload(0x80)
                if iszero(eq(data, 1)) {
                    // signature TransferFromFailed()
                    mstore(0, errorMsg)
                    revert(0, 0x20)
                }
            }
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        bytes32 errorMsg = ethTransferFailedSign;
        assembly {
            let result := call(gas(), to, value, 0, 0, 0, 0)

            // check if call was succesfull, else revert
            if iszero(result) {
                // signature ETHTransferFailed()
                mstore(0, errorMsg)
                revert(0, 0x20)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: BSL 1.1
pragma solidity ^0.8.17;

import "../libraries/MatchLibrary.sol";

interface IMatch {
  function minReward() external returns (uint88);

  function usersBalances(address user, address token) external returns (uint256);

  function execute(MatchLibrary.Action[] calldata actions) external payable returns (uint256 amount, uint256 reward);

  function fetchPageOrders(
    address tokenToSell,
    address tokenToBuy,
    uint256 cursor,
    uint256 howMany
  ) external view returns (MatchLibrary.Order[] memory values, uint256 newCursor);

  function getOrder(
    address tokenToSell,
    address tokenToBuy,
    uint256 index
  ) external view returns (MatchLibrary.Order memory);

  function countOrders(address tokenToSell, address tokenToBuy) external view returns (uint256);

  function getActionDeposit(address token, uint256 amount) external pure returns (MatchLibrary.Action memory action);

  function getActionAddOrder(
    address tokenToSell,
    address tokenToBuy,
    uint88 reward,
    uint128 amountToSell,
    uint128 amountToBuy
  ) external pure returns (MatchLibrary.Action memory action);

  function getActionMatch(
    address tokenToSell,
    address tokenToBuy,
    uint256 indexOrderA,
    uint256 indexOrderB
  ) external pure returns (MatchLibrary.Action memory action);

  function getActionWithdraw(address token, uint256 amount) external pure returns (MatchLibrary.Action memory action);

  function getActionWithdrawTo(
    address token,
    address to,
    uint256 amount
  ) external pure returns (MatchLibrary.Action memory action);

  function getActionCancel(
    address tokenToSell,
    address tokenToBuy,
    uint256 indexOrder
  ) external pure returns (MatchLibrary.Action memory action);
}