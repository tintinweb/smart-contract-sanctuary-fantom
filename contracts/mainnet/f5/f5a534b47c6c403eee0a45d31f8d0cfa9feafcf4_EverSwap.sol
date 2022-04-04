/**
 *Submitted for verification at FtmScan.com on 2022-04-04
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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


interface IHyperswapRouter01 {
    function factory() external pure returns (address);
    function WFTM() external pure returns (address);

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
    function addLiquidityFTM(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountFTM, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityFTM(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountFTM);
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
    function removeLiquidityFTMWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFTM);
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
    function swapExactFTMForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactFTM(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapFTMForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IHyperswapRouter02 is IHyperswapRouter01 {
    function removeLiquidityFTMSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external returns (uint amountFTM);
    function removeLiquidityFTMWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountFTM);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactFTMForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForFTMSupportingFeeOnTransferTokens(
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

interface IDEXTax {
    struct RouteItem
    {
        address router;
        address[] path;
    }

    function getAmountsIn(RouteItem[] calldata route, uint amountOut) external returns (uint[] memory values);
    function getAmountsOut(RouteItem[] calldata route, uint amountIn) external returns (uint[] memory values);
    function swapETHForExactTokens(RouteItem[] calldata route, uint amountOut, address to, uint deadline)
    external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(RouteItem[] calldata route, uint amountOutMin, address to, uint deadline)
    external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline)
    external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline)
    external returns (uint[] memory amounts);
    function swapExactTokensForTokens(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline)
    external returns (uint[] memory amounts);
    function swapTokensForExactTokens(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline)
    external returns (uint[] memory amounts);
}

contract DEXTax is IDEXTax {

    address beneficiary;
    address public immutable WETH;
    address public immutable yoshiRouter;
	address public immutable yoshiFactory;
	address constant HYPERSWAP_ROUTER = 0x53c153a0df7E050BbEFbb70eE9632061f12795fB;

    constructor (address _beneficiary, address _WETH, address _yoshiRouter, address _yoshiFactory) payable
    {
        beneficiary = _beneficiary;
        WETH = _WETH;
        yoshiRouter = _yoshiRouter;
		yoshiFactory = _yoshiFactory;
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


    function getAmountsOut(RouteItem[] calldata route, uint amountIn) override
    external view returns (uint[] memory values)
    {
		uint length = 0;
		uint counter = 0;
		for (uint i = 0; i < route.length; i++)
		{
			length += route[i].path.length;
		}

		values = new uint[](length);
		uint amount = amountMFee(amountIn);

		for (uint i = 0; i < route.length; i++)
		{
			uint[] memory amounts = IUniswapV2Router02(route[i].router).getAmountsOut(amount, route[i].path);
			amount = amounts[amounts.length - 1];

			for (uint j = 0; j < route[i].path.length; j++)
			{
				values[counter++] = amounts[j];
			}
		}

        values[values.length - 1] = amountMFee(values[values.length - 1]);
    }

    function getAmountsIn(RouteItem[] calldata route, uint amountOut) override
    external view returns (uint[] memory values)
    {
		uint length = 0;
		uint counter = 0;
		for (uint i = 0; i < route.length; i++)
		{
			length += route[i].path.length;
		}

		values = new uint[](length);
		uint amount = amountPFee(amountOut);

		for (uint i = route.length; i > 0; i--)
		{
			uint[] memory amounts = IUniswapV2Router02(route[i - 1].router).getAmountsIn(amount, route[i - 1].path);
			amount = amounts[0];

			for (uint j = route[i - 1].path.length; j > 0; j--)
			{
				values[counter++] = amounts[j - 1];
			}
		}

        values[values.length - 1] = amountPFee(values[values.length - 1]);
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
        uint256 allowed = IERC20(token).allowance(address(this), spender);
        if (allowed < amount)
        {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

	function takeFee(address token0, address token1) internal
	{
	    uint token0amount = IERC20(token0).balanceOf(address(this));
        uint token1amount = IERC20(token1).balanceOf(address(this));

	    if (IUniswapV2Factory(yoshiFactory).getPair(token0, token1) == address(0))
		{
            IERC20(token0).transfer(beneficiary, token0amount);
			IERC20(token1).transfer(beneficiary, token1amount);
        }
		else
		{
			approve(token0, yoshiRouter, token0amount);
			approve(token1, yoshiRouter, token1amount);
			IUniswapV2Router02(yoshiRouter).addLiquidity(token0, token1, token0amount, token1amount, 0, 0, beneficiary, block.timestamp);
		}
	}

	function takeFeeETH(address token) internal
	{
	    uint tokenAmount = IERC20(token).balanceOf(address(this));

	    if (IUniswapV2Factory(yoshiFactory).getPair(token, WETH) == address(0))
		{
            IERC20(token).transfer(beneficiary, tokenAmount);

			(bool success,) = beneficiary.call{value : address(this).balance}(new bytes(0));
			require(success, 'ETH_TRANSFER_FAILED');
        }
        else
        {
            approve(token, yoshiRouter, tokenAmount);
            IUniswapV2Router02(yoshiRouter).addLiquidityETH{value : address(this).balance}(token, tokenAmount, 0, 0, beneficiary, block.timestamp);
        }
    }

    function doSwapExactETHForTokens(RouteItem calldata routeItem, uint amountIn, uint amountOutMin, uint deadline)
    internal returns (uint[] memory amounts)
    {
        if (routeItem.router == HYPERSWAP_ROUTER)
        {
            amounts = IHyperswapRouter02(routeItem.router).swapExactFTMForTokens{value : amountIn}(amountOutMin, routeItem.path, address(this), deadline);
        }
        else
        {
            amounts = IUniswapV2Router02(routeItem.router).swapExactETHForTokens{value : amountIn}(amountOutMin, routeItem.path, address(this), deadline);
        }
    }

    function doSwapTokensForExactETH(RouteItem calldata routeItem, uint amountOut, uint amountInMax, uint deadline)
    internal returns (uint[] memory amounts)
    {
        if (routeItem.router == HYPERSWAP_ROUTER)
        {
            amounts = IHyperswapRouter02(routeItem.router).swapTokensForExactFTM(amountOut, amountInMax, routeItem.path, address(this), deadline);
        }
        else
        {
            amounts = IUniswapV2Router02(routeItem.router).swapTokensForExactETH(amountOut, amountInMax, routeItem.path, address(this), deadline);
        }
    }

    function doSwapExactTokensForETH(RouteItem calldata routeItem, uint amountIn, uint amountOutMin, uint deadline)
    internal returns (uint[] memory amounts)
    {
        if (routeItem.router == HYPERSWAP_ROUTER)
        {
            amounts = IHyperswapRouter02(routeItem.router).swapExactTokensForFTM(amountIn, amountOutMin, routeItem.path, address(this), deadline);
        }
        else
        {
            amounts = IUniswapV2Router02(routeItem.router).swapExactTokensForETH(amountIn, amountOutMin, routeItem.path, address(this), deadline);
        }
    }

    function doSwapETHForExactTokens(RouteItem calldata routeItem, uint amountIn, uint amountOut, uint deadline)
    internal returns (uint[] memory amounts)
    {
        if (routeItem.router == HYPERSWAP_ROUTER)
        {
            amounts = IHyperswapRouter02(routeItem.router).swapFTMForExactTokens{value : amountIn}(amountOut, routeItem.path, address(this), deadline);
        }
        else
        {
            amounts = IUniswapV2Router02(routeItem.router).swapETHForExactTokens{value : amountIn}(amountOut, routeItem.path, address(this), deadline);
        }
    }

    function swapExactTokensForTokens(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline) override
    external returns (uint[] memory amounts)
    {
        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint amount = amountMFee(amountIn);

        for (uint i = 0; i < route.length; i++)
        {
            approve(route[i].path[0], route[i].router, amount);
            uint amountOut = i == (route.length - 1) ? amountPFee(amountOutMin) : 0;
            amounts = IUniswapV2Router02(route[i].router).swapExactTokensForTokens(amount, amountOut, route[i].path, address(this), deadline);
            amount = amounts[amounts.length - 1];
        }

        address token1 = route[route.length - 1].path[route[route.length - 1].path.length - 1];

        IERC20(token1).transfer(to, amountMFee(amounts[amounts.length - 1]));

        takeFee(route[0].path[0], token1);
    }

    function swapTokensForExactTokens(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline) override
    external returns (uint[] memory amounts)
    {
        uint[][] memory values = new uint[][](route.length);
        uint amount = amountPFee(amountOut);

        for (uint i = route.length; i > 0; i--)
        {
            values[i - 1] = IUniswapV2Router02(route[i - 1].router).getAmountsIn(amount, route[i - 1].path);
            amount = values[i - 1][0];
        }

        amount = amountPFee(values[0][0]);
        require(amount <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amount);

        for (uint i = 0; i < route.length; i++)
        {
            approve(route[i].path[0], route[i].router, values[i][0]);
            amounts = IUniswapV2Router02(route[i].router).swapTokensForExactTokens(values[i][route[i].path.length - 1], values[i][0], route[i].path, address(this), deadline);
        }

        uint last = route[route.length - 1].path.length - 1;
        address token1 = route[route.length - 1].path[last];

        IERC20(token1).transfer(to, amountOut);

        takeFee(route[0].path[0], token1);
    }

    function swapExactETHForTokens(RouteItem[] calldata route, uint amountOutMin, address to, uint deadline) override
    external payable returns (uint[] memory amounts)
    {
        uint amount = amountMFee(msg.value);

        amounts = doSwapExactETHForTokens(route[0], amount, 0, deadline);

        if (route.length > 1)
        {
            amount = amounts[amounts.length - 1];

            for (uint i = 1; i < route.length; i++)
            {
                approve(route[i].path[0], route[i].router, amount);
                uint amountOut = i == (route.length - 1) ? amountPFee(amountOutMin) : 0;
                amounts = IUniswapV2Router02(route[i].router).swapExactTokensForTokens(amount, amountOut, route[i].path, address(this), deadline);
                amount = amounts[amounts.length - 1];
            }
        }

        uint last = route[route.length - 1].path.length - 1;
        address token1 = route[route.length - 1].path[last];

        IERC20(token1).transfer(to, amountMFee(amounts[amounts.length - 1]));

        takeFeeETH(token1);
    }

    function swapTokensForExactETH(RouteItem[] calldata route, uint amountOut, uint amountInMax, address to, uint deadline) override
    external payable returns (uint[] memory amounts)
    {
        uint[][] memory values = new uint[][](route.length);
        uint amount = amountPFee(amountOut);

        for (uint i = route.length; i > 0; i--)
        {
            values[i - 1] = IUniswapV2Router02(route[i - 1].router).getAmountsIn(amount, route[i - 1].path);
            amount = values[i - 1][0];
        }

        amount = amountPFee(values[0][0]);
        require(amount <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amount);

        if (route.length > 1)
        {
            for (uint i = 0; i < route.length - 1; i++)
            {
                approve(route[i].path[0], route[i].router, values[i][0]);
                amounts = IUniswapV2Router02(route[i].router).swapTokensForExactTokens(values[i][route[i].path.length - 1], values[i][0], route[i].path, address(this), deadline);
            }
        }

        approve(route[route.length - 1].path[0], route[route.length - 1].router, values[route.length - 1][0]);

        amounts = doSwapTokensForExactETH(route[route.length - 1], amountPFee(amountOut), values[route.length - 1][0], deadline);

        safeTransfer(to, amountOut);

        takeFeeETH(route[0].path[0]);
    }

    function swapExactTokensForETH(RouteItem[] calldata route, uint amountIn, uint amountOutMin, address to, uint deadline) override
    external returns (uint[] memory amounts)
    {
        IERC20(route[0].path[0]).transferFrom(msg.sender, address(this), amountIn);

        uint amount = amountMFee(amountIn);

        if (route.length > 1)
        {
            for (uint i = 0; i < route.length - 1; i++)
            {
                approve(route[i].path[0], route[i].router, amount);
                amounts = IUniswapV2Router02(route[i].router).swapExactTokensForTokens(amount, 0, route[i].path, address(this), deadline);
                amount = amounts[amounts.length - 1];
            }
        }

        approve(route[route.length - 1].path[0], route[route.length - 1].router, amount);

        amounts = doSwapExactTokensForETH(route[route.length - 1], amount, amountPFee(amountOutMin), deadline);

        safeTransfer(to, amountMFee(amounts[amounts.length - 1]));

        takeFeeETH(route[0].path[0]);
    }

    function swapETHForExactTokens(RouteItem[] calldata route, uint amountOut, address to, uint deadline) override
    external payable returns (uint[] memory amounts)
    {
        uint[][] memory values = new uint[][](route.length);
        uint amount = amountPFee(amountOut);
        uint value;

        for (uint i = route.length; i > 0; i--)
        {
            values[i - 1] = IUniswapV2Router02(route[i - 1].router).getAmountsIn(amount, route[i - 1].path);
            amount = values[i - 1][0];
        }

        amount = amountPFee(values[0][0]);

        amounts = doSwapETHForExactTokens(route[0], amount, values[0][1], deadline);

        value = amounts[0];

        if (route.length > 1)
        {
            for (uint i = 1; i < route.length; i++)
            {
                approve(route[i].path[0], route[i].router, values[i][0]);
                amounts = IUniswapV2Router02(route[i].router).swapTokensForExactTokens(values[i][route[i].path.length - 1], values[i][0], route[i].path, address(this), deadline);
            }
        }

        uint last = route[route.length - 1].path.length - 1;
        address token1 = route[route.length - 1].path[last];

        IERC20(token1).transfer(to, amountOut);

        if (msg.value > amountPFee(value))
        {
            safeTransfer(msg.sender, msg.value - amountPFee(value));
        }

        takeFeeETH(token1);
    }
}



interface IEverscale {
    struct EverscaleAddress {
        int128 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

interface IVaultBasic is IEverscale {
    struct WithdrawalParams {
        EverscaleAddress sender;
        uint256 amount;
        address recipient;
        uint32 chainId;
    }

    function bridge() external view returns (address);
    function configuration() external view returns (EverscaleAddress memory);
    function withdrawalIds(bytes32) external view returns (bool);
    function rewards() external view returns (EverscaleAddress memory);

    function governance() external view returns (address);
    function guardian() external view returns (address);
    function management() external view returns (address);

    function token() external view returns (address);
    function targetDecimals() external view returns (uint256);
    function tokenDecimals() external view returns (uint256);

    function depositFee() external view returns (uint256);
    function withdrawFee() external view returns (uint256);

    function emergencyShutdown() external view returns (bool);

    function apiVersion() external view returns (string memory api_version);

    function setDepositFee(uint _depositFee) external;
    function setWithdrawFee(uint _withdrawFee) external;

    function setConfiguration(EverscaleAddress memory _configuration) external;
    function setGovernance(address _governance) external;
    function acceptGovernance() external;
    function setGuardian(address _guardian) external;
    function setManagement(address _management) external;
    function setRewards(EverscaleAddress memory _rewards) external;
    function setEmergencyShutdown(bool active) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount
    ) external;

    function decodeWithdrawalEventData(
        bytes memory eventData
    ) external view returns(WithdrawalParams memory);

    function sweep(address _token) external;

    // Events
    event Deposit(
        uint256 amount,
        int128 wid,
        uint256 addr
    );

    event InstantWithdrawal(
        bytes32 payloadId,
        address recipient,
        uint256 amount
    );

    event UpdateBridge(address bridge);
    event UpdateConfiguration(int128 wid, uint256 addr);
    event UpdateTargetDecimals(uint256 targetDecimals);
    event UpdateRewards(int128 wid, uint256 addr);

    event UpdateDepositFee(uint256 fee);
    event UpdateWithdrawFee(uint256 fee);

    event UpdateGovernance(address governance);
    event UpdateManagement(address management);
    event NewPendingGovernance(address governance);
    event UpdateGuardian(address guardian);

    event EmergencyShutdown(bool active);
}

interface IVault is IVaultBasic {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct StrategyParams {
        uint256 performanceFee;
        uint256 activation;
        uint256 debtRatio;
        uint256 minDebtPerHarvest;
        uint256 maxDebtPerHarvest;
        uint256 lastReport;
        uint256 totalDebt;
        uint256 totalGain;
        uint256 totalSkim;
        uint256 totalLoss;
        address rewardsManager;
        EverscaleAddress rewards;
    }

    struct PendingWithdrawalParams {
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function initialize(
        address _token,
        address _bridge,
        address _governance,
        uint _targetDecimals,
        EverscaleAddress memory _rewards
    ) external;

    function withdrawGuardian() external view returns (address);

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawals(
        address user,
        uint id
    ) external view returns (PendingWithdrawalParams memory);
    function pendingWithdrawalsTotal() external view returns (uint);

    function managementFee() external view returns (uint256);
    function performanceFee() external view returns (uint256);

    function strategies(
        address strategyId
    ) external view returns (StrategyParams memory);
    function withdrawalQueue() external view returns (address[20] memory);

    function withdrawLimitPerPeriod() external view returns (uint256);
    function undeclaredWithdrawLimit() external view returns (uint256);
    function withdrawalPeriods(
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);

    function depositLimit() external view returns (uint256);
    function debtRatio() external view returns (uint256);
    function totalDebt() external view returns (uint256);
    function lastReport() external view returns (uint256);
    function lockedProfit() external view returns (uint256);
    function lockedProfitDegradation() external view returns (uint256);

    function setWithdrawGuardian(address _withdrawGuardian) external;
    function setStrategyRewards(
        address strategyId,
        EverscaleAddress memory _rewards
    ) external;
    function setLockedProfitDegradation(uint256 degradation) external;
    function setDepositLimit(uint256 limit) external;
    function setPerformanceFee(uint256 fee) external;
    function setManagementFee(uint256 fee) external;
    function setWithdrawLimitPerPeriod(uint256 _withdrawLimitPerPeriod) external;
    function setUndeclaredWithdrawLimit(uint256 _undeclaredWithdrawLimit) external;
    function setWithdrawalQueue(address[20] memory queue) external;
    function setPendingWithdrawalBounty(uint256 id, uint256 bounty) external;

    function deposit(
        EverscaleAddress memory recipient,
        uint256 amount,
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;
    function deposit(
        EverscaleAddress memory recipient,
        uint256[] memory amount,
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;
    function depositToFactory(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes memory level3
    ) external;

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures
    ) external returns (
        bool instantWithdrawal,
        PendingWithdrawalId memory pendingWithdrawalId
    );

    function saveWithdraw(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        EverscaleAddress memory recipient,
        uint bounty
    ) external;

    function withdraw(
        uint256 id,
        uint256 amountRequested,
        address recipient,
        uint256 maxLoss,
        uint bounty
    ) external returns(uint256);

    function addStrategy(
        address strategyId,
        uint256 _debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 _performanceFee
    ) external;

    function updateStrategyDebtRatio(
        address strategyId,
        uint256 _debtRatio
    )  external;

    function updateStrategyMinDebtPerHarvest(
        address strategyId,
        uint256 minDebtPerHarvest
    ) external;

    function updateStrategyMaxDebtPerHarvest(
        address strategyId,
        uint256 maxDebtPerHarvest
    ) external;

    function updateStrategyPerformanceFee(
        address strategyId,
        uint256 _performanceFee
    ) external;

    function migrateStrategy(
        address oldVersion,
        address newVersion
    ) external;

    function revokeStrategy(
        address strategyId
    ) external;
    function revokeStrategy() external;


    function totalAssets() external view returns (uint256);
    function debtOutstanding(address strategyId) external view returns (uint256);
    function debtOutstanding() external view returns (uint256);

    function creditAvailable(address strategyId) external view returns (uint256);
    function creditAvailable() external view returns (uint256);

    function availableDepositLimit() external view returns (uint256);
    function expectedReturn(address strategyId) external view returns (uint256);

    function report(
        uint256 profit,
        uint256 loss,
        uint256 _debtPayment
    ) external returns (uint256);

    function skim(address strategyId) external;

    function forceWithdraw(
        PendingWithdrawalId memory pendingWithdrawalId
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalId
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;


    event PendingWithdrawalUpdateBounty(address recipient, uint256 id, uint256 bounty);
    event PendingWithdrawalCancel(address recipient, uint256 id, uint256 amount);
    event PendingWithdrawalForce(address recipient, uint256 id);
    event PendingWithdrawalCreated(
        address recipient,
        uint256 id,
        uint256 amount,
        bytes32 payloadId
    );
    event PendingWithdrawalWithdraw(
        address recipient,
        uint256 id,
        uint256 requestedAmount,
        uint256 redeemedAmount
    );
    event PendingWithdrawalUpdateApproveStatus(
        address recipient,
        uint256 id,
        ApproveStatus approveStatus
    );

    event UpdateWithdrawLimitPerPeriod(uint256 withdrawLimitPerPeriod);
    event UpdateUndeclaredWithdrawLimit(uint256 undeclaredWithdrawLimit);
    event UpdateDepositLimit(uint256 depositLimit);

    event UpdatePerformanceFee(uint256 performanceFee);
    event UpdateManagementFee(uint256 managenentFee);

    event UpdateWithdrawGuardian(address withdrawGuardian);
    event UpdateWithdrawalQueue(address[20] queue);

    event StrategyUpdateDebtRatio(address indexed strategy, uint256 debtRatio);
    event StrategyUpdateMinDebtPerHarvest(address indexed strategy, uint256 minDebtPerHarvest);
    event StrategyUpdateMaxDebtPerHarvest(address indexed strategy, uint256 maxDebtPerHarvest);
    event StrategyUpdatePerformanceFee(address indexed strategy, uint256 performanceFee);
    event StrategyMigrated(address indexed oldVersion, address indexed newVersion);
    event StrategyRevoked(address indexed strategy);
    event StrategyRemovedFromQueue(address indexed strategy);
    event StrategyAddedToQueue(address indexed strategy);
    event StrategyReported(
        address indexed strategy,
        uint256 gain,
        uint256 loss,
        uint256 debtPaid,
        uint256 totalGain,
        uint256 totalSkim,
        uint256 totalLoss,
        uint256 totalDebt,
        uint256 debtAdded,
        uint256 debtRatio
    );

    event StrategyAdded(
        address indexed strategy,
        uint256 debtRatio,
        uint256 minDebtPerHarvest,
        uint256 maxDebtPerHarvest,
        uint256 performanceFee
    );
    event StrategyUpdateRewards(
        address strategyId,
        int128 wid,
        uint256 addr
    );
    event UserDeposit(
        address sender,
        int128 recipientWid,
        uint256 recipientAddr,
        uint256 amount,
        address withdrawalRecipient,
        uint256 withdrawalId,
        uint256 bounty
    );
    event FactoryDeposit(
        uint128 amount,
        int8 wid,
        uint256 user,
        uint256 creditor,
        uint256 recipient,
        uint128 tokenAmount,
        uint128 tonAmount,
        uint8 swapType,
        uint128 slippageNumerator,
        uint128 slippageDenominator,
        bytes1 separator,
        bytes level3
    );

}

    struct SwapData {
        IDEXTax.RouteItem[] route;
        uint amountIn;
        uint amountOut;
        address to;
        uint deadline;
    }

    struct DepositData {
        address vault;
        uint128 amount;
        int8 wid;
        uint256 user;
        uint256 creditor;
        uint256 recipient;
        uint128 tokenAmount;
        uint128 tonAmount;
        uint8 swapType;
        uint128 slippageNumerator;
        uint128 slippageDenominator;
        bytes level3;
    }

interface IEverSwap {
    function swapETHForExactTokens(SwapData calldata swapData, DepositData calldata depositData) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(SwapData calldata swapData, DepositData calldata depositData) external payable returns (uint[] memory amounts);
    function swapTokensForExactTokens(SwapData calldata swapData, DepositData calldata depositData) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(SwapData calldata swapData, DepositData calldata depositData) external returns (uint[] memory amounts);
}


contract EverSwap is IEverSwap {

    address dexTax;
    constructor(address _dexTax) {
        dexTax = _dexTax;
    }

    function approve(address token, address spender, uint amount) internal
    {
        uint256 allowed = IERC20(token).allowance(address(this), spender);
        if (allowed < amount)
        {
            IERC20(token).approve(spender, type(uint256).max);
        }
    }

    function deposit(address token, DepositData calldata data) internal {
        approve(token, data.vault, data.amount);
        IVault(data.vault).depositToFactory(
            data.amount,
            data.wid,
            data.user,
            data.creditor,
            data.recipient,
            data.tokenAmount,
            data.tonAmount,
            data.swapType,
            data.slippageNumerator,
            data.slippageDenominator,
            data.level3
        );
    }

    function getOutToken(SwapData calldata swapData) internal pure returns (address) {
        IDEXTax.RouteItem memory route = swapData.route[swapData.route.length-1];
        return route.path[route.path.length -1];
    }

    function swapETHForExactTokens(SwapData calldata swapData, DepositData calldata depositData) override external payable returns (uint[] memory amounts) {
        amounts = IDEXTax(dexTax).swapETHForExactTokens{value : swapData.amountIn}(swapData.route, swapData.amountOut, address(this), swapData.deadline);
        deposit(getOutToken(swapData), depositData);
    }

    function swapExactETHForTokens(SwapData calldata swapData, DepositData calldata depositData) override external payable returns (uint[] memory amounts) {
        amounts = IDEXTax(dexTax).swapExactETHForTokens{value : swapData.amountIn}(swapData.route, swapData.amountOut, address(this), swapData.deadline);
        deposit(getOutToken(swapData), depositData);
    }

    function swapTokensForExactTokens(SwapData calldata swapData, DepositData calldata depositData) override external returns (uint[] memory amounts) {
        amounts = IDEXTax(dexTax).swapTokensForExactTokens(swapData.route, swapData.amountOut, swapData.amountIn, address(this), swapData.deadline);
        deposit(getOutToken(swapData), depositData);
    }
    function swapExactTokensForTokens(SwapData calldata swapData, DepositData calldata depositData) override external returns (uint[] memory amounts) {
        amounts = IDEXTax(dexTax).swapExactTokensForTokens(swapData.route, swapData.amountIn, swapData.amountOut, address(this), swapData.deadline);
        deposit(getOutToken(swapData), depositData);
    }

}