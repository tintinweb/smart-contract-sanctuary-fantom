/**
 *Submitted for verification at FtmScan.com on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}


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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}


contract CompensationForMineSeason2 {

    address public immutable monsterReborn;
    uint public immutable amount;
    bytes32 public merkleRoot;
    mapping(uint => bool) public claimed; 
    address public assetBox;

    constructor(address monsterReborn_, uint amount_, bytes32 merkleRoot_, address assetBox_) {
        monsterReborn = monsterReborn_;
        amount = amount_;
        merkleRoot = merkleRoot_;
        assetBox = assetBox_;
    }

    function claim(uint index, uint tokenId, bytes32[] calldata _merkleProof) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved');
        require(!claimed[index], "Claimed");

        claimed[index] = true;

        bytes32 node = keccak256(abi.encodePacked(index, tokenId));

        require(MerkleProof.verify(_merkleProof, merkleRoot, node), 'Invalid proof');

        IAssetBox(assetBox).mint(3, tokenId, amount);
    }

    function _isApprovedOrOwner(address operator, uint256 tokenId) private view returns (bool) {
        address TokenOwner = IERC721(monsterReborn).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(monsterReborn).getApproved(tokenId) == operator || IERC721(monsterReborn).isApprovedForAll(TokenOwner, operator));
    }
}