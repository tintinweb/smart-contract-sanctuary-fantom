// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IAdmin {
    function setAdmin(address _admin) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/ERC721/IERC721.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../peripherals/interfaces/ITimelock.sol";

contract TokenManager is ReentrancyGuard {
    using SafeMath for uint256;

    bool public isInitialized;

    uint256 public actionsNonce;
    uint256 public minAuthorizations;

    address public admin;

    address[] public signers;
    mapping(address => bool) public isSigner;
    mapping(bytes32 => bool) public pendingActions;
    mapping(address => mapping(bytes32 => bool)) public signedActions;

    event SignalApprove(address token, address spender, uint256 amount, bytes32 action, uint256 nonce);
    event SignalApproveNFT(address token, address spender, uint256 tokenId, bytes32 action, uint256 nonce);
    event SignalApproveNFTs(address token, address spender, uint256[] tokenIds, bytes32 action, uint256 nonce);
    event SignalSetAdmin(address target, address admin, bytes32 action, uint256 nonce);
    event SignalSetGov(address timelock, address target, address gov, bytes32 action, uint256 nonce);
    event SignalPendingAction(bytes32 action, uint256 nonce);
    event SignAction(bytes32 action, uint256 nonce);
    event ClearAction(bytes32 action, uint256 nonce);

    constructor(uint256 _minAuthorizations) public {
        admin = msg.sender;
        minAuthorizations = _minAuthorizations;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "TokenManager: forbidden");
        _;
    }

    modifier onlySigner() {
        require(isSigner[msg.sender], "TokenManager: forbidden");
        _;
    }

    function initialize(address[] memory _signers) public virtual onlyAdmin {
        require(!isInitialized, "TokenManager: already initialized");
        isInitialized = true;

        signers = _signers;
        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            isSigner[signer] = true;
        }
    }

    function signersLength() public view returns (uint256) {
        return signers.length;
    }

    function signalApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, nonce));
        _setPendingAction(action, nonce);
        emit SignalApprove(_token, _spender, _amount, action, nonce);
    }

    function signApprove(
        address _token,
        address _spender,
        uint256 _amount,
        uint256 _nonce
    ) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount,
        uint256 _nonce
    ) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        IERC20(_token).approve(_spender, _amount);
        _clearAction(action, _nonce);
    }

    function signalApproveNFT(
        address _token,
        address _spender,
        uint256 _tokenId
    ) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approveNFT", _token, _spender, _tokenId, nonce));
        _setPendingAction(action, nonce);
        emit SignalApproveNFT(_token, _spender, _tokenId, action, nonce);
    }

    function signApproveNFT(
        address _token,
        address _spender,
        uint256 _tokenId,
        uint256 _nonce
    ) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approveNFT", _token, _spender, _tokenId, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approveNFT(
        address _token,
        address _spender,
        uint256 _tokenId,
        uint256 _nonce
    ) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approveNFT", _token, _spender, _tokenId, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        IERC721(_token).approve(_spender, _tokenId);
        _clearAction(action, _nonce);
    }

    function signalApproveNFTs(
        address _token,
        address _spender,
        uint256[] memory _tokenIds
    ) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("approveNFTs", _token, _spender, _tokenIds, nonce));
        _setPendingAction(action, nonce);
        emit SignalApproveNFTs(_token, _spender, _tokenIds, action, nonce);
    }

    function signApproveNFTs(
        address _token,
        address _spender,
        uint256[] memory _tokenIds,
        uint256 _nonce
    ) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("approveNFTs", _token, _spender, _tokenIds, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function approveNFTs(
        address _token,
        address _spender,
        uint256[] memory _tokenIds,
        uint256 _nonce
    ) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approveNFTs", _token, _spender, _tokenIds, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_token).approve(_spender, _tokenIds[i]);
        }
        _clearAction(action, _nonce);
    }

    function signalSetAdmin(address _target, address _admin) external nonReentrant onlySigner {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _target, _admin, nonce));
        _setPendingAction(action, nonce);
        signedActions[msg.sender][action] = true;
        emit SignalSetAdmin(_target, _admin, action, nonce);
    }

    function signSetAdmin(
        address _target,
        address _admin,
        uint256 _nonce
    ) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _target, _admin, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function setAdmin(
        address _target,
        address _admin,
        uint256 _nonce
    ) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("setAdmin", _target, _admin, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        ITimelock(_target).setAdmin(_admin);
        _clearAction(action, _nonce);
    }

    function signalSetGov(
        address _timelock,
        address _target,
        address _gov
    ) external nonReentrant onlyAdmin {
        actionsNonce++;
        uint256 nonce = actionsNonce;
        bytes32 action = keccak256(abi.encodePacked("signalSetGov", _timelock, _target, _gov, nonce));
        _setPendingAction(action, nonce);
        signedActions[msg.sender][action] = true;
        emit SignalSetGov(_timelock, _target, _gov, action, nonce);
    }

    function signSetGov(
        address _timelock,
        address _target,
        address _gov,
        uint256 _nonce
    ) external nonReentrant onlySigner {
        bytes32 action = keccak256(abi.encodePacked("signalSetGov", _timelock, _target, _gov, _nonce));
        _validateAction(action);
        require(!signedActions[msg.sender][action], "TokenManager: already signed");
        signedActions[msg.sender][action] = true;
        emit SignAction(action, _nonce);
    }

    function setGov(
        address _timelock,
        address _target,
        address _gov,
        uint256 _nonce
    ) external nonReentrant onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("signalSetGov", _timelock, _target, _gov, _nonce));
        _validateAction(action);
        _validateAuthorization(action);

        ITimelock(_timelock).signalSetGov(_target, _gov);
        _clearAction(action, _nonce);
    }

    function _setPendingAction(bytes32 _action, uint256 _nonce) private {
        pendingActions[_action] = true;
        emit SignalPendingAction(_action, _nonce);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action], "TokenManager: action not signalled");
    }

    function _validateAuthorization(bytes32 _action) private view {
        uint256 count = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            address signer = signers[i];
            if (signedActions[signer][_action]) {
                count++;
            }
        }

        if (count == 0) {
            revert("TokenManager: action not authorized");
        }
        require(count >= minAuthorizations, "TokenManager: insufficient authorization");
    }

    function _clearAction(bytes32 _action, uint256 _nonce) private {
        require(pendingActions[_action], "TokenManager: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action, _nonce);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPancakeRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IPancakeFactory.sol";

contract PancakeFactory is IPancakeFactory {
    address public btc;
    address public bnb;
    address public busd;

    address public bnbBusdPair;
    address public btcBnbPair;

    constructor(address[] memory _addresses) public {
        btc = _addresses[0];
        bnb = _addresses[1];
        busd = _addresses[2];

        bnbBusdPair = _addresses[3];
        btcBnbPair = _addresses[4];
    }

    function getPair(address tokenA, address tokenB)
        external
        view
        override
        returns (address)
    {
        if (tokenA == busd && tokenB == bnb) {
            return bnbBusdPair;
        }
        if (tokenA == bnb && tokenB == btc) {
            return btcBnbPair;
        }
        revert("Invalid tokens");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/Token.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IPancakeRouter.sol";

contract PancakeRouter is IPancakeRouter {
    address public pair;

    constructor(address _pair) public {
        pair = _pair;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256, /*amountAMin*/
        uint256, /*amountBMin*/
        address to,
        uint256 deadline
    )
        external
        override
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        require(deadline >= block.timestamp, "PancakeRouter: EXPIRED");

        Token(pair).mint(to, 1000);

        IERC20(tokenA).transferFrom(msg.sender, pair, amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountBDesired);

        amountA = amountADesired;
        amountB = amountBDesired;
        liquidity = 1000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.9.0;

interface IPositionManagerClient {
    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external;

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external payable;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external;

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external;

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRouterClient {
    function approvePlugin(address _plugin) external;
}

/// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";

import "../libraries/access/Ownable.sol";

import "./interfaces/IPositionManagerClient.sol";
import "./interfaces/IRouterClient.sol";


contract PositionManagerClient is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public positionManager;
    address public router;


    function initialize(address _positionManager,address _router) external onlyOwner {
        require(_positionManager != address(0), "Address not valid.");
        require(_router != address(0), "Address not valid.");
        positionManager = _positionManager;
        router = _router;
        IRouterClient(router).approvePlugin(positionManager);
    }
    receive() external payable {}

    function setPositionManager(address _positionManager) public onlyOwner {
        require(_positionManager != address(0), "Address not valid.");
        positionManager = _positionManager;
    }

    function setRouter(address _router) public onlyOwner {
        require(_router != address(0), "Address not valid.");
        router = _router;
    }

    function setRouterApprovePlugin() public onlyOwner {
        IRouterClient(router).approvePlugin(positionManager);
    }

    function approve(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).approve(router, _amount);
    }


    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external  {
        IPositionManagerClient(positionManager).increasePosition(
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _price,
            _referralCode
        );
    }

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external payable  {
        IPositionManagerClient(positionManager).increasePositionETH{value:msg.value}(
            _path,
            _indexToken,
            _minOut,
            _sizeDelta,
            _isLong,
            _price,
            _referralCode
        );
    }

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external  {
        IPositionManagerClient(positionManager).decreasePosition(
         _collateralToken,
         _indexToken,
         _collateralDelta,
         _sizeDelta,
         _isLong,
         _receiver,
         _price
        );
    }

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external  {
        IPositionManagerClient(positionManager).decreasePositionETH(
         _collateralToken,
         _indexToken,
         _collateralDelta,
         _sizeDelta,
         _isLong,
         _receiver,
         _price
        );
    }

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external {
        IPositionManagerClient(positionManager).decreasePositionAndSwap(
        _path,
        _indexToken,
        _collateralDelta,
        _sizeDelta,
        _isLong,
        _receiver,
        _price,
        _minOut
        );
    }

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external  {
        IPositionManagerClient(positionManager).decreasePositionAndSwapETH(
        _path,
        _indexToken,
        _collateralDelta,
        _sizeDelta,
        _isLong,
        _receiver,
        _price,
        _minOut
        );
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderBook.sol";
import "./interfaces/IBasePositionManager.sol";

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

import "../referrals/interfaces/IReferralStorage.sol";

contract BasePositionManager is IBasePositionManager, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public admin;

    address public vault;
    address public router;
    address public weth;

    // to prevent using the deposit and withdrawal of collateral as a zero fee swap,
    // there is a small depositFee charged if a collateral deposit results in the decrease
    // of leverage for an existing position
    // increasePositionBufferBps allows for a small amount of decrease of leverage
    uint256 public depositFee;
    uint256 public increasePositionBufferBps = 100;

    address public referralStorage;

    mapping(address => uint256) public feeReserves;

    mapping(address => uint256) public override maxGlobalLongSizes;
    mapping(address => uint256) public override maxGlobalShortSizes;

    event SetDepositFee(uint256 depositFee);
    event SetIncreasePositionBufferBps(uint256 increasePositionBufferBps);
    event SetReferralStorage(address referralStorage);
    event SetAdmin(address admin);
    event WithdrawFees(address token, address receiver, uint256 amount);

    event SetMaxGlobalSizes(address[] tokens, uint256[] longSizes, uint256[] shortSizes);

    event IncreasePositionReferral(address account, uint256 sizeDelta, uint256 marginFeeBasisPoints, bytes32 referralCode, address referrer);

    event DecreasePositionReferral(address account, uint256 sizeDelta, uint256 marginFeeBasisPoints, bytes32 referralCode, address referrer);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BasePositionManager: forbidden");
        _;
    }

    constructor(
        address _vault,
        address _router,
        address _weth,
        uint256 _depositFee
    ) public {
        vault = _vault;
        router = _router;
        weth = _weth;
        depositFee = _depositFee;

        admin = msg.sender;
    }

    receive() external payable {
        require(msg.sender == weth, "BasePositionManager: invalid sender");
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function setDepositFee(uint256 _depositFee) external onlyAdmin {
        depositFee = _depositFee;
        emit SetDepositFee(_depositFee);
    }

    function setIncreasePositionBufferBps(uint256 _increasePositionBufferBps) external onlyAdmin {
        increasePositionBufferBps = _increasePositionBufferBps;
        emit SetIncreasePositionBufferBps(_increasePositionBufferBps);
    }

    function setReferralStorage(address _referralStorage) external onlyAdmin {
        referralStorage = _referralStorage;
        emit SetReferralStorage(_referralStorage);
    }

    function setMaxGlobalSizes(
        address[] memory _tokens,
        uint256[] memory _longSizes,
        uint256[] memory _shortSizes
    ) external onlyAdmin {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            maxGlobalLongSizes[token] = _longSizes[i];
            maxGlobalShortSizes[token] = _shortSizes[i];
        }

        emit SetMaxGlobalSizes(_tokens, _longSizes, _shortSizes);
    }

    function withdrawFees(address _token, address _receiver) external onlyAdmin {
        uint256 amount = feeReserves[_token];
        if (amount == 0) {
            return;
        }

        feeReserves[_token] = 0;
        IERC20(_token).safeTransfer(_receiver, amount);

        emit WithdrawFees(_token, _receiver, amount);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).approve(_spender, _amount);
    }

    function sendValue(address payable _receiver, uint256 _amount) external onlyGov {
        _receiver.sendValue(_amount);
    }

    function _increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) internal {
        address _vault = vault;

        if (_isLong) {
            require(IVault(_vault).getMaxPrice(_indexToken) <= _price, "BasePositionManager: mark price higher than limit");
        } else {
            require(IVault(_vault).getMinPrice(_indexToken) >= _price, "BasePositionManager: mark price lower than limit");
        }

        if (_isLong) {
            uint256 maxGlobalLongSize = maxGlobalLongSizes[_indexToken];
            if (maxGlobalLongSize > 0 && IVault(_vault).guaranteedUsd(_indexToken).add(_sizeDelta) > maxGlobalLongSize) {
                revert("BasePositionManager: max global longs exceeded");
            }
        } else {
            uint256 maxGlobalShortSize = maxGlobalShortSizes[_indexToken];
            if (maxGlobalShortSize > 0 && IVault(_vault).globalShortSizes(_indexToken).add(_sizeDelta) > maxGlobalShortSize) {
                revert("BasePositionManager: max global shorts exceeded");
            }
        }

        address timelock = IVault(_vault).gov();

        ITimelock(timelock).enableLeverage(_vault);
        IRouter(router).pluginIncreasePosition(_account, _collateralToken, _indexToken, _sizeDelta, _isLong);
        ITimelock(timelock).disableLeverage(_vault);

        _emitIncreasePositionReferral(_account, _sizeDelta);
    }

    function _decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) internal returns (uint256) {
        address _vault = vault;

        if (_isLong) {
            require(IVault(_vault).getMinPrice(_indexToken) >= _price, "BasePositionManager: mark price lower than limit");
        } else {
            require(IVault(_vault).getMaxPrice(_indexToken) <= _price, "BasePositionManager: mark price higher than limit");
        }

        address timelock = IVault(_vault).gov();

        ITimelock(timelock).enableLeverage(_vault);
        uint256 amountOut = IRouter(router).pluginDecreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
        ITimelock(timelock).disableLeverage(_vault);

        _emitDecreasePositionReferral(_account, _sizeDelta);

        return amountOut;
    }

    function _emitIncreasePositionReferral(address _account, uint256 _sizeDelta) internal {
        address _referralStorage = referralStorage;
        if (_referralStorage == address(0)) {
            return;
        }

        (bytes32 referralCode, address referrer) = IReferralStorage(_referralStorage).getTraderReferralInfo(_account);
        emit IncreasePositionReferral(_account, _sizeDelta, IVault(vault).marginFeeBasisPoints(), referralCode, referrer);
    }

    function _emitDecreasePositionReferral(address _account, uint256 _sizeDelta) internal {
        address _referralStorage = referralStorage;
        if (_referralStorage == address(0)) {
            return;
        }

        (bytes32 referralCode, address referrer) = IReferralStorage(_referralStorage).getTraderReferralInfo(_account);

        if (referralCode == bytes32(0)) {
            return;
        }

        emit DecreasePositionReferral(_account, _sizeDelta, IVault(vault).marginFeeBasisPoints(), referralCode, referrer);
    }

    function _swap(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) internal returns (uint256) {
        if (_path.length == 2) {
            return _vaultSwap(_path[0], _path[1], _minOut, _receiver);
        }
        revert("BasePositionManager: invalid _path.length");
    }

    function _vaultSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _minOut,
        address _receiver
    ) internal returns (uint256) {
        uint256 amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        require(amountOut >= _minOut, "BasePositionManager: insufficient amountOut");
        return amountOut;
    }

    function _transferInETH() internal {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) internal {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }

    function _transferOutETHWithGasLimit(uint256 _amountOut, address payable _receiver) internal {
        IWETH(weth).withdraw(_amountOut);
        _receiver.transfer(_amountOut);
    }

    function _collectFees(
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) internal returns (uint256) {
        bool shouldDeductFee = _shouldDeductFee(_account, _path, _amountIn, _indexToken, _isLong, _sizeDelta);

        if (shouldDeductFee) {
            uint256 afterFeeAmount = _amountIn.mul(BASIS_POINTS_DIVISOR.sub(depositFee)).div(BASIS_POINTS_DIVISOR);
            uint256 feeAmount = _amountIn.sub(afterFeeAmount);
            address feeToken = _path[_path.length - 1];
            feeReserves[feeToken] = feeReserves[feeToken].add(feeAmount);
            return afterFeeAmount;
        }

        return _amountIn;
    }

    function _shouldDeductFee(
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) internal view returns (bool) {
        // if the position is a short, do not charge a fee
        if (!_isLong) {
            return false;
        }

        // if the position size is not increasing, this is a collateral deposit
        if (_sizeDelta == 0) {
            return true;
        }

        address collateralToken = _path[_path.length - 1];

        IVault _vault = IVault(vault);
        (uint256 size, uint256 collateral, , , , , , ) = _vault.getPosition(_account, collateralToken, _indexToken, _isLong);

        // if there is no existing position, do not charge a fee
        if (size == 0) {
            return false;
        }

        uint256 nextSize = size.add(_sizeDelta);
        uint256 collateralDelta = _vault.tokenToUsdMin(collateralToken, _amountIn);
        uint256 nextCollateral = collateral.add(collateralDelta);

        uint256 prevLeverage = size.mul(BASIS_POINTS_DIVISOR).div(collateral);
        // allow for a maximum of a increasePositionBufferBps decrease since there might be some swap fees taken from the collateral
        uint256 nextLeverage = nextSize.mul(BASIS_POINTS_DIVISOR + increasePositionBufferBps).div(nextCollateral);

        // deduct a fee if the leverage is decreased
        return nextLeverage < prevLeverage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBasePositionManager {
    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.9.0;

interface IOrderBook {
    function getSwapOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeDecreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeIncreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function getShouldExecuteOrderList(
        bool _returnFirst
    ) external view returns (
            bool ,
            uint160[] memory); 


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.9.0;

interface IOrderBookForReader {
    function getSwapOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrderV2(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            address receiveToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );        




}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPositionRouter {

    function increasePositionRequestKeysStart() external returns (uint256);
    function decreasePositionRequestKeysStart() external returns (uint256);

    function executeIncreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint256 _count,
        address payable _executionFeeReceiver
    ) external;

    function getRequestQueueLengths()  external view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRouter {
    function addPlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IShortsTracker {
    function isGlobalShortDataReady() external view returns (bool);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function getNextGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view returns (uint256, uint256);
    function updateGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISlpManager {
    function usds() external view returns (address);
    function cooldownDuration() external returns (uint256);
    function setCooldownDuration(uint256 _cooldownDuration) external;

    function lastAddedAt(address _account) external returns (uint256);

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsds,
        uint256 _minSlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsds,
        uint256 _minSlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IVaultUtils.sol";

interface IVault {
    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usds() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdsAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdsAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdsAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDS(address _token, address _receiver) external returns (uint256);

    function sellUSDS(address _token, address _receiver) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdsDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(address _token) external view returns (uint256);

    function maxGlobalShortSizes(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdsAmounts(address _token) external view returns (uint256);

    function maxUsdsAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdsAmount) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token)
        external
        view
        returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise)
        external
        view
        returns (uint256);

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external;

    function getLatestPrimaryPrice(address _token) external view returns (uint256);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVaultUtils {
    function updateCumulativeFundingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);

    function validateIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external view;

    function validateDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external view;

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getFundingFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getBuyUsdsFeeBasisPoints(address _token, uint256 _usdsAmount)
        external
        view
        returns (uint256);

    function getSellUsdsFeeBasisPoints(address _token, uint256 _usdsAmount)
        external
        view
        returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdsAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdsDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../tokens/interfaces/IWETH.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/IterableMapping.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderBook.sol";


contract OrderBook is ReentrancyGuard, IOrderBook {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    uint256 public constant PRICE_PRECISION = 1e30;
    uint256 public constant USDS_PRECISION = 1e18;


    itmap public orderList;
    // Apply library functions to the data type.
    using IterableMapping for itmap;


    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }
    struct DecreaseOrder {
        address account;
        address collateralToken;
        address receiveToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 minOut;
        bool withdrawETH;
        uint256 executionFee;
    }
    struct SwapOrder {
        address account;
        address[] path;
        uint256 amountIn;
        uint256 minOut;
        uint256 triggerRatio;
        bool triggerAboveThreshold;
        bool shouldUnwrap;
        uint256 executionFee;
    }

    mapping(address => mapping(uint256 => IncreaseOrder)) public increaseOrders;
    mapping(address => uint256) public increaseOrdersIndex;
    mapping(address => mapping(uint256 => DecreaseOrder)) public decreaseOrders;
    mapping(address => uint256) public decreaseOrdersIndex;
    mapping(address => mapping(uint256 => SwapOrder)) public swapOrders;
    mapping(address => uint256) public swapOrdersIndex;

    address public gov;
    address public weth;
    address public usds;
    address public router;
    address public vault;
    address public orderExecutor;


    uint256 public minExecutionFee;
    uint256 public minPurchaseTokenAmountUsd;
    bool public isInitialized = false;
    bool public chainlinkOrderExecutionActive = false;

    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address receiveToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );

    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event CancelSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event UpdateSwapOrder(
        address indexed account,
        uint256 ordexIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );
    event ExecuteSwapOrder(
        address indexed account,
        uint256 orderIndex,
        address[] path,
        uint256 amountIn,
        uint256 minOut,
        uint256 amountOut,
        uint256 triggerRatio,
        bool triggerAboveThreshold,
        bool shouldUnwrap,
        uint256 executionFee
    );

    constructor() public {
        gov = msg.sender;
    }

    function _onlyGov() private view {
        require(msg.sender == gov, "OB: forbidden");
    }

    function _onlyOrderExecutor() private view {
        require(msg.sender == orderExecutor, "OB: forbidden");
    }

    function initialize(
        address _router,
        address _vault,
        address _weth,
        address _usds,
        uint256 _minExecutionFee,
        uint256 _minPurchaseTokenAmountUsd
    ) external {
        _onlyGov();
        require(!isInitialized, "OB: error");
        isInitialized = true;

        router = _router;
        vault = _vault;
        weth = _weth;
        usds = _usds;
        minExecutionFee = _minExecutionFee;
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

    }

    receive() external payable {
        require(msg.sender == weth, "OB: invalid sender");
    }

    function setOrderExecutor(
        address _orderExecutor
    )external  {
        _onlyGov();
        orderExecutor = _orderExecutor;

    }

    function _addToOpenOrders(address _account, uint256 _index, OrderType _type) internal {
        uint256 orderKey = getOrderKey(_account,  _index,  _type);
        Orders memory order = Orders(
            _account,
            _index,
            _type
        );
        orderList.insert(orderKey,order);
    }

    function _removeFromOpenOrders(address _account, uint256 _index, OrderType _type) internal {
        uint256 orderKey = getOrderKey(_account,  _index,  _type);
        orderList.remove(orderKey);
    }

    function getOrderKey(address _account, uint256 _index, OrderType _type) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_account, _index, _type)));
    }


    function setMinExecutionFee(uint256 _minExecutionFee) external  {
        _onlyGov();
        minExecutionFee = _minExecutionFee;

    }
    function setChainlinkOrderExecutionActive(bool _chainlinkOrderExecutionActive) external  {
        _onlyGov();
        chainlinkOrderExecutionActive = _chainlinkOrderExecutionActive;


    }
    function setMinPurchaseTokenAmountUsd(uint256 _minPurchaseTokenAmountUsd) external  {
        _onlyGov();
        minPurchaseTokenAmountUsd = _minPurchaseTokenAmountUsd;

    }

    function setGov(address _gov) external  {
        _onlyGov();
        gov = _gov;

    }

    function getSwapOrder(address _account, uint256 _orderIndex)
        public
        view
        override
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        )
    {
        SwapOrder memory order = swapOrders[_account][_orderIndex];
        return (
            order.path.length > 0 ? order.path[0] : address(0),
            order.path.length > 1 ? order.path[1] : address(0),
            order.path.length > 2 ? order.path[2] : address(0),
            order.amountIn,
            order.minOut,
            order.triggerRatio,
            order.triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable nonReentrant {
        require(_path.length == 2 || _path.length == 3, "OB: invalid _path.length");
        require(_path[0] != _path[_path.length - 1], "OB: invalid _path");
        require(_path[0] != usds && _path[_path.length - 1] != usds, "OB: invalid token");
        require(_amountIn > 0, "OB: invalid _amountIn");
        require(_executionFee >= minExecutionFee, "OB: insufficient execution fee");

        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();

        if (_shouldWrap) {
            require(_path[0] == weth, "OB: only weth could be wrapped");
            require(msg.value == _executionFee.add(_amountIn), "OB: incorrect value transferred");
        } else {
            require(msg.value == _executionFee, "OB: incorrect execution fee transferred");
            IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
        }

        _createSwapOrder(msg.sender, _path, _amountIn, _minOut, _triggerRatio, _triggerAboveThreshold, _shouldUnwrap, _executionFee);
    }

    function _createSwapOrder(
        address _account,
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold,
        bool _shouldUnwrap,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = swapOrdersIndex[_account];
        SwapOrder memory order = SwapOrder(_account, _path, _amountIn, _minOut, _triggerRatio, _triggerAboveThreshold, _shouldUnwrap, _executionFee);
        swapOrdersIndex[_account] = _orderIndex.add(1);
        swapOrders[_account][_orderIndex] = order;
        _addToOpenOrders(_account,_orderIndex,OrderType.SWAP); 

        emit CreateSwapOrder(_account, _orderIndex, _path, _amountIn, _minOut, _triggerRatio, _triggerAboveThreshold, _shouldUnwrap, _executionFee);
    }

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external {
        for (uint256 i = 0; i < _swapOrderIndexes.length; i++) {
            cancelSwapOrder(_swapOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _increaseOrderIndexes.length; i++) {
            cancelIncreaseOrder(_increaseOrderIndexes[i]);
        }
        for (uint256 i = 0; i < _decreaseOrderIndexes.length; i++) {
            cancelDecreaseOrder(_decreaseOrderIndexes[i]);
        }
    }

    function cancelSwapOrder(uint256 _orderIndex) public nonReentrant {
        SwapOrder memory order = swapOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        delete swapOrders[msg.sender][_orderIndex];
        _removeFromOpenOrders(msg.sender,_orderIndex,OrderType.SWAP); 

        if (order.path[0] == weth) {
            _transferOutETH(order.executionFee.add(order.amountIn), msg.sender);
        } else {
            IERC20(order.path[0]).safeTransfer(msg.sender, order.amountIn);
            _transferOutETH(order.executionFee, msg.sender);
        }

        emit CancelSwapOrder(
            msg.sender,
            _orderIndex,
            order.path,
            order.amountIn,
            order.minOut,
            order.triggerRatio,
            order.triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function validateSwapOrderPriceWithTriggerAboveThreshold(address[] memory _path, uint256 _triggerRatio) public view returns (bool) {
        require(_path.length == 2 || _path.length == 3, "OB: invalid _path.length");

        // limit orders don't need this validation because minOut is enough
        // so this validation handles scenarios for stop orders only
        // when a user wants to swap when a price of tokenB increases relative to tokenA
        address tokenA = _path[0];
        address tokenB = _path[_path.length - 1];
        uint256 tokenAPrice;
        uint256 tokenBPrice;

        tokenAPrice = IVault(vault).getMinPrice(tokenA);
        tokenBPrice = IVault(vault).getMaxPrice(tokenB);

        uint256 currentRatio = tokenBPrice.mul(PRICE_PRECISION).div(tokenAPrice);

        bool isValid = currentRatio > _triggerRatio;
        return isValid;
    }

    function updateSwapOrder(
        uint256 _orderIndex,
        uint256 _minOut,
        uint256 _triggerRatio,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        SwapOrder storage order = swapOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        order.minOut = _minOut;
        order.triggerRatio = _triggerRatio;
        order.triggerAboveThreshold = _triggerAboveThreshold;

        emit UpdateSwapOrder(msg.sender, _orderIndex, order.path, order.amountIn, _minOut, _triggerRatio, _triggerAboveThreshold, order.shouldUnwrap, order.executionFee);
    }

    function executeSwapOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external override nonReentrant {
        _onlyOrderExecutor();
        SwapOrder memory order = swapOrders[_account][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        if (order.triggerAboveThreshold) {
            // gas optimisation
            // order.minAmount should prevent wrong price execution in case of simple limit order
            require(validateSwapOrderPriceWithTriggerAboveThreshold(order.path, order.triggerRatio), "OB: invalid price for execution");
        }

        delete swapOrders[_account][_orderIndex];
        _removeFromOpenOrders(_account,_orderIndex,OrderType.SWAP);

        IERC20(order.path[0]).safeTransfer(vault, order.amountIn);

        uint256 _amountOut;
        if (order.path[order.path.length - 1] == weth && order.shouldUnwrap) {
            _amountOut = _swap(order.path, order.minOut, address(this));
            _transferOutETH(_amountOut, payable(order.account));
        } else {
            _amountOut = _swap(order.path, order.minOut, order.account);
        }

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteSwapOrder(
            _account,
            _orderIndex,
            order.path,
            order.amountIn,
            order.minOut,
            _amountOut,
            order.triggerRatio,
            order.triggerAboveThreshold,
            order.shouldUnwrap,
            order.executionFee
        );
    }

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) public view returns (uint256, bool) {
        uint256 currentPrice = _maximizePrice ? IVault(vault).getMaxPrice(_indexToken) : IVault(vault).getMinPrice(_indexToken);
        bool isPriceValid = _triggerAboveThreshold ? currentPrice > _triggerPrice : currentPrice < _triggerPrice;
        if (_raise) {
            require(isPriceValid, "OB: invalid price for execution");
        }
        return (currentPrice, isPriceValid);
    }

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        public
        view
        override
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        )
    {
        DecreaseOrder memory order = decreaseOrders[_account][_orderIndex];
        return (order.collateralToken, order.collateralDelta, order.indexToken, order.sizeDelta, order.isLong, order.triggerPrice, order.triggerAboveThreshold, order.executionFee);
    }

    function getDecreaseOrderV2(address _account, uint256 _orderIndex)
        public
        view
        returns (
            address collateralToken,
            address receiveToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        )
    {
        DecreaseOrder memory order = decreaseOrders[_account][_orderIndex];
        return (order.collateralToken, order.receiveToken, order.collateralDelta, order.indexToken, order.sizeDelta, order.isLong, order.triggerPrice, order.triggerAboveThreshold, order.executionFee);
    }

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        public
        view
        override
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        )
    {
        IncreaseOrder memory order = increaseOrders[_account][_orderIndex];
        return (
            order.purchaseToken,
            order.purchaseTokenAmount,
            order.collateralToken,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable nonReentrant {
        // always need this call because of mandatory executionFee user has to transfer in ETH
        _transferInETH();

        require(_executionFee >= minExecutionFee, "OB: insufficient execution fee");
        if (_shouldWrap) {
            require(_path[0] == weth, "OB: only weth could be wrapped");
            require(msg.value == _executionFee.add(_amountIn), "OB: incorrect value transferred");
        } else {
            require(msg.value == _executionFee, "OB: incorrect execution fee transferred");
            IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
        }

        address _purchaseToken = _path[_path.length - 1];
        uint256 _purchaseTokenAmount;
        if (_path.length > 1) {
            require(_path[0] != _purchaseToken, "OB: invalid _path");
            IERC20(_path[0]).safeTransfer(vault, _amountIn);
            _purchaseTokenAmount = _swap(_path, _minOut, address(this));
        } else {
            _purchaseTokenAmount = _amountIn;
        }

        {
            uint256 _purchaseTokenAmountUsd = IVault(vault).tokenToUsdMin(_purchaseToken, _purchaseTokenAmount);
            require(_purchaseTokenAmountUsd >= minPurchaseTokenAmountUsd, "OB: insufficient collateral");
        }

        _createIncreaseOrder(
            msg.sender,
            _purchaseToken,
            _purchaseTokenAmount,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
    }

    function _createIncreaseOrder(
        address _account,
        address _purchaseToken,
        uint256 _purchaseTokenAmount,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = increaseOrdersIndex[_account];
        IncreaseOrder memory order = IncreaseOrder(
            _account,
            _purchaseToken,
            _purchaseTokenAmount,
            _collateralToken,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee
        );
        increaseOrdersIndex[_account] = _orderIndex.add(1);
        increaseOrders[_account][_orderIndex] = order;
        _addToOpenOrders(_account,_orderIndex,OrderType.INCREASE);
            emit CreateIncreaseOrder(
                _account,
                _orderIndex,
                _purchaseToken,
                _purchaseTokenAmount,
                _collateralToken,
                _indexToken,
                _sizeDelta,
                _isLong,
                _triggerPrice,
                _triggerAboveThreshold,
                _executionFee
            );
    }

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        IncreaseOrder storage order = increaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.sizeDelta = _sizeDelta;

        emit UpdateIncreaseOrder(msg.sender, _orderIndex, order.collateralToken, order.indexToken, order.isLong, _sizeDelta, _triggerPrice, _triggerAboveThreshold);
    }

    function cancelIncreaseOrder(uint256 _orderIndex) public nonReentrant {
        IncreaseOrder memory order = increaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        delete increaseOrders[msg.sender][_orderIndex];
        _removeFromOpenOrders(msg.sender,_orderIndex,OrderType.INCREASE);

        if (order.purchaseToken == weth) {
            _transferOutETH(order.executionFee.add(order.purchaseTokenAmount), msg.sender);
        } else {
            IERC20(order.purchaseToken).safeTransfer(msg.sender, order.purchaseTokenAmount);
            _transferOutETH(order.executionFee, msg.sender);
        }

        emit CancelIncreaseOrder(
            order.account,
            _orderIndex,
            order.purchaseToken,
            order.purchaseTokenAmount,
            order.collateralToken,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function executeIncreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external override nonReentrant {
        _onlyOrderExecutor();
        IncreaseOrder memory order = increaseOrders[_address][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        // increase long should use max price
        // increase short should use min price
        (uint256 currentPrice, ) = validatePositionOrderPrice(order.triggerAboveThreshold, order.triggerPrice, order.indexToken, order.isLong, true);

        delete increaseOrders[_address][_orderIndex];
        _removeFromOpenOrders(_address,_orderIndex,OrderType.INCREASE);

        IERC20(order.purchaseToken).safeTransfer(vault, order.purchaseTokenAmount);

        if (order.purchaseToken != order.collateralToken) {
            address[] memory path = new address[](2);
            path[0] = order.purchaseToken;
            path[1] = order.collateralToken;

            uint256 amountOut = _swap(path, 0, address(this));
            IERC20(order.collateralToken).safeTransfer(vault, amountOut);
        }

        IRouter(router).pluginIncreasePosition(order.account, order.collateralToken, order.indexToken, order.sizeDelta, order.isLong);

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteIncreaseOrder(
            order.account,
            _orderIndex,
            order.purchaseToken,
            order.purchaseTokenAmount,
            order.collateralToken,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        address _receiveToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _minOut,
        bool _withdrawETH
    ) external payable nonReentrant {

        _transferInETH();
        
        require(msg.value > minExecutionFee, "OB: insufficient execution fee");
        if (_withdrawETH) {
            if(_receiveToken != address(0))
                require(_receiveToken == weth, "OB: invalid _receiveToken");
            else   
                require(_collateralToken == weth, "OB: invalid _collateralToken");  
        }

        

        _createDecreaseOrder(msg.sender, _collateralToken,_receiveToken, _collateralDelta, _indexToken, _sizeDelta, _isLong, _triggerPrice, _triggerAboveThreshold, _minOut, _withdrawETH);
    }

    function _createDecreaseOrder(
        address _account,
        address _collateralToken,
        address _receiveToken,
        uint256 _collateralDelta,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _minOut,
        bool _withdrawETH
    ) private {
        uint256 _orderIndex = decreaseOrdersIndex[_account];
        DecreaseOrder memory order = DecreaseOrder(
            _account,
            _collateralToken,
            _receiveToken,
            _collateralDelta,
            _indexToken,
            _sizeDelta,
            _isLong,
            _triggerPrice,
            _triggerAboveThreshold,
            _minOut,
            _withdrawETH,
            msg.value
        );
        decreaseOrdersIndex[_account] = _orderIndex.add(1);
        decreaseOrders[_account][_orderIndex] = order;
        _addToOpenOrders(_account,_orderIndex,OrderType.DECREASE);

        emit CreateDecreaseOrder(_account, _orderIndex, _collateralToken, _receiveToken, _collateralDelta, _indexToken, _sizeDelta, _isLong, _triggerPrice, _triggerAboveThreshold, msg.value);

    }

    function executeDecreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external override nonReentrant {
        _onlyOrderExecutor();
        DecreaseOrder memory order = decreaseOrders[_address][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        // decrease long should use min price
        // decrease short should use max price
        (uint256 currentPrice, ) = validatePositionOrderPrice(order.triggerAboveThreshold, order.triggerPrice, order.indexToken, !order.isLong, true);

        delete decreaseOrders[_address][_orderIndex];
        _removeFromOpenOrders(_address,_orderIndex,OrderType.DECREASE);

        uint256 amountOut = IRouter(router).pluginDecreasePosition(
            order.account,
            order.collateralToken,
            order.indexToken,
            order.collateralDelta,
            order.sizeDelta,
            order.isLong,
            address(this)
        );

        if (order.receiveToken != address(0)) {
            IERC20(order.collateralToken).safeTransfer(vault, amountOut);
            amountOut = _vaultSwap(order.collateralToken, order.receiveToken, order.minOut, address(this));
        }

        if (order.withdrawETH) {
            _transferOutETHWithGasLimit(amountOut, payable(order.account));
        } else {
            if (order.receiveToken != address(0)) {
                IERC20(order.receiveToken).safeTransfer(order.account, amountOut);
            }else{
                IERC20(order.collateralToken).safeTransfer(order.account, amountOut);
            }    
        }

        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteDecreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    function cancelDecreaseOrder(uint256 _orderIndex) public nonReentrant {
        DecreaseOrder memory order = decreaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        delete decreaseOrders[msg.sender][_orderIndex];
        _removeFromOpenOrders(msg.sender,_orderIndex,OrderType.DECREASE);
        _transferOutETH(order.executionFee, msg.sender);

        emit CancelDecreaseOrder(
            order.account,
            _orderIndex,
            order.collateralToken,
            order.collateralDelta,
            order.indexToken,
            order.sizeDelta,
            order.isLong,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee
        );
    }

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external nonReentrant {
        DecreaseOrder storage order = decreaseOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OB: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.sizeDelta = _sizeDelta;
        order.collateralDelta = _collateralDelta;

        emit UpdateDecreaseOrder(
            msg.sender,
            _orderIndex,
            order.collateralToken,
            _collateralDelta,
            order.indexToken,
            _sizeDelta,
            order.isLong,
            _triggerPrice,
            _triggerAboveThreshold
        );
    }

    function _transferInETH() private {
        if (msg.value != 0) {
            IWETH(weth).deposit{value: msg.value}();
        }
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }
    function _transferOutETHWithGasLimit(uint256 _amountOut, address payable _receiver) internal {
        IWETH(weth).withdraw(_amountOut);
        _receiver.transfer(_amountOut);
    }

    function _swap(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        if (_path.length == 2) {
            return _vaultSwap(_path[0], _path[1], _minOut, _receiver);
        }
        if (_path.length == 3) {
            uint256 midOut = _vaultSwap(_path[0], _path[1], 0, address(this));
            IERC20(_path[1]).safeTransfer(vault, midOut);
            return _vaultSwap(_path[1], _path[2], _minOut, _receiver);
        }

        revert("OB: invalid _path.length");
    }

    function _vaultSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        uint256 amountOut;

        // if (_tokenOut == usds) {
        //     // buyUSDS
        //     amountOut = IVault(vault).buyUSDS(_tokenIn, _receiver);
        // } else if (_tokenIn == usds) {
        //     // sellUSDS
        //     amountOut = IVault(vault).sellUSDS(_tokenOut, _receiver);
        // } else {
            // swap
            amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        // }

        require(amountOut >= _minOut, "OB: insufficient amountOut");
        return amountOut;
    }

   function getShouldExecuteOrderList(bool _returnFirst
    ) external override view returns (bool ,uint160[] memory) {
        if(!chainlinkOrderExecutionActive){
            return(false,new uint160[](0));
        }

        uint256 orderListSize = orderList.size;
        uint160[] memory shouldExecuteOrders = new uint160[](orderListSize*3);
        uint256 shouldExecuteIndex = 0;

        if(orderListSize>0){

            for (
                uint i = orderList.iterate_start();
                orderList.iterate_valid(i);
                i = orderList.iterate_next(i)
            ) {
                (, Orders memory order) = orderList.iterate_get(i);
                bool shouldExecute =false;

                if (order.orderType == OrderType.SWAP){
                    SwapOrder memory swapOrder = swapOrders[order.account][order.orderIndex];
                    shouldExecute = !validateSwapOrderPriceWithTriggerAboveThreshold(swapOrder.path, swapOrder.triggerRatio);
                }
                else if (order.orderType == OrderType.INCREASE){
                    IncreaseOrder memory increaseOrder = increaseOrders[order.account][order.orderIndex];
                    (, shouldExecute ) = validatePositionOrderPrice(increaseOrder.triggerAboveThreshold, increaseOrder.triggerPrice, increaseOrder.indexToken, increaseOrder.isLong, false);
                }else if (order.orderType == OrderType.DECREASE){
                    DecreaseOrder memory decreaseOrder = decreaseOrders[order.account][order.orderIndex];
                    (uint256 size, , , , , , , ) = IVault(vault).getPosition(decreaseOrder.account, decreaseOrder.collateralToken, decreaseOrder.indexToken, decreaseOrder.isLong);
                    if(size>0){
                        (, shouldExecute ) = validatePositionOrderPrice(decreaseOrder.triggerAboveThreshold, decreaseOrder.triggerPrice, decreaseOrder.indexToken, !decreaseOrder.isLong, false);
                    }    
                }
                if (shouldExecute){
                    if(_returnFirst){
                        return(true,new uint160[](0));
                    }
                    shouldExecuteOrders[shouldExecuteIndex*3] = uint160(order.account);
                    shouldExecuteOrders[shouldExecuteIndex*3+1] = uint160(order.orderIndex);
                    shouldExecuteOrders[shouldExecuteIndex*3+2] = uint160(order.orderType);
                    shouldExecuteIndex++;
                }                
            }
        }

        uint160[] memory returnList = new uint160[](shouldExecuteIndex*3); 

        for (uint256 i = 0; i < shouldExecuteIndex*3; i++) {
            returnList[i]=shouldExecuteOrders[i];
        }
        
        return (shouldExecuteIndex>0,returnList);
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderBook.sol";

import "../peripherals/interfaces/ITimelock.sol";
import "./BasePositionManager.sol";

contract PositionManager is BasePositionManager {
    address public orderBook;
    bool public inLegacyMode;

    bool public shouldValidateIncreaseOrder = true;
    uint256 public minStayingOpenTime = 900; // 15 min
    

    mapping(address => bool) public isOrderKeeper;
    mapping(address => bool) public isPartner;
    mapping(address => bool) public isLiquidator;
    mapping(address => uint256) public partnerMinStayingOpenTime;

    event SetOrderKeeper(address indexed account, bool isActive);
    event SetLiquidator(address indexed account, bool isActive);
    event SetPartner(address account, bool isActive);
    event SetOrderBook(address orderBook);
    event SetInLegacyMode(bool inLegacyMode);
    event SetShouldValidateIncreaseOrder(bool shouldValidateIncreaseOrder);
    event SetMinStayingOpenTime(uint256 _minStayingOpenTime);
    event SetPartnerMinStayingOpenTime(address account, uint256 minTime);

    modifier onlyOrderKeeper() {
        require(isOrderKeeper[msg.sender], "PositionManager: forbidden");
        _;
    }

    modifier onlyLiquidator() {
        require(isLiquidator[msg.sender], "PositionManager: forbidden");
        _;
    }

    modifier onlyPartnersOrLegacyMode() {
        require(isPartner[msg.sender] || inLegacyMode, "PositionManager: forbidden");
        _;
    }

    constructor(
        address _vault,
        address _router,
        address _weth,
        uint256 _depositFee,
        address _orderBook
    ) public BasePositionManager(_vault, _router, _weth, _depositFee) {
        orderBook = _orderBook;
    }

    function setOrderKeeper(address _account, bool _isActive) external onlyAdmin {
        isOrderKeeper[_account] = _isActive;
        emit SetOrderKeeper(_account, _isActive);
    }

    function setLiquidator(address _account, bool _isActive) external onlyAdmin {
        isLiquidator[_account] = _isActive;
        emit SetLiquidator(_account, _isActive);
    }

    function setPartnerMinStayingOpenTime(address _account, uint256 _minTime) external onlyAdmin {
        partnerMinStayingOpenTime[_account] = _minTime;
        emit SetPartnerMinStayingOpenTime(_account, _minTime);
    }

    function setPartner(address _account, bool _isActive) external onlyAdmin {
        isPartner[_account] = _isActive;
        emit SetPartner(_account, _isActive);
    }


    function setOrderBook(address _orderBook) external onlyAdmin {
        orderBook = _orderBook;
        emit SetOrderBook(_orderBook);
    }

    function setMinStayingOpenTime(
        uint256 _minStayingOpenTime
    ) external onlyAdmin {
        minStayingOpenTime = _minStayingOpenTime;
        emit SetMinStayingOpenTime(_minStayingOpenTime);
    }

    function setInLegacyMode(bool _inLegacyMode) external onlyAdmin {
        inLegacyMode = _inLegacyMode;
        emit SetInLegacyMode(_inLegacyMode);
    }

    function setShouldValidateIncreaseOrder(bool _shouldValidateIncreaseOrder) external onlyAdmin {
        shouldValidateIncreaseOrder = _shouldValidateIncreaseOrder;
        emit SetShouldValidateIncreaseOrder(_shouldValidateIncreaseOrder);
    }

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 1 || _path.length == 2, "PositionManager: invalid _path.length");

        _setTraderReferralCode(_referralCode);

        if (_amountIn > 0) {
            if (_path.length == 1) {
                IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
            } else {
                IRouter(router).pluginTransfer(_path[0], msg.sender, vault, _amountIn);
                _amountIn = _swap(_path, _minOut, address(this));
            }

            uint256 afterFeeAmount = _collectFees(msg.sender, _path, _amountIn, _indexToken, _isLong, _sizeDelta);
            IERC20(_path[_path.length - 1]).safeTransfer(vault, afterFeeAmount);
        }

        _increasePosition(msg.sender, _path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price,
        bytes32 _referralCode
    ) external payable nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 1 || _path.length == 2, "PositionManager: invalid _path.length");
        require(_path[0] == weth, "PositionManager: invalid _path");

        _setTraderReferralCode(_referralCode);

        if (msg.value > 0) {
            _transferInETH();
            uint256 _amountIn = msg.value;

            if (_path.length > 1) {
                IERC20(weth).safeTransfer(vault, msg.value);
                _amountIn = _swap(_path, _minOut, address(this));
            }

            uint256 afterFeeAmount = _collectFees(msg.sender, _path, _amountIn, _indexToken, _isLong, _sizeDelta);
            IERC20(_path[_path.length - 1]).safeTransfer(vault, afterFeeAmount);
        }

        _increasePosition(msg.sender, _path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        _validatePositionTime(msg.sender, _collateralToken, _indexToken, _isLong);

        _decreasePosition(msg.sender, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver, _price);
    }

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_collateralToken == weth, "PositionManager: invalid _collateralToken");
       _validatePositionTime(msg.sender, _collateralToken, _indexToken, _isLong);

        uint256 amountOut = _decreasePosition(msg.sender, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        _transferOutETH(amountOut, _receiver);
    }

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 2, "PositionManager: invalid _path.length");
        _validatePositionTime(msg.sender, _path[0], _indexToken, _isLong);

        uint256 amount = _decreasePosition(msg.sender, _path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        _swap(_path, _minOut, _receiver);
    }

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external nonReentrant onlyPartnersOrLegacyMode {
        require(_path.length == 2, "PositionManager: invalid _path.length");
        require(_path[_path.length - 1] == weth, "PositionManager: invalid _path");
        _validatePositionTime(msg.sender, _path[0], _indexToken, _isLong);

        uint256 amount = _decreasePosition(msg.sender, _path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        uint256 amountOut = _swap(_path, _minOut, address(this));
        _transferOutETH(amountOut, _receiver);
    }

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external nonReentrant onlyLiquidator {
        address _vault = vault;
        address timelock = IVault(_vault).gov();

        ITimelock(timelock).enableLeverage(_vault);
        IVault(_vault).liquidatePosition(_account, _collateralToken, _indexToken, _isLong, _feeReceiver);
        ITimelock(timelock).disableLeverage(_vault);
    }

    function executeSwapOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external onlyOrderKeeper {
        IOrderBook(orderBook).executeSwapOrder(_account, _orderIndex, _feeReceiver);
    }

    function executeIncreaseOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external onlyOrderKeeper {
        uint256 sizeDelta = _validateIncreaseOrder(_account, _orderIndex);

        address _vault = vault;
        address timelock = IVault(_vault).gov();

        ITimelock(timelock).enableLeverage(_vault);
        IOrderBook(orderBook).executeIncreaseOrder(_account, _orderIndex, _feeReceiver);
        ITimelock(timelock).disableLeverage(_vault);

        _emitIncreasePositionReferral(_account, sizeDelta);
    }

    function executeDecreaseOrder(
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external onlyOrderKeeper {
        address _vault = vault;
        address timelock = IVault(_vault).gov();

        (
            ,
            ,
            ,
            // _collateralToken
            // _collateralDelta
            // _indexToken
            uint256 _sizeDelta, // _isLong // triggerPrice // triggerAboveThreshold // executionFee
            ,
            ,
            ,

        ) = IOrderBook(orderBook).getDecreaseOrder(_account, _orderIndex);

        ITimelock(timelock).enableLeverage(_vault);
        IOrderBook(orderBook).executeDecreaseOrder(_account, _orderIndex, _feeReceiver);
        ITimelock(timelock).disableLeverage(_vault);

        _emitDecreasePositionReferral(_account, _sizeDelta);
    }
    function _setTraderReferralCode(bytes32 _referralCode) internal {
        if (_referralCode != bytes32(0) && referralStorage != address(0)) {
            IReferralStorage(referralStorage).setTraderReferralCode(msg.sender, _referralCode);
        }
    }

    function _validateIncreaseOrder(address _account, uint256 _orderIndex) internal view returns (uint256) {
        (
            address _purchaseToken,
            uint256 _purchaseTokenAmount,
            address _collateralToken,
            address _indexToken,
            uint256 _sizeDelta,
            bool _isLong, // triggerPrice // triggerAboveThreshold // executionFee
            ,
            ,

        ) = IOrderBook(orderBook).getIncreaseOrder(_account, _orderIndex);

        if (!shouldValidateIncreaseOrder) {
            return _sizeDelta;
        }

        // shorts are okay
        if (!_isLong) {
            return _sizeDelta;
        }

        // if the position size is not increasing, this is a collateral deposit
        require(_sizeDelta > 0, "PositionManager: long deposit");

        IVault _vault = IVault(vault);
        (uint256 size, uint256 collateral, , , , , , ) = _vault.getPosition(_account, _collateralToken, _indexToken, _isLong);

        // if there is no existing position, do not charge a fee
        if (size == 0) {
            return _sizeDelta;
        }

        uint256 nextSize = size.add(_sizeDelta);
        uint256 collateralDelta = _vault.tokenToUsdMin(_purchaseToken, _purchaseTokenAmount);
        uint256 nextCollateral = collateral.add(collateralDelta);

        uint256 prevLeverage = size.mul(BASIS_POINTS_DIVISOR).div(collateral);
        // allow for a maximum of a increasePositionBufferBps decrease since there might be some swap fees taken from the collateral
        uint256 nextLeverageWithBuffer = nextSize.mul(BASIS_POINTS_DIVISOR + increasePositionBufferBps).div(nextCollateral);

        require(nextLeverageWithBuffer >= prevLeverage, "PositionManager: long leverage decrease");

        return _sizeDelta;
    }
    function _validatePositionTime(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private view{
        IVault _vault = IVault(vault);
        (uint256 size, , , , , , , uint lastIncreasedTime) = _vault.getPosition(_account, _collateralToken, _indexToken, _isLong);
        require(size > 0, "PositionManager: empty position");
        uint256 minDelayTime = partnerMinStayingOpenTime[_account]>0 ? partnerMinStayingOpenTime[_account] : minStayingOpenTime;
        require(lastIncreasedTime.add(minDelayTime) <= block.timestamp, "PositionManager: min delay not yet passed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPositionRouter.sol";

import "../peripherals/interfaces/ITimelock.sol";
import "./BasePositionManager.sol";

contract PositionRouter is BasePositionManager, IPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
    }

    uint256 public minExecutionFee;

    uint256 public minBlockDelayKeeper;
    uint256 public minTimeDelayPublic;
    uint256 public maxTimeDelay;

    bool public isLeverageEnabled = true;

    bytes32[] public increasePositionRequestKeys;
    bytes32[] public decreasePositionRequestKeys;

    uint256 public override increasePositionRequestKeysStart;
    uint256 public override decreasePositionRequestKeysStart;

    mapping(address => bool) public isPositionKeeper;

    mapping(address => uint256) public increasePositionsIndex;
    mapping(bytes32 => IncreasePositionRequest) public increasePositionRequests;

    mapping(address => uint256) public decreasePositionsIndex;
    mapping(bytes32 => DecreasePositionRequest) public decreasePositionRequests;

    event CreateIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockNumber,
        uint256 blockTime,
        uint256 gasPrice
    );

    event ExecuteIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event CancelIncreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 amountIn,
        uint256 minOut,
        uint256 sizeDelta,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event CreateDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 index,
        uint256 blockNumber,
        uint256 blockTime
    );

    event ExecuteDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event CancelDecreasePosition(
        address indexed account,
        address[] path,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        address receiver,
        uint256 acceptablePrice,
        uint256 minOut,
        uint256 executionFee,
        uint256 blockGap,
        uint256 timeGap
    );

    event SetPositionKeeper(address indexed account, bool isActive);
    event SetMinExecutionFee(uint256 minExecutionFee);
    event SetIsLeverageEnabled(bool isLeverageEnabled);
    event SetDelayValues(uint256 minBlockDelayKeeper, uint256 minTimeDelayPublic, uint256 maxTimeDelay);
    event SetRequestKeysStartValues(uint256 increasePositionRequestKeysStart, uint256 decreasePositionRequestKeysStart);

    modifier onlyPositionKeeper() {
        require(isPositionKeeper[msg.sender], "PositionRouter: forbidden");
        _;
    }

    constructor(
        address _vault,
        address _router,
        address _weth,
        uint256 _depositFee,
        uint256 _minExecutionFee
    ) public BasePositionManager(_vault, _router, _weth, _depositFee) {
        minExecutionFee = _minExecutionFee;
    }

    function setPositionKeeper(address _account, bool _isActive) external onlyAdmin {
        isPositionKeeper[_account] = _isActive;
        emit SetPositionKeeper(_account, _isActive);
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyAdmin {
        minExecutionFee = _minExecutionFee;
        emit SetMinExecutionFee(_minExecutionFee);
    }

    function setIsLeverageEnabled(bool _isLeverageEnabled) external onlyAdmin {
        isLeverageEnabled = _isLeverageEnabled;
        emit SetIsLeverageEnabled(_isLeverageEnabled);
    }

    function setDelayValues(
        uint256 _minBlockDelayKeeper,
        uint256 _minTimeDelayPublic,
        uint256 _maxTimeDelay
    ) external onlyAdmin {
        minBlockDelayKeeper = _minBlockDelayKeeper;
        minTimeDelayPublic = _minTimeDelayPublic;
        maxTimeDelay = _maxTimeDelay;
        emit SetDelayValues(_minBlockDelayKeeper, _minTimeDelayPublic, _maxTimeDelay);
    }

    function setRequestKeysStartValues(uint256 _increasePositionRequestKeysStart, uint256 _decreasePositionRequestKeysStart) external onlyAdmin {
        increasePositionRequestKeysStart = _increasePositionRequestKeysStart;
        decreasePositionRequestKeysStart = _decreasePositionRequestKeysStart;

        emit SetRequestKeysStartValues(_increasePositionRequestKeysStart, _decreasePositionRequestKeysStart);
    }

    function executeIncreasePositions(uint256 _endIndex, address payable _executionFeeReceiver) external override onlyPositionKeeper {
        uint256 index = increasePositionRequestKeysStart;
        uint256 length = increasePositionRequestKeys.length;

        if (index >= length) {
            return;
        }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = increasePositionRequestKeys[index];

            // if the request was executed then delete the key from the array
            // if the request was not executed then break from the loop, this can happen if the
            // minimum number of blocks has not yet passed
            // an error could be thrown if the request is too old or if the slippage is
            // higher than what the user specified, or if there is insufficient liquidity for the position
            // in case an error was thrown, cancel the request
            try this.executeIncreasePosition(key, _executionFeeReceiver) returns (bool _wasExecuted) {
                if (!_wasExecuted) {
                    break;
                }
            } catch {
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelIncreasePosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) {
                        break;
                    }
                } catch {}
            }

            delete increasePositionRequestKeys[index];
            index++;
        }

        increasePositionRequestKeysStart = index;
    }

    function executeDecreasePositions(uint256 _endIndex, address payable _executionFeeReceiver) external override onlyPositionKeeper {
        uint256 index = decreasePositionRequestKeysStart;
        uint256 length = decreasePositionRequestKeys.length;

        if (index >= length) {
            return;
        }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = decreasePositionRequestKeys[index];

            // if the request was executed then delete the key from the array
            // if the request was not executed then break from the loop, this can happen if the
            // minimum number of blocks has not yet passed
            // an error could be thrown if the request is too old
            // in case an error was thrown, cancel the request
            try this.executeDecreasePosition(key, _executionFeeReceiver) returns (bool _wasExecuted) {
                if (!_wasExecuted) {
                    break;
                }
            } catch {
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelDecreasePosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) {
                        break;
                    }
                } catch {}
            }

            delete decreasePositionRequestKeys[index];
            index++;
        }

        decreasePositionRequestKeysStart = index;
    }

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode
    ) external payable nonReentrant {
        require(_executionFee >= minExecutionFee, "PositionRouter: invalid executionFee");
        require(msg.value == _executionFee, "PositionRouter: invalid msg.value");
        require(_path.length == 1 || _path.length == 2, "PositionRouter: invalid _path length");

        _transferInETH();
        _setTraderReferralCode(_referralCode);

        if (_amountIn > 0) {
            IRouter(router).pluginTransfer(_path[0], msg.sender, address(this), _amountIn);
        }

        _createIncreasePosition(msg.sender, _path, _indexToken, _amountIn, _minOut, _sizeDelta, _isLong, _acceptablePrice, _executionFee, false);
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode
    ) external payable nonReentrant {
        require(_executionFee >= minExecutionFee, "PositionRouter: invalid executionFee");
        require(msg.value >= _executionFee, "PositionRouter: invalid msg.value");
        require(_path.length == 1 || _path.length == 2, "PositionRouter: invalid _path length");
        require(_path[0] == weth, "PositionRouter: invalid _path");

        _transferInETH();
        _setTraderReferralCode(_referralCode);

        uint256 amountIn = msg.value.sub(_executionFee);

        _createIncreasePosition(msg.sender, _path, _indexToken, amountIn, _minOut, _sizeDelta, _isLong, _acceptablePrice, _executionFee, true);
    }

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH
    ) external payable nonReentrant {
        require(_executionFee >= minExecutionFee, "PositionRouter: invalid executionFee");
        require(msg.value == _executionFee, "PositionRouter: invalid msg.value");
        require(_path.length == 1 || _path.length == 2, "PositionRouter: invalid _path length");

        if (_withdrawETH) {
            require(_path[_path.length - 1] == weth, "PositionRouter: invalid _path");
        }

        _transferInETH();

        _createDecreasePosition(msg.sender, _path, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver, _acceptablePrice, _minOut, _executionFee, _withdrawETH);
    }

    function getRequestQueueLengths()
        external 
        override
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (increasePositionRequestKeysStart, increasePositionRequestKeys.length, decreasePositionRequestKeysStart, decreasePositionRequestKeys.length);
    }

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
        if (request.account == address(0)) {
            return true;
        }

        bool shouldExecute = _validateExecution(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) {
            return false;
        }

        delete increasePositionRequests[_key];

        if (request.amountIn > 0) {
            uint256 amountIn = request.amountIn;

            if (request.path.length > 1) {
                IERC20(request.path[0]).safeTransfer(vault, request.amountIn);
                amountIn = _swap(request.path, request.minOut, address(this));
            }

            uint256 afterFeeAmount = _collectFees(msg.sender, request.path, amountIn, request.indexToken, request.isLong, request.sizeDelta);
            IERC20(request.path[request.path.length - 1]).safeTransfer(vault, afterFeeAmount);
        }

        _increasePosition(request.account, request.path[request.path.length - 1], request.indexToken, request.sizeDelta, request.isLong, request.acceptablePrice);

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit ExecuteIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountIn,
            request.minOut,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeIncreasePositions loop will continue executing the next request
        if (request.account == address(0)) {
            return true;
        }

        bool shouldCancel = _validateCancellation(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) {
            return false;
        }

        delete increasePositionRequests[_key];

        if (request.hasCollateralInETH) {
            _transferOutETHWithGasLimit(request.amountIn, payable(request.account));
        } else {
            IERC20(request.path[0]).safeTransfer(request.account, request.amountIn);
        }

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit CancelIncreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.amountIn,
            request.minOut,
            request.sizeDelta,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
        if (request.account == address(0)) {
            return true;
        }

        bool shouldExecute = _validateExecution(request.blockNumber, request.blockTime, request.account);
        if (!shouldExecute) {
            return false;
        }

        delete decreasePositionRequests[_key];

        uint256 amountOut = _decreasePosition(
            request.account,
            request.path[0],
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            address(this),
            request.acceptablePrice
        );

        if (request.path.length > 1) {
            IERC20(request.path[0]).safeTransfer(vault, amountOut);
            amountOut = _swap(request.path, request.minOut, address(this));
        }

        if (request.withdrawETH) {
            _transferOutETHWithGasLimit(amountOut, payable(request.receiver));
        } else {
            IERC20(request.path[request.path.length - 1]).safeTransfer(request.receiver, amountOut);
        }

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit ExecuteDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.receiver,
            request.acceptablePrice,
            request.minOut,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeDecreasePositions loop will continue executing the next request
        if (request.account == address(0)) {
            return true;
        }

        bool shouldCancel = _validateCancellation(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) {
            return false;
        }

        delete decreasePositionRequests[_key];

        _transferOutETH(request.executionFee, _executionFeeReceiver);

        emit CancelDecreasePosition(
            request.account,
            request.path,
            request.indexToken,
            request.collateralDelta,
            request.sizeDelta,
            request.isLong,
            request.receiver,
            request.acceptablePrice,
            request.minOut,
            request.executionFee,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function getRequestKey(address _account, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function getIncreasePositionRequestPath(bytes32 _key) public view returns (address[] memory) {
        IncreasePositionRequest memory request = increasePositionRequests[_key];
        return request.path;
    }

    function getDecreasePositionRequestPath(bytes32 _key) public view returns (address[] memory) {
        DecreasePositionRequest memory request = decreasePositionRequests[_key];
        return request.path;
    }

    function _setTraderReferralCode(bytes32 _referralCode) internal {
        if (_referralCode != bytes32(0) && referralStorage != address(0)) {
            IReferralStorage(referralStorage).setTraderReferralCode(msg.sender, _referralCode);
        }
    }

    function _validateExecution(
        uint256 _positionBlockNumber,
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        if (_positionBlockTime.add(maxTimeDelay) <= block.timestamp) {
            revert("PositionRouter: request has expired");
        }

        bool isKeeperCall = msg.sender == address(this) || isPositionKeeper[msg.sender];

        if (!isLeverageEnabled && !isKeeperCall) {
            revert("PositionRouter: forbidden");
        }

        if (isKeeperCall) {
            return _positionBlockNumber.add(minBlockDelayKeeper) <= block.number;
        }

        require(msg.sender == _account, "PositionRouter: forbidden");

        require(_positionBlockTime.add(minTimeDelayPublic) <= block.timestamp, "PositionRouter: min delay not yet passed");

        return true;
    }

    function _validateCancellation(
        uint256 _positionBlockNumber,
        uint256 _positionBlockTime,
        address _account
    ) internal view returns (bool) {
        bool isKeeperCall = msg.sender == address(this) || isPositionKeeper[msg.sender];

        if (!isLeverageEnabled && !isKeeperCall) {
            revert("PositionRouter: forbidden");
        }

        if (isKeeperCall) {
            return _positionBlockNumber.add(minBlockDelayKeeper) <= block.number;
        }

        require(msg.sender == _account, "PositionRouter: forbidden");

        require(_positionBlockTime.add(minTimeDelayPublic) <= block.timestamp, "PositionRouter: min delay not yet passed");

        return true;
    }

    function _createIncreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bool _hasCollateralInETH
    ) internal {
        uint256 index = increasePositionsIndex[_account].add(1);
        increasePositionsIndex[_account] = index;

        IncreasePositionRequest memory request = IncreasePositionRequest(
            _account,
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            block.number,
            block.timestamp,
            _hasCollateralInETH
        );

        bytes32 key = getRequestKey(_account, index);
        increasePositionRequests[key] = request;

        increasePositionRequestKeys.push(key);

        emit CreateIncreasePosition(
            _account,
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            index,
            block.number,
            block.timestamp,
            tx.gasprice
        );
    }

    function _createDecreasePosition(
        address _account,
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH
    ) internal {
        uint256 index = decreasePositionsIndex[_account].add(1);
        decreasePositionsIndex[_account] = index;

        DecreasePositionRequest memory request = DecreasePositionRequest(
            _account,
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            block.number,
            block.timestamp,
            _withdrawETH
        );

        bytes32 key = getRequestKey(_account, index);
        decreasePositionRequests[key] = request;

        decreasePositionRequestKeys.push(key);

        emit CreateDecreasePosition(
            _account,
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            index,
            block.number,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/Address.sol";

import "../tokens/interfaces/IWETH.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRouter.sol";

contract Router is IRouter {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    address public gov;

    // wrapped BNB / ETH
    address public weth;
    address public usds;
    address public vault;

    mapping(address => bool) public plugins;
    mapping(address => mapping(address => bool)) public approvedPlugins;

    event Swap(address account, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);

    modifier onlyGov() {
        require(msg.sender == gov, "Router: forbidden");
        _;
    }

    constructor(
        address _vault,
        address _usds,
        address _weth
    ) public {
        vault = _vault;
        usds = _usds;
        weth = _weth;

        gov = msg.sender;
    }

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function addPlugin(address _plugin) external override onlyGov {
        plugins[_plugin] = true;
    }

    function removePlugin(address _plugin) external onlyGov {
        plugins[_plugin] = false;
    }

    function approvePlugin(address _plugin) external {
        approvedPlugins[msg.sender][_plugin] = true;
    }

    function denyPlugin(address _plugin) external {
        approvedPlugins[msg.sender][_plugin] = false;
    }

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external override {
        _validatePlugin(_account);
        IERC20(_token).safeTransferFrom(_account, _receiver, _amount);
    }

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external override {
        _validatePlugin(_account);
        IVault(vault).increasePosition(_account, _collateralToken, _indexToken, _sizeDelta, _isLong);
    }

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external override returns (uint256) {
        _validatePlugin(_account);
        return IVault(vault).decreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
    }

    function directPoolDeposit(address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(_sender(), vault, _amount);
        IVault(vault).directPoolDeposit(_token);
    }

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) public override {
        IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        uint256 amountOut = _swap(_path, _minOut, _receiver);
        emit Swap(msg.sender, _path[0], _path[_path.length - 1], _amountIn, amountOut);
    }

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external payable {
        require(_path[0] == weth, "Router: invalid _path");
        _transferETHToVault();
        uint256 amountOut = _swap(_path, _minOut, _receiver);
        emit Swap(msg.sender, _path[0], _path[_path.length - 1], msg.value, amountOut);
    }

    function swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) external {
        require(_path[_path.length - 1] == weth, "Router: invalid _path");
        IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        uint256 amountOut = _swap(_path, _minOut, address(this));
        _transferOutETH(amountOut, _receiver);
        emit Swap(msg.sender, _path[0], _path[_path.length - 1], _amountIn, amountOut);
    }

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external {
        if (_amountIn > 0) {
            IERC20(_path[0]).safeTransferFrom(_sender(), vault, _amountIn);
        }
        if (_path.length > 1 && _amountIn > 0) {
            uint256 amountOut = _swap(_path, _minOut, address(this));
            IERC20(_path[_path.length - 1]).safeTransfer(vault, amountOut);
        }
        _increasePosition(_path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function increasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external payable {
        require(_path[0] == weth, "Router: invalid _path");
        if (msg.value > 0) {
            _transferETHToVault();
        }
        if (_path.length > 1 && msg.value > 0) {
            uint256 amountOut = _swap(_path, _minOut, address(this));
            IERC20(_path[_path.length - 1]).safeTransfer(vault, amountOut);
        }
        _increasePosition(_path[_path.length - 1], _indexToken, _sizeDelta, _isLong, _price);
    }

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external {
        _decreasePosition(_collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver, _price);
    }

    function decreasePositionETH(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price
    ) external {
        uint256 amountOut = _decreasePosition(_collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        _transferOutETH(amountOut, _receiver);
    }

    function decreasePositionAndSwap(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price,
        uint256 _minOut
    ) external {
        uint256 amount = _decreasePosition(_path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        _swap(_path, _minOut, _receiver);
    }

    function decreasePositionAndSwapETH(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address payable _receiver,
        uint256 _price,
        uint256 _minOut
    ) external {
        require(_path[_path.length - 1] == weth, "Router: invalid _path");
        uint256 amount = _decreasePosition(_path[0], _indexToken, _collateralDelta, _sizeDelta, _isLong, address(this), _price);
        IERC20(_path[0]).safeTransfer(vault, amount);
        uint256 amountOut = _swap(_path, _minOut, address(this));
        _transferOutETH(amountOut, _receiver);
    }

    function _increasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) private {
        if (_isLong) {
            require(IVault(vault).getMaxPrice(_indexToken) <= _price, "Router: mark price higher than limit");
        } else {
            require(IVault(vault).getMinPrice(_indexToken) >= _price, "Router: mark price lower than limit");
        }

        IVault(vault).increasePosition(_sender(), _collateralToken, _indexToken, _sizeDelta, _isLong);
    }

    function _decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) private returns (uint256) {
        if (_isLong) {
            require(IVault(vault).getMinPrice(_indexToken) >= _price, "Router: mark price lower than limit");
        } else {
            require(IVault(vault).getMaxPrice(_indexToken) <= _price, "Router: mark price higher than limit");
        }

        return IVault(vault).decreasePosition(_sender(), _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
    }

    function _transferETHToVault() private {
        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).safeTransfer(vault, msg.value);
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        IWETH(weth).withdraw(_amountOut);
        _receiver.sendValue(_amountOut);
    }

    function _swap(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        if (_path.length == 2) {
            return _vaultSwap(_path[0], _path[1], _minOut, _receiver);
        }
        if (_path.length == 3) {
            uint256 midOut = _vaultSwap(_path[0], _path[1], 0, address(this));
            IERC20(_path[1]).safeTransfer(vault, midOut);
            return _vaultSwap(_path[1], _path[2], _minOut, _receiver);
        }

        revert("Router: invalid _path.length");
    }

    function _vaultSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        uint256 amountOut;

        if (_tokenOut == usds) {
            // buyUSDS
            amountOut = IVault(vault).buyUSDS(_tokenIn, _receiver);
        } else if (_tokenIn == usds) {
            // sellUSDS
            amountOut = IVault(vault).sellUSDS(_tokenOut, _receiver);
        } else {
            // swap
            amountOut = IVault(vault).swap(_tokenIn, _tokenOut, _receiver);
        }

        require(amountOut >= _minOut, "Router: insufficient amountOut");
        return amountOut;
    }

    function _sender() private view returns (address) {
        return msg.sender;
    }

    function _validatePlugin(address _account) private view {
        require(plugins[msg.sender], "Router: invalid plugin");
        require(approvedPlugins[_account][msg.sender], "Router: plugin not approved");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";

import "../access/Governable.sol";
import "./interfaces/IShortsTracker.sol";
import "./interfaces/IVault.sol";

contract ShortsTracker is Governable, IShortsTracker {
    using SafeMath for uint256;

    event GlobalShortDataUpdated(address indexed token, uint256 globalShortSize, uint256 globalShortAveragePrice);

    uint256 public constant MAX_INT256 = uint256(type(int256).max);

    IVault public vault;

    mapping (address => bool) public isHandler;
    mapping (bytes32 => bytes32) public data;

    mapping (address => uint256) override public globalShortAveragePrices;
    bool override public isGlobalShortDataReady;

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ShortsTracker: forbidden");
        _;
    }

    constructor(address _vault) public {
        vault = IVault(_vault);
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        require(_handler != address(0), "ShortsTracker: invalid _handler");
        isHandler[_handler] = _isActive;
    }

    function _setGlobalShortAveragePrice(address _token, uint256 _averagePrice) internal {
        globalShortAveragePrices[_token] = _averagePrice;
    }

    function setIsGlobalShortDataReady(bool value) external onlyGov {
        isGlobalShortDataReady = value;
    }

    function updateGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) override external onlyHandler {
        if (_isLong || _sizeDelta == 0) {
            return;
        }

        if (!isGlobalShortDataReady) {
            return;
        }

        (uint256 globalShortSize, uint256 globalShortAveragePrice) = getNextGlobalShortData(
            _account,
            _collateralToken,
            _indexToken,
            _markPrice,
            _sizeDelta,
            _isIncrease
        );
        _setGlobalShortAveragePrice(_indexToken, globalShortAveragePrice);

        emit GlobalShortDataUpdated(_indexToken, globalShortSize, globalShortAveragePrice);
    }

    function getGlobalShortDelta(address _token) public view returns (bool, uint256) {
        uint256 size = vault.globalShortSizes(_token);
        uint256 averagePrice = globalShortAveragePrices[_token];
        if (size == 0) { return (false, 0); }

        uint256 nextPrice = IVault(vault).getMaxPrice(_token);
        uint256 priceDelta = averagePrice > nextPrice ? averagePrice.sub(nextPrice) : nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > nextPrice;

        return (hasProfit, delta);
    }


    function setInitData(address[] calldata _tokens, uint256[] calldata _averagePrices) external onlyGov {
        require(!isGlobalShortDataReady, "ShortsTracker: already migrated");

        for (uint256 i = 0; i < _tokens.length; i++) {
            globalShortAveragePrices[_tokens[i]] = _averagePrices[i];
        }
        isGlobalShortDataReady = true;
    }

    function getNextGlobalShortData(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) override public view returns (uint256, uint256) {
        int256 realisedPnl = getRealisedPnl(_account,_collateralToken, _indexToken, _sizeDelta, _isIncrease);
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice ? averagePrice.sub(_nextPrice) : _nextPrice.sub(averagePrice);

        uint256 nextSize;
        uint256 delta;
        // avoid stack to deep
        {
            uint256 size = vault.globalShortSizes(_indexToken);
            nextSize = _isIncrease ? size.add(_sizeDelta) : size.sub(_sizeDelta);

            if (nextSize == 0) {
                return (0, 0);
            }

            if (averagePrice == 0) {
                return (nextSize, _nextPrice);
            }

            delta = size.mul(priceDelta).div(averagePrice);
        }

        uint256 nextAveragePrice = _getNextGlobalAveragePrice(
            averagePrice,
            _nextPrice,
            nextSize,
            delta,
            realisedPnl
        );

        return (nextSize, nextAveragePrice);
    }

    function getRealisedPnl(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isIncrease
    ) public view returns (int256) {
        if (_isIncrease) {
            return 0;
        }

        IVault _vault = vault;
        (uint256 size, /*uint256 collateral*/, uint256 averagePrice, , , , , uint256 lastIncreasedTime) = _vault.getPosition(_account, _collateralToken, _indexToken, false);

        (bool hasProfit, uint256 delta) = _vault.getDelta(_indexToken, size, averagePrice, false, lastIncreasedTime);
        // get the proportional change in pnl
        uint256 adjustedDelta = _sizeDelta.mul(delta).div(size);
        require(adjustedDelta < MAX_INT256, "ShortsTracker: overflow");
        return hasProfit ? int256(adjustedDelta) : -int256(adjustedDelta);
    }

    function _getNextGlobalAveragePrice(
        uint256 _averagePrice,
        uint256 _nextPrice,
        uint256 _nextSize,
        uint256 _delta,
        int256 _realisedPnl
    ) public pure returns (uint256) {
        (bool hasProfit, uint256 nextDelta) = _getNextDelta(_delta, _averagePrice, _nextPrice, _realisedPnl);

        uint256 nextAveragePrice = _nextPrice
            .mul(_nextSize)
            .div(hasProfit ? _nextSize.sub(nextDelta) : _nextSize.add(nextDelta));

        return nextAveragePrice;
    }

    function _getNextDelta(
        uint256 _delta,
        uint256 _averagePrice,
        uint256 _nextPrice,
        int256 _realisedPnl
    ) internal pure returns (bool, uint256) {
        // global delta 10000, realised pnl 1000 => new pnl 9000
        // global delta 10000, realised pnl -1000 => new pnl 11000
        // global delta -10000, realised pnl 1000 => new pnl -11000
        // global delta -10000, realised pnl -1000 => new pnl -9000
        // global delta 10000, realised pnl 11000 => new pnl -1000 (flips sign)
        // global delta -10000, realised pnl -11000 => new pnl 1000 (flips sign)

        bool hasProfit = _averagePrice > _nextPrice;
        if (hasProfit) {
            // global shorts pnl is positive
            if (_realisedPnl > 0) {
                if (uint256(_realisedPnl) > _delta) {
                    _delta = uint256(_realisedPnl).sub(_delta);
                    hasProfit = false;
                } else {
                    _delta = _delta.sub(uint256(_realisedPnl));
                }
            } else {
                _delta = _delta.add(uint256(-_realisedPnl));
            }

            return (hasProfit, _delta);
        }

        if (_realisedPnl > 0) {
            _delta = _delta.add(uint256(_realisedPnl));
        } else {
            if (uint256(-_realisedPnl) > _delta) {
                _delta = uint256(-_realisedPnl).sub(_delta);
                hasProfit = true;
            } else {
                _delta = _delta.sub(uint256(-_realisedPnl));
            }
        }
        return (hasProfit, _delta);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IVault.sol";
import "./interfaces/ISlpManager.sol";
import "../tokens/interfaces/IUSDS.sol";
import "../tokens/interfaces/IMintable.sol";
import "../access/Governable.sol";

contract SlpManager is ReentrancyGuard, Governable, ISlpManager {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRICE_PRECISION = 10**30;
    uint256 public constant USDS_DECIMALS = 18;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;

    IVault public vault;
    address public override usds;
    address public slp;

    uint256 public override cooldownDuration;
    mapping(address => uint256) public override lastAddedAt;

    uint256 public aumAddition;
    uint256 public aumDeduction;

    bool public inPrivateMode;
    mapping(address => bool) public isHandler;

    event AddLiquidity(address account, address token, uint256 amount, uint256 aumInUsds, uint256 slpSupply, uint256 usdsAmount, uint256 mintAmount);

    event RemoveLiquidity(address account, address token, uint256 slpAmount, uint256 aumInUsds, uint256 slpSupply, uint256 usdsAmount, uint256 amountOut);

    constructor(
        address _vault,
        address _usds,
        address _slp,
        uint256 _cooldownDuration
    ) public {
        gov = msg.sender;
        vault = IVault(_vault);
        usds = _usds;
        slp = _slp;
        cooldownDuration = _cooldownDuration;
    }

    function setInPrivateMode(bool _inPrivateMode) external onlyGov {
        inPrivateMode = _inPrivateMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function setCooldownDuration(uint256 _cooldownDuration) external override onlyGov {
        require(_cooldownDuration <= MAX_COOLDOWN_DURATION, "SlpManager: invalid _cooldownDuration");
        cooldownDuration = _cooldownDuration;
    }

    function setAumAdjustment(uint256 _aumAddition, uint256 _aumDeduction) external onlyGov {
        aumAddition = _aumAddition;
        aumDeduction = _aumDeduction;
    }

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsds,
        uint256 _minSlp
    ) external override nonReentrant returns (uint256) {
        if (inPrivateMode) {
            revert("SlpManager: action not enabled");
        }
        return _addLiquidity(msg.sender, msg.sender, _token, _amount, _minUsds, _minSlp);
    }

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsds,
        uint256 _minSlp
    ) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _addLiquidity(_fundingAccount, _account, _token, _amount, _minUsds, _minSlp);
    }

    function removeLiquidity(
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        if (inPrivateMode) {
            revert("SlpManager: action not enabled");
        }
        return _removeLiquidity(msg.sender, _tokenOut, _slpAmount, _minOut, _receiver);
    }

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _removeLiquidity(_account, _tokenOut, _slpAmount, _minOut, _receiver);
    }

    function getAums() public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = getAum(true);
        amounts[1] = getAum(false);
        return amounts;
    }

    function getAumInUsds(bool maximise) public view returns (uint256) {
        uint256 aum = getAum(maximise);
        return aum.mul(10**USDS_DECIMALS).div(PRICE_PRECISION);
    }

    function getAum(bool maximise) public view returns (uint256) {
        uint256 length = vault.allWhitelistedTokensLength();
        uint256 aum = aumAddition;
        uint256 shortProfits = 0;

        for (uint256 i = 0; i < length; i++) {
            address token = vault.allWhitelistedTokens(i);
            bool isWhitelisted = vault.whitelistedTokens(token);

            if (!isWhitelisted) {
                continue;
            }

            uint256 price = maximise ? vault.getMaxPrice(token) : vault.getMinPrice(token);
            uint256 poolAmount = vault.poolAmounts(token);
            uint256 decimals = vault.tokenDecimals(token);

            if (vault.stableTokens(token)) {
                aum = aum.add(poolAmount.mul(price).div(10**decimals));
            } else {
                // add global short profit / loss
                uint256 size = vault.globalShortSizes(token);
                if (size > 0) {
                    uint256 averagePrice = vault.globalShortAveragePrices(token);
                    uint256 priceDelta = averagePrice > price ? averagePrice.sub(price) : price.sub(averagePrice);
                    uint256 delta = size.mul(priceDelta).div(averagePrice);
                    if (price > averagePrice) {
                        // add losses from shorts
                        aum = aum.add(delta);
                    } else {
                        shortProfits = shortProfits.add(delta);
                    }
                }

                aum = aum.add(vault.guaranteedUsd(token));

                uint256 reservedAmount = vault.reservedAmounts(token);
                aum = aum.add(poolAmount.sub(reservedAmount).mul(price).div(10**decimals));
            }
        }

        aum = shortProfits > aum ? 0 : aum.sub(shortProfits);
        return aumDeduction > aum ? 0 : aum.sub(aumDeduction);
    }

    function _addLiquidity(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsds,
        uint256 _minSlp
    ) private returns (uint256) {
        require(_amount > 0, "SlpManager: invalid _amount");

        // calculate aum before buyUSDS
        uint256 aumInUsds = getAumInUsds(true);
        uint256 slpSupply = IERC20(slp).totalSupply();

        IERC20(_token).safeTransferFrom(_fundingAccount, address(vault), _amount);
        uint256 usdsAmount = vault.buyUSDS(_token, address(this));
        require(usdsAmount >= _minUsds, "SlpManager: insufficient USDS output");

        uint256 mintAmount = aumInUsds == 0 ? usdsAmount : usdsAmount.mul(slpSupply).div(aumInUsds);
        require(mintAmount >= _minSlp, "SlpManager: insufficient SLP output");

        IMintable(slp).mint(_account, mintAmount);

        lastAddedAt[_account] = block.timestamp;

        emit AddLiquidity(_account, _token, _amount, aumInUsds, slpSupply, usdsAmount, mintAmount);

        return mintAmount;
    }

    function _removeLiquidity(
        address _account,
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        require(_slpAmount > 0, "SlpManager: invalid _slpAmount");
        require(lastAddedAt[_account].add(cooldownDuration) <= block.timestamp, "SlpManager: cooldown duration not yet passed");

        // calculate aum before sellUSDS
        uint256 aumInUsds = getAumInUsds(false);
        uint256 slpSupply = IERC20(slp).totalSupply();

        uint256 usdsAmount = _slpAmount.mul(aumInUsds).div(slpSupply);
        uint256 usdsBalance = IERC20(usds).balanceOf(address(this));
        if (usdsAmount > usdsBalance) {
            IUSDS(usds).mint(address(this), usdsAmount.sub(usdsBalance));
        }

        IMintable(slp).burn(_account, _slpAmount);

        IERC20(usds).transfer(address(vault), usdsAmount);
        uint256 amountOut = vault.sellUSDS(_tokenOut, _receiver);
        require(amountOut >= _minOut, "SlpManager: insufficient output");

        emit RemoveLiquidity(_account, _tokenOut, _slpAmount, aumInUsds, slpSupply, usdsAmount, amountOut);

        return amountOut;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "SlpManager: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../tokens/interfaces/IUSDS.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "./interfaces/IVaultPriceFeed.sol";

contract Vault is ReentrancyGuard, IVault {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant PRICE_PRECISION = 10**30;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant USDS_DECIMALS = 18;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%

    bool public override isInitialized;
    bool public override isSwapEnabled = true;
    bool public override isLeverageEnabled = true;

    IVaultUtils public vaultUtils;

    address public errorController;

    address public override router;
    address public override priceFeed;

    address public override usds;
    address public override gov;

    uint256 public override whitelistedTokenCount;

    uint256 public override maxLeverage = 50 * 10000; // 50x

    uint256 public override liquidationFeeUsd;
    uint256 public override taxBasisPoints = 50; // 0.5%
    uint256 public override stableTaxBasisPoints = 20; // 0.2%
    uint256 public override mintBurnFeeBasisPoints = 30; // 0.3%
    uint256 public override swapFeeBasisPoints = 30; // 0.3%
    uint256 public override stableSwapFeeBasisPoints = 4; // 0.04%
    uint256 public override marginFeeBasisPoints = 10; // 0.1%

    uint256 public override minProfitTime;
    bool public override hasDynamicFees = false;

    uint256 public override fundingInterval = 8 hours;
    uint256 public override fundingRateFactor;
    uint256 public override stableFundingRateFactor;
    uint256 public override totalTokenWeights;

    bool public includeAmmPrice = true;
    bool public useSwapPricing = false;

    bool public override inManagerMode = false;
    bool public override inPrivateLiquidationMode = false;

    uint256 public override maxGasPrice;

    mapping(address => mapping(address => bool)) public override approvedRouters;
    mapping(address => bool) public override isLiquidator;
    mapping(address => bool) public override isManager;

    address[] public override allWhitelistedTokens;

    mapping(address => bool) public override whitelistedTokens;
    mapping(address => uint256) public override tokenDecimals;
    mapping(address => uint256) public override minProfitBasisPoints;
    mapping(address => bool) public override stableTokens;
    mapping(address => bool) public override shortableTokens;

    // tokenBalances is used only to determine _transferIn values
    mapping(address => uint256) public override tokenBalances;

    // tokenWeights allows customisation of index composition
    mapping(address => uint256) public override tokenWeights;

    // usdsAmounts tracks the amount of USDS debt for each whitelisted token
    mapping(address => uint256) public override usdsAmounts;

    // maxUsdsAmounts allows setting a max amount of USDS debt for a token
    mapping(address => uint256) public override maxUsdsAmounts;

    // poolAmounts tracks the number of received tokens that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    mapping(address => uint256) public override poolAmounts;

    // reservedAmounts tracks the number of tokens reserved for open leverage positions
    mapping(address => uint256) public override reservedAmounts;

    // bufferAmounts allows specification of an amount to exclude from swaps
    // this can be used to ensure a certain amount of liquidity is available for leverage positions
    mapping(address => uint256) public override bufferAmounts;

    // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions
    // this value is used to calculate the redemption values for selling of USDS
    // this is an estimated amount, it is possible for the actual guaranteed value to be lower
    // in the case of sudden price decreases, the guaranteed value should be corrected
    // after liquidations are carried out
    mapping(address => uint256) public override guaranteedUsd;

    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping(address => uint256) public override cumulativeFundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    mapping(address => uint256) public override lastFundingTimes;

    // positions tracks all open positions
    mapping(bytes32 => Position) public positions;

    // feeReserves tracks the amount of fees per token
    mapping(address => uint256) public override feeReserves;

    mapping(address => uint256) public override globalShortSizes;
    mapping(address => uint256) public override globalShortAveragePrices;
    mapping(address => uint256) public override maxGlobalShortSizes;

    mapping(uint256 => string) public errors;

    event BuyUSDS(address account, address token, uint256 tokenAmount, uint256 usdsAmount, uint256 feeBasisPoints);
    event SellUSDS(address account, address token, uint256 usdsAmount, uint256 tokenAmount, uint256 feeBasisPoints);
    event Swap(address account, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 amountOutAfterFees, uint256 feeBasisPoints);

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event ClosePosition(bytes32 key, uint256 size, uint256 collateral, uint256 averagePrice, uint256 entryFundingRate, uint256 reserveAmount, int256 realisedPnl);

    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdsAmount(address token, uint256 amount);
    event DecreaseUsdsAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    // once the parameters are verified to be working correctly,
    // gov should be set to a timelock contract or a governance contract
    constructor() public {
        gov = msg.sender;
    }

    function initialize(
        address _router,
        address _usds,
        address _priceFeed,
        uint256 _liquidationFeeUsd,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external {
        _onlyGov();
        _validate(!isInitialized, 1);
        isInitialized = true;

        router = _router;
        usds = _usds;
        priceFeed = _priceFeed;
        liquidationFeeUsd = _liquidationFeeUsd;
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
    }

    function setVaultUtils(IVaultUtils _vaultUtils) external override {
        _onlyGov();
        vaultUtils = _vaultUtils;
    }

    function setErrorController(address _errorController) external {
        _onlyGov();
        errorController = _errorController;
    }

    function setError(uint256 _errorCode, string calldata _error) external override {
        require(msg.sender == errorController, "Vault: invalid errorController");
        errors[_errorCode] = _error;
    }

    function allWhitelistedTokensLength() external view override returns (uint256) {
        return allWhitelistedTokens.length;
    }

    function setInManagerMode(bool _inManagerMode) external override {
        _onlyGov();
        inManagerMode = _inManagerMode;
    }

    function setManager(address _manager, bool _isManager) external override {
        _onlyGov();
        isManager[_manager] = _isManager;
    }

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external override {
        _onlyGov();
        inPrivateLiquidationMode = _inPrivateLiquidationMode;
    }

    function setLiquidator(address _liquidator, bool _isActive) external override {
        _onlyGov();
        isLiquidator[_liquidator] = _isActive;
    }

    function setIsSwapEnabled(bool _isSwapEnabled) external override {
        _onlyGov();
        isSwapEnabled = _isSwapEnabled;
    }

    function setIsLeverageEnabled(bool _isLeverageEnabled) external override {
        _onlyGov();
        isLeverageEnabled = _isLeverageEnabled;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external override {
        _onlyGov();
        maxGasPrice = _maxGasPrice;
    }

    function setGov(address _gov) external {
        _onlyGov();
        gov = _gov;
    }

    function setPriceFeed(address _priceFeed) external override {
        _onlyGov();
        priceFeed = _priceFeed;
    }

    function setMaxLeverage(uint256 _maxLeverage) external override {
        _onlyGov();
        _validate(_maxLeverage > MIN_LEVERAGE, 2);
        maxLeverage = _maxLeverage;
    }

    function setBufferAmount(address _token, uint256 _amount) external override {
        _onlyGov();
        bufferAmounts[_token] = _amount;
    }

    function setMaxGlobalShortSize(address _token, uint256 _amount) external override {
        _onlyGov();
        maxGlobalShortSizes[_token] = _amount;
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external override {
        _onlyGov();
        _validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, 3);
        _validate(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, 4);
        _validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 5);
        _validate(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 6);
        _validate(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 7);
        _validate(_marginFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 8);
        _validate(_liquidationFeeUsd <= MAX_LIQUIDATION_FEE_USD, 9);
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        swapFeeBasisPoints = _swapFeeBasisPoints;
        stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
        marginFeeBasisPoints = _marginFeeBasisPoints;
        liquidationFeeUsd = _liquidationFeeUsd;
        minProfitTime = _minProfitTime;
        hasDynamicFees = _hasDynamicFees;
    }

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor,
        uint256 _stableFundingRateFactor
    ) external override {
        _onlyGov();
        _validate(_fundingInterval >= MIN_FUNDING_RATE_INTERVAL, 10);
        _validate(_fundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 11);
        _validate(_stableFundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 12);
        fundingInterval = _fundingInterval;
        fundingRateFactor = _fundingRateFactor;
        stableFundingRateFactor = _stableFundingRateFactor;
    }

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdsAmount,
        bool _isStable,
        bool _isShortable
    ) external override {
        _onlyGov();
        // increment token count for the first time
        if (!whitelistedTokens[_token]) {
            whitelistedTokenCount = whitelistedTokenCount.add(1);
            allWhitelistedTokens.push(_token);
        }

        uint256 _totalTokenWeights = totalTokenWeights;
        _totalTokenWeights = _totalTokenWeights.sub(tokenWeights[_token]);

        whitelistedTokens[_token] = true;
        tokenDecimals[_token] = _tokenDecimals;
        tokenWeights[_token] = _tokenWeight;
        minProfitBasisPoints[_token] = _minProfitBps;
        maxUsdsAmounts[_token] = _maxUsdsAmount;
        stableTokens[_token] = _isStable;
        shortableTokens[_token] = _isShortable;

        totalTokenWeights = _totalTokenWeights.add(_tokenWeight);

        // validate price feed
        getMaxPrice(_token);
    }

    function clearTokenConfig(address _token) external {
        _onlyGov();
        _validate(whitelistedTokens[_token], 13);
        totalTokenWeights = totalTokenWeights.sub(tokenWeights[_token]);
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete tokenWeights[_token];
        delete minProfitBasisPoints[_token];
        delete maxUsdsAmounts[_token];
        delete stableTokens[_token];
        delete shortableTokens[_token];
        whitelistedTokenCount = whitelistedTokenCount.sub(1);
    }

    function withdrawFees(address _token, address _receiver) external override returns (uint256) {
        _onlyGov();
        uint256 amount = feeReserves[_token];
        if (amount == 0) {
            return 0;
        }
        feeReserves[_token] = 0;
        _transferOut(_token, amount, _receiver);
        return amount;
    }

    function addRouter(address _router) external {
        approvedRouters[msg.sender][_router] = true;
    }

    function removeRouter(address _router) external {
        approvedRouters[msg.sender][_router] = false;
    }

    function setUsdsAmount(address _token, uint256 _amount) external override {
        _onlyGov();

        uint256 usdsAmount = usdsAmounts[_token];
        if (_amount > usdsAmount) {
            _increaseUsdsAmount(_token, _amount.sub(usdsAmount));
            return;
        }

        _decreaseUsdsAmount(_token, usdsAmount.sub(_amount));
    }

    // the governance controlling this function should have a timelock
    function upgradeVault(
        address _newVault,
        address _token,
        uint256 _amount
    ) external {
        _onlyGov();
        IERC20(_token).safeTransfer(_newVault, _amount);
    }

    // deposit into the pool without minting USDS tokens
    // useful in allowing the pool to become over-collaterised
    function directPoolDeposit(address _token) external override nonReentrant {
        _validate(whitelistedTokens[_token], 14);
        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, 15);
        _increasePoolAmount(_token, tokenAmount);
        emit DirectPoolDeposit(_token, tokenAmount);
    }

    function buyUSDS(address _token, address _receiver) external override nonReentrant returns (uint256) {
        _validateManager();
        _validate(whitelistedTokens[_token], 16);
        useSwapPricing = true;

        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, 17);

        updateCumulativeFundingRate(_token, _token);

        uint256 price = getMinPrice(_token);

        uint256 usdsAmount = tokenAmount.mul(price).div(PRICE_PRECISION);
        usdsAmount = adjustForDecimals(usdsAmount, _token, usds);
        _validate(usdsAmount > 0, 18);

        uint256 feeBasisPoints = vaultUtils.getBuyUsdsFeeBasisPoints(_token, usdsAmount);
        uint256 amountAfterFees = _collectSwapFees(_token, tokenAmount, feeBasisPoints);
        uint256 mintAmount = amountAfterFees.mul(price).div(PRICE_PRECISION);
        mintAmount = adjustForDecimals(mintAmount, _token, usds);

        _increaseUsdsAmount(_token, mintAmount);
        _increasePoolAmount(_token, amountAfterFees);

        IUSDS(usds).mint(_receiver, mintAmount);

        emit BuyUSDS(_receiver, _token, tokenAmount, mintAmount, feeBasisPoints);

        useSwapPricing = false;
        return mintAmount;
    }

    function sellUSDS(address _token, address _receiver) external override nonReentrant returns (uint256) {
        _validateManager();
        _validate(whitelistedTokens[_token], 19);
        useSwapPricing = true;

        uint256 usdsAmount = _transferIn(usds);
        _validate(usdsAmount > 0, 20);

        updateCumulativeFundingRate(_token, _token);

        uint256 redemptionAmount = getRedemptionAmount(_token, usdsAmount);
        _validate(redemptionAmount > 0, 21);

        _decreaseUsdsAmount(_token, usdsAmount);
        _decreasePoolAmount(_token, redemptionAmount);

        IUSDS(usds).burn(address(this), usdsAmount);

        // the _transferIn call increased the value of tokenBalances[usds]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for usds, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        _updateTokenBalance(usds);

        uint256 feeBasisPoints = vaultUtils.getSellUsdsFeeBasisPoints(_token, usdsAmount);
        uint256 amountOut = _collectSwapFees(_token, redemptionAmount, feeBasisPoints);
        _validate(amountOut > 0, 22);

        _transferOut(_token, amountOut, _receiver);

        emit SellUSDS(_receiver, _token, usdsAmount, amountOut, feeBasisPoints);

        useSwapPricing = false;
        return amountOut;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        _validate(isSwapEnabled, 23);
        _validate(whitelistedTokens[_tokenIn], 24);
        _validate(whitelistedTokens[_tokenOut], 25);
        _validate(_tokenIn != _tokenOut, 26);

        useSwapPricing = true;

        updateCumulativeFundingRate(_tokenIn, _tokenIn);
        updateCumulativeFundingRate(_tokenOut, _tokenOut);

        uint256 amountIn = _transferIn(_tokenIn);
        _validate(amountIn > 0, 27);

        uint256 priceIn = getMinPrice(_tokenIn);
        uint256 priceOut = getMaxPrice(_tokenOut);

        uint256 amountOut = amountIn.mul(priceIn).div(priceOut);
        amountOut = adjustForDecimals(amountOut, _tokenIn, _tokenOut);

        // adjust usdsAmounts by the same usdsAmount as debt is shifted between the assets
        uint256 usdsAmount = amountIn.mul(priceIn).div(PRICE_PRECISION);
        usdsAmount = adjustForDecimals(usdsAmount, _tokenIn, usds);

        uint256 feeBasisPoints = vaultUtils.getSwapFeeBasisPoints(_tokenIn, _tokenOut, usdsAmount);
        uint256 amountOutAfterFees = _collectSwapFees(_tokenOut, amountOut, feeBasisPoints);

        _increaseUsdsAmount(_tokenIn, usdsAmount);
        _decreaseUsdsAmount(_tokenOut, usdsAmount);

        _increasePoolAmount(_tokenIn, amountIn);
        _decreasePoolAmount(_tokenOut, amountOut);

        _validateBufferAmount(_tokenOut);

        _transferOut(_tokenOut, amountOutAfterFees, _receiver);

        emit Swap(_receiver, _tokenIn, _tokenOut, amountIn, amountOut, amountOutAfterFees, feeBasisPoints);

        useSwapPricing = false;
        return amountOutAfterFees;
    }

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external override nonReentrant {
        _validate(isLeverageEnabled, 28);
        _validateGasPrice();
        _validateRouter(_account);
        _validateTokens(_collateralToken, _indexToken, _isLong);
        vaultUtils.validateIncreasePosition(_account, _collateralToken, _indexToken, _sizeDelta, _isLong);

        updateCumulativeFundingRate(_collateralToken, _indexToken);

        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 price = _isLong ? getMaxPrice(_indexToken) : getMinPrice(_indexToken);

        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && _sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(_indexToken, position.size, position.averagePrice, _isLong, price, _sizeDelta, position.lastIncreasedTime);
        }

        uint256 fee = _collectMarginFees(_account, _collateralToken, _indexToken, _isLong, _sizeDelta, position.size, position.entryFundingRate);
        uint256 collateralDelta = _transferIn(_collateralToken);
        uint256 collateralDeltaUsd = tokenToUsdMin(_collateralToken, collateralDelta);

        position.collateral = position.collateral.add(collateralDeltaUsd);
        _validate(position.collateral >= fee, 29);

        position.collateral = position.collateral.sub(fee);
        position.entryFundingRate = getEntryFundingRate(_collateralToken, _indexToken, _isLong);
        position.size = position.size.add(_sizeDelta);
        position.lastIncreasedTime = block.timestamp;

        _validate(position.size > 0, 30);
        _validatePosition(position.size, position.collateral);
        validateLiquidation(_account, _collateralToken, _indexToken, _isLong, true);

        // reserve tokens to pay profits on the position
        uint256 reserveDelta = usdToTokenMax(_collateralToken, _sizeDelta);
        position.reserveAmount = position.reserveAmount.add(reserveDelta);
        _increaseReservedAmount(_collateralToken, reserveDelta);

        if (_isLong) {
            // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
            // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
            // since (position.size - position.collateral) would have increased by `fee`
            _increaseGuaranteedUsd(_collateralToken, _sizeDelta.add(fee));
            _decreaseGuaranteedUsd(_collateralToken, collateralDeltaUsd);
            // treat the deposited collateral as part of the pool
            _increasePoolAmount(_collateralToken, collateralDelta);
            // fees need to be deducted from the pool since fees are deducted from position.collateral
            // and collateral is treated as part of the pool
            _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, fee));
        } else {
            if (globalShortSizes[_indexToken] == 0) {
                globalShortAveragePrices[_indexToken] = price;
            } else {
                globalShortAveragePrices[_indexToken] = getNextGlobalShortAveragePrice(_indexToken, price, _sizeDelta);
            }

            _increaseGlobalShortSize(_indexToken, _sizeDelta);
        }

        emit IncreasePosition(key, _account, _collateralToken, _indexToken, collateralDeltaUsd, _sizeDelta, _isLong, price, fee);
        emit UpdatePosition(key, position.size, position.collateral, position.averagePrice, position.entryFundingRate, position.reserveAmount, position.realisedPnl, price);
    }

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        _validateGasPrice();
        _validateRouter(_account);
        return _decreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
    }

    function _decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) private returns (uint256) {
        vaultUtils.validateDecreasePosition(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, _receiver);
        updateCumulativeFundingRate(_collateralToken, _indexToken);

        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position storage position = positions[key];
        _validate(position.size > 0, 31);
        _validate(position.size >= _sizeDelta, 32);
        _validate(position.collateral >= _collateralDelta, 33);

        uint256 collateral = position.collateral;
        // scrop variables to avoid stack too deep errors
        {
            uint256 reserveDelta = position.reserveAmount.mul(_sizeDelta).div(position.size);
            position.reserveAmount = position.reserveAmount.sub(reserveDelta);
            _decreaseReservedAmount(_collateralToken, reserveDelta);
        }

        (uint256 usdOut, uint256 usdOutAfterFee) = _reduceCollateral(_account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong);

        if (position.size != _sizeDelta) {
            position.entryFundingRate = getEntryFundingRate(_collateralToken, _indexToken, _isLong);
            position.size = position.size.sub(_sizeDelta);

            _validatePosition(position.size, position.collateral);
            validateLiquidation(_account, _collateralToken, _indexToken, _isLong, true);

            if (_isLong) {
                _increaseGuaranteedUsd(_collateralToken, collateral.sub(position.collateral));
                _decreaseGuaranteedUsd(_collateralToken, _sizeDelta);
            }

            uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
            emit DecreasePosition(key, _account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, price, usdOut.sub(usdOutAfterFee));
            emit UpdatePosition(key, position.size, position.collateral, position.averagePrice, position.entryFundingRate, position.reserveAmount, position.realisedPnl, price);
        } else {
            if (_isLong) {
                _increaseGuaranteedUsd(_collateralToken, collateral);
                _decreaseGuaranteedUsd(_collateralToken, _sizeDelta);
            }

            uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
            emit DecreasePosition(key, _account, _collateralToken, _indexToken, _collateralDelta, _sizeDelta, _isLong, price, usdOut.sub(usdOutAfterFee));
            emit ClosePosition(key, position.size, position.collateral, position.averagePrice, position.entryFundingRate, position.reserveAmount, position.realisedPnl);

            delete positions[key];
        }

        if (!_isLong) {
            _decreaseGlobalShortSize(_indexToken, _sizeDelta);
        }

        if (usdOut > 0) {
            if (_isLong) {
                _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, usdOut));
            }
            uint256 amountOutAfterFees = usdToTokenMin(_collateralToken, usdOutAfterFee);
            _transferOut(_collateralToken, amountOutAfterFees, _receiver);
            return amountOutAfterFees;
        }

        return 0;
    }

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external override nonReentrant {
        if (inPrivateLiquidationMode) {
            _validate(isLiquidator[msg.sender], 34);
        }

        // set includeAmmPrice to false to prevent manipulated liquidations
        includeAmmPrice = false;

        updateCumulativeFundingRate(_collateralToken, _indexToken);

        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        _validate(position.size > 0, 35);

        (uint256 liquidationState, uint256 marginFees) = validateLiquidation(_account, _collateralToken, _indexToken, _isLong, false);
        _validate(liquidationState != 0, 36);
        if (liquidationState == 2) {
            // max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(_account, _collateralToken, _indexToken, 0, position.size, _isLong, _account);
            includeAmmPrice = true;
            return;
        }

        uint256 feeTokens = usdToTokenMin(_collateralToken, marginFees);
        feeReserves[_collateralToken] = feeReserves[_collateralToken].add(feeTokens);
        emit CollectMarginFees(_collateralToken, marginFees, feeTokens);

        _decreaseReservedAmount(_collateralToken, position.reserveAmount);
        if (_isLong) {
            _decreaseGuaranteedUsd(_collateralToken, position.size.sub(position.collateral));
            _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, marginFees));
        }

        uint256 markPrice = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
        emit LiquidatePosition(key, _account, _collateralToken, _indexToken, _isLong, position.size, position.collateral, position.reserveAmount, position.realisedPnl, markPrice);

        if (!_isLong && marginFees < position.collateral) {
            uint256 remainingCollateral = position.collateral.sub(marginFees);
            _increasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, remainingCollateral));
        }

        if (!_isLong) {
            _decreaseGlobalShortSize(_indexToken, position.size);
        }

        delete positions[key];

        // pay the fee receiver using the pool, we assume that in general the liquidated amount should be sufficient to cover
        // the liquidation fees
        _decreasePoolAmount(_collateralToken, usdToTokenMin(_collateralToken, liquidationFeeUsd));
        _transferOut(_collateralToken, usdToTokenMin(_collateralToken, liquidationFeeUsd), _feeReceiver);

        includeAmmPrice = true;
    }

    // validateLiquidation returns (state, fees)
    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) public view returns (uint256, uint256) {
        return vaultUtils.validateLiquidation(_account, _collateralToken, _indexToken, _isLong, _raise);
    }

    function getMaxPrice(address _token) public view override returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token, true, includeAmmPrice, useSwapPricing);
    }

    function getMinPrice(address _token) public view override returns (uint256) {
        return IVaultPriceFeed(priceFeed).getPrice(_token, false, includeAmmPrice, useSwapPricing);
    }

    function getRedemptionAmount(address _token, uint256 _usdsAmount) public view override returns (uint256) {
        uint256 price = getMaxPrice(_token);
        uint256 redemptionAmount = _usdsAmount.mul(PRICE_PRECISION).div(price);
        return adjustForDecimals(redemptionAmount, usds, _token);
    }

    function getRedemptionCollateral(address _token) public view returns (uint256) {
        if (stableTokens[_token]) {
            return poolAmounts[_token];
        }
        uint256 collateral = usdToTokenMin(_token, guaranteedUsd[_token]);
        return collateral.add(poolAmounts[_token]).sub(reservedAmounts[_token]);
    }

    function getRedemptionCollateralUsd(address _token) public view returns (uint256) {
        return tokenToUsdMin(_token, getRedemptionCollateral(_token));
    }

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) public view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == usds ? USDS_DECIMALS : tokenDecimals[_tokenDiv];
        uint256 decimalsMul = _tokenMul == usds ? USDS_DECIMALS : tokenDecimals[_tokenMul];
        return _amount.mul(10**decimalsMul).div(10**decimalsDiv);
    }

    function tokenToUsdMin(address _token, uint256 _tokenAmount) public view override returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        uint256 price = getMinPrice(_token);
        uint256 decimals = tokenDecimals[_token];
        return _tokenAmount.mul(price).div(10**decimals);
    }

    function usdToTokenMax(address _token, uint256 _usdAmount) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return usdToToken(_token, _usdAmount, getMinPrice(_token));
    }

    function usdToTokenMin(address _token, uint256 _usdAmount) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return usdToToken(_token, _usdAmount, getMaxPrice(_token));
    }

    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        uint256 decimals = tokenDecimals[_token];
        return _usdAmount.mul(10**decimals).div(_price);
    }

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        uint256 realisedPnl = position.realisedPnl > 0 ? uint256(position.realisedPnl) : uint256(-position.realisedPnl);
        return (
            position.size, // 0
            position.collateral, // 1
            position.averagePrice, // 2
            position.entryFundingRate, // 3
            position.reserveAmount, // 4
            realisedPnl, // 5
            position.realisedPnl >= 0, // 6
            position.lastIncreasedTime // 7
        );
    }

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _collateralToken, _indexToken, _isLong));
    }

    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) public {
        bool shouldUpdate = vaultUtils.updateCumulativeFundingRate(_collateralToken, _indexToken);
        if (!shouldUpdate) {
            return;
        }

        if (lastFundingTimes[_collateralToken] == 0) {
            lastFundingTimes[_collateralToken] = block.timestamp.div(fundingInterval).mul(fundingInterval);
            return;
        }

        if (lastFundingTimes[_collateralToken].add(fundingInterval) > block.timestamp) {
            return;
        }

        uint256 fundingRate = getNextFundingRate(_collateralToken);
        cumulativeFundingRates[_collateralToken] = cumulativeFundingRates[_collateralToken].add(fundingRate);
        lastFundingTimes[_collateralToken] = block.timestamp.div(fundingInterval).mul(fundingInterval);

        emit UpdateFundingRate(_collateralToken, cumulativeFundingRates[_collateralToken]);
    }

    function getNextFundingRate(address _token) public view override returns (uint256) {
        if (lastFundingTimes[_token].add(fundingInterval) > block.timestamp) {
            return 0;
        }

        uint256 intervals = block.timestamp.sub(lastFundingTimes[_token]).div(fundingInterval);
        uint256 poolAmount = poolAmounts[_token];
        if (poolAmount == 0) {
            return 0;
        }

        uint256 _fundingRateFactor = stableTokens[_token] ? stableFundingRateFactor : fundingRateFactor;
        return _fundingRateFactor.mul(reservedAmounts[_token]).mul(intervals).div(poolAmount);
    }

    function getUtilisation(address _token) public view returns (uint256) {
        uint256 poolAmount = poolAmounts[_token];
        if (poolAmount == 0) {
            return 0;
        }

        return reservedAmounts[_token].mul(FUNDING_RATE_PRECISION).div(poolAmount);
    }

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public view returns (uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        _validate(position.collateral > 0, 37);
        return position.size.mul(BASIS_POINTS_DIVISOR).div(position.collateral);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) public view returns (uint256) {
        (bool hasProfit, uint256 delta) = getDelta(_indexToken, _size, _averagePrice, _isLong, _lastIncreasedTime);
        uint256 nextSize = _size.add(_sizeDelta);
        uint256 divisor;
        if (_isLong) {
            divisor = hasProfit ? nextSize.add(delta) : nextSize.sub(delta);
        } else {
            divisor = hasProfit ? nextSize.sub(delta) : nextSize.add(delta);
        }
        return _nextPrice.mul(nextSize).div(divisor);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextGlobalShortAveragePrice(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        uint256 size = globalShortSizes[_indexToken];
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice ? averagePrice.sub(_nextPrice) : _nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > _nextPrice;

        uint256 nextSize = size.add(_sizeDelta);
        uint256 divisor = hasProfit ? nextSize.sub(delta) : nextSize.add(delta);

        return _nextPrice.mul(nextSize).div(divisor);
    }

    function getGlobalShortDelta(address _token) public view returns (bool, uint256) {
        uint256 size = globalShortSizes[_token];
        if (size == 0) {
            return (false, 0);
        }

        uint256 nextPrice = getMaxPrice(_token);
        uint256 averagePrice = globalShortAveragePrices[_token];
        uint256 priceDelta = averagePrice > nextPrice ? averagePrice.sub(nextPrice) : nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > nextPrice;

        return (hasProfit, delta);
    }

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public view returns (bool, uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position memory position = positions[key];
        return getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
    }

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) public view override returns (bool, uint256) {
        _validate(_averagePrice > 0, 38);
        uint256 price = _isLong ? getMinPrice(_indexToken) : getMaxPrice(_indexToken);
        uint256 priceDelta = _averagePrice > price ? _averagePrice.sub(price) : price.sub(_averagePrice);
        uint256 delta = _size.mul(priceDelta).div(_averagePrice);

        bool hasProfit;

        if (_isLong) {
            hasProfit = price > _averagePrice;
        } else {
            hasProfit = _averagePrice > price;
        }

        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        uint256 minBps = block.timestamp > _lastIncreasedTime.add(minProfitTime) ? 0 : minProfitBasisPoints[_indexToken];
        if (hasProfit && delta.mul(BASIS_POINTS_DIVISOR) <= _size.mul(minBps)) {
            delta = 0;
        }

        return (hasProfit, delta);
    }

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) public view returns (uint256) {
        return vaultUtils.getEntryFundingRate(_collateralToken, _indexToken, _isLong);
    }

    function getFundingFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) public view returns (uint256) {
        return vaultUtils.getFundingFee(_account, _collateralToken, _indexToken, _isLong, _size, _entryFundingRate);
    }

    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        return vaultUtils.getPositionFee(_account, _collateralToken, _indexToken, _isLong, _sizeDelta);
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(
        address _token,
        uint256 _usdsDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) public view override returns (uint256) {
        return vaultUtils.getFeeBasisPoints(_token, _usdsDelta, _feeBasisPoints, _taxBasisPoints, _increment);
    }

    function getTargetUsdsAmount(address _token) public view override returns (uint256) {
        uint256 supply = IERC20(usds).totalSupply();
        if (supply == 0) {
            return 0;
        }
        uint256 weight = tokenWeights[_token];
        return weight.mul(supply).div(totalTokenWeights);
    }

    function _reduceCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong
    ) private returns (uint256, uint256) {
        bytes32 key = getPositionKey(_account, _collateralToken, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 fee = _collectMarginFees(_account, _collateralToken, _indexToken, _isLong, _sizeDelta, position.size, position.entryFundingRate);
        bool hasProfit;
        uint256 adjustedDelta;

        // scope variables to avoid stack too deep errors
        {
            (bool _hasProfit, uint256 delta) = getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
            hasProfit = _hasProfit;
            // get the proportional change in pnl
            adjustedDelta = _sizeDelta.mul(delta).div(position.size);
        }

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);

            // pay out realised profits from the pool amount for short positions
            if (!_isLong) {
                uint256 tokenAmount = usdToTokenMin(_collateralToken, adjustedDelta);
                _decreasePoolAmount(_collateralToken, tokenAmount);
            }
        }

        if (!hasProfit && adjustedDelta > 0) {
            position.collateral = position.collateral.sub(adjustedDelta);

            // transfer realised losses to the pool for short positions
            // realised losses for long positions are not transferred here as
            // _increasePoolAmount was already called in increasePosition for longs
            if (!_isLong) {
                uint256 tokenAmount = usdToTokenMin(_collateralToken, adjustedDelta);
                _increasePoolAmount(_collateralToken, tokenAmount);
            }

            position.realisedPnl = position.realisedPnl - int256(adjustedDelta);
        }

        // reduce the position's collateral by _collateralDelta
        // transfer _collateralDelta out
        if (_collateralDelta > 0) {
            usdOut = usdOut.add(_collateralDelta);
            position.collateral = position.collateral.sub(_collateralDelta);
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut = usdOut.add(position.collateral);
            position.collateral = 0;
        }

        // if the usdOut is more than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        uint256 usdOutAfterFee = usdOut;
        if (usdOut > fee) {
            usdOutAfterFee = usdOut.sub(fee);
        } else {
            position.collateral = position.collateral.sub(fee);
            if (_isLong) {
                uint256 feeTokens = usdToTokenMin(_collateralToken, fee);
                _decreasePoolAmount(_collateralToken, feeTokens);
            }
        }

        emit UpdatePnl(key, hasProfit, adjustedDelta);

        return (usdOut, usdOutAfterFee);
    }

    function _validatePosition(uint256 _size, uint256 _collateral) private view {
        if (_size == 0) {
            _validate(_collateral == 0, 39);
            return;
        }
        _validate(_size >= _collateral, 40);
    }

    function _validateRouter(address _account) private view {
        if (msg.sender == _account) {
            return;
        }
        if (msg.sender == router) {
            return;
        }
        _validate(approvedRouters[_account][msg.sender], 41);
    }

    function _validateTokens(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private view {
        if (_isLong) {
            _validate(_collateralToken == _indexToken, 42);
            _validate(whitelistedTokens[_collateralToken], 43);
            _validate(!stableTokens[_collateralToken], 44);
            return;
        }

        _validate(whitelistedTokens[_collateralToken], 45);
        _validate(stableTokens[_collateralToken], 46);
        _validate(!stableTokens[_indexToken], 47);
        _validate(shortableTokens[_indexToken], 48);
    }

    function _collectSwapFees(
        address _token,
        uint256 _amount,
        uint256 _feeBasisPoints
    ) private returns (uint256) {
        uint256 afterFeeAmount = _amount.mul(BASIS_POINTS_DIVISOR.sub(_feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = _amount.sub(afterFeeAmount);
        feeReserves[_token] = feeReserves[_token].add(feeAmount);
        emit CollectSwapFees(_token, tokenToUsdMin(_token, feeAmount), feeAmount);
        return afterFeeAmount;
    }

    function _collectMarginFees(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryFundingRate
    ) private returns (uint256) {
        uint256 feeUsd = getPositionFee(_account, _collateralToken, _indexToken, _isLong, _sizeDelta);

        uint256 fundingFee = getFundingFee(_account, _collateralToken, _indexToken, _isLong, _size, _entryFundingRate);
        feeUsd = feeUsd.add(fundingFee);

        uint256 feeTokens = usdToTokenMin(_collateralToken, feeUsd);
        feeReserves[_collateralToken] = feeReserves[_collateralToken].add(feeTokens);

        emit CollectMarginFees(_collateralToken, feeUsd, feeTokens);
        return feeUsd;
    }

    function _transferIn(address _token) private returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;

        return nextBalance.sub(prevBalance);
    }

    function _transferOut(
        address _token,
        uint256 _amount,
        address _receiver
    ) private {
        IERC20(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20(_token).balanceOf(address(this));
    }

    function _updateTokenBalance(address _token) private {
        uint256 nextBalance = IERC20(_token).balanceOf(address(this));
        tokenBalances[_token] = nextBalance;
    }

    function _increasePoolAmount(address _token, uint256 _amount) private {
        poolAmounts[_token] = poolAmounts[_token].add(_amount);
        uint256 balance = IERC20(_token).balanceOf(address(this));
        _validate(poolAmounts[_token] <= balance, 49);
        emit IncreasePoolAmount(_token, _amount);
    }

    function _decreasePoolAmount(address _token, uint256 _amount) private {
        poolAmounts[_token] = poolAmounts[_token].sub(_amount, "Vault: poolAmount exceeded");
        _validate(reservedAmounts[_token] <= poolAmounts[_token], 50);
        emit DecreasePoolAmount(_token, _amount);
    }

    function _validateBufferAmount(address _token) private view {
        if (poolAmounts[_token] < bufferAmounts[_token]) {
            revert("Vault: poolAmount < buffer");
        }
    }

    function _increaseUsdsAmount(address _token, uint256 _amount) private {
        usdsAmounts[_token] = usdsAmounts[_token].add(_amount);
        uint256 maxUsdsAmount = maxUsdsAmounts[_token];
        if (maxUsdsAmount != 0) {
            _validate(usdsAmounts[_token] <= maxUsdsAmount, 51);
        }
        emit IncreaseUsdsAmount(_token, _amount);
    }

    function _decreaseUsdsAmount(address _token, uint256 _amount) private {
        uint256 value = usdsAmounts[_token];
        // since USDS can be minted using multiple assets
        // it is possible for the USDS debt for a single asset to be less than zero
        // the USDS debt is capped to zero for this case
        if (value <= _amount) {
            usdsAmounts[_token] = 0;
            emit DecreaseUsdsAmount(_token, value);
            return;
        }
        usdsAmounts[_token] = value.sub(_amount);
        emit DecreaseUsdsAmount(_token, _amount);
    }

    function _increaseReservedAmount(address _token, uint256 _amount) private {
        reservedAmounts[_token] = reservedAmounts[_token].add(_amount);
        _validate(reservedAmounts[_token] <= poolAmounts[_token], 52);
        emit IncreaseReservedAmount(_token, _amount);
    }

    function _decreaseReservedAmount(address _token, uint256 _amount) private {
        reservedAmounts[_token] = reservedAmounts[_token].sub(_amount, "Vault: insufficient reserve");
        emit DecreaseReservedAmount(_token, _amount);
    }

    function _increaseGuaranteedUsd(address _token, uint256 _usdAmount) private {
        guaranteedUsd[_token] = guaranteedUsd[_token].add(_usdAmount);
        emit IncreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _decreaseGuaranteedUsd(address _token, uint256 _usdAmount) private {
        guaranteedUsd[_token] = guaranteedUsd[_token].sub(_usdAmount);
        emit DecreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _increaseGlobalShortSize(address _token, uint256 _amount) private {
        globalShortSizes[_token] = globalShortSizes[_token].add(_amount);

        uint256 maxSize = maxGlobalShortSizes[_token];
        if (maxSize != 0) {
            require(globalShortSizes[_token] <= maxSize, "Vault: max shorts exceeded");
        }
    }

    function _decreaseGlobalShortSize(address _token, uint256 _amount) private {
        uint256 size = globalShortSizes[_token];
        if (_amount > size) {
            globalShortSizes[_token] = 0;
            return;
        }

        globalShortSizes[_token] = size.sub(_amount);
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _onlyGov() private view {
        _validate(msg.sender == gov, 53);
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateManager() private view {
        if (inManagerMode) {
            _validate(isManager[msg.sender], 54);
        }
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateGasPrice() private view {
        if (maxGasPrice == 0) {
            return;
        }
        _validate(tx.gasprice <= maxGasPrice, 55);
    }

    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, errors[_errorCode]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./interfaces/IVault.sol";
import "../access/Governable.sol";

contract VaultErrorController is Governable {
    function setErrors(IVault _vault, string[] calldata _errors) external onlyGov {
        for (uint256 i = 0; i < _errors.length; i++) {
            _vault.setError(i, _errors[i]);
        }
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";

import "./interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IPriceFeed.sol";
import "../oracle/interfaces/ISecondaryPriceFeed.sol";

pragma solidity 0.6.12;

contract VaultPriceFeed is IVaultPriceFeed {
    using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10**30;
    uint256 public constant ONE_USD = PRICE_PRECISION;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant MAX_SPREAD_BASIS_POINTS = 50;
    uint256 public constant MAX_ADJUSTMENT_INTERVAL = 2 hours;
    uint256 public constant MAX_ADJUSTMENT_BASIS_POINTS = 20;

    address public gov;

    bool public isSecondaryPriceEnabled = true;
    bool public favorPrimaryPrice = false;
    uint256 public priceSampleSpace = 3;
    uint256 public maxStrictPriceDeviation = 0;
    address public secondaryPriceFeed;
    uint256 public spreadThresholdBasisPoints = 30;


    mapping(address => address) public priceFeeds;
    mapping(address => uint256) public priceDecimals;
    mapping(address => uint256) public spreadBasisPoints;
    // Chainlink can return prices for stablecoins
    // that differs from 1 USD by a larger percentage than stableSwapFeeBasisPoints
    // we use strictStableTokens to cap the price to 1 USD
    // this allows us to configure stablecoins like DAI as being a stableToken
    // while not being a strictStableToken
    mapping(address => bool) public strictStableTokens;

    mapping(address => uint256) public override adjustmentBasisPoints;
    mapping(address => bool) public override isAdjustmentAdditive;
    mapping(address => uint256) public lastAdjustmentTimings;

    modifier onlyGov() {
        require(msg.sender == gov, "VaultPriceFeed: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external override onlyGov {
        require(lastAdjustmentTimings[_token].add(MAX_ADJUSTMENT_INTERVAL) < block.timestamp, "VaultPriceFeed: adjustment frequency exceeded");
        require(_adjustmentBps <= MAX_ADJUSTMENT_BASIS_POINTS, "invalid _adjustmentBps");
        isAdjustmentAdditive[_token] = _isAdditive;
        adjustmentBasisPoints[_token] = _adjustmentBps;
        lastAdjustmentTimings[_token] = block.timestamp;
    }

    function setIsSecondaryPriceEnabled(bool _isEnabled) external override onlyGov {
        isSecondaryPriceEnabled = _isEnabled;
    }

    function setSecondaryPriceFeed(address _secondaryPriceFeed) external onlyGov {
        secondaryPriceFeed = _secondaryPriceFeed;
    }

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints) external override onlyGov {
        require(_spreadBasisPoints <= MAX_SPREAD_BASIS_POINTS, "VaultPriceFeed: invalid _spreadBasisPoints");
        spreadBasisPoints[_token] = _spreadBasisPoints;
    }

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints) external override onlyGov {
        spreadThresholdBasisPoints = _spreadThresholdBasisPoints;
    }

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external override onlyGov {
        favorPrimaryPrice = _favorPrimaryPrice;
    }

    function setPriceSampleSpace(uint256 _priceSampleSpace) external override onlyGov {
        require(_priceSampleSpace > 0, "VaultPriceFeed: invalid _priceSampleSpace");
        priceSampleSpace = _priceSampleSpace;
    }

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation) external override onlyGov {
        maxStrictPriceDeviation = _maxStrictPriceDeviation;
    }

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external override onlyGov {
        priceFeeds[_token] = _priceFeed;
        priceDecimals[_token] = _priceDecimals;
        strictStableTokens[_token] = _isStrictStable;
    }

    function getPrice(
        address _token,
        bool _maximise,
        bool /*_includeAmmPrice */,
        bool /* _useSwapPricing */
    ) public view override returns (uint256) {
        uint256 price = getPriceV1(_token, _maximise);

        uint256 adjustmentBps = adjustmentBasisPoints[_token];
        if (adjustmentBps > 0) {
            bool isAdditive = isAdjustmentAdditive[_token];
            if (isAdditive) {
                price = price.mul(BASIS_POINTS_DIVISOR.add(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            } else {
                price = price.mul(BASIS_POINTS_DIVISOR.sub(adjustmentBps)).div(BASIS_POINTS_DIVISOR);
            }
        }

        return price;
    }

    function getPriceV1(
        address _token,
        bool _maximise
    ) public view returns (uint256) {
        uint256 price = getPrimaryPrice(_token, _maximise);


        if (isSecondaryPriceEnabled) {
            price = getSecondaryPrice(_token, price, _maximise);
        }

        if (strictStableTokens[_token]) {
            uint256 delta = price > ONE_USD ? price.sub(ONE_USD) : ONE_USD.sub(price);
            if (delta <= maxStrictPriceDeviation) {
                return ONE_USD;
            }

            // if _maximise and price is e.g. 1.02, return 1.02
            if (_maximise && price > ONE_USD) {
                return price;
            }

            // if !_maximise and price is e.g. 0.98, return 0.98
            if (!_maximise && price < ONE_USD) {
                return price;
            }

            return ONE_USD;
        }

        uint256 _spreadBasisPoints = spreadBasisPoints[_token];

        if (_maximise) {
            return price.mul(BASIS_POINTS_DIVISOR.add(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
        }

        return price.mul(BASIS_POINTS_DIVISOR.sub(_spreadBasisPoints)).div(BASIS_POINTS_DIVISOR);
    }

    function getLatestPrimaryPrice(address _token) public override view returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        int256 price = priceFeed.latestAnswer();
        require(price > 0, "VaultPriceFeed: invalid price");

        return uint256(price);
    }   

    function getPrimaryPrice(address _token, bool _maximise) public view override returns (uint256) {
        address priceFeedAddress = priceFeeds[_token];
        require(priceFeedAddress != address(0), "VaultPriceFeed: invalid price feed");

        IPriceFeed priceFeed = IPriceFeed(priceFeedAddress);

        uint256 price = 0;
        uint80 roundId = priceFeed.latestRound();

        for (uint80 i = 0; i < priceSampleSpace; i++) {
            if (roundId <= i) {
                break;
            }
            uint256 p;

            if (i == 0) {
                int256 _p = priceFeed.latestAnswer();
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            } else {
                (, int256 _p, , , ) = priceFeed.getRoundData(roundId - i);
                require(_p > 0, "VaultPriceFeed: invalid price");
                p = uint256(_p);
            }

            if (price == 0) {
                price = p;
                continue;
            }

            if (_maximise && p > price) {
                price = p;
                continue;
            }

            if (!_maximise && p < price) {
                price = p;
            }
        }

        require(price > 0, "VaultPriceFeed: could not fetch price");
        // normalise price precision
        uint256 _priceDecimals = priceDecimals[_token];
        return price.mul(PRICE_PRECISION).div(10**_priceDecimals);
    }

    function getSecondaryPrice(
        address _token,
        uint256 _referencePrice,
        bool _maximise
    ) public view returns (uint256) {
        if (secondaryPriceFeed == address(0)) {
            return _referencePrice;
        }
        return ISecondaryPriceFeed(secondaryPriceFeed).getPrice(_token, _referencePrice, _maximise);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";

import "../access/Governable.sol";

contract VaultUtils is IVaultUtils, Governable {
    using SafeMath for uint256;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    IVault public vault;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;

    constructor(IVault _vault) public {
        vault = _vault;
    }

    function updateCumulativeFundingRate(
        address, /* _collateralToken */
        address /* _indexToken */
    ) public override returns (bool) {
        return true;
    }

    function validateIncreasePosition(
        address, /* _account */
        address, /* _collateralToken */
        address, /* _indexToken */
        uint256, /* _sizeDelta */
        bool /* _isLong */
    ) external view override {
        // no additional validations
    }

    function validateDecreasePosition(
        address, /* _account */
        address, /* _collateralToken */
        address, /* _indexToken */
        uint256, /* _collateralDelta */
        uint256, /* _sizeDelta */
        bool, /* _isLong */
        address /* _receiver */
    ) external view override {
        // no additional validations
    }

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) internal view returns (Position memory) {
        IVault _vault = vault;
        Position memory position;
        {
            (
                uint256 size,
                uint256 collateral,
                uint256 averagePrice,
                uint256 entryFundingRate, /* reserveAmount */ /* realisedPnl */ /* hasProfit */
                ,
                ,
                ,
                uint256 lastIncreasedTime
            ) = _vault.getPosition(_account, _collateralToken, _indexToken, _isLong);
            position.size = size;
            position.collateral = collateral;
            position.averagePrice = averagePrice;
            position.entryFundingRate = entryFundingRate;
            position.lastIncreasedTime = lastIncreasedTime;
        }
        return position;
    }

    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) public view override returns (uint256, uint256) {
        Position memory position = getPosition(_account, _collateralToken, _indexToken, _isLong);
        IVault _vault = vault;

        (bool hasProfit, uint256 delta) = _vault.getDelta(_indexToken, position.size, position.averagePrice, _isLong, position.lastIncreasedTime);
        uint256 marginFees = getFundingFee(_account, _collateralToken, _indexToken, _isLong, position.size, position.entryFundingRate);
        marginFees = marginFees.add(getPositionFee(_account, _collateralToken, _indexToken, _isLong, position.size));

        if (!hasProfit && position.collateral < delta) {
            if (_raise) {
                revert("Vault: losses exceed collateral");
            }
            return (1, marginFees);
        }

        uint256 remainingCollateral = position.collateral;
        if (!hasProfit) {
            remainingCollateral = position.collateral.sub(delta);
        }

        if (remainingCollateral < marginFees) {
            if (_raise) {
                revert("Vault: fees exceed collateral");
            }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral);
        }

        if (remainingCollateral < marginFees.add(_vault.liquidationFeeUsd())) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return (1, marginFees);
        }

        if (remainingCollateral.mul(_vault.maxLeverage()) < position.size.mul(BASIS_POINTS_DIVISOR)) {
            if (_raise) {
                revert("Vault: maxLeverage exceeded");
            }
            return (2, marginFees);
        }

        return (0, marginFees);
    }

    function getEntryFundingRate(
        address _collateralToken,
        address, /* _indexToken */
        bool /* _isLong */
    ) public view override returns (uint256) {
        return vault.cumulativeFundingRates(_collateralToken);
    }

    function getPositionFee(
        address, /* _account */
        address, /* _collateralToken */
        address, /* _indexToken */
        bool, /* _isLong */
        uint256 _sizeDelta
    ) public view override returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }
        uint256 afterFeeUsd = _sizeDelta.mul(BASIS_POINTS_DIVISOR.sub(vault.marginFeeBasisPoints())).div(BASIS_POINTS_DIVISOR);
        return _sizeDelta.sub(afterFeeUsd);
    }

    function getFundingFee(
        address, /* _account */
        address _collateralToken,
        address, /* _indexToken */
        bool, /* _isLong */
        uint256 _size,
        uint256 _entryFundingRate
    ) public view override returns (uint256) {
        if (_size == 0) {
            return 0;
        }

        uint256 fundingRate = vault.cumulativeFundingRates(_collateralToken).sub(_entryFundingRate);
        if (fundingRate == 0) {
            return 0;
        }

        return _size.mul(fundingRate).div(FUNDING_RATE_PRECISION);
    }

    function getBuyUsdsFeeBasisPoints(address _token, uint256 _usdsAmount) public view override returns (uint256) {
        return getFeeBasisPoints(_token, _usdsAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), true);
    }

    function getSellUsdsFeeBasisPoints(address _token, uint256 _usdsAmount) public view override returns (uint256) {
        return getFeeBasisPoints(_token, _usdsAmount, vault.mintBurnFeeBasisPoints(), vault.taxBasisPoints(), false);
    }

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdsAmount
    ) public view override returns (uint256) {
        bool isStableSwap = vault.stableTokens(_tokenIn) && vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap ? vault.stableSwapFeeBasisPoints() : vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap ? vault.stableTaxBasisPoints() : vault.taxBasisPoints();
        uint256 feesBasisPoints0 = getFeeBasisPoints(_tokenIn, _usdsAmount, baseBps, taxBps, true);
        uint256 feesBasisPoints1 = getFeeBasisPoints(_tokenOut, _usdsAmount, baseBps, taxBps, false);
        // use the higher of the two fee basis points
        return feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
    }

    // cases to consider
    // 1. initialAmount is far from targetAmount, action increases balance slightly => high rebate
    // 2. initialAmount is far from targetAmount, action increases balance largely => high rebate
    // 3. initialAmount is close to targetAmount, action increases balance slightly => low rebate
    // 4. initialAmount is far from targetAmount, action reduces balance slightly => high tax
    // 5. initialAmount is far from targetAmount, action reduces balance largely => high tax
    // 6. initialAmount is close to targetAmount, action reduces balance largely => low tax
    // 7. initialAmount is above targetAmount, nextAmount is below targetAmount and vice versa
    // 8. a large swap should have similar fees as the same trade split into multiple smaller swaps
    function getFeeBasisPoints(
        address _token,
        uint256 _usdsDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) public view override returns (uint256) {
        if (!vault.hasDynamicFees()) {
            return _feeBasisPoints;
        }

        uint256 initialAmount = vault.usdsAmounts(_token);
        uint256 nextAmount = initialAmount.add(_usdsDelta);
        if (!_increment) {
            nextAmount = _usdsDelta > initialAmount ? 0 : initialAmount.sub(_usdsDelta);
        }

        uint256 targetAmount = vault.getTargetUsdsAmount(_token);
        if (targetAmount == 0) {
            return _feeBasisPoints;
        }

        uint256 initialDiff = initialAmount > targetAmount ? initialAmount.sub(targetAmount) : targetAmount.sub(initialAmount);
        uint256 nextDiff = nextAmount > targetAmount ? nextAmount.sub(targetAmount) : targetAmount.sub(nextAmount);

        // action improves relative asset balance
        if (nextDiff < initialDiff) {
            uint256 rebateBps = _taxBasisPoints.mul(initialDiff).div(targetAmount);
            return rebateBps > _feeBasisPoints ? 0 : _feeBasisPoints.sub(rebateBps);
        }

        uint256 averageDiff = initialDiff.add(nextDiff).div(2);
        if (averageDiff > targetAmount) {
            averageDiff = targetAmount;
        }
        uint256 taxBps = _taxBasisPoints.mul(averageDiff).div(targetAmount);
        return _feeBasisPoints.add(taxBps);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../GSN/Context.sol";

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../GSN/Context.sol";
import "./IERC20.sol";
import "../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../../GSN/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping(address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return
            _tokenOwners.get(
                tokenId,
                "ERC721: owner query for nonexistent token"
            );
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @dev Returns the base URI set via {_setBaseURI}. This will be
     * automatically added as a prefix in {tokenURI} to each token's URI, or
     * to the token ID if no specific URI is set for that token ID.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(
            abi.encodeWithSelector(
                IERC721Receiver(to).onERC721Received.selector,
                _msgSender(),
                from,
                tokenId,
                _data
            ),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import "./IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SA");
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "STE");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        return _get(map, key, "EnumerableMap: nonexistent key");
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint256(value)));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint256(_get(map._inner, bytes32(key), errorMessage)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

enum OrderType{ SWAP, INCREASE, DECREASE }

struct Orders {
    address account;
    uint256 orderIndex;
    OrderType orderType;
}

struct IndexValue { uint256 keyIndex; Orders value; }
struct KeyFlag { uint256 key; bool deleted; }

struct itmap {
    mapping(uint256 => IndexValue) data;
    KeyFlag[] keys;
    uint256 size;
}

library IterableMapping {
    function insert(itmap storage self, uint256 key, Orders memory value) internal returns (bool replaced) {
        uint256 keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, uint256 key) internal returns (bool success) {
        uint256 keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contains(itmap storage self, uint256 key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterate_start(itmap storage self) internal view returns (uint256 keyIndex) {
        return iterate_next(self, uint256(-1));
    }

    function iterate_valid(itmap storage self, uint256 keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint256 keyIndex) internal view returns (uint256 r_keyIndex) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get(itmap storage self, uint256 keyIndex) internal view returns (uint256 key, Orders memory value) {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

    constructor() internal {
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

pragma solidity ^0.6.12;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";

import "./interfaces/IFastPriceEvents.sol";
import "../access/Governable.sol";

pragma solidity 0.6.12;

contract FastPriceEvents is IFastPriceEvents, Governable {
    mapping(address => bool) public isPriceFeed;
    event PriceUpdate(address token, uint256 price, address priceFeed);

    function setIsPriceFeed(address _priceFeed, bool _isPriceFeed) external onlyGov {
        isPriceFeed[_priceFeed] = _isPriceFeed;
    }

    function emitPriceEvent(address _token, uint256 _price) external override {
        require(isPriceFeed[msg.sender], "FastPriceEvents: invalid sender");
        emit PriceUpdate(_token, _price, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

import "../libraries/math/SafeMath.sol";

import "./interfaces/ISecondaryPriceFeed.sol";
import "./interfaces/IFastPriceFeed.sol";
import "./interfaces/IFastPriceEvents.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IPositionRouter.sol";
import "../access/Governable.sol";

pragma solidity 0.6.12;

contract FastPriceFeed is ISecondaryPriceFeed, IFastPriceFeed, Governable {
    using SafeMath for uint256;

    // fit data in a uint256 slot to save gas costs
    struct PriceDataItem {
        uint160 refPrice; // Chainlink price
        uint32 refTime; // last updated at time
        uint32 cumulativeRefDelta; // cumulative Chainlink price delta
        uint32 cumulativeFastDelta; // cumulative fast price delta
    }

    uint256 public constant PRICE_PRECISION = 10 ** 30;

    uint256 public constant CUMULATIVE_DELTA_PRECISION = 10 * 1000 * 1000;

    uint256 public constant MAX_REF_PRICE = type(uint160).max;
    uint256 public constant MAX_CUMULATIVE_REF_DELTA = type(uint32).max;
    uint256 public constant MAX_CUMULATIVE_FAST_DELTA = type(uint32).max;

    // uint256(~0) is 256 bits of 1s
    // shift the 1s by (256 - 32) to get (256 - 32) 0s followed by 32 1s
    uint256 constant public BITMASK_32 = uint256(~0) >> (256 - 32);

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    uint256 public constant MAX_PRICE_DURATION = 30 minutes;

    bool public isInitialized;
    bool public isSpreadEnabled = false;

    address public vaultPriceFeed;
    address public fastPriceEvents;

    address public tokenManager;

    address public positionRouter;

    uint256 public override lastUpdatedAt;
    uint256 public override lastUpdatedBlock;

    uint256 public priceDuration;
    uint256 public maxPriceUpdateDelay;
    uint256 public spreadBasisPointsIfInactive;
    uint256 public spreadBasisPointsIfChainError;
    uint256 public minBlockInterval;
    uint256 public maxTimeDeviation;

    uint256 public priceDataInterval;

    // allowed deviation from primary price
    uint256 public maxDeviationBasisPoints;

    uint256 public minAuthorizations;
    uint256 public disableFastPriceVoteCount = 0;

    mapping (address => bool) public isUpdater;

    mapping (address => uint256) public prices;
    mapping (address => PriceDataItem) public priceData;
    mapping (address => uint256) public maxCumulativeDeltaDiffs;

    mapping (address => bool) public isSigner;
    mapping (address => bool) public disableFastPriceVotes;

    // array of tokens used in setCompactedPrices, saves L1 calldata gas costs
    address[] public tokens;
    // array of tokenPrecisions used in setCompactedPrices, saves L1 calldata gas costs
    // if the token price will be sent with 3 decimals, then tokenPrecision for that token
    // should be 10 ** 3
    uint256[] public tokenPrecisions;

    event DisableFastPrice(address signer);
    event EnableFastPrice(address signer);
    event PriceData(address token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event MaxCumulativeDeltaDiffExceeded(address token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);

    modifier onlySigner() {
        require(isSigner[msg.sender], "FastPriceFeed: forbidden");
        _;
    }

    modifier onlyUpdater() {
        require(isUpdater[msg.sender], "FastPriceFeed: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "FastPriceFeed: forbidden");
        _;
    }

    constructor(
      uint256 _priceDuration,
      uint256 _maxPriceUpdateDelay,
      uint256 _minBlockInterval,
      uint256 _maxDeviationBasisPoints,
      address _fastPriceEvents,
      address _tokenManager,
      address _positionRouter
    ) public {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        priceDuration = _priceDuration;
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        minBlockInterval = _minBlockInterval;
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        fastPriceEvents = _fastPriceEvents;
        tokenManager = _tokenManager;
        positionRouter = _positionRouter;
    }

    function initialize(uint256 _minAuthorizations, address[] memory _signers, address[] memory _updaters) public onlyGov {
        require(!isInitialized, "FastPriceFeed: already initialized");
        isInitialized = true;

        minAuthorizations = _minAuthorizations;

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            isSigner[signer] = true;
        }

        for (uint256 i = 0; i < _updaters.length; i++) {
            address updater = _updaters[i];
            isUpdater[updater] = true;
        }
    }

    function setSigner(address _account, bool _isActive) external override onlyGov {
        isSigner[_account] = _isActive;
    }

    function setUpdater(address _account, bool _isActive) external override onlyGov {
        isUpdater[_account] = _isActive;
    }

    function setFastPriceEvents(address _fastPriceEvents) external onlyGov {
      fastPriceEvents = _fastPriceEvents;
    }

    function setVaultPriceFeed(address _vaultPriceFeed) external override onlyGov {
      vaultPriceFeed = _vaultPriceFeed;
    }

    function setMaxTimeDeviation(uint256 _maxTimeDeviation) external onlyGov {
        maxTimeDeviation = _maxTimeDeviation;
    }

    function setPriceDuration(uint256 _priceDuration) external override onlyGov {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        priceDuration = _priceDuration;
    }

    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external override onlyGov {
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
    }

    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external override onlyGov {
        spreadBasisPointsIfInactive = _spreadBasisPointsIfInactive;
    }

    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external override onlyGov {
        spreadBasisPointsIfChainError = _spreadBasisPointsIfChainError;
    }

    function setMinBlockInterval(uint256 _minBlockInterval) external override onlyGov {
        minBlockInterval = _minBlockInterval;
    }

    function setIsSpreadEnabled(bool _isSpreadEnabled) external override onlyGov {
        isSpreadEnabled = _isSpreadEnabled;
    }

    function setLastUpdatedAt(uint256 _lastUpdatedAt) external onlyGov {
        lastUpdatedAt = _lastUpdatedAt;
    }

    function setTokenManager(address _tokenManager) external onlyTokenManager {
        tokenManager = _tokenManager;
    }

    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints) external override onlyTokenManager {
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
    }

    function setMaxCumulativeDeltaDiffs(address[] memory _tokens,  uint256[] memory _maxCumulativeDeltaDiffs) external override onlyTokenManager {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            maxCumulativeDeltaDiffs[token] = _maxCumulativeDeltaDiffs[i];
        }
    }

    function setPriceDataInterval(uint256 _priceDataInterval) external override onlyTokenManager {
        priceDataInterval = _priceDataInterval;
    }

    function setMinAuthorizations(uint256 _minAuthorizations) external onlyTokenManager {
        minAuthorizations = _minAuthorizations;
    }

    function setTokens(address[] memory _tokens, uint256[] memory _tokenPrecisions) external onlyGov {
        require(_tokens.length == _tokenPrecisions.length, "FastPriceFeed: invalid lengths");
        tokens = _tokens;
        tokenPrecisions = _tokenPrecisions;
    }

    function setPrices(address[] memory _tokens, uint256[] memory _prices, uint256 _timestamp) external onlyUpdater {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 i = 0; i < _tokens.length; i++) {
                address token = _tokens[i];
                _setPrice(token, _prices[i], _vaultPriceFeed, _fastPriceEvents);
            }
        }
    }

    function setCompactedPrices(uint256[] memory _priceBitArray, uint256 _timestamp) external onlyUpdater {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 i = 0; i < _priceBitArray.length; i++) {
                uint256 priceBits = _priceBitArray[i];

                for (uint256 j = 0; j < 8; j++) {
                    uint256 index = i * 8 + j;
                    if (index >= tokens.length) { return; }

                    uint256 startBit = 32 * j;
                    uint256 price = (priceBits >> startBit) & BITMASK_32;

                    address token = tokens[i * 8 + j];
                    uint256 tokenPrecision = tokenPrecisions[i * 8 + j];
                    uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(tokenPrecision);

                    _setPrice(token, adjustedPrice, _vaultPriceFeed, _fastPriceEvents);
                }
            }
        }
    }

    function setPricesWithBits(uint256 _priceBits, uint256 _timestamp) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);
    }

    function setPricesWithBitsAndExecute(
        uint256 _priceBits,
        uint256 _timestamp,
        uint256 _endIndexForIncreasePositions,
        uint256 _endIndexForDecreasePositions,
        uint256 _maxIncreasePositions,
        uint256 _maxDecreasePositions
    ) external onlyUpdater {
        _setPricesWithBits(_priceBits, _timestamp);

        IPositionRouter _positionRouter = IPositionRouter(positionRouter);
        uint256 maxEndIndexForIncrease = _positionRouter.increasePositionRequestKeysStart().add(_maxIncreasePositions);
        uint256 maxEndIndexForDecrease = _positionRouter.decreasePositionRequestKeysStart().add(_maxDecreasePositions);

        if (_endIndexForIncreasePositions > maxEndIndexForIncrease) {
            _endIndexForIncreasePositions = maxEndIndexForIncrease;
        }

        if (_endIndexForDecreasePositions > maxEndIndexForDecrease) {
            _endIndexForDecreasePositions = maxEndIndexForDecrease;
        }

        _positionRouter.executeIncreasePositions(_endIndexForIncreasePositions, payable(msg.sender));
        _positionRouter.executeDecreasePositions(_endIndexForDecreasePositions, payable(msg.sender));
    }

    function disableFastPrice() external onlySigner {
        require(!disableFastPriceVotes[msg.sender], "FastPriceFeed: already voted");
        disableFastPriceVotes[msg.sender] = true;
        disableFastPriceVoteCount = disableFastPriceVoteCount.add(1);

        emit DisableFastPrice(msg.sender);
    }

    function enableFastPrice() external onlySigner {
        require(disableFastPriceVotes[msg.sender], "FastPriceFeed: already enabled");
        disableFastPriceVotes[msg.sender] = false;
        disableFastPriceVoteCount = disableFastPriceVoteCount.sub(1);

        emit EnableFastPrice(msg.sender);
    }

    // under regular operation, the fastPrice (prices[token]) is returned and there is no spread returned from this function,
    // though VaultPriceFeed might apply its own spread
    //
    // if the fastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    // in case the fastPrice has not been updated for maxPriceUpdateDelay then the _refPrice with a larger spread is used (spread: spreadBasisPointsIfChainError)
    //
    // there will be a spread from the _refPrice to the fastPrice in the following cases:
    // - in case isSpreadEnabled is set to true
    // - in case the maxDeviationBasisPoints between _refPrice and fastPrice is exceeded
    // - in case watchers flag an issue
    // - in case the cumulativeFastDelta exceeds the cumulativeRefDelta by the maxCumulativeDeltaDiff
    function getPrice(address _token, uint256 _refPrice, bool _maximise) external override view returns (uint256) {
        if (block.timestamp > lastUpdatedAt.add(maxPriceUpdateDelay)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
            }

            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
        }

        if (block.timestamp > lastUpdatedAt.add(priceDuration)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
            }

            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
        }

        uint256 fastPrice = prices[_token];
        if (fastPrice == 0) { return _refPrice; }

        uint256 diffBasisPoints = _refPrice > fastPrice ? _refPrice.sub(fastPrice) : fastPrice.sub(_refPrice);
        diffBasisPoints = diffBasisPoints.mul(BASIS_POINTS_DIVISOR).div(_refPrice);

        // create a spread between the _refPrice and the fastPrice if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the fast price
        bool hasSpread = !favorFastPrice(_token) || diffBasisPoints > maxDeviationBasisPoints;

        if (hasSpread) {
            // return the higher of the two prices
            if (_maximise) {
                return _refPrice > fastPrice ? _refPrice : fastPrice;
            }

            // return the lower of the two prices
            return _refPrice < fastPrice ? _refPrice : fastPrice;
        }

        return fastPrice;
    }

    function favorFastPrice(address _token) public view returns (bool) {
        if (isSpreadEnabled) {
            return false;
        }

        if (disableFastPriceVoteCount >= minAuthorizations) {
            // force a spread if watchers have flagged an issue with the fast price
            return false;
        }

        (/* uint256 prevRefPrice */, /* uint256 refTime */, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);
        if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
            // force a spread if the cumulative delta for the fast price feed exceeds the cumulative delta
            // for the Chainlink price feed by the maxCumulativeDeltaDiff allowed
            return false;
        }

        return true;
    }

    function getPriceData(address _token) public view returns (uint256, uint256, uint256, uint256) {
        PriceDataItem memory data = priceData[_token];
        return (uint256(data.refPrice), uint256(data.refTime), uint256(data.cumulativeRefDelta), uint256(data.cumulativeFastDelta));
    }

    function _setPricesWithBits(uint256 _priceBits, uint256 _timestamp) private {
        bool shouldUpdate = _setLastUpdatedValues(_timestamp);

        if (shouldUpdate) {
            address _fastPriceEvents = fastPriceEvents;
            address _vaultPriceFeed = vaultPriceFeed;

            for (uint256 j = 0; j < 8; j++) {
                uint256 index = j;
                if (index >= tokens.length) { return; }

                uint256 startBit = 32 * j;
                uint256 price = (_priceBits >> startBit) & BITMASK_32;

                address token = tokens[j];
                uint256 tokenPrecision = tokenPrecisions[j];
                uint256 adjustedPrice = price.mul(PRICE_PRECISION).div(tokenPrecision);

                _setPrice(token, adjustedPrice, _vaultPriceFeed, _fastPriceEvents);
            }
        }
    }

    function _setPrice(address _token, uint256 _price, address _vaultPriceFeed, address _fastPriceEvents) private {
        if (_vaultPriceFeed != address(0)) {
            uint256 refPrice = IVaultPriceFeed(_vaultPriceFeed).getLatestPrimaryPrice(_token);
            uint256 fastPrice = prices[_token];

            (uint256 prevRefPrice, uint256 refTime, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);

            if (prevRefPrice > 0) {
                uint256 refDeltaAmount = refPrice > prevRefPrice ? refPrice.sub(prevRefPrice) : prevRefPrice.sub(refPrice);
                uint256 fastDeltaAmount = fastPrice > _price ? fastPrice.sub(_price) : _price.sub(fastPrice);

                // reset cumulative delta values if it is a new time window
                if (refTime.div(priceDataInterval) != block.timestamp.div(priceDataInterval)) {
                    cumulativeRefDelta = 0;
                    cumulativeFastDelta = 0;
                }

                cumulativeRefDelta = cumulativeRefDelta.add(refDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(prevRefPrice));
                cumulativeFastDelta = cumulativeFastDelta.add(fastDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(fastPrice));
            }

            if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
                emit MaxCumulativeDeltaDiffExceeded(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
            }

            _setPriceData(_token, refPrice, cumulativeRefDelta, cumulativeFastDelta);
            emit PriceData(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
        }

        prices[_token] = _price;
        _emitPriceEvent(_fastPriceEvents, _token, _price);
    }

    function _setPriceData(address _token, uint256 _refPrice, uint256 _cumulativeRefDelta, uint256 _cumulativeFastDelta) private {
        require(_refPrice < MAX_REF_PRICE, "FastPriceFeed: invalid refPrice");
        // skip validation of block.timestamp, it should only be out of range after the year 2100
        require(_cumulativeRefDelta < MAX_CUMULATIVE_REF_DELTA, "FastPriceFeed: invalid cumulativeRefDelta");
        require(_cumulativeFastDelta < MAX_CUMULATIVE_FAST_DELTA, "FastPriceFeed: invalid cumulativeFastDelta");

        priceData[_token] = PriceDataItem(
            uint160(_refPrice),
            uint32(block.timestamp),
            uint32(_cumulativeRefDelta),
            uint32(_cumulativeFastDelta)
        );
    }

    function _emitPriceEvent(address _fastPriceEvents, address _token, uint256 _price) private {
        if (_fastPriceEvents == address(0)) {
            return;
        }

        IFastPriceEvents(_fastPriceEvents).emitPriceEvent(_token, _price);
    }

    function _setLastUpdatedValues(uint256 _timestamp) private returns (bool) {
        if (minBlockInterval > 0) {
            require(block.number.sub(lastUpdatedBlock) >= minBlockInterval, "FastPriceFeed: minBlockInterval not yet passed");
        }

        uint256 _maxTimeDeviation = maxTimeDeviation;
        require(_timestamp > block.timestamp.sub(_maxTimeDeviation), "FastPriceFeed: _timestamp below allowed range");
        require(_timestamp < block.timestamp.add(_maxTimeDeviation), "FastPriceFeed: _timestamp exceeds allowed range");

        // do not update prices if _timestamp is before the current lastUpdatedAt value
        if (_timestamp < lastUpdatedAt) {
            return false;
        }

        lastUpdatedAt = _timestamp;
        lastUpdatedBlock = block.number;

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFastPriceEvents {
    function emitPriceEvent(address _token, uint256 _price) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IFastPriceFeed {
    function lastUpdatedAt() external view returns (uint256);
    function lastUpdatedBlock() external view returns (uint256);
    function setSigner(address _account, bool _isActive) external;
    function setUpdater(address _account, bool _isActive) external;
    function setPriceDuration(uint256 _priceDuration) external;
    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external;
    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external;
    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external;
    function setMinBlockInterval(uint256 _minBlockInterval) external;
    function setIsSpreadEnabled(bool _isSpreadEnabled) external;
    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints) external;
    function setMaxCumulativeDeltaDiffs(address[] memory _tokens,  uint256[] memory _maxCumulativeDeltaDiffs) external;
    function setPriceDataInterval(uint256 _priceDataInterval) external;
    function setVaultPriceFeed(address _vaultPriceFeed) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPriceFeed {
    function description() external view returns (string memory);
    function aggregator() external view returns (address);
    function latestAnswer() external view returns (int256);
    function latestRound() external view returns (uint80);
    function getRoundData(uint80 roundId) external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISecondaryPriceFeed {
    function getPrice(address _token, uint256 _referencePrice, bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IPriceFeed.sol";

contract PriceFeed is IPriceFeed {
    int256 public answer;
    uint80 public roundId;
    string public override description = "PriceFeed";
    address public override aggregator;

    uint256 public decimals;

    address public gov;

    mapping(uint80 => int256) public answers;
    mapping(address => bool) public isAdmin;

    constructor() public {
        gov = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function setAdmin(address _account, bool _isAdmin) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        isAdmin[_account] = _isAdmin;
    }

    function latestAnswer() public view override returns (int256) {
        return answer;
    }

    function latestRound() public view override returns (uint80) {
        return roundId;
    }

    function setLatestAnswer(int256 _answer) public {
        require(isAdmin[msg.sender], "PriceFeed: forbidden");
        roundId = roundId + 1;
        answer = _answer;
        answers[roundId] = _answer;
    }

    // returns roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80 _roundId)
        public
        view
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (_roundId, answers[_roundId], 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IPriceFeed.sol";

contract PriceFeedMock is IPriceFeed {
    int256 public answer = 1000000000;
    uint80 public roundId;
    string public override description = "PriceFeed";
    address public override aggregator;

    uint256 public decimals;
    string private _name;

    address public gov;

    mapping(uint80 => int256) public answers;
    mapping(address => bool) public isAdmin;

    constructor(string memory name) public {
        _name = name;
        gov = msg.sender;
        isAdmin[msg.sender] = true;
    }

    function setAdmin(address _account, bool _isAdmin) public {
        require(msg.sender == gov, "PriceFeed: forbidden");
        isAdmin[_account] = _isAdmin;
    }

    function latestAnswer() public view override returns (int256) {
        return answer;
    }

    function latestRound() public view override returns (uint80) {
        return roundId;
    }

    function setLatestAnswer(int256 _answer) public {
        require(isAdmin[msg.sender], "PriceFeed: forbidden");
        roundId = roundId + 1;
        answer = _answer;
        answers[roundId] = _answer;
    }

    // returns roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80 _roundId)
        public
        view
        override
        returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80
        )
    {
        return (_roundId, answers[_roundId], 0, 0, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../access/Governable.sol";

contract BatchSender is Governable {
    using SafeMath for uint256;

    mapping(address => bool) public isHandler;

    event BatchSend(uint256 indexed typeId, address indexed token, address[] accounts, uint256[] amounts);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "BatchSender: forbidden");
        _;
    }

    constructor() public {
        isHandler[msg.sender] = true;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function send(
        IERC20 _token,
        address[] memory _accounts,
        uint256[] memory _amounts
    ) public onlyHandler {
        _send(_token, _accounts, _amounts, 0);
    }

    function sendAndEmit(
        IERC20 _token,
        address[] memory _accounts,
        uint256[] memory _amounts,
        uint256 _typeId
    ) public onlyHandler {
        _send(_token, _accounts, _amounts, _typeId);
    }

    function _send(
        IERC20 _token,
        address[] memory _accounts,
        uint256[] memory _amounts,
        uint256 _typeId
    ) private {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            _token.transferFrom(msg.sender, account, amount);
        }

        emit BatchSend(_typeId, address(_token), _accounts, _amounts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IHandlerTarget {
    function isHandler(address _account) external returns (bool);
    function setHandler(address _handler, bool _isActive) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISkullTimelock {
    function setAdmin(address _admin) external;
    function signalSetGov(address _target, address _gov) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelock {
    function setAdmin(address _admin) external;
    function enableLeverage(address _vault) external;
    function disableLeverage(address _vault) external;
    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external;
    function signalSetGov(address _target, address _gov) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelockTarget {
    function setGov(address _gov) external;
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";

import "../core/interfaces/IOrderBookForReader.sol";

contract OrderBookReader {
    using SafeMath for uint256;

    struct Vars {
        uint256 i;
        uint256 index;
        address account;
        uint256 uintLength;
        uint256 addressLength;
    }

    function getIncreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBookForReader orderBook = IOrderBookForReader(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (
                address purchaseToken,
                uint256 purchaseTokenAmount,
                address collateralToken,
                address indexToken,
                uint256 sizeDelta,
                bool isLong,
                uint256 triggerPrice,
                bool triggerAboveThreshold,

            ) = // uint256 executionFee
                orderBook.getIncreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(purchaseTokenAmount);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (purchaseToken);
            addressProps[vars.i * vars.addressLength + 1] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 2] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getDecreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 2);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBookForReader orderBook = IOrderBookForReader(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (address collateralToken, uint256 collateralDelta, address indexToken, uint256 sizeDelta, bool isLong, uint256 triggerPrice, bool triggerAboveThreshold, ) = // uint256 executionFee
            orderBook.getDecreaseOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(collateralDelta);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 1] = (indexToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getDecreaseOrdersV2(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBookForReader orderBook = IOrderBookForReader(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (address collateralToken,address receiveToken, uint256 collateralDelta, address indexToken, uint256 sizeDelta, bool isLong, uint256 triggerPrice, bool triggerAboveThreshold, ) = // uint256 executionFee
            orderBook.getDecreaseOrderV2(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(collateralDelta);
            uintProps[vars.i * vars.uintLength + 1] = uint256(sizeDelta);
            uintProps[vars.i * vars.uintLength + 2] = uint256(isLong ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerPrice);
            uintProps[vars.i * vars.uintLength + 4] = uint256(triggerAboveThreshold ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (collateralToken);
            addressProps[vars.i * vars.addressLength + 1] = (indexToken);            
            addressProps[vars.i * vars.addressLength + 2] = (receiveToken);

            vars.i++;
        }

        return (uintProps, addressProps);
    }

    function getSwapOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory) {
        Vars memory vars = Vars(0, 0, _account, 5, 3);

        uint256[] memory uintProps = new uint256[](vars.uintLength * _indices.length);
        address[] memory addressProps = new address[](vars.addressLength * _indices.length);

        IOrderBookForReader orderBook = IOrderBookForReader(_orderBookAddress);

        while (vars.i < _indices.length) {
            vars.index = _indices[vars.i];
            (address path0, address path1, address path2, uint256 amountIn, uint256 minOut, uint256 triggerRatio, bool triggerAboveThreshold, bool shouldUnwrap, ) = // uint256 executionFee
            orderBook.getSwapOrder(vars.account, vars.index);

            uintProps[vars.i * vars.uintLength] = uint256(amountIn);
            uintProps[vars.i * vars.uintLength + 1] = uint256(minOut);
            uintProps[vars.i * vars.uintLength + 2] = uint256(triggerRatio);
            uintProps[vars.i * vars.uintLength + 3] = uint256(triggerAboveThreshold ? 1 : 0);
            uintProps[vars.i * vars.uintLength + 4] = uint256(shouldUnwrap ? 1 : 0);

            addressProps[vars.i * vars.addressLength] = (path0);
            addressProps[vars.i * vars.addressLength + 1] = (path1);
            addressProps[vars.i * vars.addressLength + 2] = (path2);

            vars.i++;
        }

        return (uintProps, addressProps);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockTarget.sol";
import "../access/interfaces/IAdmin.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../oracle/interfaces/IFastPriceFeed.sol";
import "../tokens/interfaces/IBaseToken.sol";

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract PriceFeedTimelock {
    using SafeMath for uint256;

    uint256 public constant MAX_BUFFER = 5 days;

    uint256 public buffer;
    address public admin;

    address public tokenManager;

    mapping (bytes32 => uint256) public pendingActions;

    mapping (address => bool) public isHandler;
    mapping (address => bool) public isKeeper;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(address token, address spender, uint256 amount, bytes32 action);
    event SignalWithdrawToken(address target, address token, address receiver, uint256 amount, bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);
    event SignalSetPriceFeedWatcher(address fastPriceFeed, address account, bool isActive);
    event SignalPriceFeedSetTokenConfig(
        address vaultPriceFeed,
        address token,
        address priceFeed,
        uint256 priceDecimals,
        bool isStrictStable
    );
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender] || isKeeper[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        address _tokenManager
    ) public {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        admin = _admin;
        buffer = _buffer;
        tokenManager = _tokenManager;
    }

    function setAdmin(address _admin) external onlyTokenManager {
        admin = _admin;
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        require(_target != address(this), "Timelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        isKeeper[_keeper] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        require(_buffer > buffer, "Timelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function setIsSecondaryPriceEnabled(address _priceFeed, bool _isEnabled) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setIsSecondaryPriceEnabled(_isEnabled);
    }

    function setMaxStrictPriceDeviation(address _priceFeed, uint256 _maxStrictPriceDeviation) external onlyAdmin {
        IVaultPriceFeed(_priceFeed).setMaxStrictPriceDeviation(_maxStrictPriceDeviation);
    }

    function setAdjustment(address _priceFeed, address _token, bool _isAdditive, uint256 _adjustmentBps) external onlyKeeperAndAbove {
        IVaultPriceFeed(_priceFeed).setAdjustment(_token, _isAdditive, _adjustmentBps);
    }

    function setSpreadBasisPoints(address _priceFeed, address _token, uint256 _spreadBasisPoints) external onlyKeeperAndAbove {
        IVaultPriceFeed(_priceFeed).setSpreadBasisPoints(_token, _spreadBasisPoints);
    }

    function setPriceSampleSpace(address _priceFeed,uint256 _priceSampleSpace) external onlyHandlerAndAbove {
        require(_priceSampleSpace <= 5, "Invalid _priceSampleSpace");
        IVaultPriceFeed(_priceFeed).setPriceSampleSpace(_priceSampleSpace);
    }

    function setVaultPriceFeed(address _fastPriceFeed, address _vaultPriceFeed) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setVaultPriceFeed(_vaultPriceFeed);
    }

    function setPriceDuration(address _fastPriceFeed, uint256 _priceDuration) external onlyHandlerAndAbove {
        IFastPriceFeed(_fastPriceFeed).setPriceDuration(_priceDuration);
    }

    function setMaxPriceUpdateDelay(address _fastPriceFeed, uint256 _maxPriceUpdateDelay) external onlyHandlerAndAbove {
        IFastPriceFeed(_fastPriceFeed).setMaxPriceUpdateDelay(_maxPriceUpdateDelay);
    }

    function setSpreadBasisPointsIfInactive(address _fastPriceFeed, uint256 _spreadBasisPointsIfInactive) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setSpreadBasisPointsIfInactive(_spreadBasisPointsIfInactive);
    }

    function setSpreadBasisPointsIfChainError(address _fastPriceFeed, uint256 _spreadBasisPointsIfChainError) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setSpreadBasisPointsIfChainError(_spreadBasisPointsIfChainError);
    }

    function setMinBlockInterval(address _fastPriceFeed, uint256 _minBlockInterval) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setMinBlockInterval(_minBlockInterval);
    }

    function setIsSpreadEnabled(address _fastPriceFeed, bool _isSpreadEnabled) external onlyAdmin {
        IFastPriceFeed(_fastPriceFeed).setIsSpreadEnabled(_isSpreadEnabled);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).setGov(_gov);
    }

    function signalSetPriceFeedWatcher(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedWatcher", _fastPriceFeed, _account, _isActive));
        _setPendingAction(action);
        emit SignalSetPriceFeedWatcher(_fastPriceFeed, _account, _isActive);
    }

    function setPriceFeedWatcher(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedWatcher", _fastPriceFeed, _account, _isActive));
        _validateAction(action);
        _clearAction(action);
        IFastPriceFeed(_fastPriceFeed).setSigner(_account, _isActive);
    }

    function signalSetPriceFeedUpdater(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedUpdater", _fastPriceFeed, _account, _isActive));
        _setPendingAction(action);
        emit SignalSetPriceFeedWatcher(_fastPriceFeed, _account, _isActive);
    }

    function setPriceFeedUpdater(address _fastPriceFeed, address _account, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeedUpdater", _fastPriceFeed, _account, _isActive));
        _validateAction(action);
        _clearAction(action);
        IFastPriceFeed(_fastPriceFeed).setUpdater(_account, _isActive);
    }

    function signalPriceFeedSetTokenConfig(
        address _vaultPriceFeed,
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "priceFeedSetTokenConfig",
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        ));

        _setPendingAction(action);

        emit SignalPriceFeedSetTokenConfig(
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        );
    }

    function priceFeedSetTokenConfig(
        address _vaultPriceFeed,
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "priceFeedSetTokenConfig",
            _vaultPriceFeed,
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        ));

        _validateAction(action);
        _clearAction(action);

        IVaultPriceFeed(_vaultPriceFeed).setTokenConfig(
            _token,
            _priceFeed,
            _priceDecimals,
            _isStrictStable
        );
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _setPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "Timelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../tokens/interfaces/IYieldTracker.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../amm/interfaces/IPancakeFactory.sol";

import "../access/Governable.sol";

contract Reader is Governable {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant POSITION_PROPS_LENGTH = 9;
    uint256 public constant PRICE_PRECISION = 10**30;
    uint256 public constant USDS_DECIMALS = 18;

    bool public hasMaxGlobalShortSizes;

    function setConfig(bool _hasMaxGlobalShortSizes) public onlyGov {
        hasMaxGlobalShortSizes = _hasMaxGlobalShortSizes;
    }

    function getMaxAmountIn(
        IVault _vault,
        address _tokenIn,
        address _tokenOut
    ) public view returns (uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 amountIn;

        {
            uint256 poolAmount = _vault.poolAmounts(_tokenOut);
            uint256 reservedAmount = _vault.reservedAmounts(_tokenOut);
            uint256 bufferAmount = _vault.bufferAmounts(_tokenOut);
            uint256 subAmount = reservedAmount > bufferAmount ? reservedAmount : bufferAmount;
            if (subAmount >= poolAmount) {
                return 0;
            }
            uint256 availableAmount = poolAmount.sub(subAmount);
            amountIn = availableAmount.mul(priceOut).div(priceIn).mul(10**tokenInDecimals).div(10**tokenOutDecimals);
        }

        uint256 maxUsdsAmount = _vault.maxUsdsAmounts(_tokenIn);

        if (maxUsdsAmount != 0) {
            if (maxUsdsAmount < _vault.usdsAmounts(_tokenIn)) {
                return 0;
            }

            uint256 maxAmountIn = maxUsdsAmount.sub(_vault.usdsAmounts(_tokenIn));
            maxAmountIn = maxAmountIn.mul(10**tokenInDecimals).div(10**USDS_DECIMALS);
            maxAmountIn = maxAmountIn.mul(PRICE_PRECISION).div(priceIn);

            if (amountIn > maxAmountIn) {
                return maxAmountIn;
            }
        }

        return amountIn;
    }

    function getAmountOut(
        IVault _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) public view returns (uint256, uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 feeBasisPoints;
        {
            uint256 usdsAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
            usdsAmount = usdsAmount.mul(10**USDS_DECIMALS).div(10**tokenInDecimals);

            bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
            uint256 baseBps = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
            uint256 taxBps = isStableSwap ? _vault.stableTaxBasisPoints() : _vault.taxBasisPoints();
            uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(_tokenIn, usdsAmount, baseBps, taxBps, true);
            uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(_tokenOut, usdsAmount, baseBps, taxBps, false);
            // use the higher of the two fee basis points
            feeBasisPoints = feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;
        }

        uint256 priceOut = _vault.getMaxPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = amountOut.mul(10**tokenOutDecimals).div(10**tokenInDecimals);

        uint256 amountOutAfterFees = amountOut.mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints)).div(BASIS_POINTS_DIVISOR);
        uint256 feeAmount = amountOut.sub(amountOutAfterFees);

        return (amountOutAfterFees, feeAmount);
    }

    function getFeeBasisPoints(
        IVault _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);

        uint256 usdsAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
        usdsAmount = usdsAmount.mul(10**USDS_DECIMALS).div(10**tokenInDecimals);

        bool isStableSwap = _vault.stableTokens(_tokenIn) && _vault.stableTokens(_tokenOut);
        uint256 baseBps = isStableSwap ? _vault.stableSwapFeeBasisPoints() : _vault.swapFeeBasisPoints();
        uint256 taxBps = isStableSwap ? _vault.stableTaxBasisPoints() : _vault.taxBasisPoints();
        uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(_tokenIn, usdsAmount, baseBps, taxBps, true);
        uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(_tokenOut, usdsAmount, baseBps, taxBps, false);
        // use the higher of the two fee basis points
        uint256 feeBasisPoints = feesBasisPoints0 > feesBasisPoints1 ? feesBasisPoints0 : feesBasisPoints1;

        return (feeBasisPoints, feesBasisPoints0, feesBasisPoints1);
    }

    function getFees(address _vault, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = IVault(_vault).feeReserves(_tokens[i]);
        }
        return amounts;
    }

    function getTotalStaked(address[] memory _yieldTokens) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_yieldTokens.length);
        for (uint256 i = 0; i < _yieldTokens.length; i++) {
            IYieldToken yieldToken = IYieldToken(_yieldTokens[i]);
            amounts[i] = yieldToken.totalStaked();
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _yieldTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[](_yieldTrackers.length * propsLength);
        for (uint256 i = 0; i < _yieldTrackers.length; i++) {
            IYieldTracker yieldTracker = IYieldTracker(_yieldTrackers[i]);
            amounts[i * propsLength] = yieldTracker.claimable(_account);
            amounts[i * propsLength + 1] = yieldTracker.getTokensPerInterval();
        }
        return amounts;
    }

    function getPairInfo(address _factory, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 inputLength = 2;
        uint256 propsLength = 2;
        uint256[] memory amounts = new uint256[]((_tokens.length / inputLength) * propsLength);
        for (uint256 i = 0; i < _tokens.length / inputLength; i++) {
            address token0 = _tokens[i * inputLength];
            address token1 = _tokens[i * inputLength + 1];
            address pair = IPancakeFactory(_factory).getPair(token0, token1);

            amounts[i * propsLength] = IERC20(token0).balanceOf(pair);
            amounts[i * propsLength + 1] = IERC20(token1).balanceOf(pair);
        }
        return amounts;
    }

    function getFundingRates(
        address _vault,
        address _weth,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory fundingRates = new uint256[](_tokens.length * propsLength);
        IVault vault = IVault(_vault);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            uint256 fundingRateFactor = vault.stableTokens(token) ? vault.stableFundingRateFactor() : vault.fundingRateFactor();
            uint256 reservedAmount = vault.reservedAmounts(token);
            uint256 poolAmount = vault.poolAmounts(token);

            if (poolAmount > 0) {
                fundingRates[i * propsLength] = fundingRateFactor.mul(reservedAmount).div(poolAmount);
            }

            if (vault.cumulativeFundingRates(token) > 0) {
                uint256 nextRate = vault.getNextFundingRate(token);
                uint256 baseRate = vault.cumulativeFundingRates(token);
                fundingRates[i * propsLength + 1] = baseRate.add(nextRate);
            }
        }

        return fundingRates;
    }

    function getTokenSupply(IERC20 _token, address[] memory _excludedAccounts) public view returns (uint256) {
        uint256 supply = _token.totalSupply();
        for (uint256 i = 0; i < _excludedAccounts.length; i++) {
            address account = _excludedAccounts[i];
            uint256 balance = _token.balanceOf(account);
            supply = supply.sub(balance);
        }
        return supply;
    }

    function getTotalBalance(IERC20 _token, address[] memory _accounts) public view returns (uint256) {
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 balance = _token.balanceOf(account);
            totalBalance = totalBalance.add(balance);
        }
        return totalBalance;
    }

    function getTokenBalances(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i] = _account.balance;
                continue;
            }
            balances[i] = IERC20(token).balanceOf(_account);
        }
        return balances;
    }

    function getTokenBalancesWithSupplies(address _account, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 2;
        uint256[] memory balances = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                balances[i * propsLength] = _account.balance;
                balances[i * propsLength + 1] = 0;
                continue;
            }
            balances[i * propsLength] = IERC20(token).balanceOf(_account);
            balances[i * propsLength + 1] = IERC20(token).totalSupply();
        }
        return balances;
    }

    function getPrices(IVaultPriceFeed _priceFeed, address[] memory _tokens) public view returns (uint256[] memory) {
        uint256 propsLength = 6;

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);

        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            amounts[i * propsLength] = _priceFeed.getPrice(token, true, true, false);
            amounts[i * propsLength + 1] = _priceFeed.getPrice(token, false, true, false);
            amounts[i * propsLength + 2] = _priceFeed.getPrimaryPrice(token, true);
            amounts[i * propsLength + 3] = _priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 4] = _priceFeed.isAdjustmentAdditive(token) ? 1 : 0;
            amounts[i * propsLength + 5] = _priceFeed.adjustmentBasisPoints(token);
        }

        return amounts;
    }

    function getVaultTokenInfo(
        address _vault,
        address _weth,
        uint256 _usdsAmount,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 10;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.usdsAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdsAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.getMinPrice(token);
            amounts[i * propsLength + 6] = vault.getMaxPrice(token);
            amounts[i * propsLength + 7] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 8] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 9] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getFullVaultTokenInfo(
        address _vault,
        address _weth,
        uint256 _usdsAmount,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 12;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.usdsAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdsAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxUsdsAmounts(token);
            amounts[i * propsLength + 7] = vault.getMinPrice(token);
            amounts[i * propsLength + 8] = vault.getMaxPrice(token);
            amounts[i * propsLength + 9] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 10] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 11] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getVaultTokenInfoV2(
        address _vault,
        address _weth,
        uint256 _usdsAmount,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 14;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            uint256 maxGlobalShortSize = hasMaxGlobalShortSizes ? vault.maxGlobalShortSizes(token) : 0;
            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.usdsAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdsAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxUsdsAmounts(token);
            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
            amounts[i * propsLength + 8] = maxGlobalShortSize;
            amounts[i * propsLength + 9] = vault.getMinPrice(token);
            amounts[i * propsLength + 10] = vault.getMaxPrice(token);
            amounts[i * propsLength + 11] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 12] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_collateralTokens.length * POSITION_PROPS_LENGTH);

        for (uint256 i = 0; i < _collateralTokens.length; i++) {
            {
                (
                    uint256 size,
                    uint256 collateral,
                    uint256 averagePrice,
                    uint256 entryFundingRate,
                    ,
                    /* reserveAmount */
                    uint256 realisedPnl,
                    bool hasRealisedProfit,
                    uint256 lastIncreasedTime
                ) = IVault(_vault).getPosition(_account, _collateralTokens[i], _indexTokens[i], _isLong[i]);

                amounts[i * POSITION_PROPS_LENGTH] = size;
                amounts[i * POSITION_PROPS_LENGTH + 1] = collateral;
                amounts[i * POSITION_PROPS_LENGTH + 2] = averagePrice;
                amounts[i * POSITION_PROPS_LENGTH + 3] = entryFundingRate;
                amounts[i * POSITION_PROPS_LENGTH + 4] = hasRealisedProfit ? 1 : 0;
                amounts[i * POSITION_PROPS_LENGTH + 5] = realisedPnl;
                amounts[i * POSITION_PROPS_LENGTH + 6] = lastIncreasedTime;
            }

            uint256 size = amounts[i * POSITION_PROPS_LENGTH];
            uint256 averagePrice = amounts[i * POSITION_PROPS_LENGTH + 2];
            uint256 lastIncreasedTime = amounts[i * POSITION_PROPS_LENGTH + 6];
            if (averagePrice > 0) {
                (bool hasProfit, uint256 delta) = IVault(_vault).getDelta(_indexTokens[i], size, averagePrice, _isLong[i], lastIncreasedTime);
                amounts[i * POSITION_PROPS_LENGTH + 7] = hasProfit ? 1 : 0;
                amounts[i * POSITION_PROPS_LENGTH + 8] = delta;
            }
        }

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

import "../staking/interfaces/IRewardTracker.sol";

contract RewardReader {
    using SafeMath for uint256;

    function getDepositBalances(
        address _account,
        address[] memory _depositTokens,
        address[] memory _rewardTrackers
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](_rewardTrackers.length);
        for (uint256 i = 0; i < _rewardTrackers.length; i++) {
            IRewardTracker rewardTracker = IRewardTracker(_rewardTrackers[i]);
            amounts[i] = rewardTracker.depositBalances(_account, _depositTokens[i]);
        }
        return amounts;
    }

    function getStakingInfo(address _account, address[] memory _rewardTrackers) public view returns (uint256[] memory) {
        uint256 propsLength = 5;
        uint256[] memory amounts = new uint256[](_rewardTrackers.length * propsLength);
        for (uint256 i = 0; i < _rewardTrackers.length; i++) {
            IRewardTracker rewardTracker = IRewardTracker(_rewardTrackers[i]);
            amounts[i * propsLength] = rewardTracker.claimable(_account);
            amounts[i * propsLength + 1] = rewardTracker.tokensPerInterval();
            amounts[i * propsLength + 2] = rewardTracker.averageStakedAmounts(_account);
            amounts[i * propsLength + 3] = rewardTracker.cumulativeRewards(_account);
            amounts[i * propsLength + 4] = IERC20(_rewardTrackers[i]).totalSupply();
        }
        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockTarget.sol";
import "./interfaces/ISkullTimelock.sol";
import "../access/interfaces/IAdmin.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../tokens/interfaces/IBaseToken.sol";
import "../tokens/interfaces/IMintable.sol";
import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract SkullTimelock is ISkullTimelock {
    using SafeMath for uint256;

    uint256 public constant MAX_BUFFER = 7 days;

    uint256 public buffer;
    uint256 public longBuffer;
    address public admin;

    address public tokenManager;
    uint256 public maxTokenSupply;

    mapping(bytes32 => uint256) public pendingActions;
    mapping(address => bool) public isHandler;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(address token, address spender, uint256 amount, bytes32 action);
    event SignalWithdrawToken(address target, address token, address receiver, uint256 amount, bytes32 action);
    event SignalMint(address token, address receiver, uint256 amount, bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);

    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "SkullTimelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "SkullTimelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        uint256 _longBuffer,
        address _tokenManager,
        uint256 _maxTokenSupply
    ) public {
        require(_buffer <= MAX_BUFFER, "SkullTimelock: invalid _buffer");
        require(_longBuffer <= MAX_BUFFER, "SkullTimelock: invalid _longBuffer");
        admin = _admin;
        buffer = _buffer;
        longBuffer = _longBuffer;
        tokenManager = _tokenManager;
        maxTokenSupply = _maxTokenSupply;
    }

    function setAdmin(address _admin) external override onlyTokenManager {
        admin = _admin;
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        require(_target != address(this), "SkullTimelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "SkullTimelock: invalid _buffer");
        require(_buffer > buffer, "SkullTimelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function removeAdmin(address _token, address _account) external onlyAdmin {
        IYieldToken(_token).removeAdmin(_account);
    }

    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external onlyAdmin {
        IBaseToken(_token).setInPrivateTransferMode(_inPrivateTransferMode);
    }

    function transferIn(
        address _sender,
        address _token,
        uint256 _amount
    ) external onlyAdmin {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function signalApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(
        address _target,
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(
        address _target,
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalMint(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalMint(_token, _receiver, _amount, action);
    }

    function processMint(
        address _token,
        address _receiver,
        uint256 _amount
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);

        _mint(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external override onlyTokenManager {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setLongPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).setGov(_gov);
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _mint(
        address _token,
        address _receiver,
        uint256 _amount
    ) private {
        IMintable mintable = IMintable(_token);

        if (!mintable.isMinter(address(this))) {
            mintable.setMinter(address(this), true);
        }

        mintable.mint(_receiver, _amount);
        require(IERC20(_token).totalSupply() <= maxTokenSupply, "SkullTimelock: maxTokenSupply exceeded");
    }

    function _setPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _setLongPendingAction(bytes32 _action) private {
        pendingActions[_action] = block.timestamp.add(longBuffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "SkullTimelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "SkullTimelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "SkullTimelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/ITimelockTarget.sol";
import "./interfaces/ITimelock.sol";
import "./interfaces/IHandlerTarget.sol";
import "../access/interfaces/IAdmin.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultUtils.sol";
import "../core/interfaces/ISlpManager.sol";
import "../referrals/interfaces/IReferralStorage.sol";
import "../tokens/interfaces/IYieldToken.sol";
import "../tokens/interfaces/IBaseToken.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IUSDS.sol";

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract Timelock is ITimelock {
    using SafeMath for uint256;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MAX_BUFFER = 5 days;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 200; // 0.02%
    uint256 public constant MAX_LEVERAGE_VALIDATION = 500000; // 50x

    uint256 public buffer;
    address public admin;

    address public tokenManager;
    address public mintReceiver;
    address public slpManager;
    uint256 public maxTokenSupply;

    uint256 public marginFeeBasisPoints;
    uint256 public maxMarginFeeBasisPoints;
    bool public shouldToggleIsLeverageEnabled;

    mapping (bytes32 => uint256) public pendingActions;

    mapping (address => bool) public isHandler;
    mapping (address => bool) public isKeeper;

    event SignalPendingAction(bytes32 action);
    event SignalApprove(address token, address spender, uint256 amount, bytes32 action);
    event SignalWithdrawToken(address target, address token, address receiver, uint256 amount, bytes32 action);
    event SignalMint(address token, address receiver, uint256 amount, bytes32 action);
    event SignalSetGov(address target, address gov, bytes32 action);
    event SignalSetHandler(address target, address handler, bool isActive, bytes32 action);
    event SignalSetPriceFeed(address vault, address priceFeed, bytes32 action);
    event SignalRedeemUsds(address vault, address token, uint256 amount);
    event SignalVaultSetTokenConfig(
        address vault,
        address token,
        uint256 tokenDecimals,
        uint256 tokenWeight,
        uint256 minProfitBps,
        uint256 maxUsdsAmount,
        bool isStable,
        bool isShortable
    );
    event ClearAction(bytes32 action);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Timelock: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyKeeperAndAbove() {
        require(msg.sender == admin || isHandler[msg.sender] || isKeeper[msg.sender], "Timelock: forbidden");
        _;
    }

    modifier onlyTokenManager() {
        require(msg.sender == tokenManager, "Timelock: forbidden");
        _;
    }

    constructor(
        address _admin,
        uint256 _buffer,
        address _tokenManager,
        address _mintReceiver,
        address _slpManager,
        uint256 _maxTokenSupply,
        uint256 _marginFeeBasisPoints,
        uint256 _maxMarginFeeBasisPoints
    ) public {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        admin = _admin;
        buffer = _buffer;
        tokenManager = _tokenManager;
        mintReceiver = _mintReceiver;
        slpManager = _slpManager;
        maxTokenSupply = _maxTokenSupply;

        marginFeeBasisPoints = _marginFeeBasisPoints;
        maxMarginFeeBasisPoints = _maxMarginFeeBasisPoints;
    }

    function setAdmin(address _admin) external override onlyTokenManager {
        admin = _admin;
    }

    function setExternalAdmin(address _target, address _admin) external onlyAdmin {
        require(_target != address(this), "Timelock: invalid _target");
        IAdmin(_target).setAdmin(_admin);
    }

    function setContractHandler(address _handler, bool _isActive) external onlyAdmin {
        isHandler[_handler] = _isActive;
    }

    function setKeeper(address _keeper, bool _isActive) external onlyAdmin {
        isKeeper[_keeper] = _isActive;
    }

    function setBuffer(uint256 _buffer) external onlyAdmin {
        require(_buffer <= MAX_BUFFER, "Timelock: invalid _buffer");
        require(_buffer > buffer, "Timelock: buffer cannot be decreased");
        buffer = _buffer;
    }

    function setMaxLeverage(address _vault, uint256 _maxLeverage) external onlyAdmin {
      require(_maxLeverage > MAX_LEVERAGE_VALIDATION, "Timelock: invalid _maxLeverage");
      IVault(_vault).setMaxLeverage(_maxLeverage);
    }

    function setFundingRate(address _vault, uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external onlyKeeperAndAbove {
        require(_fundingRateFactor < MAX_FUNDING_RATE_FACTOR, "Timelock: invalid _fundingRateFactor");
        require(_stableFundingRateFactor < MAX_FUNDING_RATE_FACTOR, "Timelock: invalid _stableFundingRateFactor");
        IVault(_vault).setFundingRate(_fundingInterval, _fundingRateFactor, _stableFundingRateFactor);
    }

    function setShouldToggleIsLeverageEnabled(bool _shouldToggleIsLeverageEnabled) external onlyHandlerAndAbove {
        shouldToggleIsLeverageEnabled = _shouldToggleIsLeverageEnabled;
    }

    function setMarginFeeBasisPoints(uint256 _marginFeeBasisPoints, uint256 _maxMarginFeeBasisPoints) external onlyHandlerAndAbove {
        marginFeeBasisPoints = _marginFeeBasisPoints;
        maxMarginFeeBasisPoints = _maxMarginFeeBasisPoints;
    }

    function setSwapFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints
    ) external onlyKeeperAndAbove {
        IVault vault = IVault(_vault);

        vault.setFees(
            _taxBasisPoints,
            _stableTaxBasisPoints,
            _mintBurnFeeBasisPoints,
            _swapFeeBasisPoints,
            _stableSwapFeeBasisPoints,
            maxMarginFeeBasisPoints,
            vault.liquidationFeeUsd(),
            vault.minProfitTime(),
            vault.hasDynamicFees()
        );
    }

    // assign _marginFeeBasisPoints to this.marginFeeBasisPoints
    // because enableLeverage would update Vault.marginFeeBasisPoints to this.marginFeeBasisPoints
    // and disableLeverage would reset the Vault.marginFeeBasisPoints to this.maxMarginFeeBasisPoints
    function setFees(
        address _vault,
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external onlyKeeperAndAbove {
        marginFeeBasisPoints = _marginFeeBasisPoints;

        IVault(_vault).setFees(
            _taxBasisPoints,
            _stableTaxBasisPoints,
            _mintBurnFeeBasisPoints,
            _swapFeeBasisPoints,
            _stableSwapFeeBasisPoints,
            maxMarginFeeBasisPoints,
            _liquidationFeeUsd,
            _minProfitTime,
            _hasDynamicFees
        );
    }

    function enableLeverage(address _vault) external override onlyHandlerAndAbove {
        IVault vault = IVault(_vault);

        if (shouldToggleIsLeverageEnabled) {
            vault.setIsLeverageEnabled(true);
        }

        vault.setFees(
            vault.taxBasisPoints(),
            vault.stableTaxBasisPoints(),
            vault.mintBurnFeeBasisPoints(),
            vault.swapFeeBasisPoints(),
            vault.stableSwapFeeBasisPoints(),
            marginFeeBasisPoints,
            vault.liquidationFeeUsd(),
            vault.minProfitTime(),
            vault.hasDynamicFees()
        );
    }

    function disableLeverage(address _vault) external override onlyHandlerAndAbove {
        IVault vault = IVault(_vault);

        if (shouldToggleIsLeverageEnabled) {
            vault.setIsLeverageEnabled(false);
        }

        vault.setFees(
            vault.taxBasisPoints(),
            vault.stableTaxBasisPoints(),
            vault.mintBurnFeeBasisPoints(),
            vault.swapFeeBasisPoints(),
            vault.stableSwapFeeBasisPoints(),
            maxMarginFeeBasisPoints, // marginFeeBasisPoints
            vault.liquidationFeeUsd(),
            vault.minProfitTime(),
            vault.hasDynamicFees()
        );
    }

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled) external override onlyHandlerAndAbove {
        IVault(_vault).setIsLeverageEnabled(_isLeverageEnabled);
    }

    function setTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdsAmount,
        uint256 _bufferAmount,
        uint256 _usdsAmount
    ) external onlyKeeperAndAbove {
        require(_minProfitBps <= 500, "Timelock: invalid _minProfitBps");

        IVault vault = IVault(_vault);
        require(vault.whitelistedTokens(_token), "Timelock: token not yet whitelisted");

        uint256 tokenDecimals = vault.tokenDecimals(_token);
        bool isStable = vault.stableTokens(_token);
        bool isShortable = vault.shortableTokens(_token);

        IVault(_vault).setTokenConfig(
            _token,
            tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxUsdsAmount,
            isStable,
            isShortable
        );

        IVault(_vault).setBufferAmount(_token, _bufferAmount);

        IVault(_vault).setUsdsAmount(_token, _usdsAmount);
    }

    function setUsdsAmounts(address _vault, address[] memory _tokens, uint256[] memory _usdsAmounts) external onlyKeeperAndAbove {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IVault(_vault).setUsdsAmount(_tokens[i], _usdsAmounts[i]);
        }
    }

    function updateUsdsSupply(uint256 usdsAmount) external onlyKeeperAndAbove {
        address usds = ISlpManager(slpManager).usds();
        uint256 balance = IERC20(usds).balanceOf(slpManager);

        IUSDS(usds).addVault(address(this));

        if (usdsAmount > balance) {
            uint256 mintAmount = usdsAmount.sub(balance);
            IUSDS(usds).mint(slpManager, mintAmount);
        } else {
            uint256 burnAmount = balance.sub(usdsAmount);
            IUSDS(usds).burn(slpManager, burnAmount);
        }

        IUSDS(usds).removeVault(address(this));
    }

    function setSlpCooldownDuration(uint256 _cooldownDuration) external onlyAdmin {
        ISlpManager(slpManager).setCooldownDuration(_cooldownDuration);
    }

    function setMaxGlobalShortSize(address _vault, address _token, uint256 _amount) external onlyAdmin {
        IVault(_vault).setMaxGlobalShortSize(_token, _amount);
    }

    function removeAdmin(address _token, address _account) external onlyAdmin {
        IYieldToken(_token).removeAdmin(_account);
    }

    function setIsSwapEnabled(address _vault, bool _isSwapEnabled) external onlyKeeperAndAbove {
        IVault(_vault).setIsSwapEnabled(_isSwapEnabled);
    }

    function setTier(address _referralStorage, uint256 _tierId, uint256 _totalRebate, uint256 _discountShare) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).setTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referralStorage, address _referrer, uint256 _tierId) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).setReferrerTier(_referrer, _tierId);
    }

    function govSetCodeOwner(address _referralStorage, bytes32 _code, address _newAccount) external onlyKeeperAndAbove {
        IReferralStorage(_referralStorage).govSetCodeOwner(_code, _newAccount);
    }

    function setVaultUtils(address _vault, IVaultUtils _vaultUtils) external onlyAdmin {
        IVault(_vault).setVaultUtils(_vaultUtils);
    }

    function setMaxGasPrice(address _vault, uint256 _maxGasPrice) external onlyAdmin {
        require(_maxGasPrice > 5000000000, "Invalid _maxGasPrice");
        IVault(_vault).setMaxGasPrice(_maxGasPrice);
    }

    function withdrawFees(address _vault, address _token, address _receiver) external onlyAdmin {
        IVault(_vault).withdrawFees(_token, _receiver);
    }

    function batchWithdrawFees(address _vault, address[] memory _tokens) external onlyKeeperAndAbove {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IVault(_vault).withdrawFees(_tokens[i], admin);
        }
    }

    function setInPrivateLiquidationMode(address _vault, bool _inPrivateLiquidationMode) external onlyAdmin {
        IVault(_vault).setInPrivateLiquidationMode(_inPrivateLiquidationMode);
    }

    function setLiquidator(address _vault, address _liquidator, bool _isActive) external onlyAdmin {
        IVault(_vault).setLiquidator(_liquidator, _isActive);
    }

    function setInPrivateTransferMode(address _token, bool _inPrivateTransferMode) external onlyAdmin {
        IBaseToken(_token).setInPrivateTransferMode(_inPrivateTransferMode);
    }

    function transferIn(address _sender, address _token, uint256 _amount) external onlyAdmin {
        IERC20(_token).transferFrom(_sender, address(this), _amount);
    }

    function signalApprove(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _setPendingAction(action);
        emit SignalApprove(_token, _spender, _amount, action);
    }

    function approve(address _token, address _spender, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("approve", _token, _spender, _amount));
        _validateAction(action);
        _clearAction(action);
        IERC20(_token).approve(_spender, _amount);
    }

    function signalWithdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalWithdrawToken(_target, _token, _receiver, _amount, action);
    }

    function withdrawToken(address _target, address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("withdrawToken", _target, _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);
        IBaseToken(_target).withdrawToken(_token, _receiver, _amount);
    }

    function signalMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _setPendingAction(action);
        emit SignalMint(_token, _receiver, _amount, action);
    }

    function processMint(address _token, address _receiver, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("mint", _token, _receiver, _amount));
        _validateAction(action);
        _clearAction(action);

        _mint(_token, _receiver, _amount);
    }

    function signalSetGov(address _target, address _gov) external override onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _setPendingAction(action);
        emit SignalSetGov(_target, _gov, action);
    }

    function setGov(address _target, address _gov) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setGov", _target, _gov));
        _validateAction(action);
        _clearAction(action);
        ITimelockTarget(_target).setGov(_gov);
    }

    function signalSetHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _setPendingAction(action);
        emit SignalSetHandler(_target, _handler, _isActive, action);
    }

    function setHandler(address _target, address _handler, bool _isActive) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setHandler", _target, _handler, _isActive));
        _validateAction(action);
        _clearAction(action);
        IHandlerTarget(_target).setHandler(_handler, _isActive);
    }

    function signalSetPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeed", _vault, _priceFeed));
        _setPendingAction(action);
        emit SignalSetPriceFeed(_vault, _priceFeed, action);
    }

    function setPriceFeed(address _vault, address _priceFeed) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("setPriceFeed", _vault, _priceFeed));
        _validateAction(action);
        _clearAction(action);
        IVault(_vault).setPriceFeed(_priceFeed);
    }

    function signalRedeemUsds(address _vault, address _token, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("redeemUsds", _vault, _token, _amount));
        _setPendingAction(action);
        emit SignalRedeemUsds(_vault, _token, _amount);
    }

    function redeemUsds(address _vault, address _token, uint256 _amount) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked("redeemUsds", _vault, _token, _amount));
        _validateAction(action);
        _clearAction(action);

        address usds = IVault(_vault).usds();
        IVault(_vault).setManager(address(this), true);
        IUSDS(usds).addVault(address(this));

        IUSDS(usds).mint(address(this), _amount);
        IERC20(usds).transfer(address(_vault), _amount);

        IVault(_vault).sellUSDS(_token, mintReceiver);

        IVault(_vault).setManager(address(this), false);
        IUSDS(usds).removeVault(address(this));
    }

    function signalVaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdsAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "vaultSetTokenConfig",
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxUsdsAmount,
            _isStable,
            _isShortable
        ));

        _setPendingAction(action);

        emit SignalVaultSetTokenConfig(
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxUsdsAmount,
            _isStable,
            _isShortable
        );
    }

    function vaultSetTokenConfig(
        address _vault,
        address _token,
        uint256 _tokenDecimals,
        uint256 _tokenWeight,
        uint256 _minProfitBps,
        uint256 _maxUsdsAmount,
        bool _isStable,
        bool _isShortable
    ) external onlyAdmin {
        bytes32 action = keccak256(abi.encodePacked(
            "vaultSetTokenConfig",
            _vault,
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxUsdsAmount,
            _isStable,
            _isShortable
        ));

        _validateAction(action);
        _clearAction(action);

        IVault(_vault).setTokenConfig(
            _token,
            _tokenDecimals,
            _tokenWeight,
            _minProfitBps,
            _maxUsdsAmount,
            _isStable,
            _isShortable
        );
    }

    function cancelAction(bytes32 _action) external onlyAdmin {
        _clearAction(_action);
    }

    function _mint(address _token, address _receiver, uint256 _amount) private {
        IMintable mintable = IMintable(_token);

        if (!mintable.isMinter(address(this))) {
            mintable.setMinter(address(this), true);
        }

        mintable.mint(_receiver, _amount);
        require(IERC20(_token).totalSupply() <= maxTokenSupply, "Timelock: maxTokenSupply exceeded");
    }

    function _setPendingAction(bytes32 _action) private {
        require(pendingActions[_action] == 0, "Timelock: action already signalled");
        pendingActions[_action] = block.timestamp.add(buffer);
        emit SignalPendingAction(_action);
    }

    function _validateAction(bytes32 _action) private view {
        require(pendingActions[_action] != 0, "Timelock: action not signalled");
        require(pendingActions[_action] < block.timestamp, "Timelock: action time not yet passed");
    }

    function _clearAction(bytes32 _action) private {
        require(pendingActions[_action] != 0, "Timelock: invalid _action");
        delete pendingActions[_action];
        emit ClearAction(_action);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../core/interfaces/IVault.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IBasePositionManager.sol";

contract VaultReader {
    function getVaultTokenInfoV3(
        address _vault,
        address _positionManager,
        address _weth,
        uint256 _usdsAmount,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 14;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
        IBasePositionManager positionManager = IBasePositionManager(_positionManager);

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.usdsAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdsAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxUsdsAmounts(token);
            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
            amounts[i * propsLength + 8] = positionManager.maxGlobalShortSizes(token);
            amounts[i * propsLength + 9] = vault.getMinPrice(token);
            amounts[i * propsLength + 10] = vault.getMaxPrice(token);
            amounts[i * propsLength + 11] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 12] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }

    function getVaultTokenInfoV4(
        address _vault,
        address _positionManager,
        address _weth,
        uint256 _usdsAmount,
        address[] memory _tokens
    ) public view returns (uint256[] memory) {
        uint256 propsLength = 15;

        IVault vault = IVault(_vault);
        IVaultPriceFeed priceFeed = IVaultPriceFeed(vault.priceFeed());
        IBasePositionManager positionManager = IBasePositionManager(_positionManager);

        uint256[] memory amounts = new uint256[](_tokens.length * propsLength);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (token == address(0)) {
                token = _weth;
            }

            amounts[i * propsLength] = vault.poolAmounts(token);
            amounts[i * propsLength + 1] = vault.reservedAmounts(token);
            amounts[i * propsLength + 2] = vault.usdsAmounts(token);
            amounts[i * propsLength + 3] = vault.getRedemptionAmount(token, _usdsAmount);
            amounts[i * propsLength + 4] = vault.tokenWeights(token);
            amounts[i * propsLength + 5] = vault.bufferAmounts(token);
            amounts[i * propsLength + 6] = vault.maxUsdsAmounts(token);
            amounts[i * propsLength + 7] = vault.globalShortSizes(token);
            amounts[i * propsLength + 8] = positionManager.maxGlobalShortSizes(token);
            amounts[i * propsLength + 9] = positionManager.maxGlobalLongSizes(token);
            amounts[i * propsLength + 10] = vault.getMinPrice(token);
            amounts[i * propsLength + 11] = vault.getMaxPrice(token);
            amounts[i * propsLength + 12] = vault.guaranteedUsd(token);
            amounts[i * propsLength + 13] = priceFeed.getPrimaryPrice(token, false);
            amounts[i * propsLength + 14] = priceFeed.getPrimaryPrice(token, true);
        }

        return amounts;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);

    function getTraderReferralInfo(address _account) external view returns (bytes32, address);

    function setTraderReferralCode(address _account, bytes32 _code) external;

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external;

    function setReferrerTier(address _referrer, uint256 _tierId) external;

    function govSetCodeOwner(bytes32 _code, address _newAccount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IReferralStorage.sol";

contract ReferralReader {
    function getCodeOwners(IReferralStorage _referralStorage, bytes32[] memory _codes) public view returns (address[] memory) {
        address[] memory owners = new address[](_codes.length);

        for (uint256 i = 0; i < _codes.length; i++) {
            bytes32 code = _codes[i];
            owners[i] = _referralStorage.codeOwners(code);
        }

        return owners;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "../libraries/math/SafeMath.sol";

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

import "./interfaces/IReferralStorage.sol";

contract ReferralStorage is Governable, IReferralStorage {
    using SafeMath for uint256;

    struct Tier {
        uint256 totalRebate; // e.g. 2400 for 24%
        uint256 discountShare; // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
    }

    uint256 public constant BASIS_POINTS = 10000;

    mapping(address => uint256) public referrerDiscountShares; // to override default value in tier
    mapping(address => uint256) public referrerTiers; // link between user <> tier
    mapping(uint256 => Tier) public tiers;

    mapping(address => bool) public isHandler;

    mapping(bytes32 => address) public override codeOwners;
    mapping(address => bytes32) public traderReferralCodes;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event SetReferrerDiscountShare(address referrer, uint256 discountShare);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralStorage: forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external override onlyGov {
        require(_totalRebate <= BASIS_POINTS, "ReferralStorage: invalid totalRebate");
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        Tier memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare);
    }

    function setReferrerTier(address _referrer, uint256 _tierId) external override onlyGov {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setReferrerDiscountShare(uint256 _discountShare) external {
        require(_discountShare <= BASIS_POINTS, "ReferralStorage: invalid discountShare");

        referrerDiscountShares[msg.sender] = _discountShare;
        emit SetReferrerDiscountShare(msg.sender, _discountShare);
    }

    function setTraderReferralCode(address _account, bytes32 _code) external override onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    function setTraderReferralCodeByUser(bytes32 _code) external {
        _setTraderReferralCode(msg.sender, _code);
    }

    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");
        require(codeOwners[_code] == address(0), "ReferralStorage: code already exists");

        codeOwners[_code] = msg.sender;
        emit RegisterCode(msg.sender, _code);
    }

    function setCodeOwner(bytes32 _code, address _newAccount) external {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        address account = codeOwners[_code];
        require(msg.sender == account, "ReferralStorage: forbidden");

        codeOwners[_code] = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    function govSetCodeOwner(bytes32 _code, address _newAccount) external override onlyGov {
        require(_code != bytes32(0), "ReferralStorage: invalid _code");

        codeOwners[_code] = _newAccount;
        emit GovSetCodeOwner(_code, _newAccount);
    }

    function getTraderReferralInfo(address _account) external view override returns (bytes32, address) {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
        }
        return (code, referrer);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract BonusDistributor is IRewardDistributor, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant BONUS_DURATION = 365 days;

    uint256 public bonusMultiplierBasisPoints;

    address public override rewardToken;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    address public admin;

    event Distribute(uint256 amount);
    event BonusMultiplierChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "BonusDistributor: forbidden");
        _;
    }

    constructor(address _rewardToken, address _rewardTracker) public {
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function updateLastDistributionTime() external onlyAdmin {
        lastDistributionTime = block.timestamp;
    }

    function setBonusMultiplier(uint256 _bonusMultiplierBasisPoints) external onlyAdmin {
        require(lastDistributionTime != 0, "BonusDistributor: invalid lastDistributionTime");
        IRewardTracker(rewardTracker).updateRewards();
        bonusMultiplierBasisPoints = _bonusMultiplierBasisPoints;
        emit BonusMultiplierChange(_bonusMultiplierBasisPoints);
    }

    function tokensPerInterval() public view override returns (uint256) {
        uint256 supply = IERC20(rewardTracker).totalSupply();
        return supply.mul(bonusMultiplierBasisPoints).div(BASIS_POINTS_DIVISOR).div(BONUS_DURATION);
    }

    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 supply = IERC20(rewardTracker).totalSupply();
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime);

        return timeDiff.mul(supply).mul(bonusMultiplierBasisPoints).div(BASIS_POINTS_DIVISOR).div(BONUS_DURATION);
    }

    function distribute() external override returns (uint256) {
        require(msg.sender == rewardTracker, "BonusDistributor: invalid msg.sender");
        uint256 amount = pendingRewards();
        if (amount == 0) {
            return 0;
        }

        lastDistributionTime = block.timestamp;

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }

        IERC20(rewardToken).safeTransfer(msg.sender, amount);

        emit Distribute(amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardDistributor {
    function rewardToken() external view returns (address);
    function tokensPerInterval() external view returns (uint256);
    function pendingRewards() external view returns (uint256);
    function distribute() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract RewardDistributor is IRewardDistributor, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public override rewardToken;
    uint256 public override tokensPerInterval;
    uint256 public lastDistributionTime;
    address public rewardTracker;

    address public admin;

    event Distribute(uint256 amount);
    event TokensPerIntervalChange(uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "RewardDistributor: forbidden");
        _;
    }

    constructor(address _rewardToken, address _rewardTracker) public {
        rewardToken = _rewardToken;
        rewardTracker = _rewardTracker;
        admin = msg.sender;
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function updateLastDistributionTime() external onlyAdmin {
        lastDistributionTime = block.timestamp;
    }

    function setTokensPerInterval(uint256 _amount) external onlyAdmin {
        require(lastDistributionTime != 0, "RewardDistributor: invalid lastDistributionTime");
        IRewardTracker(rewardTracker).updateRewards();
        tokensPerInterval = _amount;
        emit TokensPerIntervalChange(_amount);
    }

    function pendingRewards() public view override returns (uint256) {
        if (block.timestamp == lastDistributionTime) {
            return 0;
        }

        uint256 timeDiff = block.timestamp.sub(lastDistributionTime);
        return tokensPerInterval.mul(timeDiff);
    }

    function distribute() external override returns (uint256) {
        require(msg.sender == rewardTracker, "RewardDistributor: invalid msg.sender");
        uint256 amount = pendingRewards();
        if (amount == 0) {
            return 0;
        }

        lastDistributionTime = block.timestamp;

        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (amount > balance) {
            amount = balance;
        }

        IERC20(rewardToken).safeTransfer(msg.sender, amount);

        emit Distribute(amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

contract RewardManager is Governable {
    bool public isInitialized;

    ITimelock public timelock;
    address public rewardRouter;

    address public slpManager;

    address public stakedSkullTracker;
    address public feeSkullTracker;

    address public feeSlpTracker;
    address public stakedSlpTracker;

    address public stakedSkullDistributor;
    address public stakedSlpDistributor;

    function initialize(
        ITimelock _timelock,
        address _rewardRouter,
        address _slpManager,
        address _stakedSkullTracker,
        address _feeSkullTracker,
        address _feeSlpTracker,
        address _stakedSlpTracker,
        address _stakedSkullDistributor,
        address _stakedSlpDistributor
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        slpManager = _slpManager;

        stakedSkullTracker = _stakedSkullTracker;
        feeSkullTracker = _feeSkullTracker;

        feeSlpTracker = _feeSlpTracker;
        stakedSlpTracker = _stakedSlpTracker;

        stakedSkullDistributor = _stakedSkullDistributor;
        stakedSlpDistributor = _stakedSlpDistributor;

    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/token/TransferHelper.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/ISlpManager.sol";
import "../core/interfaces/IVault.sol";
import "../access/Governable.sol";
import "../peripherals/interfaces/ISwapRouter.sol";

contract RewardRouter is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;


    ISwapRouter public immutable swapRouter;

    address public vault;
    address public usdc;
    address public skull;

    address public slp; // SKULL Liquidity Provider token

    address public stakedSkullTracker;
    address public feeSkullTracker;

    address public stakedSlpTracker;
    address public feeSlpTracker;

    address public slpManager;

    mapping(address => address) public pendingReceivers;

    event StakeSkull(address account, address token, uint256 amount);
    event UnstakeSkull(address account, address token, uint256 amount);

    event StakeSlp(address account, uint256 amount);
    event UnstakeSlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    uint24 public constant SKULL_USDC_POOL_FEE = 10000;

    constructor(
        address _swapRouter,
        address _weth,
        address _skull,
        address _slp,       
        address _usdc,
        address _vault    
    ) public{
        swapRouter = ISwapRouter(_swapRouter);
        weth = _weth;
        skull = _skull;
        slp = _slp;        
        usdc = _usdc;
        vault = _vault;
    }

    function initialize(
        address _stakedSkullTracker,
        address _feeSkullTracker,
        address _feeSlpTracker,
        address _stakedSlpTracker,
        address _slpManager
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        stakedSkullTracker = _stakedSkullTracker;
        feeSkullTracker = _feeSkullTracker;

        feeSlpTracker = _feeSlpTracker;
        stakedSlpTracker = _stakedSlpTracker;

        slpManager = _slpManager;

    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeSkullForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _skull = skull;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeSkull(msg.sender, _accounts[i], _skull, _amounts[i]);
        }
    }

    function stakeSkullForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeSkull(msg.sender, _account, skull, _amount);
    }

    function stakeSkull(uint256 _amount) external nonReentrant {
        _stakeSkull(msg.sender, msg.sender, skull, _amount);
    }

    function unstakeSkull(uint256 _amount) external nonReentrant {
        _unstakeSkull(msg.sender, skull, _amount);
    }

    function mintAndStakeSlp(
        address _token,
        uint256 _amount,
        uint256 _minUsds,
        uint256 _minSlp
    ) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 slpAmount = ISlpManager(slpManager).addLiquidityForAccount(account, account, _token, _amount, _minUsds, _minSlp);
        IRewardTracker(feeSlpTracker).stakeForAccount(account, account, slp, slpAmount);
        IRewardTracker(stakedSlpTracker).stakeForAccount(account, account, feeSlpTracker, slpAmount);

        emit StakeSlp(account, slpAmount);

        return slpAmount;
    }

    function mintAndStakeSlpETH(uint256 _minUsds, uint256 _minSlp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        return _mintAndStakeSlpETH(msg.value,_minUsds, _minSlp);
    }

    function _mintAndStakeSlpETH(uint256 _amount,uint256 _minUsds, uint256 _minSlp) private returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IERC20(weth).approve(slpManager, _amount);

        address account = msg.sender;
        uint256 slpAmount = ISlpManager(slpManager).addLiquidityForAccount(address(this), account, weth, _amount, _minUsds, _minSlp);

        IRewardTracker(feeSlpTracker).stakeForAccount(account, account, slp, slpAmount);
        IRewardTracker(stakedSlpTracker).stakeForAccount(account, account, feeSlpTracker, slpAmount);

        emit StakeSlp(account, slpAmount);

        return slpAmount;
    }

    function unstakeAndRedeemSlp(
        address _tokenOut,
        uint256 _slpAmount,
        uint256 _minOut,
        address _receiver
    ) external nonReentrant returns (uint256) {
        require(_slpAmount > 0, "RewardRouter: invalid _slpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSlpTracker).unstakeForAccount(account, feeSlpTracker, _slpAmount, account);
        IRewardTracker(feeSlpTracker).unstakeForAccount(account, slp, _slpAmount, account);
        uint256 amountOut = ISlpManager(slpManager).removeLiquidityForAccount(account, _tokenOut, _slpAmount, _minOut, _receiver);

        emit UnstakeSlp(account, _slpAmount);

        return amountOut;
    }

    function unstakeAndRedeemSlpETH(
        uint256 _slpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external nonReentrant returns (uint256) {
        require(_slpAmount > 0, "RewardRouter: invalid _slpAmount");

        address account = msg.sender;
        IRewardTracker(stakedSlpTracker).unstakeForAccount(account, feeSlpTracker, _slpAmount, account);
        IRewardTracker(feeSlpTracker).unstakeForAccount(account, slp, _slpAmount, account);
        uint256 amountOut = ISlpManager(slpManager).removeLiquidityForAccount(account, weth, _slpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeSlp(account, _slpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSkullTracker).claimForAccount(account, account);
        IRewardTracker(feeSlpTracker).claimForAccount(account, account);

        IRewardTracker(stakedSkullTracker).claimForAccount(account, account);
        IRewardTracker(stakedSlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeSkullTracker).claimForAccount(account, account);
        IRewardTracker(feeSlpTracker).claimForAccount(account, account);
    }

    function handleRewards(
        bool _shouldStakeSkull,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth,
        bool _shouldAddIntoSLP,
        bool _shouldConvertSkullAndStake
    ) external nonReentrant returns (uint256 amountOut) {
        address account = msg.sender;

        uint256 skullAmount = 0;

        if (_shouldStakeSkull && skullAmount > 0) {
            _stakeSkull(account, account, skull, skullAmount);
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth || _shouldAddIntoSLP || _shouldConvertSkullAndStake) {
                uint256 weth0 = IRewardTracker(feeSkullTracker).claimForAccount(account, address(this));
                uint256 weth1 = IRewardTracker(feeSlpTracker).claimForAccount(account, address(this));

                uint256 wethAmount = weth0.add(weth1);
                

                if(_shouldAddIntoSLP){
                    amountOut = _mintAndStakeSlpETH(wethAmount,0,0);
                }else if(_shouldConvertSkullAndStake){
                    //convert weth->usdc->skull and stake

                    IERC20(weth).safeTransfer(vault, wethAmount);

                    //convert weth->usdc via vault
                    uint256 usdcAmountOut = IVault(vault).swap(weth, usdc, address(this));

                    //convert usdc->skull via uniswap
                     uint256 skullAmountOut = _swapExactInputSingle(usdcAmountOut);

                    if (skullAmountOut > 0) {
                        TransferHelper.safeApprove(skull, stakedSkullTracker, skullAmountOut);
                        _stakeSkull(address(this), account, skull, skullAmountOut);
                        amountOut = skullAmountOut;
                    }

                }else{
                    IWETH(weth).withdraw(wethAmount);
                    payable(account).sendValue(wethAmount);
                }
            } else {
                IRewardTracker(feeSkullTracker).claimForAccount(account, account);
                IRewardTracker(feeSlpTracker).claimForAccount(account, account);
            }
        }
    }

    function _swapExactInputSingle(uint256 amountIn) private returns (uint256 amountOut) {
        TransferHelper.safeApprove(usdc, address(swapRouter), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: usdc,
                tokenOut: skull,
                fee: SKULL_USDC_POOL_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    function signalTransfer(address _receiver) external nonReentrant {
        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);

        uint256 stakedSkull = IRewardTracker(stakedSkullTracker).depositBalances(_sender, skull);
        if (stakedSkull > 0) {
            _unstakeSkull(_sender, skull, stakedSkull);
            _stakeSkull(_sender, receiver, skull, stakedSkull);
        }

        uint256 slpAmount = IRewardTracker(feeSlpTracker).depositBalances(_sender, slp);
        if (slpAmount > 0) {
            IRewardTracker(stakedSlpTracker).unstakeForAccount(_sender, feeSlpTracker, slpAmount, _sender);
            IRewardTracker(feeSlpTracker).unstakeForAccount(_sender, slp, slpAmount, _sender);

            IRewardTracker(feeSlpTracker).stakeForAccount(_sender, receiver, slp, slpAmount);
            IRewardTracker(stakedSlpTracker).stakeForAccount(receiver, receiver, feeSlpTracker, slpAmount);
        }
    }

    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker(stakedSkullTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedSkullTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedSkullTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedSkullTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeSkullTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeSkullTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeSkullTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeSkullTracker.cumulativeRewards > 0");

        require(IRewardTracker(stakedSlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedSlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedSlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedSlpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeSlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeSlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeSlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeSlpTracker.cumulativeRewards > 0");
    }

    function _stakeSkull(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedSkullTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);

        emit StakeSkull(_account, _token, _amount);
    }

    function _unstakeSkull(
        address _account,
        address _token,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedSkullTracker).stakedAmounts(_account);

        IRewardTracker(stakedSkullTracker).unstakeForAccount(_account, _token, _amount, _account);

        emit UnstakeSkull(_account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IRewardDistributor.sol";
import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract RewardTracker is IERC20, ReentrancyGuard, IRewardTracker, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRECISION = 1e30;

    uint8 public constant decimals = 18;

    bool public isInitialized;

    string public name;
    string public symbol;

    address public distributor;
    mapping(address => bool) public isDepositToken;
    mapping(address => mapping(address => uint256)) public override depositBalances;
    mapping(address => uint256) public totalDepositSupply;

    uint256 public override totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    uint256 public cumulativeRewardPerToken;
    mapping(address => uint256) public override stakedAmounts;
    mapping(address => uint256) public claimableReward;
    mapping(address => uint256) public previousCumulatedRewardPerToken;
    mapping(address => uint256) public override cumulativeRewards;
    mapping(address => uint256) public override averageStakedAmounts;

    bool public inPrivateTransferMode;
    bool public inPrivateStakingMode;
    bool public inPrivateClaimingMode;
    mapping(address => bool) public isHandler;

    event Claim(address receiver, uint256 amount);

    constructor(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
    }

    function initialize(address[] memory _depositTokens, address _distributor) external onlyGov {
        require(!isInitialized, "RewardTracker: already initialized");
        isInitialized = true;

        for (uint256 i = 0; i < _depositTokens.length; i++) {
            address depositToken = _depositTokens[i];
            isDepositToken[depositToken] = true;
        }

        distributor = _distributor;
    }

    function setDepositToken(address _depositToken, bool _isDepositToken) external onlyGov {
        isDepositToken[_depositToken] = _isDepositToken;
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
    }

    function setInPrivateStakingMode(bool _inPrivateStakingMode) external onlyGov {
        inPrivateStakingMode = _inPrivateStakingMode;
    }

    function setInPrivateClaimingMode(bool _inPrivateClaimingMode) external onlyGov {
        inPrivateClaimingMode = _inPrivateClaimingMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stake(address _depositToken, uint256 _amount) external override nonReentrant {
        if (inPrivateStakingMode) {
            revert("RewardTracker: action not enabled");
        }
        _stake(msg.sender, msg.sender, _depositToken, _amount);
    }

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external override nonReentrant {
        _validateHandler();
        _stake(_fundingAccount, _account, _depositToken, _amount);
    }

    function unstake(address _depositToken, uint256 _amount) external override nonReentrant {
        if (inPrivateStakingMode) {
            revert("RewardTracker: action not enabled");
        }
        _unstake(msg.sender, _depositToken, _amount, msg.sender);
    }

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external override nonReentrant {
        _validateHandler();
        _unstake(_account, _depositToken, _amount, _receiver);
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }

        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "RewardTracker: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function tokensPerInterval() external view override returns (uint256) {
        return IRewardDistributor(distributor).tokensPerInterval();
    }

    function updateRewards() external override nonReentrant {
        _updateRewards(address(0));
    }

    function claim(address _receiver) external override nonReentrant returns (uint256) {
        if (inPrivateClaimingMode) {
            revert("RewardTracker: action not enabled");
        }
        return _claim(msg.sender, _receiver);
    }

    function claimForAccount(address _account, address _receiver) external override nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    function claimable(address _account) public view override returns (uint256) {
        uint256 stakedAmount = stakedAmounts[_account];
        if (stakedAmount == 0) {
            return claimableReward[_account];
        }
        uint256 supply = totalSupply;
        uint256 pendingRewards = IRewardDistributor(distributor).pendingRewards().mul(PRECISION);
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken.add(pendingRewards.div(supply));
        return claimableReward[_account].add(stakedAmount.mul(nextCumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account])).div(PRECISION));
    }

    function rewardToken() public view returns (address) {
        return IRewardDistributor(distributor).rewardToken();
    }

    function _claim(address _account, address _receiver) private returns (uint256) {
        _updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        if (tokenAmount > 0) {
            IERC20(rewardToken()).safeTransfer(_receiver, tokenAmount);
            emit Claim(_account, tokenAmount);
        }

        return tokenAmount;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "RewardTracker: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "RewardTracker: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "RewardTracker: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "RewardTracker: transfer from the zero address");
        require(_recipient != address(0), "RewardTracker: transfer to the zero address");

        if (inPrivateTransferMode) {
            _validateHandler();
        }

        balances[_sender] = balances[_sender].sub(_amount, "RewardTracker: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "RewardTracker: approve from the zero address");
        require(_spender != address(0), "RewardTracker: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "RewardTracker: forbidden");
    }

    function _stake(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");

        IERC20(_depositToken).safeTransferFrom(_fundingAccount, address(this), _amount);

        _updateRewards(_account);

        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
        depositBalances[_account][_depositToken] = depositBalances[_account][_depositToken].add(_amount);
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken].add(_amount);

        _mint(_account, _amount);
    }

    function _unstake(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) private {
        require(_amount > 0, "RewardTracker: invalid _amount");
        require(isDepositToken[_depositToken], "RewardTracker: invalid _depositToken");

        _updateRewards(_account);

        uint256 stakedAmount = stakedAmounts[_account];
        require(stakedAmounts[_account] >= _amount, "RewardTracker: _amount exceeds stakedAmount");

        stakedAmounts[_account] = stakedAmount.sub(_amount);

        uint256 depositBalance = depositBalances[_account][_depositToken];
        require(depositBalance >= _amount, "RewardTracker: _amount exceeds depositBalance");
        depositBalances[_account][_depositToken] = depositBalance.sub(_amount);
        totalDepositSupply[_depositToken] = totalDepositSupply[_depositToken].sub(_amount);

        _burn(_account, _amount);
        IERC20(_depositToken).safeTransfer(_receiver, _amount);
    }

    function _updateRewards(address _account) private {
        uint256 blockReward = IRewardDistributor(distributor).distribute();

        uint256 supply = totalSupply;
        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        if (supply > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(supply));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedAmount = stakedAmounts[_account];
            uint256 accountReward = stakedAmount.mul(_cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account])).div(PRECISION);
            uint256 _claimableReward = claimableReward[_account].add(accountReward);

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;

            if (_claimableReward > 0 && stakedAmounts[_account] > 0) {
                uint256 nextCumulativeReward = cumulativeRewards[_account].add(accountReward);

                averageStakedAmounts[_account] = averageStakedAmounts[_account].mul(cumulativeRewards[_account]).div(nextCumulativeReward).add(
                    stakedAmount.mul(accountReward).div(nextCumulativeReward)
                );

                cumulativeRewards[_account] = nextCumulativeReward;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./RewardDistributor.sol";
import "./BonusDistributor.sol";

contract StakedSkullDistributor is RewardDistributor {
    constructor(address _rewardToken, address _rewardTracker) public RewardDistributor(_rewardToken, _rewardTracker) {}
}

contract FeeSkullDistributor is RewardDistributor {
    constructor(address _rewardToken, address _rewardTracker) public RewardDistributor(_rewardToken, _rewardTracker) {}
}

contract StakedSlpDistributor is RewardDistributor {
    constructor(address _rewardToken, address _rewardTracker) public RewardDistributor(_rewardToken, _rewardTracker) {}
}

contract FeeSlpDistributor is RewardDistributor {
    constructor(address _rewardToken, address _rewardTracker) public RewardDistributor(_rewardToken, _rewardTracker) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./RewardTracker.sol";

contract StakedSkullTracker is RewardTracker {
    constructor() public RewardTracker("Staked SKULL", "sSKULL") {}
}

contract FeeSkullTracker is RewardTracker {
    constructor() public RewardTracker("Staked + Fee SKULL", "sfSKULL") {}
}

contract StakedSlpTracker is RewardTracker {
    constructor() public RewardTracker("Fee + Staked SLP", "fsSLP") {}
}

contract FeeSlpTracker is RewardTracker {
    constructor() public RewardTracker("Fee SLP", "fSLP") {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract SKULL is MintableBaseToken {
    constructor() public MintableBaseToken("Mason Jar", "SKULL", 0) {}

    function id() external pure returns (string memory _name) {
        return "SKULL";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../tokens/MintableBaseToken.sol";

contract SLP is MintableBaseToken {
    constructor() public MintableBaseToken("SKULL LP", "SLP", 0) {}

    function id() external pure returns (string memory _name) {
        return "SLP";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../core/interfaces/ISlpManager.sol";

contract SlpBalance {
    using SafeMath for uint256;

    ISlpManager public slpManager;
    address public stakedSlpTracker;

    mapping(address => mapping(address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(ISlpManager _slpManager, address _stakedSlpTracker) public {
        slpManager = _slpManager;
        stakedSlpTracker = _stakedSlpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "SlpBalance: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "SlpBalance: approve from the zero address");
        require(_spender != address(0), "SlpBalance: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "SlpBalance: transfer from the zero address");
        require(_recipient != address(0), "SlpBalance: transfer to the zero address");

        require(slpManager.lastAddedAt(_sender).add(slpManager.cooldownDuration()) <= block.timestamp, "SlpBalance: cooldown duration not yet passed");

        IERC20(stakedSlpTracker).transferFrom(_sender, _recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

import "../core/interfaces/ISlpManager.sol";

import "./interfaces/IRewardTracker.sol";

contract StakedSlp {
    using SafeMath for uint256;

    string public constant name = "StakedSlp";
    string public constant symbol = "sSLP";
    uint8 public constant decimals = 18;

    address public slp;
    ISlpManager public slpManager;
    address public stakedSlpTracker;
    address public feeSlpTracker;

    mapping(address => mapping(address => uint256)) public allowances;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address _slp,
        ISlpManager _slpManager,
        address _stakedSlpTracker,
        address _feeSlpTracker
    ) public {
        slp = _slp;
        slpManager = _slpManager;
        stakedSlpTracker = _stakedSlpTracker;
        feeSlpTracker = _feeSlpTracker;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "StakedSlp: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function balanceOf(address _account) external view returns (uint256) {
        IRewardTracker(stakedSlpTracker).depositBalances(_account, slp);
    }

    function totalSupply() external view returns (uint256) {
        IERC20(stakedSlpTracker).totalSupply();
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "StakedSlp: approve from the zero address");
        require(_spender != address(0), "StakedSlp: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "StakedSlp: transfer from the zero address");
        require(_recipient != address(0), "StakedSlp: transfer to the zero address");

        require(slpManager.lastAddedAt(_sender).add(slpManager.cooldownDuration()) <= block.timestamp, "StakedSlp: cooldown duration not yet passed");

        IRewardTracker(stakedSlpTracker).unstakeForAccount(_sender, feeSlpTracker, _amount, _sender);
        IRewardTracker(feeSlpTracker).unstakeForAccount(_sender, slp, _amount, _sender);

        IRewardTracker(feeSlpTracker).stakeForAccount(_sender, _recipient, slp, _amount);
        IRewardTracker(stakedSlpTracker).stakeForAccount(_recipient, _recipient, feeSlpTracker, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IRewardTracker.sol";
import "../access/Governable.sol";

contract StakeManager is Governable {
    function stakeForAccount(
        address _rewardTracker,
        address _account,
        address _token,
        uint256 _amount
    ) external onlyGov {
        IRewardTracker(_rewardTracker).stakeForAccount(_account, _account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";

import "./interfaces/IYieldTracker.sol";
import "./interfaces/IBaseToken.sol";

contract BaseToken is IERC20, IBaseToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    uint256 public nonStakingSupply;

    address public gov;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    address[] public yieldTrackers;
    mapping(address => bool) public nonStakingAccounts;
    mapping(address => bool) public admins;

    bool public inPrivateTransferMode;
    mapping(address => bool) public isHandler;

    modifier onlyGov() {
        require(msg.sender == gov, "BaseToken: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "BaseToken: forbidden");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setInfo(string memory _name, string memory _symbol) external onlyGov {
        name = _name;
        symbol = _symbol;
    }

    function setYieldTrackers(address[] memory _yieldTrackers) external onlyGov {
        yieldTrackers = _yieldTrackers;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external override onlyGov {
        admins[_account] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external override onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external override onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
    }

    function addNonStakingAccount(address _account) external onlyAdmin {
        require(!nonStakingAccounts[_account], "BaseToken: _account already marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = true;
        nonStakingSupply = nonStakingSupply.add(balances[_account]);
    }

    function removeNonStakingAccount(address _account) external onlyAdmin {
        require(nonStakingAccounts[_account], "BaseToken: _account not marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = false;
        nonStakingSupply = nonStakingSupply.sub(balances[_account]);
    }

    function recoverClaim(address _account, address _receiver) external onlyAdmin {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(_account, _receiver);
        }
    }

    function claim(address _receiver) external {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(msg.sender, _receiver);
        }
    }

    function totalStaked() external view override returns (uint256) {
        return totalSupply.sub(nonStakingSupply);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stakedBalance(address _account) external view override returns (uint256) {
        if (nonStakingAccounts[_account]) {
            return 0;
        }
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        if (isHandler[msg.sender]) {
            _transfer(_sender, _recipient, _amount);
            return true;
        }
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "BaseToken: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "BaseToken: mint to the zero address");

        _updateRewards(_account);

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "BaseToken: burn from the zero address");

        _updateRewards(_account);

        balances[_account] = balances[_account].sub(_amount, "BaseToken: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "BaseToken: transfer from the zero address");
        require(_recipient != address(0), "BaseToken: transfer to the zero address");

        if (inPrivateTransferMode) {
            require(isHandler[msg.sender], "BaseToken: msg.sender not whitelisted");
        }

        _updateRewards(_sender);
        _updateRewards(_recipient);

        balances[_sender] = balances[_sender].sub(_amount, "BaseToken: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        if (nonStakingAccounts[_sender]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }
        if (nonStakingAccounts[_recipient]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "BaseToken: approve from the zero address");
        require(_spender != address(0), "BaseToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _updateRewards(address _account) private {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).updateRewards(_account);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "../access/Governable.sol";

contract Bridge is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public token;
    address public wToken;

    constructor(address _token, address _wToken) public {
        token = _token;
        wToken = _wToken;
    }

    function wrap(uint256 _amount, address _receiver) external nonReentrant {
        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(wToken).safeTransfer(_receiver, _amount);
    }

    function unwrap(uint256 _amount, address _receiver) external nonReentrant {
        IERC20(wToken).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(token).safeTransfer(_receiver, _amount);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract FaucetToken is IERC20 {
    using SafeMath for uint256;

    uint256 public DROPLET_INTERVAL = 8 hours;

    address public _gov;
    uint256 public _dropletAmount;
    bool public _isFaucetEnabled;

    mapping(address => uint256) public _claimedAt;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 dropletAmount
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _gov = msg.sender;
        _dropletAmount = dropletAmount;
    }

    function mint(address account, uint256 amount) public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _mint(account, amount);
    }

    function enableFaucet() public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _isFaucetEnabled = true;
    }

    function disableFaucet() public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _isFaucetEnabled = false;
    }

    function setDropletAmount(uint256 dropletAmount) public {
        require(msg.sender == _gov, "FaucetToken: forbidden");
        _dropletAmount = dropletAmount;
    }

    function claimDroplet() public {
        require(_isFaucetEnabled, "FaucetToken: faucet not enabled");
        require(_claimedAt[msg.sender].add(DROPLET_INTERVAL) <= block.timestamp, "FaucetToken: droplet not available yet");
        _claimedAt[msg.sender] = block.timestamp;
        _mint(msg.sender, _dropletAmount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IBaseToken {
    function totalStaked() external view returns (uint256);

    function stakedBalance(address _account) external view returns (uint256);

    function removeAdmin(address _account) external;

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;

    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IDistributor {
    function distribute() external returns (uint256);

    function getRewardToken(address _receiver) external view returns (address);

    function getDistributionAmount(address _receiver)
        external
        view
        returns (uint256);

    function tokensPerInterval(address _receiver)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUSDS {
    function addVault(address _vault) external;

    function removeVault(address _vault) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IYieldToken {
    function totalStaked() external view returns (uint256);
    function stakedBalance(address _account) external view returns (uint256);
    function removeAdmin(address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IYieldTracker {
    function claim(address _account, address _receiver) external returns (uint256);
    function updateRewards(address _account) external;
    function getTokensPerInterval() external view returns (uint256);
    function claimable(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./BaseToken.sol";
import "./interfaces/IMintable.sol";

contract MintableBaseToken is BaseToken, IMintable {
    mapping(address => bool) public override isMinter;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public BaseToken(_name, _symbol, _initialSupply) {}

    modifier onlyMinter() {
        require(isMinter[msg.sender], "MintableBaseToken: forbidden");
        _;
    }

    function setMinter(address _minter, bool _isActive) external override onlyGov {
        isMinter[_minter] = _isActive;
    }

    function mint(address _account, uint256 _amount) external override onlyMinter {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyMinter {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MintableBaseToken.sol";

contract SnapshotToken is MintableBaseToken {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public MintableBaseToken(_name, _symbol, _initialSupply) {}

    function batchMint(address[] memory _accounts, uint256[] memory _amounts) external onlyMinter {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];
            _mint(account, amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";

import "./interfaces/IDistributor.sol";

contract TimeDistributor is IDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant DISTRIBUTION_INTERVAL = 1 hours;
    address public gov;
    address public admin;

    mapping(address => address) public rewardTokens;
    mapping(address => uint256) public override tokensPerInterval;
    mapping(address => uint256) public lastDistributionTime;

    event Distribute(address receiver, uint256 amount);
    event DistributionChange(address receiver, uint256 amount, address rewardToken);
    event TokensPerIntervalChange(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "TimeDistributor: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "TimeDistributor: forbidden");
        _;
    }

    constructor() public {
        gov = msg.sender;
        admin = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setTokensPerInterval(address _receiver, uint256 _amount) external onlyAdmin {
        if (lastDistributionTime[_receiver] != 0) {
            uint256 intervals = getIntervals(_receiver);
            require(intervals == 0, "TimeDistributor: pending distribution");
        }

        tokensPerInterval[_receiver] = _amount;
        _updateLastDistributionTime(_receiver);
        emit TokensPerIntervalChange(_receiver, _amount);
    }

    function updateLastDistributionTime(address _receiver) external onlyAdmin {
        _updateLastDistributionTime(_receiver);
    }

    function setDistribution(
        address[] calldata _receivers,
        uint256[] calldata _amounts,
        address[] calldata _rewardTokens
    ) external onlyGov {
        for (uint256 i = 0; i < _receivers.length; i++) {
            address receiver = _receivers[i];

            if (lastDistributionTime[receiver] != 0) {
                uint256 intervals = getIntervals(receiver);
                require(intervals == 0, "TimeDistributor: pending distribution");
            }

            uint256 amount = _amounts[i];
            address rewardToken = _rewardTokens[i];
            tokensPerInterval[receiver] = amount;
            rewardTokens[receiver] = rewardToken;
            _updateLastDistributionTime(receiver);
            emit DistributionChange(receiver, amount, rewardToken);
        }
    }

    function distribute() external override returns (uint256) {
        address receiver = msg.sender;
        uint256 intervals = getIntervals(receiver);

        if (intervals == 0) {
            return 0;
        }

        uint256 amount = getDistributionAmount(receiver);
        _updateLastDistributionTime(receiver);

        if (amount == 0) {
            return 0;
        }

        IERC20(rewardTokens[receiver]).safeTransfer(receiver, amount);

        emit Distribute(receiver, amount);
        return amount;
    }

    function getRewardToken(address _receiver) external view override returns (address) {
        return rewardTokens[_receiver];
    }

    function getDistributionAmount(address _receiver) public view override returns (uint256) {
        uint256 _tokensPerInterval = tokensPerInterval[_receiver];
        if (_tokensPerInterval == 0) {
            return 0;
        }

        uint256 intervals = getIntervals(_receiver);
        uint256 amount = _tokensPerInterval.mul(intervals);

        if (IERC20(rewardTokens[_receiver]).balanceOf(address(this)) < amount) {
            return 0;
        }

        return amount;
    }

    function getIntervals(address _receiver) public view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastDistributionTime[_receiver]);
        return timeDiff.div(DISTRIBUTION_INTERVAL);
    }

    function _updateLastDistributionTime(address _receiver) private {
        lastDistributionTime[_receiver] = block.timestamp.div(DISTRIBUTION_INTERVAL).mul(DISTRIBUTION_INTERVAL);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract Token is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() public {
        _name = "Token";
        _symbol = "TOKEN";
        _decimals = 18;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function withdrawToken(
        address token,
        address account,
        uint256 amount
    ) public {
        IERC20(token).transfer(account, amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Token: insufficient balance");
        _burn(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract TokenMock is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function withdrawToken(
        address token,
        address account,
        uint256 amount
    ) public {
        IERC20(token).transfer(account, amount);
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount, "Token: insufficient balance");
        _burn(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./interfaces/IUSDS.sol";
import "./YieldToken.sol";

contract USDS is YieldToken, IUSDS {
    mapping(address => bool) public vaults;

    modifier onlyVault() {
        require(vaults[msg.sender], "USDS: forbidden");
        _;
    }

    constructor(address _vault) public YieldToken("USD Skull", "USDS", 0) {
        vaults[_vault] = true;
    }

    function addVault(address _vault) external override onlyGov {
        vaults[_vault] = true;
    }

    function removeVault(address _vault) external override onlyGov {
        vaults[_vault] = false;
    }

    function mint(address _account, uint256 _amount) external override onlyVault {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external override onlyVault {
        _burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract WETH is IERC20 {
    using SafeMath for uint256;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function deposit() public payable {
        _balances[msg.sender] = _balances[msg.sender].add(msg.value);
    }

    function withdraw(uint256 amount) public {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./YieldToken.sol";

contract YieldFarm is YieldToken, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public stakingToken;

    constructor(
        string memory _name,
        string memory _symbol,
        address _stakingToken
    ) public YieldToken(_name, _symbol, 0) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 _amount) external nonReentrant {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external nonReentrant {
        _burn(msg.sender, _amount);
        IERC20(stakingToken).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";

import "./interfaces/IYieldTracker.sol";
import "./interfaces/IYieldToken.sol";

contract YieldToken is IERC20, IYieldToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    uint256 public nonStakingSupply;

    address public gov;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    address[] public yieldTrackers;
    mapping(address => bool) public nonStakingAccounts;
    mapping(address => bool) public admins;

    bool public inWhitelistMode;
    mapping(address => bool) public whitelistedHandlers;

    modifier onlyGov() {
        require(msg.sender == gov, "YieldToken: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "YieldToken: forbidden");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) public {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;
        admins[msg.sender] = true;
        _mint(msg.sender, _initialSupply);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setInfo(string memory _name, string memory _symbol) external onlyGov {
        name = _name;
        symbol = _symbol;
    }

    function setYieldTrackers(address[] memory _yieldTrackers) external onlyGov {
        yieldTrackers = _yieldTrackers;
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external override onlyGov {
        admins[_account] = false;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function setInWhitelistMode(bool _inWhitelistMode) external onlyGov {
        inWhitelistMode = _inWhitelistMode;
    }

    function setWhitelistedHandler(address _handler, bool _isWhitelisted) external onlyGov {
        whitelistedHandlers[_handler] = _isWhitelisted;
    }

    function addNonStakingAccount(address _account) external onlyAdmin {
        require(!nonStakingAccounts[_account], "YieldToken: _account already marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = true;
        nonStakingSupply = nonStakingSupply.add(balances[_account]);
    }

    function removeNonStakingAccount(address _account) external onlyAdmin {
        require(nonStakingAccounts[_account], "YieldToken: _account not marked");
        _updateRewards(_account);
        nonStakingAccounts[_account] = false;
        nonStakingSupply = nonStakingSupply.sub(balances[_account]);
    }

    function recoverClaim(address _account, address _receiver) external onlyAdmin {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(_account, _receiver);
        }
    }

    function claim(address _receiver) external {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).claim(msg.sender, _receiver);
        }
    }

    function totalStaked() external view override returns (uint256) {
        return totalSupply.sub(nonStakingSupply);
    }

    function balanceOf(address _account) external view override returns (uint256) {
        return balances[_account];
    }

    function stakedBalance(address _account) external view override returns (uint256) {
        if (nonStakingAccounts[_account]) {
            return 0;
        }
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "YieldToken: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "YieldToken: mint to the zero address");

        _updateRewards(_account);

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(_account != address(0), "YieldToken: burn from the zero address");

        _updateRewards(_account);

        balances[_account] = balances[_account].sub(_amount, "YieldToken: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(_sender != address(0), "YieldToken: transfer from the zero address");
        require(_recipient != address(0), "YieldToken: transfer to the zero address");

        if (inWhitelistMode) {
            require(whitelistedHandlers[msg.sender], "YieldToken: msg.sender not whitelisted");
        }

        _updateRewards(_sender);
        _updateRewards(_recipient);

        balances[_sender] = balances[_sender].sub(_amount, "YieldToken: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);

        if (nonStakingAccounts[_sender]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }
        if (nonStakingAccounts[_recipient]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(_owner != address(0), "YieldToken: approve from the zero address");
        require(_spender != address(0), "YieldToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }

    function _updateRewards(address _account) private {
        for (uint256 i = 0; i < yieldTrackers.length; i++) {
            address yieldTracker = yieldTrackers[i];
            IYieldTracker(yieldTracker).updateRewards(_account);
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";

import "./interfaces/IDistributor.sol";
import "./interfaces/IYieldTracker.sol";
import "./interfaces/IYieldToken.sol";

// code adapated from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract YieldTracker is IYieldTracker, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant PRECISION = 1e30;

    address public gov;
    address public yieldToken;
    address public distributor;

    uint256 public cumulativeRewardPerToken;
    mapping(address => uint256) public claimableReward;
    mapping(address => uint256) public previousCumulatedRewardPerToken;

    event Claim(address receiver, uint256 amount);

    modifier onlyGov() {
        require(msg.sender == gov, "YieldTracker: forbidden");
        _;
    }

    constructor(address _yieldToken) public {
        gov = msg.sender;
        yieldToken = _yieldToken;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setDistributor(address _distributor) external onlyGov {
        distributor = _distributor;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function claim(address _account, address _receiver) external override returns (uint256) {
        require(msg.sender == yieldToken, "YieldTracker: forbidden");
        updateRewards(_account);

        uint256 tokenAmount = claimableReward[_account];
        claimableReward[_account] = 0;

        address rewardToken = IDistributor(distributor).getRewardToken(address(this));
        IERC20(rewardToken).safeTransfer(_receiver, tokenAmount);
        emit Claim(_account, tokenAmount);

        return tokenAmount;
    }

    function getTokensPerInterval() external view override returns (uint256) {
        return IDistributor(distributor).tokensPerInterval(address(this));
    }

    function claimable(address _account) external view override returns (uint256) {
        uint256 stakedBalance = IYieldToken(yieldToken).stakedBalance(_account);
        if (stakedBalance == 0) {
            return claimableReward[_account];
        }
        uint256 pendingRewards = IDistributor(distributor).getDistributionAmount(address(this)).mul(PRECISION);
        uint256 totalStaked = IYieldToken(yieldToken).totalStaked();
        uint256 nextCumulativeRewardPerToken = cumulativeRewardPerToken.add(pendingRewards.div(totalStaked));
        return claimableReward[_account].add(stakedBalance.mul(nextCumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[_account])).div(PRECISION));
    }

    function updateRewards(address _account) public override nonReentrant {
        uint256 blockReward;

        if (distributor != address(0)) {
            blockReward = IDistributor(distributor).distribute();
        }

        uint256 _cumulativeRewardPerToken = cumulativeRewardPerToken;
        uint256 totalStaked = IYieldToken(yieldToken).totalStaked();
        // only update cumulativeRewardPerToken when there are stakers, i.e. when totalStaked > 0
        // if blockReward == 0, then there will be no change to cumulativeRewardPerToken
        if (totalStaked > 0 && blockReward > 0) {
            _cumulativeRewardPerToken = _cumulativeRewardPerToken.add(blockReward.mul(PRECISION).div(totalStaked));
            cumulativeRewardPerToken = _cumulativeRewardPerToken;
        }

        // cumulativeRewardPerToken can only increase
        // so if cumulativeRewardPerToken is zero, it means there are no rewards yet
        if (_cumulativeRewardPerToken == 0) {
            return;
        }

        if (_account != address(0)) {
            uint256 stakedBalance = IYieldToken(yieldToken).stakedBalance(_account);
            uint256 _previousCumulatedReward = previousCumulatedRewardPerToken[_account];
            uint256 _claimableReward = claimableReward[_account].add(stakedBalance.mul(_cumulativeRewardPerToken.sub(_previousCumulatedReward)).div(PRECISION));

            claimableReward[_account] = _claimableReward;
            previousCumulatedRewardPerToken[_account] = _cumulativeRewardPerToken;
        }
    }
}