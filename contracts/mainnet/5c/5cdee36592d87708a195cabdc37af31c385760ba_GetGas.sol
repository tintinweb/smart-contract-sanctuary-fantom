/**
 *Submitted for verification at FtmScan.com on 2022-12-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _value The value in wei to send to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint256 _value,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                _value, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
        internal
        pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

abstract contract LzNativeTransceiver is
    Ownable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    using ExcessivelySafeCall for address;

    error CallerInvalid();
    error SenderInvalid();
    error DestinationInvalid();
    error PayloadLengthInvalid();
    error PayloadBalanceMismatch(uint256 required, uint256 actual);
    error PayloadToRetryMissing();
    error PayloadToRetryInvalid();
    error FailedToWithdraw();

    event TrustedRemoteSet(
        uint16 indexed _sourceChainId,
        bytes _pathDestToSource
    );
    event ReceiveFailed(
        uint16 indexed _sourceChainId,
        bytes _sourcePath,
        uint64 _nonce,
        bytes _payload,
        uint256 _balance,
        bytes _reason
    );
    event ReceiveRetrySuceeded(
        uint16 indexed _sourceChainId,
        bytes _sourcePath,
        uint64 _nonce,
        bytes32 _payloadHash
    );

    struct NativePayload {
        uint256 amount;
        bytes payload;
    }

    struct StoredReceive {
        bytes32 payloadHash;
        uint256 storedBalance;
    }

    ILayerZeroEndpoint public immutable lzEndpoint;
    mapping(uint16 => bytes) public trustedRemotes;

    uint256 public totalStoredBalance;
    mapping(uint16 => mapping(bytes => mapping(uint64 => StoredReceive)))
        public storedReceives; // [sourceChainId][sourcePath][nonce] => StoredReceive

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzSend(
        uint16 _destChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zeroPaymentAddress,
        uint256 _nativeFee,
        uint256 _gasForDest,
        uint256 _nativeForDest
    ) internal {
        bytes memory trustedDestination = trustedRemotes[_destChainId];
        if (trustedDestination.length == 0) {
            revert DestinationInvalid();
        }

        (address destAddress, ) = decodeTrustedRemote(trustedDestination);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),
            _gasForDest,
            _nativeForDest,
            destAddress
        );

        bytes memory nativePayload = abi.encode(
            NativePayload({amount: _nativeForDest, payload: _payload})
        );

        lzEndpoint.send{value: _nativeFee}(
            _destChainId,
            trustedDestination,
            nativePayload,
            _refundAddress,
            _zeroPaymentAddress,
            adapterParams
        );
    }

    function lzEstimateFee(
        uint16 _destChainId,
        bytes memory _payload,
        uint256 _gasForDest,
        uint256 _nativeForDest
    ) internal view returns (uint256 lzFee) {
        bytes memory trustedDestination = trustedRemotes[_destChainId];
        if (trustedDestination.length == 0) {
            revert DestinationInvalid();
        }

        (address destAddress, ) = decodeTrustedRemote(trustedDestination);
        bytes memory adapterParams = abi.encodePacked(
            uint16(2),
            _gasForDest,
            _nativeForDest,
            destAddress
        );

        bytes memory nativePayload = abi.encode(
            NativePayload({amount: _nativeForDest, payload: _payload})
        );

        (lzFee, ) = lzEndpoint.estimateFees(
            _destChainId,
            address(this),
            nativePayload,
            false,
            adapterParams
        );
    }

    /**
     * @dev _trustedRemote memory layout is 30 (length) + 20 (remote address) + 20 (source address) [assuming EVM only]
     * LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
     * 00  02  04  06  08  10  12  14  16  18  20  22  24  26  28  30  32  34  36  38  40  42  44  46  48  50  52  54  56  58  60  62  64  66  68  70
     *   01  03  05  07  09  11  13  15  17  19  21  23  25  27  29  31  33  35  37  39  41  43  45  47  49  51  53  55  57  59  61  63  65  67  69  71
     *                                         \------------------------destination---------------------------/
     *                                                                                 \---------------------------source-----------------------------/
     * destination = LLLLLLLLLLLLLLLLLLLLLLLLDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD
     * source      = DDDDDDDDDDDDDDDDDDDDDDDDSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
     */
    function decodeTrustedRemote(bytes memory _trustedRemote)
        internal
        pure
        returns (address destination, address source)
    {
        // layout is bytes32,address20,address20
        // mload loads bytes32, cast to address clears the 'left' bits
        assembly {
            destination := mload(add(_trustedRemote, 20))
            source := mload(add(_trustedRemote, 40))
        }
    }

    /**
     * @dev If called from LayerZero endpoint (as intended); reverting blocks whole channel
     * CallerInvalid - not called from LZ endpoint, safe
     * SenderInvalid - source not configured, blocks channel
     * PayloadLengthInvalid - sent bad payload, blocks channel
     * PayloadBalanceMismatch - relayer didn't send enough native, blocks channel
     */
    function lzReceive(
        uint16 _sourceChainId,
        bytes calldata _sourcePath,
        uint64 _nonce,
        bytes calldata _payload
    ) external override {
        if (msg.sender != address(lzEndpoint)) {
            revert CallerInvalid();
        }

        bytes memory trustedSource = trustedRemotes[_sourceChainId];
        if (
            _sourcePath.length != trustedSource.length ||
            trustedSource.length == 0 ||
            keccak256(_sourcePath) != keccak256(trustedSource)
        ) {
            revert SenderInvalid();
        }

        NativePayload memory nativePayload = validateReceivedBalance(_payload);

        receiveOrStore(
            _sourceChainId,
            _sourcePath,
            _nonce,
            nativePayload.amount,
            nativePayload.payload
        );
    }

    /**
     * @dev Check relayer sent us native requested
     */
    function validateReceivedBalance(bytes calldata _payload)
        internal
        view
        returns (NativePayload memory nativePayload)
    {
        if (_payload.length < 8) {
            revert PayloadLengthInvalid();
        }

        uint256 actual = availableBalance();
        nativePayload = abi.decode(_payload, (NativePayload));

        if (actual < nativePayload.amount) {
            revert PayloadBalanceMismatch(nativePayload.amount, actual);
        }
    }

    /**
     * @dev Assumes any balance not reserved for a stored/failed receive is available to curent receive
     */
    function availableBalance()
        internal
        view
        virtual
        returns (uint256 balance)
    {
        balance = address(this).balance - totalStoredBalance;
    }

    /**
     * @dev Attempts to handle the receive, if it reverts, store the payload so that it can be retried later
     */
    function receiveOrStore(
        uint16 _sourceChainId,
        bytes calldata _sourcePath,
        uint64 _nonce,
        uint256 _balance,
        bytes memory _payload
    ) internal {
        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
                safeGasLeft(_payload.length),
                0, // value
                32, // max data to copy
                abi.encodeWithSelector(
                    this.handleReceiveSafe.selector,
                    _balance,
                    _payload
                )
            );

        if (!success) {
            storeFailedReceive(
                _sourceChainId,
                _sourcePath,
                _nonce,
                _balance,
                _payload,
                reason
            );
        }
    }

    /**
     * @dev How much gas we can pass to receive function
     */
    function safeGasLeft(uint256 _payloadLength)
        internal
        view
        returns (uint256 gasLeft)
    {
        uint256 extraLogGas = _payloadLength * 18;
        gasLeft = gasleft() - 80_000 - extraLogGas;
    }

    /**
     * @dev Store the payload+balance so that the receive can be retried later
     */
    function storeFailedReceive(
        uint16 _sourceChainId,
        bytes calldata _sourcePath,
        uint64 _nonce,
        uint256 _balance,
        bytes memory _payload,
        bytes memory _reason
    ) internal {
        storedReceives[_sourceChainId][_sourcePath][_nonce] = StoredReceive({
            payloadHash: keccak256(_payload),
            storedBalance: _balance
        });
        totalStoredBalance += _balance;

        emit ReceiveFailed(
            _sourceChainId,
            _sourcePath,
            _nonce,
            _payload,
            _balance,
            _reason
        );
    }

    /**
     * @dev A previously failed receive can be retried
     */
    function retryReceive(
        uint16 _sourceChainId,
        bytes calldata _sourcePath,
        uint64 _nonce,
        bytes calldata _payload
    ) external payable {
        StoredReceive memory storedReceive = storedReceives[_sourceChainId][
            _sourcePath
        ][_nonce];

        if (storedReceive.payloadHash == bytes32(0)) {
            revert PayloadToRetryMissing();
        }

        if (storedReceive.payloadHash != keccak256(_payload)) {
            revert PayloadToRetryInvalid();
        }

        uint256 balance = storedReceive.storedBalance;

        delete storedReceives[_sourceChainId][_sourcePath][_nonce];
        totalStoredBalance -= balance;

        handleReceive(balance, _payload);
    }

    /**
     * @dev Needs to be external as called via excessivelySafeCall
     */
    function handleReceiveSafe(uint256 _balance, bytes calldata _payload)
        external
    {
        if (msg.sender != address(this)) {
            revert CallerInvalid();
        }

        handleReceive(_balance, _payload);
    }

    /**
     * @dev Override to implement receive logic
     */
    function handleReceive(uint256 _balance, bytes calldata _payload)
        internal
        virtual;

    /**
     * If channel is blocked and unrecoverable we need a way to rescue;
     * (no funds should be stored unless a TX reverts)
     */
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        if (!success) {
            revert FailedToWithdraw();
        }
    }

    /**
     * LZ Config
     */
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                _version,
                _chainId,
                address(this),
                _configType
            );
    }

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(
        uint16 _sourceChainId,
        bytes calldata _srcAddress
    ) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_sourceChainId, _srcAddress);
    }

    function setTrustedRemote(
        uint16 _sourceChainId,
        bytes calldata _pathDestToSource
    ) external onlyOwner {
        trustedRemotes[_sourceChainId] = _pathDestToSource;
        emit TrustedRemoteSet(_sourceChainId, _pathDestToSource);
    }
}

contract GetGas is LzNativeTransceiver {
    error FeeTooHigh(uint256 maxFee);
    error FeeFailed();
    error PayloadEmpty();
    error PayloadInvalid();

    event FailedToTransfer(address account, uint256 amount);

    uint256 public constant FEE_MAX = 1000; // 10%
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public fee;
    address payable public feeTo;

    struct AccountAmount {
        address payable account;
        uint256 amount;
    }

    constructor(address _endpoint) LzNativeTransceiver(_endpoint) {
        feeTo = payable(msg.sender);
        fee = 50; // 0.5%
    }

    function setFee(uint256 _newFee) external onlyOwner {
        if (_newFee > FEE_MAX) revert FeeTooHigh(FEE_MAX);
        fee = _newFee;
    }

    /**
     * @dev set to address(0) to turn off fee
     */
    function setFeeTo(address payable _newFeeTo) external onlyOwner {
        feeTo = _newFeeTo;
    }

    function handleReceive(uint256 _balance, bytes calldata _payload)
        internal
        override
    {
        if (_payload.length == 0) {
            revert PayloadEmpty();
        }

        AccountAmount[] memory destinations = abi.decode(
            _payload,
            (AccountAmount[])
        );

        if (destinations.length == 0 || destinations[0].account == address(0)) {
            revert PayloadInvalid();
        }

        uint256 balanceLeft = _balance;
        for (uint256 i = 0; i < destinations.length; ) {
            balanceLeft -= destinations[i].amount;
            (bool success, ) = destinations[i].account.call{
                value: destinations[i].amount
            }("");

            // Log failure but continue to delivery rest
            if (!success) {
                emit FailedToTransfer(
                    destinations[i].account,
                    destinations[i].amount
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    function send(
        uint16 _destChainId,
        uint256 _gasForDest,
        uint256 _localNativeFee,
        AccountAmount[] calldata destinations
    ) external payable {
        applyFee(_localNativeFee);
        uint256 nativeForDest = calculateTotalNativeForDest(destinations);

        lzSend(
            _destChainId,
            abi.encode(destinations), // payload
            payable(msg.sender), // refund address
            address(0), // zero payment address (not used),
            _localNativeFee, // how much local native is required to pay for remote gas/native
            _gasForDest, // how much dest gas is required to execute
            nativeForDest // how much native we want
        );
    }

    function calculateTotalNativeForDest(AccountAmount[] calldata destinations)
        internal
        pure
        returns (uint256 total)
    {
        total = 0;
        for (uint256 i = 0; i < destinations.length; ) {
            total = total + destinations[i].amount;

            unchecked {
                ++i;
            }
        }
    }

    function applyFee(uint256 _localNativeFee) internal {
        uint256 feeToPay = calculateFee(_localNativeFee);
        if (feeToPay > 0) {
            (bool success, ) = feeTo.call{value: feeToPay}("");
            if (!success) {
                revert FeeFailed();
            }
        }
    }

    function calculateFee(uint256 _localNativeFee)
        internal
        view
        returns (uint256 protocolFee)
    {
        if (feeTo != address(0)) {
            protocolFee = (_localNativeFee * fee) / FEE_DENOMINATOR;
        } else {
            protocolFee = 0;
        }
    }

    function estimateFees(
        uint16 _destChainId,
        uint256 _gasForDest,
        AccountAmount[] calldata destinations
    ) external view returns (uint256 bridgeFee, uint256 protocolFee) {
        uint256 nativeForDest = calculateTotalNativeForDest(destinations);
        bridgeFee = lzEstimateFee(
            _destChainId,
            abi.encode(destinations),
            _gasForDest,
            nativeForDest
        );
        protocolFee = calculateFee(bridgeFee);
    }
}