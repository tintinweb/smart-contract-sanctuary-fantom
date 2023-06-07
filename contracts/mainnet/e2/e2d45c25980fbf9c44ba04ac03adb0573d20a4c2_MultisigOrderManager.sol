// SPDX-License-Identifier: BUSL 1.1

pragma solidity ^0.8.19;
import {IERC20} from "../src/interfaces/IERC20.sol";
import {ISettlement} from "../src/interfaces/ISettlement.sol";
import {SigningLib} from "../src/lib/Signing.sol";
import {OrderLib} from "../src/lib/Order.sol";

/// @author OpenFlow
/// @title Multisig Order Manager
/// @notice This contract manages the signing logic for OpenFlow multisig authenticated swap auctions
contract MultisigOrderManager {
    /// @dev OrderLib is used to generate and decode unique UIDs per order.
    /// A UID consists of digest hash, owner and deadline.
    using OrderLib for bytes;

    /// @dev Settlement contract is used to build a digest hash given a payload.
    address public immutable settlement;

    /// @dev Owner is responsible for signer management (adding/removing signers
    /// and maintaining signature threshold).
    address public owner;

    /// @dev In order for a multisig authenticated order to be executed the order
    /// must be signed by `signatureThreshold` trusted parties. This ensures that the
    /// optimal quote has been selected for a given auction. The main trust component here in multisig
    /// authenticated auctions is that the user is trusting the multisig to only sign quotes that will return
    /// the highest swap value to the end user.
    uint256 public signatureThreshold;

    /// @dev Signers is mapping of authenticated multisig signers.
    mapping(address => bool) public signers;

    /// @dev approvedHashes[owner][nonce][hash]
    /// Allows a user to validate and invalidate an order.
    mapping(address => mapping(uint256 => mapping(bytes32 => bool)))
        public approvedHashes;

    /// @dev All orders for a user can be invalidated by incrementing the user's session nonce.
    mapping(address => uint256) public sessionNonceByAddress;

    /// @dev Event emitted when an order is submitted. This event is used off-chain to detect new orders.
    /// When a SubmitOrder event is fired, multisig auction authenticators (signers) will request new quotes from all
    /// solvers, and when the auction period is up, multisig will sign the best quote. The signature will be relayed to
    /// the solver who submitted the quote. When the solver has enough multisig signatures, the solver can construct
    /// the multisig signature (see: https://docs.safe.global/learn/safe-core/safe-core-protocol/signatures) and
    /// execute the order.
    event SubmitOrder(ISettlement.Payload payload, bytes orderUid);

    /// @dev Event emitted when an order is invalidated. Only users who submit an order can invalidate the order.
    /// When an order is invalidated it is no longer able to be executed.
    event InvalidateOrder(bytes orderUid);

    /// @dev Event emitted to indicate a user has invalidated all of their orders. This is accomplished by the
    /// user incrementing their session nonce.
    event InvalidateAllOrders(address account);

    constructor(address _settlement) {
        settlement = _settlement; // Initialize settlement
        owner = msg.sender; // Initialize owner
    }

    /// @notice Submit an order
    /// @dev Given an order payload, build and approve the digest hash, and then emit an event
    /// that indicates an auction is ready to begin.
    /// @param payload The payload to sign
    /// @return orderUid Returns unique order UID
    function submitOrder(
        ISettlement.Payload memory payload
    ) external returns (bytes memory orderUid) {
        bytes32 digest = ISettlement(settlement).buildDigest(payload);
        uint256 sessionNonce = sessionNonceByAddress[msg.sender];
        approvedHashes[msg.sender][sessionNonce][digest] = true;
        orderUid = new bytes(OrderLib._UID_LENGTH);
        orderUid.packOrderUidParams(digest, msg.sender, payload.deadline);
        emit SubmitOrder(payload, orderUid);
    }

    /// @notice Invalidate an order
    /// @dev Only the user who initiated the order can invalidate the order
    /// @param orderUid The order UID to invalidate
    function invalidateOrder(bytes memory orderUid) external {
        (bytes32 digest, address ownerOwner, ) = orderUid
            .extractOrderUidParams();
        uint256 sessionNonce = sessionNonceByAddress[msg.sender];
        approvedHashes[msg.sender][sessionNonce][digest] = false;
        require(msg.sender == ownerOwner, "Only owner of order can invalidate");
        emit InvalidateOrder(orderUid);
    }

    /// @notice Invalidate all orders for a user
    /// @dev Accomplished by incrementing the user's session nonce
    function invalidateAllOrders() external {
        sessionNonceByAddress[msg.sender]++;
        emit InvalidateAllOrders(msg.sender);
    }

    /// @notice Determine whether or not a user has approved an order digest for the current session
    /// @param digest The order digest to check
    /// @return approved True if approved, false if not
    function digestApproved(
        bytes32 digest
    ) external view returns (bool approved) {
        uint256 sessionNonce = sessionNonceByAddress[msg.sender];
        approved = approvedHashes[msg.sender][sessionNonce][digest];
    }

    /// @notice Given a digest and encoded signatures, determine if a digest is approved by a
    /// sufficient number of multisig signers.
    /// @dev Reverts if not approved
    function checkNSignatures(
        bytes32 digest,
        bytes memory signatures
    ) external view {
        SigningLib.checkNSignatures(
            address(this),
            digest,
            signatures,
            signatureThreshold
        );
    }

    /// @notice Add or remove trusted multisig signers
    /// @dev Only owner is allowed to perform this action
    /// @param _signers An array of signer addresses
    /// @param _status If true, all signers in the array will be approved.
    /// If false all signers in the array will be unapproved.
    function setSigners(address[] memory _signers, bool _status) external {
        require(msg.sender == owner, "Only owner");
        for (uint256 signerIdx; signerIdx < _signers.length; signerIdx++) {
            signers[_signers[signerIdx]] = _status;
        }
    }

    /// @notice Set signature threshold
    /// @dev Only owner is allowed to perform this action
    function setSignatureThreshold(uint256 _signatureThreshold) external {
        require(msg.sender == owner, "Only owner");
        signatureThreshold = _signatureThreshold;
    }

    /// @notice Select a new owner
    /// @dev Only owner is allowed to perform this action
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Only owner");
        owner = _owner;
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

// SPDX-License-Identifier: BUSL 1.1
pragma solidity 0.8.19;
import {ISignatureValidator} from "../interfaces/ISignatureValidator.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISignatureValidator {
    function isValidSignature(
        bytes32,
        bytes memory
    ) external view returns (bytes4);

    function signers(address) external view returns (bool);
}