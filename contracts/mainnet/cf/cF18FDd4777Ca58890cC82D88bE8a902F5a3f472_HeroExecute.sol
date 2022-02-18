/**
 *Submitted for verification at FtmScan.com on 2022-02-18
*/

// File: HeroExecute.sol


// Hero Execute Contract v1.0.0

pragma solidity ^0.8.10;

interface IRarity {
    function adventure(uint _summoner) external;
    function level_up(uint _summoner) external;
}

interface IRarity_gold {
    function claim(uint summoner) external;
}

interface IRarity_crafting_materials {
    function adventure(uint _summoner) external returns(uint);
}

contract HeroExecute {
    IRarity constant ra = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);
    IRarity_gold constant rg = IRarity_gold(0x2069B76Afe6b734Fb65D1d099E7ec64ee9CC76B2);
    IRarity_crafting_materials constant rcm = IRarity_crafting_materials(0x2A0F1cB17680161cF255348dDFDeE94ea8Ca196A);

    function multipleAdventure(uint256[] calldata summoners) external {
        for (uint256 i = 0; i < summoners.length; i++) {
            ra.adventure(summoners[i]);
        }
    }

    function multipleLevelUp(uint256[] calldata summoners) external {
        for (uint256 i = 0; i < summoners.length; i++) {
            ra.level_up(summoners[i]);
        }
    }

    function multipleClaimGold(uint256[] calldata summoners) external {
        for (uint256 i = 0; i < summoners.length; i++) {
            rg.claim(summoners[i]);
        }
    }

    function multipleCraftingMaterialsAdventure(uint256[] calldata summoners) external {
        for (uint256 i = 0; i < summoners.length; i++) {
            rcm.adventure(summoners[i]);
        }
    }
}