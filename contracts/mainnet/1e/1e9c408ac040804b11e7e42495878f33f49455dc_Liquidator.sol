/**
 *Submitted for verification at FtmScan.com on 2022-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

interface ILevSwapperGeneric {
    /// @notice Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);
}

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

interface IParanormalSafe {
    function liquidate(address[] calldata users, uint256[] calldata maxBorrowParts, address to, ISwapper swapper) external;
    function masterContract() external returns (address _masterContract);
}
interface IParanormalReserve {
    function withdraw(IERC20 token_, address from, address to, uint256 amount, uint256 share ) external returns (uint256 amountOut, uint256 shareOut);
    function deposit(IERC20 token_, address from, address to, uint256 amount, uint256 share ) external payable returns (uint256 amountOut, uint256 shareOut);
    function balanceOf(IERC20 token_, address user) external view returns (uint256);
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
}



contract Liquidator {

    using SafeMath for uint256;
    address public owner;
    IERC20 paraDollar;
    IParanormalReserve paranormalReserve;
    ISwapper swapper;
    bool autoConvertCollateralIntoStable;
    mapping(address => bool) public canCallLiquidate;


    constructor(IERC20 _paraDollar, IParanormalReserve _paranormalReserve, address _masterContract) public{
        owner=msg.sender;
        paraDollar=_paraDollar;
        paranormalReserve=_paranormalReserve;
        canCallLiquidate[owner]=true;
        paranormalReserve.setMasterContractApproval(address(this), _masterContract, true, 0, 0, 0);
        paraDollar.approve(address(paranormalReserve),  type(uint256).max);
    }

    function withdrawParaDollarFromBank() public{
        require(owner==msg.sender,"Only owner");
        uint amountToWithdraw=paranormalReserve.balanceOf(paraDollar, address(this));
        if(amountToWithdraw>0){
            paranormalReserve.withdraw(paraDollar, address(this), address(this), 0, amountToWithdraw);
            paraDollar.transfer(owner, paraDollar.balanceOf(address(this)));
        }
    }
    function depositParaDollarIntoBank() public{
        require(owner==msg.sender,"Only owner");
        paranormalReserve.deposit(paraDollar, address(this), address(this), paraDollar.balanceOf(address(this)), 0);
    }

    function liquidateUsers(IParanormalSafe paranormalSafe, IERC20 collateralToken, address[] calldata users, uint256[] calldata maxBorrowParts) public{
        require(canCallLiquidate[msg.sender]==true,"No permission");

        paranormalSafe.liquidate(users, maxBorrowParts, address(this), swapper);
        uint amountToWithdraw=paranormalReserve.balanceOf(collateralToken, address(this));
        if(amountToWithdraw>0){
            paranormalReserve.withdraw(collateralToken, address(this), address(this), 0, amountToWithdraw);
        }

        if(autoConvertCollateralIntoStable==true){
            convertCollateralIntoStable(collateralToken);
        }
        else{
            transferCollateralToOwner(collateralToken);
        }
    }



    function convertCollateralIntoStable(IERC20 _collateralToken) internal {
        //To-do: Autosell the collateral for ParaDollar and deposit back into ParanormalReserve for future liquidations
        //Example: 
/*
        uint256 amountFrom = WFTM_VAULT.withdraw(type(uint256).max, address(pair));

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        
        uint256 amountTo = getAmountOut(amountFrom, reserve0, reserve1);
        pair.swap(0, amountTo, address(paranormalReserve), new bytes(0));

        paranormalReserve.deposit(paraDollar, address(paranormalReserve), address(this), amountTo, 0);
        */
    }


    function transferCollateralToOwner(IERC20 _collateralToken) internal{
        if(_collateralToken.balanceOf(address(this))>0){
            _collateralToken.transfer(owner, _collateralToken.balanceOf(address(this)));
        }
    }
    
/////////////////////////////////////////////////////////////////////////////Utility Functions////////////////////////////////////////////////////
    function changeOwner(address newOwner) external{
        require(owner==msg.sender,"Only owner");
        canCallLiquidate[owner]=false;
        canCallLiquidate[newOwner]=true;
        owner=newOwner;
    }
    function changeCanLiquidate(address liquidator, bool true_or_false) external{
        require(owner==msg.sender,"Only owner");
        canCallLiquidate[liquidator]=true_or_false;

    }
    function changeSwapper(ISwapper newSwapper) external{
        require(owner==msg.sender,"Only owner");
        swapper=newSwapper;
    }
    function toggleAutoConvert(bool true_or_false) external{
        require(owner==msg.sender,"Only owner");
        autoConvertCollateralIntoStable=true_or_false;
    }

}