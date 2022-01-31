// SPDX-License-Identifier: MIT
// NovaSwap™, by Nova Network Inc.
// https://www.novanetwork.io/

pragma solidity ^0.8.0;

import './ReentrancyGuard.sol';


// transfer helper library
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// WETH interface
interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// ERC-20 Interface
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// NovaSwap Router Interface
interface NovaSwapRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(

        // Amount of tokens being sent.
        uint256 amountIn,
        // Minimum amount of tokens coming out of the transaction.
        uint256 amountOutMin,
        // List of token addresses being traded.  This is necessary to calculate quantities.
        address[] calldata path,
        // Address that will receive the output tokens.
        address to,
        // Trade deadline time-out.
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}


// NovaSwap Pair Interface
interface NovaSwapPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}


// NovaSwap Factory Interface
interface NovaSwapFactory {
  function getPair(address token0, address token1) external returns (address);
}


// main contract
contract novaSwapContract is ReentrancyGuard {

    // Set the address of the UniswapV2 router.
    address[] private Routers;

    // Wrapped native token address. This is necessary because sometimes it might be more
    // efficient to trade with the wrapped version of the native token, eg. WRAPPED, WRAPPED, WFTM.
    address private constant WRAPPED = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    address private constant ADMIN_ADDR = 0x499FbD6C82C7C5D42731B3E9C06bEeFdC494C852;

    constructor() {
        Routers.push(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        Routers.push(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);
    }

    function takeTokenFee(address _tokenIn, uint256 amount)  private returns (uint256) {
        // check the amount to send fee
        require(amount >= 100, "No enough amount");

        uint256 feeAmount = amount / 100;

        bool feeSendResult = IERC20(_tokenIn).transfer(ADMIN_ADDR, feeAmount);

        if (feeSendResult) {
            return feeAmount;
        } else {
            return 0;
        }
    }


    // This swap function is used to trade from one token to another.
    // The inputs are self explainatory.
    // tokenIn = the token address you want to trade out of.
    // tokenOut = the token address you want as the output of this trade.
    // amountIn = the amount of tokens you are sending in.
    // amountOutMin = the minimum amount of tokens you want out of the trade.
    // to = the address you want the tokens to be sent to.
    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    )
        nonReentrant
        external
    {
        // require(_amountIn >= 100, "No enough amount");
        // First we need to transfer the amount in tokens from the msg.sender to this contract.
        // This contract will then have the amount of in tokens to be traded.
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);

        // Next we need to allow the Uniswap V2 router to spend the token we just sent to this contract.
        // By calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract.
        
        // send fee
        uint fee = takeTokenFee(_tokenIn, _amountIn);

        uint256 amountIn = _amountIn - fee;

        // // Path is an array of addresses.
        // // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
        // // The 'if' statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
        address[] memory path;
        address properRouter;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
        }

        // select router
        uint256 amount = 0;
        for (uint i = 0; i < Routers.length; i++) {
            address router = Routers[i];
            uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(amountIn, path);
            if (amountOutMins[path.length -1] > amount) {
                amount = amountOutMins[path.length -1];
                properRouter = router;
            }
        }

        // approve tokens to router contract address
        TransferHelper.safeApprove(_tokenIn, properRouter, amountIn);

        // // // Then, we will call swapExactTokensForTokens.
        // // // For the deadline we will pass in block.timestamp.
        // // // The deadline is the latest time the trade is valid for.
        NovaSwapRouter(properRouter).swapExactTokensForTokens(amountIn, _amountOutMin, path, _to, block.timestamp);
    }

    // This function is used to swap tokens to eth
    function swapExactTokensForETH(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _tokenIn,
        address _to
    )
        nonReentrant
        external
    {
        // send token from user to contract
        TransferHelper.safeTransferFrom(_tokenIn, msg.sender, address(this), _amountIn);

        // send fee to admin
        uint fee = takeTokenFee(_tokenIn, _amountIn);

        uint256 amountIn = _amountIn - fee;

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = WRAPPED;
        address properRouter;

        // select router
        uint256 amount = 0;
        for (uint i = 0; i < Routers.length; i++) {
            address router = Routers[i];
            uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(amountIn, path);
            if (amountOutMins[path.length -1] > amount) {
                amount = amountOutMins[path.length -1];
                properRouter = router;
            }
        }

        // approve to router
        TransferHelper.safeApprove(_tokenIn, properRouter, amountIn);

        // call swap
        NovaSwapRouter(properRouter).swapExactTokensForETH(amountIn, _amountOutMin, path, _to, block.timestamp);
    }

    function swapExactETHForTokens(
        uint256 _amountOutMin,
        address _tokenOut,
        address _to
    )
        nonReentrant
        payable
        external
    {
        uint256 _amountIn = msg.value;
        require(_amountIn >= 100, "No enough amount");

        // calculate fee
        uint256 feeAmount = _amountIn / 100;

        // send fee to amdin
        TransferHelper.safeTransferETH(ADMIN_ADDR, feeAmount);

        address properRouter;
        address[] memory path;
        path = new address[](2);
        path[0] = WRAPPED;
        path[1] = _tokenOut;

        // select router
        uint256 amount = 0;
        for (uint i = 0; i < Routers.length; i++) {
            address router = Routers[i];
            uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(_amountIn - feeAmount, path);
            if (amountOutMins[path.length -1] > amount) {
                amount = amountOutMins[path.length -1];
                properRouter = router;
            }
        }

        // call swap
        NovaSwapRouter(properRouter).swapExactETHForTokens{ value: _amountIn- feeAmount }(_amountOutMin, path, _to, block.timestamp);
    }

    // This function will return the minimum amount from a swap.
    // Input the 3 parameters below and it will return the minimum amount out.
    // This is needed for the swap function above.
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        address[] memory path;
        if (_tokenIn == WRAPPED || _tokenOut == WRAPPED) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WRAPPED;
            path[2] = _tokenOut;
        }
        uint256 amount = 0;
        for (uint i = 0; i < Routers.length; i++) {
            address router = Routers[i];
            // Path is an array of addresses.
            // This path array will have 3 addresses [tokenIn, WRAPPED, tokenOut].
            // The if statement below takes into account if token in or token out is WRAPPED,  then the path has only 2 addresses.
            uint256[] memory amountOutMins = NovaSwapRouter(router).getAmountsOut(_amountIn, path);
            if (amountOutMins[path.length -1] > amount) amount = amountOutMins[path.length -1];
        }

        return amount;
    }
}