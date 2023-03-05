/**
 *Submitted for verification at FtmScan.com on 2023-03-05
*/

//SPDX-License-Identifier: Unlicense
// File: contracts/libraries/SafeMath.sol
pragma solidity ^0.8.0;
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

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y != 0, "ds-math-div-overflow");
        return x / y;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
pragma solidity ^0.8.0;
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

// File: contracts/owner/Operator.sol
pragma solidity ^0.8.0;

contract Operator is Context, Ownable {
    address private _operator;
    address[] private _swappers;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    event SwapperRegistered(
        uint256 indexed index,
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        _swappers.push(_msgSender());
        _swappers.push(address(0));
        _swappers.push(address(0));
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    modifier onlySwappers() {
        require(
            _swappers[0] == msg.sender ||
                _swappers[1] == msg.sender ||
                _swappers[2] == msg.sender,
            "operator: caller is not the operator"
        );
        _;
    }

    function registerSwapper(uint256 _index, address _swapper)
        external
        onlyOwner
    {
        _registerSwapper(_index, _swapper);
    }

    function _registerSwapper(uint256 _index, address _swapper) internal {
        require(
            _swapper != address(0),
            "operator: zero address given for new operator"
        );
        require(_index < 3, "swappers cannot be more than 3");
        address prevSwapper = _swappers[_index];
        _swappers[_index] = _swapper;
        emit SwapperRegistered(_index, prevSwapper, _swappers[_index]);
    }

    function showSwappers(uint256 _index) external view returns (address) {
        require(_index < 3, "swappers cannot be more than 3");
        return _swappers[_index];
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(
            newOperator_ != address(0),
            "operator: zero address given for new operator"
        );
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}


// File: contracts/ArbV6.sol
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);
}

interface IFantom {
    function getEstimatedGasFee(uint256) external view returns (uint256);
}

interface IUniswapV2Router {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract ArbV6 is Operator {
    struct Config {
        address privatePool;
        address publicPool;
        address privateRouter;
        address publicRouter;
        address asset;
        address base;
        uint256 threshold;
    }
    Config[] public configs;
    address public rewardPool;
    using SafeMath for uint256;

    uint public maxGasPrice = 10000000000000000;

    event NewMaxGasPrice(uint oldPrice, uint newPrice);

    constructor() {
        rewardPool = address(0);
    }

    function setMaxGasPrice(uint _maxGasPrice) external onlyOwner {
        emit NewMaxGasPrice(maxGasPrice, _maxGasPrice);
        maxGasPrice = _maxGasPrice;
    }

    function recoverEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function recoverTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setRewardPool(address _rewardPool) public onlyOwner {
        rewardPool = _rewardPool;
    }

    function createConfig(
        address _privatePool,
        address _publicPool,
        address _privateRouter,
        address _publicRouter,
        address _asset,
        address _base,
        uint256 _threshold
        ) public onlyOperator {
            configs.push(
                Config(_privatePool, _publicPool, _privateRouter, _publicRouter, _asset, _base, _threshold)
            );
    }

    function updateConfig(
        uint256 _index,
        address _privatePool,
        address _publicPool,
        address _privateRouter,
        address _publicRouter,
        address _asset,
        address _base,
        uint256 _threshold
        ) public onlyOperator {
            Config storage config = configs[_index];
            config.privatePool = _privatePool;
            config.publicPool = _publicPool;
            config.privateRouter = _privateRouter;
            config.publicRouter = _publicRouter;
            config.asset = _asset;
            config.base = _base;
            config.threshold = _threshold;
    }

    function swap(
        address router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
        ) private {
            IERC20(_tokenIn).approve(router, _amount);
            address[] memory path;
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
            uint256 deadline = block.timestamp + 300;
            IUniswapV2Router(router).swapExactTokensForTokens(
                _amount,
                1,
                path,
                address(this),
                deadline
            );
    }

    function getAmountOutMin(
        address router,
        address _tokenIn,
        address _tokenOut,
        uint256 _amount
        ) public view returns (uint256) {
            address[] memory path;
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
            uint256[] memory amountOutMins = IUniswapV2Router(router).getAmountsOut(
                _amount,
                path
            );
            return amountOutMins[path.length - 1];
    }

    function getBalance(address _tokenContractAddress)
        external
        view
        returns (uint256)
        {
            uint256 balance = IERC20(_tokenContractAddress).balanceOf(
                address(this)
            );
            return balance;
    }

    function estimateDualDexTrade(
        address _router1,
        address _router2,
        address _token1,
        address _token2,
        uint256 _amount
        ) external view returns (uint256) {
            uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
            uint256 amtBack2 = getAmountOutMin(
                _router2,
                _token2,
                _token1,
                amtBack1
            );
            return amtBack2;
    }

    function estimateTriDexTrade(
        address _router1,
        address _router2,
        address _router3,
        address _token1,
        address _token2,
        address _token3,
        uint256 _amount
        ) external view returns (uint256) {
            uint256 amtBack1 = getAmountOutMin(_router1, _token1, _token2, _amount);
            uint256 amtBack2 = getAmountOutMin(
                _router2,
                _token2,
                _token3,
                amtBack1
            );
            uint256 amtBack3 = getAmountOutMin(
                _router3,
                _token3,
                _token1,
                amtBack2
            );
            return amtBack3;
    }

    function dualDexTradeV3(uint256 _index) external onlySwappers {
        (
            bool isValid,
            address _router1,
            address _router2,
            address _token1,
            address _token2,
            uint256 _amount
        ) = this.checker(_index);
        require(isValid, "Trade Reverted, Price different less than threshold.");
        require(tx.gasprice <= maxGasPrice, "Trade Reverted. Gas is too high!");
        uint256 startBalance = IERC20(_token1).balanceOf(address(this));
        uint256 token2InitialBalance = IERC20(_token2).balanceOf(address(this));
        swap(_router1, _token1, _token2, _amount);
        uint256 token2Balance = IERC20(_token2).balanceOf(address(this));
        uint256 tradeableAmount = token2Balance - token2InitialBalance;
        swap(_router2, _token2, _token1, tradeableAmount);
        uint256 endBalance = IERC20(_token1).balanceOf(address(this));
        require(endBalance > startBalance, "Trade Reverted, No Profit Made.");
        uint256 profitAmount = endBalance - startBalance;
        if (rewardPool != address(0)) {
            IERC20(_token1).approve(rewardPool, profitAmount);
            IERC20(_token1).transferFrom(address(this), rewardPool, profitAmount);
        }
    }

    function getTokenAddresses(address pairAddress) public view returns (address, address) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        return (pair.token0(), pair.token1());
    }

    function getTokenDecimals(address tokenAddress) public view returns (uint8) {
        IERC20 token = IERC20(tokenAddress);
        return token.decimals();
    }

    function normalizeTo18Decimal(uint112 _reserve, uint8 _decimal) public pure returns (uint256) {
        uint256 normalizedValue;
        if (_decimal < 18) {
            normalizedValue = uint256(_reserve).mul(10 ** (18 - _decimal));
        } else if (_decimal == 18) {
            normalizedValue = uint256(_reserve);
        } else {
            normalizedValue = 0;
        }
        return normalizedValue;
    }

    function getPriceWithPairAddr(address _pairAddress) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        (address token0_addr, address token1_addr) = this.getTokenAddresses(_pairAddress);
        uint8 decimal0 = this.getTokenDecimals(token0_addr);
        uint8 decimal1 = this.getTokenDecimals(token1_addr);

        // Normalize reserve decimals to 18 decimals for further use
        uint256 normReserve0 = this.normalizeTo18Decimal(reserve0, decimal0);
        uint256 normReserve1 = this.normalizeTo18Decimal(reserve1, decimal1);

        // Calculate price and return
        return (normReserve0).mul(10 ** 18).div(normReserve1);
    }

    function getKWithPairAddr(address _pairAddress) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(_pairAddress);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        (address token0_addr, address token1_addr) = this.getTokenAddresses(_pairAddress);
        uint8 decimal0 = this.getTokenDecimals(token0_addr);
        uint8 decimal1 = this.getTokenDecimals(token1_addr);

        // Normalize reserve decimals to 18 decimals for further use
        uint256 normReserve0 = this.normalizeTo18Decimal(reserve0, decimal0);
        uint256 normReserve1 = this.normalizeTo18Decimal(reserve1, decimal1);

        // Calculate k Value
        return normReserve0.mul(normReserve1);
    }

    function sqrt(uint256 x) public pure returns (uint256) {
        if (x == 0) {
            return 0;
        }
        uint256 y = x;
        uint256 z = (y + 1) / 2;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    function getNewReserve(uint256 _index, uint256 _pricePublic, uint256 _kPrivate, uint8 _decimal0, uint8 _decimal1) external view returns (uint256) {
        uint256 d0 = uint256(_decimal0);
        uint256 d1 = uint256(_decimal1);
        uint256 r0 = this.sqrt(_kPrivate.mul(_pricePublic).mul(10 ** d1)).div(10 ** (d1.add(d1).sub(d0)));
        uint256 r1 = this.sqrt(_kPrivate.mul(_pricePublic).mul(10 ** d0)).div(10 ** (d0.add(d0).sub(d1)));
        uint256 reserve = (_index == 0) ? r0 : r1;

        return reserve;
    }

    function getAmount(address _privatePool, address _publicPool, address _baseAddr) external view returns (uint256) {
        // Get Price and Private K Value
        uint256 pricePublic = this.getPriceWithPairAddr(_publicPool);
        uint256 kPrivate = this.getKWithPairAddr(_privatePool);

        // Calculate amount of base token to be traded
        IUniswapV2Pair privatePair = IUniswapV2Pair(_privatePool);
        (uint112 reserve0, uint112 reserve1, ) = privatePair.getReserves();

        (address token0_addr, address token1_addr) = (privatePair.token0(), privatePair.token1());
        uint8 decimal0 = this.getTokenDecimals(token0_addr);
        uint8 decimal1 = this.getTokenDecimals(token1_addr);

        uint256 reserveOld = (token0_addr == _baseAddr) ? uint256(reserve0) : uint256(reserve1);

        uint256 reserveNew0 = this.getNewReserve(0, pricePublic, kPrivate, decimal0, decimal1);
        uint256 reserveNew1 = this.getNewReserve(1, pricePublic, kPrivate, decimal0, decimal1);
        uint256 reserveNew = (token0_addr == _baseAddr) ? reserveNew0 : reserveNew1;
            
        uint256 amt = (reserveNew > reserveOld) ? reserveNew - reserveOld : reserveOld - reserveNew;
        return amt;
    }
                                    
    function comparePriceDiff(uint256 _price1, uint256 _price2, address _privateRouter, address _publicRouter) external pure returns (
            uint256,
            address,
            address
        ) {
        uint256 _priceDiffPercentage;
        address _addr1;
        address _addr2;

        if (_price1 > _price2) {
            _priceDiffPercentage = (_price1.sub(_price2)).mul(10000).div(_price2);
            _addr1 = _privateRouter;
            _addr2 = _publicRouter;
        } else {
            _priceDiffPercentage = (_price1.sub(_price2)).mul(10000).div(_price2);
            _addr1 = _publicRouter;
            _addr2 = _privateRouter;
        }

        return (_priceDiffPercentage, _addr1, _addr2);
    }

    function checker(uint256 _index) external view returns (
            bool,
            address,
            address,
            address,
            address,
            uint256
        ) {
        Config memory config = configs[_index];

        // Get Amount of base to be traded
        uint256 amt = this.getAmount(config.privatePool, config.publicPool, config.base);

        // Get sequence of setting
        uint256 pricePub = this.getPriceWithPairAddr(config.publicPool);
        uint256 pricePvt = this.getPriceWithPairAddr(config.privatePool);
        (uint256 priceDiffPercentage, address addr1, address addr2) = this.comparePriceDiff(pricePub, pricePvt, config.privateRouter, config.publicRouter);

         // Check if price gap larger than threshold
        if (priceDiffPercentage >= config.threshold) {
            return (
                true,
                addr1,
                addr2,
                config.base,
                config.asset,
                amt
            );
        } else {
            return (
                false,
                address(0),
                address(0),
                address(0),
                address(0),
                0
            );
        }
    }

    function _getPrice(
        address routerAddress,
        address sell_token,
        address buy_token,
        uint256 amount
        )
            external
            view
            returns (
                //) internal view returns (uint256) {
                uint256
            )
        {
        address[] memory pairs = new address[](2);
        pairs[0] = sell_token;
        pairs[1] = buy_token;
        uint256 price = IUniswapV2Router(routerAddress).getAmountsOut(
            amount,
            pairs
        )[1];
        return price;
    }

    receive() external payable {}
}