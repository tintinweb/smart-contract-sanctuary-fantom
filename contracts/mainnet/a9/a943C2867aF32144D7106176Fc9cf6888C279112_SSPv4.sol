// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ===================== SSP v4 ======================
// ===============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem Gh
// Miko
// MRM

// Reviewer (s)
// Vahid: https://github.com/vahid-dev

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDEIStablecoin.sol";
import "./interfaces/IDEUSToken.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract SSPv4 is Ownable, Pausable {

    address public usdc;
    address public dei;
    address public deus;
    address public native;
    address public minterPool;
    address public deusFtmPair;
    address public ftmUsdcPair;
    uint256 public topBound;
    uint256 public lowerBound;
    address public router;
    uint256 public mintFeeRate;
    uint256 public MINT_FEE_PRECISION = 1e6;
    address[] public path;

    mapping(address => bool) public arbitragers;

    event Buy(uint256 usdcAmount);

    constructor (
        address usdc_,
        address dei_,
        address deus_,
        address native_,
        address deusFtmPair_,
        address ftmUsdcPair_,
        address minterPool_,
        uint256 topBound_,
        uint256 lowerBound_,
        address router_,
        uint256 mintFeeRate_
    ) {
        usdc = usdc_;
        dei = dei_;
        deus = deus_;
        native = native_;
        deusFtmPair = deusFtmPair_;
        ftmUsdcPair = ftmUsdcPair_;
        minterPool = minterPool_;
        topBound = topBound_;
        lowerBound = lowerBound_;
        router = router_;
        mintFeeRate = mintFeeRate_;
        path = [usdc, native, deus];
        IERC20(deus).approve(router, type(uint256).max);
        IERC20(usdc).approve(router, type(uint256).max);
    }

    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        return 0;
    }

    function buyAndBurnDeus(uint256 amountIn, uint256 amountOutMin) external onlyOwner {
        uint256 deusAmount = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountIn, 
            amountOutMin, 
            path,
            address(this), 
            0xf000000000000000000000000000000000000000000000000000000000000000
        )[2];
        IDEUSToken(deus).pool_burn_from(address(this), deusAmount);
    }

    function buyDei(uint256 amountIn) external whenNotPaused {
        require(amountIn <= topBound && amountIn >= lowerBound, "you need to buy in valid range");
        IERC20(usdc).transferFrom(msg.sender, address(this), amountIn);
        uint256 deiCollateralRatio = IDEIStablecoin(dei).global_collateral_ratio();
        uint256 collateralAmount = amountIn * deiCollateralRatio / 1e6;
        IERC20(usdc).transfer(minterPool, collateralAmount);
        uint256 deiAmount = amountIn * 1e12;
        uint256 mintFee = deiAmount * mintFeeRate / MINT_FEE_PRECISION;
        IDEIStablecoin(dei).pool_mint(msg.sender, arbitragers[msg.sender] ? deiAmount : deiAmount - mintFee);
        emit Buy(amountIn);
    }

    function setBound(uint256 topBound_, uint256 lowerBound_) external onlyOwner {
        topBound = topBound_;
        lowerBound = lowerBound_;
    }

    function pause() external onlyOwner {
        super._pause();
    }

    function setMintFeeRate(uint256 mintFeeRate_) external onlyOwner {
        mintFeeRate = mintFeeRate_;
    }

    function setArbitrager(address addr, bool isArbitrager_) external onlyOwner {
        arbitragers[addr] = isArbitrager_;
    }

    function unpause() external onlyOwner {
        super._unpause();
    }

    function withdrawERC20(address token, uint256 amount, address recv) external onlyOwner {
        IERC20(token).transfer(recv, amount);
    }

}

// Dar panahe Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0 <=0.9.0;

interface IDEIStablecoin {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function global_collateral_ratio() external view returns (uint256);
    function dei_pools(address _address) external view returns (bool);
    function dei_pools_array() external view returns (address[] memory);
    function verify_price(bytes32 sighash, bytes[] calldata sigs) external view returns (bool);
    function dei_info(uint256[] memory collat_usd_price) external view returns (uint256, uint256, uint256);
    function getChainID() external view returns (uint256);
    function globalCollateralValue(uint256[] memory collat_usd_price) external view returns (uint256);
    function refreshCollateralRatio(uint deus_price, uint dei_price, uint256 expire_block, bytes[] calldata sigs) external;
    function useGrowthRatio(bool _use_growth_ratio) external;
    function setGrowthRatioBands(uint256 _GR_top_band, uint256 _GR_bottom_band) external;
    function setPriceBands(uint256 _top_band, uint256 _bottom_band) external;
    function activateDIP(bool _activate) external;
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function addPool(address pool_address) external;
    function removePool(address pool_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
    function setOracle(address _oracle) external;
    function setDEIStep(uint256 _new_step) external;
    function setReserveTracker(address _reserve_tracker_address) external;
    function setRefreshCooldown(uint256 _new_cooldown) external;
    function setDEUSAddress(address _deus_address) external;
    function toggleCollateralRatio() external;
}

//Dar panah khoda

interface IDEUSToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function mint(address to, uint256 amount) external;
    function setDEIAddress(address dei_contract_address) external;
    function setNameAndSymbol(string memory _name, string memory _symbol) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function swapExactETHForTokens(
		uint amountOutMin, 
		address[] calldata path, 
		address to, 
		uint deadline
	) external payable returns (uint[] memory amounts);

	function getAmountsIn(
		uint amountOut, 
		address[] memory path
	) external view returns (uint[] memory amounts);

	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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