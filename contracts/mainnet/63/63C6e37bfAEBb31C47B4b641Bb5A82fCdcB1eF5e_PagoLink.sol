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

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";

contract PagoLink is Ownable {
    uint256 public slippage;
    address public swapRouterAddress;
    address public stableCoinAddress;

    event PaymentSuccessful(
        string indexed paymentId,
        address indexed payer,
        string indexed merchant,
        uint256 amount,
        address token
    );
    event routerUpdated(
        address proviousRouterAddress,
        address newRouterAddress
    );
    event stableCoinUpdated(
        address proviousStableCoinAddress,
        address newStableCoinAddress
    );
    event slippageUpdated(
        uint256 previousSlippageAddress,
        uint256 newSlippageAddress
    );
    event Withdraw(address indexed recipient, uint256 amount);

    constructor(
        address _stableCoinAddress,
        address _swapRouterAddress,
        uint256 _slippage
    ) {
        stableCoinAddress = _stableCoinAddress;
        swapRouterAddress = _swapRouterAddress;
        slippage = _slippage;
    }

    function makePayment(
        address _tokenAddress,
        uint256 _amount,
        string memory _merchant,
        string memory _paymentId
    ) public payable {
        address[] memory _path;
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = stableCoinAddress;
        uint256 _tokenAmount;

        require(_amount > 0, "Invalid payment amount");

        if (_tokenAddress != stableCoinAddress && _tokenAddress != address(0)) {
            // Get the amount of token to swap
            _tokenAmount = requiredTokenAmount(_amount, _tokenAddress);

            TransferHelper.safeTransferFrom(
                _tokenAddress,
                msg.sender,
                address(this),
                _tokenAmount
            );

            // Swap to stableCoin
            _swap(_tokenAmount, _amount, _path);
        } else if (_tokenAddress == stableCoinAddress) {
            TransferHelper.safeTransferFrom(
                _tokenAddress,
                msg.sender,
                address(this),
                _amount
            );
        } else {
            _path[0] = IUniswapV2Router02(swapRouterAddress).WETH();
            _tokenAmount = requiredTokenAmount(
                _amount,
                IUniswapV2Router02(swapRouterAddress).WETH()
            );
            require(msg.value >= _tokenAmount, "Insufficient amount!");
            IUniswapV2Router02(swapRouterAddress).swapETHForExactTokens{
                value: _tokenAmount
            }(_amount, _path, address(this), block.timestamp);
        }

        TransferHelper.safeTransfer(stableCoinAddress, owner(), _amount);

        emit PaymentSuccessful(
            _paymentId,
            msg.sender,
            _merchant,
            _amount,
            _tokenAddress
        );
    }

    function updateRouter(address _routerAddress) external onlyOwner {
        address _previousRouterAddress = swapRouterAddress;
        swapRouterAddress = _routerAddress;
        emit routerUpdated(_previousRouterAddress, _routerAddress);
    }

    function updateStableCoin(address _stableCoinAddress) external onlyOwner {
        address _previousStableCoinAddress = stableCoinAddress;
        stableCoinAddress = _stableCoinAddress;
        emit stableCoinUpdated(_previousStableCoinAddress, _stableCoinAddress);
    }

    function updateSlippage(uint256 _slippage) external onlyOwner {
        uint256 _previousSlippage = slippage;
        slippage = _slippage;
        emit slippageUpdated(_previousSlippage, _slippage);
    }

    function withdraw() external onlyOwner {
        uint256 _stableCoinBalance = IERC20(stableCoinAddress).balanceOf(
            address(this)
        );
        uint256 _ethBalance = address(this).balance;
        TransferHelper.safeTransfer(
            stableCoinAddress,
            msg.sender,
            _stableCoinBalance
        );
        payable(msg.sender).transfer(_ethBalance);
        emit Withdraw(msg.sender, _stableCoinBalance);
        emit Withdraw(msg.sender, _ethBalance);
    }

    // Get the required amount of token for a swap
    function requiredTokenAmount(
        uint256 _amountInUSD,
        address _token
    ) public view returns (uint256 _tokenAmount) {
        address[] memory _path;
        _path = new address[](2);
        _path[0] = _token;
        _path[1] = stableCoinAddress;
        uint256[] memory _tokenAmounts = IUniswapV2Router02(swapRouterAddress)
            .getAmountsIn(_amountInUSD, _path);
        _tokenAmount = _tokenAmounts[0] + ((_tokenAmounts[0] * slippage) / 100);
    }

    // Swap from tokens to a stablecoin
    function _swap(
        uint256 _tokenAmount,
        uint256 _amount,
        address[] memory _path
    ) internal returns (uint256[] memory _amountOut) {
        // Approve the router to swap token.
        TransferHelper.safeApprove(_path[0], swapRouterAddress, _tokenAmount);
        _amountOut = IUniswapV2Router02(swapRouterAddress)
            .swapTokensForExactTokens(
                _amount,
                _tokenAmount,
                _path,
                owner(),
                block.timestamp
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}