///SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./CharacterLibrary.sol";
import "./CharacterStatsCalculator.sol";

contract CharacterUriConstructor {

    ///@notice Encodes the strings into a JSON string
    function encodeStrings(character_properties memory character_props, character_uri_details memory uri_details, string memory _character_name) public pure returns (string memory uriJSON){
        uriJSON =
            string.concat(
            "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                                encodeDetails(uri_details, _character_name),
                                encodeProps(character_props, uri_details),
                                encodeStats(CharacterStatsCalculator.getCharacter(character_props))
                    )
                )
            );
    }

    function encodeDetails(character_uri_details memory uri_details, string memory _character_name) internal pure returns (string memory details_part){
        details_part = string.concat(
                            '{"description": "Characters", "image": "',uri_details.image,'", "name": "', _character_name,
                            '", "attributes": [',
                                '{"trait_type": "character_class", "value": "', uri_details.name,
                                '"}, {"display_type": "boost_percentage", "trait_type": "', uri_details.bonus,'", "value": ',uri_details.bonus_value,'}, ',
                                '{"trait_type": "mood", "value": "',uri_details.mood,'"}'
        );
    }

    function encodeProps(character_properties memory character_props, character_uri_details memory uri_details) internal pure returns (string memory props_part){
        props_part = string.concat(
                                ', {"trait_type": "STR", "max_value": 1000, "value": ', Strings.toString(character_props.str),
                                '}, {"trait_type": "VIT", "max_value": 1000, "value": ', Strings.toString(character_props.vit),
                                '}, {"trait_type": "DEX", "max_value": 1000, "value": ', Strings.toString(character_props.dex),
                                '}, {"trait_type": "Character Level", "max_value": 100, "value": ', Strings.toString((character_props.exp / 100) + 1),
                                '}, {"trait_type": "element", "value": "', CharacterLibrary.getElement(character_props.element),
                                '"}, {"display_type": "boost_percentage", "trait_type": "', CharacterLibrary.getTalent(character_props.talent),
                                '", "value": ', uri_details.talent_value,'}'
        );
    }

    function encodeStats(battle_stats memory _stats) internal pure returns (string memory stats_part){
        stats_part = string.concat(
                            ', {"display_type": "number", "trait_type": "ATK", "max_value": 9999, "value": ', Strings.toString(_stats.atk),
                            '}, {"display_type": "number", "trait_type": "DEF", "max_value": 9999, "value": ', Strings.toString(_stats.def),
                            '}, {"display_type": "number", "trait_type": "EVA", "max_value": 1000, "value": ', Strings.toString(_stats.eva),
                            '}, {"display_type": "number", "trait_type": "HP", "max_value": 9999, "value": ', Strings.toString(_stats.hp),
                            '}, {"display_type": "number", "trait_type": "PEN", "max_value": 1000, "value": ', Strings.toString(_stats.pen),
                            '}, {"display_type": "number", "trait_type": "CRIT", "max_value": 1000, "value": ', Strings.toString(_stats.crit),
                            '}, {"display_type": "number", "trait_type": "LUK", "max_value": 1000, "value": ', Strings.toString(_stats.luck),
                            '}, {"display_type": "number", "trait_type": "RES", "max_value": 1000, "value": ', Strings.toString(_stats.energy_restoration),
                            '}]}' /// <<< attributes array and JSON uri closes here
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
    @title Character Stats Calculator
    @author Eman @SgtChiliPapi
*/

import "../../libraries/structs/CharacterStructs.sol";
import "../../libraries/structs/GlobalStructs.sol";

library CharacterStatsCalculator{
    function getCharacter(character_properties memory properties) internal pure returns (battle_stats memory character){
        character = battle_stats({
            atk: getAttackPower(properties),
            def: getDefense(properties),
            eva: getEvasionChance(properties),
            hp: getHP(properties),
            pen: getPenetrationChance(properties),
            crit: getCriticalChance(properties),
            luck: getLuck(properties),
            energy_restoration: getEnergyRegen(properties)
        });
    }

    function getAttackPower(character_properties memory properties) internal pure returns (uint256 attack_power){
        attack_power = (((properties.str * 6) + (properties.dex * 4)) / 10) / 4;
        uint256 attack_bonus;
        if(properties.character_class == 0){attack_bonus = 5;} //Viking
        if(properties.talent == 0){attack_bonus += 5;} //Combat Psycho
        attack_power += (attack_power * attack_bonus) / 100;
    }

    function getPenetrationChance(character_properties memory properties) internal pure returns (uint256 penetration_chance){
        penetration_chance = (properties.str / 2);
        uint256 penetration_bonus;
        if(properties.character_class == 1){penetration_bonus = 10;} //Woodcutter
        if(properties.talent == 1){penetration_bonus += 10;} //Woodcutter
        penetration_chance += (penetration_chance * penetration_bonus) / 100;
    }

    function getHP(character_properties memory properties) internal pure returns (uint256 hp){
        hp = (properties.vit * 5);
        uint256 hp_bonus;
        if(properties.character_class == 2){hp_bonus = 3;} //Troll
        if(properties.talent == 2){hp_bonus += 3;} //Body Builder
        hp += (hp * hp_bonus) / 100;
    }

    function getDefense(character_properties memory properties) internal pure returns (uint256 defense){
        defense = (((properties.vit * 6) + (properties.str * 4)) / 10) / 2;
        uint256 defense_bonus;
        if(properties.character_class == 3){defense_bonus = 10;} //Troll
        if(properties.talent == 3){defense_bonus += 10;} //Iron Skin
        defense += (defense * defense_bonus) / 100;
    }

    function getCriticalChance(character_properties memory properties) internal pure returns (uint256 critical_chance){
        critical_chance = (properties.dex / 2);
        uint256 critical_bonus;
        if(properties.character_class == 4){critical_bonus = 10;} //Zooka
        if(properties.talent == 4){critical_bonus += 10;} //Sniper
        critical_chance += (critical_chance * critical_bonus) / 100;
    }
    function getEvasionChance(character_properties memory properties) internal pure returns (uint256 evasion_chance){
        evasion_chance = (((properties.dex * 6) + (properties.vit * 4)) / 10) / 2;
        uint256 evasion_bonus;
        if(properties.character_class == 5){evasion_bonus = 10;} //Graverobber
        if(properties.talent == 5){evasion_bonus += 10;} //Ninja
        evasion_chance += (evasion_chance * evasion_bonus) / 100;
    }

    function getLuck(character_properties memory properties) internal pure returns (uint256 luck){
        luck = properties.dex / 10;
    }

    function getEnergyRegen(character_properties memory properties) internal pure returns (uint256 energy_restoration){
        energy_restoration = ((properties.vit + properties.str) / 2 ) / 10;
    }
}

//SPDX-License-Identifier: MIT
/**
    @title Character URI Library
    @author Eman @SgtChiliPapi
    @notice: Reference for character Images and Names.
    
*/
pragma solidity =0.8.17;

import "../../libraries/structs/CharacterStructs.sol";

library CharacterLibrary {
    function getCharacter(uint32 character_class, uint32 mood, uint32 talent) internal pure returns (character_uri_details memory character){
        string memory image_url = "https://chainlink-rpg2022.infura-ipfs.io/ipfs/QmTnCQVzkFecBjLUTJTbJmu1Ds3simimu8Z1XKKksgc7as/";
        (string memory _class, string memory image_prefix, string memory mood_tag, string memory bonus_tag, string memory bonus_value, string memory talent_value) = getClass(character_class, mood, talent);
        character = character_uri_details({
            name: _class,
            image: string.concat(image_url, image_prefix, _class, "/", mood_tag,".png"),
            mood: mood_tag,
            bonus: bonus_tag,
            bonus_value: bonus_value,
            talent_value: talent_value
        });
    }

    function getClass(uint32 character_class, uint32 mood, uint32 talent) internal pure returns (string memory _class, string memory image_prefix, string memory mood_tag, string memory bonus_tag, string memory bonus_value, string memory talent_value){
        if(character_class == 0){_class = "Viking"; image_prefix = "0%20"; bonus_tag = "Viking (ATK)"; bonus_value = "5";}
        if(character_class == 1){_class = "Woodcutter"; image_prefix = "1%20"; bonus_tag = "Woodcutter (PEN)"; bonus_value = "10";}
        if(character_class == 2){_class = "Troll"; image_prefix = "4%20"; bonus_tag = "Troll (HP)"; bonus_value = "3";}
        if(character_class == 3){_class = "Mechanic"; image_prefix = "5%20"; bonus_tag = "Mechanic (DEF)"; bonus_value = "10";}
        if(character_class == 4){_class = "Amphibian"; image_prefix = "2%20"; bonus_tag = "Amphibian (CRIT)"; bonus_value = "10";}
        if(character_class == 5){_class = "GraveRobber"; image_prefix = "3%20"; bonus_tag = "Graverobber (EVA)"; bonus_value = "10";}
        mood_tag = getMood(mood);
        talent_value = getTalentValue(talent);
    }

    function getMood(uint32 mood) internal pure returns (string memory mood_tag){
        if(mood == 0){mood_tag = "Amazed";}
        if(mood == 1){mood_tag = "Angry";}
        if(mood == 2){mood_tag = "Calm";}
        if(mood == 3){mood_tag = "Irritated";}
        if(mood == 4){mood_tag = "Mocking";}
        if(mood == 5){mood_tag = "Sad";}
        if(mood == 6){mood_tag = "Scared";}
        if(mood == 7){mood_tag = "Stunned";}
        if(mood == 8){mood_tag = "Thoughtful";}
        if(mood == 9){mood_tag = "Upset";}
    }

    function getElement(uint32 element) internal pure returns (string memory element_tag){
        if(element == 0){element_tag = "Fire";}
        if(element == 1){element_tag = "Earth";}
        if(element == 2){element_tag = "Wind";}
        if(element == 3){element_tag = "Water";}
    }

    function getTalent(uint32 talent) internal pure returns (string memory talent_tag){
        if(talent == 0){talent_tag = "Combat Psycho (ATK)";}
        if(talent == 1){talent_tag = "Weapon Specialist (PEN)";}
        if(talent == 2){talent_tag = "Body Builder (HP)";}
        if(talent == 3){talent_tag = "Iron Skin (DEF)";}
        if(talent == 4){talent_tag = "Sniper (CRIT)";}
        if(talent == 5){talent_tag = "Ninja (EVA)";}
    }

    function getTalentValue(uint32 talent) internal pure returns (string memory talent_value){
        if(talent == 0){talent_value = "5";}
        if(talent == 1){talent_value = "10";}
        if(talent == 2){talent_value = "3";}
        if(talent == 3){talent_value = "10";}
        if(talent == 4){talent_value = "10";}
        if(talent == 5){talent_value = "10";}
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct character_properties { //SSTORED
    uint32 character_class;
    uint32 element;
    uint32 str;
    uint32 vit;
    uint32 dex;
    uint32 talent;
    uint32 mood;
    uint32 exp;
}

struct character_uri_details {
    string name;
    string image;
    string mood;
    string bonus;
    string bonus_value;
    string talent_value;
}

struct character_request { //SSTORED
    uint256 request_id;
    uint32 character_class;
    string _name;
    uint256 time_requested;
}

//SPDX-License-Identifier: MIT
/**
    @title Struct Library
    @author Eman @SgtChiliPapi
    @notice: Reference for global structs across contracts. 
    Originally created for CHAINLINK HACKATHON FALL 2022
*/

pragma solidity =0.8.17;

struct battle_stats {
    uint256 atk;
    uint256 def;
    uint256 eva;
    uint256 hp;
    uint256 pen;
    uint256 crit;
    uint256 luck;
    uint256 energy_restoration;
}







// struct attack_event {
//     uint256 attack_index;
//     uint256 challenger_hp;
//     uint256 defender_hp;
//     uint256 evaded;
//     uint256 critical_hit;
//     uint256 penetrated;
//     uint256 damage_to_challenger;
//     uint256 damage_to_defender;  
// }