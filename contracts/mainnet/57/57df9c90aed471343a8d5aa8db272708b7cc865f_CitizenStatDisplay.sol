/**
 *Submitted for verification at FtmScan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
// Builds Deliland Citizen stat hexagon
pragma solidity ^0.8.0;
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
contract CitizenStatDisplay is Ownable {
    ISvg svg = ISvg(0xEe204166E11cAd2e30111109778220FFf55b1543);
    function changeSvgLib(address newSvgLib) public onlyOwner {
        svg = ISvg(newSvgLib);
    }
    function getScaledStats(uint256[6] memory _stats) public pure returns (uint256[6] memory) {
        uint256[6] memory statsScaled;
       
        uint256 MAX = 100000;
        uint256 i;
        
        for (i = 0; i < 6; i++) {
            statsScaled[i] = 10000*_stats[i]/MAX;
        }
        return statsScaled;
    }
 function statPolygon(uint256[6] memory _stats, uint256 minX, uint256 minY,
     uint256 maxX, uint256 maxY) public pure returns (string memory) {
        uint256[6] memory statsScaled;
        uint256[6] memory statsX;
        uint256[6] memory statsY;
       
        uint256[2] memory center = [(maxX + minX)/2, (maxY + minY)/2];
        statsScaled = getScaledStats(_stats);    

        statsX[0] = center[0];
        statsX[3] = center[0];
        uint256 dy = (maxY - minY)/2;
        uint256 dx = (maxX - minX)/2;

        statsY[0] = center[1] - statsScaled[0]*dy/10000;
        statsY[3] = center[1] + statsScaled[3]*dy/10000;

        statsX[1] = center[0] + statsScaled[1]*dx/10000;
        statsY[1] = center[1] - statsScaled[1]*(dy/2)/10000;

        statsX[2] = center[0] + statsScaled[2]*dx/10000;
        statsY[2] = center[1] + statsScaled[2]*(dy/2)/10000;

        statsX[4] = center[0] - statsScaled[4]*dx/10000;
        statsY[4] = center[1] + statsScaled[4]*(dy/2)/10000;

        statsX[5] = center[0] - statsScaled[5]*dx/10000;
        statsY[5] = center[1] - statsScaled[5]*(dy/2)/10000;

 
        if (statsY[0] == center[1]) {
            statsY[0] = center[1] - 2;
        }

        if(statsY[3] == center[1]) {
            statsY[3] = center[1] + 2;
        }

        if(statsX[1] == center[0] && statsY[1] == center[1]) {
            statsX[1] = center[0] + 2;
            statsY[1] = center[1] - 1;
        }
        if(statsX[2] == center[0] && statsY[2] == center[1]) {
            statsX[2] = center[0] + 2;
            statsY[2] = center[1] + 1;
        }
        if(statsX[4] == center[0] && statsY[4] == center[1]) {
            statsX[4] = center[0] - 2;
            statsY[4] = center[1] + 1;
        }
        if(statsX[5] == center[0] && statsY[5] == center[1]) {
            statsX[5] = center[0] - 2;
            statsY[5] = center[1] - 1;
        }

        uint256 j;
        string[6] memory points;
        for (j = 0; j < 6; j++) {
            points[j] = string(abi.encodePacked(
                _toString(statsX[j]),
                ', ',
                _toString(statsY[j]),
                ' '
            ));
        }

        string memory output = string(abi.encodePacked(
            '<polygon class="statgon" fill="#67b363" points="',
            points[0], points[1], points[2], points[3], points[4], points[5],
            '" />'
        ));

        return output;
    }
    constructor() Ownable() {

    }
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
}