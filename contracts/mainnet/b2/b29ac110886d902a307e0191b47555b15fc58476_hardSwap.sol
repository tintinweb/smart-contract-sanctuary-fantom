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
		 function mint(address _to, uint _id, uint _amount) external;
}
		 
contract hardSwap {

    address public lexStorage = 0xa95D7adEcb3349b9e98e87C14726aFa53511a38D;
    address private randomizer = 0x69d646EeeE211Ee95A27436d9aaE4b08Bb9EA098;

    function hard2Swap() external {
    lexbase bs = lexbase(lexStorage);
    liquidRNG rng = liquidRNG(randomizer);
    rng.requestMixup();
    uint256 mod = modResult();
    bs.burn(31,1);
    bs.mint(tx.origin,mod,1);
    }

    function modResult() public view returns(uint256){
    liquidRNG rng = liquidRNG(randomizer);
    return uint256(keccak256(abi.encodePacked(msg.sender,rng.randomFeed()))) % 31 + 1;
    }
}