/**
 *Submitted for verification at FtmScan.com on 2022-02-02
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.7;


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



interface IFantomonTrainer {

    /**************************************************************************
     * Stats and attributes for all trainers
     **************************************************************************/
    function getKinship(uint256 _tokenId) external view returns (uint256);
    function getFlare(uint256 _tokenId) external view returns (uint256);
    function getCourage(uint256 _tokenId) external view returns (uint256);
    function getWins(uint256 _tokenId) external view returns (uint256);
    function getLosses(uint256 _tokenId) external view returns (uint256);
    /* Stats and attributes for all trainers
     **************************************************************************/

    /**************************************************************************
     * Getters
     **************************************************************************/
    function getStatus(uint256 _tokenId) external view returns (uint8);
    function getRarity(uint256 _tokenId) external view returns (uint8);
    function getClass(uint256 _tokenId) external view returns (uint8);
    function getFace(uint256 _tokenId) external view returns (uint8);
    function getHomeworld(uint256 _tokenId) external view returns (uint8);
    function getTrainerName(uint256 _tokenId) external view returns (string memory);
    function getHealing(uint256 _tokenId) external view returns (uint256);
    /* End getters
     **************************************************************************/
    function sing(uint256 _trainer, uint256 _fantomon, address _fantomonContract) external;
    function enterJourney(uint256 _tokenId, address _journey, uint256[] calldata _args) external;
    function enterHealingRift(uint256 _tokenId, address _rifts, uint256[] calldata _args) external;
    function _leaveJourney(uint256 _tokenId) external;
    function _leaveHealingRift(uint256 _tokenId) external;
    function _leave(uint256 _tokenId) external;
    function _leaveArena(uint256 _tokenId, bool _won) external ;
    function _enterBattle(uint256 _tokenId) external ;
    function ownerOf(uint256 tokenId) external view  returns (address); 
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function safeTransferFrom(address from, address to,uint256 tokenId) external;
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

interface IFantomon{
    function safeTransferFrom(address from, address to,uint256 tokenId) external;
}

contract SendArmyV22 is IFantomonLocation, Ownable{
    
    address private FTA = 0x4F46C9D58c9736fe0f0DB5494Cf285E995c17397;
    address private _journeyAddress; 
    address private _healingRiftAddress = 0x078937eBfe4b994162520de713AeA3541e38420A;
    address private _FantomonSing = 0x8d5043176Bebb9542a5cbfccb819068600Bf4384;
    address private _Fantomon =0xC93F8096f003B09690A546d40cbB971e9346dcf3;
    
    uint8 constant private RESTING   = 0;
    //uint8 constant private PREPARING = 1;
    //uint8 constant private BATTLING  = 2;
    //uint8 constant private HEALING   = 3;
    uint8 constant private LOST      = 4;

    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;
    
   
    IFantomonTrainer trainers = IFantomonTrainer(FTA);
    IFantomon Fmon = IFantomon(_Fantomon);

    function onERC721Received(address,address,uint256,bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
    
   
    
     /**
     * @dev Called with the tokenId of a trainer to enter that trainer into a new location
     * @param _tokenId - the trainer ID entering this location
     * @param _args    - miscellaneous other arguments (placeholder to be interpreted by location contracts)
     */
    function enter(uint256 _tokenId, uint256[] calldata _args) override external{
        
    }
    
    /**
     * @dev Called with the tokenId of a trainer to flee from a location
     * @param _tokenId - the trainer ID being entered into arena
     */
    function flee(uint256 _tokenId) override external{
        
    }
    function ASingAll(uint256 fantomonId) external{
        address sender = msg.sender;
        address thisAdress = address(this);
        require (isAprroved(sender),"Please get approvalForAll");
        require (balanceOnMain(sender)>0,"You don't own any token");
        uint256[] memory tokenIds = ownedTokensOnMain();
        Fmon.safeTransferFrom(sender,thisAdress,fantomonId);
        bool hasAny = false;
        for (uint16 i=0; i < tokenIds.length; i++){
                if (trainers.getStatus(tokenIds[i])==RESTING){
                    trainers.safeTransferFrom(sender,thisAdress,tokenIds[i]);
                    trainers.sing(tokenIds[i],fantomonId,_FantomonSing);
                    trainers.safeTransferFrom(thisAdress,sender,tokenIds[i]);
                    if(!hasAny){
                        hasAny=true;
                    }
                }
        }
        require(hasAny==true,"No trainer is resting or already went on journey in the last 12hrs");
        Fmon.safeTransferFrom(thisAdress,sender,fantomonId);
    }
    function ASingJourneyHealingRift(uint256 fantomonId) external{
        address sender = msg.sender;
        address thisAdress = address(this);
        require (isAprroved(sender),"Please get approvalForAll");
        require (balanceOnMain(sender)>0,"You don't own any token");
        uint256[] memory tokenIds = ownedTokensOnMain();
        Fmon.safeTransferFrom(sender,thisAdress,fantomonId);
        bool hasAny = false;
        for (uint16 i=0; i < tokenIds.length; i++){
                if (trainers.getStatus(tokenIds[i])==RESTING){
                    trainers.safeTransferFrom(sender,thisAdress,tokenIds[i]);
                    trainers.sing(tokenIds[i],fantomonId,_FantomonSing);
                    trainers.enterJourney(tokenIds[i],_journeyAddress,new uint256[](0));
                    trainers._leaveJourney(tokenIds[i]);
                    trainers.enterHealingRift(tokenIds[i],_healingRiftAddress,new uint256[](0));
                    trainers.safeTransferFrom(thisAdress,sender,tokenIds[i]);
                    if(!hasAny){
                        hasAny=true;
                    }
                }
        }
        require(hasAny==true,"No trainer is resting or already went on journey in the last 12hrs");
        Fmon.safeTransferFrom(thisAdress,sender,fantomonId);
    }
    function BJourneyAllDeployToHealingRift() external{
        address sender = msg.sender;
        address thisAdress = address(this);
        require (isAprroved(sender),"Please get approvalForAll");
        require (balanceOnMain(sender)>0,"You don't own any token");
        uint256[] memory tokenIds = ownedTokensOnMain();
        bool hasAny = false;
        for (uint16 i=0; i < tokenIds.length; i++){
                if (trainers.getStatus(tokenIds[i])==RESTING){
                    trainers.safeTransferFrom(sender,thisAdress,tokenIds[i]);
                    trainers.enterJourney(tokenIds[i],_journeyAddress,new uint256[](0));
                    trainers._leaveJourney(tokenIds[i]);
                    trainers.enterHealingRift(tokenIds[i],_healingRiftAddress,new uint256[](0));
                    trainers.safeTransferFrom(thisAdress,sender,tokenIds[i]);
                    if(!hasAny){
                        hasAny=true;
                    }
                }
        }
        require(hasAny==true,"No trainer is resting or already went on journey in the last 12hrs");
    }
    function DJourneyOnly() external{
        address sender = msg.sender;
        address thisAdress = address(this);
        require (isAprroved(sender),"Please get approvalForAll");
        require (balanceOnMain(sender)>0,"You don't own any token");
        uint256[] memory tokenIds = ownedTokensOnMain();
        bool hasAny = false;
        for (uint16 i=0; i < tokenIds.length; i++){
                require (sender==ownerOf(tokenIds[i]));
                if (trainers.getStatus(tokenIds[i])==RESTING){
                    trainers.safeTransferFrom(sender,thisAdress,tokenIds[i]);
                    trainers.enterJourney(tokenIds[i],_journeyAddress,new uint256[](0));
                    trainers._leaveJourney(tokenIds[i]);
                    trainers.safeTransferFrom(thisAdress,sender,tokenIds[i]);
                    if(!hasAny){
                        hasAny=true;
                    }
                }
        }
        require(hasAny==true,"No trainer is resting or already went on journey in the last 12hrs");
    }
    
    function CDeployAllToHealingRift() external{
        address sender = msg.sender;
        address thisAdress = address(this);
        uint256[] memory tokenIds = ownedTokensOnMain();
        bool hasAny = false;
        for (uint16 i=0; i < tokenIds.length; i++){
                require (sender==ownerOf(tokenIds[i]));
                if (trainers.getStatus(tokenIds[i])==RESTING){
                    trainers.safeTransferFrom(sender,thisAdress,tokenIds[i]);
                    trainers.enterHealingRift(tokenIds[i],_healingRiftAddress,new uint256[](0));
                    trainers.safeTransferFrom(thisAdress,sender,tokenIds[i]);
                    if(!hasAny){
                        hasAny=true;
                    }
                }
        }
        require(hasAny==true,"No trainer is resting or already went on journey in the last 12hrs");
        
    }
    
    
    //getters n setters
    function setJourney(address journey) external onlyOwner{
        _journeyAddress = journey;
    }
    function getJourney() public view returns(address){
        return _journeyAddress;
    }
    function setHealingRift(address rift) external onlyOwner{
        _healingRiftAddress = rift;
    }
    function getHealingRift() public view returns(address){
        return _healingRiftAddress;
    }
    function setFantomonSing(address FantomonSing) external onlyOwner{
        _FantomonSing = FantomonSing;
    }
    function getFantomonSing() public view returns(address){
        return _FantomonSing;
    }
    //helpers
    function balanceOnMain(address _address) public view returns (uint256){
        return trainers.balanceOf(_address);
    }
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return trainers.ownerOf(_tokenId);
    }
    
    function ownedTokensOnMain() public view returns(uint256[] memory){
        uint256 bal = balanceOnMain(msg.sender);
        if(bal>0){
            
            uint256[] memory ownedTokensM = new uint256[](bal);
            for (uint i=0; i<bal;i++){
                ownedTokensM[i]=trainers.tokenOfOwnerByIndex(msg.sender,i);
            }
            return ownedTokensM;
        }
        return new uint256[](0);
    }
    
    function isAprroved(address _sender) public view virtual returns (bool){
        return trainers.isApprovedForAll(_sender,address(this));
    }
    
    modifier Authorized(){
        require(msg.sender==owner());
        _;
    }
    
    
     /**************************************************************************
     * Payments
     **************************************************************************/
    function donation () external payable{
    }
    function withdraw() external onlyOwner(){
        address payable addr = payable(owner());
        addr.transfer(address(this).balance);
    }
    /* End payments
     **************************************************************************/

}