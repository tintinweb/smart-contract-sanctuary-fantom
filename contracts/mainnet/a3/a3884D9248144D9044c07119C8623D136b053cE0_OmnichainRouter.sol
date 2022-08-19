// SPDX-License-Identifier: BUSL-1.1
// Omnisea omnichain-router Contracts v0.1

pragma solidity 0.8.9;

import "./NonblockingLzApp.sol";
import "../interfaces/IOmniApp.sol";
import {IAxelarExecutable} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarExecutable.sol';
import {IAxelarGateway} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol';
import {IAxelarGasService} from '@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol';
import {AddressToString, StringToAddress} from '../libs/StringAddressUtils.sol';
import "../interfaces/IOmnichainRouter.sol";
import '@routerprotocol/router-crosstalk/contracts/RouterCrossTalk.sol';

/**
 * @title OmnichainRouter
 * @author Omnisea @MaciejCzypek
 * @custom:version 0.1
 * @notice Omnichain Router contract serves as an abstract layer and common interface for omnichain/cross-chain
 *         messaging protocols. Currently supports LayerZero and Axelar.
 */
contract OmnichainRouter is IOmnichainRouter, NonblockingLzApp, IAxelarExecutable, RouterCrossTalk {
    using StringToAddress for string;
    using AddressToString for address;

    event LzReceived(uint16 srcId);
    event AxReceived(string srcChain, string srcOA);
    event Redirect(string fromChain, string toChain);
    event Redirected(string sourceChain, string toChain);

    /**
     * @notice Single route containing omnichain protocol (provider) identifier and its chain mapping
     *
     * @dev provider: 'lz': LayerZero | 'ax': Axelar | 'rp': Router Protocol
     * @dev chainId: LayerZero .send() param | Router Protocol routerSend() param
     * @dev dstChain: Axelar gateway.callContract() param
    */
    struct Route {
        string provider;
        uint16 chainId;
        string dstChain;
    }

    /**
     * @notice Data structure for router's call execution
     *
     * @dev dstChainName: Name of the destination chain
     * @dev payload: Data passed to the omReceive() function of the destination OA
     * @dev gas: Gas limit of the function execution on the destination chain
     * @dev user: Address of the user sending cross-chain message
     * @dev srcOA: Address of the OA on the source chain
     * @dev redirectFee: redirectFee Fee required to cover transaction fee on the redirectChain, if involved.
     *      Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
    */
    struct RouteCall {
        string dstChainName;
        bytes payload;
        uint gas;
        address user;
        address srcOA;
        uint256 redirectFee;
    }

    error AxInitialized();

    mapping(string => Route) public chainNameToRoute;
    string public chainName;
    string public redirectChain;
    mapping(address => uint256) public oaRedirectBudget;
    mapping(address => uint256) public srcOARedirectBudget;
    IAxelarGasService public axGasReceiver;
    mapping(string => address) internal axRemotes;
    address private _owner;
    mapping(uint8 => uint256) private _rpChainToGas;

    /**
     * @notice Sets the cross-chain protocols contracts - LayerZero Endpoint, Axelar Gateway & GasReceiver, etc.
     * Also sets source chain name and name of the chain delegated for multi-protocol cross-chain messaging.
     * @notice Using LayerZero in the Non-blocking mode.
     *
     * @param _lzEndpoint Address of the LayerZero Endpoint contract.
     * @param _axGateway Address of the Axelar Gateway contract.
     * @param _axGasReceiver Address of the Axelar GasReceiver contract.
     * @param _genericHandler Address of the Router Protocol's GenericHandler contract.
     */
    constructor(
        address _lzEndpoint,
        address _axGateway,
        address _axGasReceiver,
        address _genericHandler
) NonblockingLzApp(_lzEndpoint) IAxelarExecutable(address(0)) RouterCrossTalk(_genericHandler) {
        if (address(gateway) != address(0) || address(axGasReceiver) != address(0)) revert AxInitialized();
        _owner = msg.sender;
        chainName = "Fantom";
        redirectChain = "Avalanche";
        axGasReceiver = IAxelarGasService(_axGasReceiver);
        gateway = IAxelarGateway(_axGateway);
    }

    /**
     * @notice Adds new route.
     *
     * @param provider Symbol of the cross-chain messaging protocol.
     * @param chainId Chain identifier used internally by LayerZero.
     * @param dstChain Chain identifier (name) used internally by Axelar.
     */
    function addRoute(string memory provider, uint16 chainId, string memory dstChain) external onlyOwner {
        Route memory route = Route(provider, chainId, dstChain);
        chainNameToRoute[dstChain] = route;
    }

    /**
     * @notice Creates the mapping between supported by Axelar chain's name and corresponding remote Router address.
     *
     * @param _chainName Name of the chain supported by Axelar.
     * @param _remote Address of the corresponding remote OmnichainRouter contract.
     */
    function setAxRemote(string memory _chainName, address _remote) external onlyOwner {
        axRemotes[_chainName] = _remote;
    }

    /**
     * @notice Checks the Axelar remote binding.
     *
     * @param _chainName Name of the chain supported by Axelar.
     * @param _remote Address of the corresponding remote OmnichainRouter contract.
     */
    function isAxRemote(string memory _chainName, address _remote) public view returns (bool) {
        return axRemotes[_chainName] == _remote;
    }

    /**
     * @notice Adds default gas for Router Protocol tx.
     *
     * @param _chainId Chain identifier used internally by Router Protocol.
     * @param _gas Gas amount per selected chain.
     */
    function setRpGas(uint8 _chainId, uint256 _gas) external onlyOwner {
        _rpChainToGas[_chainId] = _gas;
    }

    /**
     * @notice Checks if the direct route is present or redirection is required. If true, redirectChain won't be used.
     *
     * @param dstChainName Name of the destination chain.
     */
    function isDirectRoute(string memory dstChainName) public view returns (bool) {
        return bytes(chainNameToRoute[dstChainName].provider).length > 0;
    }

    /**
     * @notice Function used by third applications to delegate a cross-chain task to Router. Maps and sends the message using
     *         the underlying protocol matching the route.
     *
     * @param dstChainName Name of the remote chain.
     * @param dstOA Address of the remote Omnichain Application ("OA").
     * @param fnData Encoded payload with data passed to a remote omReceive() function.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param user Address of the user initiating the cross-chain task (for gas refund)
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function send(string memory dstChainName, address dstOA, bytes memory fnData, uint gas, address user, uint256 redirectFee) external override payable {
        bytes memory _payload = abi.encode(dstChainName, dstOA, fnData, gas, msg.sender, chainName, user, redirectFee);
        RouteCall memory params = RouteCall(dstChainName, _payload, gas, user, msg.sender, redirectFee);
        _route(params, false);
    }

    /**
     * @notice OmnichainRouter on the redirect chain is charged with redirection transaction fee. Omnichain Application
     *         needs to fund its budget to support redirections (multi-protocol messaging).
     *
     * @param remoteOA Address of the remote Omnichain Application ("OA") that calls the redirect chain Router.
     */
    function fundOA(address remoteOA) external payable {
        require(keccak256(bytes(chainName)) == keccak256(bytes(redirectChain)));
        oaRedirectBudget[remoteOA] += msg.value;
    }

    /**
     * @notice Router on source chain receives redirect fee on payable send() function call. This fee is accounted to srcOARedirectBudget.
     *         here, msg.sender is that srcOA. srcOA contract should implement this function and point the address below which manages redirection budget.
     *
     * @param redirectionBudgetManager Address pointed by the srcOA (msg.sender) executing this function. Responsible for funding srcOA redirection budget.
     */
    function withdrawOARedirectFees(address redirectionBudgetManager) external {
        require(srcOARedirectBudget[msg.sender] > 0);
        srcOARedirectBudget[msg.sender] = 0;
        (bool sent,) = payable(redirectionBudgetManager).call{value: srcOARedirectBudget[msg.sender]}("");
        require(sent, "NO_WITHDRAW");
    }

    /**
     * @notice Maps the route by received params containing source and destination chain names, and delegates
     *         the sending of the message to the matching protocol.
     *
     * @param params See {RouteCall} struct.
     */
    function _route(RouteCall memory params, bool isRedirected) internal {
        bool isRedirect = isDirectRoute(params.dstChainName) == false;
        if (isRedirect) {
            _validateAndAssignRedirectFee(params.srcOA, params.redirectFee);
            emit Redirect(chainName, params.dstChainName);
        }
        Route storage route = isRedirect ? chainNameToRoute[redirectChain] : chainNameToRoute[params.dstChainName];

        if (keccak256(bytes(route.provider)) == keccak256(bytes('lz'))) {
            _lzProcess(route.chainId, params, isRedirect, isRedirected);
            return;
        }

        if (keccak256(bytes(route.provider)) == keccak256(bytes('ax'))) {
            _axProcess(route.dstChain, params, isRedirect, isRedirected);
            return;
        }

        _rpProcess(uint8(route.chainId), params, isRedirect, isRedirected);
    }

    /**
     * @notice Handles the cross-chain message sending by LayerZero.
     *
     * @param chainId Destination chain identifier used internally by LayerZero Endpoint.
     * @param params See {RouteCall} struct.
     * @param isRedirect Used to set the gas limit (default if true for delegating message to redirect chain).
     * @param isRedirected Sets if transaction is "redirection" from redirectChain to dstChain.
     */
    function _lzProcess(uint16 chainId, RouteCall memory params, bool isRedirect, bool isRedirected) internal {
        bytes memory adapter = _getAdapter(isRedirect ? 0 : params.gas);

        if (isRedirected) {
            (uint messageFee,) = lzEndpoint.estimateFees(chainId, address(this), params.payload, false, adapter);
            lzEndpoint.send{value : messageFee}(chainId, this.getTrustedRemote(chainId), params.payload, payable(params.user), address(0x0), adapter);
            return;
        }
        lzEndpoint.send{value : (msg.value - params.redirectFee)}(chainId, this.getTrustedRemote(chainId), params.payload, payable(params.user), address(0x0), adapter);
    }

    /**
     * @notice Handles the cross-chain message sending by Axelar.
     *
     * @param dstChain Destination chain identifier (name) used internally by Axelar contracts.
     * @param params See {RouteCall} struct.
     * @param isRedirect Used to set the destination OA considering possible redirection.
     * @param isRedirected Sets if transaction is "redirection" from redirectChain to dstChain. Applies redirectFee.
     */
    function _axProcess(string memory dstChain, RouteCall memory params, bool isRedirect, bool isRedirected) internal {
        string memory dstStringAddress = isRedirect ? axRemotes[redirectChain].toString() : axRemotes[params.dstChainName].toString();

        if (isRedirected) {
            axGasReceiver.payNativeGasForContractCall{value : params.redirectFee}(address(this), dstChain, dstStringAddress, params.payload, params.user);
        } else {
            axGasReceiver.payNativeGasForContractCall{value : (msg.value - params.redirectFee)}(address(this), dstChain, dstStringAddress, params.payload, params.user);
        }
        gateway.callContract(dstChain, dstStringAddress, params.payload);
    }

    /**
     * @notice Handles the cross-chain message sending by Router Protocol.
     *
     * @param _chainId Destination chain identifier used internally by Router Protocol contract.
     * @param _params See {RouteCall} struct.
     * @param _isRedirect Used to set the destination OA considering possible redirection
     * @param _isRedirected Sets if transaction is "redirection" from redirectChain to dstChain.
     */
    function _rpProcess(uint8 _chainId, RouteCall memory _params, bool _isRedirect, bool _isRedirected) internal {
        uint256 _gas = _isRedirect ? _rpChainToGas[_chainId] : _params.gas;

        if (_isRedirected) {
            routerSend(_chainId, bytes4(""), _params.payload, _gas);
            return;
        }
        routerSend(_chainId, bytes4(""), _params.payload, _gas);
    }

    /**
     * @notice Handles the cross-chain message receive by LayerZero.
     *
     * @param srcChainId Source chain identifier used by LayerZero.
     * @param srcAddress Address of the Router sending the message.
     * @param payload Encoded message data
     */
    function _nonblockingLzReceive(uint16 srcChainId, bytes memory srcAddress, uint64, bytes memory payload) internal override {
        emit LzReceived(srcChainId);
        require(this.isTrustedRemote(srcChainId, srcAddress), "NOT_LZ_REMOTE");
        _processMessage(payload);
    }

    /**
     * @notice Handles the cross-chain message receive by Axelar.
     *
     * @param srcChain Source chain identifier (name) used by Axelar.
     * @param srcAddressString Address of the Router sending the message.
     * @param payload Encoded message data
     */
    function _execute(
        string memory srcChain,
        string memory srcAddressString,
        bytes calldata payload
    ) internal override {
        emit AxReceived(srcChain, srcAddressString);
        require(isAxRemote(srcChain, srcAddressString.toAddress()), 'NOT_AX_REMOTE');
        _processMessage(payload);
    }

    /**
     * @notice Processes a received message.
     *
     * @param payload Encoded message data
     */
    function _processMessage(bytes memory payload) internal {
        (string memory dstChainName, address dstOA, bytes memory fnData, uint gas, address srcOA, string memory srcChain, address user, uint256 redirectFee)
        = abi.decode(payload, (string, address, bytes, uint, address, string, address, uint256));

        if (keccak256(bytes(dstChainName)) != keccak256(bytes(chainName))) {
            emit Redirected(srcChain, dstChainName);
            RouteCall memory params = RouteCall(dstChainName, payload, gas, user, srcOA, redirectFee);
            require(isDirectRoute(dstChainName), "NO_REDIRECTED_ROUTE");
            _validateAndChargeOA(params.srcOA, params.redirectFee);
            _route(params, true);

            return;
        }
        IOmniApp receiver = IOmniApp(dstOA);
        receiver.omReceive(fnData, srcOA, srcChain);
    }

    /**
     * @notice Validates the budget of the Omnichain Application ("OA"), Router's balance, and charges OA with redirection fee.
     *
     * @param remoteOA Address of the source OA
     * @param redirectFee Fee to be paid for the redirection by the OmnichainRouter contract. OA will be charged.
     */
    function _validateAndChargeOA(address remoteOA, uint256 redirectFee) internal {
        require(address(this).balance >= redirectFee, "ROUTER_NOT_FUNDED");
        require(oaRedirectBudget[remoteOA] >= redirectFee, "OA_NOT_FUNDED");
        oaRedirectBudget[remoteOA] -= redirectFee;
    }

    /**
     * @notice Validates the user's balance, and assigns redirection fee for OA redirections budget
     * @notice To be automated using native gas airdrop function in the future iteration
     *
     * @param srcOA Address of the Omnichain Application on the source chain
     * @param redirectFee Fee to be paid for the redirection by the OmnichainRouter contract. OA will be charged on destination.
     */
    function _validateAndAssignRedirectFee(address srcOA, uint256 redirectFee) internal {
        require(redirectFee > 0, "NO_REDIRECT_FEE");
        srcOARedirectBudget[srcOA] += redirectFee;
    }

    /**
     * @notice Returns LayerZero-specific adapter used to customize the cross-chain transaction gas usage.
     *
     * @param gas Set gas limit
     */
    function _getAdapter(uint gas) private pure returns (bytes memory) {
        if (gas == 0) {
            return bytes("");
        }
        uint16 v = 1;
        return abi.encodePacked(v, gas);
    }

    /**
     * @notice Returns cross-chain transaction fee calculated by LayerZero Endpoint contract.
     *
     * @param chainId Destination chain identifier used internally by LayerZero.
     * @param payload Encoded message data
     * @param gas Gas limit set for a cross-chain transaction execution.
     */
    function estimateFees(uint16 chainId, bytes memory payload, uint gas) external view returns (uint) {
        (uint fee,) = lzEndpoint.estimateFees(chainId, address(this), payload, false, _getAdapter(gas));
        return fee;
    }

    function setLinker(address _linker) external onlyOwner() {
        setLink(_linker);
    }

    function setFeeAddress(address _feeAddress) external onlyOwner() {
        setFeeToken(_feeAddress);
    }

    function _routerSyncHandler(bytes4, bytes memory _data) internal virtual override  returns (bool ,bytes memory) {
        _processMessage(_data);

        return (true, _data);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./LzApp.sol";

abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
        } catch {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual {
        require(_msgSender() == address(this));
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable virtual {
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0));
        require(keccak256(_payload) == payloadHash);
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmniApp {
    /**
     * @notice Function to be implemented by the Omnichain Application ("OA") utilizing Omnichain Router for receiving
     *         cross-chain messages.
     *
     * @param payload Encoded payload with a data for a target function execution.
     * @param srcOA Address of the remote Omnichain Application ("OA") that can be used for source validation.
     * @param srcChain Name of the source remote chain.
     */
    function omReceive(bytes calldata payload, address srcOA, string memory srcChain) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarGateway } from './IAxelarGateway.sol';

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    constructor(address gateway_) {
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetDailyMintLimitsParams();
    error ExceedDailyMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(address indexed sender, string destinationChain, string destinationAddress, string symbol, uint256 amount);

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenDailyMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function tokenDailyMintLimit(string memory symbol) external view returns (uint256);

    function tokenDailyMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenDailyMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IUpgradable.sol';

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService is IUpgradable {
    error NothingReceived();
    error TransferFailed();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

library StringToAddress {
    function toAddress(string memory _a) internal pure returns (address) {
        bytes memory tmp = bytes(_a);
        if (tmp.length != 42) return address(0);
        uint160 iaddr = 0;
        uint8 b;
        for (uint256 i = 2; i < 42; i++) {
            b = uint8(tmp[i]);
            if ((b >= 97) && (b <= 102)) b -= 87;
            else if ((b >= 65) && (b <= 70)) b -= 55;
            else if ((b >= 48) && (b <= 57)) b -= 48;
            else return address(0);
            iaddr |= uint160(uint256(b) << ((41 - i) << 2));
        }
        return address(iaddr);
    }
}

library AddressToString {
    function toString(address a) internal pure returns (string memory) {
        bytes memory data = abi.encodePacked(a);
        bytes memory characters = '0123456789abcdef';
        bytes memory byteString = new bytes(2 + data.length * 2);

        byteString[0] = '0';
        byteString[1] = 'x';

        for (uint256 i; i < data.length; ++i) {
            byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
            byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
        }
        return string(byteString);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmnichainRouter {
    /**
     * @notice Function used by third applications to delegate a cross-chain task to Router. Maps and sends the message using
     *         the underlying protocol matching the route.
     *
     * @param dstChainName Name of the remote chain.
     * @param dstOA Address of the remote Omnichain Application ("OA").
     * @param fnData Encoded payload with a data for a target function execution.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param user Address of the user initiating the cross-chain task (for gas refund)
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function send(string memory dstChainName, address dstOA, bytes memory fnData, uint gas, address user, uint256 redirectFee) external payable;

    /**
     * @notice Router on source chain receives redirect fee on payable send() function call. This fee is accounted to srcOARedirectBudget.
     *         here, msg.sender is that srcOA. srcOA contract should implement this function and point the address below which manages redirection budget.
     *
     * @param redirectionBudgetManager Address pointed by the srcOA (msg.sender) executing this function.
     *        Responsible for funding srcOA redirection budget.
     */
    function withdrawOARedirectFees(address redirectionBudgetManager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./interfaces/iGenericHandler.sol";
import "./interfaces/iRouterCrossTalk.sol";

/// @title RouterCrossTalk contract
/// @author Router Protocol
abstract contract RouterCrossTalk is Context , iRouterCrossTalk, ERC165 {

    iGenericHandler private handler;

    address private linkSetter;

    address private feeToken;

    mapping ( uint8 => address ) private Chain2Addr; // CHain ID to Address

    modifier isHandler(){
        require(_msgSender() == address(handler) , "RouterCrossTalk : Only GenericHandler can call this function" );
        _;
    }

    modifier isLinkSet(uint8 _chainID){
        require(Chain2Addr[_chainID] == address(0) , "RouterCrossTalk : Cross Chain Contract to Chain ID set" );
        _;
    }

    modifier isLinkUnSet(uint8 _chainID){
        require(Chain2Addr[_chainID] != address(0) , "RouterCrossTalk : Cross Chain Contract to Chain ID is not set" );
        _;
    }

    modifier isLinkSync( uint8 _srcChainID, address _srcAddress ){
        require(Chain2Addr[_srcChainID] == _srcAddress , "RouterCrossTalk : Source Address Not linked" );
        _;
    }

    modifier isSelf(){
        require(_msgSender() == address(this) , "RouterCrossTalk : Can only be called by Current Contract" );
        _;
    }

    constructor( address _handler ) {
        handler = iGenericHandler(_handler);
    }

    /// @notice Used to set linker address, this function is internal and can only be set by contract owner or admins
    /// @param _addr Address of linker.
    function setLink( address _addr ) internal {
        linkSetter = _addr;
    }

    /// @notice Used to set fee Token address, this function is internal and can only be set by contract owner or admins
    /// @param _addr Address of linker.
    function setFeeToken( address _addr ) internal {
        feeToken = _addr;
    }

    function fetchHandler( ) external override view returns ( address ) {
        return address(handler);
    }

    function fetchLinkSetter( ) external override view returns( address) {
        return linkSetter;
    }

    function fetchLink( uint8 _chainID ) external override view returns( address) {
        return Chain2Addr[_chainID];
    }

    function fetchFeetToken(  ) external override view returns( address) {
        return feeToken;
    }

    /// @notice routerSend This is internal function to generate a cross chain communication request.
    /// @param destChainId Destination ChainID.
    /// @param _selector Selector to interface on destination side.
    /// @param _data Data to be sent on Destination side.
    /// @param _gas Gas provided for cross chain send.
    function routerSend( uint8 destChainId , bytes4 _selector , bytes memory _data , uint256 _gas) internal isLinkUnSet( destChainId ) returns (bool success) {
        uint8 cid = handler.fetch_chainID();
        bytes32 hash = _hash(address(this),Chain2Addr[destChainId],destChainId, _selector, _data);
        handler.genericDeposit(destChainId , _selector , _data, hash , _gas , feeToken );
        emit CrossTalkSend( cid , destChainId , address(this), Chain2Addr[destChainId] ,_selector, _data , hash );
        return true;
    }

    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _selector , bytes memory _data , bytes32 hash ) external override isLinkSync( srcChainID , srcAddress ) isHandler returns ( bool , bytes memory ) {
        uint8 cid = handler.fetch_chainID();
        bytes32 Dhash = _hash(Chain2Addr[srcChainID],address(this),cid, _selector, _data);
        require( Dhash == hash , "RouterSync : Valid Hash" );
        ( bool success , bytes memory _returnData ) = _routerSyncHandler( _selector , _data );
        emit CrossTalkReceive( srcChainID , cid , srcAddress , address(this), _selector, _data , hash );
        return ( success , _returnData );
    }

    /// @notice _hash This is internal function to generate the hash of all data sent or received by the contract.
    /// @param _srcAddress Source Address.
    /// @param _destAddress Destination Address.
    /// @param _destChainId Destination ChainID.
    /// @param _selector Selector to interface on destination side.
    /// @param _data Data to interface on Destination side.
    function _hash(address _srcAddress , address _destAddress , uint8 _destChainId , bytes4 _selector , bytes memory _data) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            _srcAddress,
            _destAddress,
            _destChainId,
            _selector,
            keccak256(_data)
        ));
    }

    function Link(uint8 _chainID , address _linkedContract) external override isHandler isLinkSet(_chainID) {
        Chain2Addr[_chainID] = _linkedContract;
        emit Linkevent( _chainID , _linkedContract );
    }

    function Unlink(uint8 _chainID ) external override isHandler {
        emit Unlinkevent( _chainID , Chain2Addr[_chainID] );
        Chain2Addr[_chainID] = address(0);
    }

    function approveFees(address _feeToken , uint256 _value) external {
        IERC20 token = IERC20(_feeToken);
        token.approve( address(handler) , _value );
    }

    /// @notice _routerSyncHandler This is internal function to control the handling of various selectors and its corresponding .
    /// @param _selector Selector to interface.
    /// @param _data Data to be handled.
    function _routerSyncHandler( bytes4 _selector , bytes memory _data ) internal virtual returns ( bool ,bytes memory );
    uint256[100] private __gap;

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint internal immutable lzEndpoint;

    mapping(uint16 => bytes) internal trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint));
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), "LzReceiver: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParam) internal {
        require(trustedRemoteLookup[_dstChainId].length != 0, "LzSend: destination chain is not a trusted source.");
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _adapterParam);
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(lzEndpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    // interacting with the LayerZero Endpoint and remote contracts

    function getTrustedRemote(uint16 _chainId) external view returns (bytes memory) {
        return trustedRemoteLookup[_chainId];
    }

    function getLzEndpoint() external view returns (address) {
        return address(lzEndpoint);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external view returns (bytes32);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title GenericHandler contract interface for router Crosstalk
/// @author Router Protocol
interface iGenericHandler {

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
        uint8 linkerType;
    }

    /// @notice UnMapContract Unmaps the contract from the RouterCrossTalk Contract
    /// @dev This function is used to map contract from router-crosstalk contract
    /// @param linker The Data object consisting of target Contract , CHainid , Contract to be Mapped and linker type.
    /// @param _sign Signature of Linker data object signed by linkerSetter address.
    function MapContract( RouterLinker calldata linker , bytes memory _sign ) external;

    /// @notice UnMapContract Unmaps the contract from the RouterCrossTalk Contract
    /// @dev This function is used to unmap contract from router-crosstalk contract
    /// @param linker The Data object consisting of target Contract , CHainid , Contract to be unMapped and linker type.
    /// @param _sign Signature of Linker data object signed by linkerSetter address.
    function UnMapContract(RouterLinker calldata linker , bytes memory _sign ) external;

    /// @notice generic deposit on generic handler contract
    /// @dev This function is called by router crosstalk contract while initiating crosschain transaction
    /// @param _destChainID Chain id to be transacted
    /// @param _selector Selector for the crosschain interface
    /// @param _data Data to be transferred
    /// @param _hash Hash of the data sent to the contract
    /// @param _gas Gas Specified for the contract function
    /// @param _feeToken Fee Token Specified for the contract function
    function genericDeposit( uint8 _destChainID, bytes4 _selector, bytes memory _data, bytes32 _hash, uint256 _gas, address _feeToken) external;

    /// @notice Fetches ChainID for the native chain
    function fetch_chainID( ) external view returns ( uint8 );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title iRouterCrossTalk contract interface for router Crosstalk
/// @author Router Protocol
interface iRouterCrossTalk is IERC165 {

    /// @notice Link event is emitted when a new link is created.
    /// @param ChainID Chain id the contract is linked to.
    /// @param linkedContract Contract address linked to.
    event Linkevent( uint8 indexed ChainID , address indexed linkedContract );

    /// @notice UnLink event is emitted when a link is removed.
    /// @param ChainID Chain id the contract is unlinked to.
    /// @param linkedContract Contract address unlinked to.
    event Unlinkevent( uint8 indexed ChainID , address indexed linkedContract );

    /// @notice CrossTalkSend Event is emited when a request is generated in soruce side when cross chain request is generated.
    /// @param sourceChain Source ChainID.
    /// @param destChain Destination ChainID.
    /// @param sourceAddress Source Address.
    /// @param destinationAddress Destination Address.
    /// @param _selector Selector to interface on destination side.
    /// @param _data Data to interface on Destination side.
    /// @param _hash Hash of the data sent.
    event CrossTalkSend(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _selector, bytes _data , bytes32 _hash );

    /// @notice CrossTalkReceive Event is emited when a request is recived in destination side when cross chain request accepted by contract.
    /// @param sourceChain Source ChainID.
    /// @param destChain Destination ChainID.
    /// @param sourceAddress Source Address.
    /// @param destinationAddress Destination Address.
    /// @param _selector Selector to interface on destination side.
    /// @param _data Data to interface on Destination side.
    /// @param _hash Hash of the data sent.
    event CrossTalkReceive(uint8 indexed sourceChain , uint8 indexed destChain , address sourceAddress , address destinationAddress ,bytes4 indexed _selector, bytes _data , bytes32 _hash );

    /// @notice routerSync This is a public function and can only be called by Generic Handler of router infrastructure
    /// @param srcChainID Source ChainID.
    /// @param srcAddress Destination ChainID.
    /// @param _selector Selector to interface on destination side.
    /// @param _data Data to interface on Destination side.
    /// @param hash Hash of the data sent.
    function routerSync(uint8 srcChainID , address srcAddress , bytes4 _selector , bytes calldata _data , bytes32 hash ) external returns ( bool , bytes memory );

    /// @notice Link This is a public function and can only be called by Generic Handler of router infrastructure
    /// @notice This function links contract on other chain ID's.
    /// @notice This is an administrative function and can only be initiated by linkSetter address.
    /// @param _chainID network Chain ID linked Contract linked to.
    /// @param _linkedContract Linked Contract address.
    function Link(uint8 _chainID , address _linkedContract) external;

    /// @notice UnLink This is a public function and can only be called by Generic Handler of router infrastructure
    /// @notice This function unLinks contract on other chain ID's.
    /// @notice This is an administrative function and can only be initiated by linkSetter address.
    /// @param _chainID network Chain ID linked Contract linked to.
    function Unlink(uint8 _chainID ) external;

    /// @notice fetchLinkSetter This is a public function and fetches the linksetter address.
    function fetchLinkSetter( ) external view returns( address );

    /// @notice fetchLinkSetter This is a public function and fetches the address the contract is linked to.
    /// @param _chainID Chain ID information.
    function fetchLink( uint8 _chainID ) external view returns( address );

    /// @notice fetchLinkSetter This is a public function and fetches the generic handler address.
    function fetchHandler( ) external view returns ( address );

    /// @notice fetchFeetToken This is a public function and fetches the fee token set by admin.
    function fetchFeetToken(  ) external view returns( address );

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