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
}

contract RaidRewards is Ownable, ReentrancyGuard {
    IRaidersNFT public raidersNFT;

    address nftAddress;
    mapping(uint256 => address) public gameAddress;

    mapping(uint256 => uint256) public claimedBasic;
    mapping(uint256 => uint256) public claimedWinnings;
    mapping(uint256 => uint256) public claimedLoot;

    mapping(address => uint256) public addressRewards;
    mapping(address => uint256) public addressClaimed;

    constructor() {
        nftAddress = 0x65c4f2619BFE75215459d7e1f351833E7511290C;
        raidersNFT = IRaidersNFT(nftAddress);

        gameAddress[0] = 0xE19c6cE655B150839A2f78Fd6C0F0AbE6Ce500Bd;
        gameAddress[1] = 0x40Ff57b80CfD8878162D3B26C3a66Fde33D5a568;
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
            claim(tokenID, _gameRound);
        }
    }

    function claimMultiple(uint256[] calldata _raiderIDs, uint256 _gameRound)
        public
        nonReentrant
    {
        for (uint256 i = 0; i < _raiderIDs.length; i++) {
            uint256 tokenID = _raiderIDs[i];
            claim(tokenID, _gameRound);
        }
    }

    function claimSolo(uint256 _raiderID, uint256 _gameRound)
        public
        nonReentrant
    {
        claim(_raiderID, _gameRound);
    }

    function claim(uint256 _raiderID, uint256 _gameRound) internal {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);
        require(
            raidersNFT.isOwner(msg.sender, _raiderID),
            "You are not the owner."
        );

        uint256 basicRewards = game.rewards(_raiderID);
        uint256 winnings = game.raiderWinnings(_raiderID);
        uint256 gold = game.getRaiderLoot(_raiderID);

        uint256 claimableBasic = basicRewards - claimedBasic[_raiderID];
        uint256 claimableWinnings = winnings - claimedWinnings[_raiderID];
        uint256 claimableGold = gold - claimedLoot[_raiderID];

        claimedBasic[_raiderID] += claimableBasic;
        claimedBasic[_raiderID] += claimableWinnings;
        claimedLoot[_raiderID] += claimableGold;

        uint256 transferrableRewards = claimableBasic +
            claimableWinnings +
            claimableGold;
        addressRewards[msg.sender] += transferrableRewards;
    }

    function getBasicRewards(uint256 _raiderID, uint256 _gameRound)
        public
        view
        returns (uint256)
    {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);

        uint256 totalRewards = game.rewards(_raiderID);
        return totalRewards;
    }

    function getWinnings(uint256 _raiderID, uint256 _gameRound)
        public
        view
        returns (uint256)
    {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);

        uint256 totalWinnings = game.raiderWinnings(_raiderID);
        return totalWinnings;
    }

    function getGold(uint256 _raiderID, uint256 _gameRound)
        public
        view
        returns (uint256)
    {
        GameContract game;
        game = GameContract(gameAddress[_gameRound]);

        uint256 totalLoot = game.getRaiderLoot(_raiderID);
        return totalLoot;
    }

    function getClaimableBasic(uint256 _raiderID, uint256 _gameRound)
        public
        view
        returns (uint256)
    {
        uint256 basicRewards = getBasicRewards(_raiderID, _gameRound);
        uint256 claimable = basicRewards - claimedBasic[_raiderID];
        return claimable;
    }

    function getClaimableWinnings(uint256 _raiderID, uint256 _gameRound)
        public
        view
        returns (uint256)
    {
        uint256 winnings = getWinnings(_raiderID, _gameRound);
        uint256 claimable = winnings - claimedWinnings[_raiderID];
        return claimable;
    }

    function getClaimableGold(uint256 _raiderID, uint256 _gameRound)
        public
        view
        returns (uint256)
    {
        uint256 gold = getGold(_raiderID, _gameRound);
        uint256 claimable = gold - claimedLoot[_raiderID];
        return claimable;
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