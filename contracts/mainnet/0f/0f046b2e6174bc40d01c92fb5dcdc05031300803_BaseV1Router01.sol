/**
 *Submitted for verification at FtmScan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT
// Website: Panicswap.com
// Telegram: @Panic_Swap
// Twitter: @Panic_Swap

pragma solidity 0.8.11;

interface IBaseV1Factory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

interface IBaseV1Pair {
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
}

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
}

library Math {
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
}

interface IWFTM {
    function deposit() external payable returns (uint);
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external returns (uint);
}

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

interface YfiVault {
    function pricePerShare() external view returns(uint);
    function decimals() external view returns(uint);
    function deposit(uint) external returns(uint);
    function withdraw(uint) external returns(uint);
}

contract BaseV1Router01 is Ownable{

    struct route {
        address from;
        address to;
        bool stable;
    }

    address public immutable factory;
    IWFTM public immutable wftm;
    IWFTM public immutable weth;
    IWFTM public immutable WETH;
    uint internal constant MINIMUM_LIQUIDITY = 10**3;
    bytes32 immutable pairCodeHash;

    mapping(address=>address) private tokenToVault;
    mapping(address=>bool) private isVault;
    
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BaseV1Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _wftm, address _yvwftm) {
        factory = _factory;
        pairCodeHash = IBaseV1Factory(_factory).pairCodeHash();
        wftm = IWFTM(_wftm);
        weth = wftm;
        WETH = wftm;
        setTokenToVault(_wftm, _yvwftm);
        erc20(_wftm).approve(_yvwftm, type(uint).max);
    }

    receive() external payable {
        assert(msg.sender == address(wftm)); // only accept ETH via fallback from the WETH contract
    }

    function setTokenToVault(address _token, address _vault) public onlyOwner{
        tokenToVault[_token] = _vault;
        isVault[_vault] = true;
    }

    function tokenHasVault(address _token) public view returns(bool){
        return tokenToVault[_token] != address(0);
    }

    function underlyingToYv(address _token) public view returns(address){
        return tokenHasVault(_token) ? tokenToVault[_token] : _token;
    }

    function normalizedPricePerShare(address _vault) public view returns(uint pps){
        YfiVault yvT = YfiVault(_vault);
        if(isVault[_vault])
            pps = (yvT.pricePerShare()+1)*1e18/(10**yvT.decimals());
        else
            pps = 1e18;
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'BaseV1Router: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BaseV1Router: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        (address token0, address token1) = sortTokens(underlyingToYv(tokenA), underlyingToYv(tokenB));
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
        (address token0, address token1) = sortTokens(underlyingToYv(tokenA), underlyingToYv(tokenB));
        (uint reserve0, uint reserve1,) = IBaseV1Pair(pairFor(token0, token1, stable)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on one single core pair
    function _getAmountOut(uint amountIn, address tokenIn, address tokenOut) public view returns (uint amount, bool stable) {
        address pair = pairFor(tokenIn, tokenOut, true);
        uint amountStable;
        uint amountVolatile;
        if (IBaseV1Factory(factory).isPair(pair)) {
            amountStable = IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn);
        }
        pair = pairFor(tokenIn, tokenOut, false);
        if (IBaseV1Factory(factory).isPair(pair)) {
            amountVolatile = IBaseV1Pair(pair).getAmountOut(amountIn, tokenIn);
        }
        return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
    }

    // performs chained getAmountOut calculations on one single underlying pair
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) public view returns (uint amount, bool stable) {
        (address tokenInInsidePair, address tokenOutInsidePair) = (underlyingToYv(tokenIn), underlyingToYv(tokenOut));
        uint amountInV = tokenHasVault(tokenIn) ? amountIn * 1e18 / normalizedPricePerShare(tokenInInsidePair) : amountIn;
        ( uint vAmount, bool _stable ) = _getAmountOut(amountInV, tokenInInsidePair, tokenOutInsidePair);
        amount = tokenHasVault(tokenOut) ? vAmount*normalizedPricePerShare(tokenOutInsidePair)/1e18 : vAmount;
        stable = _stable;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function _getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, 'BaseV1Router: INVALID_PATH');
        amounts = new uint[](routes.length+1);
        amounts[0] = amountIn;
        for (uint i = 0; i < routes.length; i++) {
            address pair = pairFor(routes[i].from, routes[i].to, routes[i].stable);
            if (IBaseV1Factory(factory).isPair(pair)) {
                amounts[i+1] = IBaseV1Pair(pair).getAmountOut(amounts[i], routes[i].from);
            }
        }
    }

    // converts underlying route to vault routes so contracts can understand It
    function getVRoutes(route[] memory routes) public view returns (route[] memory vRoutes){
        vRoutes = new route[](routes.length);
        for(uint i; i<routes.length; i++){
            vRoutes[i] = route(underlyingToYv(routes[i].from), underlyingToYv(routes[i].to), routes[i].stable);
        }
    }

    // performs chained getAmountOut calculations on any number of underlying pairs
    function getAmountsOut(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, 'BaseV1Router: INVALID_PATH');
        amounts = new uint[](routes.length+1);
        route[] memory vRoutes = getVRoutes(routes);
        amounts[0] = amountIn;
        address tokenIn = routes[0].from;
        address vault = underlyingToYv(tokenIn);
        uint[] memory vAmounts = _getAmountsOut(
            tokenHasVault(tokenIn) ? amountIn*1e18/normalizedPricePerShare(vault) : amountIn,
            vRoutes
        );
        for(uint i; i< vRoutes.length; i++){
            amounts[i+1] =
                tokenHasVault(routes[i].to) ?
                    vAmounts[i+1] * normalizedPricePerShare(vRoutes[i].to) / 1e18 :
                    vAmounts[i+1];
        }
    }

    // Amounts the contracts need
    function getAmountsOutCore(uint amountIn, route[] memory routes) public view returns (uint[] memory amounts) {
        require(routes.length >= 1, 'BaseV1Router: INVALID_PATH');
        amounts = new uint[](routes.length+1);
        route[] memory vRoutes = getVRoutes(routes);
        address tokenIn = routes[0].from;
        address vault = underlyingToYv(tokenIn);
        amounts = _getAmountsOut(
            tokenHasVault(tokenIn) ? amountIn*1e18/normalizedPricePerShare(vault) : amountIn,
            vRoutes
        );
        amounts[0] = amountIn;
    }

    function isPair(address pair) external view returns (bool) {
        return IBaseV1Factory(factory).isPair(pair);
    }

    
    function _quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) public view returns (uint amountA, uint amountB, uint liquidity) {
        // create the pair if it doesn't exist yet
        address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);
        (uint reserveA, uint reserveB) = (0,0);
        uint _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = erc20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {

            uint amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            } else {
                uint amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min(amountA * _totalSupply / reserveA, amountB * _totalSupply / reserveB);
            }
        }
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity) {
        (address vTokenA, address vTokenB) = (underlyingToYv(tokenA), underlyingToYv(tokenB));
        (amountA, amountB, liquidity) = _quoteAddLiquidity(
            vTokenA,
            vTokenB,
            stable,
            tokenHasVault(tokenA) ? amountADesired * 1e18 / normalizedPricePerShare(vTokenA) : amountADesired,
            tokenHasVault(tokenB) ? amountBDesired * 1e18 / normalizedPricePerShare(vTokenB) : amountBDesired
        );
        amountA = tokenHasVault(tokenA) ? amountA * normalizedPricePerShare(vTokenA) / 1e18 : amountA;
        amountB = tokenHasVault(tokenB) ? amountB * normalizedPricePerShare(vTokenB) / 1e18 : amountB;
    }

    function _quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) public view returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0,0);
        }

        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB, stable);
        uint _totalSupply = erc20(_pair).totalSupply();

        amountA = liquidity * reserveA / _totalSupply; // using balances ensures pro-rata distribution
        amountB = liquidity * reserveB / _totalSupply; // using balances ensures pro-rata distribution

    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB) {
        (address vTokenA, address vTokenB) = (underlyingToYv(tokenA), underlyingToYv(tokenB));
        (amountA, amountB) = _quoteRemoveLiquidity(vTokenA, vTokenB, stable, liquidity);
        amountA = tokenHasVault(tokenA) ? amountA * normalizedPricePerShare(vTokenA) / 1e18 : amountA;
        amountB = tokenHasVault(tokenB) ? amountB * normalizedPricePerShare(vTokenB) / 1e18 : amountB;
    }

    function _addLiquidityCore(
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
        address _pair = IBaseV1Factory(factory).getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = IBaseV1Factory(factory).createPair(tokenA, tokenB, stable);
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

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal returns (uint amountA, uint amountB) {
        (address vTokenA, address vTokenB) = (underlyingToYv(tokenA), underlyingToYv(tokenB));
        (uint ppsA, uint ppsB) = (normalizedPricePerShare(vTokenA), normalizedPricePerShare(vTokenB));
        amountAMin = amountAMin * 1e18 / ppsA;
        amountBMin = amountBMin * 1e18 / ppsB;
        amountADesired = amountADesired * 1e18 / ppsA;
        amountBDesired = amountBDesired * 1e18 / ppsB;
        (amountA, amountB) = _addLiquidityCore(vTokenA, vTokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
        (amountA, amountB) = (amountA * ppsA / 1e18, amountB * ppsB / 1e18);
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = pairFor(tokenA, tokenB, stable);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IBaseV1Pair(pair).mint(to);
    }

    function addLiquidityFTM(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountFTM, uint liquidity) {
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
        //assert(wftm.transfer(pair, amountFTM));
        address yvwftm = underlyingToYv(address(wftm));
        uint shares = YfiVault(yvwftm).deposit(amountFTM);
        erc20(yvwftm).transfer(pair,shares);
        liquidity = IBaseV1Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountFTM) _safeTransferFTM(msg.sender, msg.value - amountFTM);
    }

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) external payable ensure(deadline) returns (uint amountToken, uint amountFTM, uint liquidity) {
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
        //assert(wftm.transfer(pair, amountFTM));
        address yvwftm = underlyingToYv(address(wftm));
        uint shares = YfiVault(yvwftm).deposit(amountFTM);
        erc20(yvwftm).transfer(pair,shares);
        liquidity = IBaseV1Pair(pair).mint(to);
        // refund dust eth, if any
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
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        require(IBaseV1Pair(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
        IBaseV1Pair(pair).burn(address(this));
        (amountA, amountB) = (_sendUnderlying(tokenA, to), _sendUnderlying(tokenB, to));
        require(amountA >= amountAMin, 'BaseV1Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'BaseV1Router: INSUFFICIENT_B_AMOUNT');
    }

    function removeLiquidityFTM(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountFTM) {
        (amountToken, amountFTM) = removeLiquidity(
            token,
            address(wftm),
            stable,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        wftm.withdraw(amountFTM);
        _safeTransferFTM(to, amountFTM);
    }

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline
    ) public ensure(deadline) returns (uint amountToken, uint amountFTM) {
        (amountToken, amountFTM) = removeLiquidity(
            token,
            address(wftm),
            stable,
            liquidity,
            amountTokenMin,
            amountFTMMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        wftm.withdraw(amountFTM);
        _safeTransferFTM(to, amountFTM);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        {
            uint value = approveMax ? type(uint).max : liquidity;
            IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        }

        (amountA, amountB) = removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityFTMWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFTM) {
        address pair = pairFor(token, address(wftm), stable);
        uint value = approveMax ? type(uint).max : liquidity;
        IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountFTM) = removeLiquidityFTM(token, stable, liquidity, amountTokenMin, amountFTMMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountFTMMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountFTM) {
        address pair = pairFor(token, address(wftm), stable);
        uint value = approveMax ? type(uint).max : liquidity;
        IBaseV1Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountFTM) = removeLiquidityFTM(token, stable, liquidity, amountTokenMin, amountFTMMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, route[] memory routes) internal virtual {
        for (uint i = 0; i < routes.length; i++) {
            (address token0,) = sortTokens(routes[i].from, routes[i].to);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = routes[i].from == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < routes.length - 1 ? pairFor(routes[i+1].from, routes[i+1].to, routes[i+1].stable) : address(this);
            IBaseV1Pair(pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        route[] memory routes = new route[](1);
        routes[0].from = tokenFrom;
        routes[0].to = tokenTo;
        routes[0].stable = stable;
        uint[] memory amountsCore = getAmountsOutCore(amountIn, routes);
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountsCore[0]
        );
        _swap(amountsCore, getVRoutes(routes));
        _sendUnderlying(tokenTo, to);
    }
    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external ensure(deadline) returns (uint[] memory amounts) {
        amounts = getAmountsOut(amountIn, routes);
        uint[] memory amountsCore = getAmountsOutCore(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountsCore[0]
        );
        _swap(amountsCore, getVRoutes(routes));
        _sendUnderlying(routes[routes.length-1].to, to);
    }

    function swapExactFTMForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[0].from == address(wftm), 'BaseV1Router: INVALID_PATH');
        amounts = getAmountsOut(msg.value, routes);
        uint[] memory amountsCore = getAmountsOutCore(msg.value, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        wftm.deposit{value: amountsCore[0]}();
        address yvwftm = underlyingToYv(address(wftm));
        uint shares = YfiVault(yvwftm).deposit(amountsCore[0]);
        erc20(yvwftm).transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), shares);
        _swap(amountsCore, getVRoutes(routes));
        _sendUnderlying(routes[routes.length-1].to, to);
    }

    function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[0].from == address(wftm), 'BaseV1Router: INVALID_PATH');
        amounts = getAmountsOut(msg.value, routes);
        uint[] memory amountsCore = getAmountsOutCore(msg.value, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        wftm.deposit{value: amountsCore[0]}();
        address yvwftm = underlyingToYv(address(wftm));
        uint shares = YfiVault(yvwftm).deposit(amountsCore[0]);
        erc20(yvwftm).transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), shares);
        _swap(amountsCore, getVRoutes(routes));
        _sendUnderlying(routes[routes.length-1].to, to);
    }

    function swapExactTokensForFTM(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[routes.length - 1].to == address(wftm), 'BaseV1Router: INVALID_PATH');
        amounts = getAmountsOut(amountIn, routes);
        uint[] memory amountsCore = getAmountsOutCore(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountsCore[0]
        );
        _swap(amountsCore, getVRoutes(routes));
        _sendFtmUnderlying(to);
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(routes[routes.length - 1].to == address(wftm), 'BaseV1Router: INVALID_PATH');
        amounts = getAmountsOut(amountIn, routes);
        uint[] memory amountsCore = getAmountsOutCore(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, 'BaseV1Router: INSUFFICIENT_OUTPUT_AMOUNT');
        _safeTransferFrom(
            routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amountsCore[0]
        );
        _swap(amountsCore, getVRoutes(routes));
        _sendFtmUnderlying(to);
    }

    function _safeTransferFTM(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function _sendFtmUnderlying(address _to) internal {
        address yvwftm = underlyingToYv(address(wftm));
        uint shares = erc20(yvwftm).balanceOf(address(this));
        uint underlying = YfiVault(yvwftm).withdraw(shares);
        wftm.withdraw(underlying);
        _safeTransferFTM(_to, underlying);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        address vToken = underlyingToYv(token);
        if(vToken != token){
            erc20(token).transferFrom(from, address(this), value);
            erc20(token).approve(vToken, value);
            uint shares = YfiVault(vToken).deposit(value);
            erc20(vToken).transfer(to, shares);
        } else {
            (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }

    function _sendUnderlying(address token, address to) internal returns(uint underlyingAmount){
        if(tokenHasVault(token)){
            address vToken = underlyingToYv(token);
            uint vaultAmount = erc20(vToken).balanceOf(address(this));
            YfiVault(vToken).withdraw(vaultAmount);
        }
        underlyingAmount = erc20(token).balanceOf(address(this));
        erc20(token).transfer(to, underlyingAmount);
    }
}