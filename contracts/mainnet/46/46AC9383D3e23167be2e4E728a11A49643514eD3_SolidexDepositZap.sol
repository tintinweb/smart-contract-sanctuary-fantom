/**
 *Submitted for verification at FtmScan.com on 2022-02-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;


interface IBaseV1Factory {
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

interface IBaseV1Pair {
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

interface IWFTM {
    function deposit() external payable returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external returns (uint);
}

interface ILpDepositor {
    function deposit(address pool, uint256 amount) external;
    function withdraw(address pool, uint256 amount) external;
    function tokenForPool(address pool) external view returns (IERC20);
}

contract SolidexDepositZap {

    IBaseV1Factory public immutable factory;
    IWFTM public immutable wftm;
    ILpDepositor public immutable lpDepositor;

    uint internal constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 immutable pairCodeHash;

    mapping (address => IERC20) public depositTokenForPair;

    constructor(IBaseV1Factory _factory, IWFTM _wftm, ILpDepositor _lpDepositor) {
        factory = _factory;
        pairCodeHash = IBaseV1Factory(_factory).pairCodeHash();
        wftm = _wftm;
        lpDepositor = _lpDepositor;
    }

    receive() external payable {
        assert(msg.sender == address(wftm)); // only accept ETH via fallback from the WETH contract
    }

    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'BaseV1Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BaseV1Router: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
            hex'ff',
            factory,
            keccak256(abi.encodePacked(token0, token1, stable)),
            pairCodeHash // init code hash
        )))));
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'BaseV1Router: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'BaseV1Router: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable) public view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IBaseV1Pair(pairFor(tokenA, tokenB, stable)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity) {
        // create the pair if it doesn't exist yet
        address _pair = factory.getPair(tokenA, tokenB, stable);
        (uint reserveA, uint reserveB) = (0,0);
        uint _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = IERC20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {

            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            }
        }
    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        address _pair = factory.getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0,0);
        }

        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        uint _totalSupply = IERC20(_pair).totalSupply();

        amountA = liquidity * reserveA / _totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity * reserveB / _totalSupply; // using balances ensures pro-rata distribution
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);
        // create the pair if it doesn't exist yet
        address _pair = factory.getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = factory.createPair(tokenA, tokenB, stable);
        }
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'BaseV1Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'BaseV1Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _getDepositToken(address pair) internal returns (IERC20) {
        IERC20 token = depositTokenForPair[pair];
        if (address(token) == address(0)) {
            IERC20(pair).approve(address(lpDepositor), type(uint).max);
            token = lpDepositor.tokenForPool(pair);
            depositTokenForPair[pair] = token;
        }
        return token;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = pairFor(tokenA, tokenB, stable);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBaseV1Pair(pair).mint(address(this));

        IERC20 lpToken = _getDepositToken(pair);
        lpDepositor.deposit(pair, liquidity);
        lpToken.transfer(to, liquidity);
    }

    function addLiquidityFTM(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to
    ) external payable returns (uint amountToken, uint amountFTM, uint liquidity) {
        (amountToken, amountFTM) = _addLiquidity(
            token,
            address(wftm),
            stable,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountFTMMin
        );
        address pair = pairFor(token, address(wftm), stable);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        wftm.deposit{value: amountFTM}();
        assert(wftm.transfer(pair, amountFTM));

        liquidity = IBaseV1Pair(pair).mint(address(this));
        IERC20 lpToken = _getDepositToken(pair);
        lpDepositor.deposit(pair, liquidity);
        lpToken.transfer(to, liquidity);

        if (msg.value > amountFTM) _safeTransferFTM(msg.sender, msg.value - amountFTM);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to
    ) public returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB, stable);

        IERC20 lpToken = _getDepositToken(pair);
        lpToken.transferFrom(msg.sender, address(this), liquidity);
        lpDepositor.withdraw(pair, liquidity);

        IERC20(pair).transfer(pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IBaseV1Pair(pair).burn(to);
        (address token0,) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'BaseV1Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'BaseV1Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityFTM(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to
    ) public returns (uint amountToken, uint amountFTM) {
        (amountToken, amountFTM) = removeLiquidity(
            token,
            address(wftm),
            stable,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            address(this)
        );
        _safeTransfer(token, to, amountToken);
        wftm.withdraw(amountFTM);
        _safeTransferFTM(to, amountFTM);
    }

    function _safeTransferFTM(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}