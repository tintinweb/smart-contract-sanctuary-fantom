// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../library/Codex.sol";

contract codex {
    string public constant index = "Items";
    string public constant class = "Masterwork Weapons";

    ICodexWeapon constant COMMON_CODEX =
        ICodexWeapon(0xE333649CC2E9e122F83B77Dc367D3eF02a85eDaF);

    function get_proficiency_by_id(uint256 id)
        public
        pure
        returns (string memory description)
    {
        return COMMON_CODEX.get_proficiency_by_id(id);
    }

    function get_encumbrance_by_id(uint256 id)
        public
        pure
        returns (string memory description)
    {
        return COMMON_CODEX.get_encumbrance_by_id(id);
    }

    function get_damage_type_by_id(uint256 id)
        public
        pure
        returns (string memory description)
    {
        return COMMON_CODEX.get_damage_type_by_id(id);
    }

    function get_attack_bonus(uint256 id) public pure returns (int8) {
        id; //shhh
        return 1;
    }

    function item_by_id(uint256 id)
        public
        pure
        returns (IWeapon.Weapon memory weapon)
    {
        weapon = COMMON_CODEX.item_by_id(id);
        weapon.cost = weapon.cost + 300e18;
        weapon.name = string(abi.encodePacked("Masterwork ", weapon.name));
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