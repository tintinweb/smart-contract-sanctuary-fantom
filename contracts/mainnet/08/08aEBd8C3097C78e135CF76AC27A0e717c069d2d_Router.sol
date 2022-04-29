//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./dexs/IDEX.sol";
import "./bridge/IBridge.sol";

contract Router is Ownable {
    address private relayerAddress;
    mapping(uint8 => IBridge) private bridgeProviders;
    mapping(uint8 => IDEX) private swapProviders;

    enum dexCode {
        Uniswap, // 0
        ZeroEx // 1
    }

    enum bridgeCode {
        Anyswap // 0
    }

    /**
     * @dev Throws if called by any account other than the relayer.
     */
    modifier onlyRelayer() {
        require(relayerAddress == _msgSender(), "Caller is not the relayer");
        _;
    }

    /**
     * @dev Updates the address of a bridge provider contract
     */
    function updateBridgeProvider(bridgeCode _code, address _address) external onlyOwner {
        uint8 code = uint8(_code);
        bridgeProviders[code] = IBridge(_address);
        emit UpdatedBridgeProvider(code, _address);
    }

    /**
     * @dev Updates the address of a swap provider contract
     */
    function updateSwapProvider(dexCode _code, address _address) external onlyOwner {
        uint8 code = uint8(_code);
        swapProviders[code] = IDEX(_address);
        emit UpdatedSwapProvider(code, _address);
    }

    /**
     * @dev Updates the address of the authorized relayer
     */
    function updateRelayer(address _relayerAddress) external onlyOwner {
        address oldAddress = relayerAddress;
        relayerAddress = _relayerAddress;
        emit UpdatedRelayer(oldAddress, relayerAddress);
    }

    /**
     * @dev Emitted when a bridge provider address is updated
     */
    event UpdatedBridgeProvider(
        uint8 code,
        address provAddress
    );

    /**
     * @dev Emitted when a swap provider address is updated
     */
    event UpdatedSwapProvider(
        uint8 code,
        address provAddress
    );

    /**
     * @dev Emitted when the relayer address is updated
     */
    event UpdatedRelayer(
        address oldAddress,
        address newAddress
    );

    /**
     * @dev Emitted when a multi-chain swap is initiated
     */
    event CrossInitiated(
        bytes txUuid,
        uint256 amountOut
    );

    /**
     * @dev Emitted when a multi-chain swap is finalized
     */
    event CrossFinalized(
        bytes txUuid,
        uint256 amountOut
    );

    /**
     * @dev Emitted when a single-chain swap is completed
     */
    event SwapExecuted(
        bytes txUuid,
        uint256 amountOut
    );

    /**
     * @dev Defines the details for the swap step
     */
    struct SwapData {
        uint8 providerCode;
        address tokenIn;
        address tokenOut;
        bytes data;
        bool required;
    }

    /**
     * @dev Defines the details for the bridge step
     */
    struct BridgeData {
        address tokenIn;
        uint256 toChainId;
        bytes data;
        bool required;
    }

    /**
     * Init the process of swidging
     * @dev This function is executed on the origin chain
     */
    function initTokensCross(
        uint256 _amount,
        SwapData calldata _swapData,
        BridgeData calldata _bridgeData,
        bytes calldata _txUuid
    ) external payable {
        // We need either the swap or the bridge step to be required
        require(_swapData.required || _bridgeData.required, "No required actions");

        address tokenToTakeIn;
        // Need to check which token is going to be taken as input
        if (_swapData.required) {
            tokenToTakeIn = _swapData.tokenIn;
        }
        else {
            tokenToTakeIn = _bridgeData.tokenIn;
        }

        // Take ownership of user's tokens
        TransferHelper.safeTransferFrom(
            tokenToTakeIn,
            msg.sender,
            address(this),
            _amount
        );

        uint256 finalAmount;
        // Store the amount for the next step
        // depending on the step to take
        if (_swapData.required) {
            IDEX swapper = swapProviders[_swapData.providerCode];

            // Approve swapper contract
            TransferHelper.safeApprove(
                _swapData.tokenIn,
                address(swapper),
                _amount
            );

            // Execute the swap
            finalAmount = swapper.swap{value : msg.value}(
                _swapData.tokenIn,
                _swapData.tokenOut,
                address(this),
                _amount,
                _swapData.data
            );
        }
        else {
            // If swap is not required the amount going
            // to the bridge is the same that came in
            finalAmount = _amount;
        }

        if (_bridgeData.required) {
            // Load selected bridge provider
            IBridge bridge = bridgeProviders[uint8(bridgeCode.Anyswap)];

            // Approve tokens for the bridge to take
            TransferHelper.safeApprove(
                _bridgeData.tokenIn,
                address(bridge),
                finalAmount
            );

            // Execute bridge process
            bridge.send(
                _bridgeData.tokenIn,
                address(this),
                finalAmount,
                _bridgeData.toChainId,
                _bridgeData.data
            );

            // Emit event for relayer
            emit CrossInitiated(_txUuid, finalAmount);
        }
        else {
            // Bridging is not required, means we are not changing network
            // so we send the assets back to the user
            TransferHelper.safeTransfer(_swapData.tokenOut, msg.sender, finalAmount);
            emit SwapExecuted(_txUuid, finalAmount);
        }
    }


    /**
     * Finalize the process of swidging
     * @dev This function is executed on the destination chain
     */
    function finalizeTokenCross(
        uint256 _amount,
        address _receiver,
        SwapData calldata _swapData,
        bytes calldata _txUuid
    ) external payable onlyRelayer {
        IDEX swapper = swapProviders[_swapData.providerCode];

        // Approve swapper contract
        TransferHelper.safeApprove(
            _swapData.tokenIn,
            address(swapper),
            _amount
        );

        // Execute swap with ZeroEx and compute final `boughtAmount`
        uint256 boughtAmount = swapper.swap(
            _swapData.tokenIn,
            _swapData.tokenOut,
            address(this),
            _amount,
            _swapData.data
        );

        // Send tokens to the user
        TransferHelper.safeTransfer(
            _swapData.tokenOut,
            _receiver,
            boughtAmount
        );

        emit CrossFinalized(_txUuid, boughtAmount);
    }

    /// To retrieve any tokens that got stuck on the contract
    function retrieve(address _token, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(_token, msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
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
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../Provider.sol";

abstract contract IDEX is Provider {
    function swap(
        address _tokenIn,
        address _tokenOut,
        address _router,
        uint256 _amountIn,
        bytes calldata _data
    ) external payable virtual returns (uint256 amountOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Provider.sol";

abstract contract IBridge is Provider {
    function send(
        address _token,
        address _router,
        uint256 _amount,
        uint256 _toChainId,
        bytes calldata _data
    ) external virtual;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

abstract contract Provider is Ownable {
    address private router;

    modifier onlyRouter() {
        require(msg.sender == router, "Unauthorized caller");
        _;
    }

    event UpdatedRouter(address indexed routerAddress);

    function updateRouter(address _routerAddress) external onlyOwner {
        router = _routerAddress;
        emit UpdatedRouter(_routerAddress);
    }

    function retrieve(address _token, uint256 _amount) external onlyOwner {
        TransferHelper.safeTransfer(_token, msg.sender, _amount);
    }
}