// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./ICattoKatsu.sol";
import "./IKatsuToken.sol";
import "./ICattoAttributes.sol";

contract CattoExpedition is Ownable, ERC721Holder, ReentrancyGuard {
    using Address for address;

    enum EncounterType {
        Nil,
        Companion,
        Foe
    }

    struct Encounterable {
        uint maxTokenId;
        address contractAddr;
        uint8 weight;
        bool isActive;
        bool exists;
        EncounterType encounterType;
        string collectionName;
    }

    struct Expedition {
        uint id;
        uint cattoId;
        uint endTimestamp;
        uint earnedExp;
        uint earnedKatsu;
        uint encounterableId;
        uint encounterableLvl;
        uint mercenaryId;
        uint mercenaryLvl;
        bool hiredMercenary;
        bool isActive;
        bool exists;
        address encounterableAddr;
        address mercenaryAddr;
    }

    event ExpeditionCreated(uint indexed id, uint indexed ctkTokenId, address encounterableAddr, uint encounterableId, EncounterType eType,
        uint earnedExp, uint earnedKatsu, uint encounterableLvl, uint endTimestamp);
    event ExpeditionEnded(uint indexed id, uint indexed ctkTokenId);
    event HiredMercenary(uint indexed id, uint indexed ctkTokenId, address mercenaryAddr, uint mercenaryId, uint mercenaryLvl);

    ICattoKatsu private _ctkContract;
    IKatsuToken private _katsuTokenContract;
    ICattoAttributes private _ctkAttributesContract;

    uint public _expeditionDurationSec = 21600;
    uint public _maxEncounterableLvl = 100;
    uint public _encounterableReward = 10 ether;
    uint private _randNonce = 0;
    bool public _pauseExpedition = false;

    address[] public _encounterableAddrs;

    mapping(address => Encounterable) public _encounterablesMap;
    mapping(address => mapping(uint => uint)) private _encounterableRewardMap;
    mapping(uint => Expedition[]) public _cattoExpeditionsMap;
    mapping(address => uint[]) private _ownerStakedCattos;
    mapping(uint => address) public _stakedCattoIdOwnerMap;

    constructor(address ctkAddr, address katsuTokenAddr, address ctkAttributesAddr) {
        _ctkContract = ICattoKatsu(ctkAddr);
        _katsuTokenContract = IKatsuToken(katsuTokenAddr);
        _ctkAttributesContract = ICattoAttributes(ctkAttributesAddr);
    }

    // ----- Encounterable Configs -----

    // @dev Sets encounterable
    function setEncounterable(string calldata name, address addr, uint8 weight, EncounterType eType, uint maxTokenId, bool isActive) external onlyOwner {
        if (!_encounterablesMap[addr].exists) {
            _encounterablesMap[addr] = Encounterable(maxTokenId, addr, weight, isActive, true, eType, name);
            _encounterableAddrs.push(addr);
        } else {
            _encounterablesMap[addr].collectionName = name;
            _encounterablesMap[addr].weight = weight;
            _encounterablesMap[addr].encounterType = eType;
            _encounterablesMap[addr].maxTokenId = maxTokenId;
            _encounterablesMap[addr].isActive = isActive;
        }
    }

    // ----- Expedition Configs-----

    // @dev Sets expedition duration
    function setExpeditionDuration(uint durationSec) external onlyOwner {
        _expeditionDurationSec = durationSec;
    }

    // @dev Sets max encounterable level
    function setMaxEncounterableLvl(uint lvl) external onlyOwner {
        _maxEncounterableLvl = lvl;
    }

    // @dev Sets encounterable reward
    function setEncounterableReward(uint amt) external onlyOwner {
        _encounterableReward = amt;
    }

    // @dev Sets expedition pause state
    function setExpeditionPauseState(bool pause) external onlyOwner {
        _pauseExpedition = pause;
    }

    // ----- Expedition -----

    // @dev Retrieves Catto's latest expedition
    function getLatestExpedition(uint ctkTokenId) public view returns (Expedition memory) {
        uint len = _cattoExpeditionsMap[ctkTokenId].length;
        if (len > 0) {
            return _cattoExpeditionsMap[ctkTokenId][len - 1];
        }
        return Expedition(
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            false,
            false,
            false,
            address(0),
            address(0)
        );
    }

    // @dev Retrieves paginated expeditions
    function listPaginatedExpeditions(uint ctkTokenId, uint from, uint to) public view returns (Expedition[] memory) {
        require(from <= to, "Start is greater than end");
        Expedition[] memory expeditions_ = _cattoExpeditionsMap[ctkTokenId];
        require(to < expeditions_.length, "Target end index overflow");

        Expedition[] memory selectedEntries_ = new Expedition[](to - from + 1);
        uint idx = 0;
        for (uint i = from; i <= to; i++) {
            selectedEntries_[idx] = expeditions_[i];
            idx++;
        }

        return selectedEntries_;
    }

    // @dev Returns Catto's latest n expeditions
    function listLatestExpeditions(uint ctkTokenId, uint count) external view returns (Expedition[] memory) {
        uint expeditionLen = _cattoExpeditionsMap[ctkTokenId].length;
        require(count > 0 && count <= expeditionLen, "Count out of bound");

        Expedition[] memory selectedEntries_ = new Expedition[](count);
        uint idx = 0;
        for (uint i = 1; i <= count; i++) {
            selectedEntries_[idx] = _cattoExpeditionsMap[ctkTokenId][expeditionLen - i];
            idx++;
        }

        return selectedEntries_;
    }

    // @dev Starts an expedition
    function startExpedition(uint ctkTokenId) external nonReentrant {
        require(!_msgSender().isContract(), "Contract caller not allowed");
        require(!_pauseExpedition, "Expedition is paused");

        // check if catto exists
        address ownerOfCatto_ = _ctkContract.ownerOf(ctkTokenId);
        require(ownerOfCatto_ == _msgSender(), "Requester does not own the Catto");

        // check approval state
        require(_ctkContract.isApprovedForAll(ownerOfCatto_, address(this)), "Expedition contract not approved");

        // check if current expedition has ended, and if expedition is still active
        Expedition memory currentExpedition_ = getLatestExpedition(ctkTokenId);
        if (currentExpedition_.exists) {
            require(currentExpedition_.endTimestamp <= block.timestamp, "Current expedition not yet ended");
            require(!currentExpedition_.isActive, "Current expedition still active");
        }

        // random and see if should encounter an encounterable
        uint rEncounter_ = _generateRandNum() % 2;
        if (rEncounter_ == 0) {
            _executeEncounterable(ctkTokenId, address(0));
            return;
        }

        // select a random encounterable
        address randomEncounterableAddr_ = _selectRandActiveEncounterable();
        _executeEncounterable(ctkTokenId, randomEncounterableAddr_);
    }

    // @dev Executes the encounter of the Catto
    function _executeEncounterable(uint ctkTokenId, address encounterableAddr) internal {
        // stake catto and add to ownership tracker
        _ctkContract.safeTransferFrom(_msgSender(), address(this), ctkTokenId);
        _ownerStakedCattos[_msgSender()].push(ctkTokenId);
        _stakedCattoIdOwnerMap[ctkTokenId] = _msgSender();

        // a non-eventful encounter
        if (encounterableAddr == address(0)) {
            _createExpedition(ctkTokenId, 1, 100 ether, 0, 0, encounterableAddr);
            return;
        }

        Encounterable memory encounterable_ = _encounterablesMap[encounterableAddr];

        // a non-eventful encounter
        if (encounterable_.encounterType == EncounterType.Nil) {
            _createExpedition(ctkTokenId, 1, 100 ether, 0, 0, encounterableAddr);
            return;
        }

        // get random encounterable ID
        uint encounterableId_ = _generateRandNum() % encounterable_.maxTokenId;

        // determine encounterable level
        uint encounterableLvl_ = encounterableId_ % _maxEncounterableLvl;

        // handle companion
        if (encounterable_.encounterType == EncounterType.Companion) {
            _createExpedition(ctkTokenId, 2, 200 ether, encounterableId_, encounterableLvl_, encounterableAddr);
        }

        // handle foe
        if (encounterable_.encounterType == EncounterType.Foe) {
            uint cattoLvl_ = _ctkAttributesContract.getCattoLevel(ctkTokenId);
            if (cattoLvl_ > encounterableLvl_) {
                _createExpedition(ctkTokenId, 5, 500 ether, encounterableId_, encounterableLvl_, encounterableAddr);
            } else {
                _createExpedition(ctkTokenId, 0, 10 ether, encounterableId_, encounterableLvl_, encounterableAddr);
            }
        }
    }

    // @dev Hires a mercenary if Catto level is too low to overcome foe
    function hireMercenary(uint ctkTokenId) external nonReentrant returns (Expedition memory) {
        require(!_msgSender().isContract(), "Contract caller not allowed");

        address ownerOfCatto_ = _stakedCattoIdOwnerMap[ctkTokenId];
        require(ownerOfCatto_ == _msgSender(), "Requester does not own the Catto");

        Expedition memory expedition_ = getLatestExpedition(ctkTokenId);

        require(expedition_.exists, "No expedition");
        require(expedition_.endTimestamp > block.timestamp, "Expedition already ended");
        require(expedition_.isActive, "Expedition already closed");
        require(!expedition_.hiredMercenary, "Already hired");

        uint cattoLvl_ = _ctkAttributesContract.getCattoLevel(ctkTokenId);
        require(expedition_.encounterableLvl >= cattoLvl_, "Catto level sufficient");

        // selects a random mercenary address
        address mercenaryAddr_ = _selectRandActiveEncounterable();
        if (mercenaryAddr_ == address(0)) {
            return expedition_;
        }

        Encounterable memory mercenary_ = _encounterablesMap[mercenaryAddr_];

        // get random mercenary ID
        uint mercenaryId_ = _generateRandNum() % mercenary_.maxTokenId;

        // determine mercenary levelmercenaryId_ % _maxEncounterableLvl
        uint mercenaryLvl_ = mercenaryId_ % _maxEncounterableLvl;

        uint idx_ = _cattoExpeditionsMap[ctkTokenId].length - 1;

        _cattoExpeditionsMap[ctkTokenId][idx_].mercenaryAddr = mercenaryAddr_;
        _cattoExpeditionsMap[ctkTokenId][idx_].mercenaryId = mercenaryId_;
        _cattoExpeditionsMap[ctkTokenId][idx_].mercenaryLvl = mercenaryLvl_;
        _cattoExpeditionsMap[ctkTokenId][idx_].hiredMercenary = true;

        if (mercenaryLvl_ + cattoLvl_ < expedition_.encounterableLvl) {
            _cattoExpeditionsMap[ctkTokenId][idx_].earnedExp = 1;
            _cattoExpeditionsMap[ctkTokenId][idx_].earnedKatsu = 50 ether;
        } else {
            _cattoExpeditionsMap[ctkTokenId][idx_].earnedExp = 5;
            _cattoExpeditionsMap[ctkTokenId][idx_].earnedKatsu = 500 ether;
        }

        emit HiredMercenary(expedition_.id, expedition_.cattoId, mercenaryAddr_, mercenaryId_, mercenaryLvl_);

        return _cattoExpeditionsMap[ctkTokenId][idx_];
    }

    // @dev Ends Catto's current active expedition
    function endExpedition(uint ctkTokenId) external nonReentrant {
        require(!_msgSender().isContract(), "Contract caller not allowed");

        address ownerOfCatto_ = _stakedCattoIdOwnerMap[ctkTokenId];
        require(ownerOfCatto_ == _msgSender(), "Requester does not own the Catto");

        Expedition memory expedition_ = getLatestExpedition(ctkTokenId);

        require(expedition_.exists, "No expedition");
        require(expedition_.endTimestamp <= block.timestamp, "Expedition still in progress");
        require(expedition_.isActive, "Expedition already closed");

        _cattoExpeditionsMap[ctkTokenId][_cattoExpeditionsMap[ctkTokenId].length - 1].isActive = false;

        // unstake Catto and remove from tracker
        _ctkContract.safeTransferFrom(address(this), _msgSender(), ctkTokenId);
        _removeCattoFromStakedCattosArr(_msgSender(), ctkTokenId);
        delete _stakedCattoIdOwnerMap[ctkTokenId];

        // reward catto holder $katsu and exp
        _katsuTokenContract.ecosystemReward(ownerOfCatto_, expedition_.earnedKatsu);
        _ctkAttributesContract.gainExp(ctkTokenId, expedition_.earnedExp);

        // accumulate reward for encounterable owner
        if (expedition_.encounterableAddr != address(0)) {
            _katsuTokenContract.ecosystemReward(address(this), _encounterableReward);
            uint balance_ = _encounterableRewardMap[expedition_.encounterableAddr][expedition_.encounterableId];
            _encounterableRewardMap[expedition_.encounterableAddr][expedition_.encounterableId] = balance_ + _encounterableReward;
        }

        // accumulate reward for hired mercenary
        if (expedition_.hiredMercenary) {
            _katsuTokenContract.ecosystemReward(address(this), _encounterableReward);
            uint balance_ = _encounterableRewardMap[expedition_.mercenaryAddr][expedition_.mercenaryId];
            _encounterableRewardMap[expedition_.mercenaryAddr][expedition_.mercenaryId] = balance_ + _encounterableReward;
        }

        emit ExpeditionEnded(expedition_.id, expedition_.cattoId);
    }

    // @dev List owner's staked Cattos (in expeditions)
    function listOwnerStakedCattos(address owner) external view returns (uint[] memory) {
        return _ownerStakedCattos[owner];
    }

    // @dev Creates an expedition entry for a given Catto
    function _createExpedition(uint ctkTokenId, uint earnedExp, uint earnedKatsu, uint encounterableId, uint encounterableLvl, address encounterableAddr) internal returns (Expedition memory) {
        uint lenAsId = _cattoExpeditionsMap[ctkTokenId].length;
        uint endTimestamp = block.timestamp + _expeditionDurationSec;

        _cattoExpeditionsMap[ctkTokenId].push(
            Expedition(
                lenAsId,
                ctkTokenId,
                endTimestamp,
                earnedExp,
                earnedKatsu,
                encounterableId,
                encounterableLvl,
                0,
                0,
                false,
                true,
                true,
                encounterableAddr,
                address(0)
            )
        );

        emit ExpeditionCreated(lenAsId, ctkTokenId, encounterableAddr, encounterableId, _encounterablesMap[encounterableAddr].encounterType, earnedExp, earnedKatsu, encounterableLvl, endTimestamp);

        return _cattoExpeditionsMap[ctkTokenId][lenAsId];
    }

    // @dev Remove Catto from owner's staked Cattos array
    function _removeCattoFromStakedCattosArr(address owner, uint cattoId) internal {
        uint[] memory ownerStakedCattos_ = _ownerStakedCattos[owner];
        uint stakedCattoLen_ = ownerStakedCattos_.length;

        for (uint i = 0; i < stakedCattoLen_; i++) {
            if (ownerStakedCattos_[i] == cattoId) {
                _ownerStakedCattos[owner][i] = ownerStakedCattos_[stakedCattoLen_ - 1];
                _ownerStakedCattos[owner].pop();
                break;
            }
        }
    }

    // ----- Encounterable Reward Claim -----

    // @dev Allow encounterable token holders to claim rewards
    function encounterableRewardClaim(address addr, uint[] memory tokenIds) external nonReentrant {
        require(_encounterablesMap[addr].exists, "Does not exists");

        IERC721 tokenContract_ = IERC721(addr);
        uint claimAmt_ = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            require(tokenContract_.ownerOf(tokenIds[i]) == _msgSender());
            claimAmt_ += _encounterableRewardMap[addr][tokenIds[i]];
        }

        if (claimAmt_ > 0) {
            _katsuTokenContract.transfer(_msgSender(), claimAmt_);
        }
    }

    // ----- Utils -----

    // @dev Select random active encounterable
    function _selectRandActiveEncounterable() internal returns (address) {
        uint counter_ = 0;
        uint encounterableLen_ = _encounterableAddrs.length;
        address[] memory activeEncounterableAddrs_ = new address[](encounterableLen_);
        uint[] memory weights_ = new uint[](encounterableLen_);

        // get active encounterables as array
        for (uint i = 0; i < encounterableLen_; i++) {
            Encounterable memory e_ = _encounterablesMap[_encounterableAddrs[i]];
            if (e_.isActive) {
                activeEncounterableAddrs_[counter_] = e_.contractAddr;
                weights_[counter_] = e_.weight;
                counter_ += 1;
            }
        }

        // no encounter since no active encounterable
        if (activeEncounterableAddrs_.length == 0) {
            return address(0);
        }

        // select and return a random encounterable
        return activeEncounterableAddrs_[_weightedRandomIndex(weights_)];
    }

    // @dev Given an array of weights, returns the index of selected weight
    function _weightedRandomIndex(uint[] memory weights) internal returns (uint) {
        uint totalWeight_ = 0;
        for (uint i; i <weights.length; i++) {
            totalWeight_ += weights[i];
        }

        uint random_ = _generateRandNum() % totalWeight_;
        int256 startSeed_ = int256(random_);
        uint selected_;

        for (uint i; i < weights.length; i++) {
            startSeed_ = startSeed_ - int256(weights[i]);
            if (startSeed_ <= 0) {
                selected_ = i;
                break;
            }
        }

        return selected_;
    }

    function _generateRandNum() internal returns (uint) {
        uint random_ = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _msgSender(), _randNonce)));
        _randNonce++;
        return random_;
    }
}