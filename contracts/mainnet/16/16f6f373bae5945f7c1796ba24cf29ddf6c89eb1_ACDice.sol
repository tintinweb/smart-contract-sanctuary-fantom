/**
 *Submitted for verification at FtmScan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAssetBox {
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract ACDice {

    uint private _flag;
    address public copper;
    uint public NPC;
    uint8 public NPCRole;
    uint public base; 
    bool private initialized;

    event Rolled(uint8 indexed roleIndex, uint indexed tokenId, uint expect, uint amount, uint random, bool result, uint gain);

    function initialize(address copper_, uint8 NPCRole_, uint NPC_, uint base_) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        copper = copper_;
        NPCRole = NPCRole_;
        NPC = NPC_;
        base = base_;
        _flag = 0;
    }

    function _isContract(address addr) private view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _diceRoll(uint roll_) private returns (uint){
        _flag ++;
        return uint(keccak256(abi.encodePacked(blockhash(block.number-1), _flag))) % roll_;
    }

    function roll(uint8 roleIndex, uint tokenId, uint expect, uint amount) external returns (uint, bool) {
        require(expect >= 3 && expect <= 95, "beyond scope");
        require(amount > 0 && amount % 1024 == 0 && amount <= 1024 * 32, "amount illegal");

        address roleAddress = IAssetBox(copper).getRole(roleIndex);
        require(_isApprovedOrOwner(roleAddress, msg.sender, tokenId), "Not approved or owner");

        uint random = _diceRoll(100);

        if (_isContract(msg.sender)) {
            random = 98;
        }

        bool result = expect > random;

        uint gain = 0;
        
        if(result) {
            uint odds = base * 10000 / expect - 10000;
            uint win = odds * amount / 10000;
            uint fee = win * 10 / 100;

            gain = win - fee;

            IAssetBox(copper).burn(NPCRole, NPC, gain);
            IAssetBox(copper).mint(roleIndex, tokenId, gain);
        } else{
            IAssetBox(copper).burn(roleIndex, tokenId, amount);
            IAssetBox(copper).mint(NPCRole, NPC, amount);
        }

        emit Rolled(roleIndex, tokenId, expect, amount, random, result, gain);
        return (random, result);
    }

    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }
}