/**
 *Submitted for verification at FtmScan.com on 2022-08-27
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedFtm is IERC20 {
    function deposit() external payable returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

}





////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router {
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

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

interface ITreasury {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getTombPrice() external view returns (uint256);

    function getTombUpdatedPrice() external view returns (uint256);

    function buyBonds(uint256 amount, uint256 targetPrice) external;

    function redeemBonds(uint256 amount, uint256 targetPrice) external;
}




////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/utils/Context.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";

error NewOperatorCantBeAddressZero();
error CallerIsNotTheOperator(address caller, address operator);

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        if (msg.sender != _operator)
            revert CallerIsNotTheOperator(msg.sender, _operator);
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        if (newOperator_ == address(0)) revert NewOperatorCantBeAddressZero();
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }

    function _renounceOperator() public onlyOwner {
        emit OperatorTransferred(_operator, address(0));
        _operator = address(0);
    }
}


////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

////import "./owner/Operator.sol";
////import "./interfaces/ITreasury.sol";
////import "./interfaces/IUniswapV2Pair.sol";
////import "./interfaces/IUniswapV2Router.sol";
////import "./interfaces/IWrappedFtm.sol";

contract FeesManager is Operator {
    address public constant DEAD = address(0xdead);

    IERC20 public immutable tomb;
    ITreasury public immutable treasury;
    IUniswapV2Router public immutable router;
    IUniswapV2Pair public immutable pair;
    IWrappedFtm public immutable WETH;

    uint256 threshold = (1 ether * 103) / 100; // 1.03

    struct TokenInfo {
        address[] path;
        uint256 min;
    }

    mapping(address => bool) public auth;
    mapping(address => TokenInfo) public tokenInfo;

    error TombIsAddressZero();
    error TreasuryIsAddressZero();
    error RouterIsAddressZero();
    error PairIsAddressZero();
    error forbiden();

    modifier onlyAuth() {
        if (!auth[msg.sender]) revert forbiden();
        _;
    }

    receive() external payable {}

    constructor(
        address _tomb,
        address _treasury,
        address _router,
        address _pair
    ) {
        if (_tomb == address(0)) revert TombIsAddressZero();
        if (_treasury == address(0)) revert TreasuryIsAddressZero();
        if (_router == address(0)) revert RouterIsAddressZero();
        if (_pair == address(0)) revert PairIsAddressZero();
        tomb = IERC20(_tomb);
        treasury = ITreasury(_treasury);
        router = IUniswapV2Router(_router);
        pair = IUniswapV2Pair(_pair);
        WETH = IWrappedFtm(IUniswapV2Router(_router).WETH());

        IERC20(_tomb).approve(_router, type(uint256).max);

        addAuth(msg.sender);
    }

    error TokenIsAddressZero();
    error TokenPathIsWrong();
    error MinIsZero();

    function addTokenInfo(
        address _token,
        address[] calldata _path,
        uint256 _min
    ) external onlyOperator {
        if (_token == address(0)) revert TokenIsAddressZero();
        if (_min <= 0) revert MinIsZero();
        if (
            _path.length < 2 ||
            _path[0] != _token ||
            _path[_path.length - 1] != address(tomb)
        ) revert TokenPathIsWrong();

        tokenInfo[_token] = TokenInfo({path: _path, min: _min});
    }

    function updateTokenInfo(
        address _token,
        address[] calldata _path,
        uint256 _min
    ) external onlyOperator {
        if (_token == address(0)) revert TokenIsAddressZero();
        if (_min <= 0) revert MinIsZero();
        if (
            _path.length < 2 ||
            _path[0] != _token ||
            _path[_path.length - 1] != address(tomb)
        ) revert TokenPathIsWrong();

        tokenInfo[_token] = TokenInfo({path: _path, min: _min});
    }

    function manageFees(IERC20 _token, uint256 _amount) public onlyAuth {
        TokenInfo memory _tokenInfo = tokenInfo[address(_token)];

        if (_tokenInfo.path.length <= 0) revert("Token not yet defined");

        uint256 _twapPrice = treasury.getTombUpdatedPrice();

        _token.transferFrom(msg.sender, address(this), _amount);

        _amount = _token.balanceOf(address(this));

        if (_amount < _tokenInfo.min) return;

        // Add liquidity
        if (_twapPrice >= threshold) {
            uint256 _half = _amount / 2;
            uint256 _otherHalf = _amount - _half;

            uint256 _before = address(this).balance;

            if (address(_token) != address(WETH)) {
                address[] memory _path = new address[](2);

                _path[0] = address(_token);
                _path[1] = address(WETH);

                _token.approve(address(router), _half);

                router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    _half,
                    1,
                    _path,
                    address(this),
                    block.timestamp
                );
            } else {
                WETH.withdraw(_half);
            }

            uint256 _amountEth = address(this).balance - _before;

            uint256 _tombToLp = _otherHalf;

            if (address(_token) != address(tomb)) {
                uint256 _tombBefore = tomb.balanceOf(address(this));
                swapToTomb(_token, _otherHalf, _tokenInfo.path);
                _tombToLp = tomb.balanceOf(address(this)) - _tombBefore;
            }

            router.addLiquidityETH{value: _amountEth}(
                address(tomb),
                _tombToLp,
                1,
                1,
                address(this),
                block.timestamp
            );

            uint256 _lpAmount = pair.balanceOf(address(this));

            pair.transfer(DEAD, _lpAmount);
        } else {
            // If current price is below to peg, just burn.
            uint256 _tombToBurn = _amount;
            // Bought Tomb on market.
            if (address(_token) != address(tomb)) {
                uint256 _before = tomb.balanceOf(address(this));
                swapToTomb(_token, _amount, _tokenInfo.path);
                _tombToBurn = tomb.balanceOf(address(this)) - _before;
            }

            tomb.transfer(DEAD, _tombToBurn);
        }
    }

    function swapToTomb(
        IERC20 _token,
        uint256 _amount,
        address[] memory _path
    ) internal {
        _token.approve(address(router), _amount);
        router.swapExactTokensForTokens(
            _amount,
            1,
            _path,
            address(this),
            block.timestamp
        );
    }

    function addAuth(address _addr) public onlyOperator {
        if (_addr == address(0)) revert("_addr is Address zero");
        auth[_addr] = true;
    }

    function updateThreshold(uint256 _newThreshold) external onlyOperator {
        if (_newThreshold < 500000000 gwei) revert("_newThreshold is too low");
        threshold = _newThreshold;
    }
}