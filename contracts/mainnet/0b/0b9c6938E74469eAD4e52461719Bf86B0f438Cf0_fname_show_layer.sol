/**
 *Submitted for verification at FtmScan.com on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
    
    function toString(uint256 value) internal pure returns (string memory) {
    
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
    address internal buildlayer;

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
    
    function c_buildlayer(address _b)public virtual onlyOwner {
        buildlayer = _b;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface ifname_build_layer {
    function isClaimed(string memory name) external view returns(bool);
    function getNameInfoWithName(string memory _name) external view returns(bool result,string memory name,uint256 uid,string memory nameAvatar, string memory nameDes, string memory nameLink, address addr);
    function getNameInfoWithID(uint256 _uid)external view returns(bool result,string memory name,uint256 uid,string memory nameAvatar, string memory nameDes, string memory nameLink, address addr);
    function getNamesAmount()external view returns(uint256);
    function getNameInfo(address uaddr) external view returns(bool result,string memory name,uint256 uid,string memory nameAvatar, string memory nameDes, string memory nameLink, address addr);
}


contract fname_show_layer is Ownable{
     
    function show_info_ERC721(uint256 _uid) public view returns (string memory) {
        string[7] memory parts;
        string memory output;
        ifname_build_layer sbl = ifname_build_layer(buildlayer);
        (,string memory name,,string memory avatar,string memory des,string memory link,) = sbl.getNameInfoWithID(_uid);
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 700 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = string(abi.encodePacked("##Fantom##Name_System_Protocol", '</text><text x="10" y="40" class="base">'));
        parts[2] = string(abi.encodePacked("Name: ", name,".ftm", '</text><text x="10" y="60" class="base">'));
        parts[3] = bytes(avatar).length > 0 ? string(abi.encodePacked("Avatar: ", avatar, '</text><text x="10" y="80" class="base">')) : string(abi.encodePacked("Avatar: ", "no set", '</text><text x="10" y="80" class="base">'));
        parts[4] = bytes(link).length > 0 ? string(abi.encodePacked("Link: ", link, '</text><text x="10" y="100" class="base">')) : string(abi.encodePacked("Link: ", "no set", '</text><text x="10" y="100" class="base">'));
        parts[5] = bytes(des).length > 0 ? string(abi.encodePacked("Description: ", des, '</text><text x="10" y="120" class="base">')) : string(abi.encodePacked("Description: ", "no set", '</text><text x="10" y="120" class="base">'));

        parts[6] = '</text></svg>';
        output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "fname', '", "description": "fname, build on #Fantom. A on-chain naming system protocol that stores basic user information.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
        return output;
    }
    

    function isClaimed(string memory name) public view returns(bool) {
        return ifname_build_layer(buildlayer).isClaimed(name);
    }

    function show_nameInfo_withID(uint256 _uid) public view returns(bool result,string memory name,uint256 uid,string memory nameAvatar, string memory nameDes, string memory nameLink, address addr){
        return ifname_build_layer(buildlayer).getNameInfoWithID(_uid);
    }

    function show_nameInfo_withName(string memory _name) public view returns(bool result,string memory name,uint256 uid,string memory nameAvatar, string memory nameDes, string memory nameLink, address addr){
        return ifname_build_layer(buildlayer).getNameInfoWithName(_name);
    }

    /*
        If id or name is already known, it is recommended to use 'show_nameInfo_withID' or 'show_nameInfo_withName' .
    */
    function show_nameInfo() public view returns(bool result,string memory name,uint256 uid,string memory nameAvatar, string memory nameDes, string memory nameLink, address addr){
         return ifname_build_layer(buildlayer).getNameInfo(msg.sender);
    }

    function show_nameAmount() public view returns(uint256 amount){
        return ifname_build_layer(buildlayer).getNamesAmount();
    }

    function toString(uint256 value) internal pure returns (string memory) {
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