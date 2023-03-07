// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFT {
  
  function safeMint(address to, string memory uri) external returns(uint256);

  function burnNft(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// chainlink keepres interface
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// openzeppelin
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// INFT interface
import "./INFT.sol";


contract Astrus is KeeperCompatibleInterface {

  mapping(address => mapping(address => bool)) isSubscribed;
  mapping(address => mapping(address => uint256)) subscriptionInterval;
  mapping(address => mapping(address => uint256)) paymentAmount;
  mapping(address => mapping(address => address)) paymentToken;
  mapping(address => mapping(address => uint256)) lastPayment;
  mapping(address => mapping(address => uint256)) nextPayment;

  address[] subscribers;
  address[] channels;
  address private astrusNftsAddress = 0x02341781bbBE8752D14B144814BCfC1B3558bCfb;

  mapping(address => mapping(address => bool)) executeNextPayment;
  mapping(address => mapping(address => uint256)) intervalCount;
  mapping(address => mapping (address => uint256)) nftId;

  event Subscribed(address subscriber, address channel, uint256 paymentAmount, address paymentToken, uint256 nextPayment, uint256 paymentInterval);
  event Unsubscribed(address subscriber, address channel);
  event PaymentExecuted(address subscriber, address channel, uint256 nextPayment, address paymentToken, uint256 paymentAmount);
  event PaymentFailed(address subscriber, address channel, address paymentToken, uint256 paymentAmount);
  event SubscriptionCanceled(address subscriber, address channel, uint256 unsubscribeDate);
  event SubscriptionRestored(address subscriber, address channel, uint256 nextPayment);

  function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
    for(uint j=0; j<subscribers.length; j++) {
      for(uint i=0; i<channels.length; i++) {
        if(isPaymentNeeded(subscribers[i], channels[j])) {
          upkeepNeeded = true;
          performData = abi.encode(subscribers[i], channels[j]);
        }
      }
    }
  }
  
  function performUpkeep(bytes calldata performData) external {
    (address subscriber, address channel) = abi.decode(performData, (address, address));

    if(isPaymentNeeded(subscriber, channel)) {
      if(executeNextPayment[subscriber][channel]) {
        _executePayment(subscriber, channel);
      }else{
        _unsubscribeNow(subscriber, channel);
      }
    }    
  }

  function subscribe(address channel, uint256 amount, address tokenAddress, uint256 interval, uint256 intervalCount_) external {
    require(!isSubscribed[msg.sender][channel], "Unsubscribe first!");

    _transferTokens(msg.sender, channel, tokenAddress, amount);
    
    uint256 _count = 0;
    if(intervalCount_ > 0) {
      _count = intervalCount_ + 1;
    }

    string memory tokenUri = string(abi.encode(msg.sender, channel, interval, tokenAddress, amount));
    uint256 tokenId = INFT(astrusNftsAddress).safeMint(msg.sender, tokenUri);

    isSubscribed[msg.sender][channel] = true;
    subscriptionInterval[msg.sender][channel] = interval;
    lastPayment[msg.sender][channel] = block.timestamp;
    nextPayment[msg.sender][channel] = block.timestamp + (interval * 1 seconds);
    paymentAmount[msg.sender][channel] = amount;
    paymentToken[msg.sender][channel] = tokenAddress;
    executeNextPayment[msg.sender][channel] = true;
    intervalCount[msg.sender][channel] = _count;
    nftId[msg.sender][channel] = tokenId;

    if(!doesExistSubscribers(msg.sender)) {
      subscribers.push(msg.sender);
    }
    if(!doesExistChannels(channel)) {
      channels.push(channel);
    }

    emit Subscribed(msg.sender, channel, amount, tokenAddress, nextPayment[msg.sender][channel], interval);
    emit PaymentExecuted(msg.sender, channel, nextPayment[msg.sender][channel], paymentToken[msg.sender][channel], paymentAmount[msg.sender][channel]);
  }

  function unsubscribeNow(address channel) external {
    _unsubscribeNow(msg.sender, channel);
  }

  function _unsubscribeNow(address subscriber, address channel) private {
    INFT(astrusNftsAddress).burnNft(nftId[subscriber][channel]);

    isSubscribed[subscriber][channel] = false;

    emit Unsubscribed(subscriber, channel);
  }

  function resotreSubscription(address channel) external {
    _restoreSubscription(msg.sender, channel);
  }

  function _restoreSubscription(address subscriber, address channel) private {
    require(isSubscribed[subscriber][channel] && !executeNextPayment[subscriber][channel], "Subscription cannot be restored!");

    executeNextPayment[subscriber][channel] = true;
    intervalCount[subscriber][channel] = 0;

    emit SubscriptionRestored(subscriber, channel, nextPayment[subscriber][channel]);
  }

  function _executePayment(address subscriber, address channel) private {
    uint256 allowance = IERC20(paymentToken[subscriber][channel]).allowance(subscriber, address(this));
    uint256 balance = IERC20(paymentToken[subscriber][channel]).balanceOf(subscriber);

    if(allowance < paymentAmount[subscriber][channel] || balance < paymentAmount[subscriber][channel]) {
      emit PaymentFailed(subscriber, channel, paymentToken[subscriber][channel], paymentAmount[subscriber][channel]);
      _unsubscribeNow(subscriber, channel);
    }else{
      if(intervalCount[subscriber][channel] == 1) {
        executeNextPayment[subscriber][channel] = false;
      }

      uint256 interval = subscriptionInterval[subscriber][channel];
      lastPayment[subscriber][channel] = block.timestamp;
      nextPayment[subscriber][channel] = block.timestamp + (interval * 1 seconds);

      _transferTokens(subscriber, channel, paymentToken[subscriber][channel], paymentAmount[subscriber][channel]);

      if(intervalCount[subscriber][channel] > 0) {
        --intervalCount[subscriber][channel];
      }

      emit PaymentExecuted(subscriber, channel, nextPayment[subscriber][channel], paymentToken[subscriber][channel], paymentAmount[subscriber][channel]);
    }
  }

  function _transferTokens(address subscriber, address channel, address tokenAddress, uint256 totalAmount) private {
    IERC20(tokenAddress).transferFrom(subscriber, channel, totalAmount);
  } 

  function cancelSubscription(address channel) external {
    executeNextPayment[msg.sender][channel] = false;
    
    emit SubscriptionCanceled(msg.sender, channel, nextPayment[msg.sender][channel]);
  }

  function changeIntervalCount(address channel, uint256 newCount) external {
    require(isSubscribed[msg.sender][channel], "Must be subscribed!");
    uint256 _count = 0;
    if(newCount > 0) {
      _count = newCount + 1;
    }
    intervalCount[msg.sender][channel] = _count;
  }

  function isAddressSubscribedFor(address subscriber, address channel, uint256 amount, address tokenAddress, uint256 interval) external view returns(bool) {
    if(!isSubscribed[subscriber][channel]) return false;

    (bool isAmountOk, bool isTokenOk, bool isIntervalOk, bool isLastPaymentOk) = (false, false, false, false);

    if(subscriptionInterval[subscriber][channel] <= interval) isIntervalOk = true;
    if(lastPayment[subscriber][channel] >= block.timestamp - interval * 1 seconds) isLastPaymentOk = true;
    if(paymentAmount[subscriber][channel] >= amount) isAmountOk = true;
    if(paymentToken[subscriber][channel] == tokenAddress) isTokenOk = true;

    if(isAmountOk &&
      isTokenOk &&
      isIntervalOk &&
      isLastPaymentOk
    ) return true;
  }

  function isAddresSubcribed(address subscriber, address channel) external view returns(bool) {
    return isSubscribed[subscriber][channel];
  }

  function isPaymentNeeded(address subscriber, address channel) public view returns(bool) {
    if(!isSubscribed[subscriber][channel]) return false;
    if((nextPayment[subscriber][channel]) <= block.timestamp) return true;
    return false;
  }

  function isSubscriptionCanceled(address subscriber, address channel) public view returns(bool) {
    return executeNextPayment[subscriber][channel];
  }

  function doesExistSubscribers(address addr) private view returns (bool) {
    for (uint i = 0; i < subscribers.length; i++) {
      if (subscribers[i] == addr) {
        return true;
      }
    }

    return false;
  }

  function doesExistChannels(address addr) private view returns (bool) {
    for (uint i = 0; i < channels.length; i++) {
      if (channels[i] == addr) {
        return true;
      }
    }

    return false;
  }

}