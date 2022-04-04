/**
 *Submitted for verification at FtmScan.com on 2022-04-04
*/

pragma solidity ^0.8.12;

interface IPotionPalace {

    struct Stake {
        uint256 magePunkId;
        uint256 potionBrewedBlock;
        address owner;
    }

     function receipt(uint256 id) external returns (Stake memory);
     function collectAll(uint256[] calldata magePunkId) external returns (bool);
}
 

contract PotionPalaceHelper {



    address magesPalaceAddress =0xCE602B8734CbACa42fCe35BcCB242A98b41a5Ed6;
    address arcturianPalaceAddress =0x746b38f54D68342CD0ce7063B12B1e1a1AeFe85e;
    constructor() {
    }

     function collectAll(uint256[] calldata magePunks,uint256[] calldata arcturians) external returns (bool){
       bool collectedArcturian = IPotionPalace(arcturianPalaceAddress).collectAll(arcturians); 
       bool collectedMage= IPotionPalace(magesPalaceAddress).collectAll(magePunks);
       return collectedArcturian && collectedMage;
     }
}