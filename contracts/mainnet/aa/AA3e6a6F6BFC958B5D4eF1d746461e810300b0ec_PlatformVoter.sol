// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== Platform Voter ===================
// ==============================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Mmd: https://github.com/mmd-mostafaee

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/Ive.sol";
import "./interfaces/IPlatformVoter.sol";
import "./interfaces/IBaseV1Voter.sol";
import "./interfaces/IVault.sol";

/// @title PlatformVoter of veNFTs (veSOLID)
/// @author DEUS Finance
/// @notice to vote with veNFTs locked in Vault
contract PlatformVoter is IPlatformVoter, Ownable {
    address[] public poolVote;
    int256[] public weights;

    int256 public voteShare; // voter's share of votes e.g. 10 for 10% of users vote

    mapping(address => bool) public userVoteLock;

    address public baseV1Voter;

    constructor(address baseV1Voter_, int256 voteShare_) {
        baseV1Voter = baseV1Voter_;
        voteShare = voteShare_;
    }

    function setVotes(address[] memory poolVote_, int256[] memory weights_)
        public
        onlyOwner
        returns (bool)
    {
        address[] memory localPoolVote = new address[](poolVote_.length);
        int256[] memory localWeights = new int256[](poolVote_.length);

        for (uint256 i = 0; i < poolVote_.length; i++) {
            localPoolVote[i] = poolVote_[i];
            localWeights[i] = weights_[i];
        }

        poolVote = localPoolVote;
        weights = localWeights;

        return true;
    }

    function setVoteShare(int256 voteShare_) public onlyOwner returns (bool) {
        voteShare = voteShare_;
        return true;
    }

    function voteFor(
        address vault,
        uint256[] memory tokenIds,
        address[] memory _poolVote,
        int256[] memory _weights
    ) public onlyOwner {
        IVault(vault).voteFor(tokenIds, _poolVote, _weights);
    }

    function setVoteLock(address user, bool lock) external returns (bool) {
        userVoteLock[user] = lock;
        return true;
    }

    function getVotes(
        address[] memory userPoolVote,
        int256[] memory userWeights
    )
        public
        view
        returns (address[] memory poolVote_, int256[] memory weights_)
    {
        int256 totalVoteWeight = 0;
        uint256 i;
        for (i = 0; i < userPoolVote.length; i++) {
            totalVoteWeight += userWeights[i] > 0
                ? userWeights[i]
                : -userWeights[i];
        }

        int256 platformTotalWeight = 0;
        for (i = 0; i < weights.length; i++) {
            platformTotalWeight += weights[i] > 0 ? weights[i] : -weights[i];
        }

        int256 platformWeightShare = (totalVoteWeight * voteShare) /
            (100 - voteShare);

        int256[] memory platformWeights = new int256[](weights.length);
        for (i = 0; i < weights.length; i++) {
            platformWeights[i] =
                (platformWeightShare * weights[i]) /
                platformTotalWeight;
        }

        uint256 length = userPoolVote.length + poolVote.length;

        poolVote_ = new address[](length);
        weights_ = new int256[](length);

        i = 0;
        for (; i < userPoolVote.length; i++) {
            poolVote_[i] = userPoolVote[i];
            weights_[i] = userWeights[i];
        }

        for (uint256 j = 0; j < poolVote.length; j++) {
            poolVote_[i] = poolVote[j];
            weights_[i] = platformWeights[j];
            i++;
        }
    }

    function getDefaultVotes(uint256 tokenId, uint256 poolVotesLength)
        external
        view
        returns (address[] memory poolVote_, int256[] memory weights_)
    {
        address[] memory currentPoolVote = new address[](poolVotesLength);
        int256[] memory currentWeights = new int256[](poolVotesLength);

        uint256 i;
        for (i = 0; i < poolVotesLength; i++) {
            address poolAddress = IBaseV1Voter(baseV1Voter).poolVote(
                tokenId,
                i
            );
            currentPoolVote[i] = poolAddress;
            currentWeights[i] = IBaseV1Voter(baseV1Voter).votes(
                tokenId,
                poolAddress
            );
        }

        return getVotes(currentPoolVote, currentWeights);
    }

    function canVote(address user) external view returns (bool) {
        return !userVoteLock[user];
    }
}

//Dar panah khoda

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface Ive {
    function increase_amount(uint256 tokenID, uint256 value) external;

    function increase_unlock_time(uint256 tokenID, uint256 duration) external;

    function merge(uint256 fromID, uint256 toID) external;

    function locked(uint256 tokenID)
        external
        view
        returns (uint256 amount, uint256 unlockTime);

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOfNFT(uint256 tokenId) external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256);

    function create_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IPlatformVoter {
    function getVotes(
        address[] memory userPoolVote,
        int256[] memory userWeights
    ) external returns (address[] memory poolVote_, int256[] memory weights_);

    function getDefaultVotes(uint256 tokenId, uint256 poolVotesLength)
        external
        returns (address[] memory poolVote_, int256[] memory weights_);

    function canVote(address user) external returns (bool);
}
//Dar panah khoda

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.12;

interface IBaseV1Voter {
    // address public immutable _ve; // the ve token that governs these contracts
    // address public immutable factory; // the BaseV1Factory
    // address public immutable gaugefactory;
    // address public immutable bribefactory;
    // address public minter;

    // uint public totalWeight; // total voting weight

    // address[] public pools; // all pools viable for incentives
    // mapping(address => address) public gauges; // pool => gauge
    // mapping(address => address) public poolForGauge; // gauge => pool
    // mapping(address => address) public bribes; // gauge => bribe
    // mapping(address => int256) public weights; // pool => weight
    function votes(uint256 nft, address pool) external view returns (int256); // nft => pool => votes

    function poolVote(uint256 nft, uint256 index) external view returns (address); // nft => pools

    // mapping(uint => uint) public usedWeights;  // nft => total voting weight of user
    // mapping(address => bool) public isGauge;
    // mapping(address => bool) public isWhitelisted;

    function initialize(address[] memory _tokens, address _minter) external;

    function listing_fee() external view returns (uint256);

    function reset(uint256 _tokenId) external;

    function poke(uint256 _tokenId) external;

    function vote(
        uint256 tokenId,
        address[] calldata _poolVote,
        int256[] calldata _weights
    ) external;

    function whitelist(address _token, uint256 _tokenId) external;

    function createGauge(address _pool) external returns (address);

    function attachTokenToGauge(uint256 tokenId, address account) external;

    function emitDeposit(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external;

    function detachTokenFromGauge(uint256 tokenId, address account) external;

    function emitWithdraw(
        uint256 tokenId,
        address account,
        uint256 amount
    ) external;

    function length() external view returns (uint256);

    // mapping(address => uint) external claimable;

    function notifyRewardAmount(uint256 amount) external;

    function updateFor(address[] memory _gauges) external;

    function updateForRange(uint256 start, uint256 end) external;

    function updateAll() external;

    function updateGauge(address _gauge) external;

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external;

    function claimBribes(
        address[] memory _bribes,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external;

    function claimFees(
        address[] memory _fees,
        address[][] memory _tokens,
        uint256 _tokenId
    ) external;

    function distributeFees(address[] memory _gauges) external;

    function distribute(address _gauge) external;

    function distro() external;

    function distribute() external;

    function distribute(uint256 start, uint256 finish) external;

    function distribute(address[] memory _gauges) external;
}
//Dar panah khoda

// SPDX-License-Identifier: GPL-3.0-or-later

interface IVault {
    function votingEscrow() external returns (address);
    function token() external returns (address);
    function baseV1Voter() external returns (address);
    function platformVoter() external returns (address);
    function lender() external returns (address);
    function ownerToId(address owner) external returns (uint256 id);
    function isFree(uint256 id) external returns (bool);
    function VE_LENDER_ROLE() external returns (bytes32);
    function PLATFORM_VOTER_ROLE() external returns (bytes32);
    function MANAGER_ROLE() external returns (bytes32);
    function setPlatformVoter(address platformVoter_) external;
    function setLender(address lender_) external;
    function lockFor(uint256 tokenId, uint256 poolVoteLength) external returns (uint256);
    function unlockFor(address user, uint256 amount, address to) external;
    function buyFor(uint256 tokenId, address user) external returns (uint256);
    function sellFor(address user, uint256 tokenId) external returns (uint256);
    function liquidate(address user) external;
    function vote(address[] memory _poolVote, int256[] memory _weights) external;
    function voteFor( uint256[] memory tokenIds, address[] memory _poolVote, int256[] memory _weights ) external;
    function getCollateralAmount(uint256 tokenId) external view returns (uint256);
    function getTokenId(address user) external view returns (uint256);
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