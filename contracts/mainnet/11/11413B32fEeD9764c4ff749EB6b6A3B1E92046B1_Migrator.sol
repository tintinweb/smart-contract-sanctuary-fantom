pragma solidity 0.8.4;

import "@openzeppelin/contracts-v4.7.3/access/Ownable.sol";
import "./libraries/MerkleProof.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/INFT.sol";

/**
 * @title vDEUS Migrator
 * @author DEUS Finance
 * @dev Uses merkle tree to claim ERC20 token
 */
contract Migrator is Ownable {
    bytes32 public merkleRoot;
    address public oracle;
    address public nft;
    address public token;
    uint256 public edgePrice = 250 * 1e6;

    constructor(
        address oracle_,
        address nft_,
        address token_
    ) {
        oracle = oracle_;
        nft = nft_;
        token = token_;
    }

    event Claim(
        address indexed claimant,
        uint256 tokenId,
        uint256 amount,
        uint256 mintAmount
    );
    event MerkleRootChanged(bytes32 merkleRoot);
    event EdgePriceChanged(uint256 oldEdgePrice, uint256 newEdgePrice);

    /**
     * @dev Claims tokens.
     * @param tokenId Id of vdeus nft.
     * @param amount The amount of the claim being made.
     * @param merkleProof A merkle proof proving that claim is valid.
     */
    function claim(
        uint256 tokenId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(
            INFT(nft).ownerOf(tokenId) == msg.sender,
            "Migrator: NOT_OWNED"
        );
        bytes32 leaf = keccak256(abi.encodePacked(tokenId, amount));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        require(valid, "Migrator: INVALID_PROOF");

        uint256 deusPrice = IOracle(oracle).getPrice();

        if (deusPrice < edgePrice) {
            deusPrice = edgePrice;
        }

        uint256 mintAmount = (amount * 1e6) / deusPrice;

        // INFT(nft).burn(tokenId);
        // IERC20(token).mint(msg.sender, mintAmount);

        emit Claim(msg.sender, tokenId, amount, mintAmount);
    }

    /**
     * @dev Claims tokens.
     * @param tokenIds Array of vdeus nft ids.
     * @param amounts Array of the amounts of the claims being made.
     * @param merkleProofs Array of merkle proofs proving that claims are valid.
     */
    function claimMany(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes32[][] calldata merkleProofs
    ) external {
        require(
            tokenIds.length == amounts.length &&
                amounts.length == merkleProofs.length,
            "Migrator: INVALID_LENGTH"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            claim(tokenIds[i], amounts[i], merkleProofs[i]);
        }
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _merkleRoot The merkle root to set.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }

    /**
     * @dev Sets the merkle root. Only callable if the root is not yet set.
     * @param _edgePrice New edge price
     */
    function setEdgePrice(uint256 _edgePrice) external onlyOwner {
        emit EdgePriceChanged(edgePrice, _edgePrice);
        edgePrice = _edgePrice;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

interface IOracle {
    function getPrice() external view returns (uint256 price);
}

interface IERC20 {
    function mint(address to, uint256 amount) external;
}

interface INFT {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
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