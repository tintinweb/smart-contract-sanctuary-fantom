/**
 *Submitted for verification at FtmScan.com on 2022-03-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IBreeding {
    function generation(uint tokenId) external view returns (uint32);
}

interface IBadge {
    function mint(uint8 roleIndex, uint to, uint32 value, uint32 eventKey) external;
    function roles(uint8 roleIndex) external view returns (address);
}

contract HatchingBadge {
    address immutable public badge;
    address immutable public breeding;
    address immutable public monsterV1;
    // Monster genesis
    uint8 constant private roleIndex = 2;
    mapping (uint32 => uint32) eventValue;

    constructor(address badge_, address breeding_) {
        badge = badge_;
        breeding = breeding_;
        monsterV1 = IBadge(badge).roles(roleIndex);

        eventValue[1] = 40;
        eventValue[2] = 310;
        eventValue[3] = 1230;
    }

    function isClaimable(uint32 eventKey, uint tokenId) public view returns(bool){
        if(eventKey == 1) {
            return IBreeding(breeding).generation(tokenId) >= 1;
        }else if(eventKey == 2) {
            return IBreeding(breeding).generation(tokenId) >= 5;
        }else if(eventKey == 3) {
            return IBreeding(breeding).generation(tokenId) >= 10;
        }

        return false;
    }

    function claim(uint32 eventKey, uint tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        require(isClaimable(eventKey, tokenId), "not met condition");

        IBadge(badge).mint(roleIndex, tokenId, eventValue[eventKey], eventKey);
    }

    function _isApprovedOrOwner(address operator, uint256 tokenId) private view returns (bool) {
        address TokenOwner = IERC721(monsterV1).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(monsterV1).getApproved(tokenId) == operator || IERC721(monsterV1).isApprovedForAll(TokenOwner, operator));
    }
}