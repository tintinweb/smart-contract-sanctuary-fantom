//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract rarity_extended_basic_set_armor_codex {
    string constant public index = "Items";
    string constant public class = "Armor";
    
    function get_proficiency_by_id(uint _id) public pure returns (string memory description) {
        if (_id == 1) {
            return "Light";
        } else if (_id == 2) {
            return "Medium";
        } else if (_id == 3) {
            return "Heavy";
        } else if (_id == 4) {
            return "Shields";
        }
    }

    function item_by_id(uint _id) public pure returns(
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        if (_id == 1) return padded();
        else if (_id == 2) return robe();
        else if (_id == 3) return leather();
        else if (_id == 4) return hide();
        else if (_id == 5) return chain_shirt();
        else if (_id == 6) return splint_mail();
        else if (_id == 7) return light_gloves();
        else if (_id == 8) return cestus();
        else if (_id == 9) return leather_gloves();
        else if (_id == 10) return metal_gloves();
        else if (_id == 11) return armored_bracers();
        else if (_id == 12) return light_shoes();
        else if (_id == 13) return stuffed_boots();
        else if (_id == 14) return war_boots();
        else if (_id == 15) return hood();
        else if (_id == 16) return magician_hat();
        else if (_id == 17) return fancy_hat();
        else if (_id == 18) return warrior_helmet();
        else if (_id == 19) return practice_shield();
    }

    /*******************************************************************************
    **  @notice: Body armors, from 1 to 6
	*******************************************************************************/
    function padded() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 1;
        name = "Padded";
        cost = 5e18;
        proficiency = 1;
        weight = 10;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 5;
        description = "";
    }

    function robe() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 2;
        name = "Robe";
        cost = 5e18;
        proficiency = 1;
        weight = 6;
        armor_bonus = 1;
        max_dex_bonus = 6;
        penalty = 0;
        spell_failure = 0;
        description = "A very light robe. Covers your body, that's all";
    }

    function leather() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 3;
        name = "Leather";
        cost = 10e18;
        proficiency = 1;
        weight = 15;
        armor_bonus = 2;
        max_dex_bonus = 6;
        penalty = 0;
        spell_failure = 10;
        description = "";
    }

    function hide() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 4;
        name = "Hide";
        cost = 15e18;
        proficiency = 2;
        weight = 25;
        armor_bonus = 3;
        max_dex_bonus = 4;
        penalty = -3;
        spell_failure = 20;
        description = "";
    }

    function chain_shirt() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 5;
        name = "Chain shirt";
        cost = 100e18;
        proficiency = 1;
        weight = 25;
        armor_bonus = 4;
        max_dex_bonus = 4;
        penalty = -2;
        spell_failure = 20;
        description = "A chain shirt comes with a steel cap.";
    }

    function splint_mail() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 6;
        name = "Splint mail";
        cost = 200e18;
        proficiency = 3;
        weight = 45;
        armor_bonus = 6;
        max_dex_bonus = 0;
        penalty = -7;
        spell_failure = 40;
        description = "The suit is heavy and perfect for a begginer.";
    }

    /*******************************************************************************
    **  @notice: Hand armors, from 7 to 11
	*******************************************************************************/
    function light_gloves() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 7;
        name = "Light gloves";
        cost = 5e18;
        proficiency = 1;
        weight = 2;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 0;
        description = "Do not expect them to protect you from the cold.";
    }

    function cestus() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 8;
        name = "Cestus";
        cost = 15e18;
        proficiency = 1;
        weight = 4;
        armor_bonus = 1;
        max_dex_bonus = 10;
        penalty = 0;
        spell_failure = 10;
        description = "A reinforced gauntlet which protects the knuckles.";
    }

    function leather_gloves() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 9;
        name = "Leather gloves";
        cost = 15e18;
        proficiency = 2;
        weight = 6;
        armor_bonus = 2;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 10;
        description = "A basic pair of leather gloves.";
    }

    function metal_gloves() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 10;
        name = "Metal gloves";
        cost = 20e18;
        proficiency = 2;
        weight = 8;
        armor_bonus = 3;
        max_dex_bonus = 6;
        penalty = 0;
        spell_failure = 20;
        description = "Perfect to hit, uncomfy to wash your teeth";
    }

    function armored_bracers() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 11;
        name = "Armored bracers";
        cost = 30e18;
        proficiency = 3;
        weight = 10;
        armor_bonus = 4;
        max_dex_bonus = 5;
        penalty = 0;
        spell_failure = 40;
        description = "A pair of heavy armor plated gloves that fit over the forearms and hands, that are good for bludgeoning. It's like strapping an anvil to your hand and punching someone in the face with it.";
    }


    /*******************************************************************************
    **  @notice: Foot armors, from 12 to 14
	*******************************************************************************/
    function light_shoes() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 12;
        name = "Light shoes";
        cost = 5e18;
        proficiency = 1;
        weight = 2;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 0;
        description = "Simple shoes. Does not protect you from this little rock in your shoe.";
    }

    function stuffed_boots() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 13;
        name = "Stuffed boots";
        cost = 30e18;
        proficiency = 2;
        weight = 10;
        armor_bonus = 2;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 10;
        description = "Warm and nice, but not the best for the smell.";
    }

    function war_boots() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 14;
        name = "War boots";
        cost = 40e18;
        proficiency = 3;
        weight = 15;
        armor_bonus = 3;
        max_dex_bonus = 6;
        penalty = -1;
        spell_failure = 10;
        description = "They are rusty, but will protect you. For some time. Little time.";
    }

    /*******************************************************************************
    **  @notice: Head armors, from 15 to 18
	*******************************************************************************/
    function hood() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 15;
        name = "Hood";
        cost = 5e18;
        proficiency = 1;
        weight = 2;
        armor_bonus = 1;
        max_dex_bonus = 10;
        penalty = 0;
        spell_failure = 0;
        description = "A very basic hood.";
    }

    function magician_hat() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 16;
        name = "Magician hat";
        cost = 5e18;
        proficiency = 1;
        weight = 1;
        armor_bonus = 1;
        max_dex_bonus = 10;
        penalty = 0;
        spell_failure = 0;
        description = "The only protection is preventing your hair from burning with the flying candles";
    }

    function fancy_hat() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 17;
        name = "Fancy hat";
        cost = 30e18;
        proficiency = 1;
        weight = 1;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = 0;
        spell_failure = 0;
        description = "You want everyone to know how fancy you are.";
    }

    function warrior_helmet() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 18;
        name = "Warrior helmet";
        cost = 50e18;
        proficiency = 3;
        weight = 6;
        armor_bonus = 3;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 20;
        description = "Every warrior needs one";
    }

    /*******************************************************************************
    **  @notice: Shield, from 19 to 19
	*******************************************************************************/
    function practice_shield() public pure returns (
        uint id,
        uint cost,
        uint proficiency,
        uint weight,
        uint armor_bonus,
        uint max_dex_bonus,
        int penalty,
        uint spell_failure,
        string memory name,
        string memory description
    ) {
        id = 19;
        name = "Practice shield";
        cost = 15e18;
        proficiency = 4;
        weight = 5;
        armor_bonus = 1;
        max_dex_bonus = 8;
        penalty = -1;
        spell_failure = 5;
        description = "A practice shield that should only be used for training.";
    }
}