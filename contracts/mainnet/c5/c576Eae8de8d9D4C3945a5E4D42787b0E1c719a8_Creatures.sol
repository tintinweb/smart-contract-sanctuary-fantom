/**
 *Submitted for verification at FtmScan.com on 2022-07-02
*/

// File: @openzeppelin/contracts/utils/Strings.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
}

// File: @openzeppelin/contracts/utils/Base64.sol

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
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
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

// File: contracts/storage/_BabyCreatureStorage.sol

pragma solidity ^0.8.14;

contract _BabyCreatureStorage {
    uint256 public constant CREATURE_ATTR_NUM = 13;
    address internal constant ZERO_ADDRESS = address(0);
    bytes32 internal constant STORAGE_POSITION =
        keccak256("games.wolfland.contracts.babycreaturestorage");

    struct BabyCreatureStorage {
        mapping(uint64 => uint256) breedingDuration;
        mapping(uint64 => uint256[]) breedingCurrency;
        mapping(uint256 => uint64[CREATURE_ATTR_NUM]) creatureAttributesMap;
        mapping(address => Stake[]) stakes;
        string[][12] sheepTraitNames;
        string[][12] sheepTraitImages;
        string[][12] wolfTraitNames;
        string[][12] wolfTraitImages;
    }

    struct Stake {
        uint256 start;
        uint256 end;
        uint256 male;
        uint256 female;
    }

    function babyCreatureStorage()
        internal
        pure
        returns (BabyCreatureStorage storage _storage)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            _storage.slot := position
        }
    }
}

// File: contracts/utils/Creatures.sol

pragma solidity ^0.8.14;

library Creatures {
    uint256 private constant CREATURE_ATTR_NUM = 13;
    bytes32 private constant STORAGE_POSITION =
        keccak256("games.wolfland.contracts.babycreaturestorage");

    function createURIFor(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        (
            string memory name,
            string memory attrJson,
            string memory attrSvg
        ) = _jsonSvg(tokenId);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "{",
                            name,
                            " #",
                            Strings.toString(tokenId),
                            '",',
                            '"description" : "',
                            _description(),
                            '",',
                            '"image" : "',
                            attrSvg,
                            '","attributes" : ',
                            attrJson,
                            "}"
                        )
                    )
                )
            );
    }

    function _jsonSvg(uint256 tokenId)
        private
        view
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        _BabyCreatureStorage.BabyCreatureStorage
            storage _storage = _babyCreatureStorage();
        string[12] memory creatureAttributes;
        string[12] memory creatureImages;
        (creatureAttributes, creatureImages) = _getNamesImagesFor(
            _storage.creatureAttributesMap[tokenId]
        );

        string memory name = string(
            abi.encodePacked(
                '"name" : "',
                creatureAttributes[2],
                " ",
                creatureAttributes[1]
            )
        );

        string memory json = string(abi.encodePacked("["));
        string memory svg = string(
            abi.encodePacked(
                '<svg width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
            )
        );
        for (uint256 i = 0; i < 12; i++) {
            json = string(
                abi.encodePacked(
                    json,
                    _jsonFor(_nameFor(i), creatureAttributes[i]),
                    ","
                )
            );
            if (
                keccak256(abi.encodePacked(creatureImages[i])) != _emptyString()
            ) {
                svg = string(abi.encodePacked(svg, _tagFor(creatureImages[i])));
            }
        }
        json = string(
            abi.encodePacked(
                json,
                _jsonFor(
                    _nameFor(12),
                    Strings.toString(
                        _storage.creatureAttributesMap[tokenId][12]
                    )
                ),
                "]"
            )
        );
        svg = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(abi.encodePacked(svg, "</svg>"))
            )
        );
        return (name, json, svg);
    }

    function _getNamesImagesFor(
        uint64[CREATURE_ATTR_NUM] memory creatureAttributes
    ) private view returns (string[12] memory, string[12] memory) {
        string[12] memory attrNames;
        string[12] memory attrImages;
        string[] memory traitNames;
        string[] memory traitImages;
        uint256 traitIndex;
        bool sheep = creatureAttributes[1] == 1 ? true : false;

        for (uint256 i = 0; i < 12; i++) {
            traitIndex = creatureAttributes[i];
            (traitNames, traitImages) = _getNamesImagesFor(sheep, i);

            assert(
                traitNames.length > traitIndex &&
                    traitImages.length > traitIndex
            );
            attrNames[i] = traitNames[traitIndex];
            attrImages[i] = traitImages[traitIndex];
        }
        return (attrNames, attrImages);
    }

    function _getNamesImagesFor(bool sheep, uint256 trait)
        private
        view
        returns (string[] memory, string[] memory)
    {
        _BabyCreatureStorage.BabyCreatureStorage
            storage _storage = _babyCreatureStorage();
        return
            sheep
                ? (
                    _storage.sheepTraitNames[trait],
                    _storage.sheepTraitImages[trait]
                )
                : (
                    _storage.wolfTraitNames[trait],
                    _storage.wolfTraitImages[trait]
                );
    }

    function _traitNames()
        private
        pure
        returns (string[CREATURE_ATTR_NUM] memory)
    {
        string[CREATURE_ATTR_NUM] memory names = [
            "Gender",
            "Class",
            "Age",
            "Fur",
            "Head",
            "Ears",
            "Eyes",
            "Nose",
            "Mouth",
            "Neck",
            "Feet",
            "Alpha",
            "Bred"
        ];
        return names;
    }

    function _babyCreatureStorage()
        private
        pure
        returns (_BabyCreatureStorage.BabyCreatureStorage storage _storage)
    {
        bytes32 position = STORAGE_POSITION;
        assembly {
            _storage.slot := position
        }
    }

    function _jsonFor(string memory trait, string memory value)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type" : "',
                    trait,
                    '", "value" : "',
                    value,
                    '" }'
                )
            );
    }

    function _nameFor(uint256 trait) private pure returns (string memory) {
        return _traitNames()[trait];
    }

    function _tagFor(string memory image) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    image,
                    '"/>'
                )
            );
    }

    function _emptyString() private pure returns (bytes32) {
        string memory empty = "";
        return keccak256(abi.encodePacked(empty));
    }

    function _description() private pure returns (string memory) {
        string
            memory description = "After a long cold winter our weary sheep and hungry wolves finally stretching their legs, getting fed and preparing for the breeding. We need to choose parents wisely so their descendants will be beautiful and powerful. Rare traits will make a difference in the later phases of the game and might become a great collectables.";
        return description;
    }
}