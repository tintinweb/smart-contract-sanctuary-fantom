/**
 *Submitted for verification at FtmScan.com on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

interface ISwapper {
  function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn) external view returns (uint256 amountOut);
  function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn) external returns (uint256 amountOut);
}

/// @title Swapper
/// @notice Abstract base contract for deploying wrappers for AMMs
/// @dev
abstract contract Swapper is ISwapper {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Bytes32AddressLib for bytes32;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @notice Emitted when a new swap has been executed
    /// @param from The base asset
    /// @param to The quote asset
    /// @param amountIn amount that has been swapped
    /// @param amountOut received amount
    event Swap(address indexed sender, IERC20 indexed from, IERC20 indexed to, uint256 amountIn, uint256 amountOut);

    function previewSwap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn) public virtual view returns (uint256 amountOut) {
        bytes memory payload = _buildPayload(assetFrom, assetTo);

        amountOut = _previewSwap(amountIn, payload);
    }

    function swap(IERC20 assetFrom, IERC20 assetTo, uint256 amountIn) public virtual returns (uint256 amountOut) {
        bytes memory payload = _buildPayload(assetFrom, assetTo);

        // 10% slippage
        uint256 minAmountOut = previewSwap(assetFrom, assetTo, amountIn) * 90 / 100; 
        amountOut = _swap(amountIn, minAmountOut, payload);

        emit Swap(msg.sender, assetFrom, assetTo, amountIn, amountOut);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------
    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal virtual view returns (bytes memory path);

    function _previewSwap(uint256 amountIn, bytes memory payload) internal virtual view returns (uint256 amountOut);

    function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload) internal virtual returns (uint256 amountOut);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

/// Spooky Swap Swapper
contract SpookySwapper is Swapper {
    IUniswapV2Router01 public immutable swapRouter;

    constructor(IUniswapV2Router01 swapRouter_) Swapper() {
        swapRouter = swapRouter_;
    }

    function _previewSwap(uint256 amountIn, bytes memory payload) internal view override returns (uint256) {
        address[] memory path = abi.decode(payload, (address[]));
        uint256[] memory amountsOut = swapRouter.getAmountsOut(amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    function _swap(uint256 amountIn, uint256 minAmountOut, bytes memory payload) internal override returns (uint256 amountOut) {
        address[] memory path = abi.decode(payload, (address[]));

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

        TransferHelper.safeApprove(path[0], address(swapRouter), amountIn);

        uint256[] memory amountsOut = swapRouter.swapExactTokensForTokens(
          amountIn,
          minAmountOut,
          path,
          msg.sender,
          block.timestamp
        );

        amountOut = amountsOut[amountsOut.length - 1];
    }

    function _buildPayload(IERC20 assetFrom, IERC20 assetTo) internal view override returns (bytes memory path) {
        path = abi.encodePacked(address(assetFrom), address(assetTo));
    }
}