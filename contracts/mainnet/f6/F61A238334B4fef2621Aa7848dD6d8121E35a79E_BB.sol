// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './ManagerRole.sol';
import { NativeTokenAddress } from './NativeTokenAddress.sol';
import { SafeTransfer } from './SafeTransfer.sol';

abstract contract BalanceManagement is ManagerRole, NativeTokenAddress, SafeTransfer {
    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            safeTransferNative(msg.sender, _tokenAmount);
        } else {
            safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

abstract contract DataStructures {
    struct OptionalValue {
        bool isSet;
        uint256 value;
    }

    struct KeyToValue {
        uint256 key;
        uint256 value;
    }

    struct KeyToAddressValue {
        uint256 key;
        address value;
    }

    struct KeyToAddressAndFlag {
        uint256 key;
        address value;
        bool flag;
    }

    function combinedMapSet(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        mapping(uint256 => OptionalValue) storage _keyIndexMap,
        uint256 _key,
        address _value
    ) internal returns (bool isNewKey) {
        isNewKey = !_keyIndexMap[_key].isSet;

        if (isNewKey) {
            uniqueListAdd(_keyList, _keyIndexMap, _key);
        }

        _map[_key] = _value;
    }

    function combinedMapRemove(
        mapping(uint256 => address) storage _map,
        uint256[] storage _keyList,
        mapping(uint256 => OptionalValue) storage _keyIndexMap,
        uint256 _key
    ) internal returns (bool isChanged) {
        isChanged = _keyIndexMap[_key].isSet;

        if (isChanged) {
            delete _map[_key];
            uniqueListRemove(_keyList, _keyIndexMap, _key);
        }
    }

    function uniqueListAdd(
        uint256[] storage _list,
        mapping(uint256 => OptionalValue) storage _indexMap,
        uint256 _value
    ) internal returns (bool isChanged) {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueListRemove(
        uint256[] storage _list,
        mapping(uint256 => OptionalValue) storage _indexMap,
        uint256 _value
    ) internal returns (bool isChanged) {
        OptionalValue storage indexItem = _indexMap[_value];

        isChanged = indexItem.isSet;

        if (isChanged) {
            uint256 itemIndex = indexItem.value;
            uint256 lastIndex = _list.length - 1;

            if (itemIndex != lastIndex) {
                uint256 lastValue = _list[lastIndex];
                _list[itemIndex] = lastValue;
                _indexMap[lastValue].value = itemIndex;
            }

            _list.pop();
            delete _indexMap[_value];
        }
    }

    function uniqueAddressListAdd(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    ) internal returns (bool isChanged) {
        isChanged = !_indexMap[_value].isSet;

        if (isChanged) {
            _indexMap[_value] = OptionalValue(true, _list.length);
            _list.push(_value);
        }
    }

    function uniqueAddressListRemove(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value
    ) internal returns (bool isChanged) {
        OptionalValue storage indexItem = _indexMap[_value];

        isChanged = indexItem.isSet;

        if (isChanged) {
            uint256 itemIndex = indexItem.value;
            uint256 lastIndex = _list.length - 1;

            if (itemIndex != lastIndex) {
                address lastValue = _list[lastIndex];
                _list[itemIndex] = lastValue;
                _indexMap[lastValue].value = itemIndex;
            }

            _list.pop();
            delete _indexMap[_value];
        }
    }

    function uniqueAddressListUpdate(
        address[] storage _list,
        mapping(address => OptionalValue) storage _indexMap,
        address _value,
        bool _flag
    ) internal returns (bool isChanged) {
        return
            _flag
                ? uniqueAddressListAdd(_list, _indexMap, _value)
                : uniqueAddressListRemove(_list, _indexMap, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { IAssetReceiver } from '../interfaces/IAssetReceiver.sol';
import { IBuybackToken } from '../interfaces/IBuybackToken.sol';
import { ISwapRouter } from '../interfaces/ISwapRouter.sol';
import { BalanceManagement } from '../BalanceManagement.sol';

contract BB is BalanceManagement, IAssetReceiver {
    error OnlyFeeMediatorError();
    error SwapToleranceValueError();

    IBuybackToken public immutable buybackToken;
    address public feeMediator;
    ISwapRouter public swapRouter;
    uint256 public swapTolerance; // Value in millipercent
    bool public isBurnMode;

    uint256 public totalBuyback = 0;

    uint256 private constant MILLIPERCENT_FACTOR = 1e5;

    constructor(
        IBuybackToken _buybackToken,
        ISwapRouter _swapRouter,
        uint256 _swapTolerance, // Value in millipercent
        bool _isBurnMode,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    ) {
        buybackToken = _buybackToken;
        swapRouter = _swapRouter;
        swapTolerance = _swapTolerance;
        isBurnMode = _isBurnMode;

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    modifier onlyFeeMediator() {
        if (msg.sender != address(feeMediator)) {
            revert OnlyFeeMediatorError();
        }

        _;
    }

    function setFeeMediator(address _feeMediator) external onlyManager {
        feeMediator = _feeMediator;
    }

    function setSwapRouter(ISwapRouter _swapRouter) external onlyManager {
        swapRouter = _swapRouter;
    }

    // Value in millipercent
    function setSwapTolerance(uint256 _swapTolerance) external onlyManager {
        if (_swapTolerance > MILLIPERCENT_FACTOR) {
            revert SwapToleranceValueError();
        }

        swapTolerance = _swapTolerance;
    }

    function setBurnMode(bool _isBurnMode) external onlyManager {
        isBurnMode = _isBurnMode;
    }

    function receiveAsset(address _tokenAddress, uint256 _amount) external onlyFeeMediator {
        safeTransferFrom(_tokenAddress, feeMediator, address(this), _amount);

        uint256 buybackTokenBalanceInitial = buybackToken.balanceOf(address(this));

        _buybackForToken(_tokenAddress);

        uint256 buybackTokenReceived = buybackToken.balanceOf(address(this)) -
            buybackTokenBalanceInitial;

        totalBuyback += buybackTokenReceived;

        if (isBurnMode) {
            buybackToken.burn(buybackTokenReceived);
        }
    }

    function withdraw() external onlyManager {
        uint256 balance = buybackToken.balanceOf(address(this));

        if (balance > 0) {
            safeTransfer(address(buybackToken), msg.sender, balance);
        }
    }

    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return _tokenAddress != address(buybackToken);
    }

    function _buybackForToken(address _tokenAddress) private {
        uint256 tokenAmount = tokenBalance(_tokenAddress);

        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = address(buybackToken);

        uint256[] memory amounts = swapRouter.getAmountsOut(tokenAmount, path);
        uint256 amountOutMin = (amounts[1] * (MILLIPERCENT_FACTOR - swapTolerance)) /
            MILLIPERCENT_FACTOR;

        swapRouter.swapExactTokensForTokens(
            tokenAmount,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 1 minutes
        );
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress = _ownerAddress == address(0) ? msg.sender : _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

interface IAssetReceiver {
    function receiveAsset(address _tokenAddress, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ITokenBalance } from './ITokenBalance.sol';

interface IBuybackToken is ITokenBalance {
    function burn(uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

interface ISwapRouter {
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn, // Amount of tokens we are sending in
        uint256 amountOutMin, // The minimum amount of tokens we want out of the trade
        address[] calldata path, // List of token addresses we are going to trade in
        address to, // The address we are going to send the output tokens to
        uint256 deadline // The last time that the trade is valid for
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { Ownable } from './Ownable.sol';
import { DataStructures } from './DataStructures.sol';

abstract contract ManagerRole is Ownable, DataStructures {
    error OnlyManagerError();

    address[] public managerList;
    mapping(address => OptionalValue) public managerIndexMap;

    event SetManager(address indexed account, bool indexed value);

    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public virtual onlyOwner {
        _setManager(_account, _value);
    }

    function renounceManagerRole() public virtual onlyManager {
        _setManager(msg.sender, false);
    }

    function isManager(address _account) public view virtual returns (bool) {
        return managerIndexMap[_account].isSet;
    }

    function managerCount() public view virtual returns (uint256) {
        return managerList.length;
    }

    function _setManager(address _account, bool _value) private {
        uniqueAddressListUpdate(managerList, managerIndexMap, _account, _value);

        emit SetManager(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

abstract contract NativeTokenAddress {
    address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import { ZeroAddressError } from './Errors.sol';

abstract contract Ownable {
    error OnlyOwnerError();

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerError();
        }

        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddressError();
        }

        address previousOwner = owner;
        owner = newOwner;

        emit OwnershipTransferred(previousOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

abstract contract SafeTransfer {
    error SafeApproveError();
    error SafeTransferError();
    error SafeTransferFromError();
    error SafeTransferNativeError();

    function safeApprove(address _token, address _to, uint256 _value) internal {
        // 0x095ea7b3 is the selector for "approve(address,uint256)"
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x095ea7b3, _to, _value)
        );

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeApproveError();
        }
    }

    function safeTransfer(address _token, address _to, uint256 _value) internal {
        // 0xa9059cbb is the selector for "transfer(address,uint256)"
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferError();
        }
    }

    function safeTransferFrom(address _token, address _from, address _to, uint256 _value) internal {
        // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
        );

        bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

        if (!condition) {
            revert SafeTransferFromError();
        }
    }

    function safeTransferNative(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{ value: _value }(new bytes(0));

        if (!success) {
            revert SafeTransferNativeError();
        }
    }

    function safeTransferNativeUnchecked(address _to, uint256 _value) internal {
        (bool ignore, ) = _to.call{ value: _value }(new bytes(0));

        ignore;
    }
}