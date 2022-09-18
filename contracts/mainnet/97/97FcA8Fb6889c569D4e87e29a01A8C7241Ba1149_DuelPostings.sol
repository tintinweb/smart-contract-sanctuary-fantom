//DuelPostings.sol
//SPDX-License-Identifier: MIT
//Author: @Sgt
//Will serve as the contract to hold all the states relating to duel postings/challenges in the Duel Platform

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/DuelPostsLibrary.sol";

interface NFTContract {
    function isOwner(address _owner, uint256 _nftID)
        external
        view
        returns (bool);
}

interface StakingContract {
    function totalStaked(address _payee) external view returns (uint256);
    function lockedStake(address _payee) external view returns (uint256);
    function lockStake(address _payee, uint256 _amount) external returns (bool);
    function unlockStake(address _payee, uint256 _amount) external returns (bool);
    function addStake(address payee, uint256 amount) external returns (bool success);
    function writeOffStake(address payee, uint256 amount) external returns (bool success);
}

contract DuelPostings is Ownable {
    NFTContract public nftContract;
    StakingContract public stakingContract;
    address public nftAddress;
    address public stakingAddress;
    address public duelsAddress;

    bool public paused;
    uint64 public currentPostID;
    mapping(uint256 => DuelPostsLibrary.duelPost) public idToDuelPost;

    event PostCreated(DuelPostsLibrary.duelPost postDetails);
    event PostCancelled(DuelPostsLibrary.duelPost postDetails);
    event PostUpdated(DuelPostsLibrary.duelPost postDetails);

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        nftContract = NFTContract(nftAddress);
        paused = false;
    }

    function setNftContract(address _nftAddress) public onlyOwner {
        nftAddress = _nftAddress;
        nftContract = NFTContract(nftAddress);
    }

    function setStakingContract(address _stakingAddress) public onlyOwner {
        stakingAddress = _stakingAddress;
        stakingContract = StakingContract(stakingAddress);
    }

    function setDuelsAddress(address _duelsAddress) public onlyOwner {
        duelsAddress = _duelsAddress;
    }

    function pause() public onlyOwner {
        paused = !paused;
    }

    function createPost(uint256 _character_id, uint256 _initial_prize) public {
        require (!paused, "Contract: Posting for duels is currently paused!");
        require(
            nftContract.isOwner(msg.sender, _character_id),
            "Contract: Not your character nft."
        );
        bool success = stakingContract.lockStake(msg.sender, _initial_prize);
        require(success, "Contract: Failed to lock stake for this posting. Please check if the input amounts are correct.");
        currentPostID++;
        idToDuelPost[currentPostID] = DuelPostsLibrary.duelPost({
            defender: uint64(_character_id),
            status: 1,
            streak: 1,
            prize: _initial_prize,
            owner: msg.sender
        });
        emit PostCreated(idToDuelPost[currentPostID]);
    }

    function cancelPost(uint256 _postID) public {
        DuelPostsLibrary.duelPost memory post = idToDuelPost[_postID];
        require(post.status == 1, "Contract: The post has already been cancelled.");
        require(post.owner == msg.sender, "Contract: The post's owner is not the caller.");
        idToDuelPost[_postID].status = 0;
        bool success = stakingContract.unlockStake(msg.sender, post.prize);
        require(success, "Contract: Failed to cancel the duel post.");
        emit PostCancelled(idToDuelPost[_postID]);
    }

    function cancelPostsMultiple(uint256[] memory posts) public {
        for(uint i = 0; i < posts.length; i++){
            cancelPost(posts[i]);
        }
    }

    function applyDuelResult(uint256 _postID, uint256 _result, address _challenger) public onlyDuelsContract{
        DuelPostsLibrary.duelPost memory post = idToDuelPost[_postID];
        if(_result == 0){
            stakingContract.writeOffStake(_challenger, post.prize);
            stakingContract.addStake(post.owner, (post.prize * 900 / 1000));
            stakingContract.lockStake(post.owner, (post.prize * 500) / 1000); //lock 40% of the additional stake to the winner owner
            idToDuelPost[_postID].prize += (post.prize * 500) / 1000;
            stakingContract.addStake(address(0), (post.prize * 100) / 1000); //burn 10% of challenger's stake
            idToDuelPost[_postID].streak += 1; //adds a streak that is used to compute bonus for the defender's attack and special attack
            emit PostUpdated(idToDuelPost[_postID]);
        }
        if(_result == 1){
            idToDuelPost[_postID].status = 0;
            stakingContract.writeOffStake(post.owner, post.prize);
            stakingContract.unlockStake(post.owner, post.prize);
            stakingContract.addStake(_challenger, (post.prize * 950 / 1000));
            stakingContract.addStake(address(0), (post.prize * 50 / 1000)); //burn 5% of prize pool
            emit PostUpdated(idToDuelPost[_postID]);
        }
        if(_result == 2){
            stakingContract.writeOffStake(_challenger, (post.prize * 10) / 1000);
            stakingContract.addStake(address(0), (post.prize * 10) / 1000); //burn 5% of prize pool
        }
    }

    modifier onlyDuelsContract() {
        require(msg.sender == duelsAddress, "Contract: caller is not the duels contract.");
        _;
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//DuelPostsLibrary.sol
//SPDX-License-Identifier: MIT
//Author: @Sgt
pragma solidity ^0.8.7;

library DuelPostsLibrary {
    struct duelPost {
        uint64 defender;
        uint64 status;
        uint64 streak;
        uint256 prize;
        address owner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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