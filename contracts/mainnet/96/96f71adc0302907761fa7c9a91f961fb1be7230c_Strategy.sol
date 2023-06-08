// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {IMasterChef} from "../../src/interfaces/IMasterChef.sol";
import {OpenFlowSwapper} from "./OpenFlowSwapper.sol";

contract Strategy is OpenFlowSwapper {
    address public masterChef;
    address public asset; // Underlying want token is DAI
    address public reward; // Reward is USDC
    address public multisigOrderManager;
    address public manager;

    constructor(
        address _asset,
        address _reward,
        address _masterChef,
        address _multisigOrderManager,
        address _settlement
    ) OpenFlowSwapper(_multisigOrderManager, _reward, _asset) {
        asset = _asset;
        reward = _reward;
        masterChef = _masterChef;
        multisigOrderManager = _multisigOrderManager;
        manager = msg.sender;

        // TODO: SafeApprove??
        IERC20(reward).approve(address(_settlement), type(uint256).max);
    }

    function estimatedEarnings() external view returns (uint256) {
        return IMasterChef(masterChef).rewardOwedByAccount(address(this));
    }

    function harvest() external {
        IMasterChef(masterChef).getReward();
        _swap();
    }

    function updateAccounting() public {}

    function sweep(address token) external {
        require(msg.sender == manager);
        IERC20(token).transfer(manager, IERC20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMasterChef {
    function getReward() external;

    function rewardOwedByAccount(address) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {ISettlement} from "../../src/interfaces/ISettlement.sol";
import {IMultisigOrderManager} from "../../src/interfaces/IMultisigOrderManager.sol";
import {IOracle} from "../../src/interfaces/IOracle.sol";
import {IStrategy} from "../../test/interfaces/IStrategy.sol";

/// @author OpenFlow
/// @title OpenFlow Swapper
/// @notice Implements an example of on-chain swap order submission for OpenFlow multisig authenticated auctions
/// @dev Responsible submitting swap orders. Supports EIP-1271 signature validation by delegating signature
/// validation requests to MultisigOrderManager
contract OpenFlowSwapper {
    /// @dev Magic value per EIP-1271 to be returned upon successful validation
    bytes4 private constant _EIP1271_MAGICVALUE = 0x1626ba7e;

    /// @dev Multisig order manager is responsible for signature validation and actual order submission
    address _multisigOrderManager;

    /// @dev Oracle responsible for determining minimum amount out for an order
    address _oracle;

    /// @dev Token to swap from
    address internal _fromToken;

    /// @dev Token to swap to
    address internal _toToken;

    /// @dev Acceptable slippage threshold denoted in BIPs
    uint256 internal _slippageBips;

    /// @dev Maximum duration for auction
    uint256 internal _maxAuctionDuration;

    constructor(
        address multisigOrderManager,
        address fromToken,
        address toToken
    ) {
        _multisigOrderManager = multisigOrderManager;
        _fromToken = fromToken;
        _toToken = toToken;
    }

    /// @notice Only allow strategy manager to configure swap parameters
    modifier onlyManager() {
        require(
            msg.sender == IStrategy(address(this)).manager(),
            "Only the owner can call this function."
        );
        _;
    }

    /// @notice Determine whether or not a signature is valid
    /// @dev In this case we leverage Multisig Order Manager to ensure two things:
    /// - 1. The digest is approved (and not invalidated)
    /// - 2. The swap has been approved by multisig (to ensure best quote was selected)
    /// @param digest The digest of the order payload
    /// @param signatures Encoded EIP-1271 signatures formatted per Gnosis
    function isValidSignature(
        bytes32 digest,
        bytes calldata signatures
    ) external returns (bytes4) {
        IMultisigOrderManager(_multisigOrderManager).checkNSignatures(
            digest,
            signatures
        );
        require(
            IMultisigOrderManager(_multisigOrderManager).digestApproved(digest),
            "Digest not approved"
        );
        return _EIP1271_MAGICVALUE;
    }

    /// @notice Initiate a swap using this contract's complete balance of `fromToken`
    /// @dev Calculates appropriate minimumAmountOut, defines any pre/post swap hooks
    /// and submits the order. Submitting the order will sign the digest in
    /// Multisig Order Management and emit an event, triggering a new auction.
    function _swap() internal {
        // Determine swap amounts
        uint256 fromAmount = IERC20(_fromToken).balanceOf(address(this));
        uint256 minAmountOut = IOracle(_oracle)
            .calculateEquivalentAmountAfterSlippage(
                _fromToken,
                _toToken,
                fromAmount,
                _slippageBips
            );

        // Create optional posthook
        ISettlement.Interaction[] memory preHooks;
        ISettlement.Interaction[]
            memory postHooks = new ISettlement.Interaction[](1);
        postHooks[0] = ISettlement.Interaction({
            target: address(this),
            value: 0,
            callData: abi.encodeWithSignature("updateAccounting()")
        });
        ISettlement.Hooks memory hooks = ISettlement.Hooks({
            preHooks: preHooks,
            postHooks: postHooks
        });

        // Swap
        IMultisigOrderManager(_multisigOrderManager).submitOrder(
            ISettlement.Payload({
                fromToken: address(_fromToken),
                toToken: address(_toToken),
                fromAmount: fromAmount,
                toAmount: minAmountOut,
                sender: address(this),
                recipient: address(this),
                deadline: uint32(block.timestamp + _maxAuctionDuration),
                hooks: hooks
            })
        );
    }

    /// @notice Set auction duration
    /// @param duration (in seconds)
    function setMaxAuctionDuration(uint256 duration) external onlyManager {
        _maxAuctionDuration = duration;
    }

    /// @notice Set slippage
    /// @param slippageBips Amount of allowed slippage
    function setSlippage(uint256 slippageBips) external onlyManager {
        _slippageBips = slippageBips;
    }

    /// @notice Set oracle
    /// @param oracle Oracle address
    function setOracle(address oracle) external onlyManager {
        _oracle = oracle;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISettlement {
    struct Order {
        bytes signature;
        bytes data;
        Payload payload;
    }

    struct Payload {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address sender;
        address recipient;
        uint32 deadline;
        Hooks hooks;
    }

    struct Interaction {
        address target;
        uint256 value;
        bytes callData;
    }

    struct Hooks {
        Interaction[] preHooks;
        Interaction[] postHooks;
    }

    function checkNSignatures(
        address signatureManager,
        bytes32 digest,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function executeOrder(Order memory) external;

    function buildDigest(Payload memory) external view returns (bytes32);

    function nonces(address) external view returns (uint256);

    function recoverSigner(
        bytes memory,
        bytes32
    ) external view returns (address);
}

interface ISolver {
    function hook(bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {ISettlement} from "./ISettlement.sol";

interface IMultisigOrderManager {
    function checkNSignatures(bytes32 digest, bytes memory signature) external;

    function digestApproved(bytes32 digest) external view returns (bool);

    function submitOrder(ISettlement.Payload memory payload) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IOracle {
    function calculateEquivalentAmountAfterSlippage(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        uint256 _slippageBips
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IStrategy {
    function manager() external view returns (address);
}