//RaiderAttributesV1.sol
//SPDX-License-Identifier: MIT
//Author: @Sgt
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/calculations/AttributeCostV1.sol";
import "./lib/calculations/RaiderLevel.sol";
import "./lib/calculations/AttributePointsV1.sol";

interface IRaidersNFT {
    function getClass(uint256 _raiderID) external view returns (uint256);

    function isOwner(address _owner, uint256 _raiderID)
        external
        view
        returns (bool);

    function getExperience(uint256 _raiderID) external view returns (uint256);
}

contract RaiderAttributesV1 is Ownable {
    IRaidersNFT public raidersNFT;

    struct Attributes {
        int32 rclass;
        int32 sol;
        int32 acu;
        int32 dex;
        int32 passive_skill;
        int32 active_skill;
        int32 element;
        int32 talent;
    }

    struct Costs {
        int32 solCost;
        int32 acuCost;
        int32 dexCost;
    }

    address public raidersNFTAddress;
    address public attributeResetterGateway;
    mapping(uint256 => Attributes) public raiderAttributes;
    mapping(uint256 => int256) public attributePointsSpent;
    int256 private currentActiveSkillCount = 2; //first skill library version
    int256 private currentPassiveSkillCount = 2; //first skill library version
    int256 private currentElementCount = 4; //first element library version
    int256 private currentTalentCount = 2; //first talent library version

    constructor(address _raidersNFTAddress) {
        raidersNFTAddress = _raidersNFTAddress;
        raidersNFT = IRaidersNFT(raidersNFTAddress);
    }

    event AttributesChanged(
        uint256 raiderID,
        Attributes attributes,
        int256 points_spent
    );

    function setAttributes(
        uint256 _raiderID,
        int32 sol,
        int32 acu,
        int32 dex,
        int32 pskill,
        int32 askill,
        int32 element,
        int32 talent
    ) public {
        require(
            raidersNFT.isOwner(msg.sender, _raiderID),
            "RaidersNFT: You do not own this raider."
        );

        require(
            sol >= raiderAttributes[_raiderID].sol &&
                acu >= raiderAttributes[_raiderID].acu &&
                dex >= raiderAttributes[_raiderID].dex,
            "RaidersNFT: Cannot deduct from a stat that is already set."
        );
        Costs memory costs = Costs({
            solCost: AttributeCostV1.getAttributeCost(
                raiderAttributes[_raiderID].sol,
                sol
            ),
            acuCost: AttributeCostV1.getAttributeCost(
                raiderAttributes[_raiderID].acu,
                acu
            ),
            dexCost: AttributeCostV1.getAttributeCost(
                raiderAttributes[_raiderID].dex,
                dex
            )
        });

        int256 raiderLevel = int256(getRaiderLevel(_raiderID));

        require(
            (int256(AttributePointsV1.getEarnedPoints(uint256(raiderLevel))) -
                attributePointsSpent[_raiderID]) >=
                (costs.solCost + costs.acuCost + costs.dexCost),
            "RaidersNFT: Insufficient attribute points."
        );
        require(
            isPassiveSkillValid(raiderLevel, pskill),
            "RaidersNFT: Invalid passive skill chosen."
        );
        require(
            isActiveSkillValid(raiderLevel, askill),
            "RaidersNFT: Invalid active skill chosen."
        );
        require(isElementValid(element), "RaidersNFT: Invalid element chosen.");
        require(
            (raiderAttributes[_raiderID].element == 0 ||
                raiderAttributes[_raiderID].element == element),
            "RaidersNFT: Chosen element cannot be reset."
        );
        require(
            isTalentValid(raiderLevel, talent),
            "RaidersNFT: Invalid talent chosen."
        );

        attributePointsSpent[_raiderID] += (costs.solCost +
            costs.acuCost +
            costs.dexCost);

        raiderAttributes[_raiderID] = Attributes({
            rclass: int32(int256(raidersNFT.getClass(_raiderID))),
            sol: sol,
            acu: acu,
            dex: dex,
            passive_skill: pskill,
            active_skill: askill,
            element: element,
            talent: talent
        });

        emit AttributesChanged(
            _raiderID,
            raiderAttributes[_raiderID],
            attributePointsSpent[_raiderID]
        );
    }

    function resetAttributes(uint256 _raiderID) external attributeResetterOnly {
        raiderAttributes[_raiderID] = Attributes({
            rclass: raiderAttributes[_raiderID].rclass,
            sol: 0,
            acu: 0,
            dex: 0,
            passive_skill: 0,
            active_skill: 0,
            element: 0,
            talent: 0
        });
        attributePointsSpent[_raiderID] = 0;
        emit AttributesChanged(_raiderID, raiderAttributes[_raiderID], 0);
    }

    function getRaiderAttributes(uint256 _raiderID)
        external
        view
        returns (int32[8] memory raider_attributes_arr)
    {
        raider_attributes_arr = [
            raiderAttributes[_raiderID].rclass,
            raiderAttributes[_raiderID].sol,
            raiderAttributes[_raiderID].acu,
            raiderAttributes[_raiderID].dex,
            raiderAttributes[_raiderID].passive_skill,
            raiderAttributes[_raiderID].active_skill,
            raiderAttributes[_raiderID].element,
            raiderAttributes[_raiderID].talent
        ];
    }

    function getRaiderLevel(uint256 _raiderID)
        internal
        view
        returns (uint256 level)
    {
        int256 raiderExp = int256(raidersNFT.getExperience(_raiderID));
        level = uint256(RaiderLevel.calculateLevel(raiderExp));
    }

    function isActiveSkillValid(int256 _raiderLevel, int256 skill_id)
        internal
        view
        returns (bool valid_skill)
    {
        int256 currentTier = (_raiderLevel / 10) + 1;
        valid_skill = (skill_id < (currentTier * 2) &&
            skill_id <= currentActiveSkillCount)
            ? true
            : false;
    }

    function increaseActiveSkillCount(int256 updatedSkillCount)
        external
        onlyOwner
    {
        currentActiveSkillCount = updatedSkillCount;
    }

    function isPassiveSkillValid(int256 _raiderLevel, int256 skill_id)
        internal
        view
        returns (bool valid_skill)
    {
        int256 currentTier = (_raiderLevel / 10) + 1;
        valid_skill = (skill_id < (currentTier * 2) &&
            skill_id <= currentPassiveSkillCount)
            ? true
            : false;
    }

    function increasePassiveSkillCount(int256 updatedSkillCount)
        external
        onlyOwner
    {
        currentPassiveSkillCount = updatedSkillCount;
    }

    function isElementValid(int256 _element)
        internal
        view
        returns (bool valid_element)
    {
        valid_element = _element <= currentElementCount ? true : false;
    }

    function increaseElementCount(int256 updatedElementCount)
        external
        onlyOwner
    {
        currentElementCount = updatedElementCount;
    }

    function isTalentValid(int256 _raiderLevel, int256 talent_id)
        internal
        view
        returns (bool valid_talent)
    {
        int256 currentTier = (_raiderLevel / 10) + 1;
        valid_talent = (talent_id < (currentTier * 2) &&
            talent_id <= currentTalentCount)
            ? true
            : false;
    }

    function increaseTalentCount(int256 updatedTalentCount) external onlyOwner {
        currentTalentCount = updatedTalentCount;
    }

    modifier attributeResetterOnly() {
        require(
            msg.sender == attributeResetterGateway,
            "Please use the gateway contract."
        );
        _;
    }

    function setAttributeResetterAddress(address newResetterAddress)
        external
        onlyOwner
    {
        attributeResetterGateway = newResetterAddress;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
}

//AttributeCostV1.sol
//SPDX-License-Identifier: MIT
//Author: @Sgt
pragma solidity ^0.8.7;

library AttributeCostV1 {
    int32 constant COST_MULTIPLIER = 7;

    function getAttributeCostNext(int32 _attributeLevel)
        internal
        pure
        returns (int32 cost)
    {
        cost = _attributeLevel * COST_MULTIPLIER;
    }

    function getAttributeCost(
        int32 _attributeLevelFrom,
        int32 _attributeLevelTo
    ) internal pure returns (int32 cost) {
        for (int32 i = _attributeLevelFrom; i < _attributeLevelTo; i++) {
            cost += i * COST_MULTIPLIER;
        }
        if (_attributeLevelFrom == _attributeLevelTo) {
            cost = 0;
        }
    }
}

//RaiderLevel.sol
//SPDX-License-Identifier: MIT
//Author: @Sgt

pragma solidity ^0.8.7;

library RaiderLevel {
    int256 private constant FIRST_LEVEL_EXP = 1000;

    function calculateLevel(int256 experience)
        internal
        pure
        returns (int256 level)
    {
        int256 expRequired = FIRST_LEVEL_EXP;
        for (level = 1; (experience / expRequired) > 0; level++) {
            experience -= expRequired;
            expRequired = (expRequired * 105) / 100;
        }
    }
}

//AttributePointsV1.sol
//SPDX-License-Identifier: MIT
//Author: @Sgt
pragma solidity ^0.8.7;

library AttributePointsV1 {
    uint256 constant LEVELS_PER_TIER = 10;
    uint256 constant POINTS_PER_TIER = 1328;
    uint256 constant POINTS_FIRST_LEVEL = 300;

    function getEarnedPoints(uint256 _raiderLevel)
        internal
        pure
        returns (uint256 earnedPoints)
    {
        uint256 currentTier = (_raiderLevel / LEVELS_PER_TIER) + 1;
        uint256 tierProgress = _raiderLevel % LEVELS_PER_TIER;
        earnedPoints =
            getPreviousTiersPoints(currentTier) +
            getCurrentTierPoints(tierProgress);
    }

    function getPreviousTiersPoints(uint256 _currentTier)
        internal
        pure
        returns (uint256 previousTiersPoints)
    {
        if (_currentTier == 1) {
            //check if in the first tier. In this case, the raider has no previous tiers.
            previousTiersPoints = 0;
        } else {
            previousTiersPoints = (_currentTier - 1) * POINTS_PER_TIER;
        }
    }

    function getCurrentTierPoints(uint256 _tierProgress)
        internal
        pure
        returns (uint256 currentTierPoints)
    {
        if (_tierProgress == 0) {
            //check if in the last level within a tier. If case is true, skip the loop and return 0.
            currentTierPoints = 0;
        } else {
            uint256 previousLevelPoints = POINTS_FIRST_LEVEL;
            for (uint256 lvl = 1; lvl <= _tierProgress; lvl++) {
                currentTierPoints += previousLevelPoints;
                previousLevelPoints = (previousLevelPoints * 80) / 100;
            }
        }
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