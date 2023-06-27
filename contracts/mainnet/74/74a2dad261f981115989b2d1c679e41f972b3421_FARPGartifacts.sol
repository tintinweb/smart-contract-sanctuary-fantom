/**
 *Submitted for verification at FtmScan.com on 2023-06-27
*/

// File: contracts/myArtifact.sol


pragma solidity ^0.8.0;

library Ar {
    struct ArtifactsEffects {
        uint16 id;         // The unique ID of the Pet, used to track the same token
        uint32 A;   // HP +
        uint32 B;  // STR +
        uint32 C;   // AGI +
        uint32 D;   // INT +
        uint8 R; // rarity 0 = gold, 1 = common, 2 = rare, 3 = mystical
        uint8 set; // if there is set artifact, this will indicate whether they are same set for extra effect
    }
    struct ArtifactsMetadata {
        string name;   // The name of the artifact
        string description;   // The unique ID of the Pet, used to track the same token
        uint8 slot; //this artifact is meant to wear for head/body/etc
    }
}
// File: contracts/AMetadata.sol



pragma solidity ^0.8.2;

library AMeta {
     

    function _getAEbyID(uint16 _id) private pure returns (Ar.ArtifactsEffects memory AE){
        if (_id == 0) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 0, 0, 0, 0);
        } else if (_id == 1) {
            AE = Ar.ArtifactsEffects(_id, 5, 5, 0, 0, 1, 1);
        } else if (_id == 2) {
            AE = Ar.ArtifactsEffects(_id, 5, 0, 5, 0, 1, 2);
        } else if (_id == 3) {
            AE = Ar.ArtifactsEffects(_id, 5, 0, 0, 5, 1, 3);
        } else if (_id == 4) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 5, 0, 1, 4);
        } else if (_id == 5) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 0, 5, 1, 5);
        } else if (_id == 6) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 10, 10, 2, 6);
        } else if (_id == 7) {
            AE = Ar.ArtifactsEffects(_id, 10, 10, 0, 0, 2, 7);
        } else if (_id == 8) {
            AE = Ar.ArtifactsEffects(_id, 0, 10, 10, 0, 2, 8);
        } else if (_id == 9) {
            AE = Ar.ArtifactsEffects(_id, 15, 0, 0, 15, 3, 9);
        } else if (_id == 10) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 15, 0, 3, 10);
        } else if (_id == 11) {
            AE = Ar.ArtifactsEffects(_id, 5, 0, 5, 0, 1, 1);
        } else if (_id == 12) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 0, 5, 1, 2);
        } else if (_id == 13) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 5, 0, 1, 3);
        } else if (_id == 14) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 5, 5, 1, 4);
        } else if (_id == 15) {
            AE = Ar.ArtifactsEffects(_id, 5, 5, 0, 0, 1, 5);
        } else if (_id == 16) {
            AE = Ar.ArtifactsEffects(_id, 10, 0, 10, 0, 2, 6); 
        } else if (_id == 17) {
            AE = Ar.ArtifactsEffects(_id, 0, 10, 0, 10, 2, 7);
        } else if (_id == 18) {
            AE = Ar.ArtifactsEffects(_id, 0, 10, 10, 0, 2, 8);
        } else if (_id == 19) {
            AE = Ar.ArtifactsEffects(_id, 15, 0, 0, 15, 3, 9);
        } else if (_id == 20) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 15, 0, 3, 10);
        } else if (_id == 21) {
            AE = Ar.ArtifactsEffects(_id, 5, 5, 0, 0, 1, 1);
        } else if (_id == 22) {
            AE = Ar.ArtifactsEffects(_id, 10, 0, 0, 0, 1, 2);
        } else if (_id == 23) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 5, 0, 1, 3);
        } else if (_id == 24) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 5, 5, 1, 4);
        } else if (_id == 25) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 0, 5, 1, 5);
        } else if (_id == 26) {
            AE = Ar.ArtifactsEffects(_id, 15, 0, 5, 0, 2, 6);
        } else if (_id == 27) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 5, 0, 2, 7);
        } else if (_id == 28) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 5, 15, 2, 8);
        } else if (_id == 29) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 15, 15, 3, 9);
        } else if (_id == 30) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 0, 15, 3, 10);
        }
    } 
    function _getAMbyID(uint16 _id) private pure returns (Ar.ArtifactsMetadata memory AM){
        string memory itemDescription = "The effectiveness of this item relies on the presence of duplicate artifacts in your inventory. Your current multiplier, referred to as n is determined by the number of duplicate artifacts you have equipped. To determine how many duplicates you need to reach a specific multiplier, you can utilize the formula 2 raised to the power of (n minus 1). For example, if you have 130 duplicates, you will attain a multiplier of 8. It's important to note that the maximum achievable multiplier is 9. The higher your multiplier, the more powerful the effects of the item become. To improve your gameplay performance, prioritize collecting additional duplicate artifacts to increase your multiplier.";
        if (_id == 0) {
            AM = Ar.ArtifactsMetadata("Gold", "A rare and precious resource, holds immense value in the realm. Its utility and purpose are yet to be discovered, waiting to unlock hidden secrets and potential within the world.", 0);
        } else if (_id == 1) {
            AM = Ar.ArtifactsMetadata("Ruby Ribbon", itemDescription, 1);
        } else if (_id == 2) {
            AM = Ar.ArtifactsMetadata("Lily Elegance", itemDescription, 1);
        } else if (_id == 3) {
            AM = Ar.ArtifactsMetadata("Faux Fecal", itemDescription, 1);
        } else if (_id == 4) {
            AM = Ar.ArtifactsMetadata("Pearl Petal", itemDescription, 1);
        } else if (_id == 5) {
            AM = Ar.ArtifactsMetadata("Breezeleaf", itemDescription, 1);
        } else if (_id == 6) {
            AM = Ar.ArtifactsMetadata("Whisker Wonderland", itemDescription, 1);
        } else if (_id == 7) {
            AM = Ar.ArtifactsMetadata("Featherflight", itemDescription, 1);
        } else if (_id == 8) {
            AM = Ar.ArtifactsMetadata("Purrfect Pinnacles", itemDescription, 1);
        } else if (_id == 9) {
            AM = Ar.ArtifactsMetadata("Twilight Flicker", itemDescription, 1);
        } else if (_id == 10) {
            AM = Ar.ArtifactsMetadata("Celestial Halo", itemDescription, 1);
        } else if (_id == 11) {
            AM = Ar.ArtifactsMetadata("Scholar - R", itemDescription, 2);
        } else if (_id == 12) {
            AM = Ar.ArtifactsMetadata("Scholar - Y", itemDescription, 2);
        } else if (_id == 13) {
            AM = Ar.ArtifactsMetadata("Scholar - B", itemDescription, 2);
        } else if (_id == 14) {
            AM = Ar.ArtifactsMetadata("Scholar - G", itemDescription, 2);
        } else if (_id == 15) {
            AM = Ar.ArtifactsMetadata("Scholar - C", itemDescription, 2);
        } else if (_id == 16) {
            AM = Ar.ArtifactsMetadata("Love Embrace - C", itemDescription, 2);
        } else if (_id == 17) {
            AM = Ar.ArtifactsMetadata("Love Embrace - P", itemDescription, 2);
        } else if (_id == 18) {
            AM = Ar.ArtifactsMetadata("Love Embrace - G", itemDescription, 2);
        } else if (_id == 19) {
            AM = Ar.ArtifactsMetadata("Celestial Harmony - X", itemDescription, 2);
        } else if (_id == 20) {
            AM = Ar.ArtifactsMetadata("Celestial Harmony - Y", itemDescription, 2);
        } else if (_id == 21) {
            AM = Ar.ArtifactsMetadata("Orbito Hex", itemDescription, 3);
        } else if (_id == 22) {
            AM = Ar.ArtifactsMetadata("Orbito Trix", itemDescription, 3);
        } else if (_id == 23) {
            AM = Ar.ArtifactsMetadata("Orbito Loid", itemDescription, 3);
        } else if (_id == 24) {
            AM = Ar.ArtifactsMetadata("Orbito Volt", itemDescription, 3);
        } else if (_id == 25) {
            AM = Ar.ArtifactsMetadata("Orbito Blaze", itemDescription, 3);
        } else if (_id == 26) {
            AM = Ar.ArtifactsMetadata("AeroBot Ion", itemDescription, 3);
        } else if (_id == 27) {
            AM = Ar.ArtifactsMetadata("AeroBot Byte", itemDescription, 3);
        } else if (_id == 28) {
            AM = Ar.ArtifactsMetadata("AeroBot Techno", itemDescription, 3);
        } else if (_id == 29) {
            AM = Ar.ArtifactsMetadata("Floatron Core", itemDescription, 3);
        } else if (_id == 30) {
            AM = Ar.ArtifactsMetadata("Floatron Pyro", itemDescription, 3);
        }

    } 
    function getAEbyID(uint16 _id) external pure returns (Ar.ArtifactsEffects memory AE){
        if (_id == 0) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 0, 0, 0, 0);
        } else if (_id == 1) {
            AE = Ar.ArtifactsEffects(_id, 5, 5, 0, 0, 1, 1);
        } else if (_id == 2) {
            AE = Ar.ArtifactsEffects(_id, 5, 0, 5, 0, 1, 2);
        } else if (_id == 3) {
            AE = Ar.ArtifactsEffects(_id, 5, 0, 0, 5, 1, 3);
        } else if (_id == 4) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 5, 0, 1, 4);
        } else if (_id == 5) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 0, 5, 1, 5);
        } else if (_id == 6) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 10, 10, 2, 6);
        } else if (_id == 7) {
            AE = Ar.ArtifactsEffects(_id, 10, 10, 0, 0, 2, 7);
        } else if (_id == 8) {
            AE = Ar.ArtifactsEffects(_id, 0, 10, 10, 0, 2, 8);
        } else if (_id == 9) {
            AE = Ar.ArtifactsEffects(_id, 15, 0, 0, 15, 3, 9);
        } else if (_id == 10) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 15, 0, 3, 10);
        } else if (_id == 11) {
            AE = Ar.ArtifactsEffects(_id, 5, 0, 5, 0, 1, 1);
        } else if (_id == 12) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 0, 5, 1, 2);
        } else if (_id == 13) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 5, 0, 1, 3);
        } else if (_id == 14) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 5, 5, 1, 4);
        } else if (_id == 15) {
            AE = Ar.ArtifactsEffects(_id, 5, 5, 0, 0, 1, 5);
        } else if (_id == 16) {
            AE = Ar.ArtifactsEffects(_id, 10, 0, 10, 0, 2, 6); 
        } else if (_id == 17) {
            AE = Ar.ArtifactsEffects(_id, 0, 10, 0, 10, 2, 7);
        } else if (_id == 18) {
            AE = Ar.ArtifactsEffects(_id, 0, 10, 10, 0, 2, 8);
        } else if (_id == 19) {
            AE = Ar.ArtifactsEffects(_id, 15, 0, 0, 15, 3, 9);
        } else if (_id == 20) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 15, 0, 3, 10);
        } else if (_id == 21) {
            AE = Ar.ArtifactsEffects(_id, 5, 5, 0, 0, 1, 1);
        } else if (_id == 22) {
            AE = Ar.ArtifactsEffects(_id, 10, 0, 0, 0, 1, 2);
        } else if (_id == 23) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 5, 0, 1, 3);
        } else if (_id == 24) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 5, 5, 1, 4);
        } else if (_id == 25) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 0, 5, 1, 5);
        } else if (_id == 26) {
            AE = Ar.ArtifactsEffects(_id, 15, 0, 5, 0, 2, 6);
        } else if (_id == 27) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 5, 0, 2, 7);
        } else if (_id == 28) {
            AE = Ar.ArtifactsEffects(_id, 0, 0, 5, 15, 2, 8);
        } else if (_id == 29) {
            AE = Ar.ArtifactsEffects(_id, 0, 5, 15, 15, 3, 9);
        } else if (_id == 30) {
            AE = Ar.ArtifactsEffects(_id, 0, 15, 0, 15, 3, 10);
        }
    } 
    function getAMbyID(uint16 _id) external pure returns (Ar.ArtifactsMetadata memory AM){
        string memory itemDescription = "The effectiveness of this item relies on the presence of duplicate artifacts in your inventory. Your current multiplier, referred to as n is determined by the number of duplicate artifacts you have equipped. To determine how many duplicates you need to reach a specific multiplier, you can utilize the formula 2 raised to the power of (n minus 1). For example, if you have 130 duplicates, you will attain a multiplier of 8. It's important to note that the maximum achievable multiplier is 9. The higher your multiplier, the more powerful the effects of the item become. To improve your gameplay performance, prioritize collecting additional duplicate artifacts to increase your multiplier.";
        if (_id == 0) {
            AM = Ar.ArtifactsMetadata("Gold", "A rare and precious resource, holds immense value in the realm. Its utility and purpose are yet to be discovered, waiting to unlock hidden secrets and potential within the world.", 0);
        } else if (_id == 1) {
            AM = Ar.ArtifactsMetadata("Ruby Ribbon", itemDescription, 1);
        } else if (_id == 2) {
            AM = Ar.ArtifactsMetadata("Lily Elegance", itemDescription, 1);
        } else if (_id == 3) {
            AM = Ar.ArtifactsMetadata("Faux Fecal", itemDescription, 1);
        } else if (_id == 4) {
            AM = Ar.ArtifactsMetadata("Pearl Petal", itemDescription, 1);
        } else if (_id == 5) {
            AM = Ar.ArtifactsMetadata("Breezeleaf", itemDescription, 1);
        } else if (_id == 6) {
            AM = Ar.ArtifactsMetadata("Whisker Wonderland", itemDescription, 1);
        } else if (_id == 7) {
            AM = Ar.ArtifactsMetadata("Featherflight", itemDescription, 1);
        } else if (_id == 8) {
            AM = Ar.ArtifactsMetadata("Purrfect Pinnacles", itemDescription, 1);
        } else if (_id == 9) {
            AM = Ar.ArtifactsMetadata("Twilight Flicker", itemDescription, 1);
        } else if (_id == 10) {
            AM = Ar.ArtifactsMetadata("Celestial Halo", itemDescription, 1);
        } else if (_id == 11) {
            AM = Ar.ArtifactsMetadata("Scholar - R", itemDescription, 2);
        } else if (_id == 12) {
            AM = Ar.ArtifactsMetadata("Scholar - Y", itemDescription, 2);
        } else if (_id == 13) {
            AM = Ar.ArtifactsMetadata("Scholar - B", itemDescription, 2);
        } else if (_id == 14) {
            AM = Ar.ArtifactsMetadata("Scholar - G", itemDescription, 2);
        } else if (_id == 15) {
            AM = Ar.ArtifactsMetadata("Scholar - C", itemDescription, 2);
        } else if (_id == 16) {
            AM = Ar.ArtifactsMetadata("Love Embrace - C", itemDescription, 2);
        } else if (_id == 17) {
            AM = Ar.ArtifactsMetadata("Love Embrace - P", itemDescription, 2);
        } else if (_id == 18) {
            AM = Ar.ArtifactsMetadata("Love Embrace - G", itemDescription, 2);
        } else if (_id == 19) {
            AM = Ar.ArtifactsMetadata("Celestial Harmony - X", itemDescription, 2);
        } else if (_id == 20) {
            AM = Ar.ArtifactsMetadata("Celestial Harmony - Y", itemDescription, 2);
        } else if (_id == 21) {
            AM = Ar.ArtifactsMetadata("Orbito Hex", itemDescription, 3);
        } else if (_id == 22) {
            AM = Ar.ArtifactsMetadata("Orbito Trix", itemDescription, 3);
        } else if (_id == 23) {
            AM = Ar.ArtifactsMetadata("Orbito Loid", itemDescription, 3);
        } else if (_id == 24) {
            AM = Ar.ArtifactsMetadata("Orbito Volt", itemDescription, 3);
        } else if (_id == 25) {
            AM = Ar.ArtifactsMetadata("Orbito Blaze", itemDescription, 3);
        } else if (_id == 26) {
            AM = Ar.ArtifactsMetadata("AeroBot Ion", itemDescription, 3);
        } else if (_id == 27) {
            AM = Ar.ArtifactsMetadata("AeroBot Byte", itemDescription, 3);
        } else if (_id == 28) {
            AM = Ar.ArtifactsMetadata("AeroBot Techno", itemDescription, 3);
        } else if (_id == 29) {
            AM = Ar.ArtifactsMetadata("Floatron Core", itemDescription, 3);
        } else if (_id == 30) {
            AM = Ar.ArtifactsMetadata("Floatron Pyro", itemDescription, 3);
        }
    } 
    function getSlotbyID(uint8 _id) external pure returns (uint8 slot){
        if (_id == 0) {
            slot = 0;
        } else if (_id >= 1 && _id <= 10) {
            slot = 1;
        } else if (_id >= 11 && _id <= 20) {
            slot = 2;
        } else if (_id >= 21 && _id <= 30) {
            slot = 3;
        }
    }
    function _getEquipedArtifactsEffects(uint8[3] memory id, uint8[3] memory multiplier) external pure returns (uint32[4] memory ABCD) {
        Ar.ArtifactsEffects memory AE1 = _getAEbyID(id[0]);
        Ar.ArtifactsEffects memory AE2 = _getAEbyID(id[1]);
        Ar.ArtifactsEffects memory AE3 = _getAEbyID(id[2]);

        ABCD[0] = AE1.A*multiplier[0]+ AE2.A*multiplier[1] + AE3.A*multiplier[2];
        ABCD[1] = AE1.B*multiplier[0]+ AE2.B*multiplier[1] + AE3.B*multiplier[2];
        ABCD[2] = AE1.C*multiplier[0]+ AE2.C*multiplier[1] + AE3.C*multiplier[2];
        ABCD[3] = AE1.D*multiplier[0]+ AE2.D*multiplier[1] + AE3.D*multiplier[2];

           
    }

    
}

// File: contracts/base64.sol



pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/Artifact.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;






/**
 * @title IERC2981
 * @dev Interface for the ERC2981: NFT Royalty Standard extension, which extends the ERC721 standard.
 */
interface IERC2981 is IERC165 {

  /**
   * @notice Called with the sale price to determine how much royalty is owed and to whom.
   * @param _tokenId - The ID of the NFT asset queried for royalty information.
   * @param _salePrice - The sale price of the NFT asset specified by _tokenId.
   * @return receiver - Address of who should be sent the royalty payment.
   * @return royaltyAmount - The royalty payment amount for _salePrice.
   */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view
        returns (address receiver, uint256 royaltyAmount);
} 

contract FARPGartifacts is IERC2981, ERC1155, Ownable {

    constructor() ERC1155("") {
        
    }
     
    string public name = "FantomAdventureRPG Artifact";
    string public symbol = "aFARPG";
    bool public confirmed = false;
    bool public stopgen = false;
    string public constant baseUri = "ipfs://";
    string public imageExtension = ".png";
    string public imageURL = "https://ipfs.io/ipfs/QmY2LxnJbFe2e3BeHfsziNxsnube1oGNQaFLPfJnqeqUYh/";
    bool public _namebyID = true; //indicate where it needs to have ID 123 on name
  
    
    function setImageURL(string memory URL) public onlyOwner {
        imageURL = URL;//IPFS/server is less realiable, Only URI link is upgradable.
        //URI is just for marketplace to display.
    }
    function setExtension(string memory exe) public onlyOwner {
        imageExtension = exe;//IPFS/server is less realiable, Only URI link is upgradable.
        //URI is just for marketplace to display.
    }
    mapping (address => uint8[3]) public PlayerEquiped;
    mapping (address => uint[2]) public PlayerLatestAcquiredID_AMOUNT;


    uint public royalty = 750; // base 10000, 750 royalty means 7.5%
    address public royaltyRecipient;

    event MaxMintsReached();
    event UpdateName(string name);
    event Ignore(bool ignore);

    uint public tokenIds = 31;
    using Strings for uint256;

    // Master contract, that can reward players from this reward.
    address public masterContract;
    // The fee for minting
    uint public MINTFEE = 0;

    uint8[] COMMONTREASURE = [1,2,3,4,5,11,12,13,14,15,21,22,23,24,25];
    uint8[] RARETREASURE = [6,7,8,16,17,18,26,27,28];
    uint8[] MYSTICTREASURE = [9,10,19,20,29,30];

    function setMasterContract (address _master) public onlyOwner {
        if (confirmed == false) {
            masterContract = _master;
        }
    }
    function confirmMasterContract () public onlyOwner {
        confirmed = true;
    }


    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 amount = (_salePrice * royalty) / 10000;
        return (royaltyRecipient, amount);
    }


    function setRoyaltyRecipient(address _royaltyRecipient) external onlyOwner {
        require(_royaltyRecipient != address(0), "royalty cannot be sent to zero address");
        royaltyRecipient = _royaltyRecipient;
    }

    // Maximum number of individual nft tokenIds that can be created
    uint128 public maxMints = 9999;
    uint16[31] public IDMinted; 
    mapping(uint256 => string) internal tokenURIs;

    function mint(
        uint _amount, //want to fix an amount, gold?100m artifact?10k
        address _to,
        uint _id
    ) internal {
        require(msg.sender == masterContract && _id <31, "No Right");
        _mint(_to, _id, _amount, ""); //give ownership to ID
        IDMinted[_id] = IDMinted[_id] + uint16(_amount);
    }

    // Anyone can burn their NFT if they have sufficient balance
    function burn(uint _id, uint _amount) external {
        require(balanceOf(msg.sender, _id) >= _amount);
        _burn(msg.sender, _id, _amount);
    }

    function updateName(string calldata _name) public onlyOwner {
        name = _name;
        emit UpdateName(name);
    }

    function ignore(bool _ignore) external onlyOwner {
        emit Ignore(_ignore);
    }

    /**
    * Override isApprovedForAll to whitelist the mastercontract to reward players
    */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        if (_operator == masterContract) {
        return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }


    //-------------------- Action -------------------------
    //equip based on slot, have to match, or equip gold/default, which has no effect anyway.
    //slot 0 from metastat means gold. But SLOT1 has to match with SLOT1 or 0 (gold, no effect)
    function equipArtifacts(uint8[3] memory _artifactsID) public {
        require(_artifactsID.length == 3);
        
        uint8 R1 = AMeta.getSlotbyID(_artifactsID[0]);
        uint8 R2 = AMeta.getSlotbyID(_artifactsID[1]);
        uint8 R3 = AMeta.getSlotbyID(_artifactsID[2]);
        
        require(R1 == 1 || R1 == 0);  //right artifact must be in right slot. for R = 0, means its gold, so no effect/default
        require(R2 == 2 || R2 == 0);
        require(R3 == 3 || R3 == 0);
        
        PlayerEquiped[msg.sender] = _artifactsID;
    }

    function getEquipedArtifactsEffects(address _player) public view returns (uint32[4] memory ABCD) {
        uint8[3] memory artifacts = PlayerEquiped[_player];
        uint8[3] memory multiplier;
        
        for (uint8 i = 0; i < 3; i++) {
            if (balanceOf(_player, artifacts[i]) >= 256) {
                multiplier[i] = 9;
            } else if (balanceOf(_player, artifacts[i]) >= 128) {
                multiplier[i] = 8;
            } else if (balanceOf(_player, artifacts[i]) >= 64) {
                multiplier[i] = 7;
            } else if (balanceOf(_player, artifacts[i]) >= 32) {
                multiplier[i] = 6;
            } else if (balanceOf(_player, artifacts[i]) >= 16) {
                multiplier[i] = 5;
            } else if (balanceOf(_player, artifacts[i]) >= 8) {
                multiplier[i] = 4;
            } else if (balanceOf(_player, artifacts[i]) >= 4) {
                multiplier[i] = 3;
            } else if (balanceOf(_player, artifacts[i]) >= 2) {
                multiplier[i] = 2;
            } else if (balanceOf(_player, artifacts[i]) >= 1) {
                multiplier[i] = 1;
            }
            ABCD = AMeta._getEquipedArtifactsEffects(artifacts,multiplier);
        }
    }
    //-------------
//
    function rewardSystem (uint8[4] calldata _chances , address _winner , uint _rand) public { //0=gold, 1=common, 2=rare, 3=mystic
        require(msg.sender == masterContract);
        uint _total = _chances[0] + _chances[1] + _chances[2] + _chances[3] ;
        uint _hit = _rand % _total; //this will get _total -1 as maximum number
        uint _rollID;
        uint _amount =1;
        if (_hit < _chances[0]) {
            // Give gold reward
            mint(_amount,_winner,0); //amount, to , id
        } else if (_hit < (_chances[0] + _chances[1])) {
            // Give common reward
            _rollID = COMMONTREASURE[((_rand>>5)+_rand) % COMMONTREASURE.length];// give common
            if (IDMinted[_rollID] < maxMints) {
                mint(_amount,_winner,_rollID); //amount, to , id // reward  common
            } else {
                _amount = 2;
                mint(_amount,_winner,0); //amount, to , id// give gold instead
            }
        } else if (_hit < (_chances[0] + _chances[1] + _chances[2])) {
            // Give rare reward
            _rollID = RARETREASURE[((_rand>>5)+_rand) % RARETREASURE.length];// give rare
            if (IDMinted[_rollID] < maxMints) {
                mint(_amount,_winner,_rollID); // reward  rare
            } else {
                _amount = 3;
                mint(_amount,_winner,0); //amount, to , id// give gold instead
            }
        } else {
            // Give mystic reward
            _rollID = MYSTICTREASURE[((_rand>>5)+_rand) % MYSTICTREASURE.length];// give mystic
            if (IDMinted[_rollID] < maxMints) {
                mint(_amount,_winner,_rollID);// reward  mystic
            } else {
                _amount = 4;
                mint(_amount,_winner,0); //amount, to , id// give gold instead
            }
        }
        PlayerLatestAcquiredID_AMOUNT[_winner] = [_rollID,_amount];
    }


    //--------------
    function withdraw(address payable _to) external { //incase someone want to donate to me? who knows. haha
        require(_to == owner());
        (bool sent,) = _to.call{value: address(this).balance}("");
        require(sent);
    }

    //----------read only -------------
    function viewArEf(uint8 _tokenId) external pure returns (Ar.ArtifactsEffects memory) {
        return AMeta.getAEbyID(_tokenId);
    }
    function viewArMe(uint8 _tokenId) external pure returns (Ar.ArtifactsMetadata memory) {
        return AMeta.getAMbyID(_tokenId);
    }
    
    function getArtifactsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory ownedBalance = new uint[](31); //id's balance in order
        for (uint i = 0; i < 31; i++) {
            if (balanceOf(_owner,i) > 0) {
                ownedBalance[i] = balanceOf(_owner,i);
            }
        }
        return ownedBalance;
    }
    function getNumberofUniqueArtifactsof(address _owner) public view returns(uint[] memory) {
        uint[] memory ownedBalance = getArtifactsByOwner(_owner);
        uint counter;
        for (uint i = 0; i < ownedBalance.length; i++) {
            if (ownedBalance[i] > 0) {
                counter++;
            }
        }
        return ownedBalance;
    }
    function getAllArtifactsEffects(uint8 _start, uint8 _stop) public pure returns(Ar.ArtifactsEffects[] memory) {
        uint _totalcount;
        if (_stop-_start+1 < 31) {
            _totalcount = _stop-_start+1;
        } else {
            _totalcount = 31;
        }
        Ar.ArtifactsEffects[] memory allArEf = new Ar.ArtifactsEffects[](_totalcount); //id's balance in order
        for (uint8 i = _start; i < _start+_totalcount; i++) {
            allArEf[i] = AMeta.getAEbyID(i);
        }
        return allArEf;
    }
    function getAllArtifactsMetadata(uint8 _start, uint8 _stop) public pure returns(Ar.ArtifactsMetadata[] memory) {
        uint _totalcount;
        if (_stop-_start+1 < 31) {
            _totalcount = _stop-_start+1;
        } else {
            _totalcount = 31;
        }
        Ar.ArtifactsMetadata[] memory allArMe = new Ar.ArtifactsMetadata[](_totalcount); //id's balance in order
        for (uint8 i = _start; i < _start+_totalcount; i++) {
            allArMe[i] = AMeta.getAMbyID(i);
        }
        return allArMe;
    }
    //for appearance
    function getEquipedBalance(address _owner)public view returns (uint8[3] memory EqID,uint[3] memory EqBalance) {
        EqID = PlayerEquiped[_owner];
        EqBalance[0] = balanceOf(_owner, EqID[0]);
        EqBalance[1] = balanceOf(_owner, EqID[1]);
        EqBalance[2] = balanceOf(_owner, EqID[2]);

    }


    function uri(uint _tokenId) public view virtual override returns (string memory metadata) {
         uint8 tokenID = uint8(_tokenId);
         Ar.ArtifactsEffects memory ArEf = AMeta.getAEbyID(tokenID);
         Ar.ArtifactsMetadata memory ArMe = AMeta.getAMbyID(tokenID);

        string memory _name = ArMe.name;
        string memory _imagelinkfull = string(abi.encodePacked(imageURL,_toString(tokenID), imageExtension));
        string memory _description = ArMe.description;
        
         metadata = string(abi.encodePacked("data:application/json;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        "{\"name\": \"#",_toString(tokenID)," ",_name,
                        "\",\"description\": \"",_description,
                        "\",\"image\": \"",
                        _imagelinkfull,
                        _getAttribute1(ArMe,ArEf),
                         _getAttribute2(ArEf)    
                    )
                )
            )
        ));
       
    }
    function _getAttribute1(Ar.ArtifactsMetadata memory AM, Ar.ArtifactsEffects memory AE) private pure returns (string memory attribute){
        
        string memory _slot;
        string memory _rarity;
       
        if (AM.slot == 0) {_slot = "Gold"; }
        else if (AM.slot == 1) {_slot = "Head"; }
        else if (AM.slot == 2) {_slot = "Outfit"; }
        else if (AM.slot == 3) {_slot = "Orb"; }
            else {_slot = "Unknown"; }
        if (AE.R == 0) {_rarity = "Gold"; }
        else if (AE.R == 1) {_rarity = "Common"; }
        else if (AE.R == 2) {_rarity = "Rare"; }
        else if (AE.R == 3) {_rarity = "Mystic"; }
            else {_rarity = "Unknown"; }
        
        attribute = string(abi.encodePacked(
            "\",   \"attributes\": [{\"trait_type\": \"'Slot\",\"value\": \"",bytes(_slot),
             "\"}, {\"trait_type\": \"'Rarity\",\"value\": \"",bytes(_rarity)   
        ));
    }
    function _getAttribute2(Ar.ArtifactsEffects memory AE) private pure returns (string memory attribute){      
        attribute = string(abi.encodePacked(                 
            "\"}, {\"trait_type\": \"::HP\",\"value\": \"",_toString(AE.A),
            "\"}, {\"trait_type\": \"::STR\",\"value\": \"",_toString(AE.B),
            "\"}, {\"trait_type\": \":AGI\",\"value\": \"",_toString(AE.C),
            "\"}, {\"trait_type\": \":INT\",\"value\": \"",_toString(AE.D),
            "\"}]}" 
        ));
    }
    
    function _toString(uint _i) private pure returns (bytes memory convString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return bstr;
    }
    //------------Hackathon Generation -------------
    //Will renowed when submitting to Open Marketplace for fairness
    function cheatArtifact(address _player, uint _id, uint _amount) public {
         if (stopgen == false) {
            mint(_amount,_player,_id); 
         }
    }
    function cheatAllArtifact(address _player, uint _amount) public {
         if (stopgen == false) {
            for (uint i = 0; i < 31; i++) {
                mint(_amount,_player,i); 
            }
         }
    }
    function renowGenArtifactforHackathon() public {
         stopgen = true;
    }
 
}