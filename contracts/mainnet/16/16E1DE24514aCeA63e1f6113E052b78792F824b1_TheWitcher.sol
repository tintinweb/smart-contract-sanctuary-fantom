/**
 *Submitted for verification at FtmScan.com on 2022-03-31
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: contracts/TransferHelper.sol

// pragma solidity 0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}


// Root file: contracts/TheWitcher.sol

pragma solidity 0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "contracts/TransferHelper.sol";

interface IUniswapFactory {
    function getPair(address _token0, address _token1) external view returns (address);
}

interface IUniswapRouter {
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
}

interface IMasterchef {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

interface IStaking {
    function borrow(uint256 _amount) external;
    function distribute(uint256 _amount) external;
}

interface ICalculator {
    function getLiquidityReserve(address _tokenA, address _tokenB)
        external
        view
        returns (uint256 reserveA_, uint256 reserveB_);
}

interface ILending {
    function distribute(uint256 _amount) external;
}

// @dev The witcher gets underlying from lending + vault to provide liquidity.
// It collects yield an convert to underlying tokens
contract TheWitcher is Ownable {
    using SafeMath for uint256;

    struct PoolInfo {
        address token; // underlying
        address lpToken; // liquidity token
        uint256 farmId; // masterchef PID
    }

    // AMM
    address public immutable yieldToken;
    address public immutable masterchef;
    address public immutable swapRouter;

    // staking contract will receive ETH when yield converted into underlying + ETH
    address public staking;
    // treasury receive development and dao fee
    address public treasury;
    // calculator helpers
    address public calculator;

    uint256 public treasuryRate;
    uint256 public underlyingYieldRate;
    uint256 public collateralYieldRate;

    address[] public poolList;
    mapping(address => PoolInfo) public poolInfo;

    // events
    event FarmDeposited(
        uint256 indexed farmId,
        uint256 indexed lpAmount,
        uint256 underlyingAmount,
        uint256 collateralAmount
    );
    event FarmHarvested(
        uint256 indexed farmId,
        uint256 indexed yieldAmount,
        uint256 underlyingAmount,
        uint256 collateralAmount
    );
    event FarmWithdrawn(
        uint256 indexed farmId,
        uint256 indexed lpAmount,
        uint256 underlyingAmount,
        uint256 collateralAmount
    );

    constructor(
        address _staking,
        address _calculator,
        address _yieldToken,
        address _masterchef,
        address _swapRouter
    ) {
        treasury = msg.sender;
        staking = _staking;
        calculator = _calculator;

        treasuryRate = 1000; // 10%
        underlyingYieldRate = 6000; // 60%
        collateralYieldRate = 3000; // 30%

        // AMM
        yieldToken = _yieldToken;
        masterchef = _masterchef;
        swapRouter = _swapRouter;
    }

    // @dev We need fallback functions to receive ETH in three cases:
    // 1. When withdraw ETH from vault contract
    // 2. When remove liquidity from AMM liquidity pool
    // 3. When convert yield to ETH
    receive() external payable {}

    fallback() external payable {}

    // @dev Get number of available lending pools
    function poolCount() public view returns (uint256) {
        return poolList.length;
    }

    // @dev Get number of staked LP token of a lending pool
    function balance(address _pool) public view returns (uint256) {
        (uint256 amount, ) = IMasterchef(masterchef).userInfo(poolInfo[_pool].farmId, address(this));
        return amount;
    }

    // @dev Check available underlying amount to deposit into farm
    function available(address _pool) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pool];

        (uint256 underlyingReserve, uint256 collateralReserve) = ICalculator(calculator).getLiquidityReserve(
            pool.token,
            IUniswapRouter(swapRouter).WETH()
        );

        return address(staking).balance.mul(underlyingReserve).div(collateralReserve);
    }

    // @dev Get total underlying reserve of lending pool which are staking in farms
    function reserve(address _pool) public view returns (uint256 underlying_, uint256 collateral_) {
        PoolInfo memory pool = poolInfo[_pool];

        (uint256 underlyingReserve, uint256 collateralReserve) = ICalculator(calculator).getLiquidityReserve(
            pool.token,
            IUniswapRouter(swapRouter).WETH()
        );

        uint256 lpBalance = balance(_pool);
        underlying_ = lpBalance.mul(underlyingReserve).div(IERC20(pool.lpToken).totalSupply());
        collateral_ = lpBalance.mul(collateralReserve).div(IERC20(pool.lpToken).totalSupply());
    }

    // @dev Lending pools request to deposit underlying
    function deposit(uint256 _amount) external {
        require(poolInfo[msg.sender].token != address(0), "TheWitcher: only pool allowed");

        TransferHelper.safeTransferFrom(poolInfo[msg.sender].token, msg.sender, address(this), _amount);

        // convert underlying + vault -> lp
        // deposit lp into farm
        _depositFarm(msg.sender);

        // collect farm yield
        // convert yield to underlying + vault
        _harvestFarm(msg.sender);
    }

    // @dev Lending pools request to withdraw underlying
    function withdraw(uint256 _amount) external {
        require(poolInfo[msg.sender].token != address(0), "TheWitcher: only pool allowed");

        // convert lp -> underlying + vault
        // transfer underlying to lending
        // transfer vault back to vault vault
        _withdrawFarm(msg.sender, _amount);

        // collect farm yield
        // convert yield to underlying + vault
        _harvestFarm(msg.sender);
    }

    // @dev Lending pool withdraw all underlying, use emergency withdrawal
    function withdrawAll() external {
        require(poolInfo[msg.sender].token != address(0), "TheWitcher: only pool allowed");

        // emergency withdraw all assets from farm
        _withdrawFarmAll(msg.sender);
    }

    // @dev Admin grant permission for a new lending pool. Make sure the correct contract address
    function addPool(
        address _poolAddress,
        address _token,
        uint256 _farmId
    ) external onlyOwner {
        require(poolInfo[_poolAddress].token == address(0), "TheWitcher: duplicated pool");

        address lpToken = IUniswapFactory(IUniswapRouter(swapRouter).factory()).getPair(
            _token,
            IUniswapRouter(swapRouter).WETH()
        );
        require(lpToken != address(0), "TheWitcher: non-existed lp pool");

        (address _lpToken, , , ) = IMasterchef(masterchef).poolInfo(_farmId);
        require(lpToken == _lpToken, "TheWitcher: invalid farm pid");

        poolList.push(_poolAddress);
        poolInfo[_poolAddress] = PoolInfo({token: _token, lpToken: lpToken, farmId: _farmId});
    }

    // @dev Treasury set new treasury contract
    function setTreasury(address _treasury) external {
        require(msg.sender == treasury, "TheWitcher: only treasury");
        treasury = _treasury;
    }

    // @dev Get underlying from lending contract and withdraw ETH from vault to add liquidity
    function _depositFarm(address _pool) private {
        PoolInfo memory pool = poolInfo[_pool];

        // calculate amount of vault needs for underlying balance
        // always deposit total underlying balance of the witcher
        (uint256 underlyingReserve, uint256 collateralReserve) = ICalculator(calculator).getLiquidityReserve(
            pool.token,
            IUniswapRouter(swapRouter).WETH()
        );
        uint256 underlyingAmount = IERC20(pool.token).balanceOf(address(this));
        uint256 collateralAmount = underlyingAmount.mul(collateralReserve).div(underlyingReserve);

        // check underlying overflow
        if (IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(staking) < collateralAmount) {
            underlyingAmount = underlyingAmount.mul(IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(staking)).div(collateralAmount);
            collateralAmount = IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(staking);
        }

        if (collateralAmount > 0) {
            IStaking(staking).borrow(collateralAmount);

            IERC20(pool.token).approve(swapRouter, 0);
            IERC20(pool.token).approve(swapRouter, underlyingAmount);
            IERC20(IUniswapRouter(swapRouter).WETH()).approve(swapRouter, 0);
            IERC20(IUniswapRouter(swapRouter).WETH()).approve(swapRouter, collateralAmount);

            IUniswapRouter(swapRouter).addLiquidity(
                pool.token,
                IUniswapRouter(swapRouter).WETH(),
                underlyingAmount,
                collateralAmount,
                0,
                0,
                address(this),
                block.timestamp
            );

            uint256 lpAmount = IERC20(pool.lpToken).balanceOf(address(this));
            IERC20(pool.lpToken).approve(masterchef, 0);
            IERC20(pool.lpToken).approve(masterchef, lpAmount);

            IMasterchef(masterchef).deposit(pool.farmId, lpAmount);

            emit FarmDeposited(pool.farmId, lpAmount, underlyingAmount, collateralAmount);
        }

        // refund dust
        TransferHelper.safeTransfer(pool.token, _pool, IERC20(pool.token).balanceOf(address(this)));
        TransferHelper.safeTransfer(IUniswapRouter(swapRouter).WETH(), staking, IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(address(this)));
    }

    // @dev Convert yield token to underlying and ETH.
    // Send underlying to lending contract, send ETH to staking contract
    function _harvestFarm(address _pool) private {
        uint256 yieldBalance = IERC20(yieldToken).balanceOf(address(this));

        if (yieldBalance > 0) {
            PoolInfo memory pool = poolInfo[_pool];
            uint256 underlyingYieldAmount = yieldBalance.mul(underlyingYieldRate).div(10000);
            uint256 collateralYieldAmount = yieldBalance.mul(collateralYieldRate).div(10000);
            uint256 treasuryFeeAmount = yieldBalance.sub(underlyingYieldAmount).sub(collateralYieldAmount);

            IERC20(yieldToken).approve(swapRouter, 0);
            IERC20(yieldToken).approve(swapRouter, yieldBalance);

            // swap yield -> underlying
            address[] memory path1 = new address[](3);
            (path1[0], path1[1], path1[2]) = (yieldToken, IUniswapRouter(swapRouter).WETH(), pool.token);
            IUniswapRouter(swapRouter).swapExactTokensForTokens(
                underlyingYieldAmount.add(treasuryFeeAmount),
                0,
                path1,
                address(this),
                block.timestamp
            );
            uint256 underlyingReceiveAmount = IERC20(pool.token).balanceOf(address(this));
            uint256 forTreasuryAmount = underlyingReceiveAmount.mul(1000).div(7000);
            TransferHelper.safeTransfer(pool.token, treasury, forTreasuryAmount);
            IERC20(pool.token).approve(_pool, 0);
            IERC20(pool.token).approve(_pool, underlyingReceiveAmount);
            ILending(_pool).distribute(IERC20(pool.token).balanceOf(address(this)));

            // swap yield -> WETH
            address[] memory path2 = new address[](2);
            (path2[0], path2[1]) = (yieldToken, IUniswapRouter(swapRouter).WETH());
            IUniswapRouter(swapRouter).swapExactTokensForTokens(
                collateralYieldAmount,
                0,
                path2,
                address(this),
                block.timestamp
            );

            uint256 collateralReceiveAmount = IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(address(this));

            emit FarmHarvested(
                pool.farmId,
                yieldBalance,
                underlyingReceiveAmount.mul(6000).div(7000),
                collateralReceiveAmount
            );
            IERC20(IUniswapRouter(swapRouter).WETH()).approve(staking, 0);
            IERC20(IUniswapRouter(swapRouter).WETH()).approve(staking, collateralReceiveAmount);
            IStaking(staking).distribute(collateralReceiveAmount);
        }
    }

    // @dev Convert LP token to underlying and ETH.
    // Send underlying to lending contract,  send ETH to vault contract
    function _withdrawFarm(address _pool, uint256 _amount) private {
        PoolInfo memory pool = poolInfo[_pool];

        // make sure no overflow LP amount
        (uint256 underlyingReserve, ) = reserve(_pool);
        _amount = Math.min(_amount, underlyingReserve);
        uint256 lpWithdrawAmount = _amount.mul(balance(_pool)).div(underlyingReserve);

        IMasterchef(masterchef).withdraw(pool.farmId, lpWithdrawAmount);
        IERC20(pool.lpToken).approve(swapRouter, 0);
        IERC20(pool.lpToken).approve(swapRouter, lpWithdrawAmount);
        IUniswapRouter(swapRouter).removeLiquidity(
            pool.token,
            IUniswapRouter(swapRouter).WETH(),
            lpWithdrawAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit FarmWithdrawn(
            pool.farmId,
            lpWithdrawAmount,
            IERC20(pool.token).balanceOf(address(this)),
            IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(address(this))
        );

        TransferHelper.safeTransfer(pool.token, _pool, IERC20(pool.token).balanceOf(address(this)));
        TransferHelper.safeTransfer(IUniswapRouter(swapRouter).WETH(), staking, IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(address(this)));
    }

    // @dev Withdraw all underlying tokens from farm, don't care about yield
    function _withdrawFarmAll(address _pool) private {
        PoolInfo memory pool = poolInfo[_pool];
        IMasterchef(masterchef).emergencyWithdraw(pool.farmId);

        uint256 lpWithdrawAmount = IERC20(pool.lpToken).balanceOf(address(this));
        IERC20(pool.lpToken).approve(swapRouter, 0);
        IERC20(pool.lpToken).approve(swapRouter, lpWithdrawAmount);
        IUniswapRouter(swapRouter).removeLiquidity(
            pool.token,
                IUniswapRouter(swapRouter).WETH(),
            lpWithdrawAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        emit FarmWithdrawn(
            pool.farmId,
            lpWithdrawAmount,
            IERC20(pool.token).balanceOf(address(this)),
            address(this).balance
        );

        TransferHelper.safeTransfer(pool.token, _pool, IERC20(pool.token).balanceOf(address(this)));
        TransferHelper.safeTransfer(IUniswapRouter(swapRouter).WETH(), staking, IERC20(IUniswapRouter(swapRouter).WETH()).balanceOf(address(this)));
    }
}