// Be name Khoda
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== DEUS Synchronizer ===================
// ==========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISynchronizer.sol";
import "./interfaces/IMintHelper.sol";
import "./interfaces/IRegistrar.sol";
import "./interfaces/IPartnerManager.sol";

/// @title Synchronizer
/// @author DEUS Finance
/// @notice DEUS router for trading Registrar contracts
contract Synchronizer is ISynchronizer, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    uint32 public appId; // Muon's app Id
    string public version = "v1.2.0";
    address public muonContract; // Address of Muon verifier contract
    address public deiContract = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3; // address of DEI token
    address public mintHelper; // Address of mint helper contract
    address public partnerManager; // Address of partner manager contract
    uint256 public minimumRequiredSignatures; // Minimum number of signatures required
    uint256 public scale = 1e18; // Used for math
    uint256 public expireTime; // Valid time of muon signatures
    uint256 public delayTimestamp; // Time to wait before being able to collect()
    mapping(address => int256) public cap; // partnerId => openPositionsVolume
    mapping(address => uint256) public lastTrade; // Address => last trade timestamp
    mapping(address => uint256[]) public feeCollector; // partnerId => cumulativeFee
    mapping(address => address[]) public tokens; // Address => list of collectibale tokens
    mapping(address => mapping(address => uint256)) public balance; // Balance of collectible tokens

    constructor(
        address mintHelper_,
        address muonContract_,
        address partnerManager_,
        uint256 minimumRequiredSignatures_,
        uint256 expireTime_,
        uint256 delayTimestamp_,
        uint32 appId_
    ) ReentrancyGuard() {
        mintHelper = mintHelper_;
        muonContract = muonContract_;
        partnerManager = partnerManager_;
        minimumRequiredSignatures = minimumRequiredSignatures_;
        expireTime = expireTime_;
        delayTimestamp = delayTimestamp_;
        appId = appId_;
    }

    /// @notice utility function used for generating trade signatures
    /// @return id chainId
    function getChainId() public view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /// @notice Calculate the fee percentage of registrar type for a specific partner
    /// @param partnerId address of partner
    /// @param registrar Registrar token address
    /// @return fee percentage (scale is 1e18)
    function getTotalFee(address partnerId, address registrar) public view returns (uint256 fee) {
        uint256 partnerFee = IPartnerManager(partnerManager).partnerFee(
            partnerId,
            IRegistrar(registrar).registrarType()
        );
        uint256 platformFee = IPartnerManager(partnerManager).minPlatformFee(IRegistrar(registrar).registrarType());
        uint256 minTotalFee = IPartnerManager(partnerManager).minTotalFee(IRegistrar(registrar).registrarType());
        if (partnerFee + platformFee <= minTotalFee) {
            fee = minTotalFee;
        } else {
            fee = partnerFee + platformFee;
        }
    }

    /// @notice utility function for frontends
    /// @param partnerId address of partner
    /// @param amountOut amountOut to be received
    /// @param registrar Registrar token address
    /// @param price Registrar price
    /// @param action 0 is sell & 1 is buy
    /// @return amountIn required to receive the desired amountOut
    function getAmountIn(
        address partnerId,
        address registrar,
        uint256 amountOut,
        uint256 price,
        uint256 action
    ) public view returns (uint256 amountIn) {
        uint256 fee = getTotalFee(partnerId, registrar);
        if (action == 0) {
            // sell Registrar
            amountIn = (amountOut * price) / (scale - fee); // x = y * (price) * (1 / 1 - fee)
        } else {
            // buy Registrar
            amountIn = (amountOut * scale * scale) / (price * (scale - fee)); // x = y * / (price * (1 - fee))
        }
    }

    /// @notice utility function for frontends
    /// @param amountIn exact amount user wants to spend
    /// @param partnerId address of partner
    /// @param registrar Registrar token address
    /// @param price Registrar price
    /// @param action 0 is sell & 1 is buy
    /// @return amountOut to be received
    function getAmountOut(
        address partnerId,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 action
    ) public view returns (uint256 amountOut) {
        uint256 fee = getTotalFee(partnerId, registrar);
        if (action == 0) {
            // sell Registrar
            uint256 collateralAmount = (amountIn * price) / scale;
            uint256 feeAmount = (collateralAmount * fee) / scale;
            amountOut = collateralAmount - feeAmount;
        } else {
            // buy Registrar
            uint256 feeAmount = (amountIn * fee) / scale;
            uint256 collateralAmount = amountIn - feeAmount;
            amountOut = (collateralAmount * scale) / price;
        }
    }

    /// @notice buy a Registrar
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerId partner address
    /// @param recipient recipient of the Registrar
    /// @param registrar Registrar token address
    /// @param amountIn DEI amount to spend (18 decimals)
    /// @param price registrar price according to Muon
    /// @param timestamp timestamp for signatures expiration
    /// @param _reqId Muon request id
    /// @param sigs Muon TSS signatures
    function buyFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 timestamp,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external nonReentrant returns (uint256 registrarAmount) {
        require(amountIn > 0, "Synchronizer: INSUFFICIENT_INPUT_AMOUNT");
        require(IPartnerManager(partnerManager).isPartner(partnerId), "Synchronizer: INVALID_PARTNER_ID");
        require(sigs.length >= minimumRequiredSignatures, "Synchronizer: INSUFFICIENT_SIGNATURES");
        require(timestamp + expireTime > block.timestamp, "Synchronizer: EXPIRED_SIGNATURE");
        require(int256(amountIn) > 0, "Synchronizer: INVALID_AMOUNTIN");
        require(
            int256(amountIn) + cap[partnerId] <= IPartnerManager(partnerManager).maxCap(partnerId),
            "Synchronizer: MAX_CAP"
        );

        {
            bytes32 hash = keccak256(abi.encodePacked(appId, registrar, price, uint256(1), getChainId(), timestamp));

            IMuonV02 muon = IMuonV02(muonContract);
            require(muon.verify(_reqId, uint256(hash), sigs), "Synchronizer: UNVERIFIED_SIGNATURES");
        }

        uint256 feeAmount = (amountIn * getTotalFee(partnerId, registrar)) / scale;
        uint256 collateralAmount = amountIn - feeAmount;

        feeCollector[partnerId][IRegistrar(registrar).registrarType()] += feeAmount;

        IMintHelper(mintHelper).burnFrom(msg.sender, amountIn);

        cap[partnerId] += int256(amountIn);

        registrarAmount = (collateralAmount * scale) / price;

        IRegistrar(registrar).mint(address(this), registrarAmount);

        {
            lastTrade[recipient] = block.timestamp;
            balance[recipient][registrar] += registrarAmount;
            tokens[recipient].push(registrar);
        }

        emit Buy(partnerId, recipient, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice sell a Registrar
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerId partner address
    /// @param recipient recipient of the collateral
    /// @param registrar Registrar token address
    /// @param amountIn registrar amount to spend (18 decimals)
    /// @param price registrar price according to Muon
    /// @param timestamp timestamp for signatures expiration
    /// @param _reqId Muon request id
    /// @param sigs Muon TSS signatures
    function sellFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 timestamp,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external nonReentrant returns (uint256 deiAmount) {
        require(amountIn > 0, "Synchronizer: INSUFFICIENT_INPUT_AMOUNT");
        require(IPartnerManager(partnerManager).isPartner(partnerId), "Synchronizer: INVALID_PARTNER_ID");
        require(sigs.length >= minimumRequiredSignatures, "Synchronizer: INSUFFICIENT_SIGNATURES");
        require(timestamp + expireTime > block.timestamp, "Synchronizer: EXPIRED_SIGNATURE");

        {
            bytes32 hash = keccak256(abi.encodePacked(appId, registrar, price, uint256(0), getChainId(), timestamp));

            IMuonV02 muon = IMuonV02(muonContract);
            require(muon.verify(_reqId, uint256(hash), sigs), "Synchronizer: UNVERIFIED_SIGNATURES");
        }
        uint256 collateralAmount = (amountIn * price) / scale;

        require(int256(collateralAmount) > 0, "Synchronizer: INVALID_COLLATERAL_AMOUNT");

        uint256 feeAmount = (collateralAmount * getTotalFee(partnerId, registrar)) / scale;

        feeCollector[partnerId][IRegistrar(registrar).registrarType()] += feeAmount;

        IRegistrar(registrar).burn(msg.sender, amountIn);

        deiAmount = collateralAmount - feeAmount;
        IMintHelper(mintHelper).mint(address(this), deiAmount);

        {
            lastTrade[recipient] = block.timestamp;
            balance[recipient][deiContract] += deiAmount;
            tokens[recipient].push(deiContract);
        }

        cap[partnerId] -= int256(collateralAmount);

        emit Sell(partnerId, recipient, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice collects the tokens
    /// @param recipient recipient of the tokens
    function collect(address recipient) external nonReentrant {
        require(lastTrade[msg.sender] + delayTimestamp < block.timestamp, "Synchronizer: WAITING_TIME");

        uint256 cnt = tokens[msg.sender].length;

        for (uint256 i = 0; i < cnt; i++) {
            address token = tokens[msg.sender][i];
            uint256 amount = balance[msg.sender][token];
            if (amount > 0) {
                balance[msg.sender][token] = 0;
                IERC20(token).transfer(recipient, amount);
            }
        }
        delete tokens[msg.sender];
    }

    /// @notice withdraw accumulated trading fee
    /// @dev fee will be minted in DEI
    /// @param recipient receiver of fee
    /// @param registrarType type of registrar
    function withdrawFee(address recipient, uint256 registrarType) external nonReentrant {
        require(feeCollector[msg.sender][registrarType] > 0, "Synchronizer: INSUFFICIENT_FEE");

        uint256 partnerFee = IPartnerManager(partnerManager).partnerFee(msg.sender, registrarType);

        uint256 partnerFeeAmount = (feeCollector[msg.sender][registrarType] * partnerFee) / scale;
        uint256 platformFeeAmount = feeCollector[msg.sender][registrarType] - partnerFeeAmount;

        IMintHelper(mintHelper).mint(recipient, partnerFeeAmount);
        IMintHelper(mintHelper).mint(IPartnerManager(partnerManager).platformFeeCollector(), platformFeeAmount);

        feeCollector[msg.sender][registrarType] = 0;

        emit WithdrawFee(msg.sender, partnerFeeAmount, platformFeeAmount, registrarType);
    }

    /// @notice changes the minimum required signatures for trading
    /// @param minimumRequiredSignatures_ number of required signatures
    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_) external onlyOwner {
        emit SetMinimumRequiredSignatures(minimumRequiredSignatures, minimumRequiredSignatures_);
        minimumRequiredSignatures = minimumRequiredSignatures_;
    }

    /// @notice changes Muon's app id
    /// @dev appIdd distinguishes us from other Muon apps
    /// @param appId_ Muon's app id
    function setAppId(uint32 appId_) external onlyOwner {
        emit SetAppId(appId, appId_);
        appId = appId_;
    }

    /// @notice changes Muon's verifier contract
    /// @param muonContract_ address of muon contract
    function setMuonContract(address muonContract_) external onlyOwner {
        emit SetMuonContract(muonContract, muonContract_);
        muonContract = muonContract_;
    }

    /// @notice changes expire time
    /// @param expireTime_ new exipre time
    function setExpireTime(uint256 expireTime_) external onlyOwner {
        emit SetExpireTime(expireTime, expireTime_);
        expireTime = expireTime_;
    }

    function setDelayTimestamp(uint256 delayTimestamp_) external onlyOwner {
        emit SetDelayTimestamp(delayTimestamp, delayTimestamp_);
        delayTimestamp = delayTimestamp_;
    }
}

//Dar panah khoda

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

    constructor () {
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

pragma solidity ^0.8.11;

import "./IMuonV02.sol";

interface ISynchronizer {
    event Buy(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 collateralAmount,
        uint256 feeAmount
    );
    event Sell(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 collateralAmount,
        uint256 feeAmount
    );
    event WithdrawFee(address partner, uint256 partnerFee, uint256 platformFee, uint256 registrarType);
    event SetMinimumRequiredSignatures(uint256 oldValue, uint256 newValue);
    event SetAppId(uint32 oldId, uint32 newId);
    event SetVirtualReserve(uint256 oldReserve, uint256 newReserve);
    event SetMuonContract(address oldContract, address newContract);
    event ToggleUseVirtualReserve(bool useVirtualReserve);
    event SetExpireTime(uint256 oldExpireTime, uint256 newExpireTime);
    event SetDelayTimestamp(uint256 oldDelayTimestamp, uint256 newDelayTimestamp);

    function version() external view returns (string memory);

    function mintHelper() external view returns (address);

    function muonContract() external view returns (address);

    function deiContract() external view returns (address);

    function partnerManager() external view returns (address);

    function minimumRequiredSignatures() external view returns (uint256);

    function scale() external view returns (uint256);

    function delayTimestamp() external view returns (uint256);

    function expireTime() external view returns (uint256);

    function feeCollector(address partner, uint256 registrarType) external view returns (uint256);

    function tokens(address partner, uint256 registrarType) external view returns (address);

    function balance(address user, address registrar) external view returns (uint256);

    function cap(address partner) external view returns (int256);

    function lastTrade(address partner) external view returns (uint256);

    function appId() external view returns (uint32);

    function getChainId() external view returns (uint256);

    function getAmountIn(
        address partnerId,
        address registrar,
        uint256 amountOut,
        uint256 price,
        uint256 action
    ) external view returns (uint256 amountIn);

    function getAmountOut(
        address partnerId,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 action
    ) external view returns (uint256 amountOut);

    function buyFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 registrarAmount);

    function sellFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 deiAmount);

    function collect(address recipient) external;

    function withdrawFee(address recipient, uint256 registrarType) external;

    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_) external;

    function setAppId(uint32 appId_) external;

    function setMuonContract(address muonContract_) external;

    function setExpireTime(uint256 expireTime_) external;
    
    function setDelayTimestamp(uint256 delayTimestamp_) external;
}

//Dar panah khoda

// SPDX-License-Identifier: GPL3.0-or-later

pragma solidity 0.8.13;

interface IMintHelper {
    function dei() external view returns (address);

    function useVirtualReserve(address pool) external view returns (bool);

    function virtualReserve() external view returns (uint256);

    function MINTER_ROLE() external view returns (bytes32);

    function mint(address recv, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function collatDollarBalance(uint256 collat_usd_price)
        external
        view
        returns (uint256);

    function setVirtualReserve(uint256 virtualReserve_) external;

    function setUseVirtualReserve(address pool, bool state) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IRegistrar is IERC20Metadata {
    function roleChecker() external view returns (address);

    function version() external view returns (string calldata);

    function registrarType() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function setType(uint256 registrarType_) external;

    function rename(string memory name, string memory symbol) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IPartnerManager {
    event RegistrarFeeAdded(address owner, uint256[] registrarType, uint256[] partnerFee);
    event PlatformFeeAdded(uint256[] registrarType, uint256[] minPlatformFee, uint256[] minTotalFee);
    event SetCap(address partnerId, int256 cap);

    function minPlatformFee(uint256 index) external view returns (uint256);

    function minTotalFee(uint256 index) external view returns (uint256);

    function partnerFee(address partner, uint256 index) external view returns (uint256);

    function platformFeeCollector() external view returns (address);

    function scale() external view returns (uint256);

    function isPartner(address partner) external view returns (bool);

    function maxCap(address partner) external view returns (int256);

    function addRegistrarFee(uint256[] memory registrarType, uint256[] memory partnerFee_) external;

    function addPlatformFee(
        uint256[] memory registrarType,
        uint256[] memory minPlatformFee_,
        uint256[] memory minTotalFee_
    ) external;

    function setCap(address partnerId, int256 cap, bool isNegative) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV02 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}