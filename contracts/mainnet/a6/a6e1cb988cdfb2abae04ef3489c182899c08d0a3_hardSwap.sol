/**
 *Submitted for verification at FtmScan.com on 2022-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface liquidRNG{
    	function randomFeed() external view returns (uint256);
        function requestMixup() external;
}
interface lexbase {
	     function burn(uint _id, uint _amount) external;
        function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external;
		 function mint(address _to, uint _id, uint _amount) external;
}
		 
contract hardSwap {

    address public lexStorage = 0xa95D7adEcb3349b9e98e87C14726aFa53511a38D;
    address private randomizer = 0x69d646EeeE211Ee95A27436d9aaE4b08Bb9EA098;

    function hard2Swap() external {
    lexbase bs = lexbase(lexStorage);
    liquidRNG rng = liquidRNG(randomizer);
    rng.requestMixup();
    uint256[] memory rs = new uint[](1);
    uint256[] memory hd = new uint[](1);
    uint256[] memory qs = new uint[](1);
    rs[0] = modResult();
    hd[0] = 31;
    qs[0] = 1;
    bs.burnForMint(tx.origin,hd,qs,rs,qs);
    }

    function modResult() public view returns(uint256){
    liquidRNG rng = liquidRNG(randomizer);
    return uint256(keccak256(abi.encodePacked(block.timestamp,msg.sender,rng.randomFeed()))) % 31 + 1;
    }
}