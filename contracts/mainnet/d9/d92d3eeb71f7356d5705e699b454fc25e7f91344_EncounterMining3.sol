/**
 *Submitted for verification at FtmScan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IRarity {
    function level(uint) external view returns (uint);
    function class(uint) external view returns (uint);
}

struct Ability {
    uint32 strength;
    uint32 dexterity;
    uint32 constitution;
    uint32 intelligence;
    uint32 wisdom;
    uint32 charisma;
}

interface IMonster {
    function hatched(uint) external view returns (bool);
    function monsterAbility(uint) external view returns (Ability memory);
    function monsterCRV(uint) external view returns (uint32);
}

struct ability_score {
    uint32 strength;
    uint32 dexterity;
    uint32 constitution;
    uint32 intelligence;
    uint32 wisdom;
    uint32 charisma;
}

struct VS {
    uint winnerId;
    uint8 winnerRole;
    uint losserId;
    uint8 losserRole;
    uint looted;
}

struct Opponent {
    uint8 oppRole;
    uint oppIndex;        
    uint oppId;
}

interface IRarityAttributes{
    function ability_scores(uint) external view returns (ability_score calldata);    
}

contract EncounterMining3 {
    mapping (uint8 => mapping(uint => address)) public stakedNFT;
    mapping (uint8 => mapping(uint => uint)) public stakingTime;
    mapping(uint8 => address) public roles;
    
    uint private _flag;
    mapping(uint8 => uint) public count;

    mapping (uint8 => mapping(uint => uint)) characterLocation;
    mapping (uint8 => mapping(uint => uint)) locationCharacter;

    address public copperAddress;

    uint public constant fee = 200;
    uint public totalFee;

    // uint public totalTaken;
    uint public constant limit = 100_000_000;
    uint public closeTime;

    uint public lastUpdateTime;
    uint public lastYield;
    uint public totalMined;

    address private owner;

    mapping (uint8 => mapping(uint => uint)) public miningBonus;
    mapping (uint8 => mapping(uint => uint)) public miningYield;

    mapping (uint8 => mapping(uint => uint)) public loot;

    address public rarityAttributes;

    address public gMSTAddress;
    uint public constant gMSTLimitation = 100;

    address public meat;
    uint public constant meatConsumption = 10;
    mapping (uint8 => mapping(uint => uint8)) public adventureCounter;

    uint8 public auctionRoleIndex;
    uint public auctionTokenID;

    bool private initialized;

    event Staked(uint8 indexed roleIndex, uint indexed tokenID, address indexed caller, uint stakingTime, uint yield, uint bonus);
    event Withdrawn(uint8 indexed roleIndex, uint indexed tokenID, address indexed caller, uint leftTime, uint amount);
    event Encountered(uint8 indexed roleIndex, uint indexed tokenID, address indexed caller, uint8 oppRole, uint oppId, int32 MonsterDice, int32 SummonerDice, uint looted);

    function _isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function initialize(address rarity_, address monster_, address copperAddress_, address rarityAttributes_, address gMSTAddress_, address meat_) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        owner = msg.sender;

        roles[1] = rarity_;
        roles[3] = monster_;
        copperAddress = copperAddress_;
        rarityAttributes = rarityAttributes_;
        gMSTAddress = gMSTAddress_;
        meat = meat_;
    }

    function setgmst(address gMSTAddress_) external{
        require(msg.sender == owner, "Only Owner");

        gMSTAddress = gMSTAddress_;
    }

    function _sqrt(uint32 y) internal pure returns (uint32 z) {
        if (y > 3) {
            z = y;
            uint32 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    modifier updateCal() {
        if(closeTime == 0){
            if(lastUpdateTime > 0){
                totalMined += (block.timestamp - lastUpdateTime) * lastYield;
                if(totalMined > limit * 86400) {
                    closeTime = block.timestamp;
                }
            }

            lastUpdateTime = block.timestamp;
        }
        _;
    }

    function _ability_modifier(uint32 _score) private pure returns(int32 _m){
        if(_score >= 10){
            _m = int32((_score-10)/2);
        }else{
            _m = -int32((11-_score)/2);
        }
    }

    function setAuction(uint8 roleIndex_, uint tokenID_) external{
        require(msg.sender == owner, "Only Owner");

        auctionRoleIndex = roleIndex_;
        auctionTokenID = tokenID_;
    }

    function closeMining(uint closeTime_) external{
        require(msg.sender == owner, "Only Owner");

        closeTime = closeTime_;
    }

    function stake(uint8 roleIndex, uint tokenID) external updateCal(){
        require(roleIndex == 1 || roleIndex == 3, "Only Monsters Reborn and heros");
        require(_isApprovedOrOwner(roles[roleIndex], msg.sender, tokenID), "Not approved or owner");
        require(closeTime == 0, "Mining filed closed");
        require(!_isContract(msg.sender), "illegal");

        uint bonus = 0;
        uint yield = 0;

        if(roleIndex == 1) {
            uint heroLevel = IRarity(roles[roleIndex]).level(tokenID);
            require(heroLevel >= 3, "Level requires greater than or equal to 3");

            uint balance = IAssetBox(gMSTAddress).getbalance(roleIndex, tokenID);
            require(balance >= gMSTLimitation, "Not enough gMST");

            yield = balance > 500 ? 1000 : balance * 2;
        }
        
        if(roleIndex == 3) {
            require(IMonster(roles[roleIndex]).hatched(tokenID), "The monster hasn't hatched yet");
            uint32 crv = IMonster(roles[roleIndex]).monsterCRV(tokenID);

            uint32 cr = crv < 7 ? 1 : crv - 6;
            yield = _sqrt(cr * 10000) * 150 / 100;
        }

        miningYield[roleIndex][tokenID] = yield;
        miningBonus[roleIndex][tokenID] = bonus;

        lastYield += (yield + bonus);

        count[roleIndex] += 1;
        locationCharacter[roleIndex][count[roleIndex]] = tokenID;
        characterLocation[roleIndex][tokenID] = count[roleIndex];

        stakedNFT[roleIndex][tokenID] = msg.sender;
        stakingTime[roleIndex][tokenID] = block.timestamp;

        totalFee += fee;
        IAssetBox(copperAddress).burn(roleIndex, tokenID, fee);
        IAssetBox(copperAddress).mint(auctionRoleIndex, auctionTokenID, fee);
        
        IERC721(roles[roleIndex]).transferFrom(msg.sender, address(this), tokenID);

        emit Staked(roleIndex, tokenID, msg.sender, block.timestamp, yield, bonus);
    }

    function _diceRoll(uint roll) private returns (uint){
        _flag ++;
        return uint(keccak256(abi.encodePacked(blockhash(block.number-1), _flag))) % roll + 1;
    }

    function classModifier(uint class, ability_score memory abilityScore) private pure returns (int32) {
        if (class == 1) {
            return _ability_modifier(abilityScore.strength) + _ability_modifier(abilityScore.dexterity) + _ability_modifier(abilityScore.constitution);
        } else if (class == 2) {
            return _ability_modifier(abilityScore.constitution) + _ability_modifier(abilityScore.charisma);
        } else if (class == 3) {
            return _ability_modifier(abilityScore.constitution) + _ability_modifier(abilityScore.wisdom) + _ability_modifier(abilityScore.charisma);
        } else if (class == 4) {
            return _ability_modifier(abilityScore.charisma) + _ability_modifier(abilityScore.wisdom);
        } else if (class == 5) {
            return _ability_modifier(abilityScore.strength) + _ability_modifier(abilityScore.constitution);
        } else if (class == 6) {
            return _ability_modifier(abilityScore.strength) + _ability_modifier(abilityScore.dexterity) + _ability_modifier(abilityScore.constitution);
        } else if (class == 7) {
            return _ability_modifier(abilityScore.strength) + _ability_modifier(abilityScore.constitution) + _ability_modifier(abilityScore.wisdom) + _ability_modifier(abilityScore.charisma);
        } else if (class == 8) {
            return _ability_modifier(abilityScore.strength) + _ability_modifier(abilityScore.dexterity) + _ability_modifier(abilityScore.constitution) + _ability_modifier(abilityScore.wisdom);
        } else if (class == 9) {
            return _ability_modifier(abilityScore.dexterity) + _ability_modifier(abilityScore.constitution);
        } else if (class == 10) {
            return _ability_modifier(abilityScore.dexterity) + _ability_modifier(abilityScore.constitution) + _ability_modifier(abilityScore.charisma);
        } else if (class == 11) {
            return _ability_modifier(abilityScore.dexterity) + _ability_modifier(abilityScore.constitution) + _ability_modifier(abilityScore.intelligence);
        }

        return 0;
    }

    function encounter(uint8 roleIndex, uint tokenId) external {
        require(stakedNFT[roleIndex][tokenId] == msg.sender, "Not yours");
        require(count[1] > 0 && count[3] > 0, "There is no opponents");

        adventureCounter[roleIndex][tokenId] += 1;
        IAssetBox(meat).burn(roleIndex, tokenId, adventureCounter[roleIndex][tokenId] * meatConsumption);

        Opponent memory opp;
        opp.oppRole = roleIndex == 3 ? 1 : 3;
        opp.oppIndex = _diceRoll(count[opp.oppRole]);        
        opp.oppId = locationCharacter[opp.oppRole][opp.oppIndex];

        uint monsterId;
        uint summonerId;
        if (roleIndex == 1) {
            summonerId = tokenId;
            monsterId =  opp.oppId;
        } else {
            summonerId = opp.oppId;
            monsterId =  tokenId;
        }

        Ability memory ability = IMonster(roles[3]).monsterAbility(monsterId);
        ability_score memory abilityScore = IRarityAttributes(rarityAttributes).ability_scores(summonerId);
        
        int32 monsterDice = _ability_modifier(ability.dexterity > 22 ? 22 : ability.dexterity) 
            + _ability_modifier(ability.strength > 22 ? 22 : ability.strength)
            + _ability_modifier(ability.wisdom > 22 ? 22 : ability.wisdom)
            + int32(uint32(_diceRoll(20)));
        
        int32 summonerDice = classModifier(IRarity(roles[1]).class(summonerId), abilityScore) + int32(uint32(_diceRoll(20)));

        if (opp.oppRole == 1) {
            summonerDice += int32(uint32(_diceRoll(6)));
        } else {
            monsterDice += int32(uint32(_diceRoll(6)));
        }

        VS memory vs;
        if (monsterDice > summonerDice) {
            vs.winnerId = monsterId;
            vs.winnerRole = 3;
            vs.losserId = summonerId;
            vs.losserRole = 1;
        } else {
            vs.winnerId = summonerId;
            vs.winnerRole = 1;
            vs.losserId = monsterId;
            vs.losserRole = 3;
        }

        vs.looted = getMinedAndLooted(vs.losserRole, vs.losserId);
        loot[vs.winnerRole][vs.winnerId] += vs.looted;
        loot[vs.losserRole][vs.losserId] = 0;
        stakingTime[vs.losserRole][vs.losserId] = block.timestamp;
        
        emit Encountered(roleIndex, tokenId, msg.sender, opp.oppRole, opp.oppId, monsterDice, summonerDice, vs.looted);
    }

    function getMinedAndLooted(uint8 roleIndex, uint tokenId) public view returns(uint){
        uint stakingStart = stakingTime[roleIndex][tokenId];

        if (stakingStart == 0){
            return 0;
        }

        uint stakingEnd = closeTime == 0 ? block.timestamp : closeTime;

        if (stakingEnd < stakingStart) {
            stakingStart = stakingEnd;
        }

        uint mined = (stakingEnd - stakingStart) * (miningYield[roleIndex][tokenId] + miningBonus[roleIndex][tokenId]) / 86400;

        return mined + loot[roleIndex][tokenId];
    }

    function withdrawal(uint8 roleIndex, uint tokenId) external updateCal(){
        require(stakedNFT[roleIndex][tokenId] == msg.sender, "Not yours");

        uint mined = getMinedAndLooted(roleIndex, tokenId);
        // totalTaken += mined;
        loot[roleIndex][tokenId] = 0;
        IAssetBox(copperAddress).mint(roleIndex, tokenId, mined);

        stakedNFT[roleIndex][tokenId] = address(0);
        stakingTime[roleIndex][tokenId] = 0;

        uint loc = characterLocation[roleIndex][tokenId];
        uint last = locationCharacter[roleIndex][count[roleIndex]];
        locationCharacter[roleIndex][loc] = last;
        characterLocation[roleIndex][last] = loc;

        count[roleIndex] -= 1;
        adventureCounter[roleIndex][tokenId] = 0;

        lastYield -= (miningYield[roleIndex][tokenId] + miningBonus[roleIndex][tokenId]);

        IERC721(roles[roleIndex]).transferFrom(address(this), msg.sender, tokenId);

        emit Withdrawn(roleIndex, tokenId, msg.sender, block.timestamp, mined);
    }

    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }
    
}