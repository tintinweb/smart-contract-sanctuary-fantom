pragma solidity ^0.8.17;

import "./UseRandom.sol";
import "../interfaces/IReliquary.sol";

contract Gym is UseRandom {

    IReliquary public reliquary;
    mapping(uint => uint) seeds;

    constructor(IReliquary _reliquary) {
        reliquary = _reliquary;
    }

    /// @notice Assign same random seed to each Relic. May be called no more than once per day per Relic
    /// @param relicIds Array of relicIds belonging to msg.sender (may or may not be all of them)
    /// @return seed The seed used to generate a provably random number via VDF
    function createSeed(uint[] calldata relicIds) external returns (uint seed) {
        seed = _createSeed();

        for (uint i; i < relicIds.length;) {
            require(reliquary.isApprovedOrOwner(msg.sender, relicIds[i]), "not authorized");
            PositionInfo memory position = reliquary.getPositionForId(relicIds[i]);
            require(
                block.timestamp - position.genesis >= 1 days &&
                (position.lastMaturityBonus == 0 || block.timestamp - position.lastMaturityBonus >= 1 days),
                "too soon since last bonus"
            );

            seeds[relicIds[i]] = seed;
            reliquary.updateLastMaturityBonus(relicIds[i]);
            unchecked {++i;}
        }
    }

    /// @notice Apply the maturity bonus derived from the seed assigned by createSeed function
    /// @param relicIds Array of relicIds which all have the same seed
    /// @param proof The provably random number derived from the VDF.
    ///        Used as number of seconds by which to reduce position's entry time.
    function train(uint[] calldata relicIds, uint proof) external {
        uint seed = seeds[relicIds[0]];
        require(seed != 0, "no seed");
        _prove(proof, seed);

        uint n = proof % 1 days;

        _train(relicIds[0], n);
        for (uint i = 1; i < relicIds.length;) {
            require(seeds[relicIds[i]] == seed, "Relic seed mismatch");
            _train(relicIds[i], n);
            unchecked {++i;}
        }
    }

    /// @notice Internal function which allows to apply effects to first relicId without redundant seed mismatch check
    /// @param relicId The NFT ID of the Relic being trained
    /// @param rand The provably random number derived from the VDF
    function _train(uint relicId, uint rand) internal {
        delete seeds[relicId];
        reliquary.modifyMaturity(relicId, rand);
    }
}

pragma solidity ^0.8.17;

import "../libraries/SlothVDF.sol";

abstract contract UseRandom {
    // large prime
    uint public constant PRIME = 432211379112113246928842014508850435796007;
    // adjust for block finality
    uint public constant ITERATIONS = 1000;
    // increment nonce to increase entropy
    uint private nonce;

    function _createSeed() internal returns (uint seed) {
        // commit funds/tokens/etc before running this function

        // create a pseudo random seed as the input
        seed = uint(keccak256(abi.encodePacked(msg.sender, ++nonce, block.timestamp, blockhash(block.number - 1))));
    }

    function _prove(uint proof, uint seed) internal pure {
        // see if the proof is valid for the seed associated with the address
        require(SlothVDF.verify(proof, seed, PRIME, ITERATIONS), 'Invalid proof');

        // use the proof as a provable random number
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IEmissionCurve {
    function getRate(uint lastRewardTime) external view returns (uint rate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface INFTDescriptor {
    function constructTokenURI(uint relicId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IEmissionCurve.sol";
import "./INFTDescriptor.sol";
import "./IRewarder.sol";

/*
 + @notice Info for each Reliquary position.
 + `amount` LP token amount the position owner has provided
 + `rewardDebt` Amount of reward token accumalated before the position's entry or last harvest
 + `rewardCredit` Amount of reward token owed to the user on next harvest
 + `entry` Used to determine the maturity of the position
 + `poolId` ID of the pool to which this position belongs
 + `level` Index of this position's level within the pool's array of levels
 + `genesis` Relic creation time
 + `lastMaturityBonus` Last time the position had its entry altered by a MaturityModifier
*/
struct PositionInfo {
    uint amount;
    uint rewardDebt;
    uint rewardCredit;
    uint entry; // position owner's relative entry into the pool.
    uint poolId; // ensures that a single Relic is only used for one pool.
    uint level;
    uint genesis;
    uint lastMaturityBonus;
}

/*
 + @notice Info of each Reliquary pool
 + `accRewardPerShare` Accumulated reward tokens per share of pool (1 / 1e12)
 + `lastRewardTime` Last timestamp the accumulated reward was updated
 + `allocPoint` Pool's individual allocation - ratio of the total allocation
 + `name` Name of pool to be displayed in NFT image
*/
struct PoolInfo {
    uint accRewardPerShare;
    uint lastRewardTime;
    uint allocPoint;
    string name;
}

/*
 + @notice Level that determines how maturity is rewarded
 + `requiredMaturity` The minimum maturity (in seconds) required to reach this Level
 + `allocPoint` Level's individual allocation - ratio of the total allocation
 + `balance` Total number of tokens deposited in positions at this Level
*/
struct LevelInfo {
    uint[] requiredMaturity;
    uint[] allocPoint;
    uint[] balance;
}

/*
 + @notice Object representing pending rewards and related data for a position.
 + `relicId` The NFT ID of the given position.
 + `poolId` ID of the pool to which this position belongs.
 + `pendingReward` pending reward amount for a given position.
*/
struct PendingReward {
    uint relicId;
    uint poolId;
    uint pendingReward;
}

interface IReliquary is IERC721Enumerable {

  function burn(uint tokenId) external;
  function setEmissionCurve(IEmissionCurve _emissionCurve) external;
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function addPool(
        uint allocPoint,
        IERC20 _poolToken,
        IRewarder _rewarder,
        uint[] calldata requiredMaturity,
        uint[] calldata allocPoints,
        string memory name,
        INFTDescriptor _nftDescriptor
    ) external;
  function modifyPool(
        uint pid,
        uint allocPoint,
        IRewarder _rewarder,
        string calldata name,
        INFTDescriptor _nftDescriptor,
        bool overwriteRewarder
    ) external;
  function modifyMaturity(uint relicId, uint points) external returns (uint receivedBonus);
  function updateLastMaturityBonus(uint relicId) external;
  function pendingReward(uint relicId) external view returns (uint pending);
  function relicPositionsOfOwner(
      address owner
    ) external view returns (uint[] memory relicIds, PositionInfo[] memory positionInfos);
  function levelOnUpdate(uint relicId) external view returns (uint level);
  function massUpdatePools(uint[] calldata pids) external;
  function updatePool(uint pid) external;
  function createRelicAndDeposit(
        address to,
        uint pid,
        uint amount
    ) external returns (uint id);
  function deposit(uint amount, uint relicId) external;
  function withdraw(uint amount, uint relicId) external;
  function harvest(uint relicId, address harvestTo) external;
  function withdrawAndHarvest(uint amount, uint relicId, address harvestTo) external;
  function emergencyWithdraw(uint relicId) external;
  function updatePosition(uint relicId) external;
  function split(uint relicId, uint amount, address to) external returns (uint newId);
  function shift(uint fromId, uint toId, uint amount) external;
  function merge(uint fromId, uint toId) external;

  // State

  function rewardToken() external view returns (IERC20);
  function nftDescriptor(uint) external view returns (INFTDescriptor);
  function emissionCurve() external view returns (IEmissionCurve);
  function getPoolInfo(uint) external view returns (PoolInfo memory);
  function getLevelInfo(uint) external view returns (LevelInfo memory);
  function poolToken(uint) external view returns (IERC20);
  function rewarder(uint) external view returns (IRewarder);

  function getPositionForId(uint) external view returns (PositionInfo memory);
  function totalAllocPoint() external view returns (uint);
  function poolLength() external view returns (uint);
  function isApprovedOrOwner(address, uint) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IRewarder {
    function onReward(
        uint relicId,
        uint rewardAmount,
        address to
    ) external;

    function onDeposit(
        uint relicId,
        uint depositAmount
    ) external;

    function onWithdraw(
        uint relicId,
        uint withdrawalAmount
    ) external;

    function pendingTokens(
        uint relicId,
        uint rewardAmount
    ) external view returns (IERC20[] memory, uint[] memory);
}

// SPDX-License-Identifier: MIT
// https://eprint.iacr.org/2015/366.pdf

pragma solidity ^0.8.11;

library SlothVDF {

    /// @dev pow(base, exponent, modulus)
    /// @param base base
    /// @param exponent exponent
    /// @param modulus modulus
    function bexmod(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 _result = 1;
        uint256 _base = base;
        for (; exponent > 0; exponent >>= 1) {
            if (exponent & 1 == 1) {
                _result = mulmod(_result, _base, modulus);
            }

            _base = mulmod(_base, _base, modulus);
        }
        return _result;
    }

    /// @dev compute sloth starting from seed, over prime, for iterations
    /// @param _seed seed
    /// @param _prime prime
    /// @param _iterations number of iterations
    /// @return sloth result
    function compute(
        uint256 _seed,
        uint256 _prime,
        uint256 _iterations
    ) internal pure returns (uint256) {
        uint256 _exponent = (_prime + 1) >> 2;
        _seed %= _prime;
        for (uint256 i; i < _iterations; ++i) {
            _seed = bexmod(_seed, _exponent, _prime);
        }
        return _seed;
    }

    /// @dev verify sloth result proof, starting from seed, over prime, for iterations
    /// @param _proof result
    /// @param _seed seed
    /// @param _prime prime
    /// @param _iterations number of iterations
    /// @return true if y is a quadratic residue modulo p
    function verify(
        uint256 _proof,
        uint256 _seed,
        uint256 _prime,
        uint256 _iterations
    ) internal pure returns (bool) {
        unchecked {
            for (uint256 i; i < _iterations; ++i) {
                _proof = mulmod(_proof, _proof, _prime);
            }
            _seed %= _prime;
            if (_seed == _proof) return true;
            if (_prime - _seed == _proof) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}