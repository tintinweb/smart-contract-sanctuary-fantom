// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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
//
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/Interfaces.sol";

contract GrandLineExpedition is VRFConsumerBaseV2, ReentrancyGuard {
    event RequestAddLiquidityToAll(bool status);
    event PirateOnboarded(address tokenAddress, bool status);
    event DeveloperAddressChanged(address newAddress);
    event TreasuryAddressChanged(address newAddress);
    event RemovedLiquidity(address tokenAddress);
    event LiquiditySpended(bool spended);
    event LiquidityAddedToAll(bool spended);
    event DeadTokensClaimed(address owner, address[] deadTokens);
    address chainlinkPirateCoordiator =
        0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
    address link_token_contract = 0x6F43FF82CCA38001B6699a8AC47A2d0E66939407;
    address public uniswapFactoryAddress =
        0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3;
    address public uniswapRouterAddress =
        0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    IUniswapRouter private uniswapV2Router =
        IUniswapRouter(uniswapRouterAddress);
    bytes32 keyRing =
        0xb4797e686f9a1548b9a2e8c68988d74788e0c4af5899020fb0c47784af76ddfa;
    uint32 p_cgl = 2500000;
    uint16 p_rc = 3;
    uint32 p_sw = 1;
    uint256 private p_exec;
    uint256 private p_id;
    uint64 private p_sid;
    uint public constant dropOverboardCooldown = 22 hours;
    uint256 private initialLiquidityAmount = 50_000_000;
    address[] private contractAddresses;
    address[] private deadTokens;
    address private developerAddress;
    mapping(address => bool) private liquidityAddedInTx;
    mapping(address => uint) private lastRemoveLiqCalled;
    bool private tokensLaunched = false;

    constructor() VRFConsumerBaseV2(chainlinkPirateCoordiator) {
        COORDINATOR = VRFCoordinatorV2Interface(chainlinkPirateCoordiator);
        LINKTOKEN = LinkTokenInterface(link_token_contract);
        createNewSubscription();
        developerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == developerAddress);
        _;
    }

    function CrewsAfloat() public view returns (bool status) {
        if (tokensLaunched == true) {
            return status = true;
        }
        status = false;
    }

    function SetSail() public onlyOwner {
        address[] memory tokenAddresses = AllCrewBounties();
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IPirate(tokenAddresses[i]).SetSail();
        }
        tokensLaunched = true;
    }

    function RemoveCrewRules() public onlyOwner {
        address[] memory tokenAddresses = AllCrewBounties();
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            IPirate(tokenAddresses[i]).RemoveCrewRule();
        }
    }

    function RecruitCrew(
        address[] memory _pirateAddresses
    ) public payable onlyOwner {
        for (uint i = 0; i < _pirateAddresses.length; i++) {
            contractAddresses.push(_pirateAddresses[i]);

            emit PirateOnboarded(_pirateAddresses[i], true);
        }
    }

    function FuelTheCrew(
        address tokenAddress,
        uint256 ethAmount
    ) external payable onlyOwner {
        IPirate token = IPirate(tokenAddress);
        token.approve(address(uniswapV2Router), token.balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            initialLiquidityAmount * (10 ** uint256(18)),
            0,
            0,
            address(this),
            block.timestamp + 10 minutes
        );
    }

    function DropCrewMateOverboard() public nonReentrant onlyOwner {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        if (chainId == 1) {
            require(
                block.timestamp - lastRemoveLiqCalled[msg.sender] >=
                    dropOverboardCooldown,
                "Function can be called only after 22 hours"
            );
            lastRemoveLiqCalled[msg.sender] = block.timestamp;
        }

        require(contractAddresses.length > 1, "All pirates are dead");

        address token = getRandomAddress();
        address pair = IUniswapV2Factory(uniswapFactoryAddress).getPair(
            token,
            uniswapV2Router.WETH()
        );

        require(pair != address(0), "Pair does not exist");
        IPirate lpToken = IPirate(pair);
        uint256 liquidity = lpToken.balanceOf(address(this));

        require(liquidity > 0, "Contract has no liquidity to remove");
        lpToken.approve(address(uniswapV2Router), liquidity);

        (uint amountToken, ) = uniswapV2Router.removeLiquidityETH(
            token,
            liquidity,
            0,
            0,
            address(this),
            block.timestamp + 10 minutes
        );

        IPirate(token).transfer(deadAddress, amountToken);

        uint256 tokenIndex;
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            if (contractAddresses[i] == token) {
                tokenIndex = i;
                break;
            }
        }
        if (tokenIndex < contractAddresses.length - 1) {
            contractAddresses[tokenIndex] = contractAddresses[
                contractAddresses.length - 1
            ];
        }

        addLiquidityToAll(token);
        contractAddresses.pop();
        deadTokens.push(address(token));

        emit RemovedLiquidity(token);
    }

    function addLiquidityToAll(address _token) internal {
        for (uint256 i = 0; i < AllCrewBounties().length; i++) {
            liquidityAddedInTx[AllCrewBounties()[i]] = false;
        }

        address[] memory tokenAddresses = AllCrewBounties();
        uint256 contractBalance = address(this).balance;

        uint256 remainingBalance = contractBalance;

        if (tokenAddresses.length > 1) {
            uint256 portionOfEth = remainingBalance /
                (tokenAddresses.length - 1);

            for (uint256 i = 0; i < tokenAddresses.length; i++) {
                address tokenAddress = tokenAddresses[i];
                require(tokenAddress != address(0), "Invalid token address");

                if (
                    tokenAddress == _token || liquidityAddedInTx[tokenAddress]
                ) {
                    continue;
                }

                IPirate token = IPirate(tokenAddress);
                uint256 tokenBalance = token.balanceOf(address(this));

                if (address(this).balance <= 0) {
                    continue;
                }

                uint256 value = portionOfEth <= address(this).balance
                    ? portionOfEth
                    : address(this).balance;

                uint256 tokensOut = getTokensOut(value, tokenAddress);

                if (tokensOut > tokenBalance) {
                    token.claimRewards(address(this), tokensOut - tokenBalance);
                }

                token.approve(address(uniswapV2Router), tokensOut);
                uniswapV2Router.addLiquidityETH{value: value}(
                    tokenAddress,
                    tokensOut,
                    0,
                    0,
                    address(this),
                    block.timestamp + 10 minutes
                );

                liquidityAddedInTx[tokenAddress] = true;

                emit LiquidityAddedToAll(true);
            }
        }

        emit LiquiditySpended(true);
    }

    function ClaimSunkenTreasure() external nonReentrant {
        require(deadTokens.length > 0, "No dead tokens found");
        uint256 totalUserDeadTokenBalance = 0;
        address[] memory claimedTokens = new address[](
            contractAddresses.length
        );
        for (uint256 i = 0; i < deadTokens.length; i++) {
            IPirate deadToken = IPirate(deadTokens[i]);
            uint256 userBalance = deadToken.balanceOf(msg.sender);

            if (userBalance <= 0) {
                continue;
            }

            require(
                deadToken.transferFrom(msg.sender, deadAddress, userBalance),
                "Transfer failed"
            );

            totalUserDeadTokenBalance += userBalance;
        }

        uint256 totalReward = (totalUserDeadTokenBalance * 75) / 100;
        uint256 finalReward = totalReward / contractAddresses.length;
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            IPirate token = IPirate(contractAddresses[i]);
            uint256 contractBalance = token.balanceOf(address(this));

            if (contractBalance >= finalReward) {
                require(
                    token.transfer(msg.sender, finalReward),
                    "Transfer failed"
                );
            } else {
                token.claimRewards(msg.sender, finalReward);
            }
            claimedTokens[i] = address(token);
        }
        emit DeadTokensClaimed(msg.sender, claimedTokens);
    }

    function BootyPerCrew(
        address user
    ) public view returns (uint256 totalClaimable) {
        uint256 totalUserDeadTokenBalance = 0;
        for (uint256 i = 0; i < deadTokens.length; i++) {
            IPirate deadToken = IPirate(deadTokens[i]);
            uint256 userBalance = deadToken.balanceOf(user);

            if (userBalance <= 0) {
                continue;
            }

            totalUserDeadTokenBalance += userBalance;
        }

        uint256 totalReward = (totalUserDeadTokenBalance * 75) / 100;
        uint256 finalReward = totalReward / contractAddresses.length;

        for (uint256 i = 0; i < contractAddresses.length; i++) {
            totalClaimable += finalReward;
        }
    }

    function AllCrewBounties() public view returns (address[] memory) {
        return contractAddresses;
    }

    function FallenCrewMates() public view returns (address[] memory) {
        return deadTokens;
    }

    function CrewMateStatus(address token) public view returns (bool) {
        for (uint256 i = 0; i < deadTokens.length; i++) {
            if (deadTokens[i] == token) {
                return true;
            }
        }
        return false;
    }

    function getRandomAddress() internal view returns (address) {
        address[] memory addresses = AllCrewBounties();
        require(addresses.length > 0, "No addresses found");

        uint256 index = p_exec % addresses.length;
        return addresses[index];
    }

    function getTokensOut(
        uint256 ethAmount,
        address tokenAddress
    ) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = tokenAddress;

        uint256[] memory amounts = uniswapV2Router.getAmountsOut(
            ethAmount,
            path
        );
        return amounts[1];
    }

    function AssignCaptain(
        address payable _developerAddress
    ) public onlyOwner {
        developerAddress = _developerAddress;
        emit DeveloperAddressChanged(_developerAddress);
    }

    function getDeveloperAddress() public view returns (address) {
        return developerAddress;
    }

    function SplitBooty() public onlyOwner {
        p_id = COORDINATOR.requestRandomWords(
            keyRing,
            p_sid,
            p_rc,
            p_cgl,
            p_sw
        );
    }

    function fulfillRandomWords(
        uint256,
        uint256[] memory rdw
    ) internal override {
        p_exec = rdw[0];
        emit RequestAddLiquidityToAll(true);
    }

    function createNewSubscription() private {
        p_sid = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(p_sid, address(this));
    }

    function topUpSubscription() public onlyOwner {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            LINKTOKEN.balanceOf(address(this)),
            abi.encode(p_sid)
        );
    }

    function cancelSubscription(address) external onlyOwner {
        COORDINATOR.cancelSubscription(p_sid, developerAddress);
        p_sid = 0;
    }

    function withdrawLINKtoken() public onlyOwner {
        IPirate token = IPirate(link_token_contract);
        uint256 balance = token.balanceOf(address(this));
        bool success = token.transfer(developerAddress, balance);
        require(success, "Transfer failed");
    }

    function HoistChest() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = developerAddress.call{value: balance}("");
        require(success, "Failed to send Ether");
    }

    function UnearthFinalTreasure(address tokenAddress) public onlyOwner {
        require(
            contractAddresses.length == 1,
            "Only 1 alive contract must be left"
        );
        IPirate lpToken = IPirate(tokenAddress);
        uint256 balance = lpToken.balanceOf(address(this));
        bool success = lpToken.transfer(developerAddress, balance);
        require(success, "Transfer failed");
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IPirate {
    function SetSail() external;

    function RemoveCrewRule() external;

    function claimRewards(address _user, uint256 _amount) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}