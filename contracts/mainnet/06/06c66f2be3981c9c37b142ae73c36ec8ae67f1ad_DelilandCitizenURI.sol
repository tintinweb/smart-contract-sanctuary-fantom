/**
 *Submitted for verification at FtmScan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
// svg helper functions
pragma solidity ^0.8.0;
interface ISvg {
    function textClose() external pure returns (string memory);
    function textOpen(
        uint256 x, uint256 y, 
        string memory cssClass) external pure returns (string memory);
    function textOpenClose(
        uint256 x, uint256 y, 
        string memory cssClass) external pure returns (string memory);
    function begin() external pure returns (string memory);
     function style() external pure returns (string memory);   
     function bgRect(string memory color) external pure returns (string memory);
     function hexagon(string memory className, 
        uint256 minX, uint256 minY,
        uint256 maxX, uint256 maxY) external pure returns (string memory);
    function line(
        uint256 x1, uint256 y1, 
        uint256 x2, uint256 y2) external pure returns (string memory);
        function statPolygon(uint256[6] memory _stats, uint256 minX, uint256 minY,
     uint256 maxX, uint256 maxY) external pure returns (string memory);
}
interface ICitizen {
    function getPropetyList() external view returns (string[3] memory);
    function getStats(uint256 tokenId) external view returns (uint256[6] memory);
    function getNamedProperties(uint256 tokenId) external view returns (string[3] memory);
    function getTitle(uint256 tokenId) external view returns (string memory);
    function getName(uint256 tokenId) external view returns (string memory);
}
/*
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IStatGon {
    function statPolygon(uint256[6] memory _stats, uint256 minX, uint256 minY,
     uint256 maxX, uint256 maxY) external pure returns (string memory);
}

interface ICitizenship {
    function getLocation(uint256 tokenId) external view returns (string memory);
}

contract DelilandCitizenURI is Ownable {
    string public TITLE = "Deliland Citizen";
    ISvg svg = ISvg(0xEe204166E11cAd2e30111109778220FFf55b1543);
    ICitizen citizen = ICitizen(0x0000000000000000000000000000000000000000);
    IStatGon statgon = IStatGon(0x57dF9C90aeD471343a8D5Aa8dB272708B7cC865f);
    ICitizenship ship = ICitizenship(0x85eFf26fF84c3f3eC2882b2F2cdf28e0eC9492D5);
    function changeSvgLib(address newSvgLib) public onlyOwner {
        svg = ISvg(newSvgLib);
    }
    function changeCitizenContract(address newCitizen) public onlyOwner {
        citizen = ICitizen(newCitizen);
    }
    function changeStatGon(address newStatGon) public onlyOwner {
        statgon = IStatGon(newStatGon);
    }
    function changeShipAddress(address newShipAddress) public onlyOwner {
        ship = ICitizenship(newShipAddress);
    }
    function blurb() internal pure returns (string memory) {
        return '"A Deliland Citizen. Citizens are free to mint but only one can be held per wallet."';
    }
    function jsonify(uint256 tokenId, string memory stuff) internal view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "',TITLE,' #', 
            toString(tokenId), 
            '", "description": ',
            blurb(),
            ', "image": "data:image/svg+xml;base64,', 
            Base64.encode(bytes(stuff)), 
            '"}'))));
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _statPolygon(uint256 tokenId, uint256 minX, uint256 minY,
     uint256 maxX, uint256 maxY) public view returns (string memory) {
        uint256[6] memory _stats = citizen.getStats(tokenId);
        return statgon.statPolygon(_stats, minX, minY, maxX, maxY);
    }

    function rule_base() public pure returns (string memory) {
        return ' .base { fill: #afafaf; font-family: sans-serif; font-size: 14px;}';
    }

    function rule_big() public pure returns (string memory) {
        return ' .big { font-size: 20px; fill: white;}';
    }

    function rule_small() public pure returns (string memory) {
        return ' .small { font-size: 12px; fill: #c1c1c1;} .label {font-size: 8px; fill: #626262}';
    }

    function rule_hex() public pure returns (string memory) {
        return ' .hex {fill: #2a2a2a; } .hex--outer, .hex--middle-inner {fill: #aaaaaa}';
    }
    function rule_statgon() public pure returns (string memory) {
        return ' .statgon { fill: #67b363aa; } ';
    }

    string public extraCss = '';

    function changeExtraCss(string memory css) public onlyOwner {
        extraCss = css;
    }

    function style() public view returns (string memory) {
        
        
        return string(abi.encodePacked(
            '<style>',rule_base(),rule_big(),rule_small(),rule_hex(),rule_statgon(),extraCss,'</style>'));
    }


    // get the tokenURI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string[3] memory props = citizen.getNamedProperties(tokenId);
        string[3] memory properties = citizen.getPropetyList();
        string[17] memory parts;
        uint256 gutter = 16;
        parts[0] = string(abi.encodePacked(
            svg.begin(),style(),svg.bgRect("000000")));
        parts[1] = string(abi.encodePacked(
            svg.textOpen(gutter*2,40,"base big"), 
            citizen.getTitle(tokenId),
            ' ',
            citizen.getName(tokenId),
            svg.textClose()));
        parts[2] = string(abi.encodePacked(
            svg.textOpen(gutter*2,56,"base"), 
            'Lives in ',
            ship.getLocation(tokenId),
            svg.textClose()));
        parts[3] = string(abi.encodePacked(
            svg.textOpen(gutter*2,86,"base small"), 
            properties[0], ": ", props[0],
            svg.textClose()));
        parts[4] = string(abi.encodePacked(
            svg.textOpen(gutter*2,100,"base small"), 
            properties[1], ": ", props[1],
            svg.textClose()));
        parts[5] = string(abi.encodePacked(
            svg.textOpen(gutter*2,114,"base small"), 
            properties[2], ": ", props[2],
            svg.textClose()));
        uint256 minX = 124;
        uint256 minY = 124;
        uint256 maxX = 300;
        uint256 maxY = 300;
        parts[6] = svg.hexagon("hex hex--outer", minX, minY, maxX, maxY);
        parts[7] = svg.hexagon("hex hex--middle-outer", 140, 140, 284, 284);
        parts[8] = svg.hexagon("hex hex--middle-inner", 156, 156, 268, 268);
        parts[9] = svg.hexagon("hex hex--inner", 172, 172, 252, 252);
        parts[10] = string(abi.encodePacked(
            svg.line((minX + maxX)/2, minY, (minX + maxX)/2, maxY),
            svg.line(maxX, minY + (maxY-minY)/4, minX, maxY - (maxY-minY)/4),
            svg.line(maxX, maxY - (maxY-minY)/4, minX, minY + (maxY-minY)/4),
            _statPolygon(tokenId, minX, minY, maxX, maxY)
        ));

        parts[11] = string(abi.encodePacked(
            svg.textOpen((minX + maxX)/2 - 16,minY - 2,"base label"),
            "Strength",
            svg.textClose()
            ));
        parts[12] = string(abi.encodePacked(
            svg.textOpen(maxX + 2,minY + (maxY-minY)/4,"base label"),
            "Speed",
            svg.textClose()
            ));
        parts[13] = string(abi.encodePacked(
            svg.textOpen(maxX + 2,maxY - (maxY-minY)/4,"base label"),
            "Stamina",
            svg.textClose()
            ));
        parts[14] = string(abi.encodePacked(
            svg.textOpen((minX + maxX)/2 - 16,maxY + 8,"base label"),
            "Dexterity",
            svg.textClose()
            ));
        parts[15] = string(abi.encodePacked(
            svg.textOpen(minX - 32,maxY - (maxY-minY)/4,"base label"),
            "Wisdom",
            svg.textClose()
            ));
        parts[16] = string(abi.encodePacked(
            svg.textOpen(minX - 36,minY + (maxY-minY)/4,"base label"),
            "Charisma",
            svg.textClose()
            ));
        string memory statLabels = string(abi.encodePacked(
            parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]
            ));
        string memory preOutput = string(abi.encodePacked(
            parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
        string memory output = string(abi.encodePacked(
            preOutput,
            parts[6],
            parts[7], parts[8], parts[9], parts[10],
            statLabels,
            '<text x="248" y="330" class="base small">Deliland Citizen</text>',
            '<line x1="16" y1="16" x2="16" y2="334" stroke="white"/>',
            '</svg>'));

        return jsonify(tokenId, output);
    }
    constructor () Ownable() {

    }
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}
/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}