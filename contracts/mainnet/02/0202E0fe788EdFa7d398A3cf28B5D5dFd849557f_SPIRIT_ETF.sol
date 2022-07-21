// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "ERC20.sol";
import "safeMath.sol";
import "Irouter.sol";
import "IERC20.sol";
import "Ifactory.sol";
import "Ipair.sol";
import "ImasterChef.sol";

contract SPIRIT_ETF is ERC20 {
    using SafeMath for uint256;
    Irouter router;
    Ifactory factory;
    Ipair pair;
    IERC20 erc20;
    ImasterChef masterChef;

    address public immutable WETH; //0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83;
    address public immutable Spirit; //0x5Cc61A78F164885776AA610fb0FE1257df78E59B;
    address feeTo;
    address public admin;
    uint256 fee = 0; // basis points.

    mapping(address => bool) private isPoolAdded;

    struct Pool {
        uint256 PID;
        uint256 allocation; // in basis points.
        uint256 balance;
        address baseToken;
        address LPToken;
    }

    Pool[] public pool;

    //error poolExists();

    constructor(
        address _router,
        address _masterChef,
        address _rewardToken
    ) ERC20() {
        admin = msg.sender;
        router = Irouter(_router);
        factory = Ifactory(router.factory());
        masterChef = ImasterChef(_masterChef);
        WETH = router.WETH();
        Spirit = _rewardToken;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can do this.");
        _;
    }

    modifier rebalance() {
        if (totalSupply != 0) {
            _withdraw(totalSupply);
        }

        _;
        if (totalSupply != 0) {
            _invest(address(this).balance);
        }
    }

    // read functions

    function poolLength() public view returns (uint256) {
        return pool.length;
    }

    function price() public view returns (uint256 _price) {
        uint256 l = pool.length;
        uint256 pendingSpirit = 0;
        uint256 reward;
        uint256 expectedETHOut;
        address[] memory path = new address[](2);
        path[1] = WETH;

        for (uint256 i; i < l; i++) {
            Pool memory temp;
            temp = pool[i];
            pendingSpirit += masterChef.pendingSpirit(temp.PID, address(this));
            uint256 poolETHBalance = IERC20(WETH).balanceOf(temp.LPToken);
            uint256 poolTokenBalance = IERC20(temp.baseToken).balanceOf(
                temp.LPToken
            );
            uint256 LPSupply = IERC20(temp.LPToken).totalSupply();
            expectedETHOut += temp.balance.mul(poolETHBalance) / LPSupply;
            uint256 expectedTokenOut = temp.balance.mul(poolTokenBalance) /
                LPSupply;

            path[0] = temp.baseToken;
            if (expectedTokenOut != 0) {
                expectedETHOut += router.getAmountsOut(expectedTokenOut, path)[
                    1
                ];
            }
        }
        if (pendingSpirit != 0) {
            path[0] = Spirit;
            reward = router.getAmountsOut(pendingSpirit, path)[1];
        }
        expectedETHOut += reward;
        if (totalSupply == 0) {
            _price = 10**18;
        } else {
            _price = expectedETHOut.mul(10**18) / totalSupply;
        }
    }

    function userExpectedReturn(address user) public view returns (uint256) {
        return balanceOf(user).mul(price()) / (10**18);
    }

    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 l = pool.length;
        uint256 ETHOut;
        for (uint256 i; i < l; i++) {
            uint256 withdrawAmount = pool[i].balance.mul(amount) / totalSupply;
            masterChef.withdraw(pool[i].PID, withdrawAmount);
            IERC20(pool[i].LPToken).approve(address(router), withdrawAmount);
            (uint256 amountToken, uint256 amountETH) = router
                .removeLiquidityETH(
                    pool[i].baseToken,
                    withdrawAmount,
                    1,
                    1,
                    address(this),
                    block.timestamp
                );
            ETHOut += swapToken(pool[i].baseToken, amountToken) + amountETH;
            pool[i].balance -= withdrawAmount;
        }
        uint256 SpiritBalance = IERC20(Spirit).balanceOf(address(this));
        if (SpiritBalance != 0) {
            ETHOut += swapToken(Spirit, SpiritBalance);
        }
        return ETHOut;
    }

    // write functions

    function transferOwnership(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function addFee(uint256 _fee, address _feeTo) public onlyAdmin {
        fee = _fee;
        feeTo = _feeTo;
    }

    function addPool(
        address _baseToken,
        uint256 _pid,
        uint256 _allocation
    ) public onlyAdmin rebalance {
        require(checkPID(_pid, _baseToken), "wrong pid");
        require(!isPoolAdded[_baseToken], "poolExists");
        require(_allocation <= 10000, "allocation>100");

        uint256 l = pool.length;
        if (l == 0) {
            require(
                _allocation == 10000,
                "single pool allocation should be 100"
            );
        }
        for (uint256 i; i < l; i++) {
            pool[i].allocation =
                pool[i].allocation.mul(10000 - _allocation) /
                10000;
        }
        Pool memory temp;
        temp.allocation = _allocation;
        temp.baseToken = _baseToken;
        temp.LPToken = getLPToken(_baseToken);
        temp.PID = _pid;
        pool.push(temp);
        isPoolAdded[_baseToken] = true;
    }

    function removePool(uint256 index) public onlyAdmin rebalance {
        uint256 l = pool.length;
        require(l > 1, "lastPool");
        uint256 indexAllocation = pool[index].allocation;
        pool[index] = pool[l - 1];
        pool.pop();
        isPoolAdded[pool[index].baseToken] = false;
        l = pool.length;
        for (uint256 i; i < l; i++) {
            pool[i].allocation =
                pool[i].allocation.mul(10000) /
                (10000 - indexAllocation);
        }
    }

    function capitalAllocation(uint256[] calldata _allocations)
        public
        onlyAdmin
        rebalance
    {
        uint256 l = pool.length;
        uint256 sum;
        for (uint256 i; i < l; i++) {
            pool[i].allocation = _allocations[i];
            sum += _allocations[i];
        }
        require(sum == 10000, "allocations are not adding to 100");
    }

    function invest() public payable {
        uint256 investment;

        if (fee == 0) {
            investment = msg.value;
        } else {
            uint256 commission = msg.value.mul(fee) / 10000;
            payable(feeTo).transfer(commission);
            investment = msg.value - commission;
        }
        mint(msg.sender, investment.mul(10**18) / price());
        _invest(investment);

        if (address(this).balance != 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function harvest() public {
        uint256 l = pool.length;

        for (uint256 i; i < l; i++) {
            masterChef.withdraw(pool[i].PID, 0);
        }
        uint256 SpiritObtained = IERC20(Spirit).balanceOf(address(this));
        if (SpiritObtained == 0) {
            return;
        }

        IERC20(Spirit).approve(address(router), SpiritObtained);

        uint256 ETHObtained = swapToken(Spirit, SpiritObtained);

        _invest(ETHObtained);
    }

    function withdraw(uint256 amount) public {
        uint256 ETHOut = _withdraw(amount);
        uint256 amountToUser;
        if (fee == 0) {
            amountToUser = ETHOut;
        } else {
            uint256 commission = ETHOut.mul(fee) / 10000;
            payable(feeTo).transfer(commission);
            amountToUser = ETHOut - commission;
        }
        payable(msg.sender).transfer(amountToUser);
        burn(msg.sender, amount);
    }

    receive() external payable {}

    // internal functions

    function getLPToken(address _token) internal view returns (address) {
        return factory.getPair(_token, WETH);
    }

    function swapETH(address _token, uint256 _amount)
        internal
        returns (uint256 amountToken)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        uint256 minAmount = quote(path, _amount).mul(95) / 100;
        amountToken = router.swapExactETHForTokens{value: _amount}(
            minAmount,
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
        uint256 minAmount = quote(path, _amount).mul(95) / 100;

        IERC20(_token).approve(address(router), _amount);
        amountETH = router.swapExactTokensForETH(
            _amount,
            minAmount,
            path,
            address(this),
            block.timestamp
        )[1];
    }

    function quote(address[] memory path, uint256 amountIn)
        internal
        view
        returns (uint256 amountOut)
    {
        amountOut = router.getAmountsOut(amountIn, path)[1];
    }

    function addLiquidity(address _token, uint256 amountToSwap)
        internal
        returns (uint256 liquidity)
    {
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

    function _invest(uint256 amount) internal {
        uint256 l = pool.length;
        require(l > 0, "noPoolToInvest");
        uint256 amountToSwap = amount / 2;
        for (uint256 i; i < l; i++) {
            Pool memory temp = pool[i];
            uint256 liquidity = addLiquidity(
                temp.baseToken,
                amountToSwap.mul(temp.allocation) / 10000
            );
            pool[i].balance += liquidity;
            IERC20(temp.LPToken).approve(address(masterChef), liquidity);
            masterChef.deposit(temp.PID, liquidity);
        }
    }

    function checkPID(uint256 _pid, address _token)
        internal
        view
        returns (bool)
    {
        (address lp, , , , ) = masterChef.poolInfo(_pid);
        return lp == getLPToken(_token);
    }
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
        name = "SPIRIT_ETF";
        symbol = "ETFSPIRIT";
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

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allowances[spender][owner];
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
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
            uint256,
            uint256
        );

    function poolLength() external view returns (uint256);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingSpirit(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}