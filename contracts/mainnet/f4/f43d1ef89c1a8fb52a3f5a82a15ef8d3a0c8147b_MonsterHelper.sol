/**
 *Submitted for verification at FtmScan.com on 2022-05-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface EncounterMining3 {
    //1=hero 3=monster
    function stake(uint8 roleIndex, uint tokenID) external;
    function withdrawal(uint8 roleIndex, uint tokenId) external;
    function getMinedAndLooted(uint8 roleIndex, uint tokenId) external view returns(uint);

}

interface Monster {
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract MonsterHelper {
    
    Monster monsterContrac=Monster(0x881c9c392F4E02Dd599dE22CaDAa98977c4CFB90);
    EncounterMining3 miningContract = EncounterMining3(0x450B9E5d4aFE7e665760d53544C14D8f11c66a2d);

    mapping(address => uint256[]) ownerTokenIds;

    function fillYourMonsterIds(uint256[] calldata _ids) external {
        bool isOwner=true;
        for(uint i=0;i<_ids.length;i++){
            if(monsterContrac.ownerOf(_ids[i]) != msg.sender){
                isOwner =false;
                break;
            }
        }

        if(isOwner){
            ownerTokenIds[msg.sender] = _ids;
        }
    }

    function batchMining() external {
        uint256[] memory tokenIds = ownerTokenIds[msg.sender];
        require(tokenIds.length > 0,"no monster fill");
        require(tokenIds.length <= 200,"too much monsters");

        for(uint i=0;i<tokenIds.length;i++){
            if(monsterContrac.ownerOf(tokenIds[i]) == msg.sender){
                miningContract.stake(3,tokenIds[i]);
            }
        }
    }


    function filledMonsterIds(address _addr) external view returns(uint[] memory){
        return ownerTokenIds[_addr];
    }

    function monsterOwner(uint tokenId) external view returns(address){
        return monsterContrac.ownerOf(tokenId);
    }

    function getMinedCopper(address _addr) external view returns(uint[] memory){
        uint256[] memory tokenIds = ownerTokenIds[_addr];
        uint256[] memory results =new uint256[](tokenIds.length);
        for(uint i=0;i<tokenIds.length;i++){
            results[i]=miningContract.getMinedAndLooted(3,tokenIds[i]);
        }
        return results;
    }

    function batchMining(uint256[] calldata _ids) external {
        for(uint i=0;i<_ids.length;i++){
            if(monsterContrac.ownerOf(_ids[i]) == msg.sender){
                miningContract.stake(3,_ids[i]);
            }
        }
    }


    function batchLeave() external{
        uint256[] memory tokenIds = ownerTokenIds[msg.sender];
        require(tokenIds.length > 0,"no monster fill");
        require(tokenIds.length <= 200,"too much monsters");

        for(uint i=0;i<tokenIds.length;i++){
            if(monsterContrac.ownerOf(tokenIds[i]) == msg.sender){
                miningContract.withdrawal(3,tokenIds[i]);
            }
        }
    }

    function batchLeave(uint256[] calldata _ids) external{
        for(uint i=0;i<_ids.length;i++){
            if(monsterContrac.ownerOf(_ids[i]) == msg.sender){
                miningContract.withdrawal(3,_ids[i]);
            }
        }
    }
}