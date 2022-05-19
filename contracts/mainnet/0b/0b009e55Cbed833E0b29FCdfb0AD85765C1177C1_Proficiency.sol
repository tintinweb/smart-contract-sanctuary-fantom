//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Rarity.sol";
import "./Feats.sol";

library Proficiency {
    function is_proficient_with_armor(
        uint256 summoner,
        uint256 proficiency,
        uint256 armor_type
    ) public view returns (bool) {
        uint256 class = Rarity.class(summoner);

        // Barbarian
        if (class == 1) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (
                proficiency == 3 && Feats.armor_proficiency_heavy(summoner)
            ) {
                return true;
            } else if (proficiency == 4) {
                if (armor_type == 18) {
                    return Feats.tower_shield_proficiency(summoner);
                } else {
                    return true;
                }
            }

            // Bard, Ranger
        } else if (class == 2 || class == 8) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (
                (Feats.armor_proficiency_medium(summoner)) ||
                (proficiency == 3 && Feats.armor_proficiency_heavy(summoner))
            ) {
                return true;
            } else if (proficiency == 4) {
                if (armor_type == 18) {
                    return Feats.tower_shield_proficiency(summoner);
                } else {
                    return true;
                }
            }

            // Cleric, Paladin
        } else if (class == 3 || class == 7) {
            if (proficiency == 4 && armor_type == 18) {
                return Feats.tower_shield_proficiency(summoner);
            }
            return true;

            // Druid
        } else if (class == 4) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (
                proficiency == 3 && Feats.armor_proficiency_heavy(summoner)
            ) {
                return true;
            } else if (proficiency == 4) {
                if (armor_type == 18) {
                    return Feats.tower_shield_proficiency(summoner);
                } else {
                    return true;
                }
            }

            // Fighter
        } else if (class == 5) {
            return true;

            // Rogue
        } else if (class == 9) {
            return
                (proficiency == 1) ||
                (proficiency == 2 &&
                    Feats.armor_proficiency_medium(summoner)) ||
                (proficiency == 3 && Feats.armor_proficiency_heavy(summoner)) ||
                (proficiency == 4 &&
                    armor_type == 18 &&
                    Feats.tower_shield_proficiency(summoner)) ||
                (proficiency == 4 && Feats.shield_proficiency(summoner));

            // Monk, Sorcerer, Wizard
        } else if (class == 6 || class == 10 || class == 11) {
            return
                (proficiency == 1 && Feats.armor_proficiency_light(summoner)) ||
                (proficiency == 2 &&
                    Feats.armor_proficiency_medium(summoner)) ||
                (proficiency == 3 && Feats.armor_proficiency_heavy(summoner)) ||
                (proficiency == 4 &&
                    armor_type == 18 &&
                    Feats.tower_shield_proficiency(summoner)) ||
                (proficiency == 4 && Feats.shield_proficiency(summoner));
        }

        return false;
    }

    function is_proficient_with_weapon(
        uint256 summoner,
        uint256 proficiency,
        uint256 weapon_type
    ) public view returns (bool) {
        uint256 class = Rarity.class(summoner);

        // Barbarian, Fighter, Paladin, Ranger
        if (class == 1 || class == 5 || class == 7 || class == 8) {
            if (proficiency == 1 || proficiency == 2) {
                return true;
            } else if (Feats.exotic_weapon_proficiency(summoner)) {
                return true;
            }

            // Bard
        } else if (class == 2) {
            if (proficiency == 1) {
                return true;
            } else if (
                (proficiency == 2 &&
                    Feats.martial_weapon_proficiency(summoner)) ||
                (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
            ) {
                return true;
            } else if (
                weapon_type == 27 || // longsword
                weapon_type == 29 || // rapier
                weapon_type == 23 || // sap
                weapon_type == 24 || // short sword
                weapon_type == 46 // short bow
            ) {
                return true;
            }

            // Cleric, Sorcerer
        } else if (class == 3 || class == 10) {
            if (proficiency == 1) {
                return true;
            } else if (
                (proficiency == 2 &&
                    Feats.martial_weapon_proficiency(summoner)) ||
                (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
            ) {
                return true;
            }

            // Druid, Monk, Wizard
        } else if (class == 4 || class == 6 || class == 11) {
            if (
                (proficiency == 1 &&
                    Feats.simple_weapon_proficiency(summoner)) ||
                (proficiency == 2 &&
                    Feats.martial_weapon_proficiency(summoner)) ||
                (proficiency == 3 && Feats.exotic_weapon_proficiency(summoner))
            ) {
                return true;

                // Druid
            } else if (
                class == 4 &&
                (weapon_type == 6 || // club
                    weapon_type == 2 || // dagger
                    weapon_type == 15 || // dart
                    weapon_type == 11 || // quarterstaff
                    weapon_type == 30 || // scimitar
                    weapon_type == 5 || // sickle
                    weapon_type == 9 || // shortspear
                    weapon_type == 17 || // sling
                    weapon_type == 12) // spear
            ) {
                return true;

                // Monk
            } else if (
                class == 6 &&
                (weapon_type == 6 || // club
                    weapon_type == 14 || // light crossbow
                    weapon_type == 13 || // heavy crossbow
                    weapon_type == 2 || // dagger
                    weapon_type == 20 || // hand axe
                    weapon_type == 16 || // javelin
                    weapon_type == 48 || // kama
                    weapon_type == 49 || // nunchaku
                    weapon_type == 11 || // quarterstaff
                    weapon_type == 50 || // sia
                    weapon_type == 51 || // siangham
                    weapon_type == 17) // sling
            ) {
                return true;

                // Rogue
            } else if (
                class == 9 &&
                (weapon_type <= 17 || // Simple weapons
                    weapon_type == 57 || // hand crossbow
                    weapon_type == 29 || // rapier
                    weapon_type == 23 || // sap
                    weapon_type == 46 || // shortbow
                    weapon_type == 24) // short sword
            ) {
                return true;

                // Wizard
            } else if (
                class == 11 &&
                (weapon_type == 6 || // club
                    weapon_type == 2 || // dagger
                    weapon_type == 13 || // heavy crossbow
                    weapon_type == 14 || // light crossbow
                    weapon_type == 11) // quarterstaff
            ) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/core/IRarity.sol";
import "./Attributes.sol";

library Rarity {
    IRarity constant RARITY =
        IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function level(uint256 summoner) public view returns (uint256) {
        return RARITY.level(summoner);
    }

    function class(uint256 summoner) public view returns (uint256) {
        return RARITY.class(summoner);
    }

    function isApprovedOrOwnerOfSummoner(uint256 summoner)
        public
        view
        returns (bool)
    {
        if (RARITY.getApproved(summoner) == msg.sender) return true;
        address owner = RARITY.ownerOf(summoner);
        return
            owner == msg.sender || RARITY.isApprovedForAll(owner, msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexFeats1.sol";
import "../interfaces/codex/IRarityCodexFeats2.sol";
import "../interfaces/core/IRarityFeats.sol";

library Feats {
    IRarityCodexFeats1 constant CODEX1 =
        IRarityCodexFeats1(0x88db734E9f64cA71a24d8e75986D964FFf7a1E10);
    IRarityCodexFeats2 constant CODEX2 =
        IRarityCodexFeats2(0x7A4Ba2B077CD9f4B13D5853411EcAE12FADab89C);
    IRarityFeats constant FEATS =
        IRarityFeats(0x4F51ee975c01b0D6B29754657d7b3cC182f20d8a);

    function has_feat(uint256 summoner, uint256 feat_id)
        internal
        view
        returns (bool)
    {
        bool[100] memory feats = FEATS.get_feats(summoner);
        return feats[feat_id];
    }

    function improved_initiative(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX1.improved_initiative();
        return has_feat(summoner, id);
    }

    function armor_proficiency_light(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.armor_proficiency_light();
        return has_feat(summoner, id);
    }

    function armor_proficiency_medium(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.armor_proficiency_medium();
        return has_feat(summoner, id);
    }

    function armor_proficiency_heavy(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.armor_proficiency_heavy();
        return has_feat(summoner, id);
    }

    function shield_proficiency(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX1.shield_proficiency();
        return has_feat(summoner, id);
    }

    function tower_shield_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX2.tower_shield_proficiency();
        return has_feat(summoner, id);
    }

    function simple_weapon_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX2.simple_weapon_proficiency();
        return has_feat(summoner, id);
    }

    function martial_weapon_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX2.martial_weapon_proficiency();
        return has_feat(summoner, id);
    }

    function exotic_weapon_proficiency(uint256 summoner)
        public
        view
        returns (bool)
    {
        (uint256 id, , , , , , ) = CODEX1.exotic_weapon_proficiency();
        return has_feat(summoner, id);
    }

    function negotiator(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX2.negotiator();
        return has_feat(summoner, id);
    }

    function investigator(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX2.investigator();
        return has_feat(summoner, id);
    }

    function diligent(uint256 summoner) public view returns (bool) {
        (uint256 id, , , , , , ) = CODEX1.diligent();
        return has_feat(summoner, id);
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

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

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _summoner) external view returns (string memory);

    function totalSupply() external view returns (uint256);

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
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"level","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"leveled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"class","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"summoned","type":"event"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"adventure","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"adventurers_log","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"class","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"classes","outputs":[{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"level","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"level_up","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"next_summoner","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_xp","type":"uint256"}],"name":"spend_xp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"summon","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"summoner","outputs":[{"internalType":"uint256","name":"_xp","type":"uint256"},{"internalType":"uint256","name":"_log","type":"uint256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"xp","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"curent_level","type":"uint256"}],"name":"xp_required","outputs":[{"internalType":"uint256","name":"xp_to_next_level","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/core/IRarityAttributes.sol";

library Attributes {
    IRarityAttributes constant ATTRIBUTES =
        IRarityAttributes(0xB5F5AF1087A8DA62A23b08C00C6ec9af21F397a1);

    struct Abilities {
        uint32 strength;
        uint32 dexterity;
        uint32 constitution;
        uint32 intelligence;
        uint32 wisdom;
        uint32 charisma;
    }

    function strength_modifier(uint256 summoner) public view returns (int8) {
        (uint32 strength, , , , , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(strength);
    }

    function dexterity_modifier(uint256 summoner) public view returns (int8) {
        (, uint32 dexterity, , , , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(dexterity);
    }

    function constitution_modifier(uint256 summoner)
        public
        view
        returns (int8)
    {
        (, , uint32 constitution, , , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(constitution);
    }

    function intelligence_modifier(uint256 summoner)
        public
        view
        returns (int8)
    {
        (, , , uint32 intelligence, , ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(intelligence);
    }

    function wisdom_modifier(uint256 summoner) public view returns (int8) {
        (, , , , uint32 wisdom, ) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(wisdom);
    }

    function charisma_modifier(uint256 summoner) public view returns (int8) {
        (, , , , , uint32 charisma) = ATTRIBUTES.ability_scores(summoner);
        return compute_modifier(charisma);
    }

    function compute_modifier(uint32 ability) public pure returns (int8) {
        if (ability < 10) return -1;
        return (int8(int32(ability)) - 10) / 2;
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityAttributes {
    event Created(
        address indexed creator,
        uint256 summoner,
        uint32 strength,
        uint32 dexterity,
        uint32 constitution,
        uint32 intelligence,
        uint32 wisdom,
        uint32 charisma
    );
    event Leveled(
        address indexed leveler,
        uint256 summoner,
        uint32 strength,
        uint32 dexterity,
        uint32 constitution,
        uint32 intelligence,
        uint32 wisdom,
        uint32 charisma
    );

    function abilities_by_level(uint256 current_level)
        external
        pure
        returns (uint256);

    function ability_scores(uint256)
        external
        view
        returns (
            uint32 strength,
            uint32 dexterity,
            uint32 constitution,
            uint32 intelligence,
            uint32 wisdom,
            uint32 charisma
        );

    function calc(uint256 score) external pure returns (uint256);

    function calculate_point_buy(
        uint256 _str,
        uint256 _dex,
        uint256 _const,
        uint256 _int,
        uint256 _wis,
        uint256 _cha
    ) external pure returns (uint256);

    function character_created(uint256) external view returns (bool);

    function increase_charisma(uint256 _summoner) external;

    function increase_constitution(uint256 _summoner) external;

    function increase_dexterity(uint256 _summoner) external;

    function increase_intelligence(uint256 _summoner) external;

    function increase_strength(uint256 _summoner) external;

    function increase_wisdom(uint256 _summoner) external;

    function level_points_spent(uint256) external view returns (uint256);

    function point_buy(
        uint256 _summoner,
        uint32 _str,
        uint32 _dex,
        uint32 _const,
        uint32 _int,
        uint32 _wis,
        uint32 _cha
    ) external;

    function tokenURI(uint256 _summoner) external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"creator","type":"address"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint32","name":"strength","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"dexterity","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"constitution","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"intelligence","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"wisdom","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"charisma","type":"uint32"}],"name":"Created","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"leveler","type":"address"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint32","name":"strength","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"dexterity","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"constitution","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"intelligence","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"wisdom","type":"uint32"},{"indexed":false,"internalType":"uint32","name":"charisma","type":"uint32"}],"name":"Leveled","type":"event"},{"inputs":[{"internalType":"uint256","name":"current_level","type":"uint256"}],"name":"abilities_by_level","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"ability_scores","outputs":[{"internalType":"uint32","name":"strength","type":"uint32"},{"internalType":"uint32","name":"dexterity","type":"uint32"},{"internalType":"uint32","name":"constitution","type":"uint32"},{"internalType":"uint32","name":"intelligence","type":"uint32"},{"internalType":"uint32","name":"wisdom","type":"uint32"},{"internalType":"uint32","name":"charisma","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"score","type":"uint256"}],"name":"calc","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_str","type":"uint256"},{"internalType":"uint256","name":"_dex","type":"uint256"},{"internalType":"uint256","name":"_const","type":"uint256"},{"internalType":"uint256","name":"_int","type":"uint256"},{"internalType":"uint256","name":"_wis","type":"uint256"},{"internalType":"uint256","name":"_cha","type":"uint256"}],"name":"calculate_point_buy","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"character_created","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_charisma","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_constitution","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_dexterity","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_intelligence","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_strength","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"increase_wisdom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"level_points_spent","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint32","name":"_str","type":"uint32"},{"internalType":"uint32","name":"_dex","type":"uint32"},{"internalType":"uint32","name":"_const","type":"uint32"},{"internalType":"uint32","name":"_int","type":"uint32"},{"internalType":"uint32","name":"_wis","type":"uint32"},{"internalType":"uint32","name":"_cha","type":"uint32"}],"name":"point_buy","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexFeats1 {
    function acrobatic()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function agile()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function alertness()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function animal_affinity()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function armor_proficiency_heavy()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function armor_proficiency_light()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function armor_proficiency_medium()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function athletic()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function augment_summoning()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function blind_fight()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function brew_potion()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function class() external view returns (string memory);

    function cleave()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function combat_casting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function combat_expertise()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function combat_reflexes()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_magic_arms_and_armor()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_rod()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_staff()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_wand()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function craft_wondrous_item()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function deceitful()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function deflect_arrows()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function deft_hands()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function diehard()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function diligent()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function dodge()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function empower_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function endurance()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function enlarge_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function eschew_materials()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function exotic_weapon_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function extend_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function extra_turning()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function far_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function feat_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function forge_ring()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function great_cleave()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function great_fortitude()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_spell_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_spell_peneratrion()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_two_weapon_fighting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_weapon_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function greater_weapon_specialization()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function heighten_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_bull_rush()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_counterspell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_critical()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_disarm()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_feint()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_grapple()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_initiative()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_overrun()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_precise_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_shield_bash()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_two_weapon_fighting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_unarmed_strike()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function index() external view returns (string memory);

    function point_blank_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function power_attack()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function precise_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function shield_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function spell_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function spell_penetration()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function two_weapon_fighting()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function weapon_focus()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function weapon_specialization()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"acrobatic","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"agile","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"alertness","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"animal_affinity","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armor_proficiency_heavy","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armor_proficiency_light","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armor_proficiency_medium","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"athletic","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"augment_summoning","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"blind_fight","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"brew_potion","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"cleave","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"combat_casting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"combat_expertise","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"combat_reflexes","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_magic_arms_and_armor","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_rod","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_staff","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_wand","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft_wondrous_item","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"deceitful","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"deflect_arrows","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"deft_hands","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"diehard","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"diligent","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"dodge","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"empower_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"endurance","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"enlarge_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"eschew_materials","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"exotic_weapon_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"extend_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"extra_turning","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"far_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"feat_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"forge_ring","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"great_cleave","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"great_fortitude","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_spell_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_spell_peneratrion","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_two_weapon_fighting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_weapon_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"greater_weapon_specialization","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"heighten_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_bull_rush","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_counterspell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_critical","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_disarm","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_feint","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_grapple","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_initiative","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_overrun","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_precise_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_shield_bash","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_two_weapon_fighting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_unarmed_strike","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"point_blank_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"power_attack","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"precise_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"shield_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spell_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spell_penetration","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"two_weapon_fighting","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weapon_focus","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weapon_specialization","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexFeats2 {
    function class() external view returns (string memory);

    function feat_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_sunder()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_trip()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function improved_turning()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function index() external view returns (string memory);

    function investigator()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function iron_will()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function lightning_reflexes()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function magical_aptitude()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function manyshot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function martial_weapon_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function maximize_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function mobility()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function mounted_archery()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function mounted_combat()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function negotiator()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function nimble_fingers()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function persuasive()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function quick_draw()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function quicken_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function rapid_reload()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function rapid_shot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function ride_by_attack()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function run()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function scribe_scroll()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function self_sufficient()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function silent_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function simple_weapon_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function spell_penetration()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function stealthy()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function still_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function toughness()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function tower_shield_proficiency()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function two_weapon_defense()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function weapon_finesse()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function widen_spell()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"feat_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_sunder","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_trip","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"improved_turning","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"investigator","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"iron_will","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"lightning_reflexes","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"magical_aptitude","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"manyshot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"martial_weapon_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"maximize_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"mobility","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"mounted_archery","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"mounted_combat","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"negotiator","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"nimble_fingers","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"persuasive","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"quick_draw","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"quicken_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"rapid_reload","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"rapid_shot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"ride_by_attack","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"run","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"scribe_scroll","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"self_sufficient","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"silent_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"simple_weapon_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spell_penetration","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"stealthy","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"still_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"toughness","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"tower_shield_proficiency","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"two_weapon_defense","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weapon_finesse","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"widen_spell","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IRarityFeats {
    function character_created(uint256) external view returns (bool);

    function feat_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            bool prerequisites,
            uint256 prerequisites_feat,
            uint256 prerequisites_class,
            uint256 prerequisites_level,
            string memory benefit
        );

    function feats(uint256, uint256) external view returns (bool);

    function feats_by_id(uint256, uint256) external view returns (uint256);

    function feats_per_class(uint256 _class, uint256 _level)
        external
        pure
        returns (uint256 amount);

    function feats_per_level(uint256 _level)
        external
        pure
        returns (uint256 amount);

    function get_base_class_feats(uint256 _class)
        external
        pure
        returns (uint8[7] memory _feats);

    function get_feats(uint256 _summoner)
        external
        view
        returns (bool[100] memory _feats);

    function get_feats_by_id(uint256 _summoner)
        external
        view
        returns (uint256[] memory _feats);

    function get_feats_by_name(uint256 _summoner)
        external
        view
        returns (string[] memory _names);

    function is_valid(uint256 feat) external pure returns (bool);

    function is_valid_class(uint256 _flag, uint256 _class)
        external
        pure
        returns (bool);

    function select_feat(uint256 _summoner, uint256 _feat) external;

    function setup_class(uint256 _summoner) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"character_created","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"feat_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"bool","name":"prerequisites","type":"bool"},{"internalType":"uint256","name":"prerequisites_feat","type":"uint256"},{"internalType":"uint256","name":"prerequisites_class","type":"uint256"},{"internalType":"uint256","name":"prerequisites_level","type":"uint256"},{"internalType":"string","name":"benefit","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"feats","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"feats_by_id","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"feats_per_class","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"feats_per_level","outputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"get_base_class_feats","outputs":[{"internalType":"uint8[7]","name":"_feats","type":"uint8[7]"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_feats","outputs":[{"internalType":"bool[100]","name":"_feats","type":"bool[100]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_feats_by_id","outputs":[{"internalType":"uint256[]","name":"_feats","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_feats_by_name","outputs":[{"internalType":"string[]","name":"_names","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"feat","type":"uint256"}],"name":"is_valid","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_flag","type":"uint256"},{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"is_valid_class","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_feat","type":"uint256"}],"name":"select_feat","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"setup_class","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/