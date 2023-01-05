// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import './interface/IVoting.sol';

/** HECTOR VOTING CONTRACT **/
contract Voting is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	string public version;
	IERC20Upgradeable public HEC; // HEC
	IERC20Upgradeable internal sHEC; // sHEC
	wsHEC internal wsHec; // wsHEC
	TokenVault internal tokenVault;

	struct FarmInfo {
		address voter;
		LockFarm _lockFarm;
		uint256 _farmWeight;
		uint256 time;
	}

	uint256 public totalWeight; // Total weights of the farms
	uint256 public maxPercentage; // Max percentage for each farm
	uint256 public voteDelay; // Production Mode
	uint256 public totalFarmVoteCount; // Total farm voted count

	mapping(LockFarm => uint256) public farmWeights; // Return farm weights
	LockFarm[] public farms; // Farms array
	mapping(LockFarm => bool) public farmStatus; // Return status of the farm
	mapping(LockFarm => FNFT) public fnft; // Return FNFT for each LockFarm
	mapping(LockFarm => IERC20Upgradeable) public stakingToken; // Return staking token for eack LockFarm
	mapping(address => string) public stakingTokenSymbol; // Return symbol for staking token
	mapping(IERC20Upgradeable => LockFarm) public lockFarmByERC20; // Return staking token for each LockFarm
	mapping(LockFarm => LockAddressRegistry) public lockAddressRegistry; // Return LockAddressRegistry by LockFarm
	mapping(FNFT => bool) public canVoteByFNFT; // Return status of user can vote by FNFT
	mapping(FNFT => mapping(uint256 => uint256)) public lastVotedByFNFT; // Return last time of voted FNFT
	mapping(uint256 => FarmInfo) public farmInfos;
	mapping(address => mapping(LockFarm => uint256)) public userWeight; // Return user's voting weigths by lockfarm
	mapping(address => uint256) public totalUserWeight; // Return total user's voting weigths
	mapping(address => bool) public lpTokens; // Return status of the lpToken
	uint256 public voteResetIndex;
	uint256 public lastTimeByOwner;

	// Modifiers
	modifier hasVoted(
		address voter,
		FNFT _fnft,
		uint256[] memory fnftIds
	) {
		bool flag = true;
		for (uint256 i = 0; i < getFarmsLength(); i++) {
			LockFarm _lockFarm = getFarmsByIndex(i);
			if (address(_fnft) != address(0) && address(_lockFarm) != address(0) && fnftIds.length > 0) {
				for (uint256 j = 0; j < fnftIds.length; j++) {
					require(_fnft.ownerOf(fnftIds[j]) == voter, 'FNFT: Invalid owner');
					uint256 lastVoted = lastVotedByFNFT[_fnft][fnftIds[j]]; // time of the last voted
					uint256 time = block.timestamp - lastVoted;
					if (time < voteDelay) {
						flag = false;
						break;
					}
				}
			}
		}
		require(flag, 'You voted in the last voted period days');
		_;
	}

	/**
	 * @dev sets initials
	 */
	function initialize(
		string memory _version,
		address _hec,
		address _sHec,
		address _wsHec,
		TokenVault _tokenVault,
		uint256 _maxPercentage,
		uint256 _voteDelay
	) public initializer {
		version = _version;
		HEC = IERC20Upgradeable(_hec);
		sHEC = IERC20Upgradeable(_sHec);
		wsHec = wsHEC(_wsHec);
		tokenVault = _tokenVault;
		maxPercentage = _maxPercentage;
		voteDelay = _voteDelay;
		__Context_init_unchained();
		__Ownable_init_unchained();
		__ReentrancyGuard_init_unchained();
	}

	// Return the farms list
	function getFarms() public view returns (LockFarm[] memory) {
		LockFarm[] memory tempFarms = new LockFarm[](farms.length);
		for (uint256 i = 0; i < farms.length; i++) {
			if (farmStatus[farms[i]]) tempFarms[i] = farms[i];
		}
		return tempFarms;
	}

	// Return the farm by index
	function getFarmsByIndex(uint256 index) internal view returns (LockFarm) {
		LockFarm[] memory tempFarms = new LockFarm[](farms.length);
		for (uint256 i = 0; i < farms.length; i++) {
			if (farmStatus[farms[i]]) tempFarms[i] = farms[i];
		}
		return tempFarms[index];
	}

	// Return farms length
	function getFarmsLength() public view returns (uint256) {
		LockFarm[] memory _farms = getFarms();
		return _farms.length;
	}

	// Reset every new tern if thers are some old voting history
	function reset() internal {
		if (totalFarmVoteCount > 0) {
			uint256 lastIndex = voteResetIndex;
			uint256 resetedWeights;
			for (uint256 i = voteResetIndex; i < totalFarmVoteCount; i++) {
				uint256 time = block.timestamp - farmInfos[i].time;
				if (time > voteDelay) {
					LockFarm _farm = farmInfos[i]._lockFarm;
					uint256 _votes = farmInfos[i]._farmWeight;
					address _voter = farmInfos[i].voter;
					totalWeight = totalWeight - _votes;
					farmWeights[_farm] = farmWeights[_farm] - _votes;
					userWeight[_voter][_farm] = userWeight[_voter][_farm] - _votes;
					totalUserWeight[_voter] = totalUserWeight[_voter] - _votes;
					lastIndex = i + 1;
					resetedWeights += _votes;
				}
			}

			if (voteResetIndex != lastIndex) voteResetIndex = lastIndex;

			emit Reset(voteResetIndex, resetedWeights);
		}
	}

	// Verify farms array is valid
	function validFarms(LockFarm[] memory _farms) internal view returns (bool) {
		bool flag = true;
		LockFarm prevFarm = _farms[0];
		// Check new inputted address is already existed on Voting farms array
		for (uint256 i = 1; i < _farms.length; i++) {
			if (prevFarm == _farms[i]) {
				flag = false;
				break;
			}
			prevFarm = _farms[i];
		}
		// Check Farms Status
		for (uint256 i = 0; i < _farms.length; i++) {
			if (!farmStatus[_farms[i]]) {
				flag = false;
				break;
			}
		}
		return flag;
	}

	// Check farm is already existed when admin added
	function validFarm(LockFarm _farm) internal view returns (bool) {
		bool flag = true;
		LockFarm[] memory _farms = getFarms();
		// Check new inputted address is already existed on Voting farms array
		for (uint256 i = 0; i < _farms.length; i++) {
			if (_farm == _farms[i]) {
				flag = false;
				break;
			}
		}
		return flag;
	}

	// Verify farm's percentage is valid
	function validPercentageForFarms(uint256[] memory _weights) internal view returns (bool) {
		bool flag = true;
		for (uint256 i = 0; i < _weights.length; i++) {
			if (_weights[i] > maxPercentage) {
				flag = false;
				break;
			}
		}
		return flag;
	}

	function _vote(
		address _owner,
		LockFarm[] memory _farmVote,
		uint256[] memory _weights,
		FNFT _fnft,
		uint256[] memory _fnftIds
	) internal {
		uint256 _weight = getWeightByUser(_fnft, _fnftIds);
		uint256 _totalVotePercentage = 0;

		for (uint256 i = 0; i < _farmVote.length; i++) {
			_totalVotePercentage = _totalVotePercentage.add(_weights[i]);
		}
		require(_totalVotePercentage == 100, 'Weights total percentage is not 100%');

		// Reset every term for old data
		reset();

		for (uint256 i = 0; i < _farmVote.length; i++) {
			LockFarm _farm = _farmVote[i];
			uint256 _farmWeight = _weights[i].mul(_weight).div(_totalVotePercentage);
			totalWeight = totalWeight.add(_farmWeight);
			farmWeights[_farm] = farmWeights[_farm].add(_farmWeight);
			userWeight[_owner][_farm] = userWeight[_owner][_farm] + _farmWeight;
			totalUserWeight[_owner] = totalUserWeight[_owner] + _farmWeight;

			// Store all voting infos
			farmInfos[totalFarmVoteCount] = FarmInfo(_owner, _farm, _farmWeight, block.timestamp);

			totalFarmVoteCount++;
		}

		for (uint256 j = 0; j < _fnftIds.length; j++) {
			lastVotedByFNFT[_fnft][_fnftIds[j]] = block.timestamp;
		}

		emit FarmVoted(_owner);
	}

	function _voteByTime(
		address _owner,
		LockFarm[] memory _farmVote,
		uint256[] memory _weights,
		FNFT _fnft,
		uint256[] memory _fnftIds,
		uint256 time
	) internal {
		uint256 _weight = getWeightByUser(_fnft, _fnftIds);
		uint256 _totalVotePercentage = 0;

		for (uint256 i = 0; i < _farmVote.length; i++) {
			_totalVotePercentage = _totalVotePercentage.add(_weights[i]);
		}
		require(_totalVotePercentage == 100, 'Weights total percentage is not 100%');

		// Reset every term for old data
		reset();

		for (uint256 i = 0; i < _farmVote.length; i++) {
			LockFarm _farm = _farmVote[i];
			uint256 _farmWeight = _weights[i].mul(_weight).div(_totalVotePercentage);
			totalWeight = totalWeight.add(_farmWeight);
			farmWeights[_farm] = farmWeights[_farm].add(_farmWeight);
			userWeight[_owner][_farm] = userWeight[_owner][_farm] + _farmWeight;
			totalUserWeight[_owner] = totalUserWeight[_owner] + _farmWeight;

			if (_farmWeight != 0) {
				// Store all voting infos
				farmInfos[totalFarmVoteCount] = FarmInfo(_owner, _farm, _farmWeight, time);
				totalFarmVoteCount++;
			}
		}

		for (uint256 j = 0; j < _fnftIds.length; j++) {
			lastVotedByFNFT[_fnft][_fnftIds[j]] = time;
		}

		emit FarmVoted(_owner);
	}

	// Can vote by owner
	function canVote(address owner) public view returns (bool) {
		// Check Farm is existed
		if (getFarmsLength() == 0) return false;
		// Check status by user
		bool _checkBalanceFNFT = checkBalanceFNFT(owner);

		if (!_checkBalanceFNFT) return false;
		else if (_checkBalanceFNFT) {
			bool _checkVotedFNFT = checkVotedFNFT(owner);

			if (_checkVotedFNFT) return true;
			return false;
		} else return false;
	}

	// Check Locked FNFT in voting
	function checkBalanceFNFT(address owner) internal view returns (bool _flag) {
		bool flag = false;
		// FNFT balance
		for (uint256 i = 0; i < getFarmsLength(); i++) {
			LockFarm _lockFarm = getFarmsByIndex(i);
			uint256 lockedFNFTBalance = getCurrentLockedFNFT(owner, _lockFarm);
			if (lockedFNFTBalance > 0) {
				flag = true;
				break;
			}
		}
		return flag;
	}

	// Check Locked FNFT in voting
	function checkVotedFNFT(address owner) internal view returns (bool _flag) {
		bool flag = false;
		for (uint256 i = 0; i < getFarmsLength(); i++) {
			LockFarm _lockFarm = getFarmsByIndex(i);
			FNFT fNFT = FNFT(fnft[_lockFarm]);
			if (canVoteByFNFT[fNFT]) {
				FNFTInfo[] memory fInfo = _lockFarm.getFnfts(owner);
				for (uint256 j = 0; j < fInfo.length; j++) {
					uint256 lastVoted = lastVotedByFNFT[fNFT][fInfo[j].id]; // time of the last voted
					uint256 time = block.timestamp - lastVoted;
					if (time > voteDelay && fInfo[j].amount > 0) {
						flag = true;
						break;
					}
				}
			}
		}
		return flag;
	}

	// Check Locked FNFT in voting
	function getCurrentLockedFNFT(address owner, LockFarm _lockFarm)
		internal
		view
		returns (uint256 _lockedFNFBalance)
	{
		uint256 lockedFNFTBalance = 0;

		// Check FNFT Balance
		FNFT fNFT = fnft[_lockFarm];
		if (canVoteByFNFT[fNFT]) {
			FNFTInfo[] memory fInfo = _lockFarm.getFnfts(owner);
			for (uint256 i = 0; i < fInfo.length; i++) {
				lockedFNFTBalance += fInfo[i].amount;
			}
		}
		return lockedFNFTBalance;
	}

	// Compare Text
	function compareStringsbyBytes(string memory s1, string memory s2) internal pure returns (bool) {
		return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
	}

	// Get weight for voting
	function getWeightByUser(FNFT _fnft, uint256[] memory _fnftIds) internal view returns (uint256) {
		uint256 totalWeightByUser = 0;
		uint256 weightByFNFT = 0;

		// Calculate of FNFT weight if there is FNFT voted
		if (
			address(_fnft) != address(0) &&
			compareStringsbyBytes(_fnft.symbol(), 'HFNFT') &&
			_fnftIds.length > 0
		) {
			for (uint256 j = 0; j < _fnftIds.length; j++) {
				uint256 _lockedAmount = tokenVault.getFNFT(_fnftIds[j]).depositAmount;
				IERC20Upgradeable _erc20Token = IERC20Upgradeable(tokenVault.getFNFT(_fnftIds[j]).asset);
				uint256 calcAmount = convertToHEC(address(_erc20Token), _lockedAmount);
				weightByFNFT += calcAmount;
			}
		}
		totalWeightByUser = weightByFNFT;

		return totalWeightByUser;
	}

	// Return HEC amount of the ERC20 token converted
	function convertToHEC(address _stakingToken, uint256 _amount) public view returns (uint256) {
		uint256 hecWeight = 0;
		// Can input token can be weights
		ERC20Upgradeable sToken = ERC20Upgradeable(address(_stakingToken));
		if (
			_stakingToken != address(0) &&
			compareStringsbyBytes(stakingTokenSymbol[address(_stakingToken)], sToken.symbol())
		) {
			IERC20Upgradeable _token = IERC20Upgradeable(_stakingToken);
			if (address(lockFarmByERC20[_token]) != address(0) && checkLPTokens(_stakingToken)) {
				SpookySwapPair _lpToken = SpookySwapPair(_stakingToken);
				// HEC LP
				(uint256 reserve0, uint256 reserve1, ) = _lpToken.getReserves();
				uint256 amount0 = (_amount * reserve0) / _lpToken.totalSupply();
				uint256 amount1 = (_amount * reserve1) / _lpToken.totalSupply();

				if (_lpToken.token0() == address(HEC)) {
					hecWeight = amount0;
				}

				if (_lpToken.token1() == address(HEC)) {
					hecWeight = amount1;
				}
			}

			if (
				address(lockFarmByERC20[_token]) != address(0) &&
				(address(_stakingToken) == address(HEC) || address(_stakingToken) == address(sHEC))
			) {
				// HEC, sHEC
				hecWeight = _amount;
			}

			if (
				address(lockFarmByERC20[_token]) != address(0) && address(_stakingToken) == address(wsHec)
			) {
				// wsHEC
				hecWeight = wsHec.wsHECTosHEC(_amount);
			}
		}

		return hecWeight;
	}

	// Add HEC LP tokens
	function addLPTokens(address _lpToken, bool _status) external onlyOwner returns (address, bool) {
		lpTokens[_lpToken] = _status;
		emit AddLPToken(_lpToken, _status);
		return (_lpToken, _status);
	}

	// Check HEC LP tokens
	function checkLPTokens(address _lpToken) public view returns (bool) {
		return lpTokens[_lpToken];
	}

	// Get locked FNFT IDs by Owner
	function getLockedFNFTInfos(address owner, FNFT _fnft)
		external
		view
		returns (LockedFNFTInfo[] memory _lockedFNFTInfos)
	{
		uint256 fnftBalance = _fnft.balanceOf(owner);
		uint256 countOfLockedFNFTInfos = getCountLockedFNFTInfos(owner, _fnft);

		LockedFNFTInfo[] memory lockedFNFTInfos = new LockedFNFTInfo[](countOfLockedFNFTInfos);
		// Get All Balance By user both of HEC and FNFT
		for (uint256 i = 0; i < fnftBalance; i++) {
			// FNFTInfoByUser memory fnftInfo;
			uint256 tokenOfOwnerByIndex = _fnft.tokenOfOwnerByIndex(owner, i);
			uint256 lastVoted = lastVotedByFNFT[_fnft][tokenOfOwnerByIndex]; // time of the last voted
			uint256 time = block.timestamp - lastVoted;
			if (time < voteDelay) {
				lockedFNFTInfos[i] = LockedFNFTInfo(tokenOfOwnerByIndex, lastVoted + voteDelay);
			}
		}
		return lockedFNFTInfos;
	}

	// Count of the locked FNFT infos
	function getCountLockedFNFTInfos(address owner, FNFT _fnft) internal view returns (uint256) {
		uint256 fnftBalance = _fnft.balanceOf(owner);
		uint256 countOfLockedFNFTInfos = 0;

		// Get count of all Balance By user both of HEC and FNFT
		for (uint256 i = 0; i < fnftBalance; i++) {
			// FNFTInfoByUser memory fnftInfo;
			uint256 tokenOfOwnerByIndex = _fnft.tokenOfOwnerByIndex(owner, i);
			uint256 lastVoted = lastVotedByFNFT[_fnft][tokenOfOwnerByIndex]; // time of the last voted
			uint256 time = block.timestamp - lastVoted;
			if (time < voteDelay) {
				countOfLockedFNFTInfos++;
			}
		}
		return countOfLockedFNFTInfos;
	}

	// Get available FNFT IDs by Owner
	function getFNFTByUser(address owner, FNFT _fnft)
		external
		view
		returns (FNFTInfoByUser[] memory _fnftInfos)
	{
		uint256 fnftBalance = _fnft.balanceOf(owner);
		FNFTInfoByUser[] memory fnftInfos = new FNFTInfoByUser[](fnftBalance);
		// Get All Balance By user both of HEC and FNFT
		for (uint256 i = 0; i < fnftBalance; i++) {
			// FNFTInfoByUser memory fnftInfo;
			uint256 tokenOfOwnerByIndex = _fnft.tokenOfOwnerByIndex(owner, i);
			uint256 lastVoted = lastVotedByFNFT[_fnft][tokenOfOwnerByIndex]; // time of the last voted
			address _stakingToken = tokenVault.getFNFT(tokenOfOwnerByIndex).asset;
			uint256 _stakingAmount = tokenVault.getFNFT(tokenOfOwnerByIndex).depositAmount;
			uint256 time = block.timestamp - lastVoted;
			if (time > voteDelay) {
				fnftInfos[i] = FNFTInfoByUser(tokenOfOwnerByIndex, _stakingToken, _stakingAmount);
			}
		}
		return fnftInfos;
	}

	// Get each farm's weights
	function getFarmsWeights() external view returns (uint256[] memory) {
		LockFarm[] memory _validFarms = getFarms();
		uint256[] memory _validFarmsWeights = new uint256[](_validFarms.length);
		for (uint256 i = 0; i < _validFarms.length; i++) {
			_validFarmsWeights[i] = farmWeights[_validFarms[i]];
		}
		return _validFarmsWeights;
	}

	// Return weight percentage for each lockfarm
	function getFarmsWeightPercentages()
		external
		view
		returns (LockFarm[] memory _farms, uint256[] memory _weightPercentages)
	{
		LockFarm[] memory _validFarms = getFarms();
		uint256[] memory _validFarmsWeights = new uint256[](_validFarms.length);

		for (uint256 i = 0; i < _validFarms.length; i++) {
			_validFarmsWeights[i] = farmWeights[_validFarms[i]].mul(10000).div(totalWeight);
		}

		return (_validFarms, _validFarmsWeights);
	}

	// Vote
	function vote(
		LockFarm[] calldata _farmVote,
		uint256[] calldata _weights,
		FNFT _fnft,
		uint256[] memory _fnftIds
	) external hasVoted(msg.sender, _fnft, _fnftIds) {
		require(canVote(msg.sender), "Can't participate in voting system");
		require(_farmVote.length == _weights.length, 'Farms and Weights length size are difference');
		require(_farmVote.length == getFarmsLength(), 'Invalid Farms length');
		require(validFarms(_farmVote), 'Invalid Farms');
		require(validPercentageForFarms(_weights), 'One of Weights exceeded max limit');

		// Vote
		_vote(msg.sender, _farmVote, _weights, _fnft, _fnftIds);
	}

	// Vote
	function voteByTime(
		address owner,
		LockFarm[] calldata _farmVote,
		uint256[] calldata _weights,
		FNFT _fnft,
		uint256[] memory _fnftIds,
		uint256 time
	) external onlyOwner {
		lastTimeByOwner = time;
		// Vote
		_voteByTime(owner, _farmVote, _weights, _fnft, _fnftIds, time);
	}

	// Add new lock farm
	function addLockFarmForOwner(
		LockFarm _lockFarm,
		IERC20Upgradeable _stakingToken,
		LockAddressRegistry _lockAddressRegistry
	) external onlyOwner returns (LockFarm) {
		require(validFarm(_lockFarm), 'Already existed farm');

		farms.push(_lockFarm);
		farmStatus[_lockFarm] = true;
		lockAddressRegistry[_lockFarm] = _lockAddressRegistry;
		stakingToken[_lockFarm] = _stakingToken;
		ERC20Upgradeable sToken = ERC20Upgradeable(address(_stakingToken));
		stakingTokenSymbol[address(_stakingToken)] = sToken.symbol();

		address fnftAddress = _lockAddressRegistry.getFNFT();
		fnft[_lockFarm] = FNFT(fnftAddress);
		lockFarmByERC20[_stakingToken] = _lockFarm;

		// can participate in voting system by FNFT and ERC20 at first
		canVoteByFNFT[fnft[_lockFarm]] = true;

		emit FarmAddedByOwner(_lockFarm);
		return _lockFarm;
	}

	// Deprecate existing farm
	function deprecateFarm(LockFarm _farm) external onlyOwner {
		require(farmStatus[_farm], 'farm is not active');
		farmStatus[_farm] = false;
		emit FarmDeprecated(_farm);
	}

	// Bring Deprecated farm back into use
	function resurrectFarm(LockFarm _farm) external onlyOwner {
		require(!farmStatus[_farm], 'farm is active');
		farmStatus[_farm] = true;
		emit FarmResurrected(_farm);
	}

	// Set configuration
	function setConfiguration(
		address _hec,
		address _sHec,
		address _wsHec,
		TokenVault _tokenVault
	) external onlyOwner {
		HEC = IERC20Upgradeable(_hec);
		sHEC = IERC20Upgradeable(_sHec);
		wsHec = wsHEC(_wsHec);
		tokenVault = _tokenVault;
		emit SetConfiguration(msg.sender);
	}

	// Set max percentage of the farm
	function setMaxPercentageFarm(uint256 _percentage) external onlyOwner {
		maxPercentage = _percentage;
		emit SetMaxPercentageFarm(_percentage, msg.sender);
	}

	// Set Vote Delay
	function setVoteDelay(uint256 _voteDelay) external onlyOwner {
		voteDelay = _voteDelay;
		emit SetVoteDelay(_voteDelay, msg.sender);
	}

	// Set status of the FNFT can participate in voting system by admin
	function setStatusFNFT(FNFT _fnft, bool status) public onlyOwner returns (FNFT) {
		canVoteByFNFT[_fnft] = status;
		emit SetStatusFNFT(_fnft, status);
		return _fnft;
	}

	// Set Vote Delay
	function setVersion(string memory _version) external onlyOwner {
		version = _version;
		emit SetVersion(_version, msg.sender);
	}

	// All events
	event FarmVoted(address owner);
	event FarmAddedByOwner(LockFarm farm);
	event FarmDeprecated(LockFarm farm);
	event FarmResurrected(LockFarm farm);
	event SetConfiguration(address admin);
	event SetMaxPercentageFarm(uint256 percentage, address admin);
	event SetVoteDelay(uint256 voteDelay, address admin);
	event SetStatusFNFT(FNFT farm, bool status);
	event SetStatusERC20(IERC20Upgradeable farm, bool status);
	event SetVersion(string version, address admin);
	event AddLPToken(address lpToken, bool status);
	event Reset(uint256 lastIndex, uint256 resetedAmounts);
	event Withdraw(address[] stakingTokens, uint256[] amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Structure of FNFT
struct FNFTInfo {
    uint256 id;
    uint256 amount;
    uint256 startTime;
    uint256 secs;
    uint256 multiplier;
    uint256 rewardDebt;
    uint256 pendingReward;
}

// Structure of FNFT voted info
struct FNFTInfoByUser {
    uint256 fnftId; // FNFT id
    address stakingToken; // The token being stored
    uint256 depositAmount; // How many tokens
}

// Structure of locked FNFT info
struct LockedFNFTInfo {
    uint256 id; // FNFT id
    uint256 endTime; // The token being stored
}

// Interface of the LockFarm
interface LockFarm {
    function fnfts(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function pendingReward(uint256 fnftId)
        external
        view
        returns (uint256 reward);

    function getFnfts(address owner)
        external
        view
        returns (FNFTInfo[] memory infos);

    function totalTokenSupply()
        external
        view
        returns (uint256 _totalTokenSupply);
}

// Interface of the FNFT
interface FNFT {
    function balanceOf(address) external view returns (uint256);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function symbol() external view returns (string memory);
}

// Interface of the LockAddressRegistry
interface LockAddressRegistry {
    function getTokenVault() external view returns (address);

    function getEmissionor() external view returns (address);

    function getFNFT() external view returns (address);
}

// Interface of the SpookySwap Liqudity ERC20
interface SpookySwapPair {
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function symbol() external view returns (string memory);
}

// Interface of the SpookySwap Factory
interface SpookySwapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// Interface of the SpookySwap Router
interface SpookySwapRouter {
    function WETH() external view returns (address weth);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// Interface of the wsHEC
interface wsHEC {
    function wsHECTosHEC(uint256 _amount) external view returns (uint256);
}

// Interface of the TokenVault
interface TokenVault {
    struct FNFTConfig {
        address asset; // The token being stored
        uint256 depositAmount; // How many tokens
        uint256 endTime; // Time lock expiry
    }

    function getFNFT(uint256 fnftId) external view returns (FNFTConfig memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
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
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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