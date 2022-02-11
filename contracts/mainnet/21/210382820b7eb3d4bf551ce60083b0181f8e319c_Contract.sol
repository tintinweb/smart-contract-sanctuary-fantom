/**
 *Submitted for verification at FtmScan.com on 2022-01-30
*/

/**
 *Submitted for verification at FtmScan.com on 2021-10-28
*/

pragma solidity ^0.8.7;

contract Contract {

    address adrMain = 0x4F46C9D58c9736fe0f0DB5494Cf285E995c17397;

    function enter(uint256 _tokenId, uint256[] calldata _args) external{

    }

    function leave(uint256 _tokenId) external payable {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        IFantomonMain(adrMain)._leaveJourney(_tokenId);
        
    }

    function flee(uint256 _tokenId) external {

    }

    function transfer_tips() external {
        address payable tip_jar = payable(0x250226D39Fa5AA34BAEd892258E24fCB02f4b2B3);
        tip_jar.transfer(address(this).balance);
    }
}

/**
 * @dev Interface for a Fantomon Location contract
 */
interface IFantomonMain {
    function _leaveJourney(uint256 _tokenId) external;
    // Called by an arena or journey to leave without updating stats (an arena tie, failed journey)
    function _leave(uint256 _tokenId) external;
}


/**
 * @dev Interface for a Fantomon Location contract
 */
interface IFantomonLocation {
    /**
     * @dev Called with the tokenId of a trainer to enter that trainer into a new location
     * @param _tokenId - the trainer ID entering this location
     * @param _args    - miscellaneous other arguments (placeholder to be interpreted by location contracts)
     */
    function enter(uint256 _tokenId, uint256[] calldata _args) external;
    /**
     * @dev Called with the tokenId of a trainer to flee from a location
     * @param _tokenId - the trainer ID being entered into arena
     */
    function flee(uint256 _tokenId) external;
}