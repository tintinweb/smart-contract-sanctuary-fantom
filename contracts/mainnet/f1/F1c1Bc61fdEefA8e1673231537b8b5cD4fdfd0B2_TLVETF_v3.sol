//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "safeMath.sol";
import "Irouter.sol";
import "IERC20.sol";
import "Ifactory.sol";
import "Ipair.sol";
import "ImasterChef.sol";
import "ERC20.sol";

contract TLVETF_v3 is ERC20 {
    using SafeMath for uint256;

    Irouter router;
    Ifactory factory;
    Ipair pair;
    IERC20 erc20;
    ImasterChef masterChef;
    address public constant WETH = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public constant BOO = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    mapping(uint256 => uint256) contractBalances; // contract LP balances for each pid.
    uint256[] public PID;
    address[] public investPool;
    address public owner;
    uint256 dummy;
    bool _setFee = false;
    uint256 feeAmount = 10; // 10 basis points
    address public FeeCollector;

    constructor(address _router, address _masterChef) ERC20() {
        owner = msg.sender;
        router = Irouter(_router);
        factory = Ifactory(router.factory());
        masterChef = ImasterChef(_masterChef);
    }

    function addInvestPool(address _investToken) external {
        require(
            msg.sender == owner,
            "Only Owner can add the invest pool Token!"
        );
        uint256 l = investPool.length;
        for (uint256 i; i < l; i++) {
            if (investPool[i] == _investToken) {
                return;
            }
        }
        investPool.push(_investToken);
        PID.push(getPoolId(getLPToken(_investToken)));
    }

    function getLPToken(address _token) internal view returns (address) {
        return factory.getPair(_token, WETH);
    }

    function getPoolId(address _lpToekn) public view returns (uint256 pid) {
        uint256 l = masterChef.poolLength();
        for (uint256 i; i < l; i++) {
            (address lp, , , ) = masterChef.poolInfo(i);
            if (lp == _lpToekn) {
                pid = i;
                break;
            }
        }
        return pid;
    }

    function addLiquidity2(address _token, uint256 _amount)
        internal
        returns (uint256 liquidity)
    {
        uint256 amountToSwap = _amount / 2;

        uint256 tokenObtained = swapETH(_token, amountToSwap);

        IERC20(_token).approve(address(router), tokenObtained);
        (, , liquidity) = router.addLiquidityETH{value: amountToSwap}(
            _token,
            tokenObtained,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function swapETH(address _token, uint256 _amount)
        internal
        returns (uint256 amountToken)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;

        amountToken = router.swapExactETHForTokens{value: _amount}(
            1,
            path,
            address(this),
            block.timestamp
        )[1];
    }

    function swapToken(address _token, uint256 _amount)
        internal
        returns (uint256 amountETH)
    {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        IERC20(_token).approve(address(router), _amount);
        amountETH = router.swapExactTokensForETH(
            _amount,
            1,
            path,
            address(this),
            block.timestamp
        )[1];
    }

    function invest() external payable {
        uint256 l = investPool.length;
        uint256 amtToInvest;
        if (_setFee == true) {
            uint256 commission = msg.value.mul(feeAmount) / 10000;
            payable(FeeCollector).transfer(commission);
            amtToInvest = msg.value - commission;
        } else {
            amtToInvest = msg.value;
        }
        uint256 amountPerPool = amtToInvest / l;

        for (uint256 i; i < l; i++) {
            uint256 liquidity = addLiquidity2(investPool[i], amountPerPool);
            contractBalances[PID[i]] += liquidity;
            IERC20(getLPToken(investPool[i])).approve(
                address(masterChef),
                liquidity
            );
            masterChef.deposit(PID[i], liquidity);
        }
        mint(msg.sender, amountPerPool.mul(l).mul(10**18) / price());
        payable(msg.sender).transfer(address(this).balance);
    }

    function price() public view returns (uint256 _price) {
        // calculating return from BOO.
        uint256 l = PID.length;
        uint256 expectedBOO = 0;
        uint256 reward;
        for (uint256 i; i < l; i++) {
            expectedBOO += masterChef.pendingBOO(PID[i], address(this));
        }
        if (expectedBOO != 0) {
            address[] memory path = new address[](2);
            path[0] = BOO;
            path[1] = WETH;
            reward = router.getAmountsOut(expectedBOO, path)[1];
        }
        // calculating the return from liquidity.
        uint256 amountETHOut;
        for (uint256 i; i < l; i++) {
            uint256 supply = IERC20(getLPToken(investPool[i])).totalSupply();
            uint256 poolETHBalance = IERC20(WETH).balanceOf(
                getLPToken(investPool[i])
            );
            uint256 poolTokenBalance = IERC20(investPool[i]).balanceOf(
                getLPToken(investPool[i])
            );
            uint256 amountETH = contractBalances[PID[i]].mul(poolETHBalance) /
                supply;
            uint256 amountToken = contractBalances[PID[i]].mul(
                poolTokenBalance
            ) / supply;
            if (amountToken != 0) {
                address[] memory path = new address[](2);
                path[0] = investPool[i];
                path[1] = WETH;
                amountETH += router.getAmountsOut(amountToken, path)[1];
            }
            amountETHOut += amountETH;
        }
        uint256 expectedReturn = reward + amountETHOut;
        if (totalSupply == 0) {
            _price = 10**18;
        } else {
            _price = expectedReturn.mul(10**18) / totalSupply;
        }
        return _price;
    }

    function harvest() public {
        uint256 l = PID.length;
        for (uint256 i; i < l; i++) {
            masterChef.withdraw(PID[i], 0);
            uint256 BOOObtained = IERC20(BOO).balanceOf(address(this));
            if (BOOObtained == 0) {
                return;
            }
            uint256 amountETHObtained = swapToken(BOO, BOOObtained);
            uint256 liquidity = addLiquidity2(investPool[i], amountETHObtained);
            contractBalances[PID[i]] += liquidity;
            IERC20(getLPToken(investPool[i])).approve(
                address(masterChef),
                liquidity
            );
            masterChef.deposit(PID[i], liquidity);
        }
    }

    function withdrawInvestment(uint256 amount) public {
        uint256 l = PID.length;
        uint256 ETHOut = 0;
        for (uint256 i; i < l; i++) {
            uint256 withdrawAmount = contractBalances[PID[i]].mul(amount) /
                totalSupply;

            masterChef.withdraw(PID[i], withdrawAmount);
            IERC20(getLPToken(investPool[i])).approve(
                address(router),
                withdrawAmount
            );
            (uint256 amountToken, uint256 amountETH) = router
                .removeLiquidityETH(
                    investPool[i],
                    withdrawAmount,
                    1,
                    1,
                    address(this),
                    block.timestamp
                );
            ETHOut += swapToken(investPool[i], amountToken) + amountETH;
            contractBalances[PID[i]] -= withdrawAmount;
        }
        uint256 ethToUser;
        if (_setFee == true) {
            uint256 commission = ETHOut.mul(feeAmount) / 10000;
            ethToUser = ETHOut - commission;
            payable(FeeCollector).transfer(commission);
        } else {
            ethToUser = ETHOut;
        }
        payable(msg.sender).transfer(ethToUser);
        burn(msg.sender, amount);
    }

    function userExpectedReturn(address user) public view returns (uint256) {
        return balanceOf(user).mul(price()) / (10**18);
    }

    function setFee(address collector) public {
        require(msg.sender == owner, "Only owner can set the Fee");
        _setFee = true;
        FeeCollector = collector;
    }

    function feeOff() public {
        _setFee = false;
        FeeCollector = address(0);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Irouter {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);

    function factory() external pure returns (address);

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

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Ifactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "IERC20.sol";

interface Ipair is IERC20 {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ImasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;

    function lpToken(uint256 _pid) external view returns (address);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function poolLength() external view returns (uint256);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingBOO(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "IERC20.sol";

contract ERC20 is IERC20 {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public override totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    constructor() {
        name = "TLVETF";
        symbol = "TLV";
        decimals = 18;
        totalSupply = 0;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        require(spender != address(0));
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address receiver, uint256 amount) public returns (bool) {
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address receiver,
        uint256 amount
    ) public override returns (bool) {
        require(allowances[sender][msg.sender] >= amount);
        balances[sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(sender, receiver, amount);
        return true;
    }

    function mint(address receiver, uint256 amount) internal returns (bool) {
        require(receiver != address(0));
        balances[receiver] += amount;
        totalSupply += amount;
        emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(address sender, uint256 amount) internal returns (bool) {
        require(sender != address(0));
        balances[sender] -= amount;
        totalSupply -= amount;
        emit Transfer(sender, address(0), amount);
        return true;
    }
}