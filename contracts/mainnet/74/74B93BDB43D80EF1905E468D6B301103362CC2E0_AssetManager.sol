// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Types/Asset.sol";
import "./CrimeCashGame.sol";
import "./Governable.sol";

contract AssetManager is Governable {

    CrimeCashGame private _crimeCashGame;

    /// @dev owner has added default asset in game
    bool public isDefaultAssetsAdded;

    mapping(uint8 => mapping(uint256 => Asset)) public Assets;

    event DeleteAssetFromGame(uint8 assetType, uint256 assetIndex);
    event AddAssetToGame(uint8 assetType, uint256 assetIndex, uint256 assetValue, uint256 assetCost, bool hasLimit);

    constructor(Storage storage_, address crimeCashGameAddress_) Governable(storage_) {
        require(
            crimeCashGameAddress_ != address(0),
            "crimeCashGameAddress shouldn't be empty"
        );
        _crimeCashGame = CrimeCashGame(crimeCashGameAddress_);
    }

    function setCrimeCashGame(CrimeCashGame crimeCashGame) external {
      onlyOwner();

      _crimeCashGame = crimeCashGame;
    }

    function addAssetToGame(uint8 _type, uint256 _index, uint256 _value, uint256 _cost, bool _hasLimit) external {
        onlyGovernance();
        require(_crimeCashGame.isRoundOpening() == false, "The season is started, add new asset is forbidden");

        if (_type != 0 && _index != 0) {
            Assets[_type][_index] = Asset({power: _value, cost: _cost, hasLimit: _hasLimit});
        } else {
            revert();
        } 

        emit AddAssetToGame(_type, _index, _value, _cost, _hasLimit);
    }

    function removeAssetFromGame(uint8 _type, uint256 _index) external {
        onlyGovernance();
        require(_crimeCashGame.isRoundOpening() == false, "The season is started, remove asset is forbidden");
        if (_type != 0 && _index != 0) {
            delete Assets[_type][_index];
        } else {
            revert();
        }

        emit DeleteAssetFromGame(_type, _index);
    }

    function addDefaultAssets(uint256 decimals) external {
        onlyOwner();
        require(!_crimeCashGame.isRoundOpening(), "The season is started, adding default assets is forbidden");
        require(!isDefaultAssetsAdded, "Default assets is added already");

        isDefaultAssetsAdded = true;

        uint256 precisionToken = 10 ** decimals;

        /// @dev Add default Attack Asset
        addAssetToMap(1, 1, 300, precisionToken * 500, true);
        addAssetToMap(1, 2, 660, precisionToken * 1000, true);
        addAssetToMap(1, 3, 1386, precisionToken * 2000, true);
        addAssetToMap(1, 4, 3049, precisionToken * 4000, true);
        addAssetToMap(1, 5, 6403, precisionToken * 8000, true);
        addAssetToMap(1, 6, 14087, precisionToken * 16000, true);
        addAssetToMap(1, 7, 29583, precisionToken * 32000, true);
        addAssetToMap(1, 8, 65083, precisionToken * 104000, true);
        addAssetToMap(1, 9, 136675, precisionToken * 328000, true);
        addAssetToMap(1, 10, 300685, precisionToken * 756000, true);
        addAssetToMap(1, 11, 661507, precisionToken * 1912000, true);
        addAssetToMap(1, 12, 1389165, precisionToken * 8024000, true);
        addAssetToMap(1, 13, 3056163, precisionToken * 22048000, true);
        addAssetToMap(1, 14, 6417942, precisionToken * 54096000, true);
        addAssetToMap(1, 15, 14119472, precisionToken * 108192000, false);

        /// @dev Add default Defense Asset
        addAssetToMap(2, 1, 250, precisionToken * 500, true);
        addAssetToMap(2, 2, 550, precisionToken * 1000, true);
        addAssetToMap(2, 3, 1155, precisionToken * 2000, true);
        addAssetToMap(2, 4, 2541, precisionToken * 4000, true);
        addAssetToMap(2, 5, 5336, precisionToken * 8000, true);
        addAssetToMap(2, 6, 11739, precisionToken * 16000, true);
        addAssetToMap(2, 7, 24653, precisionToken * 32000, true);
        addAssetToMap(2, 8, 54236, precisionToken * 104000, true);
        addAssetToMap(2, 9, 113896, precisionToken * 328000, true);
        addAssetToMap(2, 10, 250571, precisionToken * 756000, true);
        addAssetToMap(2, 11, 551256, precisionToken * 1912000, true);
        addAssetToMap(2, 12, 1157637, precisionToken * 8024000, true);
        addAssetToMap(2, 13, 2546802, precisionToken * 22048000, true);
        addAssetToMap(2, 14, 5348285, precisionToken * 54096000, true);
        addAssetToMap(2, 15, 11766227, precisionToken * 108192000, false);
        
        /// @dev Add default Boost Asset
        addAssetToMap(3, 1, 3, precisionToken * 1000, false);
        addAssetToMap(3, 2, 5, precisionToken * 10000, false);
        addAssetToMap(3, 3, 10, precisionToken * 120000, false);
        addAssetToMap(3, 4, 15, precisionToken * 900000, false);
        addAssetToMap(3, 5, 20, precisionToken * 3000000, false);
        addAssetToMap(3, 6, 25, precisionToken * 20000000, false);
        addAssetToMap(3, 7, 30, precisionToken * 50000000, false);
        addAssetToMap(3, 8, 50, precisionToken * 250000000, false);

        /// @dev Add default Protection Time Asset
        addAssetToMap(4, 1, 30, precisionToken * 1000, false);
        addAssetToMap(4, 2, 60, precisionToken * 10000, false);
        addAssetToMap(4, 3, 120, precisionToken * 500000, false);
        addAssetToMap(4, 4, 300, precisionToken * 10000000, false);
        addAssetToMap(4, 5, 600, precisionToken * 50000000, false);
        addAssetToMap(4, 6, 900, precisionToken * 100000000, false);
    }

    function addAssetToMap(uint8 _type, uint256 _index, uint256 _value, uint256 _cost, bool _hasLimit) private {
        Assets[_type][_index] = Asset({power: _value, cost: _cost, hasLimit: _hasLimit});
        emit AddAssetToGame(_type, _index, _value, _cost, _hasLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Asset {
    uint256 power;
    uint256 cost;
    bool hasLimit;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Governable.sol";
import "./CrimeGold.sol";
import "./CrimeGoldStaking.sol";
import "./CrimerInfo.sol";
import "./NFTAssetManager.sol";
import "./CrimeCashGamePools.sol";
import "./CrimeBankInteraction.sol";
import "./factories/CrimerInfoFactory.sol";
import "./NFT/CCashFortuneWheel.sol";
import "./CrimeLootBot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CrimeCashGame is Governable {
  using SafeERC20 for IERC20;
  using Address for address;

  uint16 public roundNumber;

  mapping(address => address) public crimerInfoStorageAddressByCrimeCashAddress;

  mapping(uint16 => bytes32) public leaderboardMerkleTreeRootByRoundNumber;
  mapping(uint16 => mapping(address => bool)) public crimerEarnedRewardByRoundNumber;

  CrimeGold private immutable _crimeGoldToken;

  Storage private _store;
  NFTAssetManager private _nftAssetManager;
  CrimeBankInteraction private _crimeBankInteraction;

  CrimerInfo public crimerInfo;
  CrimeLootBot public crimeLootBot;
  CrimeCashGamePools public _crimeCashGamePools;
  CCashFortuneWheel public _cCashFortuneWheel;
  CrimeGoldStaking public _crimeGoldStaking;
  CrimerInfoStorageFactory public crimerInfoStorageFactory;

  uint8 public roundDay;

  uint256 public roundStartTimestamp;

  bool    public isRoundOpening;
  bool    public isRoundFinished;

  uint256 public goldRewardForCrimer = 950 * 1e18;
  uint256 public goldRewardForDev = 30 * 1e18;
  uint256 public goldRewardForAdvertisement = 20 * 1e18;

  uint256[] public _topPowerMonthlyRewards = [
    200, 
    100, 
    75, 
    75, 
    75, 
    45, 
    45,
    45, 
    45, 
    30, 
    30, 
    30, 
    30, 
    30, 
    20, 
    20,
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20,
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20,
    20, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15
  ];

  function getTopPowerMonthlyRewards() external view returns(uint256[] memory) {
    return _topPowerMonthlyRewards;
  }

  uint256[] public _topPowerWeeklyRewards = [
    75, 
    50, 
    35, 
    35, 
    35, 
    25, 
    25,
    25, 
    15, 
    15, 
    15, 
    15, 
    15, 
    10, 
    10, 
    10,
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10
  ];

  function getTopPowerWeeklyRewards() external view returns(uint256[] memory) {
    return _topPowerWeeklyRewards;
  }

  uint256[] public _topCashMonthlyRewards = [
    100, 
    75, 
    50, 
    50, 
    50, 
    30, 
    30,
    30, 
    20, 
    20, 
    20, 
    20, 
    20, 
    20, 
    15, 
    15,
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15,
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15, 
    15,
    15, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10, 
    10
  ];

  function getTopCashMonthlyRewards() external view returns(uint256[] memory) {
    return _topCashMonthlyRewards;
  }

  uint256[] public _topCashWeeklyRewards = [
    30, 
    25, 
    20, 
    20, 
    20, 
    15, 
    15,
    10, 
    10, 
    10, 
    5, 
    5, 
    5, 
    5, 
    5, 
    5,
    5, 
    5, 
    5, 
    5, 
    5, 
    5, 
    5, 
    5, 
    5
  ];

  function getTopCashWeeklyRewards() external view returns(uint256[] memory) {
    return _topCashWeeklyRewards;
  }

  uint256[] public _topReferralsMonthlyRewards = [
    200, 
    150, 
    100, 
    50, 
    50, 
    50, 
    30,
    30, 
    30, 
    30, 
    30, 
    30, 
    30, 
    20, 
    20, 
    20, 
    20,
    20, 
    20, 
    20, 
    10, 
    10, 
    10, 
    10, 
    10
  ];

  function getTopReferralsMonthlyRewards() external view returns(uint256[] memory) {
    return _topReferralsMonthlyRewards;
  }

  uint256[] public _topCrimeOverallRewards = [
    200,
    150,
    150,
    100,
    100,
    100,
    50,
    50,
    50,
    50
  ];

  function getTopCrimeOverallRewards() external view returns(uint256[] memory) {
    return _topCrimeOverallRewards;
  }

  uint256[] public _topWeaponsOverallRewards = [
    125,
    100,
    75,
    50,
    25,
    15,
    15,
    15,
    15,
    15,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ];

  function getTopWeaponsOverallRewards() external view returns(uint256[] memory) {
    return _topWeaponsOverallRewards;
  }

  uint256[] public _topWeaponsMonthlyRewards = [
    125,
    100,
    75,
    50,
    25,
    15,
    15,
    15,
    15,
    15,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ];

  function getTopWeaponsMonthlyRewards() external view returns(uint256[] memory) {
    return _topWeaponsMonthlyRewards;
  }

  uint256[] public _topPerksOverallRewards = [
    125,
    100,
    75,
    50,
    25,
    15,
    15,
    15,
    15,
    15,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ];

  function getTopPerksOverallRewards() external view returns(uint256[] memory) {
    return _topPerksOverallRewards;
  }

  uint256[] public _topPerksMonthlyRewards = [
    125,
    100,
    75,
    50,
    25,
    15,
    15,
    15,
    15,
    15,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ];

  function getTopPerksMonthlyRewards() external view returns(uint256[] memory) {
    return _topPerksMonthlyRewards;
  }
  
  event eventFinishRound(uint16 roundNumber);
  event eventUpdateRoundDay(uint8 roundDay, uint16 seasonNumber);
  event eventGoldRewardClaimed(address crimer, uint256 amount);
  event eventStartRound(uint256 goldRewardForCrimer, uint8 roundDay, uint256 roundStartTimestamp, address newCrimerInfoStorage, address newCrimeCash, uint16 roundNumber);  

  constructor(CrimeGold crimeGoldToken, Storage store) Governable(store) {
    require(address(crimeGoldToken) != address(0), "Invalid CrimeGold address");
    _crimeGoldToken = crimeGoldToken;
  }

  function setCrimerInfoAddress(
    CrimerInfo _crimerInfo,
    CrimerInfoStorageFactory _crimerInfoStorageFactory,
    CrimeBankInteraction crimeBankInteraction,
    NFTAssetManager nftAssetManager,
    CrimeCashGamePools crimeCashGamePools,
    CCashFortuneWheel cCashFortuneWheel,
    CrimeGoldStaking crimeGoldStaking,
    address _crimeLootBot
  ) external {
    onlyGovernance();
    require(address(_crimerInfoStorageFactory) != address(0), "Invalid CrimerInfoStorageFactory address");
    require(address(_crimerInfo) != address(0), "Invalid CrimerInfo address");
    require(address(crimeBankInteraction) != address(0), "Invalid CrimeBankInteraction address");
    require(address(nftAssetManager) != address(0), "Invalid nftAssetManager address");
    require(address(crimeGoldStaking).isContract(), "Invalid crimeGoldStaking address");
    require(_crimeLootBot.isContract(), "Invalid CLB address");

    crimerInfoStorageFactory = _crimerInfoStorageFactory;
    crimerInfo = _crimerInfo;
    _crimeBankInteraction = crimeBankInteraction;
    _nftAssetManager = nftAssetManager;
    _crimeCashGamePools = crimeCashGamePools;
    _crimeCashGamePools.setCrimerInfo(_crimerInfo);
    _cCashFortuneWheel = cCashFortuneWheel;
    _crimeGoldStaking = crimeGoldStaking;
    crimeLootBot = CrimeLootBot(_crimeLootBot);
  }

  function setGoldRewardForCrimers(uint256 _goldAmount) external {
    onlyGovernance();
    require(isRoundOpening == false, "Error: There is an opened round currently");
    goldRewardForCrimer = _goldAmount;
  }
  
  /******************* pool-related functions start *******************/

  function crimerCanClaimRewardForSeason(
    address crimer,
    uint16 previousRoundNumber, 
    uint256 crimerReward, 
    bytes32[] calldata crimerdMerkleTreeProofs
  ) 
    public view 
    returns(bool) 
  {
    require(previousRoundNumber < roundNumber || (previousRoundNumber == roundNumber && isRoundFinished), "The previous round number is incorrect");
    return  !crimerEarnedRewardByRoundNumber[previousRoundNumber][crimer] &&
      MerkleProof.verify(
        crimerdMerkleTreeProofs,
        leaderboardMerkleTreeRootByRoundNumber[previousRoundNumber],
        keccak256(abi.encodePacked(crimer, crimerReward))
      );
  }

  function claimCGoldReward(uint16 previousRoundNumber, uint256 crimerReward, bytes32[] calldata crimerdMerkleTreeProofs) external { 
    require(
      crimerCanClaimRewardForSeason(msg.sender, previousRoundNumber, crimerReward, crimerdMerkleTreeProofs),
        "The Crimer Address is not a candidate for earn reward"
      );
    crimerEarnedRewardByRoundNumber[previousRoundNumber][msg.sender] = true;
    _crimeGoldToken.transfer(msg.sender, crimerReward * 10 ** 17);
    emit eventGoldRewardClaimed(msg.sender, crimerReward);
  }

  function finishRound(bytes32 winnersFromLeaderboardMerkleTreeRoot) external {
    onlyGovernaneOrController();
    require(isRoundOpening && roundDay == 30, "Error: The season hasn't start yet && current day not equal last(30)");
    require(winnersFromLeaderboardMerkleTreeRoot[0] != 0, "The leaderboard merkle tree root is empty");

    leaderboardMerkleTreeRootByRoundNumber[roundNumber] = winnersFromLeaderboardMerkleTreeRoot;

    roundDay = 0;
    isRoundOpening = false;
    isRoundFinished = true;
    roundStartTimestamp = 0;

    crimerInfo.updateGameState(roundDay, isRoundOpening, isRoundFinished, roundNumber);

    emit eventFinishRound(roundNumber);
  }
 
  //round-related functions
  function startRound(address newCrimeCash) external {
    onlyGovernance();
    require(!isRoundOpening, "Error: There is an opened round currently");
    require(
        address(crimerInfoStorageFactory) != address(0) && 
        address(crimerInfo) != address(0) &&
        address(_crimeBankInteraction) != address(0), 
        "CrimerInfo address is not set" 
    );
  
    roundNumber += 1;

    isRoundOpening = true;
    isRoundFinished = false;
    
    roundStartTimestamp = block.timestamp;
    roundDay = 1;

    address newCrimerInfoStorage = crimerInfoStorageFactory.createInstance(address(crimerInfo), address(_crimeBankInteraction),
    address(_nftAssetManager), address(_crimeGoldStaking), address(_crimeCashGamePools), address(_cCashFortuneWheel), address(crimeLootBot));
    
    _crimeBankInteraction.initializeIndispensableAddressesAndGameParameters(payable(newCrimeCash), newCrimerInfoStorage, roundNumber);
    crimerInfo.initializeIndispensableAddresses(newCrimerInfoStorage, payable(newCrimeCash), address(crimeLootBot));
    crimerInfo.updateGameState(roundDay, isRoundOpening, isRoundFinished, roundNumber);
    _nftAssetManager.initializeIndispensableAddresses(newCrimerInfoStorage, roundNumber);
    crimeLootBot.initializeIndispensableAddresses(address(crimerInfo), newCrimerInfoStorage, address(_crimeBankInteraction), payable(newCrimeCash));

    crimerInfoStorageAddressByCrimeCashAddress[newCrimeCash] = newCrimerInfoStorage;

    _crimeCashGamePools.onStartRound(newCrimeCash, roundNumber);

    _cCashFortuneWheel.setIndispensableAddresses(newCrimerInfoStorage, payable(newCrimeCash), address(_crimeCashGamePools));

    emit eventStartRound(goldRewardForCrimer, roundDay, roundStartTimestamp, newCrimerInfoStorage, newCrimeCash, roundNumber);
  }
  
  function updateRoundDay() external {
    onlyGovernaneOrController();
    require(roundDay >= 1 && roundDay < 30, "Error: Invalid round day");

    roundDay += 1;

    _crimeCashGamePools.onUpdateRound();

    crimerInfo.updateGameState(roundDay, isRoundOpening, isRoundFinished, roundNumber);
    
    emit eventUpdateRoundDay(roundDay, roundNumber);
  }

  modifier notOwner() {
    require(
      !store.governance(_msgSender()) && 
      !store.controller(_msgSender()), 
      "Error: owner/controller doesn't allow"
    );
    _;
  }

  modifier fromCrimerInfo() {
    require(_msgSender() == address(crimerInfo), "Error: Not allowed.");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Storage.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Governable is Context {

  Storage public store;

  constructor(Storage _store) {
    require(address(_store) != address(0), "new storage shouldn't be empty");
    store = _store;
  }

  function onlyOwner() internal view{
    require(store.owner() == _msgSender(), "Not the owner");
  }

  function onlyGovernance() internal view{
    require(store.governance(_msgSender()), "Not governance");
  }

  function onlyController() internal view{
    require(store.controller(_msgSender()), "Not controller");
  }

  function onlyGovernaneOrController() internal view{
    require(store.controller(_msgSender()) || store.governance(_msgSender()) , "Not a owner/controller");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Storage.sol";
import "./GovernableUpgradable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract CrimeGold is ERC20PresetMinterPauserUpgradeable, GovernableUpgradable {
  using AddressUpgradeable for address;

  mapping(address => bool) private _isExcludedFromBurn;

  address public pancakePair;
  uint256 public _burnRatePercent;
  uint256 public _timestampWhenCanMintForReward;
  uint256 constant public _mintForRewardFreezeTime = 0;

  mapping(address => bool) public _isIncludeAddressPairBurn;

  function initialize(Storage _storage) public initializer {
    ERC20PresetMinterPauserUpgradeable.initialize("CrimeGold", "CRIME");
    __Governable_init(_storage);
    
    _burnRatePercent = 25;

    _isExcludedFromBurn[_msgSender()] = true;

    _mint(msg.sender, 10000 * 10 ** 18);
    _pause();
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override(ERC20Upgradeable) whenNotPausedExceptGovernance returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
    return true;
  }

  function transfer(address recipient, uint256 amount) public virtual override(ERC20Upgradeable) whenNotPausedExceptGovernance returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal override {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    uint256 burnedAmount;

    if((pancakePair == recipient || _isIncludeAddressPairBurn[recipient]) && !_isExcludedFromBurn[sender]) { 
      burnedAmount = amount * _burnRatePercent / (10**2);
      _burn(sender, burnedAmount);
    }

    super._transfer(sender, recipient, amount - burnedAmount);
  }

  function setAddressPairBurn(address _address, bool _isInclude) external {
    onlyOwner();
    _isIncludeAddressPairBurn[_address] = _isInclude;
  }

  function mintForReward(
    address crimeCashGameAddress,
    uint256 amountOfTokensForCrimeCashGame, 
    address devAddress,
    uint256 amountOfTokensForDev, 
    address advertisementAddress,
    uint256 amountOfTokensForAdvertisement) external whenNotPaused {
    onlyOwner();
    _isContract(crimeCashGameAddress);
    _canMintForReward();

    _timestampWhenCanMintForReward = block.timestamp + _mintForRewardFreezeTime;
    
    _mint(crimeCashGameAddress, amountOfTokensForCrimeCashGame);
    _mint(devAddress, amountOfTokensForDev);
    _mint(advertisementAddress, amountOfTokensForAdvertisement);
  }

  function _isContract(address addr) internal view {
    require(addr.isContract(), "ERC20: crimeCashGameAddress is non contract address");
  }

  function _canMintForReward() internal view {
    require(block.timestamp >= _timestampWhenCanMintForReward, "ERC20: freeze time mintForReward()");
  }

  modifier whenNotPausedExceptGovernance() {
    if(!(msg.sender == store.owner() || store.governance(msg.sender)))
    require(!paused(), "Pausable: paused");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "./CrimeGold.sol";
import "./GovernableUpgradable.sol";

contract CrimeGoldStaking is GovernableUpgradable {
    uint256 private constant UINT256_MAX_VALUE = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    CrimeGold public _crimeGold;

    mapping (address => uint256) public _staked;
    mapping (address => uint256) public _lastStakeTimestamp;

    uint256 public _unstakeWithoutFeeCooldown;
    uint256 public _feePercentageForUnstakeWithFee;
    
    struct CrimeGoldStakingTier {
        uint256 shouldBeStaked;
        uint256 crimeCashFortuneWheelCooldown;
        uint256 assetsDiscountPercentage;
        uint256 farmBoost;
    }

    CrimeGoldStakingTier[] public _tiers;

    CrimeGoldStakingTier public _defaultTier;

    event Stake(address stakerAddress, uint256 amount);
    event UnstakeWithoutFee(address stakerAddress, uint256 amount);
    event UnstakeWithFee(address stakerAddress, uint256 burnedAmount, uint256 sendedAmount);
    event SetFeePercentageForUnstakeWithFee(uint256 feePercentage);
    event SetUnstakeWithoutFeeCooldown(uint256 cooldown);
    event SetTiers(CrimeGoldStakingTier[] tiers);

    function initialize(CrimeGold crimeGold, Storage store) public initializer {
        _crimeGold = crimeGold;

        __Governable_init(store);

        _unstakeWithoutFeeCooldown = 2 days;
        _feePercentageForUnstakeWithFee = 2;
        _defaultTier = CrimeGoldStakingTier({
            shouldBeStaked: 0,
            crimeCashFortuneWheelCooldown: UINT256_MAX_VALUE,
            assetsDiscountPercentage: 0,
            farmBoost: 0
        });
    }

    // Stake related functions -----------------------------------------------------------------------------------------------------------------

    function stake(uint256 amount) external {
        require(_crimeGold.allowance(msg.sender, address(this)) >= amount, "Amount is less than allowance");
        require(_crimeGold.balanceOf(msg.sender) >= amount, "Amount is less than CrimeGold balance");

        _crimeGold.transferFrom(msg.sender, address(this), amount);
        
        _staked[msg.sender] += amount;
        _lastStakeTimestamp[msg.sender] = block.timestamp;

        emit Stake(msg.sender, amount);
    }
    
    function unstakeWithoutFee(uint256 amount) external {
        require(canUnstakeWithoutFee(msg.sender), "Unstake without fee cooldown");
        require(_staked[msg.sender] >= amount, "Not enough staked tokens");

        _staked[msg.sender] -= amount;

        _crimeGold.transfer(msg.sender, amount);

        emit UnstakeWithoutFee(msg.sender, amount);
    }
    
    function unstakeWithFee(uint256 amount) external {
        require(!canUnstakeWithoutFee(msg.sender), "You can unstake without fee");
        require(_staked[msg.sender] >= amount, "Not enough staked tokens");

        _staked[msg.sender] -= amount;

        uint256 amountToBurn = amount * _feePercentageForUnstakeWithFee / 100;
        uint256 amountToSend = amount - amountToBurn;

        _crimeGold.burn(amountToBurn);
        _crimeGold.transfer(msg.sender, amountToSend);

        emit UnstakeWithFee(msg.sender, amountToBurn, amountToSend);
    }

    function canUnstakeWithoutFee(address stakerAddress) public view returns(bool) {
        return (block.timestamp >= _lastStakeTimestamp[stakerAddress] +  _unstakeWithoutFeeCooldown);
    }

    // Fee related functions -------------------------------------------------------------------------------------------------------------------

    function setFeePercentageForUnstakeWithFee(uint256 feePercentage) external {
        onlyOwner();
        require(feePercentage <= 100, "feePercentage should be less than or equal to 100");

        _feePercentageForUnstakeWithFee = feePercentage;

        emit SetFeePercentageForUnstakeWithFee(feePercentage); 
    }

    function setUnstakeWithoutFeeCooldown(uint256 cooldown) external {
        onlyOwner();

        _unstakeWithoutFeeCooldown = cooldown;

        emit SetUnstakeWithoutFeeCooldown(cooldown);
    }

    // Tier related functions ------------------------------------------------------------------------------------------------------------------

    function getTiers() external view returns(CrimeGoldStakingTier[] memory tiers) {
        return _tiers;
    }

    function setTiers(CrimeGoldStakingTier[] calldata tiers) external {
        onlyOwner();

        delete _tiers;

        CrimeGoldStakingTier memory flagTier = _defaultTier;

        for (uint256 i; i < tiers.length; i++) {
            require(tiers[i].shouldBeStaked >= flagTier.shouldBeStaked, "Tiers should be order(asc) by shouldBeStaked");
            require(tiers[i].crimeCashFortuneWheelCooldown <= flagTier.crimeCashFortuneWheelCooldown, "Tiers should be order(desc) by crimeCashFortuneWheelCooldown");
            require(tiers[i].assetsDiscountPercentage >= flagTier.assetsDiscountPercentage, "Tiers should be order(asc) by assetsDiscountPercentage");
            require(tiers[i].farmBoost >= flagTier.farmBoost, "Tiers should be order(asc) by farmBoost");
            require(tiers[i].assetsDiscountPercentage <= 100, "assetsDiscountPercentage should be less than or equal to 100");

            _tiers.push(tiers[i]);

            flagTier = tiers[i];
        }

        emit SetTiers(tiers);
    }

    function getStakerTier(address stakerAddress) external view returns(CrimeGoldStakingTier memory tier) {
        CrimeGoldStakingTier memory result = _defaultTier;

        for (uint256 i = 0; i < _tiers.length; i++) 
            if (_tiers[i].shouldBeStaked <= _staked[stakerAddress])
                result = _tiers[i];
            else 
                break;

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Governable.sol";
import "./CrimeCashGame.sol";
import "./CrimeCash.sol";
import "./libraries/CrimerLibrary.sol";
import "./Types/Crimer.sol";
import "./libraries/SafePercentageLibrary.sol";
import "./AssetManager.sol";
import "./NFTAssetManager.sol";
import "./CrimeGoldStaking.sol";
import "./CrimeLootBot.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract CrimerInfoStorage { 
  using SafePercentageLibrary for uint256;
  
  address public immutable crimerInfo;
  address public immutable crimeBankInteraction;
  address public immutable nftAssetManager;
  address public immutable crimeLootBot;
  CrimeGoldStaking public _crimeGoldStaking;
  address public _crimeCashGamePools;
  address public _cCashFortuneWheel;

  mapping(address=>Crimer) private crimers;
  mapping(uint8 => mapping(address=>mapping(address=>uint8))) private stolenCount;
  mapping(uint8=>mapping(address=>uint256)) private transactions;

  mapping(address => mapping(uint256 => bool)) isCrimerBoostExists;
  mapping(address => mapping(uint8 => bool)) private isCrimerBoughtProtectionAtRoundDay;

  /// @dev amount = starting Token + bonus referral Token + bounus referral click Token + gift code
  mapping(address => uint256) public lockedWithdrawToken;

  modifier onlyFromCrimerInfo {
    require(msg.sender == crimerInfo || msg.sender == crimeBankInteraction || msg.sender == nftAssetManager
      || msg.sender == _crimeCashGamePools || msg.sender == _cCashFortuneWheel || msg.sender == crimeLootBot, "Sender not a CrimerInfo");
    _;
  }

  constructor(
    address _crimerInfoAddress, 
    address _crimeBankInteraction, 
    address _nftAssetManager, 
    address crimeGoldStaking, 
    address crimeCashGamePools,
    address cCashFortuneWheel,
    address _crimeLootBot
  ) {
    crimerInfo = _crimerInfoAddress;
    crimeBankInteraction = _crimeBankInteraction;
    nftAssetManager = _nftAssetManager;
    _crimeGoldStaking = CrimeGoldStaking(crimeGoldStaking);
    _crimeCashGamePools = crimeCashGamePools;
    _cCashFortuneWheel = cCashFortuneWheel;
    crimeLootBot = _crimeLootBot;
  }

  /// Crimer
  /// @param _of crimer address
  /// @return _crimer is Crimer strcut
  function getCrimer(address _of) external view returns(Crimer memory _crimer) {
    _crimer = crimers[_of];
  }

  // CrimeGoldStaking related function -------------------------------------------------------------------------------------------------------

  // mb we can delete this function (depends on Sergej opinion)
  function getCrimerCrimeCashFortuneWheelCooldown(address crimerAddress) external view returns(uint256) {
    return _crimeGoldStaking.getStakerTier(crimerAddress).crimeCashFortuneWheelCooldown;
  }

  function getCrimerAssetsDiscountPercentage(address crimerAddress) external view returns(uint256) {
    return _crimeGoldStaking.getStakerTier(crimerAddress).assetsDiscountPercentage;
  }

  function getCrimerFarmBoost(address crimerAddress) external view returns(uint256) {
    return crimers[crimerAddress].boost + crimers[crimerAddress].nftPerkStakeBoost + _crimeGoldStaking.getStakerTier(crimerAddress).farmBoost;
  }

  // -----------------------------------------------------------------------------------------------------------------------------------------

  function updateLockedToken(address _of, uint256 amount) external onlyFromCrimerInfo {
    lockedWithdrawToken[_of] = amount;
  }

  /// Crimer
  /// @dev added specific id boost to crimer by address 
  function crimerPushBoost(address _of, uint256 _assetId) external onlyFromCrimerInfo {
    require(crimers[_of].exist, "Crimer is not exists");
    crimers[_of].boosts.push(_assetId);
  }

  /// Crimer
  /// @dev update crimer instance by address
  function setCrimer(address _of, Crimer memory _val) external onlyFromCrimerInfo {
    crimers[_of] = _val;
    crimers[_of].boosts = _val.boosts;
  }
  
  /// Crimer Stolen Count
  /// @param _defense the victim address
  /// @param _attack the attacker address
  /// @dev the amount allowed of stealing per day
  function getStolenCount(uint8 _roundDay, address _defense, address _attack) external view returns (uint8){ 
    return stolenCount[_roundDay][_defense][_attack];
  }

  function getStealCashCount(uint8 _roundDay, address[] calldata _crimers, address _crimer) external view  returns (uint256[] memory _stealCashLimits) { 
    _stealCashLimits = new uint256[](_crimers.length);
    for (uint i; i < _crimers.length; i++) 
      _stealCashLimits[i] = stolenCount[_roundDay][_crimers[i]][_crimer];
  }
  function incrementStolenCount(uint8 _roundDay, address _defense, address _attack) external onlyFromCrimerInfo { 
    stolenCount[_roundDay][_defense][_attack] = stolenCount[_roundDay][_defense][_attack] + 1;
  }

  /* crimer_addresses */  
  function getTransactions(uint8 _roundDay, address _of) external view returns (uint256){ 
    return transactions[_roundDay][_of];
  }

  function registerOneTransaction(uint256 _transactionsPerDay,uint8 _roundDay, address _sender) external onlyFromCrimerInfo {
    uint256 trans = transactions[_roundDay][_sender];
    require(trans < _transactionsPerDay, "you exceeded transactions amount");
    transactions[_roundDay][_sender] = trans + 1;
  }

  /* isCrimerBoostExists */
  function getIsCrimerBoostExists(address _crimer, uint256 _asset) external view returns (bool){ 
    return isCrimerBoostExists[_crimer][_asset];
  }
  function setIsCrimerBoostExists(address _crimer, uint256 _asset, bool _val) external onlyFromCrimerInfo { 
    isCrimerBoostExists[_crimer][_asset] = _val;
  }

  /* isCrimerBoughtProtectionAtRoundDay */
  function getIsCrimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay) external view returns (bool){ 
    return isCrimerBoughtProtectionAtRoundDay[_crimer][_roundDay];
  }
  function setIsCrimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay, bool _val) external onlyFromCrimerInfo { 
    isCrimerBoughtProtectionAtRoundDay[_crimer][_roundDay] = _val;
  }
}

contract CrimerInfo is Governable {
  using SafeMath for uint256;
  using Address for address;
  using CrimerLibrary for Crimer;

  CrimerInfoStorage public crimerInfoStorage;
  CrimeCashGame public immutable gameEngine;
  AssetManager public immutable assetManager;
  NFTAssetManager public immutable nftAssetManager;
  CrimeCash public crimecashToken;
  CrimeLootBot public crimeLootBot;
  address public _taxReceiverAddressFromSellingAssets;

  uint256 private constant _defaultReferralCashReward = 1000_00;
  uint256 private constant _defaultReferralAttackReward = 500;

  uint256 public referralCashReward;
  uint256 public referralAttackReward;
  uint256 public _maxPermitAmountAssetInTx = 10;

  uint8   private maxStolenCountLimit = 5;
  uint256 private minLimit = 10;
  uint256 private maxLimit = 50;
  uint256 private initBank = 500;
  uint256 private initCash = 500;
  uint256 private initAttack = 750;
  uint256 private initDefense = 500;
  uint256 private initProtectedUntil = 15;
  uint8   private startCashMintAtRoundDay = 3;
  uint8   private cashMintAmountPercentage = 10;
  
  // DailyBuyAssetLimit -----------------------------------------------------------------------------------------------------------------

  struct NextDailyBuyAssetLimitStatusInfo {
    uint16 startRoundNumber;
    uint8 startRoundDay;
    bool value;
  }

  struct NextDailyBuyAssetLimitInfo {
    uint16 startRoundNumber;
    uint8 startRoundDay;
    uint256 value;
  }

  struct PurchasedAssetsLastActivity {
    uint16 roundNumber;
    uint8 roundDay;
    uint256 count;
  }

  NextDailyBuyAssetLimitStatusInfo public _nextDailyBuyAssetLimitStatusInfo;
  NextDailyBuyAssetLimitInfo public _nextDailyBuyAssetLimitInfo;

  bool public _dailyBuyAssetLimitStatus = true; // true when limit is active, false - inactive
  uint256 public _dailyBuyAssetLimit = 10;

  mapping(address => mapping(uint8 => mapping(uint256 => PurchasedAssetsLastActivity))) private _purchasedAssetsLastActivity;

  event UpdateDailyBuyAssetLimitStatus(uint16 roundNumber, uint8 roundDay, bool status);
  event UpdateDailyBuyAssetLimit(uint16 roundNumber, uint8 roundDay, uint256 value);

  //-------------------------------------------------------------------------------------------------------------------------------------

  uint8 private roundDay; 
  uint16 private seasonNumber;
  bool private isRoundOpening;
  bool private isRoundFinished;
  
  event eventAddNewCrimer(address crimer, uint8 joinRoundDay, uint256 initBank, uint256 initCash, uint256 initAttack, uint256 initDefense, uint16 seasonNumber);
  event eventAddNewCrimerByReferral(address crimer, address byReferral, uint8 roundDay, uint256 initBank, uint256 initCash, uint256 initAttack, uint256 initDefense, uint256 referralBankBonus, uint256 referralAttackBonus, uint16 seasonNumber);
  event eventAddBonusByReferralClick(address referralCrimer, uint8 roundDay, uint256 referralBankBonus, uint256 referralAttackBonus, uint16 seasonNumber);
  event eventBuyAsset(address crimer, uint8 assetType, uint256 assetIndex, uint256 count, uint256 cost_amount, uint8 roundDay, uint16 seasonNumber);
  event eventStealCash(address crimer, address other, uint256 stolenCash, uint256 stolenRate, uint8 roundDay, uint16 seasonNumber);
  event getSecretBonus(address crimer, uint256 amount, uint8 roundDay, uint16 seasonNumber);

  constructor(
    CrimeCashGame _gameEngine,
    AssetManager _assetManager,
    NFTAssetManager _nftAssetManager,
    Storage _store
  ) Governable(_store) {
    require(address(_gameEngine) != address(0), "Invalid Game engine address");
    require(address(_assetManager) != address(0), "Invalid AssetManager address");

    gameEngine = _gameEngine;
    assetManager = _assetManager;
    nftAssetManager = _nftAssetManager;
    _taxReceiverAddressFromSellingAssets = _store.owner();
  }

  function initializeIndispensableAddresses(address _newStorageAddress, address payable _newCrimeCash, address _crimeLootBot) external {  
    onlyGameEngine();
    require(_newStorageAddress != address(0), "Invalid NewStorageAddress");
    require(_newCrimeCash != address(0), "Invalid NewCrimeCash");
    require(_crimeLootBot.isContract(), "Invalid crimeLootBot");

    crimerInfoStorage = CrimerInfoStorage(_newStorageAddress);
    crimecashToken = CrimeCash(_newCrimeCash);
    crimeLootBot = CrimeLootBot(_crimeLootBot);
  }

  function setMaxPermitAmountAssetInTx(uint256 maxPermitAmountAssetInTx) external {
    onlyGovernance();
    require(_maxPermitAmountAssetInTx != maxPermitAmountAssetInTx, "buy nmt max permit amount");
    _maxPermitAmountAssetInTx = maxPermitAmountAssetInTx;
  }

  function updateGameState(uint8 _roundDay, bool _isRoundOpening, bool _isRoundFinished, uint16 _seasonNumber) external {
    onlyGameEngine();
    roundDay = _roundDay;
    isRoundOpening = _isRoundOpening;
    isRoundFinished = _isRoundFinished;
    seasonNumber = _seasonNumber;

    _updateReferralRewards();
    _tryUpdateDailyBuyAssetLimitStatus();
    _tryUpdateDailyBuyAssetLimit();
  }

  function _updateReferralRewards() private {
    referralCashReward = _defaultReferralCashReward;
    referralAttackReward = _defaultReferralAttackReward;

    for (uint i = 2; i <= roundDay; i += 1) {
      referralCashReward = (referralCashReward * 3) / 2;            // + 50% everyday
      referralAttackReward = (referralAttackReward * 3) / 2;        // + 50% everyday
    }

    referralCashReward -= referralCashReward % 5;
    referralAttackReward -= referralAttackReward % 5;
  }

  function getGameSettings() external view returns (
      uint8 _maxStolenCountLimit,
      uint256 _minLimit,
      uint256 _maxLimit,
      uint256 _initBank,
      uint256 _initCash,
      uint256 _initAttack,
      uint256 _initDefense,
      uint256 _initProtectedUntil,
      uint8 _startCashMintAtRoundDay,
      uint8 _cashMintAmountPercentage
  ){
    return  (
      maxStolenCountLimit,
      minLimit,
      maxLimit,
      initBank,
      initCash,
      initAttack,
      initDefense,
      initProtectedUntil,
      startCashMintAtRoundDay,
      cashMintAmountPercentage
    );
  }

  function setGameSettings(uint256 _bank, uint256 _cash, uint256 _attack, uint256 _defense, uint256 _protectedUntil, uint256 _minLimit, uint256 _maxLimit, uint8 _maxStolenCountLimit, uint8 _startCashMintAtRoundDay, uint8 _cashMintAmountPercentage) external {
    onlyGovernance();
    require(_bank > 0 && _cash > 0 && _attack > 0 && _defense > 0 && _minLimit > 0 && _maxLimit > 0 && _maxStolenCountLimit > 0);

    initBank = _bank;
    initCash = _cash;
    initAttack = _attack;
    initDefense = _defense;
    initProtectedUntil = _protectedUntil;
    minLimit = _minLimit;
    maxLimit = _maxLimit;
    maxStolenCountLimit = _maxStolenCountLimit;
    startCashMintAtRoundDay = _startCashMintAtRoundDay;
    cashMintAmountPercentage = _cashMintAmountPercentage;
  }

  function addReferralTo(address _addTo) external {
    onlyGovernaneOrController();
    require(_addTo != _msgSender(), "Cannot add referral to controller");
    Crimer memory c = crimerInfoStorage.getCrimer(_addTo);
    require(c.exist, "Crimer doesn`t exist");
    c.bank = c.bank.add(referralCashReward);
    c.attack = c.attack.add(referralAttackReward);
    crimerInfoStorage.setCrimer(_addTo, c);

    addLockedTokenToCrimer(_addTo, referralCashReward);

    crimecashToken.mint(crimerInfoStorage.crimeBankInteraction(), referralCashReward);
    emit eventAddBonusByReferralClick(_addTo, roundDay, referralCashReward, referralAttackReward, seasonNumber);
  }

  function createNewCrimer() external {
    onlyCrimer();
    _createNewCrimer(_msgSender());
    emit eventAddNewCrimer(_msgSender(), roundDay, initBank.mul(10**2), initCash.mul(10**2), initAttack, initDefense, seasonNumber);
  }

  function createNewCrimerByReferral(address _byReferral) external {
    onlyCrimer();
    _createNewCrimerByReferral(_msgSender(), _byReferral);
  }

  function createNewCrimerByReferral(address _crimer, address _byReferral) external {
    onlyGovernaneOrController();
    require(_crimer != address(0), "Invalid crimer value");
    _createNewCrimerByReferral(_crimer, _byReferral);
  }

  function _createNewCrimerByReferral(address _crimer, address _byReferral) private {
    Crimer memory c = crimerInfoStorage.getCrimer(_byReferral);
    require(_crimer != _byReferral && c.exist, "nonexist crimer");

    _createNewCrimer(_crimer);
    
    c.referrals = c.referrals.add(1);
    c.bank = c.bank.add(referralCashReward);
    c.attack = c.attack.add(referralAttackReward);

    // if user achives 2 referrals - he get 25% farming boost
    if(c.referrals == 2) c.boost = c.boost.add(25);

    addLockedTokenToCrimer(_byReferral, referralCashReward);

    crimerInfoStorage.setCrimer(_byReferral, c);
    crimecashToken.mint(crimerInfoStorage.crimeBankInteraction(), referralCashReward);
    emit eventAddNewCrimerByReferral(_crimer, _byReferral, roundDay, initBank.mul(10**2), initCash.mul(10**2), initAttack, initDefense, referralCashReward, referralAttackReward, seasonNumber);
  }

  function _createNewCrimer(address crimerAddress) private {
    Crimer memory c = crimerInfoStorage.getCrimer(crimerAddress);
    require(!c.exist, "Crimer is already exists");

    Crimer memory _crimer = Crimer({
      exist: true,
      userAddress: crimerAddress, 
      bank: initBank.mul(10**2),
      cash: initCash.mul(10**2),
      attack: initAttack,
      defense : initDefense,
      boost: 0,
      referrals : 0,
      protectedUntil : block.timestamp + (initProtectedUntil * 1 minutes),
      boosts: new uint256[](0),
      nftPerkAttackBoost: 0, 
      nftPerkDefenseBoost: 0, 
      nftPerkPowerBoost: 0, 
      nftPerkStakeBoost: 0,
      index: 0
    });

    crimerInfoStorage.setCrimer(crimerAddress, _crimer);

    nftAssetManager.sendNFTToCrimerFromPreviousSeason(crimerAddress);

    uint256 initToken = initBank.add(initCash).mul(10**2);

    addLockedTokenToCrimer(crimerAddress, initToken);

    crimecashToken.mint(crimerInfoStorage.crimeBankInteraction(), initToken);
  }

  function setTaxReceiverAddressFromSellingAssetsAddress(address taxReceiverAddressFromSellingAssets) external {
    onlyOwner();
    _taxReceiverAddressFromSellingAssets = taxReceiverAddressFromSellingAssets;
  }

  function buyAsset(uint8 assetType, uint256 assetIndex, uint256 count) external {
    onlyCrimer();

    (uint256 assetPower, uint256 assetCost, bool assetHasBuyLimit) = assetManager.Assets(assetType, assetIndex);

    require (assetPower != 0 && assetCost != 0, "Asset doesn't exists");

    assetCost = _getAssetCostWithDiscountForCrimer(msg.sender, assetCost);

    Crimer memory crimer = crimerInfoStorage.getCrimer(msg.sender);

    require (crimer.exist, "Crimer doesn't exists");

    require (count <= _getMaxCountOfAssetThatAvailableToBuyForCrimer(msg.sender, assetType, assetIndex, assetCost, assetHasBuyLimit, crimer.cash), 
    "Count > MaxCountOfAssetThatAvailableToBuy");

    _addCountToPurchasedAssetsLastActivityForCrimer(msg.sender, assetType, assetIndex, count);

    uint256 totalCost = assetCost * count;
    uint256 totalPower = assetPower * count;

    if (assetType == 1) {
      crimer.attack += totalPower;
    }
    else if (assetType == 2) {
      crimer.defense += totalPower;
    }
    else if (assetType == 3) {
      require (!_isAlreadyHasBoost(msg.sender, assetIndex), "This boost already bought");

      crimer.boost += assetPower;
      
      crimerInfoStorage.setIsCrimerBoostExists(msg.sender, assetIndex, true);
      crimerInfoStorage.crimerPushBoost(msg.sender, assetIndex);
    }
    else if (assetType == 4) {
      require(!_crimerBoughtProtectionAtRoundDay(msg.sender, roundDay), "You already bougth protection this day");

      crimerInfoStorage.setIsCrimerBoughtProtectionAtRoundDay(msg.sender, roundDay, true);
      crimer.protectedUntil = block.timestamp + assetPower;
    }
    else 
      revert("Invalid asset type");

    crimer.cash -= totalCost;
    crimerInfoStorage.setCrimer(msg.sender, crimer);

    if (roundDay >= startCashMintAtRoundDay) {
      uint256 burnAmountToPool = totalCost * cashMintAmountPercentage / 100;      
      crimecashToken.mint(_taxReceiverAddressFromSellingAssets, burnAmountToPool);
    }

    uint256 lockedToken = crimerInfoStorage.lockedWithdrawToken(msg.sender);
    
    if (lockedToken <= totalCost) {
      crimerInfoStorage.updateLockedToken(msg.sender, 0);
    } 
    else {
      crimerInfoStorage.updateLockedToken(msg.sender, lockedToken - totalCost);
    }
    
    emit eventBuyAsset(msg.sender, assetType, assetIndex, count, totalCost, roundDay, seasonNumber);
  }

  function isAlreadyHasBoost(address _crimer, uint256 _boost) external view returns(bool) {
    return _isAlreadyHasBoost(_crimer, _boost);
  }

  function stealCash(address _crimer) external {
    onlyCrimer();
    uint8 currentRoundDay = roundDay;
    Crimer memory cStealOf = crimerInfoStorage.getCrimer(_crimer);
    Crimer memory cSender = crimerInfoStorage.getCrimer(_msgSender());

    require(cStealOf.protectedUntil <= block.timestamp, "Crimer protected now");
    require(crimerInfoStorage.getStolenCount(currentRoundDay, _crimer, _msgSender()) 
              < maxStolenCountLimit, "Hit max stolen for this player");

    require(cStealOf.cash >= 100, "Crimer's cash not enough to steal");
    require(cSender.totalAttack() > cStealOf.totalDefense(), 
            "Your attack is less than or equals crimer's defense");

    uint256 stolenRate = _random(_msgSender(), _crimer, maxLimit, minLimit, block.timestamp, block.difficulty, address(this));
    uint256 stolenCash = cStealOf.cash.mul(stolenRate).div(100);
    cStealOf.cash = cStealOf.cash.sub(stolenCash);
    crimerInfoStorage.incrementStolenCount(currentRoundDay, _crimer, _msgSender());
    cSender.cash = cSender.cash.add(stolenCash);

    crimerInfoStorage.setCrimer(_crimer, cStealOf);
    crimerInfoStorage.setCrimer(_msgSender(), cSender);

    uint256 lockedToken = crimerInfoStorage.lockedWithdrawToken(_crimer);
    if(lockedToken <= stolenCash) {
      crimerInfoStorage.updateLockedToken(_crimer, 0);
    } else {
      crimerInfoStorage.updateLockedToken(_crimer, lockedToken.sub(stolenCash));
    }

    emit eventStealCash(_msgSender(), _crimer, stolenCash, stolenRate, roundDay, seasonNumber);
  }

  function getBonustTokenFromOwner(address recipient, uint256 bonusAmount) external {
    onlyGovernaneOrController();
    require(recipient != msg.sender, "Cannot add bonus to controller");
    Crimer memory crimer = crimerInfoStorage.getCrimer(recipient);
    require(crimer.exist, "Crimer doesn`t exist");
    uint256 lockedToken = crimerInfoStorage.lockedWithdrawToken(recipient);
    uint256 amountWithPrecision = bonusAmount * 10 ** 2;
    crimerInfoStorage.updateLockedToken(recipient, lockedToken.add(amountWithPrecision));
    crimer.bank = crimer.bank.add(amountWithPrecision);
    crimerInfoStorage.setCrimer(recipient, crimer);

    crimecashToken.mint(crimerInfoStorage.crimeBankInteraction(), amountWithPrecision); 
    emit getSecretBonus(recipient, amountWithPrecision, roundDay, seasonNumber);
  }

  function crimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay) external view returns (bool){ 
    return _crimerBoughtProtectionAtRoundDay(_crimer, _roundDay);
  }

  function _crimerBoughtProtectionAtRoundDay(address _crimer, uint8 _roundDay) private view returns (bool){ 
    return crimerInfoStorage.getIsCrimerBoughtProtectionAtRoundDay(_crimer, _roundDay);
  }

  function _isAlreadyHasBoost(address _crimer, uint256 _boost) private view returns(bool) {
    return crimerInfoStorage.getIsCrimerBoostExists(_crimer, _boost);
  }

  function addLockedTokenToCrimer(address crimer, uint256 amount) private {
    uint256 lockedToken = crimerInfoStorage.lockedWithdrawToken(crimer);
    crimerInfoStorage.updateLockedToken(crimer, lockedToken.add(amount));   
  }

  // Buy asset related functions -----------------------------------------------------------------------------------------------

  function setNextDailyBuyAssetLimitStatus(uint16 startRoundNumber, uint8 startRoundDay, bool value) external {
    onlyOwner();

    require(startRoundNumber > seasonNumber || (startRoundNumber == seasonNumber && startRoundDay >= roundDay), 
      "Start roundNumber/roundDay should be greater than or equal to current roundNumber/roundDay");

    _nextDailyBuyAssetLimitStatusInfo = NextDailyBuyAssetLimitStatusInfo({
      startRoundNumber: startRoundNumber,
      startRoundDay: startRoundDay,
      value: value
    });

    _tryUpdateDailyBuyAssetLimitStatus();
  }

  function setNextDailyBuyAssetLimit(uint16 startRoundNumber, uint8 startRoundDay, uint256 value) external {
    onlyOwner();
    
    require(startRoundNumber > seasonNumber || (startRoundNumber == seasonNumber && startRoundDay >= roundDay), 
      "Start roundNumber/roundDay should be greater than or equal to current roundNumber/roundDay");

    _nextDailyBuyAssetLimitInfo = NextDailyBuyAssetLimitInfo({
      startRoundNumber: startRoundNumber,
      startRoundDay: startRoundDay,
      value: value
    });

    _tryUpdateDailyBuyAssetLimit();
  }

  function getMaxCountOfAssetThatAvailableToBuyForCrimer(address crimerAddress, uint8 assetType, uint256 assetIndex) public view returns(uint256) {
    (uint256 assetPower, uint256 assetCost, bool assetHasBuyLimit) = assetManager.Assets(assetType, assetIndex);

    require(assetPower != 0 && assetCost != 0, "The current Asset isn't exsist");

    Crimer memory crimer = crimerInfoStorage.getCrimer(crimerAddress);
    
    return _getMaxCountOfAssetThatAvailableToBuyForCrimer(
      crimerAddress, 
      assetType, 
      assetIndex, 
      _getAssetCostWithDiscountForCrimer(crimerAddress, assetCost), 
      assetHasBuyLimit, 
      crimer.cash);
  }

  function getAssetCostWithDiscountForCrimer(address crimerAddress, uint8 assetType, uint256 assetIndex) external view returns(uint256) {
    (uint256 assetPower, uint256 assetCost, bool assetHasBuyLimit) = assetManager.Assets(assetType, assetIndex);

    return _getAssetCostWithDiscountForCrimer(crimerAddress, assetCost);
  }

  function getCountOfPurchasedAssetsTodayForCrimer(address crimerAddress, uint8 assetType, uint256 assetIndex) public view returns(uint256) {
    uint256 result = 0;

    PurchasedAssetsLastActivity memory purchasedAssetsLastActivity = _purchasedAssetsLastActivity[crimerAddress][assetType][assetIndex];

    if (purchasedAssetsLastActivity.roundNumber == seasonNumber && purchasedAssetsLastActivity.roundDay == roundDay)
      result += purchasedAssetsLastActivity.count;
    
    return result;
  }

  function _tryUpdateDailyBuyAssetLimitStatus() private {
    if (seasonNumber != _nextDailyBuyAssetLimitStatusInfo.startRoundNumber || roundDay != _nextDailyBuyAssetLimitStatusInfo.startRoundDay) 
      return;
  
    _dailyBuyAssetLimitStatus = _nextDailyBuyAssetLimitStatusInfo.value;

    emit UpdateDailyBuyAssetLimitStatus(seasonNumber, roundDay, _dailyBuyAssetLimitStatus);
  }

  function _tryUpdateDailyBuyAssetLimit() private {
    if (seasonNumber != _nextDailyBuyAssetLimitInfo.startRoundNumber || roundDay != _nextDailyBuyAssetLimitInfo.startRoundDay) 
      return;

    _dailyBuyAssetLimit = _nextDailyBuyAssetLimitInfo.value;

    emit UpdateDailyBuyAssetLimit(seasonNumber, roundDay, _dailyBuyAssetLimit);
  }

  function _getMaxCountOfAssetThatAvailableToBuyForCrimer(address crimerAddress, uint8 assetType, uint256 assetIndex, uint256 assetCost, bool assetHasBuyLimit, uint256 crimerCash) private view returns (uint256) {
    uint256 result = crimerCash / assetCost;

    if (_dailyBuyAssetLimitStatus && assetHasBuyLimit) {
      uint256 countOfPurchasedAssetsToday = getCountOfPurchasedAssetsTodayForCrimer(crimerAddress, assetType, assetIndex);

      uint256 availableCountToBuy = 0;

      if (_dailyBuyAssetLimit > countOfPurchasedAssetsToday) 
        availableCountToBuy = _dailyBuyAssetLimit - countOfPurchasedAssetsToday;

      if (result > availableCountToBuy)
        result = availableCountToBuy;
    }

    if (assetHasBuyLimit && result > _maxPermitAmountAssetInTx) {
      result = _maxPermitAmountAssetInTx;
    }

    return result;
  }

  function _getAssetCostWithDiscountForCrimer(address crimerAddress, uint256 assetCost) private view returns(uint256) {
    uint256 assetsDiscountPercentage = crimerInfoStorage.getCrimerAssetsDiscountPercentage(crimerAddress);
    
    uint256 discount = assetCost * assetsDiscountPercentage / 100;
    
    return assetCost - discount;
  }

  function _addCountToPurchasedAssetsLastActivityForCrimer(address crimerAddress, uint8 assetType, uint256 assetIndex, uint256 count) private {
    PurchasedAssetsLastActivity memory purchasedAssetsLastActivity = _purchasedAssetsLastActivity[crimerAddress][assetType][assetIndex];

    if (purchasedAssetsLastActivity.roundNumber != seasonNumber || purchasedAssetsLastActivity.roundDay != roundDay) {
      _purchasedAssetsLastActivity[crimerAddress][assetType][assetIndex].roundNumber = seasonNumber;
      _purchasedAssetsLastActivity[crimerAddress][assetType][assetIndex].roundDay = roundDay;
      _purchasedAssetsLastActivity[crimerAddress][assetType][assetIndex].count = count;
    }
    else
      _purchasedAssetsLastActivity[crimerAddress][assetType][assetIndex].count += count;
  }

  //-------------------------------------------------------------------------------------------------------------------------------------

  function _random(address stealer, address crimer, uint256 maxStealLimit, uint256 minStealLimit, uint256 bnow, uint256 bdifficulty, address thisAddress) private pure returns(uint256) {
    return uint256(keccak256(abi.encodePacked(bnow, bdifficulty, stealer, crimer, thisAddress))).mod(maxStealLimit.sub(minStealLimit))+minStealLimit;
  }

  function roundOpened() private view {
    require(isRoundOpening == true, "not opened round");
  }

  function onlyCrimer() private view {
    require(
      !store.governance(_msgSender()) && 
      !store.controller(_msgSender()), 
      "owner/controller not allowed"
    );
    roundOpened();
  }
  function onlyGameEngine() private view {
    require(_msgSender() == address(gameEngine), "Sender is not a gameEngine");
  }

  function createNewBotCrimer(address botAddress) external {
    require(msg.sender == address(crimeLootBot), "S nq lootBot address");
    _createNewCrimer(botAddress);
    emit eventAddNewCrimer(botAddress, roundDay, initBank.mul(10**2), initCash.mul(10**2), initAttack, initDefense, seasonNumber);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./Types/CrimeNFT.sol";
// import "./NFT/CrimERC1155.sol";
import "./NFT/CrimeMarketplace.sol";
import "./NFT/ERC1155Receiver.sol";
import "./Governable.sol";
import "./CrimerInfo.sol";
import "./Types/NFTWeaponType.sol";
import "./Types/NFTPerkType.sol";
import "./Types/Crimer.sol";
import "./CrimeCashGame.sol";

contract NFTAssetManager is Governable, ERC1155Receiver {

    CrimerInfoStorage public _crimerInfoStorage;
    CrimeMarketplace public _crimeMarketplace;
    CrimeCashGame public _crimeCashGame;

    uint256 public constant maximumActiveNFTWeapons = 8;
    uint256 public constant maximumActiveNFTPerks = 5;

    uint16 public _seasonNumber;

    mapping(address => uint256[]) public currentlyActiveNFTWeapons;
    mapping(address => uint256[]) public currentlyActiveNFTPerks;

    event ApplyNFTInGame(address crimer, uint256[] nftWeaponIdList, uint256[] nftPerkIdList, uint16 seasonNumber);
    event SendNFTToCrimerFromPreviousSeason(address crimer, uint256[] nftWeaponIdList, uint256[] nftPerkIdList, uint16 seasonNumber);

    constructor(
        CrimeMarketplace crimeMarketplace, 
        Storage _store,
        CrimeCashGame crimeCashGame
    ) Governable(_store) {
        _crimeMarketplace = crimeMarketplace;
        _crimeCashGame = crimeCashGame;
    }

    function setAddresses(CrimeMarketplace crimeMarketplace, CrimeCashGame crimeCashGame) external {
      onlyOwner();

      _crimeMarketplace = crimeMarketplace;
      _crimeCashGame = crimeCashGame;
    }

    function initializeIndispensableAddresses(address _newStorageAddress, uint16 seasonNumber) external {  
        require(_msgSender() == address(_crimeCashGame), "Sender is not a gameEngine");
        _crimerInfoStorage = CrimerInfoStorage(_newStorageAddress);
        _seasonNumber = seasonNumber;
    }

    function getCurrentlyActiveNFTWeapons(address _of) external view returns (uint256[] memory) {
        return currentlyActiveNFTWeapons[_of];
    }

    function getCurrentlyActiveNFTPerks(address _of) external view returns (uint256[] memory) {
        return currentlyActiveNFTPerks[_of];
    }

    function setNfts(uint256[] calldata _nftWeaponIds, uint256[] calldata _nftPerkIds) external { 
        require(
            !store.governance(_msgSender()) && 
            !store.controller(_msgSender()), 
            "owner/controller not allowed"
        );
        _setNFTWeapons(_nftWeaponIds);
        _setNFTPerks(_nftPerkIds);
        emit ApplyNFTInGame(msg.sender, _nftWeaponIds, _nftPerkIds, _seasonNumber);
    }

    /// @dev if some nfts from the previous game are still in inventory - apply them
    function sendNFTToCrimerFromPreviousSeason(address crimer) external {
        require(msg.sender == address(_crimeCashGame.crimerInfo()));

        uint256[] memory nftWeaponIdList = currentlyActiveNFTWeapons[crimer];
        uint256[] memory nftPerkIdList = currentlyActiveNFTPerks[crimer];


        if(nftWeaponIdList.length != 0) {
            _transferNftFrom(address(this), crimer, nftWeaponIdList);
            delete currentlyActiveNFTWeapons[crimer];
        }

        if(nftPerkIdList.length != 0){
            _transferNftFrom(address(this), crimer, nftPerkIdList);
            delete currentlyActiveNFTPerks[crimer];
        }

        emit SendNFTToCrimerFromPreviousSeason(crimer, nftWeaponIdList, nftPerkIdList, _seasonNumber);
    }

    function _setNFTPerks(uint256[] calldata _nftIds) private { 
        require(_nftIds.length <= maximumActiveNFTPerks && _nftIds.length >= 0, "Exceeded NFT perks amount");

        _deactivateNFTPerksAndTransfer(_msgSender());

        if(_nftIds.length == 0) return;

        _transferNftFrom(_msgSender(), address(this), _nftIds);

        _applyPerksNFTBatch(_nftIds, _msgSender());
    }

    function _setNFTWeapons(uint256[] calldata _nftIds) private { 
        require(_nftIds.length <= maximumActiveNFTWeapons && _nftIds.length >= 0, "Exceeded NFT weapons amount");

        _deactivateNFTWeaponsAndTransfer(_msgSender());

        if(_nftIds.length == 0) return;

        _transferNftFrom(_msgSender(), address(this), _nftIds);

        _applyWeaponsNFTBatch(_nftIds, _msgSender());
    }

    function _transferNftFrom(address _from, address _to, uint256[] memory _ids) private { 
        _crimeMarketplace.nftItem().safeBatchTransferFrom(_from,_to, _ids, _createFilledArray(_ids.length, 1), "");
    }
  
    function _deactivateNFTPerksAndTransfer(address _of) private  { 
        _transferNftFrom(address(this), _of,  currentlyActiveNFTPerks[_of]);
        _deactivateNFTPerks(_of, currentlyActiveNFTPerks[_of]);
        delete currentlyActiveNFTPerks[_of];
    }

    function _deactivateNFTWeaponsAndTransfer(address _of) private  { 
        _transferNftFrom(address(this), _of, currentlyActiveNFTWeapons[_of]);
        _deactivateNFTWeapons(_of, currentlyActiveNFTWeapons[_of]);
        delete currentlyActiveNFTWeapons[_of];
    }

    function _deactivateNFTWeapons(address _of, uint256[] memory _currentlyActiveNFTWeapons) private { 
        for (uint256 index = 0; index < _currentlyActiveNFTWeapons.length; index++) {
            uint256 _activeWeaponId = _currentlyActiveNFTWeapons[index];
            CrimeNFT memory nft = _crimeMarketplace.getNftById(_activeWeaponId);
            _unapplyWeaponNFT(nft, _of);  
        }
    }

    function _deactivateNFTPerks(address _of, uint256[] memory _currentlyActiveNFTPerks) private {
        for (uint256 index = 0; index < _currentlyActiveNFTPerks.length; index++) {
            uint256 _activePerkId = _currentlyActiveNFTPerks[index];
            CrimeNFT memory nft = _crimeMarketplace.getNftById(_activePerkId);
            _unapplyPerkNFT(nft, _of);  
        }
    }

    function _applyWeaponsNFTBatch(uint256[] memory _nftIds, address _applyTo) private {
        for (uint256 index = 0; index < _nftIds.length; index++) {
            uint256 _nftId = _nftIds[index];

            CrimeNFT memory nft = _crimeMarketplace.getNftById(_nftId);
      
            require(nft.isPerk == false, "NFT is a perk");
            require(nft.weaponType != NFTWeaponType.NOT_A_VALUE, "NFT is not a weapon");

            _applyWeaponNFT(nft, _applyTo);
        }
    }

    function _applyPerksNFTBatch(uint256[] memory _nftIds, address _applyTo) private { 
        for (uint256 index = 0; index < _nftIds.length; index++) {
            uint256 _nftId = _nftIds[index];

            CrimeNFT memory nft = _crimeMarketplace.getNftById(_nftId);
      
            require(nft.isPerk, "NFT is not a perk");
            require(nft.perkType != NFTPerkType.NOT_A_VALUE, "NFT perk type is invalid");

            _applyPerkNFT(nft, _applyTo);  
        }
    }
  
    function _applyWeaponNFT(CrimeNFT memory _nft, address _applyTo) private { 
        currentlyActiveNFTWeapons[_applyTo].push(_nft.id);

        Crimer memory c = _crimerInfoStorage.getCrimer(_applyTo);

        if(_nft.weaponType == NFTWeaponType.Attack) {
            c.attack = c.attack + _nft.power;
        }
        else { 
            c.defense = c.defense + _nft.power;
        }

        _crimerInfoStorage.setCrimer(_applyTo, c);
    }

    function _applyPerkNFT(CrimeNFT memory _nft, address _applyTo) private { 
        currentlyActiveNFTPerks[_applyTo].push(_nft.id);

        Crimer memory c = _crimerInfoStorage.getCrimer(_applyTo);

        if (_nft.perkType == NFTPerkType.Attack) {
            c.nftPerkAttackBoost = c.nftPerkAttackBoost + _nft.power;
        } else if(_nft.perkType == NFTPerkType.Defense) { 
            c.nftPerkDefenseBoost = c.nftPerkDefenseBoost + _nft.power;
        } else if(_nft.perkType == NFTPerkType.Stake) { 
            c.nftPerkStakeBoost = c.nftPerkStakeBoost + _nft.power;
        } else {
            c.nftPerkPowerBoost = c.nftPerkPowerBoost + _nft.power;
        }

        _crimerInfoStorage.setCrimer(_applyTo, c);
    }

    function _unapplyWeaponNFT(CrimeNFT memory _nft, address _applyTo) private { 
        Crimer memory c = _crimerInfoStorage.getCrimer(_applyTo);

        if(_nft.weaponType == NFTWeaponType.Attack) {
            c.attack = c.attack - _nft.power;
        } else { 
        c.defense = c.defense - _nft.power;
        }

        _crimerInfoStorage.setCrimer(_applyTo, c);
    }

    function _unapplyPerkNFT(CrimeNFT memory _nft, address _applyTo) private { 
        Crimer memory c = _crimerInfoStorage.getCrimer(_applyTo);

        if (_nft.perkType == NFTPerkType.Attack) {
            c.nftPerkAttackBoost = c.nftPerkAttackBoost - _nft.power;
        } else if(_nft.perkType == NFTPerkType.Defense) { 
            c.nftPerkDefenseBoost = c.nftPerkDefenseBoost - _nft.power;
        } else if(_nft.perkType == NFTPerkType.Stake) { 
            c.nftPerkStakeBoost = c.nftPerkStakeBoost - _nft.power;
        } else {
            c.nftPerkPowerBoost = c.nftPerkPowerBoost - _nft.power;
        }

        _crimerInfoStorage.setCrimer(_applyTo, c);
    }

    function _createFilledArray(uint256 _size, uint256 _value) private pure returns (uint256[] memory arr) {
        arr = new uint256[](_size);
        for (uint256 i = 0; i < _size; i++) arr[i] = _value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
pragma experimental ABIEncoderV2;

import "./GovernableUpgradable.sol";
import "./CrimerInfo.sol";
import "./CrimeCashGame.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

struct PoolInfoData {
  bool isCrimeCash;

  IERC20Upgradeable lpToken;
  uint256 totalStaked;
  uint256 stakers;
  uint8   openDay;

  uint256[30] defaultApyRates;
  uint256[30] apyRates;

  bool exists;        
}  

struct PoolLastActivity {
  uint8 day;

  uint256 addStaked;
  uint256 subStaked;
  uint256 addStakers;
  uint256 subStakers;
}

struct StakerLastActivity {
  uint8 day;

  uint addStaked;
  uint subStaked;
}

struct Staker {
  bool exists;

  uint256 balance;

  StakerLastActivity lastActivity;

  mapping (uint8 => bool) isRewardClaimedAtDay;
}

struct PoolInfo {
  PoolInfoData infoData;

  PoolLastActivity lastActivity;
  
  mapping (address => Staker) stakers;
} 

contract CrimeCashGamePools is GovernableUpgradable {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using AddressUpgradeable for address;

  uint256[30] private _defaultCrimeCashPoolApyRates;

  /// @notice _00 - 2 decimals for amount
  uint256[30] private _defaultLpPoolApyRates;

  mapping (uint16 => PoolInfo[]) private _pools;

  CrimeCashGame private _crimeCashGame;
  CrimerInfo private _crimerInfo;
  CrimerInfoStorage private _crimerInfoStorage;
  CrimeCash private _crimeCash;

  uint16 private _roundNumber;
  uint8 private _roundDay;

  event AddPool(uint16 roundNumber, uint8 roundDay, uint256 poolIndex, bool isCrimeCash, address lpToken, uint8 openDay);
  event DeletePool(uint16 roundNumber, uint8 roundDay, uint256 poolIndex);
  event SetApyRate(uint16 roundNumber, uint8 roundDay, uint256 poolIndex, uint256[30] rates);
  event StakeLp(uint16 roundNumber, uint8 roundDay, uint256 poolIndex, address staker, uint256 amount);
  event StakeCash(uint16 roundNumber, uint8 roundDay, uint256 poolIndex, address staker, uint256 amount);
  event UnstakeLp(uint16 roundNumber, uint8 roundDay, uint256 poolIndex, address staker, uint256 amount);
  event Claim(uint16 roundNumber, uint8 roundDay, uint256 poolIndex, address staker, uint256 amount, uint8 payout_mode);

  function initialize(Storage store, CrimeCashGame crimeCashGame) public initializer {
    require(address(store).isContract(), "Store is not contract");
    require(address(crimeCashGame).isContract(), "CrimeCashGame is not contract");
    _crimeCashGame = crimeCashGame;

    __Governable_init(store);

    _defaultCrimeCashPoolApyRates = [
      15, 25, 20, 15, 10, 10,
      5, 5, 5, 5, 4, 4, 4, 4,
      3, 3, 3, 3, 3, 3, 3, 3,
      2, 2, 2, 2, 2, 2, 2, 2
    ];

    _defaultLpPoolApyRates = [
       5_000_000_00,     5_500_000_00,     6_000_000_00,      6_500_000_00,     7_000_000_00, 
       7_500_000_00,   10_000_000_00,   12_000_000_00,     15_000_000_00,     20_000_000_00, 
       25_000_000_00,   30_000_000_00,   40_000_000_00,    50_000_000_00,    60_000_000_00, 
       70_000_000_00,  75_000_000_00,  80_000_000_00,    90_000_000_00,    100_000_000_00, 
       200_000_000_00, 250_000_000_00, 500_000_000_00, 650_000_000_00, 800_000_000_00,
      1_000_000_000_00, 1_250_000_000_00, 1_500_000_000_00, 1_750_000_000_00, 1_800_000_000_00 
    ];
  }

  function setCrimerInfo(CrimerInfo crimerInfo) external {
    _onlyCrimeCashGame();

    require(address(crimerInfo).isContract(), "CrimerInfo is not contract");

    _crimerInfo = crimerInfo;
  }

  function onStartRound(address crimeCashAddress, uint16 roundNumber) external {
    _onlyCrimeCashGame();

    require(crimeCashAddress.isContract(), "CrimerInfo is not contract");

    _crimeCash = CrimeCash(payable(crimeCashAddress));
    _roundNumber = roundNumber;
    _roundDay = 1;

    _crimerInfoStorage = _crimerInfo.crimerInfoStorage();

    _addPool(true, crimeCashAddress, 1);
  }

  function onUpdateRound() external {
    _onlyCrimeCashGame();
    _roundDay += 1;
    for (uint256 i; i < _pools[_roundNumber].length; i++)
      _recalculateApyRates(_roundNumber, i);
  }

  function addPool(bool isCrimeCash, address lpToken, uint8 openDay) external {
    onlyGovernance();

    _addPool(isCrimeCash, lpToken, openDay);

    emit AddPool(_roundNumber, _roundDay, _pools[_roundNumber].length - 1, isCrimeCash, lpToken, openDay);
  }

  function deletePool(uint256 poolIndex) external {
    onlyGovernance();

    _deletePool(poolIndex);

    emit DeletePool(_roundNumber, _roundDay, poolIndex);
  }

  function setApyRate(uint256 poolIndex, uint256[30] calldata rates) external {
    onlyGovernance();

    _pools[_roundNumber][poolIndex].infoData.defaultApyRates = rates;

    emit SetApyRate(_roundNumber, _roundDay, poolIndex, rates);
  }
  
  function getCCashApyRateByDay() external view returns(uint256) {  
    return _defaultCrimeCashPoolApyRates[_roundDay - 1];
  }

  function getAllPoolInfos(uint16 roundNumber) external view returns(PoolInfoData[] memory){ 
    PoolInfoData[] memory poolInfos = new PoolInfoData[](_pools[roundNumber].length);

    for (uint256 i = 0; i < poolInfos.length; i++)
      poolInfos[i] = _pools[roundNumber][i].infoData;

    return poolInfos;
  }

  function getPoolInfo(uint16 roundNumber, uint256 poolIndex) public view returns (PoolInfoData memory) { 
    return _pools[roundNumber][poolIndex].infoData;
  }

  function getLengthOfPools(uint16 roundNumber) external view returns (uint256) { 
    return _pools[roundNumber].length;
  }

  function getPoolStaticStaked(uint16 roundNumber, uint256 poolIndex) public view returns (uint256 result) {
    result = _pools[roundNumber][poolIndex].infoData.totalStaked;

    if (_pools[roundNumber][poolIndex].lastActivity.day == _roundDay) {
        result += _pools[roundNumber][poolIndex].lastActivity.subStaked;
        result -= _pools[roundNumber][poolIndex].lastActivity.addStaked;
      }
  }

  function getSumOfApyRatesForCurrentRoundDayExceptCrimeCash(uint16 roundNumber) external view returns (uint256 result) {
    for (uint256 i; i < _pools[roundNumber].length; i ++) {
      if (_pools[roundNumber][i].infoData.exists && !_pools[roundNumber][i].infoData.isCrimeCash) {
        result += _pools[roundNumber][i].infoData.apyRates[_roundDay - 1];
      }
    } 
  }

  function getStakerBalance(uint16 roundNumber, uint256 poolIndex, address staker) external view returns (uint256) {
    return _pools[roundNumber][poolIndex].stakers[staker].balance;
  }

  function stakeLp(uint256 poolIndex, uint256 amount) external {
    _onlyCrimer(msg.sender);

    require(_pools[_roundNumber][poolIndex].infoData.exists == true, "Pool doesn't exists");
    require(_roundDay >= _pools[_roundNumber][poolIndex].infoData.openDay, "Pool is not opened yet");
    require(_pools[_roundNumber][poolIndex].infoData.isCrimeCash == false, "Not allowed LP staking");

    _pools[_roundNumber][poolIndex].infoData.lpToken.safeTransferFrom(msg.sender, address(this), amount);

    _tryResetLastActivity(_roundNumber, poolIndex, msg.sender);

    _stake(_roundNumber, poolIndex, msg.sender, amount);

    emit StakeLp(_roundNumber, _roundDay, poolIndex, msg.sender, amount);
  }

  function stakeCash(uint256 poolIndex, uint256 amount) external {
    _onlyCrimer(msg.sender);

    require(_pools[_roundNumber][poolIndex].infoData.exists == true, "Pool doesn't exists");
    require(_pools[_roundNumber][poolIndex].infoData.isCrimeCash == true, "Not allowed CrimeCash staking");
    require(_roundDay >= _pools[_roundNumber][poolIndex].infoData.openDay, "Pool is not opened yet");

    CrimerInfoStorage crimerInfoStorage = _crimerInfo.crimerInfoStorage();
    Crimer memory crimer = crimerInfoStorage.getCrimer(msg.sender);

    require(crimer.bank >= amount, "Not enough balance for staking");
    
    crimer.bank -= amount;
    crimerInfoStorage.setCrimer(msg.sender, crimer);

    uint256 lockedToken = crimerInfoStorage.lockedWithdrawToken(msg.sender);
    if (lockedToken <= amount) {
      crimerInfoStorage.updateLockedToken(msg.sender, 0);
    } 
    else {
      crimerInfoStorage.updateLockedToken(msg.sender, lockedToken - amount);
    }

    _tryResetLastActivity(_roundNumber, poolIndex, msg.sender);

    _stake(_roundNumber, poolIndex, msg.sender, amount);

    _crimeCash.mint(store.owner(), amount / 5); // minted 20%

    emit StakeCash(_roundNumber, _roundDay, poolIndex, msg.sender, amount);
  }

  function unstakeLp(uint16 roundNumber, uint256 poolIndex, uint256 amount) external {
    _onlyCrimer(msg.sender);
    
    require(_pools[roundNumber][poolIndex].infoData.exists == true, "Pool doesn't exists");
    require(_pools[roundNumber][poolIndex].infoData.isCrimeCash == false, "Not allowed LP unstaking");
    require(_roundNumber > roundNumber || _roundDay >= _pools[roundNumber][poolIndex].infoData.openDay, "Pool is not opened yet");
    require(_pools[roundNumber][poolIndex].stakers[msg.sender].balance >= amount, "Not enough staked balance for unstaking");  

    _tryResetLastActivity(roundNumber, poolIndex, msg.sender);

    _pools[roundNumber][poolIndex].infoData.totalStaked -= amount;
    _pools[roundNumber][poolIndex].stakers[msg.sender].balance -= amount;

    if (_pools[roundNumber][poolIndex].stakers[msg.sender].balance == 0) {
      _pools[roundNumber][poolIndex].stakers[msg.sender].exists = false;
      _pools[roundNumber][poolIndex].infoData.stakers -= 1;
      _pools[roundNumber][poolIndex].lastActivity.subStakers += 1;
    }

    _pools[roundNumber][poolIndex].lastActivity.subStaked += amount;
    _pools[roundNumber][poolIndex].stakers[msg.sender].lastActivity.subStaked += amount;

    _pools[roundNumber][poolIndex].infoData.lpToken.safeTransfer(msg.sender, amount);

    emit UnstakeLp(roundNumber,  roundNumber == _roundNumber ? _roundDay : 0, poolIndex, msg.sender, amount);
  }

  function getClaimAmount(uint256 poolIndex, address staker) public view returns(uint256) {
    _onlyCrimer(staker);

    require(_pools[_roundNumber][poolIndex].infoData.exists == true, "Pool doesn't exists");
    require(_roundDay >= 1 && _roundDay <= 30, "Invalid round day");

    if (_pools[_roundNumber][poolIndex].stakers[staker].isRewardClaimedAtDay[_roundDay])
      return 0;
    
    uint256 actualStaked = _pools[_roundNumber][poolIndex].stakers[staker].balance;

    if (_pools[_roundNumber][poolIndex].stakers[staker].lastActivity.day == _roundDay) {
      actualStaked += _pools[_roundNumber][poolIndex].stakers[staker].lastActivity.subStaked;
      actualStaked -= _pools[_roundNumber][poolIndex].stakers[staker].lastActivity.addStaked;
    }

    uint256 claimAmount = 0;

    if (_pools[_roundNumber][poolIndex].infoData.isCrimeCash) {
      claimAmount = actualStaked * _pools[_roundNumber][poolIndex].infoData.defaultApyRates[_roundDay - 1] / 100;
    }
    else {
      uint256 actualTotalStaked = _pools[_roundNumber][poolIndex].infoData.totalStaked;
      uint256 actualStakers = _pools[_roundNumber][poolIndex].infoData.stakers;

      if (_pools[_roundNumber][poolIndex].lastActivity.day == _roundDay) {
        actualTotalStaked += _pools[_roundNumber][poolIndex].lastActivity.subStaked;
        actualTotalStaked -= _pools[_roundNumber][poolIndex].lastActivity.addStaked;
        actualStakers +=_pools[_roundNumber][poolIndex].lastActivity.subStakers;
        actualStakers -= _pools[_roundNumber][poolIndex].lastActivity.addStakers;
      }

      if (actualTotalStaked == 0)
        return 0;

      uint256 apy = _pools[_roundNumber][poolIndex].infoData.apyRates[_roundDay - 1];

      uint256 liquid_share_rate = actualStaked * 100_0000 / actualTotalStaked;

      uint256 reward = apy * liquid_share_rate / 100_0000;

      uint256 burnable_rate = 0;

      if (actualStakers >= 10000) {
        if (liquid_share_rate >= 500000) {
          burnable_rate = 95;
        }
        else if (liquid_share_rate >= 300000) {
          burnable_rate = 90;
        }
        else if (liquid_share_rate >= 100000) {
          burnable_rate = 80;
        }
        else if (liquid_share_rate >= 50000) {
          burnable_rate = 50;
        }
        else {
          burnable_rate = 0;
        }
      }
      else if (actualStakers >= 1000) {
        if (liquid_share_rate >= 500000) {
          burnable_rate = 90;
        }
        else if (liquid_share_rate >= 300000) {
          burnable_rate = 80;
        }
        else if (liquid_share_rate >= 100000) {
          burnable_rate = 50;
        }
        else {
          burnable_rate = 0;
        }
      }
      else if (actualStakers >= 100) {
        if (liquid_share_rate >= 500000) {
          burnable_rate = 80;
        }
        else if (liquid_share_rate >= 300000) {
          burnable_rate = 50;
        }
        else if (liquid_share_rate >= 100000) {
          burnable_rate = 20;
        }
        else {
          burnable_rate = 0;
        }
      }
      else {
        burnable_rate = 0;
      }

      uint256 amountToBurn = reward * burnable_rate / 100;

      claimAmount = reward - amountToBurn;
    }

    uint256 boost = _crimerInfoStorage.getCrimerFarmBoost(staker);

    if (boost != 0) {
      uint256 boostAmount = claimAmount * boost / 100;

      claimAmount += boostAmount;
    }

    return claimAmount;
  }

  function claim(uint256 poolIndex, uint8 payout_mode) external {
    _onlyCrimer(msg.sender);

    PoolInfoData memory poolInfo = getPoolInfo(_roundNumber, poolIndex);

    require(poolInfo.openDay <= _roundDay, "Pool is not open yet");
    require(_pools[_roundNumber][poolIndex].stakers[msg.sender].balance > 0, "Staker balance is equal to 0");
    
    uint256 amount = getClaimAmount(poolIndex, msg.sender);

    _pools[_roundNumber][poolIndex].stakers[msg.sender].isRewardClaimedAtDay[_roundDay] = true;

    Crimer memory crimer = _crimerInfoStorage.getCrimer(msg.sender);

    if (payout_mode == 1) {
      crimer.bank += amount;
    }
    else {
      amount *= 2;
      crimer.cash += amount;
    }

    _crimerInfoStorage.setCrimer(msg.sender, crimer);

    _crimeCash.mint(_crimerInfoStorage.crimeBankInteraction(), amount);

    emit Claim(_roundNumber, _roundDay, poolIndex, msg.sender, amount, payout_mode);
  }

  function _addPool(bool isCrimeCash, address lpToken, uint8 openDay) private { 
    require(lpToken != address(0), "Invalid lpToken address");
    require(openDay > 0 && openDay < 30, "Invalid opend day");
    PoolInfo storage newPool = _pools[_roundNumber].push();
    
    newPool.infoData.isCrimeCash = isCrimeCash;
    newPool.infoData.lpToken = IERC20Upgradeable(lpToken);
    newPool.infoData.openDay = openDay;
    newPool.infoData.exists = true;
    
    _setApyRate(
      _pools[_roundNumber].length - 1,
      isCrimeCash ? 
        _defaultCrimeCashPoolApyRates : 
        _defaultLpPoolApyRates
    );

    _recalculateApyRates(_roundNumber, _pools[_roundNumber].length - 1);
  }

  function _deletePool(uint256 poolIndex) private {
    require(poolIndex < _pools[_roundNumber].length, "Invalid pool index");
    require(_pools[_roundNumber][poolIndex].infoData.exists == true, "Pool doesn't exist");
    
    _pools[_roundNumber][poolIndex].infoData.exists = false;
  }

  function _recalculateApyRates(uint16 roundNumber, uint256 poolIndex) private {
    if (_pools[roundNumber][poolIndex].infoData.isCrimeCash == true) 
        return;
    
    _pools[roundNumber][poolIndex].infoData.apyRates[_roundDay - 1] = 
      _pools[roundNumber][poolIndex].infoData.defaultApyRates[_roundDay - 1] +
        (_pools[roundNumber][poolIndex].infoData.defaultApyRates[_roundDay - 1] *
          (_pools[roundNumber][poolIndex].infoData.stakers == 0 ? 0 : _pools[roundNumber][poolIndex].infoData.stakers - 1));
  }

  function _setApyRate(uint256 poolIndex, uint256[30] memory rates) private {
    _pools[_roundNumber][poolIndex].infoData.defaultApyRates = rates;
    _pools[_roundNumber][poolIndex].infoData.apyRates = rates;
  }

  function _tryResetLastActivity(uint16 roundNumber, uint256 poolIndex, address crimer) private {
      if (_roundDay != _pools[roundNumber][poolIndex].lastActivity.day) 
      {
        _pools[roundNumber][poolIndex].lastActivity.day = _roundDay;
        _pools[roundNumber][poolIndex].lastActivity.addStaked = 0;
        _pools[roundNumber][poolIndex].lastActivity.subStaked = 0;
        _pools[roundNumber][poolIndex].lastActivity.addStakers = 0;
        _pools[roundNumber][poolIndex].lastActivity.subStakers = 0;
      }

      if (_roundDay != _pools[roundNumber][poolIndex].stakers[crimer].lastActivity.day) 
      {
        _pools[roundNumber][poolIndex].stakers[crimer].lastActivity.day = _roundDay;
        _pools[roundNumber][poolIndex].stakers[crimer].lastActivity.addStaked = 0;
        _pools[roundNumber][poolIndex].stakers[crimer].lastActivity.subStaked = 0;
      }
  }

  function _stake(uint16 roundNumber, uint256 poolIndex, address crimer, uint256 amount) private {
    require(amount > 0, "Amount to stake is equal to 0");

    _pools[roundNumber][poolIndex].infoData.totalStaked += amount;
    _pools[roundNumber][poolIndex].stakers[crimer].balance += amount;

    if (!_pools[roundNumber][poolIndex].stakers[crimer].exists) {
      _pools[roundNumber][poolIndex].stakers[crimer].exists = true;
      _pools[roundNumber][poolIndex].infoData.stakers += 1;
      _pools[roundNumber][poolIndex].lastActivity.addStakers += 1;
    }

    _pools[roundNumber][poolIndex].lastActivity.addStaked += amount;
    _pools[roundNumber][poolIndex].stakers[crimer].lastActivity.addStaked += amount;
  }
  
  function _isExistsPlayerInPool(uint16 roundNumber, uint256 poolIndex, address player) private view returns (bool) {
    return _pools[roundNumber][poolIndex].stakers[player].exists;
  }

  function _onlyCrimer(address who) view private {
    Crimer memory crimer = _crimerInfoStorage.getCrimer(who);

    require(crimer.exist, "Crimer doesn't exist");
  }

  function _onlyCrimeCashGame() view private {
    require(msg.sender == address(_crimeCashGame), "Sender is not CrimeCashGame");
  }

  function getCurrentApyRateByIndex(uint16 roundNumber, uint256 poolIndex) external view returns(uint256) {
    return _pools[roundNumber][poolIndex].infoData.apyRates[_roundDay - 1];
  }

  function setCurrentApyRateByIndex(uint16 roundNumber, uint256 poolIndex, uint256 amount) external {
    onlyController();
    _pools[roundNumber][poolIndex].infoData.apyRates[_roundDay - 1] = amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Types/Crimer.sol";
import "./Governable.sol";
import "./CrimeCashGame.sol";
import "./CrimerInfo.sol";
import "./CrimeCash.sol";

contract CrimeBankInteraction is Governable {

    CrimeCashGame private immutable _crimeCashGame;
    CrimerInfoStorage private _crimerInfoStorage;
    CrimeCash private _crimeCashToken;

    uint16 private _seasonNumber;
    
    uint256 public constant _transactionsPerDay = 15;

    event MoveToBank(address crimer, uint256 amount, uint8 roundDay, uint16 seasonNumber);
    event MoveToCash(address crimer, uint256 amount, uint8 roundDay, uint16 seasonNumber);
    event DepositTokenInGame(address crimer, uint256 amount, uint8 roundDay, uint16 seasonNumber);
    event WithdrawTokenFromGame(address crimer, uint256 amount, uint8 roundDay, uint16 seasonNumber);
    event WithdrawAllTokensFromPreviousSeasonGame(address crimer, address crimeCashAddress);

    constructor(Storage store, address crimeCashGameAddress) Governable(store) {
        require(
            crimeCashGameAddress != address(0),
            "crimeCashGameAddress shouldn't be empty"
        );
        _crimeCashGame = CrimeCashGame(crimeCashGameAddress);
    }

    modifier roundOpened() {
        require(_crimeCashGame.isRoundOpening() == true, "not opened round");
        _;
    }

    modifier onlyCrimer() {
        require(
            !store.governance(_msgSender()) && !store.controller(_msgSender()),
            "owner/controller not allowed"
        );
        _;
    }

    function moveToBank(uint256 amount) external onlyCrimer roundOpened {
        uint8 roundDay = _crimeCashGame.roundDay();
        Crimer memory crimer = _crimerInfoStorage.getCrimer(msg.sender);
        require(
            crimer.cash >= amount,
            "Not enough balance. You were looted during transaction."
        );
        require(crimer.bank + amount >= crimer.bank, "Overflow");
        _crimerInfoStorage.registerOneTransaction(
            _transactionsPerDay,
            roundDay,
            msg.sender
        );
        crimer.bank = crimer.bank + amount;
        crimer.cash = crimer.cash - (amount);
        _crimerInfoStorage.setCrimer(msg.sender, crimer);
        emit MoveToBank(msg.sender, amount, roundDay, _seasonNumber);
    }

    function moveToCash(uint256 amount) external onlyCrimer roundOpened {
        uint8 roundDay = _crimeCashGame.roundDay();
        Crimer memory crimer = _crimerInfoStorage.getCrimer(msg.sender);
        require(crimer.bank >= amount, "Not enough balance to move fund");
        require(crimer.cash + amount >= crimer.cash, "Overflow");
        _crimerInfoStorage.registerOneTransaction(
            _transactionsPerDay,
            roundDay,
            msg.sender
        );
        crimer.cash = crimer.cash + amount;
        crimer.bank = crimer.bank - amount;
        _crimerInfoStorage.setCrimer(msg.sender, crimer);
        emit MoveToCash(msg.sender, amount, roundDay, _seasonNumber);
    }

    function depositTokenInGame(uint256 amount)
        external
        onlyCrimer
        roundOpened
    {
        require(
            _crimeCashToken.balanceOf(msg.sender) >= amount,
            "lack ccash balance"
        );
        uint8 roundDay = _crimeCashGame.roundDay();
        Crimer memory crimer = _crimerInfoStorage.getCrimer(msg.sender);
        _crimeCashToken.transferFrom(msg.sender, address(this), amount);
        crimer.bank = crimer.bank + amount;
        _crimerInfoStorage.setCrimer(msg.sender, crimer);
        emit DepositTokenInGame(msg.sender, amount, roundDay, _seasonNumber);
    }

    function withdrawTokenFromGame(uint256 amount)
        external
        onlyCrimer
        roundOpened
    {
        require(
            _crimeCashToken.balanceOf(address(this)) >= amount,
            "Not enough ccash"
        );

        Crimer memory crimer = _crimerInfoStorage.getCrimer(msg.sender);

        uint256 lockedToken = _crimerInfoStorage.lockedWithdrawToken(msg.sender);
        uint256 notlocked = crimer.bank + crimer.cash - lockedToken;
        require(notlocked >= amount, "you haven't spent bonus token");

        _crimeCashToken.transfer(msg.sender, amount);
        crimer.bank = crimer.bank - amount;
        _crimerInfoStorage.setCrimer(msg.sender, crimer);
        uint8 roundDay = _crimeCashGame.roundDay();
        emit WithdrawTokenFromGame(msg.sender, amount, roundDay, _seasonNumber);
    }

    function withdrawAllTokensFromPreviousSeasonGame(address payable oldCrimeCashAddress) external onlyCrimer {
        CrimeCash crimeCash = CrimeCash(oldCrimeCashAddress);
        CrimerInfoStorage crimerInfoStorage = CrimerInfoStorage(_crimeCashGame.crimerInfoStorageAddressByCrimeCashAddress(oldCrimeCashAddress));

        Crimer memory crimer = crimerInfoStorage.getCrimer(msg.sender);
        uint256 amount = crimer.bank + crimer.cash;

        crimer.bank = 0;
        crimer.cash = 0;
        crimerInfoStorage.setCrimer(msg.sender, crimer);

        crimeCash.transfer(address(msg.sender), amount);
        emit WithdrawAllTokensFromPreviousSeasonGame(msg.sender, oldCrimeCashAddress);
    }

    function initializeIndispensableAddressesAndGameParameters(address payable crimeCashToken, address crimerInfoStorage, uint16 seasonNumber) external {
        require(msg.sender == address(_crimeCashGame), "Sender is not a gameEngine");
        _crimeCashToken = CrimeCash(crimeCashToken);
        _crimerInfoStorage = CrimerInfoStorage(crimerInfoStorage);
        _seasonNumber = seasonNumber;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../CrimerInfo.sol";

contract CrimerInfoStorageFactory {
    function createInstance(
        address _crimerInfo,
        address _crimeBankInteraction,
        address _nftAssetManager,
        address crimeGoldStaking,
        address crimeCashGamePools,
        address cCashFortuneWheel,
        address crimeLootBot
    ) external returns (address) {
        return
            address(
                new CrimerInfoStorage(
                    _crimerInfo,
                    _crimeBankInteraction,
                    _nftAssetManager,
                    crimeGoldStaking,
                    crimeCashGamePools,
                    cCashFortuneWheel,
                    crimeLootBot
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../CrimeCashGamePools.sol";
import "../GovernableUpgradable.sol";

contract CCashFortuneWheel is GovernableUpgradable {
    event RollRandom(address indexed winnerAddress, uint256 indexed id, uint256 amount, uint16 indexed seasonNumber);
    event AddMultiplierNft(uint256 id, string name, uint256 multiplierValue);

    CrimeCashGame public gameEngine;
    CrimerInfoStorage public crimerInfoStorage;
    CrimeCash public crimeCashToken;
    CrimeCashGamePools public crimeCashGamePools;

    uint256 public maxRollsPerDay;
    mapping(uint16 => mapping(uint8 => uint256)) public rollsAtDay; /// @dev roundNumber => roundDay => rollsMade

    mapping(address => uint256) public spinTimeByAddress; /// @dev address => last spin time
    uint256 private constant defaultMultiplicand = 5000_00;  /// @notice default win CCASH amount for first day; _00 - decimals
    uint256 private constant defaultWaitTime = 300; /// @notice default waitTime for user if CRIME is not staked
    uint64 public constant maxWonMultiplierPercent = 100000; /// @dev e.g. maxPercent = 100000(100%), percentValue >= 1 (0.001%)

    /// @notice Values for implementing percentage in win CCASH amount formula
    uint64 public percentValueFormula;
    uint256 public maxPercentFormula; /// @dev e.g. maxPercent = 10000(100%), percentValue >= 1 (0.01%)

    Multiplier[] private multipliers;

    uint256 private nonce; /// @dev auto-incremented nonce for random method
    uint256 private totalChanceWeight; /// @dev totalChanceWeight - overall chanche of winning multiplier

    uint256[30] private dayMultipliers;

    function initialize(Storage _storage, address gameAddress) public initializer {
        __Governable_init(_storage);

        gameEngine = CrimeCashGame(gameAddress);    
        
        maxRollsPerDay = 20000;

        percentValueFormula = 5;
        maxPercentFormula = 10000;

        dayMultipliers = [
              1000,   1300,   1563,   2000,   2400, 
              3100,   3800,   4800,   6000,   7500,
              9300,  11600,  14600,  18200,  22700,
             28400,  35500,  44400,  55500,  69400,
             86700, 108400, 135500, 169400, 211800,
            264700, 330900, 413600, 517000, 646200
        ];
    }

    function setCrimeCashGame(CrimeCashGame crimeCashGame) external {
      onlyGovernance();
      gameEngine = crimeCashGame;
    }

    function _incrementNonce() private { 
        if(nonce == RandomLibrary.MAX_UINT) nonce = 0;
        nonce++;  
    }

    function _rollRandomItem(uint256 nftsTotalChanceWeight, uint16 roundNumber, uint8 roundDay)
        private returns (uint256 winnerItemId) {
        winnerItemId = RandomLibrary.getRandomMultiplierAsset(multipliers, nftsTotalChanceWeight, nonce);
        _incrementNonce();
        rollsAtDay[roundNumber][roundDay] = rollsAtDay[roundNumber][roundDay] + 1;
    } 

    function _distributeWinAmount(uint256 multiplicand, uint16 roundNumber, uint8 roundDay) private returns(uint256 winnerItemId, uint256 winAmount) {
        winnerItemId = _rollRandomItem(totalChanceWeight, roundNumber, roundDay);
        uint256 wonMultiplier = multipliers[winnerItemId].multiplierValue;
        
        Crimer memory winner = crimerInfoStorage.getCrimer(msg.sender);

        winAmount = multiplicand * wonMultiplier / maxWonMultiplierPercent;
        winner.cash = winner.cash + winAmount;
            
        crimerInfoStorage.setCrimer(msg.sender, winner);

        crimeCashToken.mint(crimerInfoStorage.crimeBankInteraction(), winAmount);
    }

    function getMultiplicand(uint32 roundDay) public view returns(uint256) {
        return defaultMultiplicand * dayMultipliers[roundDay - 1] / 1000;
    }

    function getMultiplierNftById(uint256 id) external view returns(Multiplier memory) {
        require(id < multipliers.length, "Invalid NFT id");
        return multipliers[id];
    }

    function getMultipliers() external view returns(Multiplier[] memory) {
        return multipliers;
    } 

    function setMaxRollsPerDay(uint256 _maxRollsPerDay) external {
        onlyGovernance();
        maxRollsPerDay = _maxRollsPerDay;
    }

    function setPercentFormula(uint256 _maxPercentFormula, uint64 _percentValueFormula) external {
        onlyGovernance();
        maxPercentFormula = _maxPercentFormula;
        percentValueFormula = _percentValueFormula;
    }
    
    function setIndispensableAddresses(address crimerInfoStorageAddress, address payable cCashAddress, address _crimeCashGamePools) external {  
        require(msg.sender == address(gameEngine), "Sender is not a gameEngine");
        require(crimerInfoStorageAddress != address(0) || cCashAddress != address(0) || _crimeCashGamePools != address(0), "zero address");
   
        crimerInfoStorage = CrimerInfoStorage(crimerInfoStorageAddress);
        crimeCashToken = CrimeCash(cCashAddress);
        crimeCashGamePools = CrimeCashGamePools(_crimeCashGamePools);
    }

    function setMultipliers(Multiplier[] calldata _multipliers) external {
        onlyGovernance();
        delete multipliers;

        for(uint256 i = 0; i < _multipliers.length; i++) {
            multipliers.push(_multipliers[i]);
            emit AddMultiplierNft(_multipliers[i].id, _multipliers[i].name, _multipliers[i].multiplierValue);
        }
    }

    function addMultiplierAsset(
        uint256 id,
        string memory name,
        string memory image,
        uint256 multiplierValue,
        uint256 chanceWeight
    ) external {
        onlyGovernance();
        multipliers.push(
            Multiplier({
                id: id, 
                name: name,
                image: image,
                multiplierValue: multiplierValue,
                from: totalChanceWeight,
                to: totalChanceWeight + chanceWeight
            })
        );

        totalChanceWeight = totalChanceWeight + chanceWeight;

        emit AddMultiplierNft(id, name, multiplierValue);
    }
    function getWaitTime() public view returns(uint256 waitTime) {
        waitTime = crimerInfoStorage.getCrimerCrimeCashFortuneWheelCooldown(msg.sender);
        if(defaultWaitTime < waitTime) {
            waitTime = defaultWaitTime;
        }
    }

    function rollRandom() external {
        uint16 roundNumber = gameEngine.roundNumber();
        uint8 roundDay = gameEngine.roundDay();
        require(multipliers.length > 0 , "no items to roll");
        require(rollsAtDay[roundNumber][roundDay] < maxRollsPerDay, "no spins left");
        require(spinTimeByAddress[msg.sender] == 0 || spinTimeByAddress[msg.sender] + getWaitTime() <= block.timestamp, 
            "wait more time");
        
        uint256 multiplicand = getMultiplicand(roundDay);
        spinTimeByAddress[msg.sender] = block.timestamp;

        (uint256 winnerItemId, uint256 winAmount) = _distributeWinAmount(multiplicand, roundNumber, roundDay);

        uint256 lockedToken = crimerInfoStorage.lockedWithdrawToken(msg.sender);
        crimerInfoStorage.updateLockedToken(msg.sender, lockedToken + winAmount);

        emit RollRandom(msg.sender, winnerItemId, winAmount, roundNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Types/Crimer.sol";
import "./CrimerInfo.sol";
import "./GovernableUpgradable.sol";
import "./CrimeBankInteraction.sol";
import "./mainnet_token/CrimeCashMainnet.sol";

/**
Error codes: 
    CLB 01: msg.sender doesn't have permit to changes
*/
contract CrimeLootBot is GovernableUpgradable {
    struct Bot {
        bool isBot;
        uint256 lastAssetClaimTime;
        uint256 lastDefenseClaimTime;
        uint256 startTime;
    }

    address private _crimeCashGame;

    CrimerInfo private _crimerInfo;
    CrimeCash private _crimecashToken;
    CrimeCashMainnet private _crimeCashMainnet;
    CrimerInfoStorage private _crimerInfoStorage;

    address private _crimeBankInteraction;

    uint16 public roundNumber;
    uint256 public initialAmount;
    uint256 public initialDefense;
    uint256 public accelerationK;
    uint256 public accelerationD;
    
    address public default_address_bot_1;
    address public default_address_bot_2;
    address public default_address_bot_3;
    address public default_address_bot_4;
    address public default_address_bot_5;

    mapping(address => Bot) public bs;

    event BotSecretEventStart(
        address botAddress,
        uint16 roundNumber,
        uint256 depositAmount,
        uint256 extraDefense
    );

    function initializeIndispensableAddresses(
        address crimerInfo,
        address crimerInfoStorage,
        address crimeBankInteraction,
        address payable crimeCashMainnet
    ) external {
        require(store.owner() == msg.sender || _crimeCashGame == msg.sender, "CLB 01");
        _crimerInfo = CrimerInfo(crimerInfo);
        _crimeBankInteraction = crimeBankInteraction;
        _crimeCashMainnet = CrimeCashMainnet(crimeCashMainnet);
        _crimerInfoStorage = CrimerInfoStorage(crimerInfoStorage);
    }

    function createLootBots(address botAddress) external {
        onlyGovernaneOrController();

        _createLootBot(botAddress);
    }

    function claimDefenseDistribution(address bot) external {
        onlyGovernaneOrController();
        require(bs[bot].isBot, "A nq botAd");
        require(
            block.timestamp - bs[bot].lastDefenseClaimTime >= 23 hours,
            "Within 23 hours"
        );
        uint8 currentTimeHour = uint8((block.timestamp / 60 / 60) % 24);
        require(
            currentTimeHour >= 12 && currentTimeHour <= 18,
            "Out of eligible time scope"
        );

        uint256 calculateAsset = calculateAssetGeometric(bs[bot].startTime);
        uint256 calculateExtraDefense = calculateDefenseArithmetic(bs[bot].startTime);

        Crimer memory c = _crimerInfoStorage.getCrimer(bot);
        c.defense += calculateExtraDefense;
        c.cash += calculateAsset;
        _crimerInfoStorage.setCrimer(bot, c);

        bs[bot].lastDefenseClaimTime = block.timestamp;

        /// @dev mint ccah to increase totalSupply
        _crimeCashMainnet.mint(_crimeBankInteraction, calculateAsset);

        emit BotSecretEventStart(bot, roundNumber, calculateAsset, calculateExtraDefense);
    }

    function initialize(Storage _storage, address crimeCashGame) public initializer {
        __Governable_init(_storage);

        _crimeCashGame = crimeCashGame;

        roundNumber = 1;
        initialAmount = 3000000;
        initialDefense = 500000;
        accelerationK = 1250;
        accelerationD = 1000;

        default_address_bot_1 = 0x0000000000000000000000000000000000000001;
        default_address_bot_2 = 0x0000000000000000000000000000000000000002;
        default_address_bot_3 = 0x0000000000000000000000000000000000000003;
        default_address_bot_4 = 0x0000000000000000000000000000000000000004;
        default_address_bot_5 = 0x0000000000000000000000000000000000000005;
    }

    function calculateAssetGeometric(uint256 startTime)
        public
        view
        returns (uint256)
    {
        return
            initialAmount *
            ((accelerationK / accelerationD) **
                _calculateNumberOfDays(startTime));
    }

    function calculateDefenseArithmetic(uint256 startTime)
        public
        view
        returns (uint256)
    {
        return
            initialDefense *
            ((accelerationK / accelerationD) *
                _calculateNumberOfDays(startTime));
    }

    function _createLootBot(address botAddress) private {
        onlyGovernaneOrController();

        _crimerInfo.createNewBotCrimer(botAddress);
        bs[botAddress].isBot = true;
        bs[botAddress].startTime = block.timestamp;
        bs[botAddress].lastDefenseClaimTime = 0;
    }

    function _calculateNumberOfDays(uint256 startTime)
        private
        view
        returns (uint256)
    {
        return (block.timestamp - startTime) / (1 days) + 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";

contract Storage is Context {

  mapping (address => bool) public governance;
  mapping (address => bool) public controller;

  address immutable public owner;

  constructor() {
    owner = _msgSender();
    governance[_msgSender()] = true;
    controller[_msgSender()] = true;
  }

  
  function setGovernance(address _governance, bool _isGovernance) external {
    require(_msgSender() == owner, "not an owner");
    require(_governance != _msgSender(), "governance cannot modify itself");
    governance[_governance] = _isGovernance;
  }

  function setController(address _controller, bool _isController) external {
    require(governance[_msgSender()], "not a governance");
    controller[_controller] = _isController;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Storage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// File: contracts/Governable.sol

contract GovernableUpgradable is Initializable {
  Storage public store;

  function __Governable_init(Storage _store) public initializer {
    store = _store;
  }

  function onlyOwner() internal view{
    require(store.owner() == msg.sender, "Not the owner");
  }

  function onlyGovernance() internal view{
    require(store.governance(msg.sender), "Not governance");
  }

  function onlyController() internal view{
    require(store.controller(msg.sender), "Not controller");
  }

  function onlyGovernaneOrController() internal view{
    require(store.controller(msg.sender) || store.governance(msg.sender) , "Not a owner/controller");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../extensions/ERC20BurnableUpgradeable.sol";
import "../extensions/ERC20PausableUpgradeable.sol";
import "../../../access/AccessControlEnumerableUpgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauserUpgradeable is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable {
    function initialize(string memory name, string memory symbol) public virtual initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal onlyInitializing {
        __ERC20_init_unchained(name, symbol);
        __Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory, string memory) internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
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
pragma solidity 0.8.13;

import "./Storage.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract CrimeCash is ERC20PresetMinterPauserUpgradeable {
    using AddressUpgradeable for address;

    Storage private _storage;

    function initialize(Storage storage_) public initializer {
        ERC20PresetMinterPauserUpgradeable.initialize("CrimeCash", "CCASH");
        _storage = storage_;
    }

    modifier onlyOwner() {
        require(_storage.owner() == msg.sender, "The msg.sender adress is not the owner contract");
        _;
    }

    /// @dev The CrimeCash token must have precision of 2
    function decimals() public pure override returns (uint8) {
        return 2;
    }

    function initializeMintAccess(
        address crimerInfoAddress, 
        address crimeCashGamePoolsAddress, 
        address cCashFortuneWheel,
        address crimeLootBot) 
        external onlyOwner 
    {
        _isContract(crimerInfoAddress);
        grantRole(MINTER_ROLE, crimerInfoAddress);
        grantRole(MINTER_ROLE, cCashFortuneWheel);
        grantRole(MINTER_ROLE, crimeCashGamePoolsAddress);
        grantRole(MINTER_ROLE, crimeLootBot);
    }

    receive() external payable {}

    function _isContract(address addr) private view {
        require(addr.isContract(), "current address is non contract address");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Types/Crimer.sol";
import "./SafePercentageLibrary.sol";

library CrimerLibrary {
    using SafePercentageLibrary for uint256;

    function totalAttack(Crimer memory _crimer) internal pure returns (uint256) { 
        return 
            _crimer.attack 
                + _crimer.attack.safePercentageFrom(_crimer.nftPerkAttackBoost)
                + _crimer.attack.safePercentageFrom(_crimer.nftPerkPowerBoost);
    }

    function totalDefense(Crimer memory _crimer) internal pure returns (uint256) { 
        return
            _crimer.defense
                + _crimer.defense.safePercentageFrom(_crimer.nftPerkDefenseBoost)
                + _crimer.defense.safePercentageFrom(_crimer.nftPerkPowerBoost);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Crimer {
    bool exist;
    address userAddress;
    uint256 bank;
    uint256 cash;
    uint256 attack;
    uint256 defense;
    uint256 boost;
    uint256 referrals;
    uint256 protectedUntil;
    uint256[] boosts;
    // in percents. Parts per 100 (1% - 1)
    uint256 nftPerkAttackBoost;
    uint256 nftPerkDefenseBoost;
    uint256 nftPerkPowerBoost;
    uint256 nftPerkStakeBoost;
    uint256 index;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library SafePercentageLibrary {
    using SafeMath for uint256;
    function safePercentageFrom(uint256 _total, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        if (_total == 0) return 0;
        return _total.mul(_percentage).div(_total);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity 0.8.13;

import "../Types/NFTWeaponType.sol";
import "../Types/NFTPerkType.sol";

struct CrimeNFT {
    uint256 id;
    string name;
    string description;
    string image;
    bool isPerk;
    NFTPerkType perkType;
    NFTWeaponType weaponType;
    uint256 power;
    uint256 from;
    uint256 to;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "./CrimeNFTItem.sol";

import "../Types/CrimeNFT.sol";
import "../libraries/RandomLibrary.sol";
import "../Types/NFTWeaponType.sol";
import "../Types/NFTPerkType.sol";
import "../CrimeGold.sol";
import "../CrimeCashGame.sol";
import "../GovernableUpgradable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract CrimeMarketplace is GovernableUpgradable, Context {
    using SafeMath for uint256;

    /// @notice The amount is utilized for rolling cost of fortune wheel
    /// Consist of 950(reward_crimer) + 30(reward_dev) + 20(marketing_expenses)
    uint256 constant private CRIME_REWARD_FOR_SEASON = 1000 * 1e18;
    address constant private DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event AddNFTAssetToGame(uint256 indexed id, string name, bool indexed isPerk, NFTPerkType perkType, NFTWeaponType weaponType, uint256 power);
    event MintNFTAssetToAddressById(uint256 indexed _idNft, address indexed _mintTo);
    event RollRandomItem(address indexed winnerAddres,uint256 indexed weaponId, uint16 indexed seasonNumber);
    event ReRollRandomItem(address indexed winnerAddres, uint256 indexed nftId, uint256 burnNftId, uint16 indexed seasonNumber);

    /// @notice roundNumber => roundDay => rollsMade
    mapping(uint16 => mapping(uint8 => uint256)) public rollsAtDay;

    CrimeNFT[] public nfts;

    uint256[] public weaponAttackNftIds;
    uint256[] public weaponDefenseNftIds;
    uint256[] public perkNftIds; 

    uint256 private _randomNonce;
    uint256 private _totalAttackWeaponsChanceWeight;
    uint256 private _totalDefenseWeaponsChanceWeight;

    uint256 private _totalPerksChanceWeight;

    uint256 public maximumRollsPerDay;
    
    CrimeNFTItem public nftItem;

    CrimeGold private _cgold;

    CrimeCashGame private crimeCashGame;

    function initialize (
        CrimeGold cgold,
        CrimeCashGame _crimeCashGame,
        Storage _store,
        CrimeNFTItem _nftItem
    ) public initializer { 
        _cgold = cgold;
        crimeCashGame = _crimeCashGame;
        nftItem = _nftItem;

        __Governable_init(_store);

        maximumRollsPerDay = 250;
    }

    function setCrimeCashGame(CrimeCashGame _crimeCashGame) external {
      onlyGovernance();
      crimeCashGame = _crimeCashGame;
    }

    function setMaximumRollsPerDay(uint256 _rollsPerDay) external { 
        onlyGovernance();
        maximumRollsPerDay = _rollsPerDay;
    }

    function addAsset(
        uint256 id,
        string memory name,
        string memory description,
        string memory image,
        bool isPerk,
        NFTPerkType perkType,
        NFTWeaponType weaponType,
        uint256 power,
        uint256 chanceWeight
    ) external {
        onlyGovernance();
        
        nfts.push(CrimeNFT({
                id: id, 
                name: name,
                description : description,
                image: image,
                isPerk: isPerk, 
                perkType: perkType, 
                weaponType: weaponType,
                power: power,
                from: isPerk 
                    ? _totalPerksChanceWeight 
                    : weaponType == NFTWeaponType.Attack 
                        ? _totalAttackWeaponsChanceWeight 
                        : _totalDefenseWeaponsChanceWeight,
                to: isPerk
                    ? _totalPerksChanceWeight.add(chanceWeight)
                    : weaponType == NFTWeaponType.Attack
                        ? _totalAttackWeaponsChanceWeight.add(chanceWeight)
                        : _totalDefenseWeaponsChanceWeight.add(chanceWeight)
            }));

        if (isPerk) { // if perk
            _totalPerksChanceWeight = _totalPerksChanceWeight.add(chanceWeight);
            perkNftIds.push(id);
        } else if (weaponType == NFTWeaponType.Attack) { // if attack weapon
            _totalAttackWeaponsChanceWeight = _totalAttackWeaponsChanceWeight.add(chanceWeight);
            weaponAttackNftIds.push(id);
        } else { // if defense weapon
            _totalDefenseWeaponsChanceWeight = _totalDefenseWeaponsChanceWeight.add(chanceWeight);
            weaponDefenseNftIds.push(id);
        }

        emit AddNFTAssetToGame(id, name, isPerk, perkType, weaponType, power);
    }

    function getAllNfts() external view returns (CrimeNFT[] memory) { 
        return nfts;
    }
    
    function getRollRandomPerkCost() public view returns(uint256){
        return _cgold.totalSupply().sub(CRIME_REWARD_FOR_SEASON).sub(_cgold.balanceOf(0x000000000000000000000000000000000000dEaD)).div(10000);
    }

    function getRollRandomWeaponCost() public view returns(uint256){
        return _cgold.totalSupply().sub(CRIME_REWARD_FOR_SEASON).sub(_cgold.balanceOf(0x000000000000000000000000000000000000dEaD)).div(100000);
    }

    function getNftById(uint256 _id) external view returns(CrimeNFT memory) {
        return nfts[_id];
    }

    function rollRandomPerk() 
        external
        returns (uint256 winnerItemId) 
    {
        uint256 rollRandomPerkCost = getRollRandomPerkCost();
        require(rollRandomPerkCost > 0, "Roll cost is less less than or equal to 0");
        _cgold.transferFrom(_msgSender(), address(this), rollRandomPerkCost);

        uint16 seasonNumber = _beforeItemRoll();
        require(perkNftIds.length > 0, "No perks to roll");

        winnerItemId = _rollRandomItem(_msgSender(), perkNftIds,_totalPerksChanceWeight);
        emit RollRandomItem(_msgSender(), winnerItemId, seasonNumber);
    }

    function rollRandomWeapon() 
        external
        returns (uint256 winnerItemId)
    {
        uint256 rollRandomWeaponCost = getRollRandomWeaponCost();
        require(rollRandomWeaponCost > 0, "Roll cost is less less than or equal to 0");
        _cgold.transferFrom(_msgSender(), address(this), rollRandomWeaponCost);

        uint16 seasonNumber = _beforeItemRoll();

        winnerItemId = _rollWeapon();
        
        emit RollRandomItem(_msgSender(), winnerItemId, seasonNumber);
    }


    function _rollWeapon() private returns (uint256) {
        require(weaponAttackNftIds.length > 0 || weaponDefenseNftIds.length > 0 , "No weapons to roll");
        // 50% of rolling attack and 50% of rolling defense
        bool rollAttack =  RandomLibrary.random(_randomNonce, 2) == 1;

        return rollAttack ? 
            _rollRandomItem(_msgSender(), weaponAttackNftIds, _totalAttackWeaponsChanceWeight) : 
            _rollRandomItem(_msgSender(), weaponDefenseNftIds,_totalDefenseWeaponsChanceWeight);
    }
    
    function _rollRandomItem(
        address _mintTo, 
        uint256[] storage _participatingIds, 
        uint256 _participatingNftsTotalChanceWeight
    ) private returns (uint256 _winnerItemId){
        _winnerItemId =  RandomLibrary.getRandomAsset(nfts, _participatingIds, _participatingNftsTotalChanceWeight, _randomNonce);
        _incrementNonce();
        nftItem.mintItem(_mintTo, _winnerItemId, 1);
    }

    function reRollRandomItem(uint256 burnItemId) external returns (uint256 winnerItemId) {
        require(nftItem.balanceOf(msg.sender, burnItemId) > 0, "");

        bool isPerkNFT = nfts[burnItemId].isPerk;

        uint256 discountPrice = 0;
        if(isPerkNFT)
            discountPrice = getRollRandomPerkCost() / 2;
        else 
            discountPrice = getRollRandomWeaponCost() / 2;

        _cgold.transferFrom(msg.sender, address(this), discountPrice);
        nftItem.burnItem(msg.sender, burnItemId, 1);

        uint16 seasonNumber = _beforeItemRoll();

        if(isPerkNFT) {
            winnerItemId = _rollRandomItem(_msgSender(), perkNftIds, _totalPerksChanceWeight);
        } else {
            winnerItemId = _rollWeapon();
        }

        emit ReRollRandomItem(msg.sender, winnerItemId, burnItemId, seasonNumber);
    }

    function _beforeItemRoll() private returns(uint16) { 
        require(crimeCashGame.isRoundOpening(), "CrimeMarketplace: Round is not opened");
        uint16 roundNumber = crimeCashGame.roundNumber();
        uint8 roundDay = crimeCashGame.roundDay();

        require(rollsAtDay[roundNumber][roundDay] < maximumRollsPerDay, "CrimeMarketplace: Exceeded rolls for current day");
        rollsAtDay[roundNumber][roundDay] = rollsAtDay[roundNumber][roundDay].add(1);
        return roundNumber;
    }   
    
    function _incrementNonce() private { 
        if(_randomNonce == RandomLibrary.MAX_UINT) _randomNonce = 0;
        _randomNonce = _randomNonce.add(1);  
    }

    function celarNFTArray() external {
        onlyGovernance();
        delete nfts;
        delete weaponAttackNftIds;
        delete weaponDefenseNftIds;
        delete perkNftIds;

        _totalAttackWeaponsChanceWeight = 0;
        _totalDefenseWeaponsChanceWeight = 0; 
        _totalPerksChanceWeight = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract ERC1155Receiver is IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 interfaceId)
        external
        view
        virtual
        override
        returns (bool)
    {
        return type(IERC1155Receiver).interfaceId == interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum NFTWeaponType { 
    NOT_A_VALUE,
    Attack,
    Defense
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

enum NFTPerkType { 
    NOT_A_VALUE,
    Attack,
    Defense,
    Stake,
    TotalPower
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
interface IERC165 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../Types/CrimeNFT.sol";
import "../libraries/RandomLibrary.sol";
import "../Types/NFTWeaponType.sol";
import "../Types/NFTPerkType.sol";
import "../CrimeGold.sol";
import "../CrimeCashGame.sol";
import "../GovernableUpgradable.sol";

/// @title Crime NFT Item
/// @notice represents nft game item
contract CrimeNFTItem is ERC1155Upgradeable, GovernableUpgradable {
    using Strings for uint256;

    mapping(address => bool) public minters;

    address public marketplace;

    event MintItem(address indexed mintTo, uint256 indexed id, uint256 amount);
    event BurnItem(address indexed from, uint256 indexed id, uint256 amount);

    modifier onlyMarketplace() {
        require(msg.sender == marketplace, "not marketplace");
        _;
    }

    /// @param baseUrl nft metadata base url. Should end with /
    /// Example https://some-url.com/
    function initialize(string memory baseUrl, Storage _store) public initializer {
        __Governable_init(_store);
        __ERC1155_init(baseUrl);
        minters[_store.owner()] = true;
    }

    function mintItem(
        address mintTo,
        uint256 nftId,
        uint256 amount
    ) external {
        require(
            minters[msg.sender] || msg.sender == marketplace,
            "CrimeNFTItem: not minter"
        );
        require(amount > 0, "amount lte 0");
        _mintItem(mintTo, nftId, amount);
    }

    function mintItemsBunch(
        address[] memory mintTos,
        uint256[] memory nftIds,
        uint256[] memory amounts
    ) external {
        require(
            minters[msg.sender] || msg.sender == marketplace,
            "CrimeNFTItem: not minter"
        );
        require(
            mintTos.length == nftIds.length && mintTos.length == amounts.length,
            "Mismatch lengths"
        );

        for (uint256 i = 0; i < mintTos.length; i++) {
            _mintItem(mintTos[i], nftIds[i], amounts[i]);
        }
    }

    function burnItem(
        address from,
        uint256 nftId,
        uint256 amount
    ) external onlyMarketplace {
        _burn(from, nftId, amount);
        emit BurnItem(from, nftId, amount);
    }

    function setMinter(address minter, bool value) external {
        onlyGovernance();
        minters[minter] = value;
    }

    function setMarketplace(address _marketplace) external {
        onlyGovernance();
        marketplace = _marketplace;
    }

    function setUri(string memory newUri) external virtual {
        onlyGovernance();
        _setURI(newUri);
    }

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.uri(id), Strings.toString(id), ".json"));
    }

    function _mintItem(
        address mintTo,
        uint256 nftId,
        uint256 amount
    ) private {
        _mint(mintTo, nftId, amount, "");
        emit MintItem(mintTo, nftId, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Types/CrimeNFT.sol";
import "../Types/Multiplier.sol";

library RandomLibrary {

    uint256 public constant MAX_UINT = 2**256 - 1;

    function random(uint256 nonce, uint256 maxValue)
        internal
        view
        returns (uint256)
    {
        return
            _random(
                block.difficulty,
                block.timestamp,
                blockhash(block.number),
                nonce,
                maxValue
            );
    }

    function random(uint256 nonce) internal view returns (uint256) {
        return
            _random(
                block.difficulty,
                block.timestamp,
                blockhash(block.number),
                nonce,
                MAX_UINT
            );
    }

    function _random(
        uint256 _blockDiff,
        uint256 _timestamp,
        bytes32 _hash,
        uint256 nonce,
        uint256 maxValue
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(_blockDiff, _timestamp, _hash, nonce)
                )
            ) % maxValue;
    }

    function getRandomAsset(
        CrimeNFT[] storage _assets,
        uint256[] storage _participatedIds,
        uint256 _totalWeigths,
        uint256 _nonce
    ) internal view returns (uint256 assetId) {
        uint256 rnd = random(_nonce, _totalWeigths);

        if(rnd == 0)
            rnd = 1;

        for (uint256 j; j < _participatedIds.length; j++) {
            uint256 i = _participatedIds[j];
            if (rnd >= _assets[i].from && rnd <= _assets[i].to) return i;
        }
    }

    function getRandomMultiplierAsset(
        Multiplier[] storage _assets,
        uint256 _totalWeigths,
        uint256 _nonce
    ) internal view returns (uint256 assetId) {
        uint256 rnd = random(_nonce, _totalWeigths);

        if(rnd == 0)
            rnd = 1;

        for (uint256 i; i < _assets.length; i++) {
            if (rnd >= _assets[i].from && rnd <= _assets[i].to) 
                return i;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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
     * Emits a {ApprovalForAll} event.
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
pragma solidity 0.8.13;

struct Multiplier {
    uint256 id;
    string name;
    string image;
    uint256 multiplierValue;
    uint256 from;
    uint256 to;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Swapper.sol";
import "../Storage.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract CrimeCashMainnet is ERC20PresetMinterPauserUpgradeable {
    Storage private _storage;
    bool private _inSwapAndLiquify;

    uint256 public liquidityFee;
    uint256 public burnFee;
    bool public swapAndLiquifyEnabled;

    IUniswapV2Router02 public uniswapV2Router;

    Swapper private _swapper;
    address public usdc;
    address public crime;
    address public uniswapV2Pair;

    modifier onlyOwner() {
        require(
            _storage.owner() == msg.sender,
            "The msg.sender adress is not the owner contract"
        );
        _;
    }

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    receive() external payable {}

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function initializeMintAccess(
        address crimerInfoAddress,
        address crimeCashGamePoolsAddress,
        address cCashFortuneWheel,
        address crimeLootBot
    ) external onlyOwner {
        _isContract(crimerInfoAddress);
        _isContract(cCashFortuneWheel);
        _isContract(crimeCashGamePoolsAddress);
        grantRole(MINTER_ROLE, crimerInfoAddress);
        grantRole(MINTER_ROLE, cCashFortuneWheel);
        grantRole(MINTER_ROLE, crimeCashGamePoolsAddress);
        grantRole(MINTER_ROLE, crimeLootBot);
    }

    function initialize(
        Storage storage_,
        address routerAddress_,
        address usdc_,
        address crime_
    ) public initializer {
        ERC20PresetMinterPauserUpgradeable.initialize("CrimeCash", "CCASH");

        _swapper = new Swapper(routerAddress_, address(this), usdc_, crime_);
        uniswapV2Router = IUniswapV2Router02(routerAddress_);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                usdc_
            );

        IERC20Upgradeable(usdc_).approve(routerAddress_, type(uint256).max);
        IERC20Upgradeable(crime_).approve(routerAddress_, type(uint256).max);

        _approve(address(this), address(_swapper), type(uint256).max);
        _approve(address(this), routerAddress_, type(uint256).max);

        usdc = usdc_;
        crime = crime_;

        liquidityFee = 5;
        burnFee = 5;
        _storage = storage_;
        swapAndLiquifyEnabled = true;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        return
            super.transfer(
                recipient,
                _partialAddToLiquidity(msg.sender, recipient, amount)
            );
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        return
            super.transferFrom(
                sender,
                recipient,
                _partialAddToLiquidity(sender, recipient, amount)
            );
    }

    /// @dev The CrimeCash token must have precision of 2
    function decimals() public pure override returns (uint8) {
        return 2;
    }

    function _partialAddToLiquidity(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 amountForLiquidity = 0;
        uint256 amountForBuyCrime = 0;        
        address owner = _storage.owner();

        if (
            !_inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            sender != owner &&
            recipient != owner &&
            recipient == uniswapV2Pair
        ) {
            amountForLiquidity = (amount * liquidityFee) / 100;
            _swapAndLiquify(amountForLiquidity, sender);

            amountForBuyCrime = (amount * burnFee) / 100;
            _swapAndBurn(amountForBuyCrime, sender);         
        }

        return amount - amountForLiquidity - amountForBuyCrime;
    }
    
    function _swapAndBurn(uint256 amountToBurn, address from)
        private
        lockTheSwap
    {
        _transfer(from, address(this), amountToBurn);        
        _swapper.swapTokensAForTokensCAndBurn(amountToBurn);
    }

    function _swapAndLiquify(uint256 amountToLiquify, address from)
        private
        lockTheSwap
    {
        _transfer(from, address(this), amountToLiquify);

        uint256 half = amountToLiquify / 2;
        uint256 otherHalf = amountToLiquify - half;

        uint256 initialBalance = IERC20(usdc).balanceOf(address(this));
        _swapper.swapTokensAForTokensB(half);

        uint256 newBalance = IERC20(usdc).balanceOf(address(this)) -
            initialBalance;

        _addLiquidity(otherHalf, newBalance);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdcAmount) private {
        uniswapV2Router.addLiquidity(
            address(this),
            usdc,
            tokenAmount,
            usdcAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _storage.owner(), // The LP tokens will be added to owner address.
            block.timestamp
        );
    }

    function _isContract(address addr) private view {
        require(
            AddressUpgradeable.isContract(addr),
            "current address is non contract address"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Swapper {
    IUniswapV2Router02 private immutable _uniswapV2Router;
    address private immutable _tokenA;
    address private immutable _tokenB;
    address private immutable _tokenC;

    address private constant _DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    constructor(address router, address tokenA, address tokenB, address tokenC) {
        _uniswapV2Router = IUniswapV2Router02(router);
        _tokenA = tokenA;
        _tokenB = tokenB;
        _tokenC = tokenC;

        IERC20(tokenB).approve(router, type(uint256).max);
        IERC20(tokenC).approve(router, type(uint256).max);
    }

    function swapTokensAForTokensB(uint256 amountIn)
        external
        returns (uint256 amountOut)
    {
        address[] memory path = new address[](2);
        // gas saving
        IUniswapV2Router02 router = _uniswapV2Router;
        
        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountIn);
        
        if(IERC20(_tokenA).allowance(address(this), address(router)) < amountIn) {
          IERC20(_tokenA).approve(address(router), type(uint256).max);
        }

        path[0] = _tokenA;
        path[1] = _tokenB;

        amountOut = router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp
        )[path.length - 1];

        IERC20(path[path.length - 1]).transfer(msg.sender, amountOut);
    }

    function swapTokensAForTokensCAndBurn(uint256 amountIn) external {
        address[] memory path = new address[](3);
        // gas saving
        IUniswapV2Router02 router = _uniswapV2Router;
        
        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountIn);
        
        if(IERC20(_tokenA).allowance(address(this), address(router)) < amountIn) {
          IERC20(_tokenA).approve(address(router), type(uint256).max);
        }

        path[0] = _tokenA;
        path[1] = _tokenB;
        path[2] = _tokenC;

        router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            _DEAD_ADDRESS,
            block.timestamp
        );
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}