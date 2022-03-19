/**
 *Submitted for verification at FtmScan.com on 2022-03-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

pragma solidity ^0.8.0;


contract DEXTax {

    address beneficiary;
    address public immutable WETH;
    address public immutable yoshiExchange;

    constructor (address _beneficiary, address _WETH, address _yoshiExchange) payable
    {
        beneficiary = _beneficiary;
        WETH = _WETH;
        yoshiExchange = _yoshiExchange;
    }

    receive() external payable {}

    modifier onlyBeneficiary() {
        require(beneficiary == msg.sender, "Ownable: caller is not the beneficiary");
        _;
    }

    function setBeneficiary(address _beneficiary) public onlyBeneficiary {
        beneficiary = _beneficiary;
    }

    function Fee(uint amountIn) internal pure returns (uint fee)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        fee = amountIn * 15 / 10000;

        require(fee > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    }

    function amountMFee(uint amountIn) internal pure returns (uint amountOut)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        amountOut = amountIn - Fee(amountIn);

        require(amountOut > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    }

    function amountPFee(uint amountIn) internal pure returns (uint amountOut)
    {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');

        amountOut = amountIn + Fee(amountIn);

        require(amountOut > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    }

    function safeTransfer(address to, uint256 value) internal
    {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function getAmountsOut(address router, uint amountIn, address[] memory path)
    external view returns (uint[] memory amounts)
    {
        amounts = IUniswapV2Router02(router).getAmountsOut(amountMFee(amountIn), path);

        amounts[amounts.length - 1] = amountMFee(amounts[amounts.length - 1]);
    }

    function getAmountsIn(address router, uint amountOut, address[] memory path)
    external view returns (uint[] memory amounts)
    {
        amounts = IUniswapV2Router02(router).getAmountsIn(amountPFee(amountOut), path);

        amounts[0] = amountPFee(amounts[0]);
    }

    function sendFTM(address to, uint amount) external payable onlyBeneficiary
    {
        (bool success,) = to.call{value : amount}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    function send(address token, address to, uint amount) public onlyBeneficiary
    {
        IERC20(token).transfer(to, amount);
    }

    function approve(address token, address spender, uint amount) internal
    {
        uint256 allowed = IERC20(token).allowance(msg.sender, spender);
        if (allowed < amount)
        {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function swapExactTokensForTokens(address router, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts)
    {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint amount = amountMFee(amountIn);

        approve(path[0], router, amount);
        amounts = IUniswapV2Router02(router).swapExactTokensForTokens(amount, amountPFee(amountOutMin), path, address(this), deadline);

        address token0 = path[0];
        address token1 = path[path.length - 1];

        IERC20(token1).transfer(to, amountMFee(amounts[amounts.length - 1]));

        uint token0amount = IERC20(token0).balanceOf(address(this));
        uint token1amount = IERC20(token1).balanceOf(address(this));

        approve(token0, yoshiExchange, token0amount);
        approve(token1, yoshiExchange, token1amount);
        IUniswapV2Router02(yoshiExchange).addLiquidity(token0, token1, token0amount, token1amount, 0, 0, beneficiary, deadline);
    }

    function swapTokensForExactTokens(address router, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external returns (uint[] memory amounts)
    {
        amounts = IUniswapV2Router02(router).getAmountsIn(amountPFee(amountOut), path);
        uint amount = amountPFee(amounts[0]);
		require(amount <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IERC20(path[0]).transferFrom(msg.sender, address(this), amount);

        approve(path[0], router, amounts[0]);
        amounts = IUniswapV2Router02(router).swapTokensForExactTokens(amountPFee(amountOut), amounts[0], path, address(this), deadline);

        address token0 = path[0];
        address token1 = path[path.length - 1];

        IERC20(token1).transfer(to, amountOut);

        uint token0amount = IERC20(token0).balanceOf(address(this));
        uint token1amount = IERC20(token1).balanceOf(address(this));

        approve(token0, yoshiExchange, token0amount);
        approve(token1, yoshiExchange, token1amount);
        IUniswapV2Router02(yoshiExchange).addLiquidity(token0, token1, token0amount, token1amount, 0, 0, beneficiary, deadline);
    }

    function swapExactETHForTokens(address router, uint amountOutMin, address[] calldata path, address to, uint deadline)
    public payable returns (uint[] memory amounts)
    {
        uint amount = amountMFee(msg.value);

        amounts = IUniswapV2Router02(router).swapExactETHForTokens{value : amount}(amountPFee(amountOutMin), path, address(this), deadline);

        address token1 = path[path.length - 1];

        IERC20(token1).transfer(to, amountMFee(amounts[amounts.length - 1]));

        uint token1amount = IERC20(token1).balanceOf(address(this));

        approve(token1, yoshiExchange, token1amount);
        IUniswapV2Router02(yoshiExchange).addLiquidityETH{value : address(this).balance}(token1, token1amount, 0, 0, beneficiary, deadline);
    }

    function swapTokensForExactETH(address router, uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    public payable returns (uint[] memory amounts)
    {
        amounts = IUniswapV2Router02(router).getAmountsIn(amountPFee(amountOut), path);
        uint amount = amountPFee(amounts[0]);
		require(amount <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IERC20(path[0]).transferFrom(msg.sender, address(this), amount);

        approve(path[0], router, amounts[0]);
        amounts = IUniswapV2Router02(router).swapTokensForExactETH(amountPFee(amountOut), amounts[0], path, address(this), deadline);

        safeTransfer(to, amountOut);

        uint token0amount = IERC20(path[0]).balanceOf(address(this));

        approve(path[0], yoshiExchange, token0amount);
        IUniswapV2Router02(yoshiExchange).addLiquidityETH{value : address(this).balance}(path[0], token0amount, 0, 0, beneficiary, deadline);
    }

    function swapExactTokensForETH(address router, uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    public returns (uint[] memory amounts)
    {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint amount = amountMFee(amountIn);

        approve(path[0], router, amount);
        amounts = IUniswapV2Router02(router).swapExactTokensForETH(amount, amountPFee(amountOutMin), path, address(this), deadline);

        safeTransfer(to, amountMFee(amounts[amounts.length - 1]));

        uint token0amount = IERC20(path[0]).balanceOf(address(this));

        approve(path[0], yoshiExchange, token0amount);
        IUniswapV2Router02(yoshiExchange).addLiquidityETH{value : address(this).balance}(path[0], token0amount, 0, 0, beneficiary, deadline);
    }

    function swapETHForExactTokens(address router, uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts)
    {
        uint amount = IUniswapV2Router02(router).getAmountsIn(amountPFee(amountOut), path)[0];

        amounts = IUniswapV2Router02(router).swapETHForExactTokens{value : amount}(amountPFee(amountOut), path, address(this), deadline);

        address token1 = path[path.length - 1];

        IERC20(token1).transfer(to, amountOut);

        if (msg.value > amountPFee(amounts[0]))
        {
            safeTransfer(msg.sender, msg.value - amountPFee(amounts[0]));
        }

        uint token1amount = IERC20(token1).balanceOf(address(this));

        approve(token1, yoshiExchange, token1amount);
        IUniswapV2Router02(yoshiExchange).addLiquidityETH{value : address(this).balance}(token1, token1amount, 0, 0, beneficiary, deadline);
    }
}