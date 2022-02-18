//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract rarity_extended_basic_set_weapon_codex {
    string constant public index = "Items";
    string constant public class = "Weapons";
    
    function get_proficiency_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Simple";
        } else if (_id == 2) {
            return "Martial";
        } else if (_id == 3) {
            return "Exotic";
        }
    }
    
    function get_encumbrance_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Unarmed";
        } else if (_id == 2) {
            return "Light Melee Weapons";
        } else if (_id == 3) {
            return "One-Handed Melee Weapons";
        } else if (_id == 4) {
            return "Two-Handed Melee Weapons";
        } else if (_id == 5) {
            return "Ranged Weapons";
        }
    }
    
    function get_damage_type_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Bludgeoning";
        } else if (_id == 2) {
            return "Piercing";
        } else if (_id == 3) {
            return "Slashing";
        } else if (_id == 4) {
            return "Magical";
        }
    }
    
    struct weapon {
        uint id;
        uint cost;
        uint proficiency;
        uint encumbrance;
        uint damage_type;
        uint weight;
        uint damage;
        uint critical;
        int critical_modifier;
        uint range_increment;
        string name;
        string description;
    }

    function item_by_id(uint _id) public pure returns(weapon memory _weapon) {
        if (_id == 1) return dagger();
        else if (_id == 2) return sickle();
        else if (_id == 3) return hammer_light();
        else if (_id == 4) return greataxe();
        else if (_id == 5) return sword_short();
        else if (_id == 6) return longsword();
        else if (_id == 7) return longbow();
		else if (_id == 8) return gauntlet();
		else if (_id == 9) return wand();
    }

    function dagger() public pure returns (weapon memory _weapon) {
        _weapon.id = 1;
        _weapon.name = "Dagger";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "You get a +2 bonus on Sleight of Hand checks made to conceal a dagger on your body (see the Sleight of Hand skill).";
    }

    function sickle() public pure returns (weapon memory _weapon) {
        _weapon.id = 2;
        _weapon.name = "Sickle";
        _weapon.cost = 6e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 3;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "A sickle can be used to make trip attacks. If you are tripped during your own trip attempt, you can drop the sickle to avoid being tripped.";
    }

    function hammer_light() public pure returns (weapon memory _weapon) {
        _weapon.id = 3;
        _weapon.name = "Hammer, light";
        _weapon.cost = 1e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 1;
        _weapon.weight = 2;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function greataxe() public pure returns (weapon memory _weapon) {
        _weapon.id = 4;
        _weapon.name = "Greataxe";
        _weapon.cost = 20e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 4;
        _weapon.damage_type = 3;
        _weapon.weight = 12;
        _weapon.damage = 12;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function sword_short() public pure returns (weapon memory _weapon) {
        _weapon.id = 5;
        _weapon.name = "Sword, short";
        _weapon.cost = 10e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 2;
        _weapon.weight = 2;
        _weapon.damage = 6;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function longsword() public pure returns (weapon memory _weapon) {
        _weapon.id = 6;
        _weapon.name = "Longsword";
        _weapon.cost = 15e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 3;
        _weapon.damage_type = 3;
        _weapon.weight = 4;
        _weapon.damage = 8;
        _weapon.critical = 2;
        _weapon.critical_modifier = -1;
        _weapon.range_increment = 0;
        _weapon.description = "";
    }

    function longbow() public pure returns (weapon memory _weapon) {
        _weapon.id = 7;
        _weapon.name = "Longbow";
        _weapon.cost = 75e18;
        _weapon.proficiency = 2;
        _weapon.encumbrance = 5;
        _weapon.damage_type = 2;
        _weapon.weight = 3;
        _weapon.damage = 8;
        _weapon.critical = 3;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 100;
        _weapon.description = "You need at least two hands to use a bow, regardless of its size. A longbow is too unwieldy to use while you are mounted. If you have a penalty for low Strength, apply it to damage rolls when you use a longbow. If you have a bonus for high Strength, you can apply it to damage rolls when you use a composite longbow (see below) but not a regular longbow.";
    }

    function gauntlet() public pure returns (weapon memory _weapon) {
        _weapon.id = 8;
        _weapon.name = "Gauntlet";
        _weapon.cost = 2e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 1;
        _weapon.damage_type = 1;
        _weapon.weight = 1;
        _weapon.damage = 3;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 0;
        _weapon.description = "This metal glove lets you deal lethal damage rather than nonlethal damage with unarmed strikes. A strike with a gauntlet is otherwise considered an unarmed attack. The cost and weight given are for a single gauntlet. Medium and heavy armors (except breastplate) come with gauntlets.";
    }

    function wand() public pure returns (weapon memory _weapon) {
        _weapon.id = 9;
        _weapon.name = "Wand";
        _weapon.cost = 5e18;
        _weapon.proficiency = 1;
        _weapon.encumbrance = 2;
        _weapon.damage_type = 4;
        _weapon.weight = 1;
        _weapon.damage = 4;
        _weapon.critical = 2;
        _weapon.critical_modifier = 0;
        _weapon.range_increment = 20;
        _weapon.description = "It's a stick, but with magical powers.";
    }
}