/**
 *Submitted for verification at FtmScan.com on 2022-08-31
*/

pragma solidity =0.5.16;

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

interface ICDeployer {
	function deployCollateral(address uniswapV2Pair) external returns (address collateral);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IPoolToken {
    /*** Tomb ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    /*** Pool Token ***/

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;
}

contract TombERC20 {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() public {}

    function _setName(string memory _name, string memory _symbol) internal {
        name = _name;
        symbol = _symbol;
        uint256 chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        balanceOf[from] = balanceOf[from].sub(
            value,
            "Tomb: TRANSFER_TOO_HIGH"
        );
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != uint256(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value,
                "Tomb: TRANSFER_NOT_ALLOWED"
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function _checkSignature(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 typehash
    ) internal {
        require(deadline >= block.timestamp, "Tomb: EXPIRED");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            typehash,
                            owner,
                            spender,
                            value,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Tomb: INVALID_SIGNATURE"
        );
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        _checkSignature(
            owner,
            spender,
            value,
            deadline,
            v,
            r,
            s,
            PERMIT_TYPEHASH
        );
        _approve(owner, spender, value);
    }
}

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

interface IBorrowTracker {
	function trackBorrow(address borrower, uint borrowBalance, uint borrowIndex) external;
}

interface IFactory {
	event LendingPoolInitialized(address indexed uniswapV2Pair, address indexed token0, address indexed token1,
		address collateral, address borrowable0, address borrowable1, uint lendingPoolId);
	event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
	event NewAdmin(address oldAdmin, address newAdmin);
	event NewReservesPendingAdmin(address oldReservesPendingAdmin, address newReservesPendingAdmin);
	event NewReservesAdmin(address oldReservesAdmin, address newReservesAdmin);
	event NewReservesManager(address oldReservesManager, address newReservesManager);
	
	function admin() external view returns (address);
	function pendingAdmin() external view returns (address);
	function reservesAdmin() external view returns (address);
	function reservesPendingAdmin() external view returns (address);
	function reservesManager() external view returns (address);

	function getLendingPool(address uniswapV2Pair) external view returns (
		bool initialized, 
		uint24 lendingPoolId, 
		address collateral, 
		address borrowable0, 
		address borrowable1
	);
	function allLendingPools(uint) external view returns (address uniswapV2Pair);
	function allLendingPoolsLength() external view returns (uint);
	
	function bDeployer() external view returns (address);
	function cDeployer() external view returns (address);
	function tombPriceOracle() external view returns (address);

	function createCollateral(address uniswapV2Pair) external returns (address collateral);
	function createBorrowable0(address uniswapV2Pair) external returns (address borrowable0);
	function createBorrowable1(address uniswapV2Pair) external returns (address borrowable1);
	function initializeLendingPool(address uniswapV2Pair) external;

	function _setPendingAdmin(address newPendingAdmin) external;
	function _acceptAdmin() external;
	function _setReservesPendingAdmin(address newPendingAdmin) external;
	function _acceptReservesAdmin() external;
	function _setReservesManager(address newReservesManager) external;
}

interface ITombCallee {
    function tombBorrow(
        address sender,
        address borrower,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function tombRedeem(
        address sender,
        uint256 redeemAmount,
        bytes calldata data
    ) external;
}

interface ICollateral {
    /*** Tomb ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    /*** Pool Token ***/

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /*** Collateral ***/

    function borrowable0() external view returns (address);

    function borrowable1() external view returns (address);

    function tombPriceOracle() external view returns (address);

    function safetyMarginSqrt() external view returns (uint256);

    function liquidationIncentive() external view returns (uint256);

    function getPrices() external returns (uint256 price0, uint256 price1);

    function tokensUnlocked(address from, uint256 value)
        external
        returns (bool);

    function accountLiquidityAmounts(
        address account,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 liquidity, uint256 shortfall);

    function accountLiquidity(address account)
        external
        returns (uint256 liquidity, uint256 shortfall);

    function canBorrow(
        address account,
        address borrowable,
        uint256 accountBorrows
    ) external returns (bool);

    function seize(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 seizeTokens);

    function flashRedeem(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external;

    /*** Collateral Setter ***/

    event NewSafetyMargin(uint256 newSafetyMarginSqrt);
    event NewLiquidationIncentive(uint256 newLiquidationIncentive);

    function SAFETY_MARGIN_SQRT_MIN() external pure returns (uint256);

    function SAFETY_MARGIN_SQRT_MAX() external pure returns (uint256);

    function LIQUIDATION_INCENTIVE_MIN() external pure returns (uint256);

    function LIQUIDATION_INCENTIVE_MAX() external pure returns (uint256);

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _borrowable0,
        address _borrowable1
    ) external;

    function _setSafetyMarginSqrt(uint256 newSafetyMarginSqrt) external;

    function _setLiquidationIncentive(uint256 newLiquidationIncentive) external;
}



interface IBorrowable {
    /*** TOMB ERC20 ***/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    /*** Pool Token ***/

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    function underlying() external view returns (address);

    function factory() external view returns (address);

    function totalBalance() external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function exchangeRate() external returns (uint256);

    function mint(address minter) external returns (uint256 mintTokens);

    function redeem(address redeemer) external returns (uint256 redeemAmount);

    function skim(address to) external;

    function sync() external;

    function _setFactory() external;

    /*** Borrowable ***/

    event BorrowApproval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Borrow(
        address indexed sender,
        address indexed borrower,
        address indexed receiver,
        uint256 borrowAmount,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );
    event Liquidate(
        address indexed sender,
        address indexed borrower,
        address indexed liquidator,
        uint256 seizeTokens,
        uint256 repayAmount,
        uint256 accountBorrowsPrior,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    function BORROW_FEE() external pure returns (uint256);

    function collateral() external view returns (address);

    function reserveFactor() external view returns (uint256);

    function exchangeRateLast() external view returns (uint256);

    function borrowIndex() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function borrowAllowance(address owner, address spender)
        external
        view
        returns (uint256);

    function borrowBalance(address borrower) external view returns (uint256);

    function borrowTracker() external view returns (address);

    function BORROW_PERMIT_TYPEHASH() external pure returns (bytes32);

    function borrowApprove(address spender, uint256 value)
        external
        returns (bool);

    function borrowPermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function borrow(
        address borrower,
        address receiver,
        uint256 borrowAmount,
        bytes calldata data
    ) external;

    function liquidate(address borrower, address liquidator)
        external
        returns (uint256 seizeTokens);

    function trackBorrow(address borrower) external;

    /*** Borrowable Interest Rate Model ***/

    event AccrueInterest(
        uint256 interestAccumulated,
        uint256 borrowIndex,
        uint256 totalBorrows
    );
    event CalculateKink(uint256 kinkRate);
    event CalculateBorrowRate(uint256 borrowRate);

    function KINK_BORROW_RATE_MAX() external pure returns (uint256);

    function KINK_BORROW_RATE_MIN() external pure returns (uint256);

    function KINK_MULTIPLIER() external pure returns (uint256);

    function borrowRate() external view returns (uint256);

    function kinkBorrowRate() external view returns (uint256);

    function kinkUtilizationRate() external view returns (uint256);

    function adjustSpeed() external view returns (uint256);

    function rateUpdateTimestamp() external view returns (uint32);

    function accrualTimestamp() external view returns (uint32);

    function accrueInterest() external;

    /*** Borrowable Setter ***/

    event NewReserveFactor(uint256 newReserveFactor);
    event NewKinkUtilizationRate(uint256 newKinkUtilizationRate);
    event NewAdjustSpeed(uint256 newAdjustSpeed);
    event NewBorrowTracker(address newBorrowTracker);

    function RESERVE_FACTOR_MAX() external pure returns (uint256);

    function KINK_UR_MIN() external pure returns (uint256);

    function KINK_UR_MAX() external pure returns (uint256);

    function ADJUST_SPEED_MIN() external pure returns (uint256);

    function ADJUST_SPEED_MAX() external pure returns (uint256);

    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _collateral
    ) external;

    function _setReserveFactor(uint256 newReserveFactor) external;

    function _setKinkUtilizationRate(uint256 newKinkUtilizationRate) external;

    function _setAdjustSpeed(uint256 newAdjustSpeed) external;

    function _setBorrowTracker(address newBorrowTracker) external;
}

contract CStorage {
	address public borrowable0;
	address public borrowable1;
	address public tombPriceOracle;
	uint public safetyMarginSqrt = 1.58113883e18; //safetyMargin: 250%
	uint public liquidationIncentive = 1.04e18; //4%
}



contract PoolToken is IPoolToken, TombERC20 {
    uint256 internal constant initialExchangeRate = 1e18;
    address public underlying;
    address public factory;
    uint256 public totalBalance;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;

    event Mint(
        address indexed sender,
        address indexed minter,
        uint256 mintAmount,
        uint256 mintTokens
    );
    event Redeem(
        address indexed sender,
        address indexed redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    );
    event Sync(uint256 totalBalance);

    /*** Initialize ***/

    // called once by the factory
    function _setFactory() external {
        require(factory == address(0), "TOMB: FACTORY_ALREADY_SET");
        factory = msg.sender;
    }

    /*** PoolToken ***/

    function _update() internal {
        totalBalance = IERC20(underlying).balanceOf(address(this));
        emit Sync(totalBalance);
    }

    function exchangeRate() public returns (uint256) {
        uint256 _totalSupply = totalSupply; // gas savings
        uint256 _totalBalance = totalBalance; // gas savings
        if (_totalSupply == 0 || _totalBalance == 0) return initialExchangeRate;
        return _totalBalance.mul(1e18).div(_totalSupply);
    }

    // this low-level function should be called from another contract
    function mint(address minter)
        external
        nonReentrant
        update
        returns (uint256 mintTokens)
    {
        uint256 balance = IERC20(underlying).balanceOf(address(this));
        uint256 mintAmount = balance.sub(totalBalance);
        mintTokens = mintAmount.mul(1e18).div(exchangeRate());

        if (totalSupply == 0) {
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            mintTokens = mintTokens.sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        }
        require(mintTokens > 0, "TOMB: MINT_AMOUNT_ZERO");
        _mint(minter, mintTokens);
        emit Mint(msg.sender, minter, mintAmount, mintTokens);
    }

    // this low-level function should be called from another contract
    function redeem(address redeemer)
        external
        nonReentrant
        update
        returns (uint256 redeemAmount)
    {
        uint256 redeemTokens = balanceOf[address(this)];
        redeemAmount = redeemTokens.mul(exchangeRate()).div(1e18);

        require(redeemAmount > 0, "TOMB: REDEEM_AMOUNT_ZERO");
        require(redeemAmount <= totalBalance, "TOMB: INSUFFICIENT_CASH");
        _burn(address(this), redeemTokens);
        _safeTransfer(redeemer, redeemAmount);
        emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);
    }

    // force real balance to match totalBalance
    function skim(address to) external nonReentrant {
        _safeTransfer(
            to,
            IERC20(underlying).balanceOf(address(this)).sub(totalBalance)
        );
    }

    // force totalBalance to match real balance
    function sync() external nonReentrant update {}

    /*** Utilities ***/

    // same safe transfer function used by UniSwapV2 (with fixed underlying)
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));

    function _safeTransfer(address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            underlying.call(abi.encodeWithSelector(SELECTOR, to, amount));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TOMB: TRANSFER_FAILED"
        );
    }

    // prevents a contract from calling itself, directly or indirectly.
    bool internal _notEntered = true;
    modifier nonReentrant() {
        require(_notEntered, "TOMB: REENTERED");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    // update totalBalance with current balance
    modifier update() {
        _;
        _update();
    }
}





contract CSetter is PoolToken, CStorage {
    uint256 public constant SAFETY_MARGIN_SQRT_MIN = 1.00e18; //safetyMargin: 100%
    uint256 public constant SAFETY_MARGIN_SQRT_MAX = 1.58113884e18; //safetyMargin: 250%
    uint256 public constant LIQUIDATION_INCENTIVE_MIN = 1.00e18; //100%
    uint256 public constant LIQUIDATION_INCENTIVE_MAX = 1.05e18; //105%

    event NewSafetyMargin(uint256 newSafetyMarginSqrt);
    event NewLiquidationIncentive(uint256 newLiquidationIncentive);

    // called once by the factory at the time of deployment
    function _initialize(
        string calldata _name,
        string calldata _symbol,
        address _underlying,
        address _borrowable0,
        address _borrowable1
    ) external {
        require(msg.sender == factory, "TOMB: UNAUTHORIZED"); // sufficient check
        _setName(_name, _symbol);
        underlying = _underlying;
        borrowable0 = _borrowable0;
        borrowable1 = _borrowable1;
        tombPriceOracle = IFactory(factory).tombPriceOracle();
    }

    function _setSafetyMarginSqrt(uint256 newSafetyMarginSqrt)
        external
        nonReentrant
    {
        _checkSetting(
            newSafetyMarginSqrt,
            SAFETY_MARGIN_SQRT_MIN,
            SAFETY_MARGIN_SQRT_MAX
        );
        safetyMarginSqrt = newSafetyMarginSqrt;
        emit NewSafetyMargin(newSafetyMarginSqrt);
    }

    function _setLiquidationIncentive(uint256 newLiquidationIncentive)
        external
        nonReentrant
    {
        _checkSetting(
            newLiquidationIncentive,
            LIQUIDATION_INCENTIVE_MIN,
            LIQUIDATION_INCENTIVE_MAX
        );
        liquidationIncentive = newLiquidationIncentive;
        emit NewLiquidationIncentive(newLiquidationIncentive);
    }

    function _checkSetting(
        uint256 parameter,
        uint256 min,
        uint256 max
    ) internal view {
        _checkAdmin();
        require(parameter >= min, "TOMB: INVALID_SETTING");
        require(parameter <= max, "TOMB: INVALID_SETTING");
    }

    function _checkAdmin() internal view {
        require(msg.sender == IFactory(factory).admin(), "TOMB: UNAUTHORIZED");
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
	
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);
}

interface ITombPriceOracle {
    event PriceUpdate(
        address indexed pair,
        uint256 priceCumulative,
        uint32 blockTimestamp,
        bool latestIsSlotA
    );

    function MIN_T() external pure returns (uint32);

    function getPair(address uniswapV2Pair)
        external
        view
        returns (
            uint256 priceCumulativeSlotA,
            uint256 priceCumulativeSlotB,
            uint32 lastUpdateSlotA,
            uint32 lastUpdateSlotB,
            bool latestIsSlotA,
            bool initialized
        );

    function initialize(address uniswapV2Pair) external;

    function getResult(address uniswapV2Pair)
        external
        returns (uint224 price, uint32 T);
}

contract Collateral is ICollateral, PoolToken, CStorage, CSetter {
    using UQ112x112 for uint224;

    constructor() public {}

    /*** Collateralization Model ***/

    // returns the prices of borrowable0's and borrowable1's underlyings with collateral's underlying as denom
    function getPrices() public returns (uint256 price0, uint256 price1) {
        (uint224 twapPrice112x112, ) =
            ITombPriceOracle(tombPriceOracle).getResult(underlying);
        (uint112 reserve0, uint112 reserve1, ) =
            IUniswapV2Pair(underlying).getReserves();
        uint256 collateralTotalSupply =
            IUniswapV2Pair(underlying).totalSupply();

        uint224 currentPrice112x112 =
            UQ112x112.encode(reserve1).uqdiv(reserve0);
        uint256 adjustmentSquared =
            uint256(twapPrice112x112).mul(2**32).div(currentPrice112x112);
        uint256 adjustment = Math.sqrt(adjustmentSquared.mul(2**32));

        uint256 currentBorrowable0Price =
            uint256(collateralTotalSupply).mul(1e18).div(reserve0 * 2);
        uint256 currentBorrowable1Price =
            uint256(collateralTotalSupply).mul(1e18).div(reserve1 * 2);

        price0 = currentBorrowable0Price.mul(adjustment).div(2**32);
        price1 = currentBorrowable1Price.mul(2**32).div(adjustment);

        /*
         * Price calculation errors may happen in some edge pairs where
         * reserve0 / reserve1 is close to 2**112 or 1/2**112
         * We're going to prevent users from using pairs at risk from the UI
         */
        require(price0 > 100, "Tomb: PRICE_CALCULATION_ERROR");
        require(price1 > 100, "Tomb: PRICE_CALCULATION_ERROR");
    }

    // returns liquidity in  collateral's underlying
    function _calculateLiquidity(
        uint256 amountCollateral,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 liquidity, uint256 shortfall) {
        uint256 _safetyMarginSqrt = safetyMarginSqrt;
        (uint256 price0, uint256 price1) = getPrices();

        uint256 a = amount0.mul(price0).div(1e18);
        uint256 b = amount1.mul(price1).div(1e18);
        if (a < b) (a, b) = (b, a);
        a = a.mul(_safetyMarginSqrt).div(1e18);
        b = b.mul(1e18).div(_safetyMarginSqrt);
        uint256 collateralNeeded = a.add(b).mul(liquidationIncentive).div(1e18);

        if (amountCollateral >= collateralNeeded) {
            return (amountCollateral - collateralNeeded, 0);
        } else {
            return (0, collateralNeeded - amountCollateral);
        }
    }

    /*** ERC20 ***/

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(tokensUnlocked(from, value), "Tomb: INSUFFICIENT_LIQUIDITY");
        super._transfer(from, to, value);
    }

    function tokensUnlocked(address from, uint256 value) public returns (bool) {
        uint256 _balance = balanceOf[from];
        if (value > _balance) return false;
        uint256 finalBalance = _balance - value;
        uint256 amountCollateral = finalBalance.mul(exchangeRate()).div(1e18);
        uint256 amount0 = IBorrowable(borrowable0).borrowBalance(from);
        uint256 amount1 = IBorrowable(borrowable1).borrowBalance(from);
        (, uint256 shortfall) =
            _calculateLiquidity(amountCollateral, amount0, amount1);
        return shortfall == 0;
    }

    /*** Collateral ***/

    function accountLiquidityAmounts(
        address borrower,
        uint256 amount0,
        uint256 amount1
    ) public returns (uint256 liquidity, uint256 shortfall) {
        if (amount0 == uint256(-1))
            amount0 = IBorrowable(borrowable0).borrowBalance(borrower);
        if (amount1 == uint256(-1))
            amount1 = IBorrowable(borrowable1).borrowBalance(borrower);
        uint256 amountCollateral =
            balanceOf[borrower].mul(exchangeRate()).div(1e18);
        return _calculateLiquidity(amountCollateral, amount0, amount1);
    }

    function accountLiquidity(address borrower)
        public
        returns (uint256 liquidity, uint256 shortfall)
    {
        return accountLiquidityAmounts(borrower, uint256(-1), uint256(-1));
    }

    function canBorrow(
        address borrower,
        address borrowable,
        uint256 accountBorrows
    ) public returns (bool) {
        address _borrowable0 = borrowable0;
        address _borrowable1 = borrowable1;
        require(
            borrowable == _borrowable0 || borrowable == _borrowable1,
            "Tomb: INVALID_BORROWABLE"
        );
        uint256 amount0 =
            borrowable == _borrowable0 ? accountBorrows : uint256(-1);
        uint256 amount1 =
            borrowable == _borrowable1 ? accountBorrows : uint256(-1);
        (, uint256 shortfall) =
            accountLiquidityAmounts(borrower, amount0, amount1);
        return shortfall == 0;
    }

    // this function must be called from borrowable0 or borrowable1
    function seize(
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256 seizeTokens) {
        require(
            msg.sender == borrowable0 || msg.sender == borrowable1,
            "Tomb: UNAUTHORIZED"
        );

        (, uint256 shortfall) = accountLiquidity(borrower);
        require(shortfall > 0, "Tomb: INSUFFICIENT_SHORTFALL");

        uint256 price;
        if (msg.sender == borrowable0) (price, ) = getPrices();
        else (, price) = getPrices();

        seizeTokens = repayAmount
            .mul(liquidationIncentive)
            .div(1e18)
            .mul(price)
            .div(exchangeRate());

        balanceOf[borrower] = balanceOf[borrower].sub(
            seizeTokens,
            "Tomb: LIQUIDATING_TOO_MUCH"
        );
        balanceOf[liquidator] = balanceOf[liquidator].add(seizeTokens);
        emit Transfer(borrower, liquidator, seizeTokens);
    }

    // this low-level function should be called from another contract
    function flashRedeem(
        address redeemer,
        uint256 redeemAmount,
        bytes calldata data
    ) external nonReentrant update {
        require(redeemAmount <= totalBalance, "Tomb: INSUFFICIENT_CASH");

        // optimistically transfer funds
        _safeTransfer(redeemer, redeemAmount);
        if (data.length > 0)
            ITombCallee(redeemer).tombRedeem(msg.sender, redeemAmount, data);

        uint256 redeemTokens = balanceOf[address(this)];
        uint256 declaredRedeemTokens =
            redeemAmount.mul(1e18).div(exchangeRate()).add(1); // rounded up
        require(
            redeemTokens >= declaredRedeemTokens,
            "Tomb: INSUFFICIENT_REDEEM_TOKENS"
        );

        _burn(address(this), redeemTokens);
        emit Redeem(msg.sender, redeemer, redeemAmount, redeemTokens);
    }
}

contract CDeployer is ICDeployer {
	constructor () public {}

    bytes32 public constant INIT_CODE = keccak256(abi.encodePacked(type(Collateral).creationCode));
	
	function deployCollateral(address uniswapV2Pair) external returns (address collateral) {
		bytes memory bytecode = type(Collateral).creationCode;
		bytes32 salt = keccak256(abi.encodePacked(msg.sender, uniswapV2Pair));
		assembly {
			collateral := create2(0, add(bytecode, 32), mload(bytecode), salt)
		}
	}
}