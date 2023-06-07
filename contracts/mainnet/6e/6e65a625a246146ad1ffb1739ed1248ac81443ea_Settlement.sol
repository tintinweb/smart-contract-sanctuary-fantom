// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.19;
import "./interfaces/ISettlement.sol";
import "./interfaces/IERC20.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";
import {SigningLib} from "./lib/Signing.sol";
import {OrderLib} from "./lib/Order.sol";

/// @author OpenFlow
/// @title Settlement
/// @dev Settlement is the primary contract for swap execution. The concept is simple.
/// - User approves Settlement to spend fromToken
/// - User submits a request for quotes (RFQ) and solvers submit quotes
/// - User selects the best quote and user creates a signed order for the swap based on the quote
/// - Once an order is signed anyone with the signature and payload can execute the order
/// - The solver whose quote was selected receives the signature and initiates a signed order execution
/// - Order `fromToken` is transferred from the order signer to the order executor (order executor is solver configurable)
/// - Order executor executes the swap in whatever way they see fit
/// - At the end of the swap the user's `toToken` delta must be greater than or equal to the agreed upon `toAmount`
contract Settlement {
    /// @dev Use SafeTransfer for all ERC20 operations
    using SafeTransferLib for ERC20;

    /// @dev Use OrderLib for order UID encoding/decoding
    using OrderLib for bytes;

    /// @dev Prepare constants for building domainSeparator
    bytes32 private constant _DOMAIN_NAME = keccak256("Blockswap");
    bytes32 private constant _DOMAIN_VERSION = keccak256("v0.0.1");
    bytes32 private constant _DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant TYPE_HASH =
        keccak256(
            "Payload(address fromToken,address toToken,uint256 fromAmount,uint256 toAmount,address sender,address recipient,uint256 deadline)"
        );
    bytes32 public immutable domainSeparator;

    /// @dev Map each user order by UID to the amount that has been filled
    mapping(bytes => uint256) public filledAmount;
    mapping(bytes => uint256) public filledTime;

    /// @dev Contracts are allowed to submit pre-swap and post-swap hooks along with their order.
    /// For security purposes all hooks are executed via a simople execution proxy to disallow sending
    /// arbitrary calls directly from the context of Settlement. This is done because Settlement is the
    /// primary contract upon which token allowances will be set.
    ExecutionProxy _executionProxy;

    /// @dev When an order has been executed successfully emit an event
    event OrderExecuted(
        address solver,
        address executor,
        address sender,
        address recipient,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    /// @dev Set domainSeparator and _executionProxy
    constructor() {
        domainSeparator = keccak256(
            abi.encode(
                _DOMAIN_TYPE_HASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                block.chainid,
                address(this)
            )
        );
        _executionProxy = new ExecutionProxy();
    }

    /// @notice Primary method for order execution
    /// @dev TODO: Analyze whether or not this needs to be non-reentrant
    /// @param order The order to execute
    function executeOrder(ISettlement.Order calldata order) public {
        ISettlement.Payload memory payload = order.payload;

        /// @notice Step 1. Verify the integrity of the order
        /// @dev Verifies that payload.sender signed the order
        /// @dev Only the order payload is signed
        /// @dev Once an order is signed anyone who has the signature can fufil the order
        /// @dev In the case of smart contracts sender must implement EIP-1271 isVerified method
        bytes memory orderUid = _verify(order);

        /// @notice Step 2. Execute optional contract preswap hooks
        _execute(order.payload.hooks.preHooks);

        /// @notice Step 3. Optimistically transfer funds from payload.sender to msg.sender (order executor)
        /// @dev Payload.sender must approve settlement
        /// @dev TODO: We probably don't need safe transfer anymore here since we are checking balances now
        ERC20(payload.fromToken).safeTransferFrom(
            payload.sender,
            msg.sender,
            payload.fromAmount
        );
        uint256 outputTokenBalanceBefore = ERC20(payload.toToken).balanceOf(
            payload.recipient
        );

        /// @notice Step 4. Order executor executes the swap and is required to send funds to payload.recipient
        /// @dev Order executors can be completely custom, or the generic order executor can be used
        /// @dev Solver configurable metadata about the order is sent to the order executor hook
        /// @dev Settlement does not care how the solver executes the order, all Settlement cares about is that
        /// the user receives the minimum amount of tokens the signer agreed to
        ISolver(msg.sender).hook(order.data);

        /// @notice Step 5. Execute optional contract postswap hooks
        _execute(order.payload.hooks.postHooks);

        /// @notice Step 6. Make sure payload.recipient receives the agreed upon amount of tokens
        uint256 outputTokenBalanceAfter = ERC20(payload.toToken).balanceOf(
            payload.recipient
        );
        uint256 balanceDelta = outputTokenBalanceAfter -
            outputTokenBalanceBefore;
        require(balanceDelta >= payload.toAmount, "Order not filled");
        filledAmount[orderUid] = balanceDelta;

        /// @dev Emit OrderExecuted
        emit OrderExecuted(
            tx.origin,
            msg.sender,
            payload.sender,
            payload.recipient,
            payload.fromToken,
            payload.toToken,
            payload.fromAmount,
            balanceDelta
        );
    }

    /// @notice Pass hook execution interactions to execution proxy to be executed
    /// @param interactions The interactions to execute
    function _execute(ISettlement.Interaction[] memory interactions) internal {
        if (interactions.length > 0) {
            _executionProxy.execute(interactions);
        }
    }

    /// @notice Order verification
    /// @dev Verify the order
    /// @dev Signature type is auto-detected based on signature's v
    /// see: Gnosis Safe implementationa.
    /// @dev Supports:
    /// - EIP-712 (Structured EOA signatures)
    /// - EIP-1271 (Contract based signatures)
    /// - EthSign (Non-structured EOA signatures)
    /// @param order Complete signed order
    /// @return orderUid New order UID
    function _verify(
        ISettlement.Order calldata order
    ) internal returns (bytes memory orderUid) {
        bytes32 digest = buildDigest(order.payload);
        address signatory = SigningLib.recoverSigner(order.signature, digest);
        orderUid = new bytes(OrderLib._UID_LENGTH);
        orderUid.packOrderUidParams(digest, signatory, order.payload.deadline);
        if (filledTime[orderUid] == 0) {
            filledTime[orderUid] = block.timestamp;
        } else {
            require(block.timestamp == filledTime[orderUid], "Auction is over");
        }
        if (order.payload.toAmount > 0) {
            require(
                order.payload.toAmount > filledAmount[orderUid],
                "Order already filled"
            ); // Allow single block auctions
        }
        require(signatory == order.payload.sender, "Invalid signer");
        require(block.timestamp <= order.payload.deadline, "Deadline expired");
    }

    /// @notice Building the digest hash
    /// @dev Message digest hash consists of type hash, domain separator and type hash
    function buildDigest(
        ISettlement.Payload memory _payload
    ) public view returns (bytes32 orderDigest) {
        bytes32 typeHash = TYPE_HASH;
        bytes32 structHash = keccak256(
            abi.encodePacked(typeHash, abi.encode(_payload))
        );
        orderDigest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
    }
}

/// @title Execution proxy
/// @notice Simple contract used to execute pre-swap and post-swap hooks
contract ExecutionProxy {
    function execute(ISettlement.Interaction[] memory interactions) external {
        for (uint256 i; i < interactions.length; i++) {
            ISettlement.Interaction memory interaction = interactions[i];
            (bool success, ) = interaction.target.call{
                value: interaction.value
            }(interaction.callData);
            require(success, "Interaction failed");
        }
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
        uint256 nonce;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.19;

interface ISignatureValidator {
    function isValidSignature(
        bytes32,
        bytes memory
    ) external view returns (bytes4);

    function signers(address) external view returns (bool);
}

/// @author OpenFlow
/// @title Signing Library
/// @notice Responsible for all OpenFlow signature logic
/// @dev This library is a slightly modified combined version of two battle
/// signing libraries (Gnosis Safe and Cowswap). The intention here is to make an
/// extremely versatile signing lib to handle all major signature types as well as
/// multisig signatures. It handles EIP-712, EIP-1271, EthSign and Gnosis style
/// multisig signature threshold. Multisig signatures can be comprised of any
/// combination of signature types. Signature type is auto-detected (per Gnosis)
/// based on v value.
library SigningLib {
    uint256 private constant _ECDSA_SIGNATURE_LENGTH = 65;
    bytes4 private constant _EIP1271_MAGICVALUE = 0x1626ba7e;

    /// @notice Primary signature check endpoint
    /// @param signature Signature bytes (usually 65 bytes) but in the case of packed
    /// contract signatures actual signature data offset and length may vary
    /// @param digest Hashed payload digest
    /// @return owner Returns authenticated owner
    function recoverSigner(
        bytes memory signature,
        bytes32 digest
    ) public view returns (address owner) {
        /// @dev Extract v from signature
        uint8 v;
        assembly {
            v := and(mload(add(signature, 0x41)), 0xff)
        }
        if (v == 0) {
            /// @dev Contract signature (EIP-1271)
            owner = recoverEip1271Signer(digest, signature);
        } else if (v == 1) {
            /// @dev Presigned (not yet implemented)
            // currentOwner = recoverPresignedOwner(digest, signature);
        } else if (v > 30) {
            /// @dev EthSign signature. If v > 30 then default va (27,28)
            /// has been adjusted for eth_sign flow
            owner = recoverEthsignSigner(digest, signature);
        } else {
            /// @dev EIP-712 signature. Default is the ecrecover flow with the provided data hash
            owner = recoverEip712Signer(digest, signature);
        }
    }

    /// @notice Recover EIP 712 signer
    /// @param digest Hashed payload digest
    /// @param signature Signature bytes
    /// @return owner Signature owner
    function recoverEip712Signer(
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (address owner) {
        owner = ecdsaRecover(digest, signature);
    }

    /// @notice Extract forward and validate signature for EIP-1271
    /// @dev See "Contract Signature" section of https://docs.safe.global/learn/safe-core/safe-core-protocol/signatures
    /// @param digest Hashed payload digest
    /// @param encodedSignature Encoded signature
    /// @return owner Signature owner
    function recoverEip1271Signer(
        bytes32 digest,
        bytes memory encodedSignature
    ) internal view returns (address owner) {
        bytes32 signatureOffset;
        uint256 signatureLength;
        bytes memory signature;
        assembly {
            owner := mload(add(encodedSignature, 0x20))
            signatureOffset := mload(add(encodedSignature, 0x40))
            signatureLength := mload(add(encodedSignature, 0x80))
            mstore(signature, signatureLength)
            calldatacopy(
                add(signature, 0x20),
                add(add(signature, signatureOffset), 0x24), // digest + free memory + 4byte
                signatureLength
            )
        }
        require(
            ISignatureValidator(owner).isValidSignature(digest, signature) ==
                _EIP1271_MAGICVALUE,
            "Invalid EIP-1271 signature"
        );
        return owner;
    }

    /// @notice Eth sign signature
    /// @dev Uses ecdsaRecover with "Ethereum Signed Message" prefixed
    /// @param digest Hashed payload digest
    /// @param signature Signature
    /// @return owner Signature owner
    function recoverEthsignSigner(
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (address owner) {
        bytes32 ethsignDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        owner = ecdsaRecover(ethsignDigest, signature);
    }

    /// @notice Utility for recovering signature using ecrecover
    /// @dev Signature length is expected to be exactly 65 bytes
    /// @param message Signed messed
    /// @param signature Signature
    /// @return signer Returns signer (signature owner)
    function ecdsaRecover(
        bytes32 message,
        bytes memory signature
    ) internal pure returns (address signer) {
        require(
            signature.length == _ECDSA_SIGNATURE_LENGTH,
            "Malformed ECDSA signature"
        );
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := and(mload(add(signature, 0x41)), 0xff)
        }
        signer = ecrecover(message, v, r, s);
        require(signer != address(0), "Invalid ECDSA signature");
    }

    /// @notice Gnosis style signature threshold check
    /// @param signatureManager The address responsible for signer storage
    /// @param digest The digest to check signatures for
    /// @param signatures Packed and encoded multisig signatures payload
    /// @param requiredSignatures Signature threshold. This is required since we are unable
    /// to easily determine the number of signatures from the signature payload alone
    /// @dev Reverts if signature threshold is not passed
    function checkNSignatures(
        address signatureManager,
        bytes32 digest,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        require(signatures.length >= requiredSignatures * 65, "GS020");
        address lastOwner = address(0);
        address currentOwner;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            bytes memory signature;
            // TODO: More checks? Review Gnosis code: https://ftmscan.com/address/d9db270c1b5e3bd161e8c8503c55ceabee709552#code
            assembly {
                // Similar to Gnosis signatureSplit, except splits the entire signature into 65 byte chunks instead of r, s, v
                let signaturePos := add(
                    add(sub(signatures, 28), mul(0x41, i)),
                    0x40
                )
                mstore(signature, 65)
                calldatacopy(add(signature, 0x20), signaturePos, 65)
            }
            currentOwner = recoverSigner(signature, digest);

            require(
                currentOwner > lastOwner,
                "Invalid signature order or duplicate signature"
            );
            require(
                ISignatureValidator(signatureManager).signers(currentOwner),
                "Signer is not approved"
            );
            lastOwner = currentOwner;
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.19;

/// @title Gnosis Protocol v2 Order Library
/// @author Gnosis Developers
library OrderLib {
    /// @dev The byte length of an order unique identifier.
    uint256 internal constant _UID_LENGTH = 56;

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == _UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(
        bytes memory orderUid
    )
        internal
        pure
        returns (bytes32 orderDigest, address owner, uint32 validTo)
    {
        require(orderUid.length == _UID_LENGTH, "GPv2: invalid uid");
        assembly {
            orderDigest := mload(add(orderUid, 32))
            owner := shr(96, mload(add(orderUid, 64)))
            validTo := shr(224, mload(add(orderUid, 84)))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}