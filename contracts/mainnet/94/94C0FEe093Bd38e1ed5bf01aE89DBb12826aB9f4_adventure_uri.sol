//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Base64.sol";
import "../library/Codex.sol";
import "../library/Combat.sol";
import "../library/Crafting.sol";
import "../library/Equipment.sol";
import "../library/Monster.sol";
import "../library/StringUtil.sol";

library adventure_uri {
    address constant RARITY =
        address(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRarityEquipment constant EQUIPMENT =
        IRarityEquipment(0xB6Ee6A99d474a30C9C407E7f32a88fF82071FDC0);

    struct Adventure {
        bool dungeon_entered;
        bool combat_ended;
        bool search_check_rolled;
        bool search_check_succeeded;
        bool search_check_critical;
        uint8 monster_count;
        uint8 monsters_defeated;
        uint8 combat_round;
        uint64 started;
        uint64 ended;
        uint256 summoner;
    }

    function tokenURI(
        uint256 token,
        Adventure memory adventure,
        Combat.Combatant[] memory turn_order,
        Equipment.Slot[3] memory loadout,
        uint8[] memory monsters
    ) public view returns (string memory) {
        uint256 y = 0;
        string
            memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';

        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "status ",
                status_string(adventure, turn_order),
                "</text>"
            )
        );

        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "summoner ",
                summoner_string(adventure, turn_order),
                "</text>"
            )
        );

        y += 20;
        (
            string memory loadout_fragment,
            uint256 y_after_loadout
        ) = loadout_svg_fragment(loadout, y);
        svg = string(abi.encodePacked(svg, loadout_fragment));

        y = y_after_loadout + 20;
        (
            string memory monster_fragment,
            uint256 y_after_monsters
        ) = monsters_svg_fragment(turn_order, monsters, y);
        svg = string(abi.encodePacked(svg, monster_fragment));

        y = y_after_monsters + 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "loot ",
                loot_string(adventure, turn_order, monsters),
                "</text>"
            )
        );

        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "started ",
                StringUtil.toString(adventure.started),
                "</text>"
            )
        );

        y += 20;
        if (adventure.ended > 0)
            svg = string(
                abi.encodePacked(
                    svg,
                    '<text x="10" y="',
                    StringUtil.toString(y),
                    '" class="base">',
                    "ended ",
                    StringUtil.toString(adventure.ended),
                    "</text>"
                )
            );
        else
            svg = string(
                abi.encodePacked(
                    svg,
                    '<text x="10" y="',
                    StringUtil.toString(y),
                    '" class="base">',
                    "ended --</text>"
                )
            );
        svg = string(abi.encodePacked(svg, "</svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "adventure #',
                        StringUtil.toString(token),
                        '", "description": "Rarity Adventure 2: Monsters in the Barn. Fight, claim salvage, craft masterwork items.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function status_string(
        Adventure memory adventure,
        Combat.Combatant[] memory turn_order
    ) public pure returns (string memory result) {
        if (outside_dungeon(adventure)) result = "Outside the dungeon";
        else if (en_combat(adventure))
            result = string(
                abi.encodePacked(
                    "Combat in Round",
                    " ",
                    StringUtil.toString(adventure.combat_round)
                )
            );
        else if (combat_over(adventure)) result = "Looting";
        else if (ended(adventure)) {
            if (victory(adventure)) {
                result = string(
                    abi.encodePacked(
                        "Victory! during Round",
                        " ",
                        StringUtil.toString(adventure.combat_round)
                    )
                );
            } else {
                if (fled(adventure, turn_order)) {
                    result = string(
                        abi.encodePacked(
                            "Fled during Round",
                            " ",
                            StringUtil.toString(adventure.combat_round)
                        )
                    );
                } else {
                    result = string(
                        abi.encodePacked(
                            "Defeat during Round",
                            " ",
                            StringUtil.toString(adventure.combat_round)
                        )
                    );
                }
            }
        }
    }

    function summoner_string(
        Adventure memory adventure,
        Combat.Combatant[] memory turn_order
    ) public pure returns (string memory result) {
        result = StringUtil.toString(adventure.summoner);
        uint256 turn_count = turn_order.length;
        for (uint256 i = 0; i < turn_count; i++) {
            if (turn_order[i].mint == RARITY) {
                result = string(
                    abi.encodePacked(
                        result,
                        " (",
                        StringUtil.toString(turn_order[i].hit_points),
                        "hp)"
                    )
                );
            }
        }
    }

    function monsters_svg_fragment(
        Combat.Combatant[] memory turn_order,
        uint8[] memory monsters,
        uint256 y
    ) public pure returns (string memory result, uint256 new_y) {
        result = string(
            abi.encodePacked(
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">monsters</text>'
            )
        );

        if (monsters.length == 0) {
            y += 20;
            result = string(
                abi.encodePacked(
                    result,
                    '<text x="20" y="',
                    StringUtil.toString(y),
                    '" class="base">--</text>'
                )
            );
        } else {
            uint256 monster_index = 0;
            uint256 turn_count = turn_order.length;
            for (uint256 i = 0; i < turn_count; i++) {
                if (turn_order[i].mint != RARITY) {
                    y += 20;
                    result = string(
                        abi.encodePacked(
                            result,
                            '<text x="20" y="',
                            StringUtil.toString(y),
                            '" class="base">',
                            Monster
                                .monster_by_id(monsters[monster_index++])
                                .name,
                            " (",
                            StringUtil.toString(turn_order[i].hit_points),
                            "hp)",
                            "</text>"
                        )
                    );
                }
            }
        }

        new_y = y;
    }

    function loadout_svg_fragment(Equipment.Slot[3] memory loadout, uint256 y)
        public
        view
        returns (string memory result, uint256 new_y)
    {
        result = string(
            abi.encodePacked(
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">loadout</text>'
            )
        );

        Equipment.Slot memory weapon_slot = loadout[0];
        Equipment.Slot memory armor_slot = loadout[1];
        Equipment.Slot memory shield_slot = loadout[2];

        y += 20;
        if (weapon_slot.mint == address(0)) {
            result = string(
                abi.encodePacked(
                    result,
                    '<text x="20" y="',
                    StringUtil.toString(y),
                    '" class="base">Unarmed</text>'
                )
            );
        } else {
            (, uint8 item_type, , ) = ICrafting(weapon_slot.mint).items(
                weapon_slot.token
            );
            result = string(
                abi.encodePacked(
                    result,
                    '<text x="20" y="',
                    StringUtil.toString(y),
                    '" class="base">',
                    ICodexWeapon(EQUIPMENT.codexes(weapon_slot.mint, 3))
                        .item_by_id(item_type)
                        .name,
                    "</text>"
                )
            );
        }

        if (armor_slot.mint == address(0) && shield_slot.mint == address(0)) {
            y += 20;
            result = string(
                abi.encodePacked(
                    result,
                    '<text x="20" y="',
                    StringUtil.toString(y),
                    '" class="base">Unarmored</text>'
                )
            );
        } else {
            if (armor_slot.mint != address(0)) {
                (, uint8 item_type, , ) = ICrafting(armor_slot.mint).items(
                    armor_slot.token
                );
                y += 20;
                result = string(
                    abi.encodePacked(
                        result,
                        '<text x="20" y="',
                        StringUtil.toString(y),
                        '" class="base">',
                        ICodexArmor(EQUIPMENT.codexes(armor_slot.mint, 2))
                            .item_by_id(item_type)
                            .name,
                        "</text>"
                    )
                );
            }
            if (shield_slot.mint != address(0)) {
                (, uint8 item_type, , ) = ICrafting(shield_slot.mint).items(
                    shield_slot.token
                );
                y += 20;
                result = string(
                    abi.encodePacked(
                        result,
                        '<text x="20" y="',
                        StringUtil.toString(y),
                        '" class="base">',
                        ICodexArmor(EQUIPMENT.codexes(shield_slot.mint, 2))
                            .item_by_id(item_type)
                            .name,
                        "</text>"
                    )
                );
            }
        }

        new_y = y;
    }

    function outside_dungeon(adventure_uri.Adventure memory adventure)
        public
        pure
        returns (bool)
    {
        return !adventure.dungeon_entered && adventure.ended == 0;
    }

    function en_combat(adventure_uri.Adventure memory adventure)
        public
        pure
        returns (bool)
    {
        return
            adventure.dungeon_entered &&
            !adventure.combat_ended &&
            adventure.ended == 0;
    }

    function combat_over(adventure_uri.Adventure memory adventure)
        public
        pure
        returns (bool)
    {
        return
            adventure.dungeon_entered &&
            adventure.combat_ended &&
            adventure.ended == 0;
    }

    function ended(adventure_uri.Adventure memory adventure)
        public
        pure
        returns (bool)
    {
        return adventure.ended > 0;
    }

    function victory(adventure_uri.Adventure memory adventure)
        public
        pure
        returns (bool)
    {
        return adventure.monster_count == adventure.monsters_defeated;
    }

    function fled(
        adventure_uri.Adventure memory adventure,
        Combat.Combatant[] memory turn_order
    ) public pure returns (bool result) {
        if (
            combat_over(adventure) &&
            adventure.monster_count > adventure.monsters_defeated
        ) {
            uint256 turn_count = turn_order.length;
            for (uint256 i = 0; i < turn_count; i++) {
                if (turn_order[i].mint == RARITY) {
                    return turn_order[i].hit_points > -1;
                }
            }
        }
    }

    function count_loot(
        adventure_uri.Adventure memory adventure,
        Combat.Combatant[] memory turn_order,
        uint8[] memory monsters
    ) public view returns (uint256) {
        if (!victory(adventure)) return 0;

        uint256 reward = 0;
        uint256 monster_index = 0;
        uint8 turn_count = adventure.monster_count + 1;
        for (uint256 i = 0; i < turn_count; i++) {
            Combat.Combatant memory combatant = turn_order[i];
            if (combatant.mint == address(this)) {
                reward += Monster
                    .monster_by_id(monsters[monster_index++])
                    .challenge_rating;
            }
        }

        if (adventure.search_check_succeeded) {
            if (adventure.search_check_critical) {
                reward = (6 * reward) / 5;
            } else {
                reward = (23 * reward) / 20;
            }
        }

        return (reward * 1e18) / 10;
    }

    function loot_string(
        Adventure memory adventure,
        Combat.Combatant[] memory turn_order,
        uint8[] memory monsters
    ) public view returns (string memory result) {
        result = "--";
        if (ended(adventure) && victory(adventure))
            result = string(
                abi.encodePacked(
                    StringUtil.toString(
                        count_loot(adventure, turn_order, monsters) / 1e18
                    ),
                    " Salvage"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IWeapon {
    struct Weapon {
        uint8 id;
        uint8 proficiency;
        uint8 encumbrance;
        uint8 damage_type;
        uint8 weight;
        uint8 damage;
        uint8 critical;
        int8 critical_modifier;
        uint8 range_increment;
        uint256 cost;
        string name;
        string description;
    }
}

interface ICodexWeapon {
    function item_by_id(uint256 id)
        external
        pure
        returns (IWeapon.Weapon memory);

    function get_proficiency_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function get_encumbrance_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function get_damage_type_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function get_attack_bonus(uint256 id) external pure returns (int8);
}

interface IArmor {
    struct Armor {
        uint8 id;
        uint8 proficiency;
        uint8 weight;
        uint8 armor_bonus;
        uint8 max_dex_bonus;
        int8 penalty;
        uint8 spell_failure;
        uint256 cost;
        string name;
        string description;
    }
}

interface ICodexArmor {
    function item_by_id(uint256 id) external pure returns (IArmor.Armor memory);

    function get_proficiency_by_id(uint256 id)
        external
        pure
        returns (string memory);

    function armor_check_bonus(uint256 id) external pure returns (int8);
}

interface ITools {
    struct Tools {
        uint8 id;
        uint8 weight;
        uint256 cost;
        string name;
        string description;
        int8[36] skill_bonus;
    }
}

interface ICodexTools {
    function item_by_id(uint256 id) external pure returns (ITools.Tools memory);

    function get_skill_bonus(uint256 id, uint256 skill_id)
        external
        pure
        returns (int8);
}

interface ICodexSkills {
    function skill_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Roll.sol";

library Combat {
    uint256 internal constant ATTACK_STRIDE = 7;

    struct Combatant {
        uint8 initiative_roll;
        int8 initiative_score;
        uint8 armor_class;
        int16 hit_points;
        address mint;
        uint256 token;
        int8[28] attacks; // layout: [attack_bonus, critical_modifier, critical_multiplier, damage_dice_count, damage_dice_sides, damage_modifier, damage_type.. x4]
    }

    struct Attack {
        int8 attack_bonus;
        int8 critical_modifier;
        uint8 critical_multiplier;
        uint8 damage_dice_count;
        uint8 damage_dice_sides;
        int8 damage_modifier;
        uint8 damage_type;
    }

    function pack_attack(
        int8 attack_bonus,
        int8 critical_modifier,
        uint8 critical_multiplier,
        uint8 damage_dice_count,
        uint8 damage_dice_sides,
        int8 damage_modifier,
        uint8 damage_type,
        uint256 attack_number,
        int8[28] memory attacks
    ) internal pure {
        uint256 offset = attack_number * ATTACK_STRIDE;
        attacks[offset + 0] = attack_bonus;
        attacks[offset + 1] = critical_modifier;
        attacks[offset + 2] = int8(critical_multiplier);
        attacks[offset + 3] = int8(damage_dice_count);
        attacks[offset + 4] = int8(damage_dice_sides);
        attacks[offset + 5] = damage_modifier;
        attacks[offset + 6] = int8(damage_type);
    }

    function unpack_attack(int8[28] memory attacks, uint256 attack_number)
        internal
        pure
        returns (Attack memory attack)
    {
        uint256 offset = attack_number * ATTACK_STRIDE;
        attack.attack_bonus = attacks[offset + 0];
        attack.critical_modifier = attacks[offset + 1];
        attack.critical_multiplier = uint8(attacks[offset + 2]);
        attack.damage_dice_count = uint8(attacks[offset + 3]);
        attack.damage_dice_sides = uint8(attacks[offset + 4]);
        attack.damage_modifier = attacks[offset + 5];
        attack.damage_type = uint8(attacks[offset + 6]);
    }

    function has_attack(int8[28] memory attacks, uint256 attack_number)
        internal
        pure
        returns (bool)
    {
        return attacks[ATTACK_STRIDE * (attack_number + 1) - 1] > 0;
    }

    function order_by_initiative(Combatant[] memory combatants) internal pure {
        uint256 length = combatants.length;
        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = i + 1; j < length; j++) {
                Combatant memory i_combatant = combatants[i];
                Combatant memory j_combatant = combatants[j];
                if (
                    i_combatant.initiative_score < j_combatant.initiative_score
                ) {
                    combatants[i] = j_combatant;
                    combatants[j] = i_combatant;
                } else if (
                    i_combatant.initiative_score == j_combatant.initiative_score
                ) {
                    if (
                        i_combatant.initiative_roll >
                        j_combatant.initiative_roll
                    ) {
                        combatants[i] = j_combatant;
                        combatants[j] = i_combatant;
                    }
                }
            }
        }
    }

    function attack_combatant(
        Combatant memory attacker,
        Combatant storage defender,
        uint256 attack_number
    )
        internal
        returns (
            bool hit,
            uint8 roll,
            int8 score,
            uint8 critical_confirmation,
            uint8 damage,
            uint8 damage_type
        )
    {
        Attack memory attack = unpack_attack(attacker.attacks, attack_number);

        AttackRoll memory attack_roll = Roll.attack(
            attacker.token + attack_number,
            attack.attack_bonus,
            attack.critical_modifier,
            attack.critical_multiplier,
            defender.armor_class
        );

        if (attack_roll.damage_multiplier == 0) {
            return (
                false,
                attack_roll.roll,
                attack_roll.score,
                attack_roll.critical_confirmation,
                0,
                0
            );
        } else {
            damage = Roll.damage(
                attacker.token + attack_number,
                attack.damage_dice_count,
                attack.damage_dice_sides,
                attack.damage_modifier,
                attack_roll.damage_multiplier
            );
            defender.hit_points -= int16(uint16(damage));
            return (
                true,
                attack_roll.roll,
                attack_roll.score,
                attack_roll.critical_confirmation,
                damage,
                attack.damage_type
            );
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICrafting {
    function items(uint256 token)
        external
        view
        returns (
            uint8 base_type,
            uint8 item_type,
            uint32 crafted,
            uint256 crafter
        );
}

library Crafting {
    function isApprovedOrOwnerOfItem(uint256 token, address mint)
        public
        view
        returns (bool)
    {
        if (IERC721(mint).getApproved(token) == msg.sender) return true;
        address owner = IERC721(mint).ownerOf(token);
        return
            owner == msg.sender ||
            IERC721(mint).isApprovedForAll(owner, msg.sender);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRarityEquipment {
    function slots(uint256 summoner, uint256 slot_type)
        external
        view
        returns (Equipment.Slot memory);

    function encumberance(uint256 summoner) external view returns (uint256);

    function codexes(address mint, uint256 base_type)
        external
        view
        returns (address);

    function equip(
        uint256 summoner,
        uint256 slot_type,
        address mint,
        address codex,
        uint256 token
    ) external;

    function unequip(uint256 summoner, uint256 slot_type) external;

    function snapshot(uint256 token, uint256 summoner) external;

    function snapshots(
        address encounter,
        uint256 token,
        uint256 summoner,
        uint8 slot_type
    ) external view returns (Equipment.Slot memory);
}

library Equipment {
    struct Slot {
        address mint;
        uint256 token;
    }

    uint8 public constant SLOT_TYPE_WEAPON_1 = 1;
    uint8 public constant SLOT_TYPE_ARMOR = 2;
    uint8 public constant SLOT_TYPE_SHIELD = 3;
    uint8 public constant SLOT_TYPE_WEAPON_2 = 4;
    uint8 public constant SLOT_TYPE_HANDS = 5;
    uint8 public constant SLOT_TYPE_RING_1 = 6;
    uint8 public constant SLOT_TYPE_RING_2 = 7;
    uint8 public constant SLOT_TYPE_HEAD = 8;
    uint8 public constant SLOT_TYPE_HEADBAND = 9;
    uint8 public constant SLOT_TYPE_EYES = 10;
    uint8 public constant SLOT_TYPE_NECK = 11;
    uint8 public constant SLOT_TYPE_SHOULDERS = 12;
    uint8 public constant SLOT_TYPE_CHEST = 13;
    uint8 public constant SLOT_TYPE_BELT = 14;
    uint8 public constant SLOT_TYPE_BODY = 15;
    uint8 public constant SLOT_TYPE_ARMS = 16;
    uint8 public constant SLOT_TYPE_FEET = 17;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Combat.sol";
import "./Random.sol";

library Monster {
    struct MonsterCodex {
        uint8 id;
        uint8 hit_dice_count;
        uint8 hit_dice_sides;
        int8 hit_dice_modifier;
        int8 initiative_bonus;
        uint8 armor_class;
        uint16 challenge_rating;
        uint8[6] abilities;
        int8[28] attacks; // layout: [attack_bonus, critical_modifier, critical_multiplier, damage_dice_count, damage_dice_sides, damage_modifier, damage_type.. x4]
        string name;
    }

    function standard_hit_points(MonsterCodex memory monster)
        public
        pure
        returns (int16)
    {
        return
            int16(
                uint16(
                    (monster.hit_dice_count *
                        monster.hit_dice_sides -
                        monster.hit_dice_count) /
                        2 +
                        monster.hit_dice_count
                )
            ) + monster.hit_dice_modifier;
    }

    function roll_hit_points(MonsterCodex memory monster, uint256 token)
        public
        view
        returns (int16)
    {
        int16 roll = int16(
            uint16(
                Random.dn(
                    9409069218745053777,
                    token,
                    monster.hit_dice_count,
                    monster.hit_dice_sides
                )
            )
        );
        return roll + monster.hit_dice_modifier;
    }

    function monster_combatant(
        uint256 token,
        address mint,
        Monster.MonsterCodex memory monster_codex
    ) public view returns (Combat.Combatant memory combatant) {
        (uint8 initiative_roll, int8 initiative_score) = Roll.initiative(
            token,
            Attributes.compute_modifier(monster_codex.abilities[1]),
            monster_codex.initiative_bonus
        );

        combatant.mint = mint;
        combatant.token = token;
        combatant.initiative_roll = initiative_roll;
        combatant.initiative_score = initiative_score;
        combatant.hit_points = standard_hit_points(monster_codex);
        combatant.armor_class = monster_codex.armor_class;
        combatant.attacks = monster_codex.attacks;
    }

    function monster_by_id(uint8 id)
        public
        pure
        returns (MonsterCodex memory monster)
    {
        if (id == 1) {
            return kobold();
        } else if (id == 2) {
            return dire_rat();
        } else if (id == 3) {
            return goblin();
        } else if (id == 4) {
            return gnoll();
        } else if (id == 5) {
            return grimlock();
        } else if (id == 6) {
            return black_bear();
        } else if (id == 7) {
            return ogre();
        } else if (id == 8) {
            return dire_boar();
        } else if (id == 9) {
            return dire_wolverine();
        } else if (id == 10) {
            return troll();
        } else if (id == 11) {
            return ettin();
        } else if (id == 12) {
            return hill_giant();
        } else if (id == 13) {
            return stone_giant();
        }
    }

    function kobold() public pure returns (MonsterCodex memory monster) {
        monster.id = 1;
        monster.challenge_rating = 25; // CR 1/4
        monster.hit_dice_count = 1;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 0;
        monster.initiative_bonus = 0;
        monster.armor_class = 15;
        monster.abilities = [9, 13, 10, 10, 9, 8];
        Combat.pack_attack(1, 0, 3, 1, 2, -1, 2, 0, monster.attacks);
        monster.name = "Kobold";
    }

    function dire_rat() public pure returns (MonsterCodex memory monster) {
        monster.id = 2;
        monster.challenge_rating = 33; // CR 1/3
        monster.hit_dice_count = 1;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 1;
        monster.initiative_bonus = 0;
        monster.armor_class = 15;
        monster.abilities = [10, 17, 12, 1, 12, 4];
        Combat.pack_attack(4, 0, 2, 1, 4, 0, 3, 0, monster.attacks);
        monster.name = "Dire Rat";
    }

    function goblin() public pure returns (MonsterCodex memory monster) {
        monster.id = 3;
        monster.challenge_rating = 33; // CR 1/3
        monster.hit_dice_count = 1;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 1;
        monster.initiative_bonus = 0;
        monster.armor_class = 15;
        monster.abilities = [11, 13, 12, 10, 9, 6];
        Combat.pack_attack(2, 0, 2, 1, 6, 0, 1, 0, monster.attacks);
        monster.name = "Goblin";
    }

    function gnoll() public pure returns (MonsterCodex memory monster) {
        monster.id = 4;
        monster.challenge_rating = 100; // CR 1
        monster.hit_dice_count = 2;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 2;
        monster.initiative_bonus = 0;
        monster.armor_class = 15;
        monster.abilities = [15, 10, 13, 8, 11, 8];
        Combat.pack_attack(3, 0, 3, 1, 8, 2, 3, 0, monster.attacks);
        monster.name = "Gnoll";
    }

    function grimlock() public pure returns (MonsterCodex memory monster) {
        monster.id = 5;
        monster.challenge_rating = 100; // CR 1
        monster.hit_dice_count = 2;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 2;
        monster.initiative_bonus = 0;
        monster.armor_class = 15;
        monster.abilities = [15, 13, 13, 10, 8, 6];
        Combat.pack_attack(4, 0, 3, 1, 8, 3, 3, 0, monster.attacks);
        monster.name = "Grimlock";
    }

    function black_bear() public pure returns (MonsterCodex memory monster) {
        monster.id = 6;
        monster.challenge_rating = 200; // CR 2
        monster.hit_dice_count = 3;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 6;
        monster.initiative_bonus = 0;
        monster.armor_class = 13;
        monster.abilities = [19, 13, 15, 2, 12, 6];
        Combat.pack_attack(6, 0, 2, 1, 4, 4, 3, 0, monster.attacks);
        Combat.pack_attack(6, 0, 2, 1, 4, 4, 3, 1, monster.attacks);
        Combat.pack_attack(1, 0, 2, 1, 6, 2, 3, 2, monster.attacks);
        monster.name = "Black Bear";
    }

    function ogre() public pure returns (MonsterCodex memory monster) {
        monster.id = 7;
        monster.challenge_rating = 300; // CR 3
        monster.hit_dice_count = 4;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 11;
        monster.initiative_bonus = 0;
        monster.armor_class = 16;
        monster.abilities = [21, 8, 15, 6, 10, 7];
        Combat.pack_attack(8, 0, 2, 2, 8, 7, 1, 0, monster.attacks);
        monster.name = "Ogre";
    }

    function dire_boar() public pure returns (MonsterCodex memory monster) {
        monster.id = 8;
        monster.challenge_rating = 400; // CR 4
        monster.hit_dice_count = 7;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 21;
        monster.initiative_bonus = 0;
        monster.armor_class = 15;
        monster.abilities = [27, 10, 17, 2, 13, 8];
        Combat.pack_attack(12, 0, 2, 1, 8, 12, 2, 0, monster.attacks);
        monster.name = "Dire Boar";
    }

    function dire_wolverine()
        public
        pure
        returns (MonsterCodex memory monster)
    {
        monster.id = 9;
        monster.challenge_rating = 400; // CR 4
        monster.hit_dice_count = 5;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 23;
        monster.initiative_bonus = 0;
        monster.armor_class = 16;
        monster.abilities = [22, 17, 19, 2, 12, 10];
        Combat.pack_attack(8, 0, 2, 1, 6, 6, 3, 0, monster.attacks);
        Combat.pack_attack(8, 0, 2, 1, 6, 6, 3, 1, monster.attacks);
        Combat.pack_attack(3, 0, 2, 1, 8, 3, 3, 2, monster.attacks);
        monster.name = "Dire Wolverine";
    }

    function troll() public pure returns (MonsterCodex memory monster) {
        monster.id = 10;
        monster.challenge_rating = 500; // CR 5
        monster.hit_dice_count = 6;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 36;
        monster.initiative_bonus = 0;
        monster.armor_class = 16;
        monster.abilities = [27, 10, 17, 2, 13, 8];
        Combat.pack_attack(9, 0, 2, 1, 6, 6, 3, 0, monster.attacks);
        Combat.pack_attack(9, 0, 2, 1, 6, 6, 3, 1, monster.attacks);
        Combat.pack_attack(4, 0, 2, 1, 6, 3, 2, 2, monster.attacks);
        monster.name = "Troll";
    }

    function ettin() public pure returns (MonsterCodex memory monster) {
        monster.id = 11;
        monster.challenge_rating = 600; // CR 6
        monster.hit_dice_count = 10;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 20;
        monster.initiative_bonus = 4; // improved initiative feat
        monster.armor_class = 18;
        monster.abilities = [27, 10, 17, 2, 13, 8];
        Combat.pack_attack(12, 0, 2, 2, 6, 6, 1, 0, monster.attacks);
        Combat.pack_attack(7, 0, 2, 2, 6, 6, 1, 1, monster.attacks);
        monster.name = "Ettin";
    }

    function hill_giant() public pure returns (MonsterCodex memory monster) {
        monster.id = 12;
        monster.challenge_rating = 700; // CR 7
        monster.hit_dice_count = 12;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 48;
        monster.initiative_bonus = 0;
        monster.armor_class = 20;
        monster.abilities = [25, 8, 19, 6, 10, 7];
        Combat.pack_attack(16, 0, 2, 2, 8, 10, 1, 0, monster.attacks);
        Combat.pack_attack(11, 0, 2, 2, 8, 10, 1, 1, monster.attacks);
        monster.name = "Hill Giant";
    }

    function stone_giant() public pure returns (MonsterCodex memory monster) {
        monster.id = 13;
        monster.challenge_rating = 800; // CR 8
        monster.hit_dice_count = 14;
        monster.hit_dice_sides = 8;
        monster.hit_dice_modifier = 56;
        monster.initiative_bonus = 0;
        monster.armor_class = 25;
        monster.abilities = [27, 15, 19, 10, 12, 11];
        Combat.pack_attack(17, 0, 2, 2, 8, 12, 1, 0, monster.attacks);
        Combat.pack_attack(12, 0, 2, 2, 8, 12, 1, 1, monster.attacks);
        monster.name = "Stone Giant";
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library StringUtil {
    function toString(int256 value) internal pure returns (string memory) {
        string memory _string = "";
        if (value < 0) {
            _string = "-";
            value = value * -1;
        }
        return string(abi.encodePacked(_string, toString(uint256(value))));
    }

    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
    function toString(uint256 value) internal pure returns (string memory) {
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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/core/IRarityCommonCrafting.sol";
import "./Attributes.sol";
import "./CraftingSkills.sol";
import "./Feats.sol";
import "./Random.sol";
import "./Skills.sol";

struct AttackRoll {
    uint8 roll;
    int8 score;
    uint8 critical_roll;
    uint8 critical_confirmation;
    uint8 damage_multiplier;
}

library Roll {
    function appraise(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 838841482654980658, 20);
        score = int8(roll);
        score += Attributes.intelligence_modifier(summoner);
        score += int8(Skills.appraise(summoner));
        if (Feats.diligent(summoner)) score += 2;
    }

    function craft_bonus(uint256 summoner, uint8 specialization)
        public
        view
        returns (int8 bonus)
    {
        bonus += Attributes.intelligence_modifier(summoner);
        if (specialization == 0) {
            bonus += int8(Skills.craft(summoner));
        } else {
            bonus += int8(CraftingSkills.ranks(summoner, specialization));
        }
    }

    function craft(uint256 summoner, uint8 specialization)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 12171199555242019957, 20);
        score = int8(roll) + craft_bonus(summoner, specialization);
    }

    function initiative(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        return
            initiative(
                summoner,
                Attributes.dexterity_modifier(summoner),
                Feats.improved_initiative(summoner) ? int8(4) : int8(0)
            );
    }

    function initiative(
        uint256 token,
        int8 total_dex_modifier,
        int8 initiative_bonus
    ) public view returns (uint8 roll, int8 score) {
        roll = Random.dn(token, 11781769727069077443, 20);
        score = total_dex_modifier + int8(initiative_bonus) + int8(roll);
    }

    function search(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 12460038586674487978, 20);
        score = int8(roll);
        score += Attributes.intelligence_modifier(summoner);
        score += int8(Skills.search(summoner));
        if (Feats.investigator(summoner)) score += 2;
    }

    function sense_motive(uint256 summoner)
        public
        view
        returns (uint8 roll, int8 score)
    {
        roll = Random.dn(summoner, 3505325381439919961, 20);
        score = int8(roll);
        score += Attributes.wisdom_modifier(summoner);
        score += int8(Skills.sense_motive(summoner));
        if (Feats.negotiator(summoner)) score += 2;
    }

    function attack(
        uint256 seed,
        int8 total_bonus,
        int8 critical_modifier,
        uint8 critical_multiplier,
        uint8 target_armor_class
    ) public view returns (AttackRoll memory result) {
        result.roll = Random.dn(seed, 9807527763775093748, 20);
        if (result.roll == 1) return AttackRoll(1, 0, 0, 0, 0);
        result.score = int8(result.roll) + total_bonus;
        if (result.score >= int8(target_armor_class))
            result.damage_multiplier++;
        if (result.roll >= uint256(int256(int8(20) + critical_modifier))) {
            result.critical_roll = Random.dn(seed, 9809778455456300450, 20);
            result.critical_confirmation = uint8(
                int8(result.critical_roll) + total_bonus
            );
            if (result.critical_confirmation >= target_armor_class)
                result.damage_multiplier += critical_multiplier;
        }
    }

    function damage(
        uint256 seed,
        uint8 dice_count,
        uint8 dice_sides,
        int8 total_modifier,
        uint8 damage_multiplier
    ) public view returns (uint8 result) {
        for (uint256 i; i < damage_multiplier; i++) {
            int8 signed_result = int8(
                Random.dn(seed, 6459055441333536942 + i, dice_count, dice_sides)
            ) + total_modifier;
            if (signed_result < 1) {
                result += 1;
            } else {
                result += uint8(signed_result);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCommonCrafting {
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
    event Crafted(
        address indexed owner,
        uint256 check,
        uint256 summoner,
        uint256 base_type,
        uint256 item_type,
        uint256 gold,
        uint256 craft_i
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function SUMMMONER_ID() external view returns (uint256);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function craft(
        uint256 _summoner,
        uint8 _base_type,
        uint8 _item_type,
        uint256 _crafting_materials
    ) external;

    function craft_skillcheck(uint256 _summoner, uint256 _dc)
        external
        view
        returns (bool crafted, int256 check);

    function getApproved(uint256 tokenId) external view returns (address);

    function get_armor_dc(uint256 _item_id) external pure returns (uint256 dc);

    function get_dc(uint256 _base_type, uint256 _item_id)
        external
        pure
        returns (uint256 dc);

    function get_goods_dc() external pure returns (uint256 dc);

    function get_item_cost(uint256 _base_type, uint256 _item_type)
        external
        pure
        returns (uint256 cost);

    function get_token_uri_armor(uint256 _item)
        external
        view
        returns (string memory output);

    function get_token_uri_goods(uint256 _item)
        external
        view
        returns (string memory output);

    function get_token_uri_weapon(uint256 _item)
        external
        view
        returns (string memory output);

    function get_type(uint256 _type_id)
        external
        pure
        returns (string memory _type);

    function get_weapon_dc(uint256 _item_id) external pure returns (uint256 dc);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isValid(uint256 _base_type, uint256 _item_type)
        external
        pure
        returns (bool);

    function items(uint256)
        external
        view
        returns (
            uint8 base_type,
            uint8 item_type,
            uint32 crafted,
            uint256 crafter
        );

    function modifier_for_attribute(uint256 _attribute)
        external
        pure
        returns (int256 _modifier);

    function name() external view returns (string memory);

    function next_item() external view returns (uint256);

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

    function simulate(
        uint256 _summoner,
        uint256 _base_type,
        uint256 _item_type,
        uint256 _crafting_materials
    )
        external
        view
        returns (
            bool crafted,
            int256 check,
            uint256 cost,
            uint256 dc
        );

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _item) external view returns (string memory uri);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"uint256","name":"check","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"summoner","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"base_type","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"item_type","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gold","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"craft_i","type":"uint256"}],"name":"Crafted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"inputs":[],"name":"SUMMMONER_ID","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8","name":"_base_type","type":"uint8"},{"internalType":"uint8","name":"_item_type","type":"uint8"},{"internalType":"uint256","name":"_crafting_materials","type":"uint256"}],"name":"craft","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_dc","type":"uint256"}],"name":"craft_skillcheck","outputs":[{"internalType":"bool","name":"crafted","type":"bool"},{"internalType":"int256","name":"check","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_armor_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"get_goods_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"}],"name":"get_item_cost","outputs":[{"internalType":"uint256","name":"cost","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_armor","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_goods","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"get_token_uri_weapon","outputs":[{"internalType":"string","name":"output","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_type_id","type":"uint256"}],"name":"get_type","outputs":[{"internalType":"string","name":"_type","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item_id","type":"uint256"}],"name":"get_weapon_dc","outputs":[{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"}],"name":"isValid","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"items","outputs":[{"internalType":"uint8","name":"base_type","type":"uint8"},{"internalType":"uint8","name":"item_type","type":"uint8"},{"internalType":"uint32","name":"crafted","type":"uint32"},{"internalType":"uint256","name":"crafter","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_attribute","type":"uint256"}],"name":"modifier_for_attribute","outputs":[{"internalType":"int256","name":"_modifier","type":"int256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"next_item","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint256","name":"_base_type","type":"uint256"},{"internalType":"uint256","name":"_item_type","type":"uint256"},{"internalType":"uint256","name":"_crafting_materials","type":"uint256"}],"name":"simulate","outputs":[{"internalType":"bool","name":"crafted","type":"bool"},{"internalType":"int256","name":"check","type":"int256"},{"internalType":"uint256","name":"cost","type":"uint256"},{"internalType":"uint256","name":"dc","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_item","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"uri","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"}]
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexCraftingSkills.sol";
import "../interfaces/core/IRarityCraftingSkills.sol";

library CraftingSkills {
    IRarityCodexCraftingSkills constant CODEX =
        IRarityCodexCraftingSkills(0xa0B2508A25dc28D20C537b8E1798543AC437F669);
    IRarityCraftingSkills constant SKILLS =
        IRarityCraftingSkills(0xc84275A99C01D0b6C1A63bD94d589e4A44a85DeD);

    function ranks(uint256 summoner, uint8 specialization)
        public
        view
        returns (uint8)
    {
        uint8[5] memory skills = SKILLS.get_skills(summoner);
        return skills[specialization - 1];
    }

    function get_specialization(uint8 base_type, uint8 item_type)
        public
        pure
        returns (uint8 result)
    {
        if (base_type == 2) {
            (result, , ) = CODEX.armorsmithing();
        } else if (base_type == 3) {
            if (item_type >= 44 && item_type <= 47) {
                (result, , ) = CODEX.bowmaking();
            } else {
                (result, , ) = CODEX.weaponsmithing();
            }
        }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexBaseRandom2.sol";

library Random {
    IRarityCodexBaseRandom2 constant RANDOM =
        IRarityCodexBaseRandom2(0x165AD01B090BC91352AeA8cEF7513C63852797Ed);

    function dn(
        uint256 seed_a,
        uint256 seed_b,
        uint8 dice_sides
    ) public view returns (uint8) {
        return RANDOM.dn(seed_a, seed_b, dice_sides);
    }

    function dn(
        uint256 seed_a,
        uint256 seed_b,
        uint8 dice_count,
        uint8 dice_sides
    ) public view returns (uint8) {
        uint8 result = 0;
        for (uint256 i; i < dice_count; i++) {
            result += RANDOM.dn(seed_a + i, seed_b, dice_sides);
        }
        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/codex/IRarityCodexSkills.sol";
import "../interfaces/core/IRaritySkills.sol";

library Skills {
    IRarityCodexSkills constant CODEX =
        IRarityCodexSkills(0x67ae39a2Ee91D7258a86CD901B17527e19E493B3);
    IRaritySkills constant SKILLS =
        IRaritySkills(0x51C0B29A1d84611373BA301706c6B4b72283C80F);

    function appraise(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.appraise();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }

    function craft(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.craft();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }

    function search(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.search();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
    }

    function sense_motive(uint256 summoner) public view returns (uint8 ranks) {
        (uint256 id, , , , , , , ) = CODEX.sense_motive();
        uint8[36] memory skills = SKILLS.get_skills(summoner);
        ranks = skills[id - 1];
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

interface IRarityCodexCraftingSkills {
    function alchemy()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function armorsmithing()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function bowmaking()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function class() external view returns (string memory);

    function index() external view returns (string memory);

    function skill_by_id(uint256 _id)
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function trapmaking()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );

    function weaponsmithing()
        external
        pure
        returns (
            uint8 id,
            string memory name,
            string memory description
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"alchemy","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"armorsmithing","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"bowmaking","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"skill_by_id","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"trapmaking","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"weaponsmithing","outputs":[{"internalType":"uint8","name":"id","type":"uint8"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"description","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCraftingSkills {
    function SKILL_SLOTS() external view returns (uint8);

    function crafting_skills(uint256, uint256) external view returns (uint8);

    function get_skills(uint256 summoner)
        external
        view
        returns (uint8[5] memory);

    function is_spell_caster(uint256 summoner) external view returns (bool);

    function set_skills(uint256 summoner, uint8[5] memory skills) external;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"SKILL_SLOTS","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"crafting_skills","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"get_skills","outputs":[{"internalType":"uint8[5]","name":"","type":"uint8[5]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"}],"name":"is_spell_caster","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"summoner","type":"uint256"},{"internalType":"uint8[5]","name":"skills","type":"uint8[5]"}],"name":"set_skills","outputs":[],"stateMutability":"nonpayable","type":"function"}]
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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexBaseRandom2 {
    function class() external view returns (string memory);

    function d10(uint256 a, uint256 b) external view returns (uint8);

    function d100(uint256 a, uint256 b) external view returns (uint8);

    function d12(uint256 a, uint256 b) external view returns (uint8);

    function d20(uint256 a, uint256 b) external view returns (uint8);

    function d4(uint256 a, uint256 b) external view returns (uint8);

    function d6(uint256 a, uint256 b) external view returns (uint8);

    function d8(uint256 a, uint256 b) external view returns (uint8);

    function dn(
        uint256 a,
        uint256 b,
        uint8 die_sides
    ) external view returns (uint8);

    function index() external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d10","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d100","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d12","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d20","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d4","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d6","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"}],"name":"d8","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"a","type":"uint256"},{"internalType":"uint256","name":"b","type":"uint256"},{"internalType":"uint8","name":"die_sides","type":"uint8"}],"name":"dn","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IRarityCodexSkills {
    function appraise()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function balance()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function bluff()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function class() external view returns (string memory);

    function climb()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function concentration()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function craft()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function decipher_script()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function diplomacy()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function disable_device()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function disguise()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function escape_artist()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function forgery()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function gather_information()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function get_attribute(uint256 id)
        external
        pure
        returns (string memory attribute);

    function handle_animal()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function heal()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function hide()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function index() external view returns (string memory);

    function intimidate()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function jump()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function knowledge()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function listen()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function move_silently()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function open_lock()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function perform()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function profession()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function ride()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function search()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function sense_motive()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function skill_by_id(uint256 _id)
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function sleight_of_hand()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function speak_language()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function spellcraft()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function spot()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function survival()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function swim()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function tumble()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function use_magic_device()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );

    function use_rope()
        external
        pure
        returns (
            uint256 id,
            string memory name,
            uint256 attribute_id,
            uint256 synergy,
            bool retry,
            bool armor_check_penalty,
            string memory check,
            string memory action
        );
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"appraise","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"balance","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"bluff","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"class","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"climb","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"concentration","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"craft","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"decipher_script","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"diplomacy","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"disable_device","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"disguise","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"escape_artist","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"forgery","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"gather_information","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"get_attribute","outputs":[{"internalType":"string","name":"attribute","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"handle_animal","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"heal","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"hide","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"index","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"intimidate","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"jump","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"knowledge","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"listen","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"move_silently","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"open_lock","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"perform","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"profession","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"ride","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"search","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"sense_motive","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"skill_by_id","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"sleight_of_hand","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"speak_language","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spellcraft","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"spot","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"survival","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"swim","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"tumble","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"use_magic_device","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"use_rope","outputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"string","name":"name","type":"string"},{"internalType":"uint256","name":"attribute_id","type":"uint256"},{"internalType":"uint256","name":"synergy","type":"uint256"},{"internalType":"bool","name":"retry","type":"bool"},{"internalType":"bool","name":"armor_check_penalty","type":"bool"},{"internalType":"string","name":"check","type":"string"},{"internalType":"string","name":"action","type":"string"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IRaritySkills {
    function base_per_class(uint256 _class)
        external
        pure
        returns (uint256 base);

    function calculate_points_for_set(uint256 _class, uint8[36] memory _skills)
        external
        pure
        returns (uint256 points);

    function class_skills(uint256 _class)
        external
        pure
        returns (bool[36] memory _skills);

    function class_skills_by_name(uint256 _class)
        external
        view
        returns (string[] memory);

    function get_skills(uint256 _summoner)
        external
        view
        returns (uint8[36] memory);

    function is_valid_set(uint256 _summoner, uint8[36] memory _skills)
        external
        view
        returns (bool);

    function modifier_for_attribute(uint256 _attribute)
        external
        pure
        returns (int256 _modifier);

    function set_skills(uint256 _summoner, uint8[36] memory _skills) external;

    function skills(uint256, uint256) external view returns (uint8);

    function skills_per_level(
        int256 _int,
        uint256 _class,
        uint256 _level
    ) external pure returns (uint256 points);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"base_per_class","outputs":[{"internalType":"uint256","name":"base","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"calculate_points_for_set","outputs":[{"internalType":"uint256","name":"points","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"class_skills","outputs":[{"internalType":"bool[36]","name":"_skills","type":"bool[36]"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_class","type":"uint256"}],"name":"class_skills_by_name","outputs":[{"internalType":"string[]","name":"","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"}],"name":"get_skills","outputs":[{"internalType":"uint8[36]","name":"","type":"uint8[36]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"is_valid_set","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_attribute","type":"uint256"}],"name":"modifier_for_attribute","outputs":[{"internalType":"int256","name":"_modifier","type":"int256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"_summoner","type":"uint256"},{"internalType":"uint8[36]","name":"_skills","type":"uint8[36]"}],"name":"set_skills","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"skills","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"int256","name":"_int","type":"int256"},{"internalType":"uint256","name":"_class","type":"uint256"},{"internalType":"uint256","name":"_level","type":"uint256"}],"name":"skills_per_level","outputs":[{"internalType":"uint256","name":"points","type":"uint256"}],"stateMutability":"pure","type":"function"}]
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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