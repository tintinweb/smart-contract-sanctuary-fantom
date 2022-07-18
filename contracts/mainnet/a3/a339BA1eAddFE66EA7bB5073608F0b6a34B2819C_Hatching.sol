/**
 *Submitted for verification at FtmScan.com on 2022-07-18
*/

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}


// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// File: hatch/Hatching.sol


pragma solidity ^0.8.7;



struct Original {
    uint256 from;
    uint32 generation;
    uint256 emergingTS;
    uint32 value;
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function hatched(uint256) external view returns (bool);

    function setReadyToHatch(uint256 tokenId, uint32 index) external;

    function getReadyToHatch(uint256) external view returns (uint32);

    function monsterOriginal(uint256) external view returns (Original memory);

    function claim(
        uint256 tokenId,
        string memory monster,
        uint32 crv,
        uint32 type_,
        uint32 size,
        uint32 hp,
        uint32[6] memory abilities
    ) external;
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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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
        return computedHash;
    }
}

contract Hatching is VRFConsumerBaseV2 {
    address public immutable monster2;

    uint256 constant DAYs = 7 days;

    uint256 private _flag;

    uint32[33] private _weights1 = [
        19,
        38,
        58,
        78,
        96,
        116,
        155,
        531,
        1176,
        1105,
        1171,
        832,
        1000,
        847,
        689,
        543,
        418,
        316,
        234,
        171,
        123,
        87,
        61,
        43,
        30,
        21,
        14,
        10,
        7,
        5,
        3,
        2,
        1
    ];
    uint32[33] private _weights2 = [
        0,
        0,
        0,
        0,
        0,
        0,
        90,
        120,
        440,
        970,
        910,
        970,
        690,
        830,
        700,
        570,
        450,
        345,
        260,
        190,
        140,
        100,
        70,
        50,
        36,
        25,
        17,
        11,
        8,
        6,
        4,
        3,
        2
    ];
    uint32[33] private _weights3 = [
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        690,
        648,
        689,
        490,
        588,
        498,
        405,
        319,
        246,
        185,
        137,
        100,
        72,
        51,
        37,
        26,
        18,
        12,
        9,
        7,
        5,
        4,
        3
    ];
    uint32 private constant _total1 = 10000;
    uint32 private constant _total2 = 8007;
    uint32 private constant _total3 = 5239;

    mapping(uint32 => uint32[2]) private _crIndexMap;

    bytes32 public merkleRoot;

    uint32[20] private _randoms = [
        7,
        11,
        13,
        14,
        19,
        21,
        22,
        25,
        26,
        28,
        35,
        37,
        38,
        41,
        42,
        44,
        49,
        50,
        52,
        56
    ];

    mapping(uint256 => uint32[33]) public eggIdToWeights;
    mapping(uint256 => uint32) public eggIdToTotal;

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    address vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    bytes32 keyHash =
        0xb4797e686f9a1548b9a2e8c68988d74788e0c4af5899020fb0c47784af76ddfa;
    uint32 callbackGasLimit = 300000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;
    mapping(uint256 => uint256[]) public s_requestIdToRandomWords;
    mapping(uint256 => uint256) public s_eggeIdToRequestId;
    mapping(uint256 => uint256) public s_requestIdToEggId;
    uint256 public s_requestId;

    event Readied(address sender, uint256 indexed tokenId, uint256 requestId);
    event Hatched(
        uint256 indexed tokenId,
        uint32 index,
        string monster,
        uint32 crv,
        uint32 type_,
        uint32 size
    );

    constructor(
        address monster2_,
        bytes32 merkleRoot_,
        uint64 subscriptionid_
    ) VRFConsumerBaseV2(vrfCoordinator) {
        monster2 = monster2_;

        _flag = uint256(blockhash(block.number - 1));

        merkleRoot = merkleRoot_;

        _crIndexMap[1] = [1, 2];
        _crIndexMap[2] = [3, 4];
        _crIndexMap[3] = [5, 8];
        _crIndexMap[4] = [9, 16];
        _crIndexMap[5] = [17, 23];
        _crIndexMap[6] = [24, 53];
        _crIndexMap[7] = [54, 98];
        _crIndexMap[8] = [99, 149];
        _crIndexMap[9] = [150, 221];
        _crIndexMap[10] = [222, 261];
        _crIndexMap[11] = [262, 312];
        _crIndexMap[12] = [313, 338];
        _crIndexMap[13] = [339, 383];
        _crIndexMap[14] = [384, 414];
        _crIndexMap[15] = [415, 445];
        _crIndexMap[16] = [446, 464];
        _crIndexMap[17] = [465, 488];
        _crIndexMap[18] = [489, 500];
        _crIndexMap[19] = [501, 512];
        _crIndexMap[20] = [513, 524];
        _crIndexMap[21] = [525, 532];
        _crIndexMap[22] = [533, 543];
        _crIndexMap[23] = [544, 550];
        _crIndexMap[24] = [551, 558];
        _crIndexMap[25] = [559, 568];
        _crIndexMap[26] = [569, 577];
        _crIndexMap[27] = [578, 590];
        _crIndexMap[28] = [591, 599];
        _crIndexMap[29] = [600, 610];
        _crIndexMap[30] = [611, 618];
        _crIndexMap[31] = [619, 629];
        _crIndexMap[32] = [630, 636];
        _crIndexMap[33] = [637, 640];

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionid_;
    }

    function hatchable(uint256 tokenId) public view returns (bool) {
        Original memory ori = IERC721(monster2).monsterOriginal(tokenId);
        if (block.timestamp - ori.emergingTS > DAYs) {
            return true;
        }

        return false;
    }

    function _getCRV(uint32 rand, uint32[33] memory weights)
        private
        pure
        returns (uint32 crv)
    {
        for (uint32 i = 0; i < 33; i++) {
            if (rand <= weights[i]) {
                return i + 1;
            }
            rand -= weights[i];
        }
    }

    function _isContract(address addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function ready(uint256 tokenId) external {
        require(hatchable(tokenId), "It's not time to hatch");

        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");

        require(s_eggeIdToRequestId[tokenId] == 0, "Can't re-ready");

        uint256 requestId;

        if (_isContract(msg.sender)) {
            revert();
        } else {
            requestId = COORDINATOR.requestRandomWords(
                keyHash,
                s_subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                numWords
            );
            s_eggeIdToRequestId[tokenId] = requestId;
            s_requestIdToEggId[requestId] = tokenId;
        }

        Original memory ori = IERC721(monster2).monsterOriginal(tokenId);
        uint32 value = ori.value;
        if (value <= 18) {
            eggIdToWeights[tokenId] = _weights1;
            eggIdToTotal[tokenId] = _total1;
        } else if (value <= 24 && value >= 19) {
            eggIdToWeights[tokenId] = _weights2;
            eggIdToTotal[tokenId] = _total2;
        } else if (value >= 25) {
            eggIdToWeights[tokenId] = _weights3;
            eggIdToTotal[tokenId] = _total3;
        }

        emit Readied(msg.sender, tokenId, requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        s_requestIdToRandomWords[requestId] = randomWords;
        uint256 tokenId = s_requestIdToEggId[requestId];

        uint256 rand = (randomWords[0] % eggIdToTotal[tokenId]) + 1;
        uint32 crv = _getCRV(uint32(rand), eggIdToWeights[tokenId]);

        uint32[2] memory crIndex = _crIndexMap[crv];
        uint32 range = crIndex[1] - crIndex[0] + 1;

        _flag++;
        uint256 rand2 = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), _flag))
        ) % range;

        IERC721(monster2).setReadyToHatch(tokenId, crIndex[0] + uint32(rand2));
    }

    function hatch(
        uint256 tokenId,
        uint32 index_,
        string memory monster,
        uint32 crv,
        uint32 type_,
        uint32 size,
        uint32 hp,
        uint32[6] memory abilities,
        bytes32[] calldata _merkleProof
    ) external {
        uint32 index = IERC721(monster2).getReadyToHatch(tokenId);
        require(index > 0, "Not ready");
        require(index == index_, "Not the right Monster");
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");

        bytes32 node = keccak256(
            abi.encodePacked(
                index_,
                monster,
                crv,
                type_,
                size,
                hp,
                abilities[0],
                abilities[1],
                abilities[2],
                abilities[3],
                abilities[4],
                abilities[5]
            )
        );

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        if (_isContract(msg.sender)) {
            revert();
        }

        _flag++;
        uint256 rand2 = (uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), _flag))
        ) % 8) + 1;
        hp += uint32(rand2);

        _flag++;
        rand2 =
            uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), _flag))
            ) %
            20;
        uint32 random = _randoms[rand2];

        _flag++;
        rand2 =
            (uint256(
                keccak256(abi.encodePacked(blockhash(block.number - 1), _flag))
            ) % 6) +
            1;
        if (random & 1 == 1) {
            abilities[0] += uint32(rand2);
        } else if (random & 2 == 2) {
            abilities[1] += uint32(rand2);
        } else if (random & 4 == 4) {
            abilities[2] += uint32(rand2);
        } else if (random & 8 == 8) {
            abilities[3] += uint32(rand2);
        } else if (random & 16 == 16) {
            abilities[4] += uint32(rand2);
        } else if (random & 32 == 32) {
            abilities[5] += uint32(rand2);
        }

        IERC721(monster2).claim(
            tokenId,
            monster,
            crv,
            type_,
            size,
            hp,
            abilities
        );

        emit Hatched(tokenId, index, monster, crv, type_, size);
    }

    function _isApprovedOrOwner(address operator, uint256 tokenId)
        private
        view
        returns (bool)
    {
        address TokenOwner = IERC721(monster2).ownerOf(tokenId);
        return (operator == TokenOwner ||
            IERC721(monster2).getApproved(tokenId) == operator ||
            IERC721(monster2).isApprovedForAll(TokenOwner, operator));
    }
}