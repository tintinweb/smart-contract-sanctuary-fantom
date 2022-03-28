// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeMath.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "IERC20.sol";
import "IERC20.sol";

interface IStrategy {
    function vault() external view returns (address);
    function want() external view returns (IERC20);
    function beforeDeposit() external;
    function deposit() external;
    function withdraw(uint256) external;
    function balanceOf() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function harvest() external;
    function retireStrat() external;
    function panic() external;
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
    function unirouter() external view returns (address);
    function setStrategist(address _strategist) external;
}

interface IVault is IERC20 {
    function deposit(uint256) external;
    function depositAll() external;
    function withdraw(uint256) external;
    function withdrawAll() external;
    function getPricePerFullShare() external view returns (uint256);
    function upgradeStrat() external;
    function balance() external view returns (uint256);
    function strategy() external view returns (IStrategy);
    function getInterestRate() external view returns (uint256);
    function getLTV() external view returns (uint256);
    function getLnToken() external view returns (ILnToken);
}

interface IBorrow {
    function borrow(
        uint256 _amount, 
        uint256 _hostageAmt,
        uint256 _hostageBalance, 
        address _vault, 
        uint256 _existingDebt
        ) external view returns (uint256 newBorrowedAmount, uint256 newHostageAmt, uint256 newBorrowTime);

        function repay(
        uint256 _amount, 
        uint256 _existingDebt
        ) external view returns (uint256 borrowedAmount, uint256 borrowTime);

        function wtithdraw(
        uint256 _withdrawAmount,
        address _vault,
        uint256 _hostageBalance,
        uint256 _existingDebt
    ) external view returns (uint256 newHostageBalance, uint256 newBorrowTime);

    function calculateLTV(
        uint256 _amount, 
        uint256 _existingDebt, 
        uint256 _hostageAmt, 
        uint256 _hostageBalance, 
        IVault _ibToken
        ) external view returns (uint256);
}

interface ILnToken {
    /**
     * @dev
     * mint LnToken to a bank.
     */
    function mintToBank(address _to, uint256 _amount) external;

    /**
     * @dev
     * set the bank address to valid or invalid. 
     */
    function setValidBank(address _bank, bool _in) external;

    /**
     * @dev
     * A safe way to send LnToken between banks.
     * Ensured the sender or recipient is a owner bank.
     */
    function sendToBank(address _to, uint256 _amount) external;
    
    /**
     * @dev
     * burn LnToken from a address.
     */
    function burn(uint256 _amount) external;

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

}

/**
 * @dev
 * Bank contract will mint LnUSD for Vault to borrow.
 * Bank contract will keep track of Vault's debt.
 * When Vault repay LnUSD, Bank will calculate the interest owed.
 *
 * Only 1 valid bank exist at anytime for a lnToken. 
 * Can have many vaults and many strats. But only 1 bank.
 */
contract Bank is ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    string public bankName;
    ILnToken public lnToken;
    IBorrow public borrowImpl;
    IVault public vault;

    bool public initialized;

    uint256 public borrowFee; // 5/1000 = 0.005 aka 0.5%
    address public treasury;

    uint256 constant public MAX_BORROW_FEE = 100;

    struct BorrowCandidate {
        address implementation;
        uint proposedTime;
    }

    // The last proposed strategy to switch to.
    BorrowCandidate public borrowCandidate;
    // The minimum time it has to pass before a strat candidate can be approved.
    uint256 public immutable approvalDelay;

    

    /**
     * @dev
     * struct to track user debt and interest 
     */
    struct BorrowerInfo {
        uint256 borrowedAmount;
        uint256 borrowTime;
        uint256 collateralAmount;
    }
    /** 
     * @dev
     * mapping to track borrower infos
     */
    mapping (address => BorrowerInfo) public borrowerInfoMap;

    event BankTransfer(address _from, address _to, uint256 _amount);
    event Repaid(address indexed _borrower, uint256 _amount, address indexed _vault);
    event Borrowed(address indexed _borrower, uint256 _collateralAmt, uint256 _amount, address indexed _vault);
    event Withdrawn(address indexed _borrower, uint256 _withdrawAmount, address indexed _vault);
    event NewBorrowCandidate(address _implementation);
    event UpgradeBorrowImpl(address _implementation);

    /** 
     * @param _bankName name of the bank eg: 'WFTM SCREAM BANK'
     * @param _approvalDelay time before new borrow implementation can be upgraded.
     * @param _treasury address where borrowFee goes.
     */
    constructor(
        string memory _bankName,
        uint256 _approvalDelay,
        address _treasury
        ) {
        bankName = _bankName;
        approvalDelay = _approvalDelay;
        treasury = _treasury;
        borrowFee = 5;
    }

    /**
     * @dev
     * Initialize the borrowable token and the borrow implementation.
     * This function should only be called a single time only right after deploying.
     * @param _lnToken address of lnToken this bank suppose to mint.
     * @param _borrowImpl address of borrow implementation contract.
     * @param _vault address of vault that can borrow with this bank.
     */
    function initialize(ILnToken _lnToken, IBorrow _borrowImpl, IVault _vault) public onlyOwner {
        require(initialized == false, "already initialized");
        lnToken = _lnToken;
        borrowImpl = _borrowImpl;
        vault = _vault;
        initialized = true;
    }
    /** 
     * @dev Sets the candidate for the new borrow to use with this bank.
     * @param _implementation The address of the candidate borrow.  
     */
    function proposeBorrowImpl(address _implementation) public onlyOwner {
        borrowCandidate = BorrowCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
         });

        emit NewBorrowCandidate(_implementation);
    }
    /** 
     * @dev It switches the active strat for the strat candidate. After upgrading, the 
     * candidate implementation is set to the 0x00 address, and proposedTime to a time 
     * happening in +100 years for safety. 
     */
    function upgradeBorrowImpl() public onlyOwner {
        require(borrowCandidate.implementation != address(0), "There is no candidate");
        require(borrowCandidate.proposedTime.add(approvalDelay) < block.timestamp, "Delay has not passed");

        emit UpgradeBorrowImpl(borrowCandidate.implementation);

        borrowImpl = IBorrow(borrowCandidate.implementation);
        borrowCandidate.implementation = address(0);
        borrowCandidate.proposedTime = 5000000000;
    }

    /// LnToken functions ///
    
    /**
     * @dev
     * mint lnToken to this address 
     * @param _amount the amount of lnToken to mint.
     */
    function mintLnToken(uint256 _amount) public onlyOwner {
        lnToken.mintToBank(address(this), _amount);
    }

    /** 
     * @dev
     * change the owner bank of lnToken. 
     * @param _newBank address of a new bank.
     * @param _valid boolean.
     */
    function setValidBank(address _newBank, bool _valid) public onlyOwner {
        lnToken.setValidBank(_newBank, _valid);
    }

    /**
     * @dev
     * get total supply of lnToken. 
     */
    function lnTokenTotalSupply() public view returns (uint256) {
        return lnToken.totalSupply();
    }

    /**
     * @dev
     * return bank balance of lnToken 
     */
    function bankBalance() public view returns (uint256) {
        return lnToken.balanceOf(address(this));
    }

    /**
     * @dev
     * burn lnToken from bank address 
     */
    function burnLnToken(uint256 _amount) public onlyOwner {
        lnToken.burn(_amount);

    }

    /**
     * @dev
     * transfer lnToken to another address 
     */
    function bankTransfer(address _to, uint256 _amount) public onlyOwner {
        lnToken.approve(address(lnToken), _amount);
        lnToken.sendToBank(_to, _amount);
        emit BankTransfer(address(this), _to, _amount);
    }

    /**
     * @dev
     * To get the user's last borrow time and borrowed amount and collateral.
     * @param _borrower address of borrower.
     */
    function getBorrowerInfo(address _borrower) public view returns (uint256, uint256, uint256) {
        uint256 totalDebt = getDebtWithInterest(_borrower);
        return (totalDebt, borrowerInfoMap[_borrower].borrowTime,
            borrowerInfoMap[_borrower].collateralAmount);
        
    }
   
    /**
     * @dev To borrow lnToken.
     * @param _amount amount of lnToken to borrow.
     * @param _collateralAmt amount of collateral to deposit.
     */
    function borrow(
        uint256 _amount, 
        uint256 _collateralAmt
        ) public nonReentrant {

        // user info
        ( , uint256 lastBorrowTime, uint256 collateralBalance) = getBorrowerInfo(msg.sender);

        uint256 existingDebt = getDebtWithInterest(msg.sender);

        (uint256 newBorrowedAmount, uint256 newCollateralAmt, uint256 newBorrowTime) = borrowImpl.borrow(
            _amount, _collateralAmt, collateralBalance, address(vault), existingDebt);

        /** 
         * Make sure that borrowed amount is more equal than the the one in state.
         * Make sure that borrow time is ahead of previous borrow time.
         * Make sure the the borrow amount is more equal than the current borrowed amount in the state. 
         */ 
        require(newBorrowTime > lastBorrowTime, "borrow: new borrow time less than old one.");
        require(newCollateralAmt >= collateralBalance, "borrow: new collateral less than old one.");
        require(newBorrowedAmount >= existingDebt, "borrow: new borrow is less than new one.");
        
        // update user info
        BorrowerInfo memory borrowerInfo;
        borrowerInfo.borrowedAmount = newBorrowedAmount;
        borrowerInfo.borrowTime = newBorrowTime;
        borrowerInfo.collateralAmount = newCollateralAmt;

        borrowerInfoMap[msg.sender] = borrowerInfo;

        // Charge fees from borrowing.
        uint256 borrowableAmt = chargeFee(_amount);

        vault.transferFrom(msg.sender, address(this), _collateralAmt);
        lnToken.transfer(msg.sender, borrowableAmt);
        
        emit Borrowed(msg.sender, _collateralAmt, _amount, address(vault));

    }

    /**
     * @dev to charge borrowFee.
     * @param _borrowAmt the amount to borrow.
     */
    function chargeFee(uint256 _borrowAmt) internal returns (uint256 borrowableAmt) {
        uint256 fee = _borrowAmt.mul(borrowFee).div(1000);
        lnToken.transfer(treasury, fee);
        borrowableAmt = _borrowAmt.sub(fee);
    }

    /**
     * @dev set borrow fee.
     * @param _borrowFee fee. 
     */
    function setBorrowFee(uint256 _borrowFee) public onlyOwner {
        require(_borrowFee < MAX_BORROW_FEE, "setborrowFee: over MAX_BORROW_FEE");
        borrowFee = _borrowFee;
    }

    /**
     * @dev get interest on the borrowed lnTokens.
     * @param _interestRate interest rate in % from vault.
     * @param _borrowedAmount amount of borred lnToken from bank.
     * @param _borrowTime time of last borrow.
     */
    function calculateInterest(
        uint256 _interestRate, 
        uint256 _borrowedAmount, 
        uint256 _borrowTime
        ) view internal returns (uint256) {
        
        //formula for interest = interstRate/365days * (now-borrowTime) * borrowedAmount.
         
        uint256 timeDiff = block.timestamp.sub(_borrowTime).mul(1e18).div(365 days);
        uint256 interest = timeDiff.mul(_interestRate).div(1000);
        return interest.mul(_borrowedAmount).div(1e18);
    }

    /**
     * @dev
     * Helper function to calculate current debt + interest accured. 
     * @param _borrower address of borrower.
     */
    function getDebtWithInterest(
        address _borrower
        ) view public returns (uint256){
            uint256 interestRate = vault.getInterestRate();
            uint256 interestAmt = calculateInterest(interestRate, borrowerInfoMap[_borrower].borrowedAmount,
             borrowerInfoMap[_borrower].borrowTime);
            return borrowerInfoMap[_borrower].borrowedAmount.add(interestAmt);

        }


    /**
     * @dev
     * To repay debt.
     * @param _amount amount of lnToken to repay.
     */
    function repay(
        uint256 _amount
        ) public nonReentrant {

        // user info
        ( , uint256 lastBorrowTime, uint256 collateralAmount) = getBorrowerInfo(msg.sender);

        uint256 existingDebt = getDebtWithInterest(msg.sender);

        (uint256 newBorrowedAmount, uint256 newBorrowTime) = borrowImpl.repay(_amount, existingDebt);

        /**
         * Make sure that borrow amount is less than existing borrow amount in state. 
         * Make sure that borrow time is ahead of the previous time in state.
         */
        require(newBorrowedAmount < existingDebt, "repay: new borrow more than equal to old one.");
        require(newBorrowTime > lastBorrowTime, "repay: new borrow time lesser than old one");

        // update user info
        BorrowerInfo memory borrowerInfo;
        borrowerInfo.borrowedAmount = newBorrowedAmount;
        borrowerInfo.borrowTime = newBorrowTime;
        borrowerInfo.collateralAmount = collateralAmount;

        borrowerInfoMap[msg.sender] = borrowerInfo;

        lnToken.transferFrom(msg.sender, address(this), _amount);


        emit Repaid(msg.sender, _amount, address(vault));
    }

    /**
     * @dev
     * Repay all debt 
     */
    function repayAll() public {
            uint256 debtWithInterest = getDebtWithInterest(msg.sender);
            repay(debtWithInterest);
        }

    /**
     * @dev
     * To withdraw ibTokens.
     * @param _withdrawAmount amount of collateral to withdraw.
     */
    function withdraw(
        uint256 _withdrawAmount
        ) public nonReentrant {

        // user info
        ( , uint256 lastBorrowTime, uint256 collateralBalance) = getBorrowerInfo(msg.sender);
        
        uint256 existingDebt = getDebtWithInterest(msg.sender);
        (uint256 newCollateralAmt, uint256 newBorrowTime) = borrowImpl.wtithdraw(_withdrawAmount, address(vault),
         collateralBalance, existingDebt);

        /**
         * Make sure that borrow time ahead of the previous borrow time in state.
         * Make sure that collateral amount is less equal than the previous collateral amount in state.
         */
        require(newBorrowTime > lastBorrowTime, "withdraw: new borrow time less than old one.");
        require(newCollateralAmt <= collateralBalance, "withdraw: new collateral more than old one.");
        
        // update user info
        BorrowerInfo memory borrowerInfo;
        borrowerInfo.borrowedAmount = existingDebt;
        borrowerInfo.borrowTime = newBorrowTime;
        borrowerInfo.collateralAmount = newCollateralAmt;

        borrowerInfoMap[msg.sender] = borrowerInfo;

        vault.transfer(msg.sender, _withdrawAmount);
        
        emit Withdrawn(msg.sender, _withdrawAmount, address(vault));
        }

    /**
     * @dev
     * To withdraw max collateral fron bank without going below LTV. */
    function withdrawAll() public {

        // user info
        uint256 collateralBalance = borrowerInfoMap[msg.sender].collateralAmount;

        // update new debt with interest.
        uint256 newBorrowedAmount = getDebtWithInterest(msg.sender);

        uint256 lTV = vault.getLTV();
        uint256 maxLtv = lTV.mul(1e18).div(100);
        uint256 minCollateral = newBorrowedAmount.mul(1e18).div(maxLtv);

        uint256 maxWithdrawable = collateralBalance.sub(minCollateral);

        // give some space to prevent going over ltv slightly.
        withdraw(maxWithdrawable.mul(999).div(1000));     
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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