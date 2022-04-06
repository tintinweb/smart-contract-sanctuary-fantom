// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Rewards.sol";
import "./Math.sol";

contract ServiceV1 {
  event Claimed(address indexed entity, uint reward);
  event Paid(address indexed entity, uint nodeType, uint nodeId, uint upToBlockNumber);
  event Created(address indexed entity, uint nodeId, uint blockNumber, uint nodeType, bool addToNodePool, uint paidOn);
  event RegisteredWithConnect(address indexed entity, bytes nodeId, uint nodeType);
  event DeregisteredWithConnect(address indexed entity, bytes nodeId, uint nodeType);

  mapping(address => mapping(uint => uint)) public entityNodeTypeCount;

  mapping(uint => bool) public nodeTypeActive;
  mapping(bytes => uint) public entityNodeIdType;
  mapping(bytes => uint) public entityNodePaidOnBlock;
  mapping(bytes => uint) public entityNodeClaimedOnBlock;
  mapping(bytes => uint) public entityNodeAddedToPoolOnBlock;
  mapping(bytes => uint) public entityNodeCreatedAt;  
  mapping(bytes => uint) public entityNodeLastClaimedAt;
  mapping(uint => uint) public nodeTypeLimit;
  mapping(uint => uint) public nodeTypeCreationFee;
  mapping(uint => uint) public nodeTypeBaseRewardRate;
  mapping(uint => uint) public nodeTypeDecayFactor;
  mapping(uint => uint) public nodeTypeRecurringPaymentCycle;
  mapping(uint => uint) public nodeTypeRecurringFee;
  mapping(uint => uint) public nodeTypeNodeifyFee;
  mapping(uint => uint) public nodeTypePoolRewardNumerator;
  mapping(uint => uint) public nodeTypePoolRewardDenominator;
  mapping(uint => uint) public nodeTypeClaimingFeeNumerator;
  mapping(uint => uint) public nodeTypeClaimingFeeDenominator;
  mapping(uint => uint) public nodeTypeGracePeriod;

  uint private constant _SECONDS_IN_ONE_MINUTE = 60;

  mapping(address => bool) public isPresaleWallet;

  struct MetalRewardsEarnedOn {
    uint bronze;
    uint silver;
    uint gold;
  }

  mapping(address => MetalRewardsEarnedOn) public metalBlockMap;
  mapping(address => uint128) public entityNodeCount;
  mapping(address => bool) public isDenied;

  AggregatorV3Interface internal priceFeed;

  IERC20 public nodeifyToken;
  bool public isPresaleActive;
  bool public isPublicLaunchActive;
  address public owner;
  address public superOwner;
  address public feeCollectorAddress;
  uint128 public totalNodeTypesAvailable = 4;
  uint128 public maxPaymentPeriods = 2;
  uint128 public maxNodeCount = 100;
  uint128 public bronzeNodeAmount = 1;
  uint128 public silverNodeAmount = 5;
  uint128 public goldNodeAmount = 10;
  uint public totalNodesCreated;
  uint public priceFeedOverride;
  uint public rewardBalance;
  uint public totalPooledNodes;
  uint public poolLockInBlocks = 1000000;
  uint public poolRemovalFee = 1500000000000000000000000000;
  uint public bronzeReward = 200000000000 wei;
  uint public silverReward = 400000000000 wei;
  uint public goldReward = 600000000000 wei;
  uint public rewardPercentageSentToFeeCollector = 3000;
  uint public presaleRequestingFee = 48000000000000000000000000000;

  constructor(
    address _nodeifyTokenAddress,
    address _owner,
    address _feeCollectorAddress,
    address _priceFeedAddress,
    address _superOwner
    ) {
    nodeifyToken = IERC20(_nodeifyTokenAddress);
    owner = _owner;
    superOwner = _superOwner;
    feeCollectorAddress = _feeCollectorAddress;
    priceFeed = AggregatorV3Interface(_priceFeedAddress);
    isPublicLaunchActive = false;
    isPresaleActive = false;
    init();
  }

  modifier onlySuperOwner {
    require(msg.sender == superOwner, "Not Super Owner");
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  function updateOwner(address _newOwner) public onlySuperOwner {
    require(_newOwner != address(0), "zero address");
    owner = _newOwner;
  }

  function updateFeeCollector(address _newFeeCollector) public onlyOwner {
    require(_newFeeCollector != address(0), "zero address");
    feeCollectorAddress = _newFeeCollector;
  }

  // Sets
  function setPresaleWallet(address _presaleWallet, bool _active) public onlyOwner {
    require(_presaleWallet != address(0), "zero address");
    isPresaleWallet[_presaleWallet] = _active;
  }

  function setNodesLimit(uint _nodeType, uint _amount) public onlyOwner {
    nodeTypeLimit[_nodeType] = _amount;
  }

  function setTotalNodeTypesAvailable(uint128 _totalNodeTypesAvailable) public onlyOwner {
    totalNodeTypesAvailable = _totalNodeTypesAvailable;
  }

  function setBronzeRewardValue(uint _reward) public onlyOwner {
    bronzeReward = _reward;
  }

  function setSilverRewardValue(uint _reward) public onlyOwner {
    silverReward = _reward;
  }

  function setGoldRewardValue(uint _reward) public onlyOwner {
    goldReward = _reward;
  }

  function setClaimingFeeNumerator(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeClaimingFeeNumerator[_nodeType] = _value;
  }

  function setClaimingFeeDenominator(uint _nodeType, uint _value) public onlyOwner {
    require(_value > 0, "invalid");
    nodeTypeClaimingFeeDenominator[_nodeType] = _value;
  }

  function setNodeTypeActive(uint _nodeType, bool _active) public onlyOwner {
    nodeTypeActive[_nodeType] = _active;
  }

  function setNodeifyFee(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeNodeifyFee[_nodeType] = _value;
  }

  function setNodeTypeRecurringFee(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeRecurringFee[_nodeType] = _value;
  }

  function setRecurringPaymentCycle(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeRecurringPaymentCycle[_nodeType] = _value;
  }

  function setDecayFactor(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeDecayFactor[_nodeType] = _value;
  }

  function setBaseRewardRate(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeBaseRewardRate[_nodeType] = _value;
  }

  function setCreatingFee(uint _nodeType, uint _value) public onlyOwner {
    nodeTypeCreationFee[_nodeType] = _value;
  }

  function setPriceFeedOverride(uint _value) public onlyOwner {
    priceFeedOverride = _value;
  }

  function setPresaleCreationFee(uint _fee) public onlyOwner {
    presaleRequestingFee = _fee;
  }

  function setPublicLaunchIsActive(bool _value) public onlyOwner {
    isPublicLaunchActive = _value;
  }

  function setPresaleIsActive(bool _value) public onlyOwner {
    isPresaleActive = _value;
  }

  function setMaxPaymentPeriods(uint128 _maxPaymentPeriods) public onlyOwner {  
    maxPaymentPeriods = _maxPaymentPeriods;
  }
  
  function setPoolRemovalFee(uint _fee) public onlyOwner {
    require(_fee > 0, "invalid amount");
    poolRemovalFee = _fee;
  }

  function setPoolLockInBlocks(uint _blocks) public onlyOwner {  
    poolLockInBlocks = _blocks;
  }

  function setGracePeriodInBlocks(uint _nodeType, uint _blocks) public onlyOwner { 
    nodeTypeGracePeriod[_nodeType] = _blocks;
  }

  function setNodeTypePoolRewardNumerator(uint _nodeType, uint128 _numerator) public onlyOwner {
    nodeTypePoolRewardNumerator[_nodeType] = _numerator;
  }

  function setNodeTypePoolRewardDenominator(uint _nodeType, uint128 _denominator) public onlyOwner {
    require(_denominator > 0, "invalid");
    nodeTypePoolRewardDenominator[_nodeType] = _denominator;
  }

  function setMaxNodeAmount(uint128 _maxNodeCount) public onlyOwner {  
    maxNodeCount = _maxNodeCount;
  }

  function setBronzeNodeAmount(uint128 _amount) public onlyOwner {  
    bronzeNodeAmount = _amount;
  }

  function setSilverNodeAmount(uint128 _amount) public onlyOwner {  
    silverNodeAmount = _amount;
  }

  function setGoldNodeAmount(uint128 _amount) public onlyOwner {  
    goldNodeAmount = _amount;
  }

  function setRewardPercentageSentToFeeCollector(uint _rewardPercentageSentToFeeCollector) public onlyOwner {
    rewardPercentageSentToFeeCollector = _rewardPercentageSentToFeeCollector;
  }

  function setDenied(address _account, bool _value) external onlyOwner {
      isDenied[_account] = _value;
  }

  // Internal setters
  function _setBronzeRewardBlock(address _entity, uint _blockNumber) internal {
      MetalRewardsEarnedOn storage m = metalBlockMap[_entity];
      m.bronze = _blockNumber;
  }

  function _setSilverRewardBlock(address _entity, uint _blockNumber) internal {
      MetalRewardsEarnedOn storage m = metalBlockMap[_entity];
      m.silver = _blockNumber;
  }

  function _setGoldRewardBlock(address _entity, uint _blockNumber) internal {
      MetalRewardsEarnedOn storage m = metalBlockMap[_entity];
      m.gold = _blockNumber;
  }

  // Getters
  function getNodeTypePoolRewardNumerator(uint _nodeType) public view returns (uint) {
    return nodeTypePoolRewardNumerator[_nodeType];
  }

  function getNodeClaimingFee(address _entity, uint _nodeId, uint _timestamp) external view returns (uint) {
    uint nodeType = entityNodeIdType[getNodeId(_entity, _nodeId)];
    uint reward = getRewardAt(_entity, _nodeId, _timestamp);
    return reward * getClaimingFeeNumerator(nodeType) / getClaimingFeeDenominator(nodeType);
  }

  function getRewardAll(address _entity, uint _timestamp) public view returns (uint) {
    uint rewardsAll = 0;

    for (uint128 i = 1; i <= entityNodeCount[_entity]; i++) {
      rewardsAll = rewardsAll + getRewardAt(_entity, i, _timestamp > 0 ? _timestamp : block.timestamp);
    }

    return rewardsAll;
  }

  function getFtmPrice() public view returns (int) {
      (
          ,
          int price,
          ,
          ,
          
      ) = priceFeed.latestRoundData();
      return price;
  }

  function getNodesLimit(uint _nodeType) public view returns (uint) {
    return nodeTypeLimit[_nodeType];
  }

  function getEntityNodeTypeCount(uint _nodeType, address _entity) public view returns (uint) {
    return entityNodeTypeCount[_entity][_nodeType];
  }
  
  function getRecurringPaymentCycle(uint _nodeType) public view  returns (uint) {
    return nodeTypeRecurringPaymentCycle[_nodeType];
  }

  function _determineEarnedChip(address _entity) internal {
    uint _bronzeReward;
    uint _silverReward;
    uint _goldReward;
    for (uint index = 1; index <= totalNodeTypesAvailable; index++) {
      uint entityNodeType = getEntityNodeTypeCount(index, _entity);
      if (entityNodeType >= bronzeNodeAmount) {
        _bronzeReward = _bronzeReward + bronzeNodeAmount;
      }
      if (entityNodeType >= silverNodeAmount) {
        _silverReward = _silverReward + silverNodeAmount;
      }
      if (entityNodeType >= goldNodeAmount) {
        _goldReward = _goldReward + goldNodeAmount;
      }
    }
    MetalRewardsEarnedOn storage m = metalBlockMap[_entity];
    if (_bronzeReward >= bronzeNodeAmount * totalNodeTypesAvailable && m.bronze == 0) {
      _setBronzeRewardBlock(_entity, block.number);
    }
    if (_silverReward >= silverNodeAmount * totalNodeTypesAvailable && m.silver == 0) {
      _setSilverRewardBlock(_entity, block.number);
    }
    if (_goldReward >= goldNodeAmount * totalNodeTypesAvailable && m.gold == 0) {
      _setGoldRewardBlock(_entity, block.number);
    }
  }

  function getClaimingFeeNumerator(uint _nodeType) public view returns (uint) {
    return nodeTypeClaimingFeeNumerator[_nodeType];
  }

  function getClaimingFeeDenominator(uint _nodeType) public view returns (uint) {
    return nodeTypeClaimingFeeDenominator[_nodeType];
  }

  function getNodeifyFee(uint _nodeType) public view returns (uint) {
    return nodeTypeNodeifyFee[_nodeType];
  }

  function getNodeTypeRecurringFee(uint _nodeType) public view returns (uint) {
    return nodeTypeRecurringFee[_nodeType];
  }

  function getDecayFactor(uint _nodeType) public view returns (uint) {
    return nodeTypeDecayFactor[_nodeType];
  }

  function getGracePeriod(uint _nodeType) public view returns (uint) {
    return nodeTypeGracePeriod[_nodeType];
  }

  function getBaseRewardRate(uint _nodeType) public view returns (uint) {
    return nodeTypeBaseRewardRate[_nodeType];
  }

  function getCreatingFee(uint _nodeType) public view returns (uint) {
    return nodeTypeCreationFee[_nodeType];
  }

  function getNodeReward(address _entity, uint _nodeId) external view returns (uint) {
    return getRewardAt(_entity, _nodeId, block.timestamp);
  }

  function getNodePaidOn(address _entity, uint _nodeId) public view returns (uint) {
    bytes memory id = getNodeId(_entity, _nodeId);
    return entityNodePaidOnBlock[id];
  }

  function getNodeType(address _entity, uint _nodeId) public view returns (uint) {
    return entityNodeIdType[getNodeId(_entity, _nodeId)];
  }

  function getNodesRecurringFee(address _entity, uint _fromNode, uint _toNode) external view returns (uint) {
    uint fee = 0;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[_entity];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      if (canBePaid(_entity, nodeId)) fee = fee + getNodeTypeRecurringFee(getNodeType(_entity, nodeId));
    }

    return fee;
  }

  function getNodesClaimingFee(address _entity, uint _timestamp, uint _fromNode, uint _toNode) external view returns (uint) {
    uint fee = 0;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[_entity];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      uint reward = getRewardAt(_entity, nodeId, _timestamp > 0 ? _timestamp : block.timestamp);
      if (reward > 0) {
        uint nodeType = getNodeType(_entity, nodeId);
        fee = fee + reward * getClaimingFeeNumerator(nodeType) / getClaimingFeeDenominator(nodeType);
      }
    }

    return fee;
  }

  function getNodeId(address _entity, uint _nodeId) public view returns (bytes memory) {
    uint id = _nodeId != 0 ? _nodeId : entityNodeCount[_entity] + 1;
    return abi.encodePacked(_entity, id);
  }

  function getRewardAt(address _entity, uint _nodeId, uint _timestamp) public view returns (uint) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint lastClaimedAt = entityNodeLastClaimedAt[id] != 0 ? entityNodeLastClaimedAt[id] : entityNodeCreatedAt[id];
    uint registeredAt = entityNodeCreatedAt[id];
    if (_timestamp <= registeredAt) return 0;
    if (!doesNodeExist(_entity, _nodeId)) return 0;
    if (hasNodeExpired(_entity, _nodeId)) return 0;
    if (_timestamp > block.timestamp) return 0;
    if (_timestamp <= lastClaimedAt) return 0;
  
    uint nodeType = entityNodeIdType[id];
    uint blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
    uint minutesTotal = (_timestamp - registeredAt) / _SECONDS_IN_ONE_MINUTE;

    uint baseRewardRate = getBaseRewardRate(nodeType);
    uint decayFactor = getDecayFactor(nodeType);

    uint reward = calcDecayedReward(
      baseRewardRate,
      decayFactor,
      minutesTotal
    );

    if (lastClaimedAt > 0) {
      uint minutesToLastClaim = (lastClaimedAt - registeredAt) / _SECONDS_IN_ONE_MINUTE;
      uint rewardAtLastClaim = calcDecayedReward(baseRewardRate, decayFactor, minutesToLastClaim);
      reward = reward - rewardAtLastClaim;
    }

    if (entityNodeAddedToPoolOnBlock[id] > 0) {
      uint cReward = rewards.calculateConnectReward(reward, nodeTypePoolRewardNumerator[nodeType], nodeTypePoolRewardDenominator[nodeType]);
      reward = reward + cReward;
    }
    uint bonus = _determineMetalReward(block.number, _entity, blockLastClaimedOn);
    return reward + bonus;
  }

  // Checks
  function canBeRemoveNodeFromPool(uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(msg.sender, _nodeId);
    if (block.number > entityNodeAddedToPoolOnBlock[id] + poolLockInBlocks) return true;
    return false;
  }

  function canBePaid(address _entity, uint _nodeId) public view returns (bool) {
    return doesNodeExist(_entity, _nodeId) && !hasNodeExpired(_entity, _nodeId) && !hasMaxPayments(_entity, _nodeId);
  }

  function doesNodeExist(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    return entityNodePaidOnBlock[id] > 0;
  }

  function hasNodeExpired(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeIdType[id];
    uint blockLastPaidOn = entityNodePaidOnBlock[id];

    if (doesNodeExist(_entity, _nodeId) == false) return true;
    uint recurringPaymentCycle = getRecurringPaymentCycle(nodeType);
    return block.number > blockLastPaidOn + recurringPaymentCycle + getGracePeriod(nodeType);
  }

  function isNodePastDue(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeIdType[id];
    uint blockLastPaidOn = entityNodePaidOnBlock[id];

    uint recurringPaymentCycle = getRecurringPaymentCycle(nodeType);
    return block.number > blockLastPaidOn + recurringPaymentCycle;
  }

  function hasMaxPayments(address _entity, uint _nodeId) public view returns (bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    uint nodeType = entityNodeIdType[id];
    uint blockLastPaidOn = entityNodePaidOnBlock[id];
    uint recurringPaymentCycleInBlocks = getRecurringPaymentCycle(nodeType);
    uint limit = block.number + (recurringPaymentCycleInBlocks * maxPaymentPeriods);

    return blockLastPaidOn + recurringPaymentCycleInBlocks >= limit;
  }

  function isNodeInPool(address _entity, uint _nodeId) public view returns(bool) {
    bytes memory id = getNodeId(_entity, _nodeId);
    return entityNodeAddedToPoolOnBlock[id] > 0;
  }

  // Actions
  function createPresaleNode(bool _addToNodePool, uint _nodeType) public payable {
    require(!isPublicLaunchActive, "public launch is active");
    require(isPresaleActive, "presale not active");
    require(isPresaleWallet[msg.sender], "not part of presale");
    require(entityNodeCount[msg.sender] < 2, "maxed nodes for presale");
    require(msg.sender != address(0), "zero address");
    require(!isDenied[msg.sender], "not allowed");
    require(nodeTypeActive[_nodeType], "invalid type");

    uint nodeId = entityNodeCount[msg.sender] + 1;
    bytes memory id = getNodeId(msg.sender, nodeId);

    entityNodePaidOnBlock[id] = block.number;
    entityNodeClaimedOnBlock[id] = block.number;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;
    entityNodeCreatedAt[id] = block.timestamp;
    entityNodeTypeCount[msg.sender][_nodeType] = entityNodeTypeCount[msg.sender][_nodeType] + 1;
    entityNodeIdType[id] = _nodeType;
    _determineEarnedChip(msg.sender);

    uint recurringPaymentCycleInBlocks = getRecurringPaymentCycle(_nodeType);
    if (_addToNodePool) {
      entityNodeAddedToPoolOnBlock[id] = block.number;
      totalPooledNodes = totalPooledNodes + 1;
    } else {
      entityNodeAddedToPoolOnBlock[id] = 0;
    }

    uint rFee = _determineFee(presaleRequestingFee);
    require(msg.value >= rFee, "invalid fee");

    totalNodesCreated = totalNodesCreated + 1;
    emit Created(msg.sender, nodeId, block.number, _nodeType, _addToNodePool, entityNodePaidOnBlock[id] + recurringPaymentCycleInBlocks);

    _sendValue(payable(feeCollectorAddress), msg.value);
  }

  function createNode(bool _addToNodePool, uint _nodeType) public payable {
      require(isPublicLaunchActive, "public launch not active");
      require(entityNodeCount[msg.sender] < maxNodeCount, "limit reached");
      require(msg.sender != address(0), "zero address");
      require(!isDenied[msg.sender], "not allowed");
      require(nodeTypeActive[_nodeType], "invalid type");

      uint nFee = getNodeifyFee(_nodeType);
      require(nodeifyToken.balanceOf(msg.sender) >= nFee, "too low tokens");
    
      uint _nodeTypeLimit = getNodesLimit(_nodeType);
      require(_nodeTypeLimit == 0 || getEntityNodeTypeCount(_nodeType, msg.sender) < _nodeTypeLimit, "over limit");

      uint nodeId = entityNodeCount[msg.sender] + 1;
      bytes memory id = getNodeId(msg.sender, nodeId);

      entityNodePaidOnBlock[id] = block.number;
      entityNodeClaimedOnBlock[id] = block.number;
      entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;
      entityNodeCreatedAt[id] = block.timestamp;
      entityNodeTypeCount[msg.sender][_nodeType] = entityNodeTypeCount[msg.sender][_nodeType] + 1;
      entityNodeIdType[id] = _nodeType;
      _determineEarnedChip(msg.sender);

      if (_addToNodePool) {
        entityNodeAddedToPoolOnBlock[id] = block.number;
        totalPooledNodes = totalPooledNodes + 1;
      } else {
        entityNodeAddedToPoolOnBlock[id] = 0;
      }

      uint fee = getCreatingFee(_nodeType);
      uint rFee = _determineFee(fee);

      require(msg.value >= rFee, "invalid fee");
      totalNodesCreated = totalNodesCreated + 1;

      uint paymentCycle = getRecurringPaymentCycle(_nodeType);

      uint takeNDFI = nFee * rewardPercentageSentToFeeCollector / 10000;

      require(nodeifyToken.transferFrom(msg.sender, feeCollectorAddress, takeNDFI), "transfer failed");
      if (nFee > takeNDFI) {
        require(nodeifyToken.transferFrom(msg.sender, address(this), nFee - takeNDFI), "transfer failed");
      }
      emit Created(msg.sender, nodeId, block.number, _nodeType, _addToNodePool, entityNodePaidOnBlock[id] + paymentCycle);

      _sendValue(payable(feeCollectorAddress), msg.value);
  }

  function createNodeForEntity(bool _addToNodePool, uint _nodeType, address _entity) external onlyOwner {
      require(entityNodeCount[_entity] < maxNodeCount, "limit reached");
      require(_entity != address(0), "zero address");
      require(!isDenied[_entity], "not allowed");
      require(nodeTypeActive[_nodeType], "invalid type");

      uint _nodeTypeLimit = getNodesLimit(_nodeType);
      require(_nodeTypeLimit == 0 || getEntityNodeTypeCount(_nodeType, _entity) < _nodeTypeLimit, "over limit");

      uint nodeId = entityNodeCount[_entity] + 1;
      bytes memory id = getNodeId(_entity, nodeId);

      entityNodePaidOnBlock[id] = block.number;
      entityNodeClaimedOnBlock[id] = block.number;
      entityNodeCount[_entity] = entityNodeCount[_entity] + 1;
      entityNodeCreatedAt[id] = block.timestamp;
      entityNodeTypeCount[_entity][_nodeType] = entityNodeTypeCount[_entity][_nodeType] + 1;
      entityNodeIdType[id] = _nodeType;
      _determineEarnedChip(_entity);

      if (_addToNodePool) {
        entityNodeAddedToPoolOnBlock[id] = block.number;
        totalPooledNodes = totalPooledNodes + 1;
      } else {
        entityNodeAddedToPoolOnBlock[id] = 0;
      }

      totalNodesCreated = totalNodesCreated + 1;
      uint paymentCycle = getRecurringPaymentCycle(_nodeType);

      emit Created(_entity, nodeId, block.number, _nodeType, _addToNodePool, entityNodePaidOnBlock[id] + paymentCycle);
  }

  function addNodeToPool(uint _nodeId, uint _timestamp) external payable makesInternalCalls {
    bytes memory id = getNodeId(msg.sender, _nodeId);
    require(entityNodeAddedToPoolOnBlock[id] == 0, "already in pool" ); 

    uint reward = getRewardAt(msg.sender, _nodeId, _timestamp);
    if (reward > 0) {
      claim(_nodeId, _timestamp);
    }

    entityNodeAddedToPoolOnBlock[id] = block.number;
    totalPooledNodes = totalPooledNodes + 1;
    emit RegisteredWithConnect(msg.sender, id, entityNodeIdType[id]);
  }

  function removeNodeFromPool(uint _nodeId, uint _timestamp) external payable makesInternalCalls {
    bytes memory id = getNodeId(msg.sender, _nodeId);
    require(_timestamp <= block.timestamp, "bad timestamp");
    require(canBeRemoveNodeFromPool(_nodeId), "cannot be removed yet");
    require(entityNodeAddedToPoolOnBlock[id] > 0, "not in pool");

    uint reward = getRewardAt(msg.sender, _nodeId, _timestamp);
    uint fee;
    if (reward > 0) {
      fee = claim(_nodeId, _timestamp);
    }

    uint rFee = _determineFee(poolRemovalFee);
    require(msg.value >= rFee, "invalid fee");
    entityNodeAddedToPoolOnBlock[id] = 0;
    if (totalPooledNodes > 0) {
      totalPooledNodes = totalPooledNodes - 1;
    }

    emit DeregisteredWithConnect(msg.sender, id, entityNodeIdType[id]);

    _sendValue(payable(feeCollectorAddress), rFee);
    if (isUserCall() && msg.value > rFee) _sendValue(payable(msg.sender), msg.value - rFee);
  }

  function _sendValue(address payable _recipient, uint _amount) internal {
    require(address(this).balance >= _amount, "insufficient balance");
    
    // solhint-disable-next-line avoid-low-level-calls, a void-call-value
    (bool success,) = _recipient.call{value : _amount}("");
    require(success, "send failed");
  }

  function claimAll(uint _timestamp, uint _fromNode, uint _toNode) external payable makesInternalCalls {
    require(entityNodeCount[msg.sender] > 0, "no nodes");

    uint valueLeft = msg.value;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[msg.sender];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      uint reward = getRewardAt(msg.sender, nodeId, _timestamp);

      if (reward > 0) {
        require(valueLeft > 0, "not enough");
        uint paid = claim(nodeId, _timestamp);
        valueLeft = valueLeft - paid;
      }
    }
    if (valueLeft > 0) _sendValue(payable(msg.sender), valueLeft);

  }

  function deposit(uint _amount) public onlyOwner {
    nodeifyToken.transferFrom(msg.sender, address(this), _amount);
    rewardBalance = rewardBalance + _amount;
  }

  function withdraw(address _destination, uint _amount) public onlyOwner {
    require(rewardBalance >= _amount, "not enough");
    rewardBalance = rewardBalance - _amount;
    nodeifyToken.transfer(_destination, _amount);
  }

  function claim(uint _nodeId, uint _timestamp) public payable returns (uint) {
    bytes memory id = getNodeId(msg.sender, _nodeId);
    uint nodeType = entityNodeIdType[id];
    uint blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodeClaimedOnBlock[id];
    uint lastClaimedAt = entityNodeLastClaimedAt[id] != 0 ? entityNodeLastClaimedAt[id] : entityNodeCreatedAt[id];

    require(doesNodeExist(msg.sender, _nodeId), "doesnt exist");
    require(!hasNodeExpired(msg.sender, _nodeId), "node expired");
    require(!isNodePastDue(msg.sender, _nodeId), "past due");
    require(blockLastClaimedOn != 0, "never claimed");
    require(!isDenied[msg.sender], "not allowed");
    require(_timestamp <= block.timestamp, "bad timestamp");
    require(lastClaimedAt + 1200 < _timestamp, "too soon");

    uint reward = getRewardAt(msg.sender, _nodeId, _timestamp);
    require(reward > 0, "no reward");

    uint fee = reward * getClaimingFeeNumerator(nodeType) / getClaimingFeeDenominator(nodeType);
    require(msg.value >= fee, "invalid fee");
    require(rewardBalance > reward, "no rewards");

    rewardBalance = rewardBalance - reward;
    entityNodeLastClaimedAt[id] = _timestamp;
    entityNodeClaimedOnBlock[id] = block.number;
    emit Claimed(msg.sender, reward);

    require(nodeifyToken.transfer(msg.sender, reward), "transfer failed");

    _sendValue(payable(feeCollectorAddress), fee);
    if (isUserCall() && msg.value > fee) _sendValue(payable(msg.sender), msg.value - fee);

    return fee;
  }

  function _determineFee(uint _fee) internal view returns (uint) {
    if (priceFeedOverride > 0) {
      return _fee / priceFeedOverride;
    }
    int256 ftmPrice = getFtmPrice();
    return _fee / uint(ftmPrice);
  }

  function payAll(uint _fromNode, uint _toNode) external payable makesInternalCalls {
    require(entityNodeCount[msg.sender] > 0, "no nodes");

    uint valueLeft = msg.value;
    uint fromNode = _fromNode > 0 ? _fromNode : 1;
    uint toNode = _toNode > 0 ? _toNode : entityNodeCount[msg.sender];

    for (uint nodeId = fromNode; nodeId <= toNode; nodeId++) {
      if (!canBePaid(msg.sender, nodeId)) continue;
      require(valueLeft > 0, "not enough");
      uint paid = payFee(nodeId);
      valueLeft = valueLeft - paid;
    }

    if (valueLeft > 0) _sendValue(payable(msg.sender), valueLeft);
  }

  function payFee(uint _nodeId) public payable returns (uint) {
    bytes memory id = getNodeId(msg.sender, _nodeId);
    require(canBePaid(msg.sender, _nodeId), "cant pay");

    uint nodeType = entityNodeIdType[id];
    uint fee = getNodeTypeRecurringFee(nodeType);
    uint mFee = _determineFee(fee);

    require(msg.value >= mFee, "invalid fee");

    entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id] + getRecurringPaymentCycle(nodeType);

    emit Paid(msg.sender, nodeType, _nodeId, entityNodePaidOnBlock[id]);

    _sendValue(payable(feeCollectorAddress), mFee);
    if (isUserCall() && msg.value > mFee) _sendValue(payable(msg.sender), msg.value - mFee);

    return mFee;
  }

  function calcDecayedReward(uint _baseRate, uint _decayFactor, uint _minutesPassed) public pure returns (uint) {
    uint power = math._decPow(_decayFactor, _minutesPassed);
    uint cumulativeFraction = math.DECIMAL_PRECISION - power;

    return _baseRate * cumulativeFraction / math.DECIMAL_PRECISION;
  }

  function _determineMetalReward(uint _blockNumber, address _entity, uint _blockLastClaimedOn) internal view returns (uint) {
    uint bronze = rewards.metalRewardAddition(_blockNumber, metalBlockMap[_entity].bronze, bronzeReward, _blockLastClaimedOn);
    uint silver = rewards.metalRewardAddition(_blockNumber, metalBlockMap[_entity].silver, silverReward, _blockLastClaimedOn);
    uint gold = rewards.metalRewardAddition(_blockNumber, metalBlockMap[_entity].gold, goldReward, _blockLastClaimedOn);

    uint bonus = (bronze + silver + gold) / entityNodeCount[_entity];
    return bonus;
  }

  // Status
  uint private constant _NOT_MAKING_INTERNAL_CALLS = 1;
  uint private constant _MAKING_INTERNAL_CALLS = 2;
  uint private _internal_calls_status;

  modifier makesInternalCalls() {
    _internal_calls_status = _MAKING_INTERNAL_CALLS;
    _;
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function init() internal {
    _internal_calls_status = _NOT_MAKING_INTERNAL_CALLS;
  }

  function isInternalCall() internal view returns (bool) {
    return _internal_calls_status == _MAKING_INTERNAL_CALLS;
  }

  function _msgSender() internal view virtual returns (address) {
      return msg.sender;
  }

  function isContractCall() internal view returns (bool) {
    return _msgSender() != tx.origin;
  }

  function isUserCall() internal view returns (bool) {
    return !isInternalCall() && !isContractCall();
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library rewards {
  function metalRewardAddition(
      uint256 currentBlock,
      uint256 rewardBlockChecker,
      uint256 rewardValue,
      uint256 lastClaimedBlock
      ) internal pure returns (uint256) {
      if (rewardBlockChecker == 0) return 0;
      if (rewardBlockChecker >= currentBlock) return 0;
      if (currentBlock == lastClaimedBlock) return 0;
      if (currentBlock <= rewardBlockChecker) return 0;
      if (lastClaimedBlock <= 0) return 0;
      if (lastClaimedBlock > currentBlock) return 0;
      if (lastClaimedBlock > rewardBlockChecker) {
        return (currentBlock - lastClaimedBlock) * rewardValue;
      }
      if (rewardBlockChecker < currentBlock) {
        return (currentBlock - rewardBlockChecker)  * rewardValue;
      }
      return 0;
  }

  function calculateConnectReward(uint amount, uint256 numerator, uint256 denominator) internal pure returns(uint) {
    if (numerator == 0) return amount;
    return (amount * numerator) / denominator;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

library math {
  uint internal constant DECIMAL_PRECISION = 1e18;

  function decMul(uint x, uint y) internal pure returns (uint decProd) {
    uint prod_xy = x * y;

    decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
  }

  function _decPow(uint _base, uint _minutes) internal pure returns (uint) {

    if (_minutes > 525_600_000) _minutes = 525_600_000;  // cap to avoid overflow

    if (_minutes == 0) return DECIMAL_PRECISION;

    uint y = DECIMAL_PRECISION;
    uint x = _base;
    uint n = _minutes;

    // Exponentiation-by-squaring
    while (n > 1) {
      if (n % 2 == 0) {
        x = decMul(x, x);
        n = n / 2;
      } else { // if (n % 2 != 0)
        y = decMul(x, y);
        x = decMul(x, x);
        n = (n - 1) / 2;
      }
    }

    return decMul(x, y);
  }

}