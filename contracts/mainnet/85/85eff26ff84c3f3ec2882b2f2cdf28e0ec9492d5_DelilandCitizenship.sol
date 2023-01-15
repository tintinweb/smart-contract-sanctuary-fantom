/**
 *Submitted for verification at FtmScan.com on 2023-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
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
interface ICitizen {
    function ownerOf(uint256 tokenId) external view returns (address);
    function getProperties(uint256 tokenId) external view returns (uint256[3] memory);
}
interface IMap {
    function getLocation (
        uint256 region, 
        uint256 location) external view returns (string memory);
    function getMaxPop (
        uint256 region, 
        uint256 location) external view returns (uint256);
    
}

interface IERC20 {
    function mint(address to, uint256 amount) external;
}

interface IUbi {
    function getUBI (
        uint256 region, 
        uint256 location) external view returns (uint256);
}

contract DelilandCitizenship is Ownable {

    error LocationDoesNotExist(uint256 region, uint256 location);
    error NotTheOwner(uint256 tokenId, address sender);
    error LocationIsFull(uint256 region, uint256 location);
    error AlreadyRegistered(uint256 tokenId);
    error NotRegistered(uint256 tokenId);

    ICitizen citizen = ICitizen(0x0000000000000000000000000000000000000000);
    function changeCitizenContract(address newCitizen) public onlyOwner {
        citizen = ICitizen(newCitizen);
    }

    IMap delimap = IMap(0x89EDa85E9DC7d2D43dB9B091A0CF0643083c7522);
    function changeMap(address newMap) public onlyOwner {
        delimap = IMap(newMap);
    }

    
    IERC20 ubi_token = IERC20(0x3f9C449FEBb5e8cC452637ACe9287dD806F49B86);
    function changeUbiToken(address newUbiToken) public onlyOwner {
        ubi_token = IERC20(newUbiToken);
    }

    
    IUbi ubi = IUbi(0x40258684a94B1e22Ae7A5033C37B8F8b258E36E6);
    function changeUbi(address newUbi) public onlyOwner {
        ubi = IUbi(newUbi);
    }

    uint256 public fee = 10 ether;
    function changeFee(uint256 newFee) public onlyOwner {
        fee = newFee;
    }

    uint256 public minCitizenshipLength = 13 weeks;
    function changeMinCitizenshipLength(uint256 newMin) public onlyOwner {
        minCitizenshipLength = newMin;
    }

    mapping (uint256 => uint256[]) public pops;


    // ---------------------------------------------------------------------------
    // ---------------------------------------------------------------------------
    // citizenship ---------------------------------------------------------------
    mapping (uint256 => uint256[2]) locationIndicesByTokenId;
    mapping (uint256 => bool) hasRegisteredByTokenId;
    mapping (uint256 => uint256) citizenSinceById;

    function _ownsCitizen(uint256 _tokenId, address _sender) internal view {
        if (citizen.ownerOf(_tokenId) != _sender) revert NotTheOwner({tokenId: _tokenId, sender: _sender});
    }

    function _isValidLocation(uint256 _region, uint256 _location) internal view {
        if (_region >= 4 || bytes(delimap.getLocation(_region,_location)).length == 0) revert LocationDoesNotExist({region: _region, location: _location});
    }

    function isValidLocation(uint256 _region, uint256 _location) public view {
        _isValidLocation(_region, _location);
    } 
    
    function _hasSpace(uint256 _region, uint256 _location) internal view {
        if (pops[_region][_location] + 1 > delimap.getMaxPop(_region,_location)) revert LocationIsFull({region: _region, location: _location});
    }
    function hasSpace(uint256 _region, uint256 _location) public view {
        _hasSpace(_region, _location);
    }

    function _notRegistered(uint256 _tokenId) internal view {
        if (hasRegisteredByTokenId[_tokenId] == true) revert AlreadyRegistered({tokenId: _tokenId});
    }
    function _isRegistered(uint256 _tokenId) internal view {
        if (hasRegisteredByTokenId[_tokenId] == false) revert NotRegistered({tokenId: _tokenId});
    }

    function _updateCitizenship(uint256 tokenId, uint256 region, uint256 location) internal {
        locationIndicesByTokenId[tokenId] = [region, location];
        pops[region][location] += 1;
        citizenSinceById[tokenId] = block.timestamp;
    }

    function _timeAsCitizen(uint256 tokenId) internal view returns (uint256) {
        return block.timestamp - citizenSinceById[tokenId];
    }

    function _correctFee(uint256 value) internal view {
        if (value != fee) revert MustPayCitizenshipFee();
    }

    function _hasBeenCitizenLongEnough(uint256 tokenId) internal view {
        if (_timeAsCitizen(tokenId) < 13 weeks) revert ChangedTooRecently();
    }

    function commonChecks( 
        uint256 region, uint256 location ) public view {
            
            _isValidLocation(region, location);
            _hasSpace(region, location);
        }

    function registerCitizenship(uint256 tokenId, 
        uint256 region, uint256 location) public {
            _ownsCitizen(tokenId, msg.sender);
        commonChecks( region, location);
        _notRegistered(tokenId);
        hasRegisteredByTokenId[tokenId] = true;
        _updateCitizenship(tokenId, region, location);
        _registerForUBI(tokenId);
    }

    error ChangedTooRecently();
    error MustPayCitizenshipFee();
    function changeCitizenship(uint256 tokenId, 
        uint256 region, uint256 location) public payable {
            _ownsCitizen(tokenId, msg.sender);
        commonChecks( region, location);
        _isRegistered(tokenId);
        _hasBeenCitizenLongEnough(tokenId);
        _correctFee(msg.value);
        _claimUBI(msg.sender, tokenId);
        uint256 a = locationIndicesByTokenId[tokenId][0];
        uint256 b = locationIndicesByTokenId[tokenId][1];
        pops[a][b] -= 1;
        _updateCitizenship(tokenId, region, location);

    }

    function _getLocIndex(uint256 tokenId) internal view returns (uint256[2] memory) {
        uint256 a = locationIndicesByTokenId[tokenId][0];
        uint256 b = locationIndicesByTokenId[tokenId][1];
        return [a,b];
    }
    function getLocIndex(uint256 tokenId) public view returns (uint256[2] memory) {
        return _getLocIndex(tokenId);
    }

    function _getLocation(uint256 tokenId) internal view returns (string memory) {
        uint256 a = locationIndicesByTokenId[tokenId][0];
        uint256 b = locationIndicesByTokenId[tokenId][1];
        return delimap.getLocation(a,b);
    }
    function getLocation(uint256 tokenId) public view returns (string memory) {
        return _getLocation(tokenId);
    }


    // ---------------------------------------------------------------------------
    // ---------------------------------------------------------------------------
    // universal basic income ----------------------------------------------------
    mapping (uint256 => uint256) public lastUBIclaimByID;
    error AlreadyUBI();
    function _registerForUBI (uint256 tokenId) internal {
        if (lastUBIclaimByID[tokenId] > 0) revert AlreadyUBI();
        lastUBIclaimByID[tokenId] = block.timestamp;
    }

    function getLastClaim (uint256 tokenId) public view returns (uint256) {
        return lastUBIclaimByID[tokenId];
    }

    function _getBaseRate(uint256 tokenId) internal view returns (uint256) {
        uint256[2] memory index = _getLocIndex(tokenId);
        return ubi.getUBI(index[0],index[1]);
    }
    function getBaseRate(uint256 tokenId) public view returns (uint256) {
        return _getBaseRate(tokenId);
    }

    function _getExtraRate(uint256 tokenId) internal view returns (uint256) {
        return citizen.getProperties(tokenId)[2];
    }
    function getExtraRate(uint256 tokenId) public view returns (uint256) {
        return _getExtraRate(tokenId);
    }

    function _getUBIrate (uint256 tokenId) internal view returns (uint256) {
        
        return (_getExtraRate(tokenId) + _getBaseRate(tokenId)) * 10 ** 18;
    }

    function getUBIrate (uint256 tokenId) public view returns (uint256) {
        return _getUBIrate(tokenId);
    }
    
    function _accumulatedUBI (uint256 tokenId) internal view returns (uint256) {
        uint256 ubirate = _getUBIrate(tokenId);
        uint256 ubiPerSecond = ubirate/365 days;
        return (block.timestamp - lastUBIclaimByID[tokenId])*ubiPerSecond;
    }

    function accumulatedUBI (uint256 tokenId) public view returns (uint256) {
        return _accumulatedUBI(tokenId);
    }

    function _claimUBI (address to, uint256 _tokenId) internal {
        if (citizen.ownerOf(_tokenId) != to) revert NotTheOwner({tokenId: _tokenId, sender: to});
        ubi_token.mint(to, _accumulatedUBI(_tokenId));
        lastUBIclaimByID[_tokenId] = block.timestamp;
    }

    function claimUBI (uint256 _tokenId) public {
        _claimUBI(msg.sender, _tokenId);
    }
    
    constructor() Ownable() {        
        pops[0] = [0,0];
        pops[1] = [0,0];
        pops[2] = [0,0];
        pops[3] = [0];    
       
    }  
}