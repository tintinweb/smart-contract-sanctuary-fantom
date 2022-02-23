// Contracts/RaidRewards.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IRaidersNFT {
    function getFaction(uint256 _raiderID) external view returns (uint256);

    function isOwner(address _owner, uint256 _raiderID)
        external
        view
        returns (bool);

    function balanceOf(address owner) external view returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

interface GameContract {
    function rewards(uint256 _raiderID) external view returns (uint256);

    function getClaimableRewards(uint256 _raiderID)
        external
        view
        returns (uint256);

    function raiderWinnings(uint256 _raiderID) external view returns (uint256);

    function getRaiderLoot(uint256 _raiderID) external view returns (uint256);

    function timeGameEnded() external view returns (uint256);
}

contract RaidRewards is Ownable, ReentrancyGuard {
    IRaidersNFT public raidersNFT;

    address nftAddress;
    mapping(uint256 => address) public gameAddress;

    mapping(uint256 => mapping(uint256 => uint256)) private claimedBasic; //round => id => value
    mapping(uint256 => mapping(uint256 => uint256)) private claimedWinnings;
    mapping(uint256 => mapping(uint256 => uint256)) private claimedLoot;

    mapping(uint256 => mapping(address => uint256)) private addressRewards;

    event Claimed(uint256 _gameRound, uint256 _raiderID, address _owner, uint256 _basicRewards, uint256 _winnings, uint256 _gold, uint256 _totalAmount);

    constructor() {
        nftAddress = 0x65c4f2619BFE75215459d7e1f351833E7511290C;
        raidersNFT = IRaidersNFT(nftAddress);

        gameAddress[0] = 0xE19c6cE655B150839A2f78Fd6C0F0AbE6Ce500Bd;
        gameAddress[1] = 0x40Ff57b80CfD8878162D3B26C3a66Fde33D5a568;
        gameAddress[2] = 0x8BF0f2E30A609B3AaD3d6aa422e9799E5F49538D;
    }

    function setNftContract(address _nftContract) public onlyOwner {
        nftAddress = _nftContract;
        raidersNFT = IRaidersNFT(nftAddress);
    }

    function setGameAddress(uint256 _gameRound, address _gameAddress)
        public
        onlyOwner
    {
        gameAddress[_gameRound] = _gameAddress;
    }

    function claimAll(uint256 _gameRound) public nonReentrant {
        uint256 ownedTokens = raidersNFT.balanceOf(msg.sender);
        for (uint256 i = 0; i < ownedTokens; i++) {
            uint256 tokenID = raidersNFT.tokenOfOwnerByIndex(msg.sender, i);
            claim(_gameRound, tokenID);
        }
    }

    function claimMultiple(uint256[] calldata _raiderIDs, uint256 _gameRound)
        public
        nonReentrant
    {
        for (uint256 i = 0; i < _raiderIDs.length; i++) {
            uint256 tokenID = _raiderIDs[i];
            claim(_gameRound, tokenID);
        }
    }

    function claimSolo(uint256 _gameRound, uint256 _raiderID)
        public
        nonReentrant
    {
        claim(_gameRound, _raiderID);
    }

    function claim(uint256 _gameRound, uint256 _raiderID) internal {
        uint256 timeGameEnded = getTimeGameEnded(_gameRound);
        uint256 transferrableRewards;

        require(
            raidersNFT.isOwner(msg.sender, _raiderID),
            "You are not the owner."
        );

        uint256 claimableBasic = getClaimableBasic(_gameRound, _raiderID);
        uint256 claimableWinnings = getClaimableWinnings(_gameRound, _raiderID);
        uint256 claimableGold = getClaimableGold(_gameRound, _raiderID);
		
        if (block.timestamp >= timeGameEnded){
            transferrableRewards = claimableBasic +
            claimableWinnings +
            claimableGold;
        }else{
            transferrableRewards = claimableBasic;
        }
		
		if(transferrableRewards > 0){
			if(claimableBasic > 0){
				claimedBasic[_gameRound][_raiderID] += claimableBasic;
			}
			if(claimableWinnings > 0) {
				claimedWinnings[_gameRound][_raiderID] += claimableWinnings;
			}
			if(claimableGold > 0) {
				claimedLoot[_gameRound][_raiderID] += claimableGold;
			}
			
			addressRewards[_gameRound][msg.sender] += transferrableRewards;
		}
        emit Claimed(_gameRound, _raiderID, msg.sender, claimableBasic, claimableWinnings, claimableGold, transferrableRewards);
    }

    ////PUBLIC FUNCTIONS FETCHING FROM THE GAME CONTRACTS

    function getTimeGameEnded(uint256 _gameRound) public view returns (uint256){
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);
        
        uint256 timeGameEnded = game.timeGameEnded();
        return timeGameEnded;
    }

    function getBasicRewards(uint256 _gameRound, uint256 _raiderID)
        public
        view
        returns (uint256)
    {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);

        uint256 totalRewards = game.rewards(_raiderID);
        return totalRewards;
    }

    function getWinnings(uint256 _gameRound, uint256 _raiderID)
        public
        view
        returns (uint256)
    {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);

        uint256 totalWinnings = game.raiderWinnings(_raiderID);
        return totalWinnings;
    }

    function getGold(uint256 _gameRound, uint256 _raiderID)
        public
        view
        returns (uint256)
    {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);

        uint256 totalLoot = game.getRaiderLoot(_raiderID);
        return totalLoot;
    }

    //PUBLIC FUNCTIONS CALCULATING NET CLAIMABLE REWARDS/WINNINGS/GOLD
    function getClaimableBasic(uint256 _gameRound, uint256 _raiderID)
        public
        view
        returns (uint256)
    {
        uint256 basicRewards = getBasicRewards(_gameRound, _raiderID);
        uint256 claimable = basicRewards - claimedBasic[_gameRound][_raiderID];
        return claimable;
    }

    function getClaimableWinnings(uint256 _gameRound, uint256 _raiderID)
        public
        view
        returns (uint256)
    {
        uint256 winnings = getWinnings(_gameRound, _raiderID);
        uint256 claimable = winnings - claimedWinnings[_gameRound][_raiderID];
        return claimable;
    }

    function getClaimableGold(uint256 _gameRound, uint256 _raiderID)
        public
        view
        returns (uint256)
    {
        uint256 gold = getGold(_gameRound, _raiderID);
        uint256 claimable = gold - claimedLoot[_gameRound][_raiderID];
        return claimable;
    }

    //PUBLIC FUNCTIONS FOR RETURNING CLAIMED REWARDS/WINNINGS/GOLD
    function getClaimedBasic(uint256 _gameRound, uint256 _raiderID) public view returns (uint256){
        return claimedBasic[_gameRound][_raiderID];
    }

    function getClaimedWinnings(uint256 _gameRound, uint256 _raiderID) public view returns (uint256){
        return claimedWinnings[_gameRound][_raiderID];
    }

    function getClaimedGold(uint256 _gameRound, uint256 _raiderID) public view returns (uint256){
        return claimedLoot[_gameRound][_raiderID];
    }

    function getTotalClaimed(uint256 _gameRound, uint256 _raiderID) public view returns (uint256){
        uint256 basic = getClaimedBasic(_gameRound, _raiderID);
        uint256 winnings = getClaimedWinnings(_gameRound, _raiderID);
        uint256 gold = getClaimedGold(_gameRound, _raiderID);
        uint256 total = basic + winnings + gold;
        return total;

    }
	
	function getEarningsOfAddress(uint256 _gameRound, address _address) public view returns (uint256){
		uint256 earnings = addressRewards[_gameRound][_address];
		return earnings;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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