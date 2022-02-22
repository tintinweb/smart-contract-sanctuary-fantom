// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../shared/libraries/SafeMath.sol";
import "../shared/interfaces/IBond.sol";
import "../shared/interfaces/IsMVD.sol";
import "../shared/interfaces/IgMVD.sol";
import "../shared/interfaces/IDistributor.sol";
import "../shared/interfaces/IStaking.sol";
import "../shared/types/MetaVaultAC.sol";
import "../shared/libraries/SafeERC20.sol";

interface IPriceHelperV2 {
    function adjustPrice(address bond, uint256 percent) external;
}

interface IUniV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract BondPriceStrategy is MetaVaultAC {
    using SafeMath for uint256;

    IPriceHelperV2 public helper;
    address public mvDdai;
    IsMVD public sMVD;
    IStaking public staking;

    uint256 public additionalLp11MinDiscount; //100 = 1%
    uint256 public additionalLp11MaxDiscount;

    uint256 public min44Discount;
    uint256 public max44Discount;

    uint256 public additionalAsset11MinDiscount;
    uint256 public additionalAsset11MaxDiscount;

    uint256 public adjustmentBlockGap;

    mapping(address => bool) public executors;

    mapping(address => TYPES) public bondTypes;
    mapping(address => uint256) public usdPriceDecimals;
    mapping(address => uint256) public lastAdjustBlockNumbers;
    address[] public bonds;
    mapping(address => uint256) public perBondDiscounts;

    address public mvd;

    constructor(address _authority) MetaVaultAC(IMetaVaultAuthority(_authority)) {}

    function setLp11(uint256 min, uint256 max) external onlyGovernor {
        require(min <= 500 && max <= 1000, "additional disccount can't be more than 5%-10%");
        additionalLp11MinDiscount = min;
        additionalLp11MaxDiscount = max;
    }

    function setAsset11(uint256 min, uint256 max) external onlyGovernor {
        require(min <= 500 && max <= 1000, "additional disccount can't be more than 5%-10%");
        additionalAsset11MinDiscount = min;
        additionalAsset11MaxDiscount = max;
    }

    function setAll44(uint256 min, uint256 max) external onlyGovernor {
        require(min <= 500 && max <= 1000, "additional disccount can't be more than 5%-10%");
        min44Discount = min;
        max44Discount = max;
    }

    function setHelper(address _helper) external onlyGovernor {
        require(_helper != address(0));
        helper = IPriceHelperV2(_helper);
    }

    function setMvdDai(address _mvdDai) external onlyGovernor {
        require(_mvdDai != address(0));
        mvDdai = _mvdDai;
    }

    function setSMVD(address _sMVD) external onlyGovernor {
        require(_sMVD != address(0));
        sMVD = IsMVD(_sMVD);
    }

    function setStaking(address _staking) external onlyGovernor {
        require(_staking != address(0));
        staking = IStaking(_staking);
    }

    function setMVD(address _mvd) external onlyGovernor {
        require(_mvd != address(0));
        mvd = _mvd;
    }

    function setAdjustmentBlockGap(uint256 _adjustmentBlockGap) external onlyGovernor {
        require(_adjustmentBlockGap >= 600 && _adjustmentBlockGap <= 28800);
        adjustmentBlockGap = _adjustmentBlockGap;
    }

    function addExecutor(address executor) external onlyGovernor {
        executors[executor] = true;
    }

    function removeExecutor(address executor) external onlyGovernor {
        delete executors[executor];
    }

    enum TYPES {
        NOTYPE,
        ASSET11,
        ASSET44,
        LP11,
        LP44
    }

    function addBond(
        address bond,
        TYPES bondType,
        uint256 usdPriceDecimal
    ) external onlyGovernor {
        require(bondType == TYPES.ASSET11 || bondType == TYPES.ASSET44 || bondType == TYPES.LP11 || bondType == TYPES.LP44, "incorrect bond type");
        for (uint256 i = 0; i < bonds.length; i++) {
            if (bonds[i] == bond) return;
        }
        bonds.push(bond);
        bondTypes[bond] = bondType;
        usdPriceDecimals[bond] = usdPriceDecimal;
        lastAdjustBlockNumbers[bond] = block.number;
    }

    function removeBond(address bond) external onlyGovernor {
        for (uint256 i = 0; i < bonds.length; i++) {
            if (bonds[i] == bond) {
                bonds[i] = address(0);
                delete bondTypes[bond];
                delete usdPriceDecimals[bond];
                delete lastAdjustBlockNumbers[bond];
                delete perBondDiscounts[bond];
                return;
            }
        }
    }

    function setBondSpecificDiscount(address bond, uint256 discount) external onlyGovernor {
        require(discount <= 200, "per bond discount can't be more than 2%");
        require(bondTypes[bond] != TYPES.NOTYPE, "not a bond under strategy");
        perBondDiscounts[bond] = discount;
    }

    function runPriceStrategy() external {
        require(executors[msg.sender] == true, "not authorized to run strategy");
        uint256 mvdPrice = getPrice(mvDdai); //$220 = 22000
        uint256 roi5day = getRoiForDays(5); //2% = 200
        for (uint256 i = 0; i < bonds.length; i++) {
            address bond = bonds[i];
            if (bond != address(0) && lastAdjustBlockNumbers[bond] + adjustmentBlockGap < block.number) {
                executeStrategy(bond, mvdPrice, roi5day);
                lastAdjustBlockNumbers[bond] = block.number;
            }
        }
    }

    function runSinglePriceStrategy(uint256 i) external {
        require(executors[msg.sender] == true, "not authorized to run strategy");
        address bond = bonds[i];
        require(bond != address(0), "bond not found");
        uint256 mvdPrice = getPrice(mvDdai); //$220 = 22000
        uint256 roi5day = getRoiForDays(5); //2% = 200
        if (lastAdjustBlockNumbers[bond] + adjustmentBlockGap < block.number) {
            executeStrategy(bond, mvdPrice, roi5day);
            lastAdjustBlockNumbers[bond] = block.number;
        }
    }

    function getBondPriceUSD(address bond) public view returns (uint256) {
        return IBond(bond).bondPriceInUSD();
    }

    function getBondPrice(address bond) public view returns (uint256) {
        return getBondPriceUSD(bond).mul(100).div(10**usdPriceDecimals[bond]);
    }

    function executeStrategy(
        address bond,
        uint256 mvdPrice,
        uint256 roi5day
    ) internal {
        uint256 percent = calcPercentage(bondTypes[bond], mvdPrice, getBondPrice(bond), roi5day, perBondDiscounts[bond]);
        if (percent > 11000) helper.adjustPrice(bond, 11000);
        else if (percent < 9000) helper.adjustPrice(bond, 9000);
        else if (percent >= 10100 || percent <= 9900) helper.adjustPrice(bond, percent);
    }

    function calcPercentage(
        TYPES bondType,
        uint256 mvdPrice,
        uint256 bondPrice,
        uint256 roi5day,
        uint256 perBondDiscount
    ) public view returns (uint256) {
        uint256 upper = bondPrice;
        uint256 lower = bondPrice;
        if (bondType == TYPES.LP44 || bondType == TYPES.ASSET44) {
            upper = mvdPrice.mul(10000).div(uint256(10000).add(min44Discount).add(perBondDiscount));
            lower = mvdPrice.mul(10000).div(uint256(10000).add(max44Discount).add(perBondDiscount));
        } else if (bondType == TYPES.LP11) {
            upper = mvdPrice.mul(10000).div(uint256(10000).add(roi5day).add(additionalLp11MinDiscount).add(perBondDiscount));
            lower = mvdPrice.mul(10000).div(uint256(10000).add(roi5day).add(additionalLp11MaxDiscount).add(perBondDiscount));
        } else if (bondType == TYPES.ASSET11) {
            upper = mvdPrice.mul(10000).div(uint256(10000).add(roi5day).add(additionalAsset11MinDiscount).add(perBondDiscount));
            lower = mvdPrice.mul(10000).div(uint256(10000).add(roi5day).add(additionalAsset11MaxDiscount).add(perBondDiscount));
        }
        uint256 targetPrice = bondPrice;
        if (bondPrice > upper) targetPrice = upper;
        else if (bondPrice < lower) targetPrice = lower;
        uint256 percentage = targetPrice.mul(10000).div(bondPrice);
        return percentage;
    }

    function getRoiForDays(uint256 numberOfDays) public view returns (uint256) {
        require(numberOfDays > 0);
        uint256 circulating = sMVD.circulatingSupply();
        uint256 distribute = 0;
        (, , , distribute) = staking.epoch();
        if (distribute == 0) return 0;
        uint256 precision = 1e6;
        uint256 epochBase = distribute.mul(precision).div(circulating).add(precision);
        uint256 dayBase = epochBase.mul(epochBase).mul(epochBase).div(precision * precision);
        uint256 total = dayBase;
        for (uint256 i = 0; i < numberOfDays - 1; i++) {
            total = total.mul(dayBase).div(precision);
        }
        return total.sub(precision).div(100);
    }

    function getPrice(address _mvDdai) public view returns (uint256) {
        uint112 _reserve0 = 0;
        uint112 _reserve1 = 0;
        (_reserve0, _reserve1, ) = IUniV2Pair(_mvDdai).getReserves();
        uint256 reserve0 = uint256(_reserve0);
        uint256 reserve1 = uint256(_reserve1);
        uint256 decimals0 = uint256(IERC20(IUniV2Pair(_mvDdai).token0()).decimals());
        uint256 decimals1 = uint256(IERC20(IUniV2Pair(_mvDdai).token1()).decimals());
        if (IUniV2Pair(_mvDdai).token0() == mvd) return reserve1.mul(10**decimals0).div(reserve0).div(10**(decimals1.sub(2)));
        //$220 = 22000
        else return reserve0.mul(10**decimals1).div(reserve1).div(10**(decimals0.sub(2))); //$220 = 22000
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IBond {
    function initializeBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _fee,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external;

    function totalDebt() external view returns (uint256);

    function isLiquidityBond() external view returns (bool);

    function bondPrice() external view returns (uint256);

    function bondPriceInUSD() external view returns (uint256 price_);

    function redeem(address _recipient, bool _stake) external returns (uint256);

    function pendingPayoutFor(address _depositor) external view returns (uint256 pendingPayout_);

    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor
    ) external returns (uint256);

    function principle() external view returns (address);

    function terms()
        external
        view
        returns (
            uint256 controlVariable, // scaling variable for price
            uint256 vestingTerm, // in blocks
            uint256 minimumPrice, // vs principle value
            uint256 maxPayout, // in thousandths of a %. i.e. 500 = 0.5%
            uint256 fee, // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
            uint256 maxDebt // 9 decimal debt ratio, max % total supply created as debt
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IsMVD is IERC20 {
    function rebase(uint256 mvdProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(uint256 amount, address debtor, bool add ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IgMVD is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;

    function rebase() external;

    function epoch()
        external
        view
        returns (
            uint256 length,
            uint256 number,
            uint256 endBlock,
            uint256 distribute
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/IMetaVaultAuthority.sol";

abstract contract MetaVaultAC {
    IMetaVaultAuthority public authority;

    event AuthorityUpdated(IMetaVaultAuthority indexed authority);

    constructor(IMetaVaultAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), "MetavaultAC: caller is not the Governer");
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), "MetavaultAC: caller is not the Policy");
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), "MetavaultAC: caller is not the Vault");
        _;
    }

    function setAuthority(IMetaVaultAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMetaVaultAuthority {
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    // function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    //     require(address(this).balance >= value, "Address: insufficient balance for call");
    //     return _functionCallWithValue(target, data, value, errorMessage);
    // }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = "0";
        _addr[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}