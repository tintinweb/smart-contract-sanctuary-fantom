// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "IERC20.sol";
import "Irouter.sol";
import "Ifactory.sol";
import "Ipair.sol";
import "ERC20.sol";

contract ETF is ERC20 {
    Irouter router;
    Ifactory factory;
    Ipair pair;

    //address routerAddress = 0xa6AD18C2aC47803E193F75c3677b14BF19B94883;

    /* initializes the "router" and "factory" contract instances. While deploying, the address of
        "router" contract on block-chain must be provided.
    */
    constructor(address routerAddress) {
        router = Irouter(routerAddress);
        factory = Ifactory(router.factory());
    }

    /*  This contract invests in a number of liquidity pools. Each pool is a pir of erc20-token 
        and FTM. This variable "pool" is an array of addresses of these erc20-tokens. 
    */
    address[] public pool = [0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E];

    // returns the number of liquidity pools in which investment will be made.
    function numberOfPools() public view returns (uint256) {
        return pool.length;
    }

    // adds liquidiyt pools in the pool array.
    function addPool(address token) external {
        uint256 length = pool.length;
        bool action = true;
        for (uint256 i; i < length; i++) {
            if (token == pool[i]) {
                action = false;
                break;
            }
        }
        if (action == true) {
            pool.push(token);
        }
    }

    /*  This is the function that should be called for investment. Investment value should be sent
        along with the transaction. You will receive the Investment Tokens in return.
    */
    function investFunds() external payable {
        uint256 amount = msg.value / (2 * pool.length);
        uint256 deadline = block.timestamp + 300000;
        for (uint256 i; i < pool.length; i++) {
            swapETH(pool[i], amount, deadline);
            addLiquidityETH(pool[i], amount, deadline);
        }
        uint256 extra = address(this).balance;
        if (extra > 0) {
            payable(msg.sender).transfer(extra);
        }
        mint(msg.sender, msg.value);
    }

    function swapETH(
        address token,
        uint256 amount,
        uint256 deadline
    ) internal {
        address[] memory path = new address[](2);
        address WETH = router.WETH();
        path[0] = WETH;
        path[1] = token;

        uint256 amountOutMin = ((router.getAmountsOut(amount, path)[1]) / 100) *
            90;

        router.swapExactETHForTokens{value: amount}(
            amountOutMin,
            path,
            address(this),
            deadline
        );
    }

    function addLiquidityETH(
        address token,
        uint256 amount,
        uint256 deadline
    ) internal {
        address[] memory path = new address[](2);
        address WETH = router.WETH();
        path[0] = WETH;
        path[1] = token;

        uint256 amountTokenDesired = ERC20Token(token).balanceOf(address(this));
        uint256 amountTokenMin = (amountTokenDesired / 100) * 90;
        uint256 amountETHMin = (amount / 100) * 90;
        ERC20Token(token).approve(address(router), amountTokenDesired);

        router.addLiquidityETH{value: amount}(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
    }

    function ERC20Token(address token) internal pure returns (IERC20) {
        return IERC20(token);
    }

    /*
        This function should be called to withdraw the investment. Before calling this function,
        please approve this contract to spend the Investment tokens on your behalf.
    */
    function withdrawFunds(uint256 liquidity) external {
        uint256 deadline = block.timestamp + 300000;
        uint256 liquidityRatio = (liquidity * 100) / totalSupply;
        IERC20 token_contract;
        for (uint256 i; i < pool.length; i++) {
            uint256 balances = ((getLPBalances(pool[i]) * liquidityRatio) /
                100);
            removeLiquidityETH(balances, pool[i]);
            token_contract = IERC20(pool[i]);
            uint256 token_balance = token_contract.balanceOf(address(this));
            swapToken(pool[i], token_balance, deadline);
        }
        burn(msg.sender, liquidity);
        uint256 balance_ftm = address(this).balance;
        payable(msg.sender).transfer(balance_ftm);
    }

    function getLPBalances(address token) internal view returns (uint256) {
        address WETH = router.WETH();
        address tokenPair = factory.getPair(WETH, token);
        return ERC20Token(tokenPair).balanceOf(address(this));
    }

    function swapToken(
        address token,
        uint256 amount,
        uint256 deadline
    ) internal {
        address[] memory path = new address[](2);
        address WETH = router.WETH();
        path[0] = token;
        path[1] = WETH;
        uint256 amountOutMin = ((router.getAmountsOut(amount, path)[1]) * 90) /
            100;

        ERC20Token(token).approve(address(router), amount);
        router.swapExactTokensForETH(
            amount,
            amountOutMin,
            path,
            address(this),
            deadline
        );
    }

    function removeLiquidityETH(uint256 liquidity, address token) internal {
        address WETH = router.WETH();
        address LPToken = factory.getPair(token, WETH);
        pair = Ipair(LPToken);
        uint256 WETH_reserve;
        uint256 token_reserve;
        if (pair.token0() == token) {
            (token_reserve, WETH_reserve, ) = pair.getReserves();
        } else {
            (WETH_reserve, token_reserve, ) = pair.getReserves();
        }
        uint256 supply = pair.totalSupply();
        uint256 percent = (liquidity * 100) / supply;
        uint256 amountTokenMin = (percent * token_reserve) / 100;
        amountTokenMin = (amountTokenMin * 90) / 100;
        uint256 amountETHMin = (percent * WETH_reserve) / 100;
        amountETHMin = (amountETHMin * 90) / 100;
        uint256 deadline = block.timestamp + 300000;

        pair.approve(address(router), liquidity);

        router.removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface Irouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface Ifactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "IERC20.sol";

interface Ipair is IERC20 {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "IERC20.sol";

contract ERC20 is IERC20 {
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    string name = "TLV_INVEST";
    string symbol = "TLVI";
    uint256 decimals = 18;

    function transfer(address _to, uint256 _value)
        external
        override
        returns (bool success)
    {
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        external
        override
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool) {
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) internal returns (bool) {
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burn(address _from, uint256 _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
        return true;
    }
}