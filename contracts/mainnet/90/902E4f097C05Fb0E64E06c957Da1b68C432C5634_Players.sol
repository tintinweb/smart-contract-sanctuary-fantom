// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./World.sol";
import "./types.sol";
import "./items.sol";
import "./ItemNFT.sol";
import "./PlayerNFT.sol";

import {PlayerLibrary} from "./PlayerLibrary.sol";

contract Players is
  OwnableUpgradeable,
  UUPSUpgradeable //, Multicall {
{
  event ActionUnequip(uint playerId, uint queueId, uint16 itemTokenId, uint amount);

  event ClearAll(uint playerId);

  event AddSkillPoints(uint playerId, Skill skill, uint32 points);

  event LevelUp(uint playerId, uint[] itemTokenIdsRewarded, uint[] amountTokenIdsRewarded);

  event AddToActionQueue(uint playerId, QueuedAction queuedAction); // This includes everything
  event SetActionQueue(uint playerId, QueuedAction[] queuedActions);

  event ConsumeBoostVial(uint playerId, PlayerBoostInfo playerBoostInfo);
  event UnconsumeBoostVial(uint playerId);

  event SetActivePlayer(address account, uint oldPlayerId, uint newPlayerId);

  event RemoveQueuedAction(uint playerId, uint queueId);

  // For logging
  event Died(address from, uint playerId, uint queueId);
  event Rewards(address from, uint playerId, uint queueId, uint[] itemTokenIds, uint[] amounts);
  event Reward(address from, uint playerId, uint queueId, uint itemTokenId, uint amount); // Used in PlayerLibrary too
  event Consume(address from, uint playerId, uint queueId, uint itemTokenId, uint amount); // Used in PlayerLibrary too
  event ActionFinished(address from, uint playerId, uint queueId);
  event ActionPartiallyFinished(address from, uint playerId, uint queueId, uint elapsedTime);

  error SkillsArrayZero();
  error NotOwner();
  error NotActive();
  error EquipSameItem();
  error NotEquipped();
  error ArgumentLengthMismatch();
  error NotPlayerNFT();
  error NotItemNFT();
  error ActionNotAvailable();
  error UnsupportedAttire();
  error InvalidArmEquipment(uint16 itemTokenId);
  error DoNotHaveEnoughQuantityToEquipToAction();
  error NoActiveBoost();
  error BoostTimeAlreadyStarted();
  error NoItemBalance(uint16 itemTokenId);
  error TooManyActionsQueued();
  error TooManyActionsQueuedSomeAlreadyExist();
  error ActionTimespanExceedsMaxTime();

  uint32 public constant MAX_TIME = 1 days;
  uint constant LEVEL_5_BOUNDARY = 374;
  uint constant LEVEL_10_BOUNDARY = 1021;
  uint constant LEVEL_15_BOUNDARY = 1938;
  uint constant LEVEL_20_BOUNDARY = 3236;
  uint constant LEVEL_30_BOUNDARY = 7650;
  uint constant LEVEL_40_BOUNDARY = 16432;
  uint constant LEVEL_50_BOUNDARY = 33913;
  uint constant LEVEL_60_BOUNDARY = 68761;
  uint constant LEVEL_70_BOUNDARY = 138307;
  uint constant LEVEL_80_BOUNDARY = 277219;
  uint constant LEVEL_90_BOUNDARY = 554828;
  uint constant LEVEL_99_BOUNDARY = 1035476;

  uint constant MAX_MAIN_EQUIPMENT_ID = 65536 * 8;

  mapping(uint => uint) speedMultiplier; // 0 or 1 is diabled, for testing only

  mapping(address => uint) activePlayer;

  mapping(uint => PlayerBoostInfo) public activeBoosts; // player id => boost info

  uint private queueId; // Global queued action id
  World private world;

  mapping(uint => mapping(Skill => uint32)) public skillPoints;

  mapping(uint => Player) public players;
  ItemNFT private itemNFT;
  PlayerNFT private playerNFT;
  PendingLoot[] private pendingLoot; // queue, will be sorted by timestamp

  struct EquipmentDiff {
    uint16 itemTokenId;
    int128 change;
  }

  mapping(uint => EquipmentDiff[]) public actionEquipmentItemTokenIds; // QueuedActionId. Should only hold it for actions/actionChoices that are applicable

  enum ActionQueueStatus {
    NONE,
    APPEND,
    KEEP_LAST_IN_PROGRESS
  }

  modifier isOwnerOfPlayer(uint playerId) {
    if (playerNFT.balanceOf(msg.sender, playerId) != 1) {
      revert NotOwner();
    }
    _;
  }

  modifier isOwnerOfPlayerAndActive(uint _playerId) {
    if (playerNFT.balanceOf(msg.sender, _playerId) != 1) {
      revert NotOwner();
    }
    if (activePlayer[msg.sender] != _playerId) {
      revert NotActive();
    }
    _;
  }

  modifier onlyPlayerNFT() {
    if (msg.sender != address(playerNFT)) {
      revert NotPlayerNFT();
    }
    _;
  }

  modifier onlyItemNFT() {
    if (msg.sender != address(itemNFT)) {
      revert NotItemNFT();
    }
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(ItemNFT _itemNFT, PlayerNFT _playerNFT, World _world) public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();

    itemNFT = _itemNFT;
    playerNFT = _playerNFT;
    world = _world;

    queueId = 1; // Global queued action id
  }

  // Consumes all the actions in the queue up to this time.
  // Unequips everything which is just emitting an event
  // Mints the boost vial if it hasn't been consumed at all yet
  // Removes all the actions from the queue
  function _clearEverything(address _from, uint _playerId) private {
    _consumeActions(_from, _playerId);
    emit ClearAll(_playerId);
    // Can re-mint boost if it hasn't been consumed at all yet
    if (activeBoosts[_playerId].boostType != BoostType.NONE && activeBoosts[_playerId].startTime < block.timestamp) {
      itemNFT.mint(_from, activeBoosts[_playerId].itemTokenId, 1);
      delete activeBoosts[_playerId];
    }
    _clearActionQueue(_playerId);
  }

  function clearEverything(uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    _clearEverything(msg.sender, _playerId);
  }

  function clearEverythingBeforeTokenTransfer(address _from, uint _playerId) external onlyPlayerNFT {
    _clearEverything(_from, _playerId);
  }

  function _isMainEquipped(uint _playerId, uint _itemTokenId) private view returns (bool) {
    EquipPosition position = _getMainEquipPosition(_itemTokenId);
    Player storage player = players[_playerId];
    uint equippedTokenId = _getEquippedTokenId(position, player);
    return equippedTokenId == _itemTokenId;
  }

  function _getMainEquipPosition(uint _itemTokenId) private pure returns (EquipPosition) {
    if (_itemTokenId >= MAX_MAIN_EQUIPMENT_ID) {
      return EquipPosition.NONE;
    }

    return EquipPosition(_itemTokenId / 65536);
  }

  // If an item is transferred from a player, we need to unequip it from main attire for an action,
  // because it could affect stats.
  function itemBeforeTokenTransfer(
    address _from,
    uint[] calldata _itemTokenIds,
    uint[] calldata _amounts
  ) external onlyItemNFT {
    uint playerId = activePlayer[_from];
    if (playerId == 0) {
      return;
    }
    /*
    // Check if any of these are equipped, if no unequip if they don't have sufficient balance
    QueuedAction[] memory remainingSkillQueue = _consumeActions(_from, playerId);

    for (uint i = 0; i < _itemTokenIds.length; ++i) {
      uint itemTokenId = _itemTokenIds[i];
      uint amount = _amounts[i];
      if (itemTokenId < MAX_MAIN_EQUIPMENT_ID) {
        // Only have 1 and it's equipped so unequip it.
//        if (itemNFT.balanceOf(_from, itemTokenId) == 1 && _isMainEquipped(playerId, itemTokenId)) {
//          _unequip(playerId, _getMainEquipPosition(itemTokenId));
//        }
      } else {
        // Not main attire. This is potentially equipped in an action, need to check all the queued actions and action choices
        Player storage player = players[_playerId];
        player.actionQueue = _queuedActions;

        for (uint i = 0; i < player.actionQueue.length; ++i) {
          QueuedAction storage queuedAction = player.actionQueue[i];

          // Left/right arm

          // Food

          // Consumables

          if (_queuedAction.choiceId != NONE) {
            // Get all items for this
            ActionChoice memory actionChoice = world.getActionChoice(
              _isCombat(_queuedAction.skill) ? NONE : _queuedAction.actionId,
              _queuedAction.choiceId
            );

            _equipActionConsumable(_playerId, actionChoice.inputTokenId1, actionChoice.num1 * _queuedAction.num);
            _equipActionConsumable(_playerId, actionChoice.inputTokenId2, actionChoice.num2 * _queuedAction.num);
            _equipActionConsumable(_playerId, actionChoice.inputTokenId3, actionChoice.num3 * _queuedAction.num);
          }

          queuedAction.choiceId;

          //        player.actionQueue = remainingSkillQueue;
          //        actionEquipmentItemTokenIds
        }
      }
    }

    // Any of these remaining actions requiring this and don't have appropriate outputs?
    _setActionQueue(playerId, remainingSkillQueue); */
  }

  function mintBatch(address _to, uint[] calldata _ids, uint256[] calldata _amounts) external onlyPlayerNFT {
    itemNFT.mintBatch(_to, _ids, _amounts);
  }

  function _updateCombatStats(
    address _from,
    CombatStats memory _stats,
    Attire storage _attire,
    bool _add,
    uint _startTime
  ) private view returns (CombatStats memory) {
    return PlayerLibrary.updateCombatStats(_from, _stats, _attire, itemNFT, _add);
  }

  function _getEquippedTokenId(
    EquipPosition _position,
    Player storage _player
  ) private view returns (uint16 equippedTokenId) {
    assembly ("memory-safe") {
      let val := sload(_player.slot)
      equippedTokenId := shr(mul(_position, 16), val)
    }
  }

  function _checkEquipActionEquipment(
    address _from,
    uint16 _itemTokenId,
    uint16 _itemTokenIdRangeMin,
    uint16 _itemTokenIdRangeMax
  ) private view {
    if (_itemTokenId != NONE) {
      if (_itemTokenId < _itemTokenIdRangeMin || _itemTokenId > _itemTokenIdRangeMax) {
        revert InvalidArmEquipment(_itemTokenId);
      }

      uint256 balance = itemNFT.balanceOf(_from, _itemTokenId);
      if (balance == 0) {
        revert DoNotHaveEnoughQuantityToEquipToAction();
      }
    }
  }

  // This doesn't work as memory structs take up 1 element per slot, so we can't just do a mload
  /*  function _getEquipmentRawVal(Attire memory _attire) private view returns (uint256 raw) {
    assembly ("memory-safe") {
      raw := mload(_attire)
    }
  } */

  function _isCombat(Skill _skill) private pure returns (bool) {
    return _skill == Skill.ATTACK || _skill == Skill.DEFENCE || _skill == Skill.MAGIC || _skill == Skill.RANGED;
  }

  function _consumeBoost(uint _playerId, uint16 _itemTokenId, uint40 _startTime) private {
    PlayerBoostInfo storage playerBoost = activeBoosts[_playerId];
    PlayerLibrary.consumeBoost(_itemTokenId, itemNFT, _startTime, playerBoost);
    emit ConsumeBoostVial(_playerId, playerBoost);
  }

  function consumeBoost(
    uint _playerId,
    uint16 _itemTokenId,
    uint40 _startTime
  ) external isOwnerOfPlayerAndActive(_playerId) {
    _consumeBoost(_playerId, _itemTokenId, _startTime);
  }

  function unequipBoostVial(uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    if (activeBoosts[_playerId].boostType == BoostType.NONE) {
      revert NoActiveBoost();
    }
    if (activeBoosts[_playerId].startTime > block.timestamp) {
      revert BoostTimeAlreadyStarted();
    }
    address from = msg.sender;
    itemNFT.mint(from, activeBoosts[_playerId].itemTokenId, 1);
    emit UnconsumeBoostVial(_playerId);
  }

  // Checks they have sufficient balance to equip the items
  function _checkAttire(address _from, Attire memory _attire) private view {
    // Check the user has these items
    //    uint raw = _getEquipmentRawVal(_attire);
    //    if (raw > 0) {
    if (_attire.helmet != NONE && itemNFT.balanceOf(_from, _attire.helmet) == 0) {
      revert NoItemBalance(_attire.helmet);
    }
    if (_attire.amulet != NONE && itemNFT.balanceOf(_from, _attire.amulet) == 0) {
      revert NoItemBalance(_attire.amulet);
    }
    if (_attire.armor != NONE && itemNFT.balanceOf(_from, _attire.armor) == 0) {
      revert NoItemBalance(_attire.armor);
    }
    if (_attire.gauntlets != NONE && itemNFT.balanceOf(_from, _attire.gauntlets) == 0) {
      revert NoItemBalance(_attire.gauntlets);
    }
    if (_attire.tassets != NONE && itemNFT.balanceOf(_from, _attire.tassets) == 0) {
      revert NoItemBalance(_attire.tassets);
    }
    if (_attire.boots != NONE && itemNFT.balanceOf(_from, _attire.boots) == 0) {
      revert NoItemBalance(_attire.boots);
    }
    //    }
  }

  function _checkActionConsumables(address _from, QueuedAction memory _queuedAction) private view {
    // Check they have this to equip. Indexer can check actionChoices
    if (_queuedAction.regenerateId != NONE && itemNFT.balanceOf(_from, _queuedAction.regenerateId) == 0) {
      revert NoItemBalance(_queuedAction.regenerateId);
    }

    if (_queuedAction.choiceId != NONE) {
      // Get all items for this
      ActionChoice memory actionChoice = world.getActionChoice(
        _isCombat(_queuedAction.skill) ? NONE : _queuedAction.actionId,
        _queuedAction.choiceId
      );

      // TODO: Can be balance of batch
      if (actionChoice.inputTokenId1 != NONE && itemNFT.balanceOf(_from, actionChoice.inputTokenId1) == 0) {
        revert NoItemBalance(actionChoice.inputTokenId1);
      }
      if (actionChoice.inputTokenId2 != NONE && itemNFT.balanceOf(_from, actionChoice.inputTokenId2) == 0) {
        revert NoItemBalance(actionChoice.inputTokenId2);
      }
      if (actionChoice.inputTokenId3 != NONE && itemNFT.balanceOf(_from, actionChoice.inputTokenId3) == 0) {
        revert NoItemBalance(actionChoice.inputTokenId3);
      }
    }
    //     if (_queuedAction.choiceId1 != NONE) {
    //     if (_queuedAction.choiceId2 != NONE) {
  }

  function _addToQueue(
    address _from,
    uint _playerId,
    QueuedAction memory _queuedAction,
    uint64 _queueId,
    uint _startTime
  ) private {
    Player storage _player = players[_playerId];
    //    Skill skill = world.getSkill(_queuedAction.actionId); // Can be combat

    if (_queuedAction.attire.ring != NONE) {
      revert UnsupportedAttire();
    }
    if (_queuedAction.attire.reserved1 != NONE) {
      revert UnsupportedAttire();
    }

    (uint16 itemTokenIdRangeMin, uint16 itemTokenIdRangeMax) = world.getPermissibleItemsForAction(
      _queuedAction.actionId
    );

    if (!world.actionIsAvailable(_queuedAction.actionId)) {
      revert ActionNotAvailable();
    }

    // TODO: Check if it requires an action choice and that a valid one was specified
    _checkEquipActionEquipment(_from, _queuedAction.leftArmEquipmentTokenId, itemTokenIdRangeMin, itemTokenIdRangeMax);
    _checkEquipActionEquipment(_from, _queuedAction.rightArmEquipmentTokenId, itemTokenIdRangeMin, itemTokenIdRangeMax);

    _checkAttire(_from, _queuedAction.attire);
    _checkActionConsumables(_from, _queuedAction);

    _queuedAction.startTime = uint40(_startTime);
    _queuedAction.attire.queueId = _queueId;
    _player.actionQueue.push(_queuedAction);
    emit AddToActionQueue(_playerId, _queuedAction);
  }

  function _clearActionQueue(uint _playerId) private {
    QueuedAction[] memory queuedActions;
    _setActionQueue(_playerId, queuedActions);
  }

  function _setActionQueue(uint _playerId, QueuedAction[] memory _queuedActions) private {
    Player storage player = players[_playerId];
    player.actionQueue = _queuedActions;
    emit SetActionQueue(_playerId, player.actionQueue);
  }

  function consumeActions(uint _playerId) external isOwnerOfPlayerAndActive(_playerId) {
    QueuedAction[] memory remainingSkillQueue = _consumeActions(msg.sender, _playerId);
    _setActionQueue(_playerId, remainingSkillQueue);
  }

  function _startActions(
    uint _playerId,
    QueuedAction[] memory _queuedActions,
    uint16 _boostItemTokenId,
    ActionQueueStatus _queueStatus
  ) private {
    if (_queuedActions.length == 0) {
      revert SkillsArrayZero();
    }

    address from = msg.sender;
    uint totalTimespan;
    QueuedAction[] memory remainingSkills = _consumeActions(from, _playerId);

    if (_boostItemTokenId != NONE) {
      _consumeBoost(_playerId, _boostItemTokenId, uint40(block.timestamp));
    }

    Player storage player = players[_playerId];
    if (_queueStatus == ActionQueueStatus.NONE) {
      if (player.actionQueue.length > 0) {
        _clearActionQueue(_playerId);
      }
      if (_queuedActions.length > 3) {
        revert TooManyActionsQueued();
      }
    } else {
      if (_queueStatus == ActionQueueStatus.KEEP_LAST_IN_PROGRESS && remainingSkills.length > 1) {
        // Only want one
        assembly ("memory-safe") {
          mstore(remainingSkills, 1)
        }
      }

      // Keep remaining actions
      if (remainingSkills.length + _queuedActions.length > 3) {
        revert TooManyActionsQueuedSomeAlreadyExist();
      }
      player.actionQueue = remainingSkills;

      for (uint i = 0; i < remainingSkills.length; ++i) {
        totalTimespan += remainingSkills[i].timespan;
      }
    }

    uint prevEndTime = block.timestamp + totalTimespan;

    uint256 i;
    uint currentQueuedActionId = queueId;
    do {
      QueuedAction memory queuedAction = _queuedActions[i];

      if (totalTimespan + queuedAction.timespan > MAX_TIME) {
        // Must be the last one which will exceed the max time
        if (i != _queuedActions.length - 1) {
          revert ActionTimespanExceedsMaxTime();
        }
        // Shorten it so that it does not extend beyond the max time
        queuedAction.timespan = uint24(MAX_TIME - totalTimespan);
      }

      _addToQueue(from, _playerId, queuedAction, uint64(currentQueuedActionId), prevEndTime);
      unchecked {
        ++i;
        ++currentQueuedActionId;
      }
      totalTimespan += queuedAction.timespan;
      prevEndTime += queuedAction.timespan;
    } while (i < _queuedActions.length);

    assert(totalTimespan <= MAX_TIME); // Should never happen
    queueId = currentQueuedActionId;
  }

  function startAction(
    uint _playerId,
    QueuedAction calldata _queuedAction,
    ActionQueueStatus _queueStatus
  ) external isOwnerOfPlayerAndActive(_playerId) {
    QueuedAction[] memory queuedActions = new QueuedAction[](1);
    queuedActions[0] = _queuedAction;
    _startActions(_playerId, queuedActions, NONE, _queueStatus);
  }

  // Queue them up (Skill X for some amount of time, Skill Y for some amount of time, SKill Z for some amount of time)
  function startActions(
    uint _playerId,
    QueuedAction[] calldata _queuedActions,
    uint16 _boostItemTokenId,
    ActionQueueStatus _queueStatus
  ) external isOwnerOfPlayerAndActive(_playerId) {
    _startActions(_playerId, _queuedActions, _boostItemTokenId, _queueStatus);
  }

  /*
  function removeQueuedAction(uint _playerId, uint _queueId) external isOwnerOfPlayer(_playerId) {
    // If the action is in progress, it can't be removed (allow later)
    QueuedAction[] storage actionQueue = players[_playerId].actionQueue;
    for (uint i; i < actionQueue.length; ++i) {
      QueuedAction storage queuedAction = actionQueue[i];
      if (queuedAction.attire.queueId == _queueId) {
        uint skillEndTime = queuedAction.startTime +
          (
            speedMultiplier[_playerId] > 1
              ? uint(queuedAction.timespan) / speedMultiplier[_playerId]
              : queuedAction.timespan
          );

        uint elapsedTime = _getElapsedTime(_playerId, skillEndTime, queuedAction);
        require(elapsedTime == 0);
        // Action hasn't started yet so allow it to be removed.
        for (uint j = i; j < actionQueue.length - 1; ++j) {
          actionQueue[j] = actionQueue[j + 1];
          // Shift start times
          actionQueue[j].startTime -= queuedAction.timespan;
        }
        actionQueue.pop();
        emit RemoveQueuedAction(_playerId, _queueId);
        return;
      }
    }
  } */

  // Get any changes that are pending and not on the blockchain yet.
  function pending(uint _playerId) external view returns (PendingOutput memory pendingOutput) {
    QueuedAction[] storage actionQueue = players[_playerId].actionQueue;
    return
      PlayerLibrary.pending(
        _playerId,
        actionQueue,
        players[_playerId],
        itemNFT,
        world,
        speedMultiplier[_playerId],
        activeBoosts[_playerId]
      );
  }

  function getActionQueue(uint _playerId) external view returns (QueuedAction[] memory) {
    return players[_playerId].actionQueue;
  }

  function actionQueueLength(uint _playerId) external view returns (uint256) {
    return players[_playerId].actionQueue.length;
  }

  /*  function getLootBonusMultiplier(uint  _playerId) external view returns (uint256) {
    // The higher the level the higher the multiplier?
    return 2;
  } */

  function _handleLevelUpRewards(
    address _from,
    uint _playerId,
    uint oldOverallSkillPoints,
    uint newOverallSkillPoints
  ) private {
    /*
    // Level 99
    if (oldOverallSkillPoints < LEVEL_99_BOUNDARY && newOverallSkillPoints >= LEVEL_99_BOUNDARY) {
      // Mint rewards
      uint[] memory itemTokenIds = new uint[](1);
      itemTokenIds[0] = SAPPHIRE_AMULET;

      uint[] memory amounts = new uint[](1);
      amounts[0] = 1;

      itemNFT.mintBatch(_from, itemTokenIds, amounts);

      // Consume an XP boost immediately
      // TODO

      emit LevelUp(_playerId, itemTokenIds, amounts);
    } else if (oldOverallSkillPoints < LEVEL_90_BOUNDARY && newOverallSkillPoints >= LEVEL_90_BOUNDARY) {} else if (
      oldOverallSkillPoints < LEVEL_80_BOUNDARY && newOverallSkillPoints >= LEVEL_80_BOUNDARY
    ) {} else if (oldOverallSkillPoints < LEVEL_70_BOUNDARY && newOverallSkillPoints >= LEVEL_70_BOUNDARY) {} else if (
      oldOverallSkillPoints < LEVEL_60_BOUNDARY && newOverallSkillPoints >= LEVEL_60_BOUNDARY
    ) {} else if (oldOverallSkillPoints < LEVEL_50_BOUNDARY && newOverallSkillPoints >= LEVEL_50_BOUNDARY) {} else if (
      oldOverallSkillPoints < LEVEL_40_BOUNDARY && newOverallSkillPoints >= LEVEL_40_BOUNDARY
    ) {} else if (oldOverallSkillPoints < LEVEL_30_BOUNDARY && newOverallSkillPoints >= LEVEL_30_BOUNDARY) {} else if (
      oldOverallSkillPoints < LEVEL_20_BOUNDARY && newOverallSkillPoints >= LEVEL_20_BOUNDARY
    ) {} else if (oldOverallSkillPoints < LEVEL_10_BOUNDARY && newOverallSkillPoints >= LEVEL_10_BOUNDARY) {} else if (
      oldOverallSkillPoints < LEVEL_5_BOUNDARY && newOverallSkillPoints >= LEVEL_5_BOUNDARY
    ) {} */
  }

  /*
  function getLoot(uint actionId, uint seed) external view returns (uint[] memory playerIds) {
    if (seed == 0) {
      return playerIds;
    }

    playerIds = new uint[](3); // max
    uint length;
    if (seed % 2 == 0) {
      playerIds[0] = SAPPHIRE_AMULET;
    } else {
      playerIds[0] = BRONZE_PICKAXE;
    }

    assembly ("memory-safe") {
      mstore(playerIds, length)
    }
  } */

  function setSpeedMultiplier(uint _playerId, uint16 multiplier) external {
    // Disable for production code
    speedMultiplier[_playerId] = multiplier;
  }

  function _addRemainingSkill(
    QueuedAction[] memory remainingSkills,
    QueuedAction storage queuedAction,
    uint prevEndTime,
    uint length
  ) private view {
    uint40 end = queuedAction.startTime + queuedAction.timespan;

    QueuedAction memory remainingAction = queuedAction;
    remainingAction.startTime = uint40(prevEndTime);
    remainingAction.timespan = uint16(end - prevEndTime);

    // Build a list of the skills queued that remain
    remainingSkills[length] = remainingAction;
  }

  function getURI(
    uint _playerId,
    bytes32 _name,
    bytes32 _avatarName,
    string calldata _avatarDescription,
    string calldata imageURI
  ) external view returns (string memory) {
    Player storage player = players[_playerId];
    return
      PlayerLibrary.uri(_name, skillPoints[_playerId], player.totalStats, _avatarName, _avatarDescription, imageURI);
  }

  function _getElapsedTime(
    uint _playerId,
    uint _skillEndTime,
    QueuedAction storage _queuedAction
  ) private view returns (uint) {
    return PlayerLibrary.getElapsedTime(_skillEndTime, _queuedAction, speedMultiplier[_playerId]);
  }

  function _updateSkillPoints(uint _playerId, Skill _skill, uint32 _pointsAccrued) private {
    skillPoints[_playerId][_skill] += _pointsAccrued;
    emit AddSkillPoints(_playerId, _skill, _pointsAccrued);
  }

  function _addPendingLoot(
    PendingLoot[] storage _pendingLoot,
    ActionRewards memory _actionRewards,
    uint _actionId,
    uint _elapsedTime,
    uint _skillEndTime
  ) private {
    bool hasRandomRewards = _actionRewards.randomRandomTokenId1 != NONE; // A precheck as an optimization
    if (hasRandomRewards) {
      bool hasSeed = world.hasSeed(_skillEndTime);
      if (!hasSeed) {
        // There's no seed for this yet, so add it to the loot queue. (TODO: They can force add it later)
        _pendingLoot.push(
          PendingLoot({actionId: _actionId, timestamp: uint40(_skillEndTime), elapsedTime: uint16(_elapsedTime)})
        );
      }
    }
  }

  // Callback after minting a player. If they aren't the active player then set it.
  function mintedPlayer(address _from, uint _playerId, bool makeActive) external onlyPlayerNFT {
    if (makeActive) {
      _setActivePlayer(_from, _playerId);
    }
  }

  function _setActivePlayer(address _from, uint _playerId) private {
    uint existingActivePlayer = activePlayer[_from];
    if (existingActivePlayer > 0) {
      // If there is an existing active player, unequip all items
      _clearEverything(_from, existingActivePlayer);
    }
    // All attire and actions can be made for this player
    activePlayer[_from] = _playerId;
    emit SetActivePlayer(_from, existingActivePlayer, _playerId);
  }

  function setActivePlayer(uint _playerId) external isOwnerOfPlayer(_playerId) {
    _setActivePlayer(msg.sender, _playerId);
  }

  function _extraXPFromBoost(
    uint _playerId,
    bool _isCombatSkill,
    uint _actionStartTime,
    uint _elapsedTime,
    uint16 _xpPerHour
  ) private view returns (uint32 boostPointsAccrued) {
    return
      PlayerLibrary.extraXPFromBoost(
        _isCombatSkill,
        _actionStartTime,
        _elapsedTime,
        _xpPerHour,
        activeBoosts[_playerId]
      );
  }

  function _consumeActions(address _from, uint _playerId) private returns (QueuedAction[] memory remainingSkills) {
    Player storage player = players[_playerId];
    if (player.actionQueue.length == 0) {
      // No actions remaining
      return remainingSkills;
    }

    // TODO: Check they have everything (attire is checked already)
    uint previousSkillPoints = player.totalSkillPoints;
    uint32 allpointsAccrued;

    remainingSkills = new QueuedAction[](player.actionQueue.length); // Max
    uint length;
    uint nextStartTime = block.timestamp;
    for (uint i = 0; i < player.actionQueue.length; ++i) {
      QueuedAction storage queuedAction = player.actionQueue[i];

      // This will only ones that they have a balance for at this time. This will check balances
      CombatStats memory combatStats = _updateCombatStats(
        _from,
        player.totalStats,
        queuedAction.attire,
        true,
        queuedAction.startTime
      );

      uint32 pointsAccrued;
      uint skillEndTime = queuedAction.startTime +
        (
          speedMultiplier[_playerId] > 1
            ? uint(queuedAction.timespan) / speedMultiplier[_playerId]
            : queuedAction.timespan
        );

      uint elapsedTime = _getElapsedTime(_playerId, skillEndTime, queuedAction);
      if (elapsedTime == 0) {
        // Haven't touched this action yet so add it all
        _addRemainingSkill(remainingSkills, queuedAction, nextStartTime, length);
        nextStartTime += queuedAction.timespan;
        length = i + 1;
        continue;
      }

      bool fullyFinished = elapsedTime >= queuedAction.timespan;

      // Create some items if necessary (smithing ores to bars for instance)
      bool died;

      ActionChoice memory actionChoice;
      bool isCombat = _isCombat(queuedAction.skill);

      uint xpElapsedTime = elapsedTime;

      if (queuedAction.choiceId != 0) {
        // Includes combat
        // { || isCombat) {
        uint combatElapsedTime;
        actionChoice = world.getActionChoice(isCombat ? 0 : queuedAction.actionId, queuedAction.choiceId);

        (xpElapsedTime, combatElapsedTime, died) = PlayerLibrary.processConsumables(
          _from,
          _playerId,
          queuedAction,
          elapsedTime,
          world,
          itemNFT,
          combatStats,
          actionChoice
        );
      }
      uint queueId = queuedAction.attire.queueId;
      if (!died) {
        bool _isCombatSkill = _isCombat(queuedAction.skill);
        uint16 xpPerHour = world.getXPPerHour(queuedAction.actionId, _isCombatSkill ? NONE : queuedAction.choiceId);
        pointsAccrued = uint32((xpElapsedTime * xpPerHour) / 3600);
        pointsAccrued += _extraXPFromBoost(_playerId, _isCombatSkill, queuedAction.startTime, elapsedTime, xpPerHour);
      } else {
        emit Died(_from, _playerId, queueId);
      }

      if (!fullyFinished) {
        // Add the remainder if this action is not fully consumed
        _addRemainingSkill(remainingSkills, queuedAction, nextStartTime, length);
        nextStartTime += elapsedTime;
        length = i + 1;
      }

      if (pointsAccrued > 0) {
        _updateSkillPoints(_playerId, queuedAction.skill, pointsAccrued);

        if (_isCombat(queuedAction.skill)) {
          // Update health too with 33%
          _updateSkillPoints(_playerId, Skill.HEALTH, (pointsAccrued * 33) / 100);
        }

        ActionRewards memory actionRewards = world.getActionRewards(queuedAction.actionId);
        (uint[] memory newIds, uint[] memory newAmounts) = PlayerLibrary.getRewards(
          _from,
          uint40(queuedAction.startTime + xpElapsedTime),
          xpElapsedTime,
          world,
          actionRewards
        );

        _addPendingLoot(pendingLoot, actionRewards, queuedAction.actionId, xpElapsedTime, skillEndTime);

        // This loot might be needed for a future task so mint now rather than later
        // But this could be improved
        if (newIds.length > 0) {
          itemNFT.mintBatch(_from, newIds, newAmounts);
          emit Rewards(_from, _playerId, queuedAction.attire.queueId, newIds, newAmounts);
        }
        allpointsAccrued += pointsAccrued;
      }

      if (fullyFinished) {
        emit ActionFinished(_from, _playerId, queueId);
      } else {
        emit ActionPartiallyFinished(_from, _playerId, queueId, elapsedTime);
      }
    }

    if (allpointsAccrued > 0) {
      // Check if they have levelled up
      _handleLevelUpRewards(_from, _playerId, previousSkillPoints, previousSkillPoints + allpointsAccrued);
    }

    assembly ("memory-safe") {
      mstore(remainingSkills, length)
    }
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// For optimization purposes this contains a few data items, and everything except combat stats (although it could fit?)
struct Item {
  // TODO: Type?
  EquipPosition equipPosition;
  bool hasNonCombatStats;
  bool hasCombatStats;
  bool exists;
  // Food
  uint16 healthRestored;
  // Boost vial
  BoostType boostType;
  uint16 boostValue; // Varies, could be the % increase
  uint24 boostDuration; // How long the effect of the boost last
  // Combat stats
  int8 attack;
  int8 magic;
  int8 range;
  int8 meleeDefence;
  int8 magicDefence;
  int8 rangeDefence;
  int8 health;
  // Noncombat skills
  Skill skill1;
  int16 skillDiff1;
  //    Skill skill2;
  //    int16 diff2;
  //    Skill skill3;
  //    int16 diff3;
}

enum BoostType {
  NONE,
  ANY_XP,
  COMBAT_XP,
  NON_COMBAT_XP,
  GATHERING,
  ABSENCE
}

enum Skill {
  NONE,
  COMBAT, // This is a helper which incorporates attack <-> magic
  ATTACK,
  RANGED,
  MAGIC,
  DEFENCE,
  //  MELEE_DEFENCE, // combo
  //  RANGED_DEFENCE, // combo
  //  MAGIC_DEFENCE, // combo
  HEALTH,
  MINING,
  WOODCUTTING,
  FISHING,
  SMITHING,
  THIEVING,
  CRAFTING,
  COOKING,
  FIREMAKING
}

enum EquipPosition {
  HEAD,
  NECK,
  BODY,
  ARMS,
  LEGS,
  BOOTS,
  SPARE1,
  SPARE2,
  LEFT_HAND,
  RIGHT_HAND,
  BOTH_HANDS,
  ARROW_SATCHEL,
  MAGIC_BAG,
  FOOD,
  AUX, // wood, seeds  etc..
  BOOST_VIAL,
  NONE
}

// CombatStats
struct CombatStats {
  int16 attack;
  int16 magic;
  int16 range;
  int16 meleeDefence;
  int16 magicDefence;
  int16 rangeDefence;
  int16 health;
}

// Loot
struct ActionReward {
  uint16 itemTokenId;
  uint24 rate; // num per hour, base 100 (2 decimals) or percentage chance
}
struct PendingLoot {
  uint actionId;
  uint40 timestamp;
  uint16 elapsedTime;
}
struct Equipment {
  uint16 itemTokenId;
  uint16 numToEquip;
}

struct ActionRewards {
  uint16 guaranteedRewardTokenId1;
  uint24 guaranteedRewardRate1; // num per hour, base 100 (2 decimals)
  uint16 guaranteedRewardTokenId2;
  uint24 guaranteedRewardRate2;
  uint16 guaranteedRewardTokenId3;
  uint24 guaranteedRewardRate3;
  // Random chance rewards
  uint16 randomRandomTokenId1;
  uint16 randomRewardChance1; // percentage, base 100 (2 decimals)
  uint16 randomRandomTokenId2;
  uint16 randomRewardChance2;
  uint16 randomRandomTokenId3;
  uint16 randomRewardChance3;
  uint16 randomReward4;
  uint16 randomRewardChance4;
}

// This is effectively a ratio to produce 1 of outputTokenId.
// Fixed based available actions that can be undertaken for an action
struct ActionChoice {
  Skill skill;
  uint32 diff;
  uint32 rate; // rate of output produced per hour (base 100) 2 decimals
  uint16 xpPerHour;
  uint32 minSkillPoints;
  uint16 inputTokenId1;
  uint8 num1;
  uint16 inputTokenId2;
  uint8 num2;
  uint16 inputTokenId3;
  uint8 num3;
  uint16 outputTokenId; // Always num of 1
}

// The user chooses these
struct QueuedAction {
  // Keep this first
  Attire attire; // Keep here for now
  uint16 actionId;
  uint16 regenerateId; // Food (combat), maybe something for non-combat later
  uint16 choiceId; // Melee/Arrow/Magic (combat), logs, ore (non-combat)
  uint16 choiceId1; // Reserved (TBD)
  uint16 choiceId2; // Reserved (TBD)
  uint16 rightArmEquipmentTokenId; // Axe/Sword/bow, can be empty
  uint16 leftArmEquipmentTokenId; // Shield, can be empty
  uint24 timespan; // How long to queue the action for
  Skill skill; // attack, defence, strength, magic, ranged, woodcutting, needs to match actionId skill. Attack/defence can also be used
  uint40 startTime; // Filled in by the function
  //  bool reusePrev; // If true, then the previous queued action attire is reused?
  // 9 bytes left
}

struct ActionInfo {
  Skill skill;
  bool isAvailable;
  bool isDynamic;
  bool isCombat;
  uint16 xpPerHour;
  uint16 numSpawn; // Mostly for combat, capped respawn rate for xp/drops
  uint32 minSkillPoints;
  uint16 itemTokenIdRangeMin; // Inclusive
  uint16 itemTokenIdRangeMax; // Inclusive
}

// Equipment (leave at the bottom to allow for further ones)
struct Attire {
  uint16 helmet; // tokenId for the head (1 - 255)
  uint16 amulet; // tokenId for the neck (256 - 511) (256 * i -> 256 * (i + 1))
  uint16 armor;
  uint16 gauntlets;
  uint16 tassets;
  uint16 boots;
  uint16 ring;
  uint16 reserved1;
  uint64 queueId; // Just here for packing purposes
}

// TODO: Can pack this better, remove the structs
struct Player {
  // These are stored in case individual items are changed later, but also prevents having to read them loads
  // Base attributes
  CombatStats totalStats;
  // TODO: Can be up to 7
  QueuedAction[] actionQueue;
  uint240 totalSkillPoints;
  uint8 version; // This is used in case we want to do some migration of old characters, like halt them at level 30 from gaining XP
}

// This is only for viewing so doesn't need to be optimized
struct PendingOutput {
  Equipment[] consumed;
  ActionReward[] produced;
  bool died;
}

struct PlayerBoostInfo {
  uint40 startTime;
  uint24 duration;
  uint16 val;
  uint16 itemTokenId; // Get the effect of it
  BoostType boostType;
}

uint constant MAX_LOOT_PER_ACTION = 3;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./VRFConsumerBaseV2Upgradeable.sol";
import "./types.sol";

// Fantom VRF
// VRF 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634
// LINK token 0x6F43FF82CCA38001B6699a8AC47A2d0E66939407
// PREMIUM 0.0005 LINK
contract World is VRFConsumerBaseV2Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
  event RequestSent(uint256 requestId, uint32 numWords);
  event RequestFulfilled(uint256 requestId, uint256 randomWord);
  event AddAction(uint actionId, Action action);
  event EditAction(uint actionId, Action action);
  event SetAvailableAction(uint actionId, bool available);
  event AddDynamicActions(uint[] actionIds);
  event RemoveDynamicActions(uint[] actionIds);
  event AddActionChoice(uint actionId, uint actionChoiceId, ActionChoice choice);
  event AddActionChoices(uint actionId, uint startActionChoice, ActionChoice[] choices);

  struct Action {
    ActionInfo info;
    ActionReward[] guaranteedRewards;
    ActionReward[] randomRewards;
    CombatStats combatStats;
  }

  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 subscriptionId;

  // Past request ids
  uint[] public requestIds; // Each one is a seed for a day
  mapping(uint => uint) public randomWords; /* requestId --> random word */
  uint public lastSeedUpdatedTime;

  uint startTime;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network, this is 10000gwei
  // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
  bytes32 constant keyHash = 0x5881eea62f9876043df723cf89f0c2bb6f950da25e9dfe66995c24f919c8f8ab;

  uint32 constant callbackGasLimit = 100000;
  // The default is 3, but you can set this higher.
  uint16 constant requestConfirmations = 3;
  // For this example, retrieve 1 random value in one request.
  // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
  uint32 constant numWords = 1;

  uint32 public constant MIN_SEED_UPDATE_TIME = 1 days;
  uint32 public constant MIN_DYNAMIC_ACTION_UPDATE_TIME = 1 days;

  mapping(uint => ActionInfo) public actions;
  uint public lastActionId;
  uint public actionChoiceId;
  uint[] private lastAddedDynamicActions;
  uint public lastDynamicUpdatedTime;

  mapping(uint => mapping(uint => ActionChoice)) public actionChoices; // action id => (choice id => Choice)
  mapping(uint => CombatStats) actionCombatStats; // action id => combat stats

  mapping(uint => ActionRewards) private actionRewards;

  function initialize(VRFCoordinatorV2Interface _coordinator, uint64 _subscriptionId) public initializer {
    __VRFConsumerBaseV2_init(address(_coordinator));
    __Ownable_init();
    __UUPSUpgradeable_init();

    COORDINATOR = _coordinator;
    subscriptionId = _subscriptionId;
    lastActionId = 1;
    actionChoiceId = 1;
    startTime = block.timestamp;
  }

  function requestSeedUpdate() external returns (uint256 requestId) {
    // Last one has not been fulfilled yet
    if (requestIds.length > 0) {
      require(requestIds[requestIds.length - 1] != 0, "Seed can't be updated");
    }

    require(lastSeedUpdatedTime + MIN_SEED_UPDATE_TIME <= block.timestamp, "Can only request after 1 day has passed");

    // Will revert if subscription is not set and funded.
    requestId = COORDINATOR.requestRandomWords(
      keyHash,
      subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );

    requestIds.push(requestId);
    lastSeedUpdatedTime = lastSeedUpdatedTime == 0 ? block.timestamp : lastSeedUpdatedTime + MIN_SEED_UPDATE_TIME;
    emit RequestSent(requestId, numWords);
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
    require(_requestId == requestIds[requestIds.length - 1], "request not found");
    require(randomWords[_requestId] == 0, "Request already been satisfied");

    uint random = _randomWords[0];
    if (random == 0) {
      // Not sure if 0 can be selected, but in case use previous block hash as pseudo random number
      random = uint(blockhash(block.number - 1));
    }

    randomWords[_requestId] = random;
    emit RequestFulfilled(_requestId, random);
  }

  function hasSeed(uint timestamp) external view returns (bool) {
    uint offset = (timestamp - startTime) / MIN_SEED_UPDATE_TIME;
    return offset > 0 && requestIds.length >= offset;
  }

  function getSeed(uint timestamp) public view returns (uint seed) {
    uint offset = (timestamp - startTime) / MIN_SEED_UPDATE_TIME;
    seed = randomWords[requestIds[offset - 1]];
    require(seed > 0, "No valid seed");
  }

  // Can be called by anyone as long as over 1 day has passed since the last call
  function updateDynamicActions() external {
    require(
      (lastDynamicUpdatedTime + MIN_DYNAMIC_ACTION_UPDATE_TIME) <= block.timestamp,
      "Can only request after 1 day has passed"
    );

    emit RemoveDynamicActions(lastAddedDynamicActions);

    // These are no longer available as existing actions
    for (uint i = 0; i < lastAddedDynamicActions.length; ++i) {
      actions[lastAddedDynamicActions[i]].isAvailable = false;
    }

    delete lastAddedDynamicActions;
    uint seed = getSeed(block.timestamp);

    uint[] memory actionIdsToAdd = new uint[](1);

    if (seed % 2 == 0) {
      // If it's even do X
      actionIdsToAdd[0] = 1; // ?
    } else {
      actionIdsToAdd[0] = 2; // ?
    }

    lastAddedDynamicActions = actionIdsToAdd;

    for (uint i; i < actionIdsToAdd.length; ++i) {
      actions[actionIdsToAdd[i]].isAvailable = false;
    }

    lastDynamicUpdatedTime = block.timestamp;
    emit AddDynamicActions(actionIdsToAdd);
  }

  function getSkill(uint _actionId) external view returns (Skill) {
    return actions[_actionId].skill;
  }

  function getActionRewards(uint _actionId) external view returns (ActionRewards memory) {
    return actionRewards[_actionId];
  }

  function getPermissibleItemsForAction(
    uint _actionId
  ) external view returns (uint16 itemTokenIdRangeMin, uint16 itemTokenIdRangeMax) {
    ActionInfo storage actionInfo = actions[_actionId];
    return (actionInfo.itemTokenIdRangeMin, actionInfo.itemTokenIdRangeMax);
  }

  function getXPPerHour(uint16 _actionId, uint16 _actionChoiceId) external view returns (uint16 xpPerHour) {
    return _actionChoiceId != 0 ? actionChoices[_actionId][_actionChoiceId].xpPerHour : actions[_actionId].xpPerHour;
  }

  function getNumSpawn(uint16 _actionId) external view returns (uint numSpawn) {
    return actions[_actionId].numSpawn;
  }

  function _setAction(uint _actionId, Action calldata _action) private {
    require(_action.info.itemTokenIdRangeMin <= _action.info.itemTokenIdRangeMax);
    actions[_actionId] = _action.info;

    // Set the rewards
    ActionRewards storage actionReward = actionRewards[_actionId];
    if (_action.guaranteedRewards.length > 0) {
      actionReward.guaranteedRewardTokenId1 = _action.guaranteedRewards[0].itemTokenId;
      actionReward.guaranteedRewardRate1 = _action.guaranteedRewards[0].rate;
    }
    if (_action.guaranteedRewards.length > 1) {
      actionReward.guaranteedRewardTokenId2 = _action.guaranteedRewards[1].itemTokenId;
      actionReward.guaranteedRewardRate2 = _action.guaranteedRewards[1].rate;
    }
    if (_action.guaranteedRewards.length > 2) {
      actionReward.guaranteedRewardTokenId3 = _action.guaranteedRewards[2].itemTokenId;
      actionReward.guaranteedRewardRate3 = _action.guaranteedRewards[2].rate;
    }
    // Now do the same for randomRewards
    if (_action.randomRewards.length > 0) {
      actionReward.randomRandomTokenId1 = _action.randomRewards[0].itemTokenId;
      actionReward.randomRewardChance1 = uint16(_action.randomRewards[0].rate);
    }
    if (_action.randomRewards.length > 1) {
      actionReward.randomRandomTokenId2 = _action.randomRewards[1].itemTokenId;
      actionReward.randomRewardChance2 = uint16(_action.randomRewards[1].rate);
    }
    if (_action.randomRewards.length > 2) {
      actionReward.randomRandomTokenId3 = _action.randomRewards[2].itemTokenId;
      actionReward.randomRewardChance3 = uint16(_action.randomRewards[2].rate);
    }
    if (_action.randomRewards.length > 3) {
      actionReward.randomReward4 = _action.randomRewards[3].itemTokenId;
      actionReward.randomRewardChance4 = uint16(_action.randomRewards[3].rate);
    }

    if (_action.info.isCombat) {
      actionCombatStats[_actionId] = _action.combatStats;
    }
  }

  function _addAction(uint _actionId, Action calldata _action) private {
    require(!_action.info.isDynamic, "Action is dynamic");
    _setAction(_actionId, _action);
    emit AddAction(_actionId, _action);
  }

  function addActions(Action[] calldata _actions) external onlyOwner {
    uint currentActionId = lastActionId;
    for (uint i; i < _actions.length; ++i) {
      _addAction(currentActionId + i, _actions[i]);
    }
    lastActionId += _actions.length;
  }

  function addAction(Action calldata _action) external onlyOwner {
    _addAction(lastActionId, _action);
    ++lastActionId;
  }

  function editAction(uint _actionId, Action calldata _action) external onlyOwner {
    _setAction(_actionId, _action);
    emit EditAction(_actionId, _action);
  }

  // actionId of 0 means it is not tied to a specific action
  function addActionChoice(uint _actionId, ActionChoice calldata _actionChoice) external onlyOwner {
    uint currentActionChoiceId = actionChoiceId;
    actionChoices[_actionId][currentActionChoiceId] = _actionChoice;
    emit AddActionChoice(_actionId, currentActionChoiceId, _actionChoice);
    actionChoiceId = currentActionChoiceId + 1;
  }

  function addActionChoices(uint _actionId, ActionChoice[] calldata _actionChoices) external onlyOwner {
    require(_actionChoices.length > 0);
    uint currentActionChoiceId = actionChoiceId;
    for (uint i; i < _actionChoices.length; ++i) {
      actionChoices[_actionId][currentActionChoiceId + i] = _actionChoices[i];
    }
    emit AddActionChoices(_actionId, currentActionChoiceId, _actionChoices);
    actionChoiceId = currentActionChoiceId + _actionChoices.length;
  }

  function addBulkActionChoices(
    uint[] calldata _actionIds,
    ActionChoice[][] calldata _actionChoices
  ) external onlyOwner {
    require(_actionChoices.length > 0);
    uint currentActionChoiceId = actionChoiceId;
    uint count;
    for (uint i; i < _actionIds.length; ++i) {
      uint actionId = _actionIds[i];
      emit AddActionChoices(actionId, currentActionChoiceId + count, _actionChoices[i]);
      for (uint j; j < _actionChoices[i].length; ++j) {
        actionChoices[actionId][currentActionChoiceId + count] = _actionChoices[i][j];
        ++count;
      }
    }
    actionChoiceId = currentActionChoiceId + count;
  }

  function setAvailable(uint _actionId, bool _isAvailable) external onlyOwner {
    require(actions[_actionId].skill != Skill.NONE, "Action does not exist");
    require(!actions[_actionId].isDynamic, "Action is dynamic");
    actions[_actionId].isAvailable = _isAvailable;
    emit SetAvailableAction(_actionId, _isAvailable);
  }

  function actionIsAvailable(uint _actionId) external view returns (bool) {
    return actions[_actionId].isAvailable;
  }

  function getCombatStats(uint _actionId) external view returns (bool isCombat, CombatStats memory stats) {
    isCombat = actions[_actionId].isCombat;
    if (isCombat) {
      stats = actionCombatStats[_actionId];

      // TODO: This shouldn't be needed
      if (stats.attack <= 0) {
        stats.attack = 1;
      }
      if (stats.meleeDefence <= 0) {
        stats.meleeDefence = 1;
      }
      if (stats.magic <= 0) {
        stats.magic = 1;
      }
      if (stats.magicDefence <= 0) {
        stats.magicDefence = 1;
      }
      if (stats.range <= 0) {
        stats.range = 1;
      }
      if (stats.rangeDefence <= 0) {
        stats.rangeDefence = 1;
      }
      if (stats.health <= 0) {
        stats.health = 1;
      }
    }
  }

  function getActionChoice(uint _actionId, uint _choiceId) external view returns (ActionChoice memory) {
    return actionChoices[_actionId][_choiceId];
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint16 constant NONE = 0;
// 1 - 255 (head)
uint16 constant HEAD_BASE = 1;
uint16 constant BRONZE_HELMET = HEAD_BASE;
uint16 constant IRON_HELMET = HEAD_BASE + 1;
uint16 constant MITHRIL_HELMET = HEAD_BASE + 2;
uint16 constant ADAMANTINE_HELMET = HEAD_BASE + 3;
uint16 constant RUNITE_HELMET = HEAD_BASE + 4;
uint16 constant TITANIUM_HELMET = HEAD_BASE + 5;
uint16 constant ORCHALCUM_HELMET = HEAD_BASE + 6;

uint16 constant HEAD_MAX = HEAD_BASE + 254; // Inclusive
// 257 - 511 (neck)
uint16 constant NECK_BASE = 257;
uint16 constant SAPPHIRE_AMULET = NECK_BASE;
uint16 constant EMERALD_AMULET = NECK_BASE + 1;
uint16 constant RUBT_AMULET = NECK_BASE + 2;
uint16 constant AMETHYST_AMULET = NECK_BASE + 3;
uint16 constant DIAMOND_AMULET = NECK_BASE + 4;
uint16 constant DRAGONSTONE_AMULET = NECK_BASE + 5;
uint16 constant NECK_MAX = NECK_BASE + 254;

// 513 - 767 (body)
uint16 constant BODY_BASE = 513;
uint16 constant BRONZE_ARMOR = BODY_BASE;
uint16 constant IRON_ARMOR = BODY_BASE + 1;
uint16 constant MITHRIL_ARMOR = BODY_BASE + 2;
uint16 constant ADAMANTINE_ARMOR = BODY_BASE + 3;
uint16 constant RUNITE_ARMOR = BODY_BASE + 4;
uint16 constant TITANIUM_ARMOR = BODY_BASE + 5;
uint16 constant ORCHALCUM_ARMOR = BODY_BASE + 6;
uint16 constant BODY_MAX = BODY_BASE + 254;
// 769 - 1023 (arms)
uint16 constant ARMS_BASE = 769;
uint16 constant BRONZE_GAUNTLETS = ARMS_BASE;
uint16 constant IRON_GAUNTLETS = ARMS_BASE + 1;
uint16 constant MITHRIL_GAUNTLETS = ARMS_BASE + 2;
uint16 constant ADAMANTINE_GAUNTLETS = ARMS_BASE + 3;
uint16 constant RUNITE_GAUNTLETS = ARMS_BASE + 4;
uint16 constant TITANIUM_GAUNTLETS = ARMS_BASE + 5;
uint16 constant ORCHALCUM_GAUNTLETS = ARMS_BASE + 6;
uint16 constant ARMS_MAX = ARMS_BASE + 254;
// 1025 - 1279 (legs)
uint16 constant LEGS_BASE = 1025;
uint16 constant BRONZE_TASSETS = LEGS_BASE;
uint16 constant IRON_TASSETS = LEGS_BASE + 1;
uint16 constant MITHRIL_TASSETS = LEGS_BASE + 2;
uint16 constant ADAMANTINE_TASSETS = LEGS_BASE + 3;
uint16 constant RUNITE_TASSETS = LEGS_BASE + 4;
uint16 constant TITANIUM_TASSETS = LEGS_BASE + 5;
uint16 constant ORCHALCUM_TASSETS = LEGS_BASE + 6;
uint16 constant LEGS_MAX = LEGS_BASE + 254;

// 1281 - 1535 (boots)
uint16 constant BOOTS_BASE = 1281;
uint16 constant BRONZE_BOOTS = BOOTS_BASE;
uint16 constant IRON_BOOTS = BOOTS_BASE + 1;
uint16 constant MITHRIL_BOOTS = BOOTS_BASE + 2;
uint16 constant ADAMANTINE_BOOTS = BOOTS_BASE + 3;
uint16 constant RUNITE_BOOTS = BOOTS_BASE + 4;
uint16 constant TITANIUM_BOOTS = BOOTS_BASE + 5;
uint16 constant ORCHALCUM_BOOTS = BOOTS_BASE + 6;
uint16 constant BOOTS_MAX = BOOTS_BASE + 254;

// 1537 - 1791 ring(1)
// 1793 - 2047 spare(2)

// All other ones for the first arm

// Combat (right arm) (2048 - 2303)
uint16 constant COMBAT_BASE = 2048;
// Melee
uint16 constant BRONZE_SWORD = COMBAT_BASE;
uint16 constant IRON_SWORD = COMBAT_BASE + 1;
uint16 constant MITHRIL_SWORD = COMBAT_BASE + 2;
uint16 constant ADAMANTINE_SWORD = COMBAT_BASE + 3;
uint16 constant RUNITE_SWORD = COMBAT_BASE + 4;
uint16 constant TITANIUM_SWORD = COMBAT_BASE + 5;
uint16 constant ORCHALCUM_SWORD = COMBAT_BASE + 6;
// Magic
uint16 constant STAFF_BASE = COMBAT_BASE + 50;
uint16 constant STAFF_OF_THE_PHOENIX = STAFF_BASE;
uint16 constant SAPPHIRE_STAFF = STAFF_BASE + 1;
uint16 constant EMERALD_STAFF = STAFF_BASE + 2;
uint16 constant RUBY_STAFF = STAFF_BASE + 3;
uint16 constant AMETHYST_STAFF = STAFF_BASE + 4;
uint16 constant DIAMOND_STAFF = STAFF_BASE + 5;
uint16 constant DRAGONSTONE_STAFF = STAFF_BASE + 6;
uint16 constant STAFF_MAX = STAFF_BASE + 49;
// Ranged
uint16 constant BOW = COMBAT_BASE + 100;
// Combat (left arm)
uint16 constant SHIELD_BASE = COMBAT_BASE + 150;
uint16 constant BRONZE_SHIELD = SHIELD_BASE;
uint16 constant IRON_SHIELD = SHIELD_BASE + 1;
uint16 constant MITHRIL_SHIELD = SHIELD_BASE + 2;
uint16 constant ADAMANTINE_SHIELD = SHIELD_BASE + 3;
uint16 constant RUNITE_SHIELD = SHIELD_BASE + 4;
uint16 constant TITANIUM_SHIELD = SHIELD_BASE + 5;
uint16 constant ORCHALCUM_SHIELD = SHIELD_BASE + 6;

uint16 constant COMBAT_MAX = COMBAT_BASE + 255;

// Mining (2560 - 2815)
uint16 constant MINING_BASE = 2560;
uint16 constant BRONZE_PICKAXE = MINING_BASE;
uint16 constant IRON_PICKAXE = MINING_BASE + 1;
uint16 constant MITHRIL_PICKAXE = MINING_BASE + 2;
uint16 constant ADAMANTINE_PICKAXE = MINING_BASE + 3;
uint16 constant RUNITE_PICKAXE = MINING_BASE + 4;
uint16 constant TITANIUM_PICKAXE = MINING_BASE + 5;
uint16 constant ORCHALCUM_PICKAXE = MINING_BASE + 6;
uint16 constant MINING_MAX = MINING_BASE + 255;

// Woodcutting (2816 - 3071)
uint16 constant WOODCUTTING_BASE = 2816;
uint16 constant BRONZE_AXE = WOODCUTTING_BASE;
uint16 constant IRON_AXE = WOODCUTTING_BASE + 1;
uint16 constant MITHRIL_AXE = WOODCUTTING_BASE + 2;
uint16 constant ADAMANTINE_AXE = WOODCUTTING_BASE + 3;
uint16 constant RUNITE_AXE = WOODCUTTING_BASE + 4;
uint16 constant TITANIUM_AXE = WOODCUTTING_BASE + 5;
uint16 constant ORCHALCUM_AXE = WOODCUTTING_BASE + 6;
uint16 constant WOODCUTTING_MAX = WOODCUTTING_BASE + 255;

// Fishing (3072)
uint16 constant FISHING_BASE = 3072;
uint16 constant SMALL_NET = FISHING_BASE;
uint16 constant MEDIUM_NET = FISHING_BASE + 1;
uint16 constant FISHING_ROD = FISHING_BASE + 2;
uint16 constant HARPOON = FISHING_BASE + 3;
uint16 constant LARGE_NET = FISHING_BASE + 4;
uint16 constant MAGIC_NET = FISHING_BASE + 5;
uint16 constant FISHING_MAX = FISHING_BASE + 255;

// Firemaking (3328)
uint16 constant FIRE_BASE = 3328;
uint16 constant FIRE_LIGHTER = FIRE_BASE;
uint16 constant FIRE_MAX = FIRE_BASE + 255;

// Smithing (none needed)
// Thieiving (none needed)
// Crafting (none needed)
// Cooking (none needed)

// 10000+ it'a all other items

// Bars
uint16 constant BAR_BASE = 10240; // (256 * 40)
uint16 constant BRONZE_BAR = BAR_BASE;
uint16 constant IRON_BAR = BAR_BASE + 1;
uint16 constant MITHRIL_BAR = BAR_BASE + 2;
uint16 constant ADAMANTINE_BAR = BAR_BASE + 3;
uint16 constant RUNITE_BAR = BAR_BASE + 4;
uint16 constant TITANIUM_BAR = BAR_BASE + 5;
uint16 constant ORCHALCUM_BAR = BAR_BASE + 6;
uint16 constant BAR_MAX = BAR_BASE + 255;

// Logs
uint16 constant LOG_BASE = 10496;
uint16 constant LOG = LOG_BASE;
uint16 constant OAK_LOG = LOG_BASE + 1;
uint16 constant WILLOW_LOG = LOG_BASE + 2;
uint16 constant MAPLE_LOG = LOG_BASE + 3;
uint16 constant REDWOOD_LOG = LOG_BASE + 4;
uint16 constant MAGICAL_LOG = LOG_BASE + 5;
uint16 constant ASH_LOG = LOG_BASE + 6;
uint16 constant LOG_MAX = LOG_BASE + 255;

// Fish
uint16 constant RAW_FISH_BASE = 10752;
uint16 constant RAW_HUPPY = RAW_FISH_BASE;
uint16 constant RAW_MINNOW = RAW_FISH_BASE + 1;
uint16 constant RAW_SUNFISH = RAW_FISH_BASE + 2;
uint16 constant RAW_PERCH = RAW_FISH_BASE + 3;
uint16 constant RAW_CRAYFISH = RAW_FISH_BASE + 4;
uint16 constant RAW_BLUEGILL = RAW_FISH_BASE + 5;
uint16 constant RAW_CATFISH = RAW_FISH_BASE + 6;
uint16 constant RAW_CARP = RAW_FISH_BASE + 7;
uint16 constant RAW_TILAPIA = RAW_FISH_BASE + 8;
uint16 constant RAW_MUSKELLUNGE = RAW_FISH_BASE + 9;
uint16 constant RAW_SWORDFISH = RAW_FISH_BASE + 10;
uint16 constant RAW_SHARK = RAW_FISH_BASE + 11;
uint16 constant RAW_BARRIMUNDI = RAW_FISH_BASE + 12;
uint16 constant RAW_KINGFISH = RAW_FISH_BASE + 13;
uint16 constant RAW_MARLIN = RAW_FISH_BASE + 14;
uint16 constant RAW_GIANT_CATFISH = RAW_FISH_BASE + 15;
uint16 constant RAW_ELECTRIC_EEL = RAW_FISH_BASE + 16;
uint16 constant RAW_MANTA_RAY = RAW_FISH_BASE + 17;
uint16 constant RAW_LEVIATHAN = RAW_FISH_BASE + 18;
uint16 constant RAW_DRAGONFISH = RAW_FISH_BASE + 19;
uint16 constant RAW_FIRE_MAX = RAW_FISH_BASE + 255;

// Cooked fish
uint16 constant COOKED_FISH_BASE = 11008;
uint16 constant COOKED_HUPPY = COOKED_FISH_BASE;
uint16 constant COOKED_MINNOW = COOKED_FISH_BASE + 1;
uint16 constant COOKED_SUNFISH = COOKED_FISH_BASE + 2;
uint16 constant COOKED_PERCH = COOKED_FISH_BASE + 3;
uint16 constant COOKED_CRAYFISH = COOKED_FISH_BASE + 4;
uint16 constant COOKED_BLUEGILL = COOKED_FISH_BASE + 5;
uint16 constant COOKED_CATFISH = COOKED_FISH_BASE + 6;
uint16 constant COOKED_CARP = COOKED_FISH_BASE + 7;
uint16 constant COOKED_TILAPIA = COOKED_FISH_BASE + 8;
uint16 constant COOKED_MUSKELLUNGE = COOKED_FISH_BASE + 9;
uint16 constant COOKED_SWORDFISH = COOKED_FISH_BASE + 10;
uint16 constant COOKED_SHARK = COOKED_FISH_BASE + 11;
uint16 constant COOKED_BARRIMUNDI = COOKED_FISH_BASE + 12;
uint16 constant COOKED_KINGFISH = COOKED_FISH_BASE + 13;
uint16 constant COOKED_MARLIN = COOKED_FISH_BASE + 14;
uint16 constant COOKED_GIANT_CATFISH = COOKED_FISH_BASE + 15;
uint16 constant COOKED_ELECTRIC_EEL = COOKED_FISH_BASE + 16;
uint16 constant COOKED_MANTA_RAY = COOKED_FISH_BASE + 17;
uint16 constant COOKED_LEVIATHAN = COOKED_FISH_BASE + 18;
uint16 constant COOKED_DRAGONFISH = COOKED_FISH_BASE + 19;
uint16 constant COOKED_FISH_MAX = COOKED_FISH_BASE + 255;

// Farming
uint16 constant FARMING_BASE = 11264;
uint16 constant BONEMEAL = FARMING_BASE;
uint16 constant BONEMEALX2 = FARMING_BASE + 1;
uint16 constant BONEMEALX5 = FARMING_BASE + 2;
uint16 constant BONEMEALX10 = FARMING_BASE + 3;
uint16 constant FARMING_MAX = FARMING_BASE + 255;

// Mining
uint16 constant ORE_BASE = 11520;
uint16 constant COPPER_ORE = ORE_BASE;
uint16 constant TIN_ORE = ORE_BASE + 1;
uint16 constant IRON_ORE = ORE_BASE + 2;
uint16 constant SAPPHIRE_ORE = ORE_BASE + 3;
uint16 constant COAL_ORE = ORE_BASE + 4;
uint16 constant EMERALD_ORE = ORE_BASE + 5;
uint16 constant MITHRIL_ORE = ORE_BASE + 6;
uint16 constant RUBY_ORE = ORE_BASE + 7;
uint16 constant ADAMANTINE_ORE = ORE_BASE + 8;
uint16 constant AMETHYST_ORE = ORE_BASE + 9;
uint16 constant DIAMOND_ORE = ORE_BASE + 10;
uint16 constant RUNITE_ORE = ORE_BASE + 11;
uint16 constant DRAGONSTONE_ORE = ORE_BASE + 12;
uint16 constant TITANIUM_ORE = ORE_BASE + 13;
uint16 constant ORCHALCUM_ORE = ORE_BASE + 14;
uint16 constant ORE_MAX = ORE_BASE + 255;
// Arrows
uint16 constant ARROW_BASE = 11776;
uint16 constant BRONZE_ARROW = ORE_BASE;
uint16 constant ARROW_MAX = ARROW_BASE + 255;

// Scrolls
uint16 constant SCROLL_BASE = 12032;
uint16 constant SHADOW_SCROLL = SCROLL_BASE;
uint16 constant NATURE_SCROLL = SCROLL_BASE + 1;
uint16 constant AQUA_SCROLL = SCROLL_BASE + 2;
uint16 constant HELL_SCROLL = SCROLL_BASE + 3;
uint16 constant AIR_SCROLL = SCROLL_BASE + 4;
uint16 constant BARRAGE_SCROLL = SCROLL_BASE + 5;
uint16 constant FREEZE_SCROLL = SCROLL_BASE + 6;
uint16 constant SCROLL_MAX = SCROLL_BASE + 255;

// Spells
uint16 constant SPELL_BASE = 12544;
uint16 constant SHADOW_BLAST = SPELL_BASE;
uint16 constant NATURES_FURU = SPELL_BASE + 1;
uint16 constant DEATH_WAVE = SPELL_BASE + 2;
uint16 constant VORTEX = SPELL_BASE + 3;
uint16 constant MYSTIC_BLAST = SPELL_BASE + 4;
uint16 constant MAGIC_BREATH = SPELL_BASE + 5;
uint16 constant SUMMON_HELL_HOUND = SPELL_BASE + 6;
uint16 constant AIR_BALL = SPELL_BASE + 7;
uint16 constant FURY_FISTS = SPELL_BASE + 8;
uint16 constant CONCUSSION_BEAMS = SPELL_BASE + 9;
uint16 constant ICE_SPIKES = SPELL_BASE + 10;
uint16 constant SPELL_MAX = SPELL_BASE + 255;

// Boosts
uint16 constant BOOST_BASE = 12800;
uint16 constant COMBAT_BOOST = BOOST_BASE;
uint16 constant XP_BOOST = BOOST_BASE + 1;
uint16 constant GATHERING_BOOST = BOOST_BASE + 2;
uint16 constant SKILLER_BOOST = BOOST_BASE + 3;
uint16 constant ABSENCE_BOOST = BOOST_BASE + 4;
uint16 constant BOOST_MAX = BOOST_BASE + 255;

// Thieving
uint16 constant THIEVING_BASE = 13056;
uint16 constant PICKPOCKET_CHILD = THIEVING_BASE;
uint16 constant PICKPOCKET_MAN = THIEVING_BASE + 1;
uint16 constant PICKPOCKET_GUARD = THIEVING_BASE + 2;
uint16 constant LOCKPICK_CHEST = THIEVING_BASE + 3;
uint16 constant STEAL_FROM_STALL = THIEVING_BASE + 4;
uint16 constant STEAL_FROM_FARMER = THIEVING_BASE + 5;
uint16 constant STEAL_FROM_FISHERMAN = THIEVING_BASE + 6;
uint16 constant STEAL_FROM_LUMBERJACK = THIEVING_BASE + 7;
uint16 constant STEAL_FROM_BLACKSMITH = THIEVING_BASE + 8;
uint16 constant PICKPOCKET_HEAD_GUARD = THIEVING_BASE + 9;
uint16 constant PICKPOCKET_WIZARD = THIEVING_BASE + 10;
uint16 constant STEAL_FROM_POTION_SHOP = THIEVING_BASE + 11;
uint16 constant STEAL_FROM_GEM_MERCHANT = THIEVING_BASE + 12;
uint16 constant STEAL_FROM_BANK = THIEVING_BASE + 13;
uint16 constant PICKPOCKET_MASTER_THIEF = THIEVING_BASE + 14;
uint16 constant THIEVING_MAX = THIEVING_BASE + 255;

// Misc
uint16 constant MISC_BASE = 32768;
uint16 constant NATUOW_HIDE = MISC_BASE;
uint16 constant NATUOW_LEATHER = MISC_BASE + 1;
uint16 constant SMALL_BONE = MISC_BASE + 2;
uint16 constant MEDIUM_BONE = MISC_BASE + 3;
uint16 constant LARGE_BONE = MISC_BASE + 4;
uint16 constant DRAGON_BONE = MISC_BASE + 5;
uint16 constant DRAGON_TEETH = MISC_BASE + 6;
uint16 constant DRAGON_SCALE = MISC_BASE + 7;
uint16 constant POISON = MISC_BASE + 8;
uint16 constant STRING = MISC_BASE + 9;
uint16 constant ROPE = MISC_BASE + 10;
uint16 constant LEAF_FRAGMENTS = MISC_BASE + 11;
uint16 constant VENOM_POUCH = MISC_BASE + 12;
uint16 constant BAT_WING = MISC_BASE + 13;
uint16 constant BAT_WING_PATCH = MISC_BASE + 14;
uint16 constant THREAD_NEEDLE = MISC_BASE + 15;
uint16 constant LOSSUTH_TEETH = MISC_BASE + 16;
uint16 constant LOSSUTH_SCALE = MISC_BASE + 17;
uint16 constant FEATHER = MISC_BASE + 18;
uint16 constant QUARTZ_INFUSED_FEATHER = MISC_BASE + 19;
uint16 constant BARK_CHUNK = MISC_BASE + 20;
uint16 constant APPRENTICE_FABRIC = MISC_BASE + 21;
uint16 constant MAGE_FABRIC = MISC_BASE + 22;
uint16 constant SORCERER_FABRIC = MISC_BASE + 23;
uint16 constant SEERS_FABRIC = MISC_BASE + 24;
uint16 constant SHAMAN_FABRIC = MISC_BASE + 25;
uint16 constant MASTER_FABRIC = MISC_BASE + 26;
uint16 constant DRAGON_KEY = MISC_BASE + 27;
uint16 constant BONE_KEY = MISC_BASE + 28;
uint16 constant NATURE_KEY = MISC_BASE + 29;
uint16 constant AQUA_KEY = MISC_BASE + 30;
uint16 constant BLUECANAR = MISC_BASE + 31;
uint16 constant ANURGAT = MISC_BASE + 32;
uint16 constant RUFARUM = MISC_BASE + 33;
uint16 constant WHITE_DEATH_SPORE = MISC_BASE + 34;
uint16 constant BONES = MISC_BASE + 35;
uint16 constant MISC_MAX = MISC_BASE + (10 + 256) + 255;

// Other
uint16 constant MYSTERY_BOX = 65535;
uint16 constant RAID_PASS = MISC_BASE - 1;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";
import "./interfaces/IBrushToken.sol";
import "./interfaces/IPlayers.sol";
import "./World.sol";
import "./types.sol";
import "./items.sol";

// The NFT contract contains data related to the items and who owns them
contract ItemNFT is ERC1155Upgradeable, Multicall, UUPSUpgradeable, OwnableUpgradeable {
  event AddItem(Item item, uint16 tokenId);
  event AddItems(Item[] items, uint16[] tokenIds);
  event EditItem(Item item, uint16 tokenId);

  // Input only
  struct NonCombatStat {
    Skill skill;
    int16 diff;
  }
  // Contains everything you need to create an item
  struct InputItem {
    CombatStats combatStats;
    NonCombatStat[] nonCombatStats;
    uint16 tokenId;
    EquipPosition equipPosition;
    // Food
    uint16 healthRestored;
    // Boost
    BoostType boostType;
    uint16 boostValue; // Varies, could be the % increase
    uint24 boostDuration; // How long the effect of the boost vial last
    // uri
    string metadataURI;
  }

  World world;
  string private baseURI;

  // How many of this item exist
  mapping(uint => uint) public itemBalances;

  address players;
  address shop;

  uint public uniqueItems; // unique number of items

  mapping(uint => string) private tokenURIs;
  mapping(uint => CombatStats) combatStats;
  mapping(uint => Item) items;

  modifier onlyPlayersOrShop() {
    require(msg.sender == players || msg.sender == shop, "Not players OR shop");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(World _world, address _shop) public initializer {
    __ERC1155_init("");
    __Ownable_init();
    __UUPSUpgradeable_init();
    world = _world;
    shop = _shop;
    baseURI = "ipfs://";
  }

  function _mintItem(address _to, uint _tokenId, uint256 _amount) internal {
    require(_tokenId < type(uint16).max, "id too high");
    //    require(_exists(_tokenId));
    uint existingBalance = itemBalances[_tokenId];
    if (existingBalance == 0) {
      ++uniqueItems;
    }

    itemBalances[_tokenId] = existingBalance + _amount;
    _mint(_to, uint(_tokenId), _amount, "");
  }

  function _mintBatchItems(address _to, uint[] calldata _tokenIds, uint[] calldata _amounts) internal {
    uint numNewItems;
    for (uint i = 0; i < _tokenIds.length; ++i) {
      uint tokenId = _tokenIds[i];
      require(tokenId < type(uint16).max, "id too high");
      //      require(_exists(_tokenIds[i]));
      uint existingBalance = itemBalances[tokenId];
      if (existingBalance == 0) {
        // Brand new item
        ++numNewItems;
      }

      itemBalances[tokenId] = existingBalance + _amounts[i];
    }
    if (numNewItems > 0) {
      uniqueItems += numNewItems;
    }
    _mintBatch(_to, _tokenIds, _amounts, "");
  }

  function mint(address _to, uint _tokenId, uint256 _amount) external onlyPlayersOrShop {
    _mintItem(_to, _tokenId, _amount);
  }

  // Can't use Item[] array unfortunately so they don't support array casts
  function mintBatch(address _to, uint[] calldata _ids, uint256[] calldata _amounts) external onlyPlayersOrShop {
    _mintBatchItems(_to, _ids, _amounts);
  }

  function uri(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token does not exist");
    return string(abi.encodePacked(baseURI, tokenURIs[_tokenId]));
  }

  function _exists(uint _tokenId) private view returns (bool) {
    return bytes(tokenURIs[_tokenId]).length != 0;
  }

  function getItem(uint16 _tokenId) external view returns (Item memory) {
    require(items[_tokenId].exists, "Item doesn't exist");
    return items[_tokenId];
  }

  // If an item is burnt, remove it from the total
  function _removeAnyBurntFromTotal(address _to, uint[] memory _ids, uint[] memory _amounts) internal {
    uint i = _ids.length;
    // Precondition is that ids/amounts has some elements
    if (_to == address(0)) {
      // burning
      do {
        unchecked {
          --i;
        }
        itemBalances[_ids[i]] -= _amounts[i];
      } while (i > 0);
    }
  }

  function _beforeTokenTransfer(
    address /*_operator*/,
    address _from,
    address _to,
    uint[] memory _ids,
    uint[] memory _amounts,
    bytes memory /*_data*/
  ) internal virtual override {
    if (_from == address(0) || _amounts.length == 0 || _from == _to) {
      // When minting, self sending or transferring then no further processing is required
      return;
    }

    _removeAnyBurntFromTotal(_to, _ids, _amounts);

    // TODO Add checkpoints so we know exactly what items a player has at a given time

    // Properly update the player inventory
    if (_to != address(0)) {
      IPlayers(players).itemBeforeTokenTransfer(_from, _ids, _amounts);
    }
  }

  function burn(address _from, uint _tokenId, uint _quantity) external {
    require(
      _from == _msgSender() || isApprovedForAll(_from, _msgSender()) || players == _msgSender() || shop == _msgSender(),
      "ERC1155: caller is not token owner, approved , players contract or shop contract"
    );
    _burn(_from, _tokenId, _quantity);
  }

  function _setItem(InputItem calldata _item) private returns (Item storage item) {
    bool hasCombat;
    CombatStats calldata _combatStats = _item.combatStats;
    assembly ("memory-safe") {
      hasCombat := not(iszero(_combatStats))
    }
    bool hasNonCombat = _item.nonCombatStats.length > 0;
    item = items[_item.tokenId];
    item.exists = true;
    item.hasCombatStats = hasCombat;
    item.hasNonCombatStats = hasNonCombat;
    item.equipPosition = _item.equipPosition;

    if (hasCombat) {
      // Combat stats
      item.attack = int8(_item.combatStats.attack);
      item.magic = int8(_item.combatStats.magic);
      item.range = int8(_item.combatStats.range);
      item.meleeDefence = int8(_item.combatStats.meleeDefence);
      item.magicDefence = int8(_item.combatStats.magicDefence);
      item.rangeDefence = int8(_item.combatStats.rangeDefence);
      item.health = int8(_item.combatStats.health);
    }
    if (hasNonCombat) {
      item.skill1 = _item.nonCombatStats[0].skill;
      item.skillDiff1 = _item.nonCombatStats[0].diff;
      // TODO: Add more later if necessary
    }

    if (_item.healthRestored > 0) {
      item.healthRestored = _item.healthRestored;
    }

    if (_item.boostType != BoostType.NONE) {
      item.boostType = _item.boostType;
      item.boostValue = _item.boostValue;
      item.boostDuration = _item.boostDuration;
    }
    tokenURIs[_item.tokenId] = _item.metadataURI;
  }

  // Or make it constants and redeploy the contracts
  function addItem(InputItem calldata _inputItem) external onlyOwner {
    require(!_exists(_inputItem.tokenId), "This item was already added");
    Item storage item = _setItem(_inputItem);
    emit AddItem(item, _inputItem.tokenId);
  }

  function addItems(InputItem[] calldata _inputItems) external onlyOwner {
    Item[] memory _items = new Item[](_inputItems.length);
    uint16[] memory tokenIds = new uint16[](_items.length);
    for (uint i; i < _inputItems.length; ++i) {
      require(!_exists(_inputItems[i].tokenId), "This item was already added");
      _items[i] = _setItem(_inputItems[i]);
      tokenIds[i] = _inputItems[i].tokenId;
    }
    emit AddItems(_items, tokenIds);
  }

  function editItem(InputItem calldata _inputItem) external onlyOwner {
    require(_exists(_inputItem.tokenId), "This item was not added yet");
    require(
      items[_inputItem.tokenId].equipPosition == _inputItem.equipPosition,
      "Equipment position should not change"
    );
    Item storage item = _setItem(_inputItem);
    emit EditItem(item, _inputItem.tokenId);
  }

  function setPlayers(address _players) external onlyOwner {
    players = _players;
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _setURI(_baseURI);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  modifier isHardhat() {
    require(block.chainid == 31337, "Only for hardhat");
    _;
  }

  modifier isNotHardhat() {
    require(block.chainid != 31337, "Not allowed hardhat");
    _;
  }

  // TODO: Remove in live version!! Just using it for live testing atm
  function testMint(address _to, uint _tokenId, uint _amount) external isNotHardhat {
    _mintItem(_to, _tokenId, _amount);
  }

  function testMints(address _to, uint[] calldata _tokenIds, uint[] calldata _amounts) external isNotHardhat {
    _mintBatchItems(_to, _tokenIds, _amounts);
  }

  // These are just to make tests easier to run by allowing arbitrary minting
  function testOnlyMint(address _to, uint _tokenId, uint _amount) external isHardhat {
    _mintItem(_to, _tokenId, _amount);
  }

  function testOnlyMints(address _to, uint[] calldata _tokenIds, uint[] calldata _amounts) external isHardhat {
    _mintBatchItems(_to, _tokenIds, _amounts);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IBrushToken.sol";
import "./interfaces/IPlayers.sol";
import "./types.sol";
import "./items.sol";

// Each NFT represents a player. This contract deals with the NFTs, and the Players contract deals with the player data
contract PlayerNFT is ERC1155Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
  event NewPlayer(uint playerId, uint avatarId, bytes20 name);
  event EditPlayer(uint playerId, bytes20 newName);

  event SetAvatar(uint avatarId, AvatarInfo avatarInfo);
  event SetAvatars(uint startAvatarId, AvatarInfo[] avatarInfos);

  struct AvatarInfo {
    bytes32 name;
    string description;
    string imageURI;
  }

  error NotOwner();
  error AvatarNotExists();

  uint public latestPlayerId;

  mapping(uint => AvatarInfo) public avatars;
  string public baseURI;
  mapping(uint => uint) public playerIdToAvatar; // playerId => avatar id
  mapping(uint => bytes32) public names;
  mapping(bytes => bool) public lowercaseNames; // name => exists

  IBrushToken public brush;
  IPlayers public players;
  address public pool;

  uint public editNameCost;

  modifier isOwnerOfPlayer(uint playerId) {
    if (balanceOf(msg.sender, playerId) != 1) {
      revert NotOwner();
    }
    _;
  }

  modifier onlyPlayers() {
    require(msg.sender == address(players), "Not players");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(IBrushToken _brush, address _pool, uint _editNameCost) public initializer {
    __ERC1155_init("");
    __Ownable_init();
    __UUPSUpgradeable_init();
    brush = _brush;
    latestPlayerId = 1;
    baseURI = "ipfs://";
    pool = _pool;
    editNameCost = _editNameCost;
  }

  function _mintStartingItems() private {
    // Give the player some starting items
    uint[] memory itemNFTs = new uint[](5);
    itemNFTs[0] = BRONZE_SWORD;
    itemNFTs[1] = BRONZE_AXE;
    itemNFTs[2] = FIRE_LIGHTER;
    itemNFTs[3] = SMALL_NET;
    itemNFTs[4] = BRONZE_PICKAXE;

    uint[] memory quantities = new uint[](5);
    quantities[0] = 1;
    quantities[1] = 1;
    quantities[2] = 1;
    quantities[3] = 1;
    quantities[4] = 1;
    players.mintBatch(msg.sender, itemNFTs, quantities);
  }

  function _setName(uint _playerId, bytes20 _name) private {
    require(uint160(_name) != 0, "Name cannot be empty");
    names[_playerId] = _name;
    bytes memory lowercaseName = _toLower(_name);
    require(!lowercaseNames[lowercaseName], "Name already exists");
    lowercaseNames[lowercaseName] = true;
  }

  // Costs nothing to mint, only gas
  function mint(uint _avatarId, bytes32 _name, bool _makeActive) external {
    address from = msg.sender;
    uint currentPlayerId = latestPlayerId;
    players.mintedPlayer(from, currentPlayerId, _makeActive);
    emit NewPlayer(currentPlayerId, _avatarId, bytes20(_name));
    _mint(from, currentPlayerId, 1, "");
    _setName(currentPlayerId, bytes20(_name));
    _mintStartingItems();
    _setTokenIdToAvatar(currentPlayerId, _avatarId);
    ++latestPlayerId;
  }

  function _setTokenIdToAvatar(uint _playerId, uint _avatarId) private {
    if (bytes(avatars[_avatarId].description).length == 0) {
      revert AvatarNotExists();
    }
    playerIdToAvatar[_playerId] = _avatarId;
  }

  function uri(uint256 _playerId) public view virtual override returns (string memory) {
    require(_exists(_playerId), "ERC1155Metadata: URI query for nonexistent token");
    AvatarInfo storage avatarInfo = avatars[playerIdToAvatar[_playerId]];
    string memory imageURI = string(abi.encodePacked(baseURI, avatarInfo.imageURI));
    return players.getURI(names[_playerId], avatarInfo.name, avatarInfo.description, imageURI);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    if (from == address(0) || amounts.length == 0 || from == to) {
      return;
    }
    uint i = 0;
    do {
      // Get player and consume any actions & unequip all items before transferring the whole player
      uint playerId = ids[i];
      players.clearEverythingBeforeTokenTransfer(from, playerId);
      unchecked {
        ++i;
      }
    } while (i < ids.length);
  }

  /**
   * @dev Returns whether `playerId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   */
  function _exists(uint256 _playerId) private view returns (bool) {
    return playerIdToAvatar[_playerId] != 0;
  }

  function editName(uint _playerId, bytes32 _newName) external isOwnerOfPlayer(_playerId) {
    uint brushCost = editNameCost;
    // Pay
    brush.transferFrom(msg.sender, address(this), brushCost);
    // Send half to the pool
    brush.transferFrom(msg.sender, pool, brushCost - (brushCost / 2));
    // Burn the other half
    brush.burn(brushCost / 2);

    // Delete old name
    bytes32 oldName = names[_playerId];
    delete names[_playerId];
    bytes memory oldLowercaseName = _toLower(oldName);
    delete lowercaseNames[oldLowercaseName];

    _setName(_playerId, bytes20(_newName));

    emit EditPlayer(_playerId, bytes20(_newName));
  }

  function setAvatar(uint _avatarId, AvatarInfo calldata _avatarInfo) external onlyOwner {
    avatars[_avatarId] = _avatarInfo;
    emit SetAvatar(_avatarId, _avatarInfo);
  }

  function setAvatars(uint _startAvatarId, AvatarInfo[] calldata _avatarInfos) external onlyOwner {
    for (uint i; i < _avatarInfos.length; ++i) {
      avatars[_startAvatarId + i] = _avatarInfos[i];
    }
    emit SetAvatars(_startAvatarId, _avatarInfos);
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _setURI(_baseURI);
  }

  function burn(address _from, uint _playerId) external {
    require(
      _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
      "ERC1155: caller is not token owner or approved"
    );
    _burn(_from, _playerId, 1);
  }

  function setPlayers(IPlayers _players) external onlyOwner {
    players = _players;
  }

  function setEditNameCost(uint _editNameCost) external onlyOwner {
    editNameCost = _editNameCost;
  }

  function _toLower(bytes32 _name) private pure returns (bytes memory) {
    bytes memory lowerName = bytes(abi.encodePacked(_name));
    for (uint i = 0; i < lowerName.length; i++) {
      if ((uint8(lowerName[i]) >= 65) && (uint8(lowerName[i]) <= 90)) {
        // So we add 32 to make it lowercase
        lowerName[i] = bytes1(uint8(lowerName[i]) + 32);
      }
    }
    return lowerName;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";
import "./types.sol";
import "./World.sol";
import "./ItemNFT.sol";
import "./Players.sol"; // Might not even be needed

// Show all the player stats, return metadata json
library PlayerLibrary {
  // Should match the event in Players
  event Reward(address _from, uint playerId, uint queueId, uint itemTokenId, uint amount);
  event Consume(address _from, uint playerId, uint queueId, uint itemTokenId, uint amount);

  function uri(
    bytes32 name,
    mapping(Skill => uint32) storage skillPoints,
    CombatStats calldata totalStats,
    bytes32 avatarName,
    string calldata avatarDescription,
    string calldata imageURI
  ) external view returns (string memory) {
    string memory attributes = string(
      abi.encodePacked(
        '{"trait_type":"Player name","value":"',
        name,
        '{"trait_type":"Attack","value":"',
        skillPoints[Skill.ATTACK],
        '"}, {"trait_type":"Defence","value":"',
        skillPoints[Skill.DEFENCE],
        '"}, {"trait_type":"Mining","value":"',
        skillPoints[Skill.MINING],
        '{"trait_type":"WoodCutting","value":"',
        skillPoints[Skill.WOODCUTTING],
        '"}, {"trait_type":"Fishing","value":"',
        skillPoints[Skill.FISHING],
        '{"trait_type":"Smithing","value":"',
        skillPoints[Skill.SMITHING],
        '"}, {"trait_type":"Thieving","value":"',
        skillPoints[Skill.THIEVING],
        '{"trait_type":"Crafting","value":"',
        skillPoints[Skill.CRAFTING],
        '"}, {"trait_type":"Cooking","value":"',
        skillPoints[Skill.COOKING],
        '{"trait_type":"FireMaking","value":"',
        skillPoints[Skill.FIREMAKING],
        '"}, {"trait_type":"Max health","value":"',
        totalStats.health,
        '"}'
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            avatarName,
            '", "description": "',
            avatarDescription,
            '", attributes":[',
            attributes,
            ', "image": "',
            imageURI,
            '"}'
          )
        )
      )
    );

    // Base64
    string memory output = string(abi.encodePacked("data:application/json;base64,", json));

    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    return output;
  }

  function updateCombatStats(
    address _from,
    CombatStats memory _stats,
    Attire memory _attire,
    ItemNFT _itemNFT,
    bool _add
  ) public view returns (CombatStats memory stats) {
    stats = _stats;
    // TODO: Balance of Batch would be better
    // TODO: Checkpoints for start time.
    if (_attire.helmet != NONE && _itemNFT.balanceOf(_from, _attire.helmet) > 0) {
      _updateCombatStats(stats, _itemNFT.getItem(_attire.helmet), _add);
    }
    if (_attire.amulet != NONE && _itemNFT.balanceOf(_from, _attire.amulet) > 0) {
      _updateCombatStats(stats, _itemNFT.getItem(_attire.amulet), _add);
    }
    if (_attire.armor != NONE && _itemNFT.balanceOf(_from, _attire.armor) > 0) {
      _updateCombatStats(stats, _itemNFT.getItem(_attire.armor), _add);
    }
    if (_attire.gauntlets != NONE && _itemNFT.balanceOf(_from, _attire.gauntlets) > 0) {
      _updateCombatStats(stats, _itemNFT.getItem(_attire.gauntlets), _add);
    }
    if (_attire.tassets != NONE && _itemNFT.balanceOf(_from, _attire.tassets) > 0) {
      _updateCombatStats(stats, _itemNFT.getItem(_attire.tassets), _add);
    }
    if (_attire.boots != NONE && _itemNFT.balanceOf(_from, _attire.boots) > 0) {
      _updateCombatStats(stats, _itemNFT.getItem(_attire.boots), _add);
    }
    // TODO: This isn't correct, should be hanlded in the calculations elsewhere with a better formula
    if (stats.attack <= 0) {
      stats.attack = 1;
    }
    if (stats.meleeDefence <= 0) {
      stats.meleeDefence = 1;
    }
    if (stats.magic <= 0) {
      stats.magic = 1;
    }
    if (stats.magicDefence <= 0) {
      stats.magicDefence = 1;
    }
    if (stats.range <= 0) {
      stats.range = 1;
    }
    if (stats.rangeDefence <= 0) {
      stats.rangeDefence = 1;
    }
    if (stats.health <= 0) {
      stats.health = 1;
    }
  }

  function _updateCombatStats(CombatStats memory _stats, Item memory _item, bool _add) private pure {
    if (_item.attack != 0) {
      _stats.attack += _add ? _item.attack : -_item.attack;
    }
    if (_item.magic != 0) {
      _stats.magic += _add ? _item.magic : -_item.magic;
    }
    if (_item.range != 0) {
      _stats.range += _add ? _item.range : -_item.range;
    }
    if (_item.meleeDefence != 0) {
      _stats.meleeDefence += _add ? _item.meleeDefence : -_item.meleeDefence;
    }
    if (_item.magicDefence != 0) {
      _stats.magicDefence += _add ? _item.magicDefence : -_item.magicDefence;
    }
    if (_item.rangeDefence != 0) {
      _stats.rangeDefence += _add ? _item.rangeDefence : -_item.rangeDefence;
    }
    if (_item.health != 0) {
      _stats.health += _add ? _item.health : -_item.health;
    }
  }

  function _addGuarenteedReward(
    uint[] memory _ids,
    uint[] memory _amounts,
    uint _elapsedTime,
    uint16 _rewardTokenId,
    uint24 _rewardRate,
    ActionRewards memory _actionRewards,
    uint oldLength
  ) private pure returns (uint length) {
    length = oldLength;
    uint numRewards = (_elapsedTime * _rewardRate) / (3600 * 100);
    if (numRewards > 0) {
      _ids[length] = _rewardTokenId;
      _amounts[length] = numRewards;
      ++length;
    }
  }

  function _addGuarenteedRewards(
    uint[] memory _ids,
    uint[] memory _amounts,
    uint _elapsedTime,
    ActionRewards memory _actionRewards
  ) private pure returns (uint length) {
    length = _addGuarenteedReward(
      _ids,
      _amounts,
      _elapsedTime,
      _actionRewards.guaranteedRewardTokenId1,
      _actionRewards.guaranteedRewardRate1,
      _actionRewards,
      length
    );
    length = _addGuarenteedReward(
      _ids,
      _amounts,
      _elapsedTime,
      _actionRewards.guaranteedRewardTokenId2,
      _actionRewards.guaranteedRewardRate3,
      _actionRewards,
      length
    );
    length = _addGuarenteedReward(
      _ids,
      _amounts,
      _elapsedTime,
      _actionRewards.guaranteedRewardTokenId3,
      _actionRewards.guaranteedRewardRate2,
      _actionRewards,
      length
    );
  }

  function _addRandomRewards(
    address _from,
    uint40 skillEndTime,
    uint elapsedTime,
    World world,
    uint[] memory _ids,
    uint[] memory _amounts,
    uint _oldLength,
    ActionRewards memory _actionRewards
  ) private view returns (uint length) {
    length = _oldLength;

    // Easier to make it an array, but TODO update later
    ActionReward[] memory _randomRewards = new ActionReward[](4);
    uint randomRewardLength;
    if (_actionRewards.randomRandomTokenId1 != 0) {
      _randomRewards[0] = ActionReward(_actionRewards.randomRandomTokenId1, _actionRewards.randomRewardChance1);
      ++randomRewardLength;
    }
    if (_actionRewards.randomRandomTokenId2 != 0) {
      _randomRewards[1] = ActionReward(_actionRewards.randomRandomTokenId2, _actionRewards.randomRewardChance2);
      ++randomRewardLength;
    }
    if (_actionRewards.randomRandomTokenId3 != 0) {
      _randomRewards[2] = ActionReward(_actionRewards.randomRandomTokenId3, _actionRewards.randomRewardChance3);
      ++randomRewardLength;
    }
    if (_actionRewards.randomReward4 != 0) {
      _randomRewards[3] = ActionReward(_actionRewards.randomReward4, _actionRewards.randomRewardChance4);
      ++randomRewardLength;
    }

    assembly ("memory-safe") {
      mstore(_randomRewards, randomRewardLength)
    }

    if (_randomRewards.length > 0) {
      bool hasSeed = world.hasSeed(skillEndTime);
      if (hasSeed) {
        uint seed = world.getSeed(skillEndTime);

        // Figure out how many chances they get (1 per hour spent)
        uint numTickets = elapsedTime / 3600;

        bytes32 randomComponent = bytes32(seed) ^ bytes20(_from);
        uint startLootLength = length;
        for (uint i; i < numTickets; ++i) {
          // Percentage out of 256
          uint8 rand = uint8(uint256(randomComponent >> (i * 8)));

          // Take each byte and check
          for (uint j; j < _randomRewards.length; ++j) {
            ActionReward memory potentialLoot = _randomRewards[j];
            if (rand < potentialLoot.rate) {
              // Get the lowest chance one

              // Compare with previous and append amounts if an entry already exists
              bool found;
              for (uint k = startLootLength; k < _ids.length; ++k) {
                if (potentialLoot.itemTokenId == _ids[k]) {
                  // exists
                  _amounts[k] += 1;
                  found = true;
                  break;
                }
              }

              if (!found) {
                // New item
                _ids[length] = potentialLoot.itemTokenId;
                _amounts[length] = 1;
                ++length;
              }
              break;
            }
          }
        }
      }
    }
  }

  function getRewards(
    address _from,
    uint40 _skillEndTime,
    uint _elapsedTime,
    World _world,
    ActionRewards memory _actionRewards
  ) public view returns (uint[] memory ids, uint[] memory amounts) {
    ids = new uint[](7);
    amounts = new uint[](7);

    uint length = _addGuarenteedRewards(ids, amounts, _elapsedTime, _actionRewards);
    length = _addRandomRewards(_from, _skillEndTime, _elapsedTime, _world, ids, amounts, length, _actionRewards);

    assembly ("memory-safe") {
      mstore(ids, length)
      mstore(amounts, length)
    }
  }

  function _processConsumable(
    address _from,
    uint _playerId,
    ItemNFT _itemNFT,
    uint16 _itemTokenId,
    uint16 _numProduced,
    uint16 _baseNum,
    uint64 _queueId
  ) private {
    if (_itemTokenId == 0) {
      return;
    }
    uint16 numBurn = _numProduced * _baseNum;
    // Balance should be checked beforehand
    emit Consume(_from, _playerId, _queueId, _itemTokenId, numBurn);
    _itemNFT.burn(_from, _itemTokenId, numBurn);
  }

  function processConsumablesView(
    address _from,
    uint _playerId,
    QueuedAction storage _queuedAction,
    uint _elapsedTime,
    World _world,
    ItemNFT _itemNFT,
    CombatStats memory _combatStats,
    ActionChoice memory _actionChoice
  )
    public
    view
    returns (
      Equipment[] memory consumedEquipment,
      ActionReward memory output,
      uint actualElapsedTime,
      uint xpElapsedTime,
      bool died
    )
  {
    // Fetch the requirements for it
    (bool isCombat, CombatStats memory enemyCombatStats) = _world.getCombatStats(_queuedAction.actionId);

    consumedEquipment = new Equipment[](4);
    uint consumedEquipmentLength;

    // Figure out how much food should be consumed.
    // This is based on the damage done from battling
    // TODO Should probably move this out?
    uint16 numConsumed;
    uint combatElapsedTime;
    if (isCombat) {
      (xpElapsedTime, combatElapsedTime, numConsumed) = getAdjustedElapsedTimes(
        _from,
        _itemNFT,
        _world,
        _elapsedTime,
        _actionChoice,
        _queuedAction,
        _combatStats,
        enemyCombatStats
      );

      uint16 foodConsumed;
      (foodConsumed, died) = _foodConsumedView(
        _from,
        _queuedAction,
        combatElapsedTime,
        _itemNFT,
        _combatStats,
        enemyCombatStats
      );

      if (_actionChoice.inputTokenId1 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(_queuedAction.regenerateId, foodConsumed);
        ++consumedEquipmentLength;
      }
    } else {
      actualElapsedTime = _elapsedTime;
    }

    if (numConsumed > 0) {
      if (_actionChoice.inputTokenId1 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(
          _actionChoice.inputTokenId1,
          numConsumed * _actionChoice.num1
        );
        ++consumedEquipmentLength;
      }
      if (_actionChoice.inputTokenId2 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(
          _actionChoice.inputTokenId2,
          numConsumed * _actionChoice.num2
        );
        ++consumedEquipmentLength;
      }
      if (_actionChoice.inputTokenId3 != NONE) {
        consumedEquipment[consumedEquipmentLength] = Equipment(
          _actionChoice.inputTokenId3,
          numConsumed * _actionChoice.num3
        );
        ++consumedEquipmentLength;
      }
    }

    if (_actionChoice.outputTokenId != 0) {
      output = ActionReward(_actionChoice.outputTokenId, numConsumed);
    }

    assembly ("memory-safe") {
      mstore(consumedEquipment, consumedEquipmentLength)
    }
  }

  function _foodConsumedView(
    address _from,
    QueuedAction storage queuedAction,
    uint _combatElapsedTime, // uint _battleTime,
    ItemNFT _itemNFT,
    CombatStats memory _combatStats,
    CombatStats memory _enemyCombatStats
  ) private view returns (uint16 foodConsumed, bool died) {
    int32 totalHealthLost = int32(
      (_enemyCombatStats.attack * _enemyCombatStats.attack * int32(int(_combatElapsedTime))) /
        (_combatStats.meleeDefence * 60)
    ) - _combatStats.health;
    totalHealthLost += int32(
      (_enemyCombatStats.magic * _enemyCombatStats.magic * int32(int(_combatElapsedTime))) /
        (_combatStats.magicDefence * 60)
    );

    Item memory item = _itemNFT.getItem(queuedAction.regenerateId);

    if (item.healthRestored == 0 || totalHealthLost <= 0) {
      // No food attached or didn't lose any health
      died = totalHealthLost > 0;
    } else {
      foodConsumed = uint16(
        uint32(totalHealthLost) / item.healthRestored + (uint32(totalHealthLost) % item.healthRestored == 0 ? 0 : 1)
      );
      uint balance = _itemNFT.balanceOf(_from, queuedAction.regenerateId);

      died = foodConsumed > balance;
      if (died) {
        foodConsumed = uint16(balance);
      }
    }
  }

  function _processFoodConsumed(
    address _from,
    uint _playerId,
    QueuedAction storage _queuedAction,
    uint _combatElapsedTime,
    ItemNFT _itemNFT,
    CombatStats calldata _combatStats,
    CombatStats memory _enemyCombatStats
  ) private returns (bool died) {
    uint16 foodConsumed;
    // Figure out how much food should be used
    (foodConsumed, died) = _foodConsumedView(
      _from,
      _queuedAction,
      _combatElapsedTime,
      _itemNFT,
      _combatStats,
      _enemyCombatStats
    );

    _processConsumable(
      _from,
      _playerId,
      _itemNFT,
      _queuedAction.regenerateId,
      foodConsumed,
      1,
      _queuedAction.attire.queueId
    );
  }

  function _getMaxRequiredRatio(
    address _from,
    ActionChoice memory _actionChoice,
    uint16 _numConsumed,
    ItemNFT _itemNFT
  ) private view returns (uint maxRequiredRatio) {
    maxRequiredRatio = _numConsumed;
    if (_numConsumed > 0) {
      if (_actionChoice.inputTokenId1 != 0) {
        maxRequiredRatio = _getMaxRequiredRatioPartial(
          _from,
          _actionChoice.inputTokenId1,
          _actionChoice.num1,
          _numConsumed,
          maxRequiredRatio,
          _itemNFT
        );
      }
      if (_actionChoice.inputTokenId2 != 0) {
        maxRequiredRatio = _getMaxRequiredRatioPartial(
          _from,
          _actionChoice.inputTokenId2,
          _actionChoice.num2,
          _numConsumed,
          maxRequiredRatio,
          _itemNFT
        );
      }
      if (_actionChoice.inputTokenId3 != 0) {
        maxRequiredRatio = _getMaxRequiredRatioPartial(
          _from,
          _actionChoice.inputTokenId3,
          _actionChoice.num3,
          _numConsumed,
          maxRequiredRatio,
          _itemNFT
        );
      }
    }
  }

  function _getMaxRequiredRatioPartial(
    address _from,
    uint16 _inputTokenId,
    uint16 _num,
    uint16 _numConsumed,
    uint _maxRequiredRatio,
    ItemNFT _itemNFT
  ) private view returns (uint maxRequiredRatio) {
    uint balance = _itemNFT.balanceOf(_from, _inputTokenId);
    uint tempMaxRequiredRatio = _maxRequiredRatio;
    if (_numConsumed > balance / _num) {
      tempMaxRequiredRatio = balance / _num;
    }

    // Could be the first time
    if (tempMaxRequiredRatio < _maxRequiredRatio || _maxRequiredRatio == _numConsumed) {
      maxRequiredRatio = tempMaxRequiredRatio;
    }
  }

  function _processInputConsumables(
    address _from,
    uint _playerId,
    ActionChoice memory _actionChoice,
    uint16 _numConsumed,
    ItemNFT _itemNFT,
    uint64 _queueId
  ) private {
    _processConsumable(
      _from,
      _playerId,
      _itemNFT,
      _actionChoice.inputTokenId1,
      _numConsumed,
      _actionChoice.num1,
      _queueId
    );
    _processConsumable(
      _from,
      _playerId,
      _itemNFT,
      _actionChoice.inputTokenId2,
      _numConsumed,
      _actionChoice.num2,
      _queueId
    );
    _processConsumable(
      _from,
      _playerId,
      _itemNFT,
      _actionChoice.inputTokenId3,
      _numConsumed,
      _actionChoice.num3,
      _queueId
    );
  }

  function getAdjustedElapsedTimes(
    address _from,
    ItemNFT _itemNFT,
    World _world,
    uint _elapsedTime,
    ActionChoice memory _actionChoice,
    QueuedAction memory _queuedAction,
    CombatStats memory _combatStats,
    CombatStats memory _enemyCombatStats
  ) public view returns (uint xpElapsedTime, uint combatElapsedTime, uint16 numConsumed) {
    // Update these as necessary
    xpElapsedTime = _elapsedTime;
    combatElapsedTime = _elapsedTime;

    // Figure out how much food should be consumed.
    // This is based on the damage done from battling
    // TODO Should probably move this out?
    (bool isCombat, CombatStats memory enemyCombatStats) = _world.getCombatStats(_queuedAction.actionId);
    if (isCombat) {
      uint numSpawned = _world.getNumSpawn(_queuedAction.actionId); // Per hour
      uint maxHealthEnemy = numSpawned * uint16(enemyCombatStats.health);

      int32 totalHealthDealt;
      if (_actionChoice.skill == Skill.ATTACK) {
        totalHealthDealt =
          ((_combatStats.attack * _combatStats.attack * int32(int(_elapsedTime))) /
            _enemyCombatStats.meleeDefence +
            40) *
          60;
      } else if (_actionChoice.skill == Skill.MAGIC) {
        _combatStats.magic += int16(int32(_actionChoice.diff)); // Extra magic damage

        totalHealthDealt =
          ((_combatStats.magic * _combatStats.magic * int32(int(_elapsedTime))) / _enemyCombatStats.magicDefence) *
          60;
      } else if (_actionChoice.skill == Skill.RANGED) {
        // Add later
        //        totalHealthDealt = (_combatStats.range * _combatStats.range * int32(int(_elapsedTime))) /
        //        _enemyCombatStats.rangeDefence;
      }

      // Work out the ratio of health dealt to the max health they have
      if (uint32(totalHealthDealt) > maxHealthEnemy) {
        // We killed them all, but figure out how long it took
        combatElapsedTime = (_elapsedTime * uint32(totalHealthDealt)) / maxHealthEnemy; // Use this to work out how much food, arrows & spells to consume
        if (combatElapsedTime > _elapsedTime) {
          combatElapsedTime = _elapsedTime;
        }
      } else if (uint32(totalHealthDealt) < maxHealthEnemy) {
        // We didn't kill them all so they don't get the full rewards/xp
        // This correct?
        xpElapsedTime = (_elapsedTime * uint32(totalHealthDealt)) / maxHealthEnemy;
      }

      // Check the max that can be used
      numConsumed = uint16((combatElapsedTime * _actionChoice.rate) / (3600 * 100));
      if (numConsumed != 0) {
        // This checks the balances
        uint maxRequiredRatio = _getMaxRequiredRatio(_from, _actionChoice, numConsumed, _itemNFT);

        if (numConsumed > maxRequiredRatio) {
          numConsumed = uint16(maxRequiredRatio);

          // Work out what the actual elapsedTime should really be because they didn't have enough equipped to gain all the XP
          xpElapsedTime = (combatElapsedTime * maxRequiredRatio) / numConsumed;
        }
      }
    } else {
      // Non-combat, check the max that can be used
      numConsumed = uint16((_elapsedTime * _actionChoice.rate) / (3600 * 100));
      // This checks the balances
      uint maxRequiredRatio = _getMaxRequiredRatio(_from, _actionChoice, numConsumed, _itemNFT);
      if (numConsumed > maxRequiredRatio) {
        numConsumed = uint16(maxRequiredRatio);

        // Work out what the actual elapsedTime should really be because they didn't have enough equipped to gain all the XP
        xpElapsedTime = (combatElapsedTime * maxRequiredRatio) / numConsumed;
      }
    }
  }

  function processConsumables(
    address _from,
    uint _playerId,
    QueuedAction storage _queuedAction,
    uint _elapsedTime,
    World _world,
    ItemNFT _itemNFT,
    CombatStats calldata _combatStats,
    ActionChoice memory _actionChoice
  ) external returns (uint xpElapsedTime, uint combatElapsedTime, bool died) {
    // This is based on the damage done from battling
    (bool isCombat, CombatStats memory enemyCombatStats) = _world.getCombatStats(_queuedAction.actionId);
    uint16 numConsumed;
    (xpElapsedTime, combatElapsedTime, numConsumed) = getAdjustedElapsedTimes(
      _from,
      _itemNFT,
      _world,
      _elapsedTime,
      _actionChoice,
      _queuedAction,
      _combatStats,
      enemyCombatStats
    );
    if (isCombat) {
      (died) = _processFoodConsumed(
        _from,
        _playerId,
        _queuedAction,
        combatElapsedTime,
        _itemNFT,
        _combatStats,
        enemyCombatStats
      );
    }

    if (numConsumed > 0) {
      _processInputConsumables(_from, _playerId, _actionChoice, numConsumed, _itemNFT, _queuedAction.attire.queueId);
    }

    if (_actionChoice.outputTokenId != 0) {
      _itemNFT.mint(_from, _actionChoice.outputTokenId, numConsumed);
      emit Reward(_from, _playerId, _queuedAction.attire.queueId, _actionChoice.outputTokenId, numConsumed);
    }
  }

  function getElapsedTime(
    uint _skillEndTime,
    QueuedAction storage _queuedAction,
    uint _speedMultiplier
  ) public view returns (uint elapsedTime) {
    bool consumeAll = _skillEndTime <= block.timestamp;

    if (consumeAll) {
      // Fully consume this skill
      elapsedTime = _queuedAction.timespan;
    } else if (block.timestamp > _queuedAction.startTime) {
      // partially consume
      elapsedTime = block.timestamp - _queuedAction.startTime;
      uint modifiedElapsedTime = _speedMultiplier > 1 ? uint(elapsedTime) * _speedMultiplier : elapsedTime;
      // Up to timespan
      if (modifiedElapsedTime > _queuedAction.timespan) {
        elapsedTime = _queuedAction.timespan;
      }
    }
  }

  function _isCombat(Skill _skill) private pure returns (bool) {
    return _skill == Skill.ATTACK || _skill == Skill.DEFENCE || _skill == Skill.MAGIC || _skill == Skill.RANGED;
  }

  function extraXPFromBoost(
    bool _isCombatSkill,
    uint _actionStartTime,
    uint _elapsedTime,
    uint16 _xpPerHour,
    PlayerBoostInfo storage activeBoost
  ) public view returns (uint32 boostPointsAccrued) {
    if (activeBoost.itemTokenId != NONE && activeBoost.startTime < block.timestamp) {
      // A boost is active
      if (
        (_isCombatSkill && activeBoost.boostType == BoostType.COMBAT_XP) ||
        (!_isCombatSkill && activeBoost.boostType == BoostType.NON_COMBAT_XP)
      ) {
        uint boostedTime;
        // Correct skill for the boost
        if (_actionStartTime + _elapsedTime < activeBoost.startTime + activeBoost.duration) {
          // Consume it all
          boostedTime = _elapsedTime;
        } else {
          boostedTime = activeBoost.duration;
        }
        boostPointsAccrued = uint32((boostedTime * _xpPerHour * activeBoost.val) / (3600 * 100));
      }
    }
  }

  function pending(
    uint _playerId,
    QueuedAction[] storage actionQueue,
    Player storage player,
    ItemNFT _itemNFT,
    World _world,
    uint _speedMultiplier,
    PlayerBoostInfo storage activeBoost
  ) external view returns (PendingOutput memory pendingOutput) {
    pendingOutput.consumed = new Equipment[](actionQueue.length * MAX_LOOT_PER_ACTION + 1);
    pendingOutput.produced = new ActionReward[](actionQueue.length * MAX_LOOT_PER_ACTION * 2);

    uint consumedLength;
    uint producedLength;
    address from = msg.sender;
    uint previousSkillPoints = player.totalSkillPoints;
    uint32 allpointsAccrued;
    for (uint i; i < actionQueue.length; ++i) {
      QueuedAction storage queuedAction = actionQueue[i];

      CombatStats memory combatStats = player.totalStats;

      // This will only ones that they have a balance for at this time. This will check balances
      updateCombatStats(from, combatStats, queuedAction.attire, _itemNFT, true);

      uint32 pointsAccrued;
      uint skillEndTime = queuedAction.startTime +
        (_speedMultiplier > 1 ? uint(queuedAction.timespan) / _speedMultiplier : queuedAction.timespan);

      uint elapsedTime = getElapsedTime(skillEndTime, queuedAction, _speedMultiplier);
      if (elapsedTime == 0) {
        break;
      }

      // Create some items if necessary (smithing ores to bars for instance)
      bool died;

      ActionChoice memory actionChoice;
      bool isCombat = _isCombat(queuedAction.skill);
      uint xpElapsedTime = elapsedTime;
      if (queuedAction.choiceId != 0) {
        // || isCombat) {
        actionChoice = _world.getActionChoice(isCombat ? 0 : queuedAction.actionId, queuedAction.choiceId);

        Equipment[] memory consumedEquipment;
        ActionReward memory output;

        (consumedEquipment, output, elapsedTime, xpElapsedTime, died) = processConsumablesView(
          from,
          _playerId,
          queuedAction,
          elapsedTime,
          _world,
          _itemNFT,
          combatStats,
          actionChoice
        );

        if (output.itemTokenId != NONE) {
          pendingOutput.produced[producedLength] = output;
          ++producedLength;
        }

        for (uint i; i < consumedEquipment.length; ++i) {
          pendingOutput.consumed[consumedLength] = consumedEquipment[i];
          ++consumedLength;
        }

        if (died) {
          pendingOutput.died = true;
        }
      }

      if (!died) {
        bool _isCombatSkill = _isCombat(queuedAction.skill);
        uint16 xpPerHour = _world.getXPPerHour(queuedAction.actionId, _isCombatSkill ? NONE : queuedAction.choiceId);
        pointsAccrued = uint32((xpElapsedTime * xpPerHour) / 3600);
        pointsAccrued += extraXPFromBoost(
          _isCombatSkill,
          queuedAction.startTime,
          xpElapsedTime,
          xpPerHour,
          activeBoost
        );
      }

      if (pointsAccrued > 0) {
        //        _updateSkillPoints(_playerId, queuedAction.skill, pointsAccrued);

        ActionRewards memory actionRewards = _world.getActionRewards(queuedAction.actionId);
        (uint[] memory newIds, uint[] memory newAmounts) = getRewards(
          from,
          uint40(queuedAction.startTime + elapsedTime),
          xpElapsedTime,
          _world,
          actionRewards
        );

        for (uint i; i < newIds.length; ++i) {
          pendingOutput.produced[producedLength] = ActionReward(uint16(newIds[i]), uint24(newAmounts[i]));
          ++producedLength;
        }

        // This loot might be needed for a future task so mint now rather than later
        // But this could be improved
        allpointsAccrued += pointsAccrued;
      }
    } // end of loop

    if (allpointsAccrued > 0) {
      // Check if they have levelled up
      //      _handleLevelUpRewards(from, _playerId, previousSkillPoints, previousSkillPoints + allpointsAccrued);
    }

    // TODO Will also need guaranteedRewards, find a way to re-factor all this stuff so it can be re-used in the actual queue consumption

    assembly ("memory-safe") {
      mstore(mload(pendingOutput), consumedLength)
      mstore(mload(add(pendingOutput, 32)), producedLength)
    }
  }

  function consumeBoost(
    uint16 _itemTokenId,
    ItemNFT itemNFT,
    uint40 _startTime,
    PlayerBoostInfo storage playerBoost
  ) external {
    Item memory item = itemNFT.getItem(_itemTokenId);
    require(item.boostType != BoostType.NONE); // , "Not a boost vial");
    require(_startTime < block.timestamp + 7 days); // , "Start time too far in the future");
    if (_startTime < block.timestamp) {
      _startTime = uint40(block.timestamp);
    }

    // Burn it
    address from = msg.sender;
    itemNFT.burn(from, _itemTokenId, 1);

    // If there's an active potion which hasn't been consumed yet, then we can mint it back
    if (playerBoost.itemTokenId != NONE) {
      itemNFT.mint(from, playerBoost.itemTokenId, 1);
    }

    playerBoost.startTime = _startTime;
    playerBoost.duration = item.boostDuration;
    playerBoost.val = item.boostValue;
    playerBoost.boostType = item.boostType;
    playerBoost.itemTokenId = _itemTokenId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2Upgradeable is Initializable {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private vrfCoordinator;

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  function __VRFConsumerBaseV2_init(address _vrfCoordinator) internal onlyInitializing {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPlayers {
  function clearEverythingBeforeTokenTransfer(address from, uint tokenId) external;

  function getURI(
    bytes32 name,
    bytes32 avatarName,
    string calldata avatarDescription,
    string calldata imageURI
  ) external view returns (string memory);

  function mintBatch(address to, uint[] calldata ids, uint256[] calldata amounts) external;

  function itemBeforeTokenTransfer(address from, uint[] calldata tokenIds, uint256[] calldata amounts) external;

  function mintedPlayer(address from, uint playerId, bool makeActive) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBrushToken is IERC20 {
  function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}