// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../../../nft/interfaces/ITokenURIProcessor.sol";
import "../../../nft/lib/TokenURIMetadata.sol";
import "../../../nft/interfaces/INFT.sol";
import "../../../lib/AccessControlConstants.sol";
import "../../../lib/Base64.sol";
import "../lib/RunesNFTConstants.sol";
import "../interfaces/INFTPower.sol";
import "../interfaces/IRunicNFT.sol";

contract RunesNFTTokenURIProcessor is AccessControlEnumerable, ITokenURIProcessor {
    using Strings for uint256;
    using Strings for uint32;
    address public nftContract;
    string public description;
    string public externalURL;
    string public baseURI;

    constructor(address nftContract_, string memory baseURI_, string memory externalURL_) {
        AccessControl._grantRole(AccessControlConstants.DEFAULT_ADMIN_ROLE, msg.sender);
        nftContract = nftContract_;
        baseURI = baseURI_;
        externalURL = externalURL_;
    }

    function getTokenURI(uint256 tokenId) external virtual override view returns (string memory) {
        RunicNFTLib.RunicAttributes memory attributes = IRunicNFT(nftContract).getRunicAttributes(tokenId);

        string memory json = string(abi.encodePacked(
            '{"id": ', tokenId.toString(),
            ', "name": "', getRuneName(tokenId, INFT(nftContract).getAttributeString(tokenId, RunesNFTConstants.STRING_NAME)),
            '", "description": "', description,
            '", "external_url": "', externalURL, tokenId.toString(),
            '", "attributes":['
        ));

        json = string(abi.encodePacked(json, TokenURIMetadata.getTraitUint256Json('Power', INFTPower(nftContract).getPower(tokenId))));
        json = getRarity(attributes.rarityId, json);
        json = getBackground(attributes, json);
        json = getRune(attributes, json);
        if(attributes.rarityId >= RunesNFTConstants.RARITY_RARE) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson('Element', getElementName(attributes.elementId))));
        }

        string memory image;
        if(bytes(INFT(nftContract).getAttributeString(tokenId, RunesNFTConstants.STRING_IMAGE_URL)).length > 0) {
            image = INFT(nftContract).getAttributeString(tokenId, RunesNFTConstants.STRING_IMAGE_URL);
        } else {
            string memory suffix;
            if(attributes.rarityId < RunesNFTConstants.RARITY_LEGENDARY) {
                suffix = '.png';
            } else {
                suffix = '.gif';
            }
            image = string(abi.encodePacked(baseURI, attributes.bodyId.toString(), '-', attributes.backgroundId.toString(), suffix));
        }

        json = string(abi.encodePacked(json,
            '],"image":"', image, '"',
            '}'
        ));

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(json))));
    }

    function getRarity(uint32 rarityId_, string memory json) internal pure returns (string memory) {
        string memory rarity = 'Rarity';
        if(rarityId_ == RunesNFTConstants.RARITY_COMMON) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rarity, 'Common', '75.00%')));
        } else if(rarityId_ == RunesNFTConstants.RARITY_RARE) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rarity, 'Rare', '15.00%')));
        } else if(rarityId_ == RunesNFTConstants.RARITY_EPIC) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rarity, 'Epic', '8.00%')));
        } else if(rarityId_ == RunesNFTConstants.RARITY_LEGENDARY) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rarity, 'Legendary', '2.00%')));
        }
        return json;
    }

    function getBackground(RunicNFTLib.RunicAttributes memory attributes_, string memory json) private pure returns (string memory) {
        string memory background = 'Background';
        string memory element = getElementName(attributes_.elementId);
        // common and rare backgrounds
        if(attributes_.backgroundId <= RunesNFTConstants.BACKGROUND_ID_RAINBOW) {
            string[15] memory backgroundNames = [
                'None',
                'Red',
                'Orange',
                'Yellow',
                'Light Green',
                'Green',
                'Blue',
                'Indigo',
                'Violet',
                'Pink',
                'White',
                'Gray',
                'Brown',
                'Black',
                'Rainbow'
            ];
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(background, backgroundNames[attributes_.backgroundId])));
        } else if(attributes_.rarityId == RunesNFTConstants.RARITY_EPIC) {
            string memory version = ((attributes_.backgroundId % 2) + 1).toString();
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(background, string(abi.encodePacked('Epic ', element, ' ', version)))));
        } else if(attributes_.rarityId == RunesNFTConstants.RARITY_LEGENDARY) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(background, string(abi.encodePacked('Legendary ', element)))));
        }
        return json;
    }

    function getRune(RunicNFTLib.RunicAttributes memory attributes_, string memory json) private pure returns (string memory) {
        string memory rune = 'Rune';
        string memory element = getElementName(attributes_.elementId);
        string[28] memory runeNames = [
            'Red 1',
            'Red 2',
            'Orange 1',
            'Orange 2',
            'Yellow 1',
            'Yellow 2',
            'Light Green 1',
            'Light Green 2',
            'Green 1',
            'Green 2',
            'Blue 1',
            'Blue 2',
            'Indigo 1',
            'Indigo 2',
            'Violet 1',
            'Violet 2',
            'Pink 1',
            'Pink 2',
            'White 1',
            'White 2',
            'Gray 1',
            'Gray 2',
            'Brown 1',
            'Brown 2',
            'Black 1',
            'Black 2',
            'Rainbow 1',
            'Rainbow 2'
        ];
        if(attributes_.bodyId <= RunesNFTConstants.RUNE_ID_RAINBOW_2) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rune, runeNames[attributes_.bodyId - 1])));
        } else if(attributes_.rarityId == RunesNFTConstants.RARITY_RARE) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rune, string(abi.encodePacked('Rare ', element, ' ', runeNames[(attributes_.bodyId - 1000 - 1) - (100 * (attributes_.elementId - 1))])))));
        } else if(attributes_.rarityId == RunesNFTConstants.RARITY_EPIC) {
            string memory version = ((attributes_.bodyId % 2) + 1).toString();
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rune, string(abi.encodePacked('Epic ', element, ' ', version)))));
        } else if(attributes_.rarityId == RunesNFTConstants.RARITY_LEGENDARY) {
            json = string(abi.encodePacked(json, ',', TokenURIMetadata.getTraitStringJson(rune, string(abi.encodePacked('Legendary ', element)))));
        }
        return json;
    }

    function getElementName(uint32 elementId_) private pure returns (string memory) {
        if(elementId_ == 0) return '';
        string[13] memory elementNames = [
            'Neutral',
            'Fire',
            'Water',
            'Nature',
            'Earth',
            'Wind',
            'Ice',
            'Lightning',
            'Light',
            'Dark',
            'Metal',
            'Nether',
            'Aether'
        ];
        return elementNames[elementId_ - 1];
    }

    function getRuneName(uint256 tokenId_, string memory name_) private pure returns (string memory) {
        if(bytes(name_).length == 0) {
            return string(abi.encodePacked("Rune #", tokenId_.toString()));
        }
        return name_;
    }

    function setNFTContract(address nftContract_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        nftContract = nftContract_;
    }

    function setDescription(string calldata description_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        description = description_;
    }

    function setExternalURL(string calldata externalURL_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        externalURL = externalURL_;
    }

    function setBaseURI(string calldata baseURI_) external onlyRole(AccessControlConstants.DEFAULT_ADMIN_ROLE) {
        baseURI = baseURI_;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @notice Generic Runic NFT stats
 */
library RunicNFTLib {
    struct RunicAttributes {
        uint32 level;
        uint32 rarityId;
        uint32 backgroundId;
        uint32 bodyId;
        uint32 elementId;
        uint32 foregroundId;
        uint32 promotion;
        uint32 awakening;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library RunesNFTConstants {
    /**
     * Attribute Integer IDs
     */
    uint256 public constant UINT_DISABLE_TEXT = 100; // disable text on nft
    uint256 public constant UINT_LOCKED = 180;       // locked so nft doesn't get used for fodder

    /**
     * Attribute Array IDs
     */

    /**
     * Attribute Address IDs
     */

    /**
     * Attribute String IDs
     */
    uint256 public constant STRING_NAME = 1;
    uint256 public constant STRING_IMAGE_URL = 10;

    /**
     * Address Mapping IDs
     */

    // Rarities
    uint32 public constant RARITY_COMMON = 0; // basic logo
    uint32 public constant RARITY_RARE = 1; // element logo
    uint32 public constant RARITY_EPIC = 2; // element logo with background
    uint32 public constant RARITY_LEGENDARY = 3; // element logo with animated background
    uint32 public constant RARITY_MYTHIC = 4;

    // Backgrounds
    uint32 public constant BACKGROUND_ID_NONE = 0;
    uint32 public constant BACKGROUND_ID_RED = 1;
    uint32 public constant BACKGROUND_ID_ORANGE = 2;
    uint32 public constant BACKGROUND_ID_YELLOW = 3;
    uint32 public constant BACKGROUND_ID_LIGHT_GREEN = 4;
    uint32 public constant BACKGROUND_ID_GREEN = 5;
    uint32 public constant BACKGROUND_ID_BLUE = 6;
    uint32 public constant BACKGROUND_ID_INDIGO = 7;
    uint32 public constant BACKGROUND_ID_VIOLET = 8;
    uint32 public constant BACKGROUND_ID_PINK = 9;
    uint32 public constant BACKGROUND_ID_WHITE = 10;
    uint32 public constant BACKGROUND_ID_GRAY = 11;
    uint32 public constant BACKGROUND_ID_BROWN = 12;
    uint32 public constant BACKGROUND_ID_BLACK = 13;
    uint32 public constant BACKGROUND_ID_RAINBOW = 14;

    // Elemental Backgrounds
    uint32 public constant BACKGROUND_ID_NEUTRAL_1 = 3000;
    uint32 public constant BACKGROUND_ID_NEUTRAL_2 = 3001;
    uint32 public constant BACKGROUND_ID_FIRE_1 = 3010;
    uint32 public constant BACKGROUND_ID_FIRE_2 = 3011;
    uint32 public constant BACKGROUND_ID_WATER_1 = 3020;
    uint32 public constant BACKGROUND_ID_WATER_2 = 3021;
    uint32 public constant BACKGROUND_ID_NATURE_1 = 3030;
    uint32 public constant BACKGROUND_ID_NATURE_2 = 3031;
    uint32 public constant BACKGROUND_ID_EARTH_1 = 3040;
    uint32 public constant BACKGROUND_ID_EARTH_2 = 3041;
    uint32 public constant BACKGROUND_ID_WIND_1 = 3050;
    uint32 public constant BACKGROUND_ID_WIND_2 = 3051;
    uint32 public constant BACKGROUND_ID_ICE_1 = 3060;
    uint32 public constant BACKGROUND_ID_ICE_2 = 3061;
    uint32 public constant BACKGROUND_ID_LIGHTNING_1 = 3070;
    uint32 public constant BACKGROUND_ID_LIGHTNING_2 = 3071;
    uint32 public constant BACKGROUND_ID_LIGHT_1 = 3080;
    uint32 public constant BACKGROUND_ID_LIGHT_2 = 3081;
    uint32 public constant BACKGROUND_ID_DARK_1 = 3090;
    uint32 public constant BACKGROUND_ID_DARK_2 = 3091;
    uint32 public constant BACKGROUND_ID_METAL_1 = 3100;
    uint32 public constant BACKGROUND_ID_METAL_2 = 3101;
    uint32 public constant BACKGROUND_ID_NETHER_1 = 3110;
    uint32 public constant BACKGROUND_ID_NETHER_2 = 3111;
    uint32 public constant BACKGROUND_ID_AETHER_1 = 3120;
    uint32 public constant BACKGROUND_ID_AETHER_2 = 3121;

    // Legendary Backgrounds
    uint32 public constant BACKGROUND_ID_LEGENDARY_NEUTRAL = 4000;
    uint32 public constant BACKGROUND_ID_LEGENDARY_FIRE = 4010;
    uint32 public constant BACKGROUND_ID_LEGENDARY_WATER = 4020;
    uint32 public constant BACKGROUND_ID_LEGENDARY_NATURE = 4030;
    uint32 public constant BACKGROUND_ID_LEGENDARY_EARTH = 4040;
    uint32 public constant BACKGROUND_ID_LEGENDARY_WIND = 4050;
    uint32 public constant BACKGROUND_ID_LEGENDARY_ICE = 4060;
    uint32 public constant BACKGROUND_ID_LEGENDARY_LIGHTNING = 4070;
    uint32 public constant BACKGROUND_ID_LEGENDARY_LIGHT = 4080;
    uint32 public constant BACKGROUND_ID_LEGENDARY_DARK = 4090;
    uint32 public constant BACKGROUND_ID_LEGENDARY_METAL = 4100;
    uint32 public constant BACKGROUND_ID_LEGENDARY_NETHER = 4110;
    uint32 public constant BACKGROUND_ID_LEGENDARY_AETHER = 4120;

    // Runes
    uint32 public constant RUNE_ID_RED = 1;
    uint32 public constant RUNE_ID_RED_2 = 2;
    uint32 public constant RUNE_ID_ORANGE = 3;
    uint32 public constant RUNE_ID_ORANGE_2 = 4;
    uint32 public constant RUNE_ID_YELLOW = 5;
    uint32 public constant RUNE_ID_YELLOW_2 = 6;
    uint32 public constant RUNE_ID_LIME_GREEN = 7;
    uint32 public constant RUNE_ID_LIME_GREEN_2 = 8;
    uint32 public constant RUNE_ID_GREEN = 9;
    uint32 public constant RUNE_ID_GREEN_2 = 10;
    uint32 public constant RUNE_ID_BLUE = 11;
    uint32 public constant RUNE_ID_BLUE_2 = 12;
    uint32 public constant RUNE_ID_INDIGO = 13;
    uint32 public constant RUNE_ID_INDIGO_2 = 14;
    uint32 public constant RUNE_ID_VIOLET = 15;
    uint32 public constant RUNE_ID_VIOLET_2 = 16;
    uint32 public constant RUNE_ID_PINK = 17;
    uint32 public constant RUNE_ID_PINK_2 = 18;
    uint32 public constant RUNE_ID_WHITE = 19;
    uint32 public constant RUNE_ID_WHITE_2 = 20;
    uint32 public constant RUNE_ID_GRAY = 21;
    uint32 public constant RUNE_ID_GRAY_2 = 22;
    uint32 public constant RUNE_ID_BROWN = 23;
    uint32 public constant RUNE_ID_BROWN_2 = 24;
    uint32 public constant RUNE_ID_BLACK = 25;
    uint32 public constant RUNE_ID_BLACK_2 = 26;
    uint32 public constant RUNE_ID_RAINBOW = 27;
    uint32 public constant RUNE_ID_RAINBOW_2 = 28;

    // Rare Elemental Runes
    uint32 public constant RUNE_ID_NEUTRAL_RED = 1001;
    uint32 public constant RUNE_ID_NEUTRAL_RED_2 = 1002;
    uint32 public constant RUNE_ID_NEUTRAL_ORANGE = 1003;
    uint32 public constant RUNE_ID_NEUTRAL_ORANGE_2 = 1004;
    uint32 public constant RUNE_ID_NEUTRAL_YELLOW = 1005;
    uint32 public constant RUNE_ID_NEUTRAL_YELLOW_2 = 1006;
    uint32 public constant RUNE_ID_NEUTRAL_LIGHT_GREEN = 1007;
    uint32 public constant RUNE_ID_NEUTRAL_LIGHT_GREEN_2 = 1008;
    uint32 public constant RUNE_ID_NEUTRAL_GREEN = 1009;
    uint32 public constant RUNE_ID_NEUTRAL_GREEN_2 = 1010;
    uint32 public constant RUNE_ID_NEUTRAL_BLUE = 1011;
    uint32 public constant RUNE_ID_NEUTRAL_BLUE_2 = 1012;
    uint32 public constant RUNE_ID_NEUTRAL_INDIGO = 1013;
    uint32 public constant RUNE_ID_NEUTRAL_INDIGO_2 = 1014;
    uint32 public constant RUNE_ID_NEUTRAL_VIOLET = 1015;
    uint32 public constant RUNE_ID_NEUTRAL_VIOLET_2 = 1016;
    uint32 public constant RUNE_ID_NEUTRAL_PINK = 1017;
    uint32 public constant RUNE_ID_NEUTRAL_PINK_2 = 1018;
    uint32 public constant RUNE_ID_NEUTRAL_WHITE = 1019;
    uint32 public constant RUNE_ID_NEUTRAL_WHITE_2 = 1020;
    uint32 public constant RUNE_ID_NEUTRAL_GRAY = 1021;
    uint32 public constant RUNE_ID_NEUTRAL_GRAY_2 = 1022;
    uint32 public constant RUNE_ID_NEUTRAL_BROWN = 1023;
    uint32 public constant RUNE_ID_NEUTRAL_BROWN_2 = 1024;
    uint32 public constant RUNE_ID_NEUTRAL_BLACK = 1025;
    uint32 public constant RUNE_ID_NEUTRAL_BLACK_2 = 1026;
    uint32 public constant RUNE_ID_NEUTRAL_RAINBOW = 1027;
    uint32 public constant RUNE_ID_NEUTRAL_RAINBOW_2 = 1028;

    uint32 public constant RUNE_ID_FIRE_RED = 1101;
    uint32 public constant RUNE_ID_FIRE_RED_2 = 1102;
    uint32 public constant RUNE_ID_FIRE_ORANGE = 1103;
    uint32 public constant RUNE_ID_FIRE_ORANGE_2 = 1104;
    uint32 public constant RUNE_ID_FIRE_YELLOW = 1105;
    uint32 public constant RUNE_ID_FIRE_YELLOW_2 = 1106;
    uint32 public constant RUNE_ID_FIRE_LIGHT_GREEN = 1107;
    uint32 public constant RUNE_ID_FIRE_LIGHT_GREEN_2 = 1108;
    uint32 public constant RUNE_ID_FIRE_GREEN = 1109;
    uint32 public constant RUNE_ID_FIRE_GREEN_2 = 1110;
    uint32 public constant RUNE_ID_FIRE_BLUE = 1111;
    uint32 public constant RUNE_ID_FIRE_BLUE_2 = 1112;
    uint32 public constant RUNE_ID_FIRE_INDIGO = 1113;
    uint32 public constant RUNE_ID_FIRE_INDIGO_2 = 1114;
    uint32 public constant RUNE_ID_FIRE_VIOLET = 1115;
    uint32 public constant RUNE_ID_FIRE_VIOLET_2 = 1116;
    uint32 public constant RUNE_ID_FIRE_PINK = 1117;
    uint32 public constant RUNE_ID_FIRE_PINK_2 = 1118;
    uint32 public constant RUNE_ID_FIRE_WHITE = 1119;
    uint32 public constant RUNE_ID_FIRE_WHITE_2 = 1120;
    uint32 public constant RUNE_ID_FIRE_GRAY = 1121;
    uint32 public constant RUNE_ID_FIRE_GRAY_2 = 1122;
    uint32 public constant RUNE_ID_FIRE_BROWN = 1123;
    uint32 public constant RUNE_ID_FIRE_BROWN_2 = 1124;
    uint32 public constant RUNE_ID_FIRE_BLACK = 1125;
    uint32 public constant RUNE_ID_FIRE_BLACK_2 = 1126;
    uint32 public constant RUNE_ID_FIRE_RAINBOW = 1127;
    uint32 public constant RUNE_ID_FIRE_RAINBOW_2 = 1128;

    uint32 public constant RUNE_ID_WATER_RED = 1201;
    uint32 public constant RUNE_ID_WATER_RED_2 = 1202;
    uint32 public constant RUNE_ID_WATER_ORANGE = 1203;
    uint32 public constant RUNE_ID_WATER_ORANGE_2 = 1204;
    uint32 public constant RUNE_ID_WATER_YELLOW = 1205;
    uint32 public constant RUNE_ID_WATER_YELLOW_2 = 1206;
    uint32 public constant RUNE_ID_WATER_LIGHT_GREEN = 1207;
    uint32 public constant RUNE_ID_WATER_LIGHT_GREEN_2 = 1208;
    uint32 public constant RUNE_ID_WATER_GREEN = 1209;
    uint32 public constant RUNE_ID_WATER_GREEN_2 = 1210;
    uint32 public constant RUNE_ID_WATER_BLUE = 1211;
    uint32 public constant RUNE_ID_WATER_BLUE_2 = 1212;
    uint32 public constant RUNE_ID_WATER_INDIGO = 1213;
    uint32 public constant RUNE_ID_WATER_INDIGO_2 = 1214;
    uint32 public constant RUNE_ID_WATER_VIOLET = 1215;
    uint32 public constant RUNE_ID_WATER_VIOLET_2 = 1216;
    uint32 public constant RUNE_ID_WATER_PINK = 1217;
    uint32 public constant RUNE_ID_WATER_PINK_2 = 1218;
    uint32 public constant RUNE_ID_WATER_WHITE = 1219;
    uint32 public constant RUNE_ID_WATER_WHITE_2 = 1220;
    uint32 public constant RUNE_ID_WATER_GRAY = 1221;
    uint32 public constant RUNE_ID_WATER_GRAY_2 = 1222;
    uint32 public constant RUNE_ID_WATER_BROWN = 1223;
    uint32 public constant RUNE_ID_WATER_BROWN_2 = 1224;
    uint32 public constant RUNE_ID_WATER_BLACK = 1225;
    uint32 public constant RUNE_ID_WATER_BLACK_2 = 1226;
    uint32 public constant RUNE_ID_WATER_RAINBOW = 1227;
    uint32 public constant RUNE_ID_WATER_RAINBOW_2 = 1228;

    uint32 public constant RUNE_ID_NATURE_RED = 1301;
    uint32 public constant RUNE_ID_NATURE_RED_2 = 1302;
    uint32 public constant RUNE_ID_NATURE_ORANGE = 1303;
    uint32 public constant RUNE_ID_NATURE_ORANGE_2 = 1304;
    uint32 public constant RUNE_ID_NATURE_YELLOW = 1305;
    uint32 public constant RUNE_ID_NATURE_YELLOW_2 = 1306;
    uint32 public constant RUNE_ID_NATURE_LIGHT_GREEN = 1307;
    uint32 public constant RUNE_ID_NATURE_LIGHT_GREEN_2 = 1308;
    uint32 public constant RUNE_ID_NATURE_GREEN = 1309;
    uint32 public constant RUNE_ID_NATURE_GREEN_2 = 1310;
    uint32 public constant RUNE_ID_NATURE_BLUE = 1311;
    uint32 public constant RUNE_ID_NATURE_BLUE_2 = 1312;
    uint32 public constant RUNE_ID_NATURE_INDIGO = 1313;
    uint32 public constant RUNE_ID_NATURE_INDIGO_2 = 1314;
    uint32 public constant RUNE_ID_NATURE_VIOLET = 1315;
    uint32 public constant RUNE_ID_NATURE_VIOLET_2 = 1316;
    uint32 public constant RUNE_ID_NATURE_PINK = 1317;
    uint32 public constant RUNE_ID_NATURE_PINK_2 = 1318;
    uint32 public constant RUNE_ID_NATURE_WHITE = 1319;
    uint32 public constant RUNE_ID_NATURE_WHITE_2 = 1320;
    uint32 public constant RUNE_ID_NATURE_GRAY = 1321;
    uint32 public constant RUNE_ID_NATURE_GRAY_2 = 1322;
    uint32 public constant RUNE_ID_NATURE_BROWN = 1323;
    uint32 public constant RUNE_ID_NATURE_BROWN_2 = 1324;
    uint32 public constant RUNE_ID_NATURE_BLACK = 1325;
    uint32 public constant RUNE_ID_NATURE_BLACK_2 = 1326;
    uint32 public constant RUNE_ID_NATURE_RAINBOW = 1327;
    uint32 public constant RUNE_ID_NATURE_RAINBOW_2 = 1328;

    uint32 public constant RUNE_ID_EARTH_RED = 1401;
    uint32 public constant RUNE_ID_EARTH_RED_2 = 1402;
    uint32 public constant RUNE_ID_EARTH_ORANGE = 1403;
    uint32 public constant RUNE_ID_EARTH_ORANGE_2 = 1404;
    uint32 public constant RUNE_ID_EARTH_YELLOW = 1405;
    uint32 public constant RUNE_ID_EARTH_YELLOW_2 = 1406;
    uint32 public constant RUNE_ID_EARTH_LIGHT_GREEN = 1407;
    uint32 public constant RUNE_ID_EARTH_LIGHT_GREEN_2 = 1408;
    uint32 public constant RUNE_ID_EARTH_GREEN = 1409;
    uint32 public constant RUNE_ID_EARTH_GREEN_2 = 1410;
    uint32 public constant RUNE_ID_EARTH_BLUE = 1411;
    uint32 public constant RUNE_ID_EARTH_BLUE_2 = 1412;
    uint32 public constant RUNE_ID_EARTH_INDIGO = 1413;
    uint32 public constant RUNE_ID_EARTH_INDIGO_2 = 1414;
    uint32 public constant RUNE_ID_EARTH_VIOLET = 1415;
    uint32 public constant RUNE_ID_EARTH_VIOLET_2 = 1416;
    uint32 public constant RUNE_ID_EARTH_PINK = 1417;
    uint32 public constant RUNE_ID_EARTH_PINK_2 = 1418;
    uint32 public constant RUNE_ID_EARTH_WHITE = 1419;
    uint32 public constant RUNE_ID_EARTH_WHITE_2 = 1420;
    uint32 public constant RUNE_ID_EARTH_GRAY = 1421;
    uint32 public constant RUNE_ID_EARTH_GRAY_2 = 1422;
    uint32 public constant RUNE_ID_EARTH_BROWN = 1423;
    uint32 public constant RUNE_ID_EARTH_BROWN_2 = 1424;
    uint32 public constant RUNE_ID_EARTH_BLACK = 1425;
    uint32 public constant RUNE_ID_EARTH_BLACK_2 = 1426;
    uint32 public constant RUNE_ID_EARTH_RAINBOW = 1427;
    uint32 public constant RUNE_ID_EARTH_RAINBOW_2 = 1428;

    uint32 public constant RUNE_ID_WIND_RED = 1501;
    uint32 public constant RUNE_ID_WIND_RED_2 = 1502;
    uint32 public constant RUNE_ID_WIND_ORANGE = 1503;
    uint32 public constant RUNE_ID_WIND_ORANGE_2 = 1504;
    uint32 public constant RUNE_ID_WIND_YELLOW = 1505;
    uint32 public constant RUNE_ID_WIND_YELLOW_2 = 1506;
    uint32 public constant RUNE_ID_WIND_LIGHT_GREEN = 1507;
    uint32 public constant RUNE_ID_WIND_LIGHT_GREEN_2 = 1508;
    uint32 public constant RUNE_ID_WIND_GREEN = 1509;
    uint32 public constant RUNE_ID_WIND_GREEN_2 = 1510;
    uint32 public constant RUNE_ID_WIND_BLUE = 1511;
    uint32 public constant RUNE_ID_WIND_BLUE_2 = 1512;
    uint32 public constant RUNE_ID_WIND_INDIGO = 1513;
    uint32 public constant RUNE_ID_WIND_INDIGO_2 = 1514;
    uint32 public constant RUNE_ID_WIND_VIOLET = 1515;
    uint32 public constant RUNE_ID_WIND_VIOLET_2 = 1516;
    uint32 public constant RUNE_ID_WIND_PINK = 1517;
    uint32 public constant RUNE_ID_WIND_PINK_2 = 1518;
    uint32 public constant RUNE_ID_WIND_WHITE = 1519;
    uint32 public constant RUNE_ID_WIND_WHITE_2 = 1520;
    uint32 public constant RUNE_ID_WIND_GRAY = 1521;
    uint32 public constant RUNE_ID_WIND_GRAY_2 = 1522;
    uint32 public constant RUNE_ID_WIND_BROWN = 1523;
    uint32 public constant RUNE_ID_WIND_BROWN_2 = 1524;
    uint32 public constant RUNE_ID_WIND_BLACK = 1525;
    uint32 public constant RUNE_ID_WIND_BLACK_2 = 1526;
    uint32 public constant RUNE_ID_WIND_RAINBOW = 1527;
    uint32 public constant RUNE_ID_WIND_RAINBOW_2 = 1528;

    uint32 public constant RUNE_ID_ICE_RED = 1601;
    uint32 public constant RUNE_ID_ICE_RED_2 = 1602;
    uint32 public constant RUNE_ID_ICE_ORANGE = 1603;
    uint32 public constant RUNE_ID_ICE_ORANGE_2 = 1604;
    uint32 public constant RUNE_ID_ICE_YELLOW = 1605;
    uint32 public constant RUNE_ID_ICE_YELLOW_2 = 1606;
    uint32 public constant RUNE_ID_ICE_LIGHT_GREEN = 1607;
    uint32 public constant RUNE_ID_ICE_LIGHT_GREEN_2 = 1608;
    uint32 public constant RUNE_ID_ICE_GREEN = 1609;
    uint32 public constant RUNE_ID_ICE_GREEN_2 = 1610;
    uint32 public constant RUNE_ID_ICE_BLUE = 1611;
    uint32 public constant RUNE_ID_ICE_BLUE_2 = 1612;
    uint32 public constant RUNE_ID_ICE_INDIGO = 1613;
    uint32 public constant RUNE_ID_ICE_INDIGO_2 = 1614;
    uint32 public constant RUNE_ID_ICE_VIOLET = 1615;
    uint32 public constant RUNE_ID_ICE_VIOLET_2 = 1616;
    uint32 public constant RUNE_ID_ICE_PINK = 1617;
    uint32 public constant RUNE_ID_ICE_PINK_2 = 1618;
    uint32 public constant RUNE_ID_ICE_WHITE = 1619;
    uint32 public constant RUNE_ID_ICE_WHITE_2 = 1620;
    uint32 public constant RUNE_ID_ICE_GRAY = 1621;
    uint32 public constant RUNE_ID_ICE_GRAY_2 = 1622;
    uint32 public constant RUNE_ID_ICE_BROWN = 1623;
    uint32 public constant RUNE_ID_ICE_BROWN_2 = 1624;
    uint32 public constant RUNE_ID_ICE_BLACK = 1625;
    uint32 public constant RUNE_ID_ICE_BLACK_2 = 1626;
    uint32 public constant RUNE_ID_ICE_RAINBOW = 1627;
    uint32 public constant RUNE_ID_ICE_RAINBOW_2 = 1628;

    uint32 public constant RUNE_ID_LIGHTNING_RED = 1701;
    uint32 public constant RUNE_ID_LIGHTNING_RED_2 = 1702;
    uint32 public constant RUNE_ID_LIGHTNING_ORANGE = 1703;
    uint32 public constant RUNE_ID_LIGHTNING_ORANGE_2 = 1704;
    uint32 public constant RUNE_ID_LIGHTNING_YELLOW = 1705;
    uint32 public constant RUNE_ID_LIGHTNING_YELLOW_2 = 1706;
    uint32 public constant RUNE_ID_LIGHTNING_LIGHT_GREEN = 1707;
    uint32 public constant RUNE_ID_LIGHTNING_LIGHT_GREEN_2 = 1708;
    uint32 public constant RUNE_ID_LIGHTNING_GREEN = 1709;
    uint32 public constant RUNE_ID_LIGHTNING_GREEN_2 = 1710;
    uint32 public constant RUNE_ID_LIGHTNING_BLUE = 1711;
    uint32 public constant RUNE_ID_LIGHTNING_BLUE_2 = 1712;
    uint32 public constant RUNE_ID_LIGHTNING_INDIGO = 1713;
    uint32 public constant RUNE_ID_LIGHTNING_INDIGO_2 = 1714;
    uint32 public constant RUNE_ID_LIGHTNING_VIOLET = 1715;
    uint32 public constant RUNE_ID_LIGHTNING_VIOLET_2 = 1716;
    uint32 public constant RUNE_ID_LIGHTNING_PINK = 1717;
    uint32 public constant RUNE_ID_LIGHTNING_PINK_2 = 1718;
    uint32 public constant RUNE_ID_LIGHTNING_WHITE = 1719;
    uint32 public constant RUNE_ID_LIGHTNING_WHITE_2 = 1720;
    uint32 public constant RUNE_ID_LIGHTNING_GRAY = 1721;
    uint32 public constant RUNE_ID_LIGHTNING_GRAY_2 = 1722;
    uint32 public constant RUNE_ID_LIGHTNING_BROWN = 1723;
    uint32 public constant RUNE_ID_LIGHTNING_BROWN_2 = 1724;
    uint32 public constant RUNE_ID_LIGHTNING_BLACK = 1725;
    uint32 public constant RUNE_ID_LIGHTNING_BLACK_2 = 1726;
    uint32 public constant RUNE_ID_LIGHTNING_RAINBOW = 1727;
    uint32 public constant RUNE_ID_LIGHTNING_RAINBOW_2 = 1728;

    uint32 public constant RUNE_ID_LIGHT_RED = 1801;
    uint32 public constant RUNE_ID_LIGHT_RED_2 = 1802;
    uint32 public constant RUNE_ID_LIGHT_ORANGE = 1803;
    uint32 public constant RUNE_ID_LIGHT_ORANGE_2 = 1804;
    uint32 public constant RUNE_ID_LIGHT_YELLOW = 1805;
    uint32 public constant RUNE_ID_LIGHT_YELLOW_2 = 1806;
    uint32 public constant RUNE_ID_LIGHT_LIME_GREEN = 1807;
    uint32 public constant RUNE_ID_LIGHT_LIME_GREEN_2 = 1808;
    uint32 public constant RUNE_ID_LIGHT_GREEN = 1809;
    uint32 public constant RUNE_ID_LIGHT_GREEN_2 = 1810;
    uint32 public constant RUNE_ID_LIGHT_BLUE = 1811;
    uint32 public constant RUNE_ID_LIGHT_BLUE_2 = 1812;
    uint32 public constant RUNE_ID_LIGHT_INDIGO = 1813;
    uint32 public constant RUNE_ID_LIGHT_INDIGO_2 = 1814;
    uint32 public constant RUNE_ID_LIGHT_VIOLET = 1815;
    uint32 public constant RUNE_ID_LIGHT_VIOLET_2 = 1816;
    uint32 public constant RUNE_ID_LIGHT_PINK = 1817;
    uint32 public constant RUNE_ID_LIGHT_PINK_2 = 1818;
    uint32 public constant RUNE_ID_LIGHT_WHITE = 1819;
    uint32 public constant RUNE_ID_LIGHT_WHITE_2 = 1820;
    uint32 public constant RUNE_ID_LIGHT_GRAY = 1821;
    uint32 public constant RUNE_ID_LIGHT_GRAY_2 = 1822;
    uint32 public constant RUNE_ID_LIGHT_BROWN = 1823;
    uint32 public constant RUNE_ID_LIGHT_BROWN_2 = 1824;
    uint32 public constant RUNE_ID_LIGHT_BLACK = 1825;
    uint32 public constant RUNE_ID_LIGHT_BLACK_2 = 1826;
    uint32 public constant RUNE_ID_LIGHT_RAINBOW = 1827;
    uint32 public constant RUNE_ID_LIGHT_RAINBOW_2 = 1828;

    uint32 public constant RUNE_ID_DARK_RED = 1901;
    uint32 public constant RUNE_ID_DARK_RED_2 = 1902;
    uint32 public constant RUNE_ID_DARK_ORANGE = 1903;
    uint32 public constant RUNE_ID_DARK_ORANGE_2 = 1904;
    uint32 public constant RUNE_ID_DARK_YELLOW = 1905;
    uint32 public constant RUNE_ID_DARK_YELLOW_2 = 1906;
    uint32 public constant RUNE_ID_DARK_LIGHT_GREEN = 1907;
    uint32 public constant RUNE_ID_DARK_LIGHT_GREEN_2 = 1908;
    uint32 public constant RUNE_ID_DARK_GREEN = 1909;
    uint32 public constant RUNE_ID_DARK_GREEN_2 = 1910;
    uint32 public constant RUNE_ID_DARK_BLUE = 1911;
    uint32 public constant RUNE_ID_DARK_BLUE_2 = 1912;
    uint32 public constant RUNE_ID_DARK_INDIGO = 1913;
    uint32 public constant RUNE_ID_DARK_INDIGO_2 = 1914;
    uint32 public constant RUNE_ID_DARK_VIOLET = 1915;
    uint32 public constant RUNE_ID_DARK_VIOLET_2 = 1916;
    uint32 public constant RUNE_ID_DARK_PINK = 1917;
    uint32 public constant RUNE_ID_DARK_PINK_2 = 1918;
    uint32 public constant RUNE_ID_DARK_WHITE = 1919;
    uint32 public constant RUNE_ID_DARK_WHITE_2 = 1920;
    uint32 public constant RUNE_ID_DARK_GRAY = 1921;
    uint32 public constant RUNE_ID_DARK_GRAY_2 = 1922;
    uint32 public constant RUNE_ID_DARK_BROWN = 1923;
    uint32 public constant RUNE_ID_DARK_BROWN_2 = 1924;
    uint32 public constant RUNE_ID_DARK_BLACK = 1925;
    uint32 public constant RUNE_ID_DARK_BLACK_2 = 1926;
    uint32 public constant RUNE_ID_DARK_RAINBOW = 1927;
    uint32 public constant RUNE_ID_DARK_RAINBOW_2 = 1928;

    uint32 public constant RUNE_ID_METAL_RED = 2001;
    uint32 public constant RUNE_ID_METAL_RED_2 = 2002;
    uint32 public constant RUNE_ID_METAL_ORANGE = 2003;
    uint32 public constant RUNE_ID_METAL_ORANGE_2 = 2004;
    uint32 public constant RUNE_ID_METAL_YELLOW = 2005;
    uint32 public constant RUNE_ID_METAL_YELLOW_2 = 2006;
    uint32 public constant RUNE_ID_METAL_LIGHT_GREEN = 2007;
    uint32 public constant RUNE_ID_METAL_LIGHT_GREEN_2 = 2008;
    uint32 public constant RUNE_ID_METAL_GREEN = 2009;
    uint32 public constant RUNE_ID_METAL_GREEN_2 = 2010;
    uint32 public constant RUNE_ID_METAL_BLUE = 2011;
    uint32 public constant RUNE_ID_METAL_BLUE_2 = 2012;
    uint32 public constant RUNE_ID_METAL_INDIGO = 2013;
    uint32 public constant RUNE_ID_METAL_INDIGO_2 = 2014;
    uint32 public constant RUNE_ID_METAL_VIOLET = 2015;
    uint32 public constant RUNE_ID_METAL_VIOLET_2 = 2016;
    uint32 public constant RUNE_ID_METAL_PINK = 2017;
    uint32 public constant RUNE_ID_METAL_PINK_2 = 2018;
    uint32 public constant RUNE_ID_METAL_WHITE = 2019;
    uint32 public constant RUNE_ID_METAL_WHITE_2 = 2020;
    uint32 public constant RUNE_ID_METAL_GRAY = 2021;
    uint32 public constant RUNE_ID_METAL_GRAY_2 = 2022;
    uint32 public constant RUNE_ID_METAL_BROWN = 2023;
    uint32 public constant RUNE_ID_METAL_BROWN_2 = 2024;
    uint32 public constant RUNE_ID_METAL_BLACK = 2025;
    uint32 public constant RUNE_ID_METAL_BLACK_2 = 2026;
    uint32 public constant RUNE_ID_METAL_RAINBOW = 2027;
    uint32 public constant RUNE_ID_METAL_RAINBOW_2 = 2028;

    uint32 public constant RUNE_ID_NETHER_RED = 2101;
    uint32 public constant RUNE_ID_NETHER_RED_2 = 2102;
    uint32 public constant RUNE_ID_NETHER_ORANGE = 2103;
    uint32 public constant RUNE_ID_NETHER_ORANGE_2 = 2104;
    uint32 public constant RUNE_ID_NETHER_YELLOW = 2105;
    uint32 public constant RUNE_ID_NETHER_YELLOW_2 = 2106;
    uint32 public constant RUNE_ID_NETHER_LIGHT_GREEN = 2107;
    uint32 public constant RUNE_ID_NETHER_LIGHT_GREEN_2 = 2108;
    uint32 public constant RUNE_ID_NETHER_GREEN = 2109;
    uint32 public constant RUNE_ID_NETHER_GREEN_2 = 2110;
    uint32 public constant RUNE_ID_NETHER_BLUE = 2111;
    uint32 public constant RUNE_ID_NETHER_BLUE_2 = 2112;
    uint32 public constant RUNE_ID_NETHER_INDIGO = 2113;
    uint32 public constant RUNE_ID_NETHER_INDIGO_2 = 2114;
    uint32 public constant RUNE_ID_NETHER_VIOLET = 2115;
    uint32 public constant RUNE_ID_NETHER_VIOLET_2 = 2116;
    uint32 public constant RUNE_ID_NETHER_PINK = 2117;
    uint32 public constant RUNE_ID_NETHER_PINK_2 = 2118;
    uint32 public constant RUNE_ID_NETHER_WHITE = 2119;
    uint32 public constant RUNE_ID_NETHER_WHITE_2 = 2120;
    uint32 public constant RUNE_ID_NETHER_GRAY = 2121;
    uint32 public constant RUNE_ID_NETHER_GRAY_2 = 2122;
    uint32 public constant RUNE_ID_NETHER_BROWN = 2123;
    uint32 public constant RUNE_ID_NETHER_BROWN_2 = 2124;
    uint32 public constant RUNE_ID_NETHER_BLACK = 2125;
    uint32 public constant RUNE_ID_NETHER_BLACK_2 = 2126;
    uint32 public constant RUNE_ID_NETHER_RAINBOW = 2127;
    uint32 public constant RUNE_ID_NETHER_RAINBOW_2 = 2128;

    uint32 public constant RUNE_ID_AETHER_RED = 2201;
    uint32 public constant RUNE_ID_AETHER_RED_2 = 2202;
    uint32 public constant RUNE_ID_AETHER_ORANGE = 2203;
    uint32 public constant RUNE_ID_AETHER_ORANGE_2 = 2204;
    uint32 public constant RUNE_ID_AETHER_YELLOW = 2205;
    uint32 public constant RUNE_ID_AETHER_YELLOW_2 = 2206;
    uint32 public constant RUNE_ID_AETHER_LIGHT_GREEN = 2207;
    uint32 public constant RUNE_ID_AETHER_LIGHT_GREEN_2 = 2208;
    uint32 public constant RUNE_ID_AETHER_GREEN = 2209;
    uint32 public constant RUNE_ID_AETHER_GREEN_2 = 2210;
    uint32 public constant RUNE_ID_AETHER_BLUE = 2211;
    uint32 public constant RUNE_ID_AETHER_BLUE_2 = 2212;
    uint32 public constant RUNE_ID_AETHER_INDIGO = 2213;
    uint32 public constant RUNE_ID_AETHER_INDIGO_2 = 2214;
    uint32 public constant RUNE_ID_AETHER_VIOLET = 2215;
    uint32 public constant RUNE_ID_AETHER_VIOLET_2 = 2216;
    uint32 public constant RUNE_ID_AETHER_PINK = 2217;
    uint32 public constant RUNE_ID_AETHER_PINK_2 = 2218;
    uint32 public constant RUNE_ID_AETHER_WHITE = 2219;
    uint32 public constant RUNE_ID_AETHER_WHITE_2 = 2220;
    uint32 public constant RUNE_ID_AETHER_GRAY = 2221;
    uint32 public constant RUNE_ID_AETHER_GRAY_2 = 2222;
    uint32 public constant RUNE_ID_AETHER_BROWN = 2223;
    uint32 public constant RUNE_ID_AETHER_BROWN_2 = 2224;
    uint32 public constant RUNE_ID_AETHER_BLACK = 2225;
    uint32 public constant RUNE_ID_AETHER_BLACK_2 = 2226;
    uint32 public constant RUNE_ID_AETHER_RAINBOW = 2227;
    uint32 public constant RUNE_ID_AETHER_RAINBOW_2 = 2228;

    // Epic Elemental Runes
    uint32 public constant RUNE_ID_NEUTRAL_1 = 3000;
    uint32 public constant RUNE_ID_NEUTRAL_2 = 3001;
    uint32 public constant RUNE_ID_FIRE_1 = 3010;
    uint32 public constant RUNE_ID_FIRE_2 = 3011;
    uint32 public constant RUNE_ID_WATER_1 = 3020;
    uint32 public constant RUNE_ID_WATER_2 = 3021;
    uint32 public constant RUNE_ID_NATURE_1 = 3030;
    uint32 public constant RUNE_ID_NATURE_2 = 3031;
    uint32 public constant RUNE_ID_EARTH_1 = 3040;
    uint32 public constant RUNE_ID_EARTH_2 = 3041;
    uint32 public constant RUNE_ID_WIND_1 = 3050;
    uint32 public constant RUNE_ID_WIND_2 = 3051;
    uint32 public constant RUNE_ID_ICE_1 = 3060;
    uint32 public constant RUNE_ID_ICE_2 = 3061;
    uint32 public constant RUNE_ID_LIGHTNING_1 = 3070;
    uint32 public constant RUNE_ID_LIGHTNING_2 = 3071;
    uint32 public constant RUNE_ID_LIGHT_1 = 3080;
    uint32 public constant RUNE_ID_LIGHT_2 = 3081;
    uint32 public constant RUNE_ID_DARK_1 = 3090;
    uint32 public constant RUNE_ID_DARK_2 = 3091;
    uint32 public constant RUNE_ID_METAL_1 = 3100;
    uint32 public constant RUNE_ID_METAL_2 = 3101;
    uint32 public constant RUNE_ID_NETHER_1 = 3110;
    uint32 public constant RUNE_ID_NETHER_2 = 3111;
    uint32 public constant RUNE_ID_AETHER_1 = 3120;
    uint32 public constant RUNE_ID_AETHER_2 = 3121;

    // Legendary Elemental Runes
    uint32 public constant RUNE_ID_LEGENDARY_NEUTRAL = 4000;
    uint32 public constant RUNE_ID_LEGENDARY_FIRE = 4001;
    uint32 public constant RUNE_ID_LEGENDARY_WATER = 4002;
    uint32 public constant RUNE_ID_LEGENDARY_NATURE = 4003;
    uint32 public constant RUNE_ID_LEGENDARY_EARTH = 4004;
    uint32 public constant RUNE_ID_LEGENDARY_WIND = 4005;
    uint32 public constant RUNE_ID_LEGENDARY_ICE = 4006;
    uint32 public constant RUNE_ID_LEGENDARY_LIGHTNING = 4007;
    uint32 public constant RUNE_ID_LEGENDARY_LIGHT = 4008;
    uint32 public constant RUNE_ID_LEGENDARY_DARK = 4009;
    uint32 public constant RUNE_ID_LEGENDARY_METAL = 4010;
    uint32 public constant RUNE_ID_LEGENDARY_NETHER = 4011;
    uint32 public constant RUNE_ID_LEGENDARY_AETHER = 4012;

    // Elements
    uint32 public constant ELEMENT_ID_NEUTRAL = 1;
    uint32 public constant ELEMENT_ID_FIRE = 2;
    uint32 public constant ELEMENT_ID_WATER = 3;
    uint32 public constant ELEMENT_ID_NATURE = 4;
    uint32 public constant ELEMENT_ID_EARTH = 5;
    uint32 public constant ELEMENT_ID_WIND = 6;
    uint32 public constant ELEMENT_ID_ICE = 7;
    uint32 public constant ELEMENT_ID_LIGHTNING = 8;
    uint32 public constant ELEMENT_ID_LIGHT = 9;
    uint32 public constant ELEMENT_ID_DARK = 10;
    uint32 public constant ELEMENT_ID_METAL = 11;
    uint32 public constant ELEMENT_ID_NETHER = 12;
    uint32 public constant ELEMENT_ID_AETHER = 13;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../lib/RunicNFTLib.sol";

interface IRunicNFT {
    function setRunicAttributes(uint256, RunicNFTLib.RunicAttributes memory) external;
    function getRunicAttributes(uint256) external view returns (RunicNFTLib.RunicAttributes memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFTPower {
    function getPower(uint256 tokenId) external view returns (uint256 power);
    function getUserPower(address account) external view returns (uint256 power);
    function getTotalPower() external view returns (uint256 power);
    function addPower(address account, uint256 tokenId, uint256 power) external;
    function removePower(address account, uint256 tokenId, uint256 power) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

library TokenURIMetadata {
    using Strings for uint256;

    uint256 internal constant DISPLAY_TYPE_STRING = 0;
    uint256 internal constant DISPLAY_TYPE_NUMBER = 1;
    uint256 internal constant DISPLAY_TYPE_BOOST_NUMBER = 2;
    uint256 internal constant DISPLAY_TYPE_BOOST_PERCENTAGE = 3;
    uint256 internal constant DISPLAY_TYPE_DATE = 4;

    function dataAddArray(string memory data, string memory key, uint256[] memory arr) internal pure returns(string memory) {
        data = string(abi.encodePacked(data,
            ',"',key,'":['));
        for(uint256 i = 0; i < arr.length; i++) {
            string memory addition = '';
            if(i < arr.length - 1) {
                addition = ',';
            }
            data = string(abi.encodePacked(data, arr[i].toString(), addition));
        }
        data = string(abi.encodePacked(data, ']'));
        return data;
    }

    /**
     * @dev Generates string trait json
     */
    function getTraitStringJson(string memory traitType_, string memory value_) internal pure returns(string memory) {
        return getTraitStringJson(traitType_, value_, "");
    }

    /**
     * @dev Generates string trait json with frequency
     */
    function getTraitStringJson(string memory traitType_, string memory value_, string memory frequency_) internal pure returns(string memory) {
        if(bytes(frequency_).length > 0) {
            return string(abi.encodePacked('{"trait_type":','"',traitType_,'"',',"value":"',value_,'","frequency":"',frequency_,'"}'));
        }
        return string(abi.encodePacked('{"trait_type":','"',traitType_,'"',',"value":"',value_,'"}'));
    }

    /**
     * @dev Generates numeric trait json with number display type
     */
    function getTraitUint256Json(string memory traitType_, uint256 value_) internal pure returns(string memory) {
        return getTraitUint256Json(traitType_, value_, DISPLAY_TYPE_NUMBER, 0, "");
    }

    /**
     * @dev Generates numeric trait json with number display type
     */
    function getTraitUint256Json(string memory traitType_, uint256 value_, string memory frequency_) internal pure returns(string memory) {
        return getTraitUint256Json(traitType_, value_, DISPLAY_TYPE_NUMBER, 0, frequency_);
    }

    /**
     * @dev Generates numeric trait json with number display type and max value
     */
    function getTraitUint256Json(string memory traitType_, uint256 value_, uint256 maxValue_) internal pure returns(string memory) {
        return getTraitUint256Json(traitType_, value_, DISPLAY_TYPE_NUMBER, maxValue_, "");
    }

    /**
     * @dev Generates numeric trait json with number display type and max value
     */
    function getTraitUint256Json(string memory traitType_, uint256 value_, uint256 maxValue_, string memory frequency_) internal pure returns(string memory) {
        return getTraitUint256Json(traitType_, value_, DISPLAY_TYPE_NUMBER, maxValue_, frequency_);
    }

    /**
     * @dev Generates numeric trait json
     */
    function getTraitUint256Json(string memory traitType_, uint256 value_, uint256 displayType_, uint256 maxValue_, string memory frequency_) internal pure returns(string memory) {
        string memory display_type;
        if(displayType_ == DISPLAY_TYPE_NUMBER) {
            display_type = "number";
        }
        if(displayType_ == DISPLAY_TYPE_BOOST_NUMBER) {
            display_type = "boost_number";
        }
        if(displayType_ == DISPLAY_TYPE_BOOST_PERCENTAGE) {
            display_type = "boost_percentage";
        }
//        string memory str = string(abi.encodePacked('{"display_type":"',display_type,'","trait_type":"',traitType_,'","value":',value_.toString()));
        string memory str = string(abi.encodePacked('{"trait_type":"',traitType_,'","value":',value_.toString()));
        if(maxValue_ > 0 && maxValue_ >= value_) {
            str = string(abi.encodePacked(str,',"max_value":',maxValue_.toString()));
        }
        if(bytes(frequency_).length > 0) {
            str = string(abi.encodePacked(str,',"frequency":"',frequency_,'"'));
        }
        return string(abi.encodePacked(str,'}'));
    }

    /**
     * @dev Generates date trait json
     */
    function getTraitDateJson(string memory traitType_, uint256 value_) internal pure returns(string memory) {
//        return string(abi.encodePacked('{"display_type":"date","trait_type":','"',traitType_,'"',',"value":"',value_.toString(),'"}'));
        return string(abi.encodePacked('{"trait_type":','"',traitType_,'"',',"value":"',value_.toString(),'"}'));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface ITokenURIProcessor {
    function getTokenURI(uint256) external view returns(string memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface INFT {
    function getAttribute(uint256 tokenId, uint256 attributeId) external view returns(uint256 value);
    function getAttributeString(uint256 tokenId, uint256 attributeId) external view returns(string memory value);
    function getAttributeAddress(uint256 tokenId, uint256 attributeId) external view returns(address value);
    function getAttributeArray(uint256 tokenId, uint256 attributeId) external view returns(uint256[] memory value);
    function getAttributeBytes(uint256 tokenId, uint256 attributeId) external view returns(bytes32[] memory value);
    function getTokenAddressData(uint256 tokenId, address account) external view returns(uint256 value);
    function getAddressData(uint256 id, address account) external returns(uint256 value);
    function getAddressMapping(uint256 id) external returns(address value);
    function getUintMapping(uint256 id) external returns(uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64

library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

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
                dataPtr := add(dataPtr, 3)

            // read 3 bytes
                let input := mload(dataPtr)

            // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AccessControlConstants {
    /**
     * Access Control Roles
     */
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR"); // 523a704056dcd17bcf83bed8b68c59416dac1119be77755efe3bde0a64e46e0c
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");     // f0887ba65ee2024ea881d91b74c2450ef19e1557f03bed3ea9f16b037cbe2dc9
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");       // df8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW"); // 7a8dc26796a1e50e6e190b70259f58f6a4edd5b22280ceecc82b687b8e982869
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}