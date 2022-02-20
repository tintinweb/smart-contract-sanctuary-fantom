// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./rarity_extended_farming_base.sol";

contract rarity_extended_farming_base_premium is rarity_extended_farming_base {
    uint256 immutable BASE_UPGRADE_PRICE;
    address immutable REWARD_ADDRESS;

    /*******************************************************************************
    **  @dev Register the farming contract.
    **	@param _rewardAddress: The address that collects upgrade fees for this farm
    **	@param _upgradePrice: Base upgrade cost for this farm (in FTM)
    **	@param _farmingCore: Core farming contract
    **	@param _farmLoot: Loot item farmed by this contract
    **	@param _farmingType: Can be one of theses, but some more may be added
    **	- 1 for wood
    **	- 2 for minerals
    **	@param _requiredLevel: Level required to access this farm
    **	@param _name: Name of this contract
    **	@param _requiredItems: List of loot items required to unlock this farm
    **	@param _requiredItemsCount: Amount of loots required to unlock this farm
    *******************************************************************************/
	constructor(
        address _rewardAddress,
        uint256 _upgradePrice,
        address _farmingCore,
        address _farmLoot,
        uint8 _farmingType,
        uint _requiredLevel,
        string memory _name,
        address[] memory _requiredItems,
        uint[] memory _requiredItemsCount
    ) rarity_extended_farming_base(_farmingCore, _farmLoot, _farmingType, _requiredLevel, _name, _requiredItems, _requiredItemsCount) {
        REWARD_ADDRESS = _rewardAddress;
        BASE_UPGRADE_PRICE = _upgradePrice;
    }

    /*******************************************************************************
    **  @dev Allow an adventurer to unlock the farm if the requirement are met.
    **	@param _adventurer: adventurer we would like to use with this farm
    **	@param _toUpgradeLevel: level to upgrade to
    *******************************************************************************/
	function _beforeUpgrade(uint _adventurer, uint _toUpgradeLevel) internal override {
        uint256 priceToUpgrade = ((_toUpgradeLevel ** 2) * 1e18) - (_toUpgradeLevel * 1e18) + BASE_UPGRADE_PRICE;
        require(msg.value == priceToUpgrade, "!price");
        payable(REWARD_ADDRESS).transfer(priceToUpgrade);
        _adventurer; //silence!
	}

    /*******************************************************************************
    **  @dev Retrieve the price for an upgrade
    **	@param _toUpgradeLevel: level to upgrade to
    *******************************************************************************/
	function upgradePrice(uint _toUpgradeLevel) public view returns (uint256) {
        return ((_toUpgradeLevel ** 2) * 1e18) - (_toUpgradeLevel * 1e18) + BASE_UPGRADE_PRICE;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../rarity.sol";
import "../../interfaces/IrERC20.sol";
import "../../interfaces/IRarityFarmingCore.sol";

contract rarity_extended_farming_base is Rarity {
	uint constant DAY = 1 days; //Duration between two harvest
	uint constant MAX_REWARD_PER_HARVEST = 3; //Base rewards is between 1 and MAX_REWARD_PER_HARVEST 
	uint immutable public typeOf; //Type of farm. 1 for wood, 2 for minerals etc.
	uint public requiredLevel; //Required level to access this farm
	address[] public requiredItems; //What you need to unlock this farm
	uint[] public requiredItemsCount; //How many of what you need you need to unlock this farm
	string public name; //Name of the farm
	IrERC20 immutable farmLoot; //What you will get by using this farm
	IRarityFarmingCore immutable farmingCore; //Farm Core contract

    bool immutable defaultUnlocked; //Is this contract unlocked by default for any adventurer
	mapping(uint => bool) public isUnlocked; //Is this contract unlocked for adventurer uint
	mapping(uint => uint) public nextHarvest; //Next harvest for adventurer
	mapping(uint => uint) public upgradeLevel; //What is the upgrade level for this farm. Premium override.

    event Harvested(uint _adventurer, uint _amount);
    event Unlocked(uint _adventurer);
    event Upgrade(uint _adventurer, uint _level);

    /*******************************************************************************
    **  @dev Register the farming contract.
    **	@param _farmingType: Can be one of theses, but some more may be added
    **	- 1 for wood
    **	- 2 for minerals
    **	@param _farmingCore: Core farming contract
    **	@param _farmLoot: Loot item farmed by this contract
    **	@param _name: Name of this contract
    **	@param _requiredLevel: Level required to access this farm
    **	@param _requiredItems: List of loot items required to unlock this farm
    **	@param _requiredItemsCount: Amount of loots required to unlock this farm
    *******************************************************************************/
	constructor(
        address _farmingCore,
        address _farmLoot,
        uint8 _farmingType,
        uint _requiredLevel,
        string memory _name,
        address[] memory _requiredItems,
        uint[] memory _requiredItemsCount
    ) Rarity(true) {
        require(_requiredItems.length == _requiredItemsCount.length);
		typeOf = _farmingType;
        farmingCore = IRarityFarmingCore(_farmingCore);
        farmLoot = IrERC20(_farmLoot);
        name = _name;
        requiredLevel = _requiredLevel;
		requiredItems = _requiredItems;
		requiredItemsCount = _requiredItemsCount;
        defaultUnlocked = _requiredItems.length == 0;
	}

    /*******************************************************************************
    **  @dev Perform an harvest with an adventurer. You have to be the owner of the
    **  adventurer, nextHarvest should be before now, the requirements must be met.
    **  On success, set the next harvest to now + 1 day and increase XP for this
    **  farming type
    **	@param _adventurer: adventurer we would like to use with this farm
    *******************************************************************************/
    function harvest(uint _adventurer) public {
        require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        require(block.timestamp > nextHarvest[_adventurer], "!nextHarvest");
        require(_rm.level(_adventurer) >= requiredLevel + 1, "!adventurer_level");
        require(farmingCore.level(_adventurer, typeOf) >= requiredLevel, "!level");
		require(isUnlocked[_adventurer] || defaultUnlocked, "!unlocked");
        nextHarvest[_adventurer] = block.timestamp + DAY;
        farmingCore.earnXp(_adventurer);
        uint harvestAmount = _mintFarmLoot(_adventurer);
        emit Harvested(_adventurer, harvestAmount);
    }

    /*******************************************************************************
    **  @dev mint the rewards for the adventurer. The rewards are set in two random
    **  parts, one based on a basic random from 1 to MAX_REWARD_PER_HARVEST, and one
    **  based on adventurer level, from 0 to the level
    **	@param _adventurer: adventurer we would like to use with this farm
    *******************************************************************************/
	function _mintFarmLoot(uint _adventurer) internal returns (uint) {
		uint adventurerLevel = farmingCore.level(_adventurer, typeOf);
		uint farmLootAmount = _get_random(_adventurer, MAX_REWARD_PER_HARVEST, false);
        uint extraFarmLootAmount = _get_random(_adventurer, adventurerLevel, true);
        uint totalFarmLoot = extraFarmLootAmount + (farmLootAmount * (upgradeLevel[_adventurer] + 1));
		farmLoot.mint(_adventurer, totalFarmLoot);
		return totalFarmLoot;
	}

	/*******************************************************************************
	**  @dev Increment the upgrade for a specific adventurer/farm by 1. It will then
	**	increase all the reward from this pool.
    **  The _beforeUpgrade function is called to allow deployer to customize the
    **  upgrade requirements.
	**	@param _adventurer: adventurer to upgrade the farm for
	*******************************************************************************/
	function upgrade(uint _adventurer) public payable {
		require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
        _beforeUpgrade(_adventurer, upgradeLevel[_adventurer] + 1);
        upgradeLevel[_adventurer] += 1;
        emit Upgrade(_adventurer, upgradeLevel[_adventurer]);
	}

	/*******************************************************************************
	**  @dev Fire before an upgrade. It allows the deployer to customize the upgrade
    **  requirements. Default is revert;
	**	@param _adventurer: adventurer to upgrade the farm for
	*******************************************************************************/
    function _beforeUpgrade(uint _adventurer, uint _toUpgradeLevel) internal virtual {
        _adventurer; //silence!
        _toUpgradeLevel; //silence!
        require(false, "no upgrade");
    }

    /*******************************************************************************
    **  @dev Allow an adventurer to unlock the farm if the requirement are met.
    **	@param _adventurer: adventurer we would like to use with this farm
    *******************************************************************************/
	function unlock(uint _adventurer) public {
        require(!defaultUnlocked, "!unlocked");
        require(!isUnlocked[_adventurer], "!unlocked");
		require(_isApprovedOrOwner(_adventurer, msg.sender), "!owner");
		for (uint256 i = 0; i < requiredItems.length; i++) {
			IrERC20(requiredItems[i]).transferFrom(
				RARITY_EXTENDED_NPC,
				_adventurer,
				RARITY_EXTENDED_NPC,
				requiredItemsCount[i]
			);
		}
		isUnlocked[_adventurer] = true;
        emit Unlocked(_adventurer);
	}

    /*******************************************************************************
    **  @dev Estimate the amount of loot the adventurer will get.
    **	@param _adventurer: adventurer we would like to use with this farm
    *******************************************************************************/
	function estimateHarvest(uint _adventurer) public view returns (uint) {
		uint adventurerLevel = farmingCore.level(_adventurer, typeOf);
		uint farmLootAmount = _get_random(_adventurer, MAX_REWARD_PER_HARVEST, false);
        uint extraFarmLootAmount = _get_random(_adventurer, adventurerLevel, true);
		return extraFarmLootAmount + (farmLootAmount * (upgradeLevel[_adventurer] + 1));
	}

    /*******************************************************************************
    **  @dev Indicate is a summonner has access to this farm
    **	@param _adventurer: adventurer we would like to use with this farm
    *******************************************************************************/
	function adventurerHasAccess(uint _adventurer) public view returns (bool) {
        return (
            farmingCore.level(_adventurer, typeOf) >= requiredLevel
            && 
		    isUnlocked[_adventurer] || defaultUnlocked
        );
	}

    /*******************************************************************************
    **  @dev Random number generator
    **	@param _adventurer: some seed
    **	@param _limit: max amount expected
    **	@param _withZero: [0 - X] or [1 - X]
    *******************************************************************************/
    function _get_random(uint _adventurer, uint _limit, bool _withZero) internal view returns (uint) {
        _adventurer += gasleft();
        uint result = 0;
        if (_withZero) {
            if (_limit == 0) {
                return 0;
            }
            result = _random.dn(_adventurer, _limit);
        } else {
            if (_limit == 1) {
                return 1;
            }
            result = _random.dn(_adventurer, _limit);
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "./interfaces/IRarity.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/IrERC721.sol";
import "./interfaces/IRandomCodex.sol";

abstract contract Rarity {
    IRarity constant _rm = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRandomCodex constant _random = IRandomCodex(0x7426dBE5207C2b5DaC57d8e55F0959fcD99661D4);

	uint public RARITY_EXTENDED_NPC;

	constructor(bool requireSummoner) {
		if (requireSummoner) {
        	RARITY_EXTENDED_NPC = IRarity(_rm).next_summoner();
        	IRarity(_rm).summon(8);
		}
	}

	/*******************************************************************************
    **  @dev Check if the _owner has the autorization to act on this adventurer
    **	@param _adventurer: TokenID of the adventurer we want to check
    **	@param _operator: the operator to check
	*******************************************************************************/
    function _isApprovedOrOwner(uint _adventurer, address _operator) internal view returns (bool) {
        return (
			_rm.getApproved(_adventurer) == _operator ||
			_rm.ownerOf(_adventurer) == _operator ||
			_rm.isApprovedForAll(_rm.ownerOf(_adventurer), _operator)
		);
    }

	/*******************************************************************************
    **  @dev Check if the _owner has the autorization to act on this tokenID
    **	@param _tokenID: TokenID of the item we want to check
    **	@param _source: address of contract for tokenID 
    **	@param _operator: the operator to check
	*******************************************************************************/
    function _isApprovedOrOwnerOfItem(uint _tokenID, IERC721 _source, address _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_source.ownerOf(_tokenID), _operator)
        );
    }
    function _isApprovedOrOwnerOfItem(uint256 _tokenID, IrERC721 _source, uint _operator) internal view returns (bool) {
        return (
            _source.ownerOf(_tokenID) == _operator ||
            _source.getApproved(_tokenID) == _operator ||
            _source.isApprovedForAll(_tokenID, _operator)
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IrERC20 {
    function burn(uint from, uint amount) external;
    function mint(uint to, uint amount) external;
    function approve(uint from, uint spender, uint amount) external returns (bool);
    function transfer(uint from, uint to, uint amount) external returns (bool);
    function transferFrom(uint executor, uint from, uint to, uint amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRarityFarmingCore {
    function xp(uint _adventurer, uint _farmType) external view returns (uint);
    function level(uint _adventurer, uint _farmType) external view returns (uint);
	function earnXp(uint _adventurer) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity ^0.8.10;

interface IRarity {
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event leveled(address indexed owner, uint256 level, uint256 summoner);
    event summoned(address indexed owner, uint256 class, uint256 summoner);

    function adventure(uint256 _summoner) external;

    function adventurers_log(uint256) external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function class(uint256) external view returns (uint256);

    function classes(uint256 id)
        external
        pure
        returns (string memory description);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function level(uint256) external view returns (uint256);

    function level_up(uint256 _summoner) external;

    function name() external view returns (string memory);

    function next_summoner() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function spend_xp(uint256 _summoner, uint256 _xp) external;

    function summon(uint256 _class) external;

    function summoner(uint256 _summoner)
        external
        view
        returns (
            uint256 _xp,
            uint256 _log,
            uint256 _class,
            uint256 _level
        );

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _summoner) external view returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function xp(uint256) external view returns (uint256);

    function xp_required(uint256 curent_level)
        external
        pure
        returns (uint256 xp_to_next_level);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"level","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"leveled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"class","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"summoned","type":"event"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"adventure","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"adventurers_log","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"class","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"classes","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"level","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"level_up","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"next_summoner","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_xp","type":"uint256"}],"name":"spend_xp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"summon","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"summoner","outputs":[{"internalType":"uint256","name":"_xp","type":"uint256"},{"internalType":"uint256","name":"_log","type":"uint256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"xp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"curent_level","type":"uint256"}],"name":"xp_required","outputs":[{"internalType":"uint256","name":"xp_to_next_level","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IrERC721 {
    function ownerOf(uint256 tokenId) external view returns (uint);
    function approve(uint from, uint to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (uint);
    function isApprovedForAll(uint owner, uint operator) external view returns (bool);
    function transferFrom(uint operator, uint from, uint to, uint256 tokenId) external;
    function permit(
        uint operator,
        uint from,
		uint to,
        uint256 tokenId,
        uint256 deadline,
        bytes calldata signature
    ) external;
    function nonces(uint owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRandomCodex {
    function dn(uint _summoner, uint _number) external view returns (uint);
}