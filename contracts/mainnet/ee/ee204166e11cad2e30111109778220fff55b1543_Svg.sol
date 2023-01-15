/**
 *Submitted for verification at FtmScan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
// svg helper functions
pragma solidity ^0.8.0;
contract Svg {
    function _toString(uint256 value) internal pure returns (string memory) {
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

    function textClose() external pure returns (string memory) {
        return '</text>';
    }

    // utility for creating the start of an svg text element
    function textOpen(
        uint256 x, uint256 y, 
        string memory cssClass) external pure returns (string memory) {
        return string(abi.encodePacked('<text x="',_toString(x),'" y="',_toString(y),'" class="',cssClass,'">'));
    }

    // utility for creating the closing tag of an svg text element followed by the start of an svg text element
    function textOpenClose(
        uint256 x, uint256 y, 
        string memory cssClass) external pure returns (string memory) {
        return string(abi.encodePacked('</text><text x="',_toString(x),'" y="',_toString(y),'" class="',cssClass,'">'));
    }

    function begin() external pure returns (string memory) {
        return '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">';
    }

    function style() external pure returns (string memory) {
        string memory _base = ' .base { fill: #afafaf; font-family: sans-serif; font-size: 14px;}';
        string memory _big = ' .big { font-size: 20px; fill: white;}';
        string memory _small = ' .small { font-size: 12px; fill: #c1c1c1;}';
        string memory _hex = ' .hex {fill: #2a2a2a; } .hex--outer, .hex--middle-inner {fill: #aaaaaa}';
        return string(abi.encodePacked('<style>',_base,_big,_small,_hex,'</style>'));
    }

    function bgRect(string memory color) external pure returns (string memory) {
        return string(abi.encodePacked('<rect width="100%" height="100%" fill="#',color,'" />'));
    }
    function _hexagon(
        string memory className, 
        uint256 minX, 
        uint256 minY, 
        uint256 maxX, 
        uint256 maxY) internal pure returns (string memory) {
        string memory output = string(abi.encodePacked('<polygon class="',
            className,'" ',
            'points="'));
        output = string(abi.encodePacked(output, 
            _toString((minX + maxX)/2), ', ',_toString(minY), ' '));
        output = string(abi.encodePacked(
            output,
            _toString(maxX), ', ',_toString(minY + (maxY-minY)/4), ' '
        ));

        output = string(abi.encodePacked(
            output,
            _toString(maxX), ', ',_toString(minY + 3*(maxY-minY)/4), ' '));
        
        output = string(abi.encodePacked(
            output,
            _toString((minX + maxX)/2), ', ',_toString(maxY), ' '));
        output = string(abi.encodePacked(
            output,
            _toString(minX), ', ',_toString(minY + 3*(maxY-minY)/4), ' '));
        output = string(abi.encodePacked(
            output,
            _toString(minX), ', ',_toString(minY + (maxY-minY)/4)
        ));
        return string(abi.encodePacked(output,'"/>'));
    }

    function hexagon(string memory className, 
        uint256 minX, uint256 minY,
        uint256 maxX, uint256 maxY) external pure returns (string memory) {
        return _hexagon(className, minX, minY, maxX, maxY);
     }

     function line(
        uint256 x1, uint256 y1, 
        uint256 x2, uint256 y2) external pure returns (string memory) {
         return string(abi.encodePacked(
             '<line x1="',
             _toString(x1),
             '" y1="',
             _toString(y1),
             '" x2="',
             _toString(x2),
             '" y2="',
             _toString(y2),
             '" stroke="white"/>'
         ));
     }

}