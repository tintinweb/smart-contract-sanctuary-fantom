//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Base64.sol";
import "../library/Codex.sol";
import "../library/StringUtil.sol";

library masterwork_uri {
    ICodexSkills constant SKILLS_CODEX =
        ICodexSkills(0x67ae39a2Ee91D7258a86CD901B17527e19E493B3);
    ICodexWeapon constant WEAPONS_CODEX =
        ICodexWeapon(0xaDB319B7beb933615a80588340b4287E30DcACD8);
    ICodexArmor constant ARMOR_CODEX =
        ICodexArmor(0xa6D0dBDe7f7c14d09d1df96EfA6913Ce17a4817f);
    ICodexTools constant TOOLS_CODEX =
        ICodexTools(0x0aF202E692a3edad4c5710ABa9A298E44b661F98);

    struct Project {
        bool complete;
        uint8 base_type;
        uint8 item_type;
        uint64 started;
        uint256 crafter;
        uint256 progress;
        uint256 tools;
        uint256 xp;
    }

    struct Item {
        uint8 base_type;
        uint8 item_type;
        uint64 crafted;
        uint256 crafter;
    }

    function item_name(uint8 base_type, uint8 item_type)
        public
        pure
        returns (string memory result)
    {
        if (base_type == 2) {
            result = ARMOR_CODEX.item_by_id(item_type).name;
        } else if (base_type == 3) {
            result = WEAPONS_CODEX.item_by_id(item_type).name;
        } else if (base_type == 4) {
            result = TOOLS_CODEX.item_by_id(item_type).name;
        }
    }

    function project_uri(
        uint256 token,
        Project memory project,
        uint256 m,
        uint256 n
    ) public pure returns (string memory) {
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
                "category ",
                base_type_name(project.base_type),
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
                "item ",
                item_name(project.base_type, project.item_type),
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
                "crafter ",
                StringUtil.toString(project.crafter),
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
                "status ",
                status_string(project),
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
                "tools ",
                tools_string(project),
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
                "progress ",
                progress_string(m, n),
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
                "xp ",
                StringUtil.toString(project.xp / 1e18),
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
                StringUtil.toString(project.started),
                "</text>"
            )
        );
        svg = string(abi.encodePacked(svg, "</svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "project #',
                        StringUtil.toString(token),
                        '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function armor_uri(uint256 token, Item memory item)
        public
        pure
        returns (string memory)
    {
        uint256 y = 0;
        IArmor.Armor memory armor = ARMOR_CODEX.item_by_id(item.item_type);

        string
            memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "category ",
                base_type_name(item.base_type),
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
                "name ",
                armor.name,
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
                "cost ",
                StringUtil.toString(armor.cost / 1e18),
                "gp</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "weight ",
                StringUtil.toString(armor.weight),
                "lb</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "proficiency ",
                ARMOR_CODEX.get_proficiency_by_id(armor.proficiency),
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
                "armor bonus ",
                StringUtil.toString(armor.armor_bonus),
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
                "max_dex ",
                StringUtil.toString(armor.max_dex_bonus),
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
                "penalty ",
                StringUtil.toString(armor.penalty),
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
                "spell failure ",
                StringUtil.toString(armor.spell_failure),
                "%</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "bonus</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="20" y="',
                StringUtil.toString(y),
                '" class="base">',
                "-1 Armor Check Penalty</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "description ",
                armor.description,
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
                "crafter ",
                StringUtil.toString(item.crafter),
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
                "crafted ",
                StringUtil.toString(item.crafted),
                "</text>"
            )
        );
        svg = string(abi.encodePacked(svg, "</svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "item #',
                        StringUtil.toString(token),
                        '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function weapon_uri(uint256 token, Item memory item)
        public
        pure
        returns (string memory)
    {
        uint256 y = 0;
        IWeapon.Weapon memory weapon = WEAPONS_CODEX.item_by_id(item.item_type);

        string
            memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "category ",
                base_type_name(item.base_type),
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
                "name ",
                weapon.name,
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
                "cost ",
                StringUtil.toString(weapon.cost / 1e18),
                "gp</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "weight ",
                StringUtil.toString(weapon.weight),
                "lb</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "proficiency ",
                WEAPONS_CODEX.get_proficiency_by_id(weapon.proficiency),
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
                "encumbrance ",
                WEAPONS_CODEX.get_encumbrance_by_id(weapon.encumbrance),
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
                "damage 1d",
                StringUtil.toString(weapon.damage),
                ", ",
                WEAPONS_CODEX.get_damage_type_by_id(weapon.damage_type),
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
                "(modifier) x critical (",
                StringUtil.toString(weapon.critical_modifier),
                ") x ",
                StringUtil.toString(weapon.critical),
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
                "range ",
                StringUtil.toString(weapon.range_increment),
                "ft</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "bonus</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="20" y="',
                StringUtil.toString(y),
                '" class="base">',
                "+1 Attack</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "description ",
                weapon.description,
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
                "crafter ",
                StringUtil.toString(item.crafter),
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
                "crafted ",
                StringUtil.toString(item.crafted),
                "</text>"
            )
        );
        svg = string(abi.encodePacked(svg, "</svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "item #',
                        StringUtil.toString(token),
                        '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function tools_uri(uint256 token, Item memory item)
        public
        pure
        returns (string memory)
    {
        uint256 y = 0;
        ITools.Tools memory tools = TOOLS_CODEX.item_by_id(item.item_type);

        string
            memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350" shape-rendering="crispEdges"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" />';
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "category ",
                base_type_name(item.base_type),
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
                "name ",
                tools.name,
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
                "cost ",
                StringUtil.toString(tools.cost / 1e18),
                "gp</text>"
            )
        );
        y += 20;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "weight ",
                StringUtil.toString(tools.weight),
                "lb</text>"
            )
        );

        y += 20;
        (
            string memory bonus_fragment,
            uint256 y_after_bonus
        ) = tools_bonus_svg_fragment(tools, y);
        svg = string(abi.encodePacked(svg, bonus_fragment));

        y = y_after_bonus;
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">',
                "description ",
                tools.description,
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
                "crafter ",
                StringUtil.toString(item.crafter),
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
                "crafted ",
                StringUtil.toString(item.crafted),
                "</text>"
            )
        );
        svg = string(abi.encodePacked(svg, "</svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "item #',
                        StringUtil.toString(token),
                        '", "description": "Rarity tier 2 (Masterwork), non magical, item crafting.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function base_type_name(uint8 base_type)
        internal
        pure
        returns (string memory result)
    {
        if (base_type == 2) {
            result = "Armor";
        } else if (base_type == 3) {
            result = "Weapons";
        } else if (base_type == 4) {
            result = "Tools";
        }
    }

    function status_string(Project memory project)
        internal
        pure
        returns (string memory)
    {
        if (project.complete) return "Complete";
        return "Crafting";
    }

    function tools_string(Project memory project)
        internal
        pure
        returns (string memory)
    {
        if (project.tools > 0) return "Masterwork Artisan's Tools";
        return "Common Artisan's Tools (Rental)";
    }

    function progress_string(uint256 m, uint256 n)
        internal
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(StringUtil.toString((m * 100) / n), "%"));
    }

    function tools_bonus_svg_fragment(ITools.Tools memory tools, uint256 y)
        internal
        pure
        returns (string memory result, uint256 new_y)
    {
        result = string(
            abi.encodePacked(
                '<text x="10" y="',
                StringUtil.toString(y),
                '" class="base">bonus</text>'
            )
        );
        y += 20;
        for (uint256 i = 0; i < 36; i++) {
            int8 bonus = tools.skill_bonus[i];
            string memory sign = "";
            if (bonus != 0) {
                if (bonus > 0) sign = "+";
                (, string memory name, , , , , , ) = SKILLS_CODEX.skill_by_id(
                    i + 1
                );
                result = string(
                    abi.encodePacked(
                        result,
                        '<text x="20" y="',
                        StringUtil.toString(y),
                        '" class="base">',
                        sign,
                        StringUtil.toString(bonus),
                        " ",
                        name,
                        "</text>"
                    )
                );
                y += 20;
            }
        }
        new_y = y;
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