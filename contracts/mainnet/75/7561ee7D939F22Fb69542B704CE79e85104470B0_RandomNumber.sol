// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns(uint);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ArbSys} from "./arbitrum/ArbSys.sol";
import {ArbGasInfo} from "./arbitrum/ArbGasInfo.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
  address private constant ARBGAS_ADDR = address(0x000000000000000000000000000000000000006C);
  ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);
  uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;

  function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      if ((getBlockNumber() - blockNumber) > 256 || blockNumber >= getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  function getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }

  function getCurrentTxL1GasFees() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      return ARBGAS.getCurrentTxL1GasFees();
    }
    return 0;
  }

  /**
   * @notice Returns the gas cost in wei of calldataSizeBytes of calldata being posted
   * @notice to L1.
   */
  function getL1CalldataGasCost(uint256 calldataSizeBytes) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      (, uint256 l1PricePerByte, , , , ) = ARBGAS.getPricesInWei();
      // see https://developer.arbitrum.io/devs-how-tos/how-to-estimate-gas#where-do-we-get-all-this-information-from
      // for the justification behind the 140 number.
      return l1PricePerByte * (calldataSizeBytes + 140);
    }
    return 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface RandomNumberInterface {
  
  struct RandomNumberRequest {
    address requestReciver;
    address user;
    uint256 requestBlockNumber;
    uint256 maxFee;
    uint32 gasLimit;
    uint32 randomNumberCount;
    uint8 requestConfirmations;
  }

  // node management
  function registerNode() external;
  function unregisterNode() external;  
  function collectFees() external;

  // user
  function deposit() external payable;
  function withdraw(uint256 amount) external;
  function depositUser(address userAddress) external payable;
  function withdrawUser(address userAddress, uint256 amount) external;
  function refundExpiredRequest(uint256 requestId) external;

  // RandomNumber
  function estimateFee(uint256 gasUsed) external view returns (uint256 nativeTokenUsedWithFee);
  function isPrioritySender(address operator, uint256 blocknumber) external view returns (bool);
  function requestRandom(address user, uint32 gasLimit, uint32 randomNumberCount, uint8 requestConfirmations) external payable returns (uint256 requestId);
  function fulfillRandomRequest(uint256 requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract RandomNumberReciverBase {
  error WrongRandomNumberSender(address randomNumberAddress, address sender);
  address private immutable randomNumberAddress;

  constructor(address _randomNumberAddress) {
    randomNumberAddress = _randomNumberAddress;
  }

  function rawRandomNumberCallback(uint256 requestId, uint256[] memory randomNumbers) external {
    if (msg.sender != randomNumberAddress) {
      revert WrongRandomNumberSender(randomNumberAddress, msg.sender);
    }
    randomNumberCallback(requestId, randomNumbers);
  }

  function randomNumberCallback(uint256 requestId, uint256[] memory randomNumbers) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./interface/RandomNumberInterface.sol";
import "./interface/RandomNumberReciverBase.sol";
import "./ChainSpecificUtil.sol";

contract RandomNumber is RandomNumberInterface {

  // EVENTS
  event Node_Registered(address indexed operator);
  event Node_Removed(address indexed operator);
  event Fees_Collected(address indexed operator, uint256 amount);

  event User_Deposit(address indexed user, uint256 depositAmount, uint256 newBalance);
  event User_Withdraw(address indexed user, uint256 withdrawAmount, uint256 newBalance);
  event RefundedRequest(uint256 indexed requestId, address indexed user);

  event RandomNumberRequested(uint256 indexed requestId, RandomNumberRequest newRequest);
  event RandomNumberResult(uint256 indexed requestId, uint256[] randomness, bool success);
  event Fee_Collected(uint256 indexed requestId, address indexed operator, address indexed user, uint256 amount);

  // ERRORS
  error Not_Priority_Sender();

  uint256 priorityBlockCount = 10;

  uint256 paymentGasOverhead = 100000;  
  uint256 feeNumerator = 50;
  uint256 feeDenominator = 1000;

  constructor() {}

  // node management
  address[] private nodes;
  mapping(address => uint16) private nodeIndexes;
  mapping(address => uint256) private nodeBalance;

  function registerNode() external {
    uint16 index = nodeIndexes[msg.sender];
    require(index == 0 && msg.sender != nodes[0], "Node already registered");

    nodes.push(msg.sender);
    nodeIndexes[msg.sender] = uint16(nodes.length - 1);

    emit Node_Registered(msg.sender);
  }

  function unregisterNode() external {
    uint16 index = nodeIndexes[msg.sender];
    if (index > 0 || msg.sender == nodes[0]) {
      _removeNode(index);
    }
  }

  function collectFees() public {
    uint256 amount = nodeBalance[msg.sender];
    nodeBalance[msg.sender] = 0;
    (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
    require(sent, "Failed to collectFees");

    emit Fees_Collected(msg.sender, amount);
  }

  function _removeNode(uint16 index) internal {
    require(index > 0 && index < nodes.length, "Invalid index");
    nodes[index] = nodes[nodes.length - 1];
    nodes.pop();
    emit Node_Removed(msg.sender);

    collectFees();
  }

  // user
  mapping(address => uint256) private userBalance;

  function deposit() external payable {
    _deposit(msg.sender, msg.value);
  }

  function withdraw(uint256 amount) external {
    _withdraw(msg.sender, amount);
  }

  function depositUser(address userAddress) external payable {
    _deposit(userAddress, msg.value);
  }

  function withdrawUser(address userAddress, uint256 amount) external {
    _withdraw(userAddress, amount);
  }

  function refundExpiredRequest(uint256 requestId) external {
    RandomNumberRequest memory randomNumberRequest = pendingRequests[requestId];
    require(randomNumberRequest.requestBlockNumber > 0 && randomNumberRequest.requestBlockNumber + 256 < ChainSpecificUtil.getBlockNumber(), "No expired request");
    userBalance[randomNumberRequest.user] += randomNumberRequest.maxFee;

    emit RefundedRequest(requestId, randomNumberRequest.user);
  }

  function _deposit(address userAddress, uint256 amount) internal {
    userBalance[userAddress] += uint256(amount);

    emit User_Deposit(userAddress, amount, userBalance[userAddress]);
  }

  function _withdraw(address userAddress, uint256 amount) internal {
    require(userBalance[userAddress] > amount, "InsufficientBalance");
    userBalance[userAddress] -= amount;
    (bool sent, bytes memory data) = userAddress.call{value: amount}("");
    require(sent, "Failed to withdraw");

    emit User_Withdraw(userAddress, amount, userBalance[userAddress]);
  }

  // RandomNumber
  RandomNumberRequest[] pendingRequests;
  uint256 nextRequestId = 0;

  function estimateFee(uint256 gasUsed) public view returns (uint256 nativeTokenUsedWithFee) {
    uint256 nativeTokenUsed = (paymentGasOverhead + gasUsed) * tx.gasprice + ChainSpecificUtil.getCurrentTxL1GasFees();
    nativeTokenUsedWithFee = (nativeTokenUsed * (feeNumerator + feeDenominator)) / feeDenominator;
  }

  function isPrioritySender(address operator, uint256 blocknumber) public view returns (bool) {
    bytes32 requestBlockBlockhash = ChainSpecificUtil.getBlockhash(uint64(blocknumber));
    uint256 priorityNodeIndex = uint(requestBlockBlockhash) % nodes.length;
    return operator == nodes[priorityNodeIndex];
  }

  function requestRandom(address user, uint32 gasLimit, uint32 randomNumberCount, uint8 requestConfirmations) external payable returns (uint256 requestId) {
    uint256 maxFee = (estimateFee(gasLimit) * 13) / 10;
    if (userBalance[user] < maxFee) {
      uint256 depositAmount = maxFee - userBalance[user];
      require(msg.value > depositAmount, "InsufficientAmount");
    }

    // deposit msg.value, even if this is too much, in order to avoid refunding eth
    _deposit(user, msg.value);

    // remove maxFee temporarly so user cant withdraw it while request is pending
    userBalance[msg.sender] -= maxFee;

    RandomNumberRequest memory newRequest = RandomNumberRequest(
      msg.sender,
      user,
      ChainSpecificUtil.getBlockNumber(),
      maxFee,
      gasLimit,
      randomNumberCount,
      requestConfirmations
    );

    // set requestId to next id and increment nextRequestId
    requestId = nextRequestId++;

    // save the newRequest
    pendingRequests[requestId] = newRequest;

    emit RandomNumberRequested(requestId, newRequest);
  }

  function fulfillRandomRequest(uint256 requestId) external {
    uint256 startGas = gasleft();
    RandomNumberRequest memory randomNumberRequest = pendingRequests[requestId];

    uint256 randomness = _getRandomNumber(randomNumberRequest.requestBlockNumber, randomNumberRequest.requestConfirmations);

    uint256[] memory randomNumbers = new uint256[](randomNumberRequest.randomNumberCount);
    for (uint256 i = 0; i < randomNumberRequest.randomNumberCount; i++) {
      randomNumbers[i] = uint256(keccak256(abi.encode(randomness, i)));
    }

    delete pendingRequests[requestId];
    RandomNumberReciverBase target;
    bytes memory data = abi.encodeWithSelector(target.rawRandomNumberCallback.selector, requestId, randomNumbers);
    bool success = _callWithExactGas(randomNumberRequest.gasLimit, randomNumberRequest.requestReciver, data);
 
    _collectFees(requestId, randomNumberRequest.user, startGas, randomNumberRequest.maxFee);

    emit RandomNumberResult(requestId, randomNumbers, success);
  }

  function _getRandomNumber(uint256 blocknumber, uint8 confirmations) internal view returns (uint256 randomness) {
    require(blocknumber > 0, "Request does not exist (anymore)");
    uint256 currentBlocknumber = ChainSpecificUtil.getBlockNumber();
    require(blocknumber + 256 > currentBlocknumber, "Request expired");
    
    if (blocknumber + priorityBlockCount > currentBlocknumber && !isPrioritySender(msg.sender, blocknumber)) {
      revert Not_Priority_Sender();
    }
    
    // start at 1  for blocknumber + 1 as first blocknumber
    for (uint i = 1; i <= confirmations; i++) {
      bytes32 pastBlockhash = ChainSpecificUtil.getBlockhash(uint64(blocknumber + i));
      randomness = uint256(keccak256(abi.encodePacked(randomness, pastBlockhash)));
    }
  }

  function _collectFees(uint256 requestId, address userAddress, uint256 startGas, uint256 maxFee) internal {
    uint256 payment = estimateFee(startGas - gasleft());

    // refund excess fee
    // payment is higher as blocked maxFee AND user can't afford the extra fee. Delta is not charged
    if (payment > maxFee && payment - maxFee > userBalance[userAddress]) {
      payment = userBalance[userAddress];
    }

    nodeBalance[msg.sender] += payment;
    userBalance[userAddress] -= payment;

    emit Fee_Collected(requestId, msg.sender, userAddress, payment);
  }


  // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
  // and some arithmetic operations.
  uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;  
  function _callWithExactGas(uint256 gasAmount, address target, bytes memory data) private returns (bool success) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      let g := gas()
      // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
      // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
        revert(0, 0)
      }
      g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }
}