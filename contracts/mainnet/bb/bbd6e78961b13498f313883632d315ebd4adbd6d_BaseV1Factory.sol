/**
 *Submitted for verification at FtmScan.com on 2022-11-26
*/

/*

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU



            **************************
            **                      **
            **         ABCDEFx         **
            **                      **
            **     A Multi-Chain    **
            **Decentralized Exchange**
            **                      **
            ** A Product created by **
            **   Guru Network DAO   **
            **************************


Create Liquidity, Trade, Farm, & Vault for your own projects for free with MTV.Guru

                        Contact us at:
            https://discord.com/invite/QpyfMarNrV
                    https://t.me/FTM1337

                Powered by Guru Network (🦾,🚀)

*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface erc20 {
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
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

interface IBaseV1Callee {
    function hook(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IBaseV1Factory {
    function fee() external view returns (uint256);
    function feeTaker() external view returns (address);
}

interface IBaseV1Pair {
    function updateFee(uint _f) external;
    function setFeeTaker(address _ft) external;
}


// The base pair of pools, stable
contract BaseV1Pair {

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public fee;

    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) public allowance;
    mapping(address => uint) public balanceOf;

    bytes32 internal DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    uint internal constant MINIMUM_LIQUIDITY = 10**3;

    address public immutable token0;
    address public immutable token1;
    address public feeTaker;
    address public immutable factory;

    uint112 public reserve0;
    uint112 public reserve1;
    uint32 public blockTimestampLast;

    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint timestamp;
        uint reserve0Cumulative;
        uint reserve1Cumulative;
    }

    // Capture oracle reading every 30 minutes
    uint constant periodSize = 1800;

    Observation[] public observations;

    uint internal immutable decimals0;
    uint internal immutable decimals1;

    uint public reserve0CumulativeLast;
    uint public reserve1CumulativeLast;

    uint public totalFee0;
    uint public totalFee1;

    event Fees(address indexed sender, uint amount0, uint amount1);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    constructor() {
        factory = msg.sender;
        (address _token0, address _token1) = BaseV1Factory(msg.sender).getInitializable();
        (token0, token1) = (_token0, _token1);
        feeTaker = IBaseV1Factory(msg.sender).feeTaker();
        name = string(abi.encodePacked("ABCDEFx Liquidity Position: ", erc20(_token0).name(), " paired with ", erc20(_token1).name()));
        symbol = string(abi.encodePacked("ABCDEFxLP-", erc20(_token0).symbol(), "/", erc20(_token1).symbol()));
        fee = IBaseV1Factory(factory).fee();

        decimals0 = 10**erc20(_token0).decimals();
        decimals1 = 10**erc20(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));
    }

    // simple re-entrancy check
    uint internal _unlocked = 1;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function observationLength() external view returns (uint) {
        return observations.length;
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length-1];
    }

    function metadata() external view returns (uint dec0, uint dec1, uint112 r0, uint112 r1, address t0, address t1) {
        return (decimals0, decimals1, reserve0, reserve1, token0, token1);
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    function updateFee(uint _fee) external {
        require(msg.sender == factory && _fee >= 10);
        fee = _fee;
    }

    function getFeeTaker() public view returns(address) {
      address lft = feeTaker;
      if(lft == address(0)) {
        return IBaseV1Factory(factory).feeTaker();
      }
      else {
        return lft;
      }
    }

    function setFeeTaker(address _ft) external {
        require(msg.sender == factory);
        feeTaker = _ft;
    }


    // Accrue fees on token0
    function _update0(uint amount) internal {
        _safeTransfer(token0, getFeeTaker(), amount); // transfer the fees out to BaseV1Fees
        totalFee0 += amount;
        emit Fees(msg.sender, amount, 0);
    }

    // Accrue fees on token1
    function _update1(uint amount) internal {
        _safeTransfer(token1, getFeeTaker(), amount);
        totalFee1 += amount;
        emit Fees(msg.sender, 0, amount);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) internal {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'BaseV1Pair: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - uint32(_point.timestamp); // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(Observation(blockTimestamp, reserve0CumulativeLast, reserve1CumulativeLast));
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices() public view returns (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp) {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint _reserve0, uint _reserve1, uint _blockTimestampLast) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint amountIn) external view returns (uint amountOut) {
        Observation memory _observation = lastObservation();
        (uint reserve0Cumulative, uint reserve1Cumulative,) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length-2];
        }

        uint timeElapsed = block.timestamp - _observation.timestamp;
        uint _reserve0 = (reserve0Cumulative - _observation.reserve0Cumulative) / timeElapsed;
        uint _reserve1 = (reserve1Cumulative - _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(address tokenIn, uint amountIn, uint granularity) external view returns (uint amountOut) {
        uint [] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint priceAverageCumulative;
        for (uint i = 0; i < _prices.length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(address tokenIn, uint amountIn, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    function sample(address tokenIn, uint amountIn, uint points, uint window) public view returns (uint[] memory) {
        uint[] memory _prices = new uint[](points);

        uint length = observations.length-1;
        uint i = length - (points * window);
        uint nextIndex = 0;
        uint index = 0;

        for (; i < length; i+=window) {
            nextIndex = i + window;
            uint timeElapsed = observations[nextIndex].timestamp - observations[i].timestamp;
            uint _reserve0 = (observations[nextIndex].reserve0Cumulative - observations[i].reserve0Cumulative) / timeElapsed;
            uint _reserve1 = (observations[nextIndex].reserve1Cumulative - observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
            index = index + 1;
        }
        return _prices;
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1) = (reserve0, reserve1);
        uint _balance0 = erc20(token0).balanceOf(address(this));
        uint _balance1 = erc20(token1).balanceOf(address(this));
        uint _amount0 = _balance0 - _reserve0;
        uint _amount1 = _balance1 - _reserve1;

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(_amount0 * _totalSupply / _reserve0, _amount1 * _totalSupply / _reserve1);
        }
        require(liquidity > 0, 'ILM'); // BaseV1: INSUFFICIENT_LIQUIDITY_MINTED
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, _amount0, _amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint _balance0 = erc20(_token0).balanceOf(address(this));
        uint _balance1 = erc20(_token1).balanceOf(address(this));
        uint _liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = _liquidity * _balance0 / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = _liquidity * _balance1 / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'ILB'); // BaseV1: INSUFFICIENT_LIQUIDITY_BURNED
        _burn(address(this), _liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _balance0 = erc20(_token0).balanceOf(address(this));
        _balance1 = erc20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(!BaseV1Factory(factory).isPaused());
        require(amount0Out > 0 || amount1Out > 0, 'IOA'); // BaseV1: INSUFFICIENT_OUTPUT_AMOUNT
        (uint112 _reserve0, uint112 _reserve1) =  (reserve0, reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'IL'); // BaseV1: INSUFFICIENT_LIQUIDITY

        uint _balance0;
        uint _balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        (address _token0, address _token1) = (token0, token1);
        require(to != _token0 && to != _token1, 'IT'); // BaseV1: INVALID_TO
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) IBaseV1Callee(to).hook(msg.sender, amount0Out, amount1Out, data); // callback, used for flash loans
        _balance0 = erc20(_token0).balanceOf(address(this));
        _balance1 = erc20(_token1).balanceOf(address(this));
        }
        uint amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'IIA'); // BaseV1: INSUFFICIENT_INPUT_AMOUNT
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        (address _token0, address _token1) = (token0, token1);

        if (amount0In > 0) _update0(amount0In / fee); // accrue fees for token0 and move them out of pool
        if (amount1In > 0) _update1(amount1In / fee); // accrue fees for token1 and move them out of pool

        _balance0 = erc20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
        _balance1 = erc20(_token1).balanceOf(address(this));
        // The curve, k = x3y+y3x for stable pools
        require(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1), 'K'); // BaseV1: K
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        (address _token0, address _token1) = (token0, token1);
        _safeTransfer(_token0, to, erc20(_token0).balanceOf(address(this)) - (reserve0));
        _safeTransfer(_token1, to, erc20(_token1).balanceOf(address(this)) - (reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(erc20(token0).balanceOf(address(this)), erc20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*1e18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*1e18/_d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint) {
        (uint _reserve0, uint _reserve1) = (reserve0, reserve1);
        amountIn -= amountIn / fee; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1) internal view returns (uint) {
        uint xy =  _k(_reserve0, _reserve1);
        _reserve0 = _reserve0 * 1e18 / decimals0;
        _reserve1 = _reserve1 * 1e18 / decimals1;
        (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
        uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
        return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
    }

    function _k(uint x, uint y) internal view returns (uint) {
        uint _x = x * 1e18 / decimals0;
        uint _y = y * 1e18 / decimals1;
        uint _a = (_x * _y) / 1e18;
        uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return _a * _b / 1e18;  // x3y+y3x >= k
    }

    function kLast() public view returns (uint) {
        return _k(reserve0, reserve1);
    }

    function _mint(address dst, uint amount) internal {
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {
        totalSupply -= amount;
        balanceOf[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'BaseV1: EXPIRED');
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256('1'),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'BaseV1: INVALID_SIGNATURE');
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balanceOf[src] -= amount;
        balanceOf[dst] += amount;
        emit Transfer(src, dst, amount);
    }

    function _safeTransfer(address token,address to,uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

contract BaseV1Factory {

    bool public isPaused;
    address public owner;
    address public pendingOwner;
    address public admin;

    uint256 public fee = 250;   //1000: =1/1000 = 0.001 = 0.1%, 250 = 0.4%

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    address internal _temp0;
    address internal _temp1;

    address public feeTaker;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() {
        owner = msg.sender;
        isPaused = false;
    }

    function setfee(uint256 _fee) external {
        require(msg.sender == owner);
        require(_fee >= 100 && _fee <= 10000, "!range");
        fee = _fee;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        pendingOwner = _owner;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == owner || msg.sender == admin);
        admin = _admin;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner);
        owner = pendingOwner;
    }

    //Global
    function setPause(bool _state) external {
        require(msg.sender == owner);
        isPaused = _state;
    }

    //Global
    function setFeeTaker(address _ft) external {
        require (msg.sender == owner);
        feeTaker = _ft;
    }

    //Local
    function setFeeTaker(address _pair, address _ft) external {
        require (msg.sender == owner);
        IBaseV1Pair(_pair).setFeeTaker(_ft);
    }

    //Local
    function setFeeTakers(address[] memory _pairs, address[] memory _ft) external {
        require (msg.sender == owner);
        for(uint i;i<_pairs.length;i++) {
          IBaseV1Pair(_pairs[i]).setFeeTaker(_ft[i]);
        }
    }

    //Local
    function updateFee(address _pair, uint _f) external {
        require (msg.sender == owner);
        IBaseV1Pair(_pair).updateFee(_f);
    }

    //Local
    function updateFee(address[] memory _pairs, uint[] memory _f) external {
        require (msg.sender == owner);
        for(uint i;i<_pairs.length;i++) {
          IBaseV1Pair(_pairs[i]).updateFee(_f[i]);
        }
    }

    function INIT_CODE_PAIR_HASH() external pure returns (bytes32) {
        return keccak256(type(BaseV1Pair).creationCode);
    }

    function getInitializable() external view returns (address, address) {
        return (_temp0, _temp1);
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'IA'); // BaseV1: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZA'); // BaseV1: ZERO_ADDRESS
        require(getPair[token0][token1] == address(0), 'PE'); // BaseV1: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        (_temp0, _temp1) = (token0, token1);
        pair = address(new BaseV1Pair{salt:salt}());
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}