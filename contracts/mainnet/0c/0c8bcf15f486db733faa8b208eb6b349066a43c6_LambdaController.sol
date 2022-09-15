/**
 *Submitted for verification at FtmScan.com on 2022-09-15
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/Common/Context.sol

// 
pragma solidity >=0.6.11;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/Math/SafeMath.sol

// 
pragma solidity >=0.6.11;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// File contracts/ERC20/IERC20.sol

// 
pragma solidity >=0.6.11;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/Staking/Owned.sol

// 
pragma solidity >=0.6.11;

// https://docs.synthetix.io/contracts/Owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor (address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}


// File contracts/Frax/Pools/ILambdaPool.sol

// 
pragma solidity >=0.6.11;

interface ILambdaPool {
    function collatDollarBalance() external view returns (uint256);
    function amoMinterBorrow(uint256 collateral_amount) external;
    function collateralAddrToIdx(address collateral_address) external returns(uint256);
}


// File contracts/Oracle/AggregatorV3Interface.sol

// 
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function update() external;

}


// File contracts/Uniswap/TransferHelper.sol

// 
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/Frax/LambdaController.sol

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;







contract LambdaController is Owned {
    using SafeMath for uint256;

    
    address public controller_address; // Controller contract to dynamically adjust system parameters automatically
    
    // The addresses in this array are added by the oracle and these contracts are able to mint lambda
    address[] public lambda_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public lambda_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public redemption_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public minting_fee; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public lambda_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of Lambda at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    bool public collateral_ratio_paused = false;

    IERC20 public lambdaToken;
    IERC20 public shareToken;

    address public lambda_oracle_address;
    address public shareToken_oracle_address;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(lambda_pools[msg.sender] == true, "Only lambda pools can call this function");
        _;
    } 

    modifier onlyByOwnerGovernanceOrController() {
        require(msg.sender == owner || msg.sender == controller_address, "Not the owner, controller");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (
        address _lambda_address,
        address _shareToken_address,
        address _creator_address,
        address _lambda_oracle_address,
        address _shareToken_oracle_address
    ) public Owned(_creator_address){

        lambda_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // Lambda system starts off fully collateralized (6 decimals of precision)
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis

        lambdaToken = IERC20(_lambda_address);
        shareToken = IERC20(_shareToken_address);

        lambda_oracle_address = _lambda_oracle_address;
        shareToken_oracle_address = _shareToken_oracle_address;
    }

    /* ========== VIEWS ========== */

    function lambda_price() public view returns (uint256) {
        (, int256 price, , ,) =  AggregatorV3Interface(lambda_oracle_address).latestRoundData();
        return uint256(price);
    }

    function update_lambda_price() public{
        AggregatorV3Interface(lambda_oracle_address).update();
    }

    function shareToken_price() public view returns (uint256) {
        (, int256 price, , ,) =  AggregatorV3Interface(shareToken_oracle_address).latestRoundData();
        return uint256(price);
    }

    function update_shareToken_price() public{
        AggregatorV3Interface(shareToken_oracle_address).update();
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function lambdaController_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            lambda_price(),
            shareToken_price(),
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            minting_fee, // minting_fee()
            redemption_fee // redemption_fee()
        );
    }

    // Iterate through all lambda pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < lambda_pools_array.length; i++){ 
            // Exclude null addresses
            if (lambda_pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(ILambdaPool(lambda_pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");

        AggregatorV3Interface(lambda_oracle_address).update();
        uint256 lambda_price_cur = lambda_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setLambdaStep()) 
        if (lambda_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= lambda_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(lambda_step);
            }
        } else if (lambda_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(lambda_step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(lambda_step);
            }
        }
        last_call_time = block.timestamp; // Set the time of the last expansion

        emit CollateralRatioRefreshed(global_collateral_ratio);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        lambdaToken.transferFrom(b_address, address(this), b_amount);
        emit LambdaBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other lambda pools will call to mint new lambda 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        lambdaToken.transfer(m_address, m_amount);
        emit LambdaMinted(msg.sender, m_address, m_amount);
    }

    function pool_burn_shareToken_from(address b_address, uint256 b_amount) public onlyPools {
        shareToken.transferFrom(b_address, address(this), b_amount);
        emit ShareTokenBurned(b_address, msg.sender, b_amount);
    }

    function pool_mint_shareToken(address m_address, uint256 m_amount) public onlyPools {
        shareToken.transfer(m_address, m_amount);
        emit ShareTokenMinted(msg.sender, m_address, m_amount);
    }


    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerGovernanceOrController {
        require(pool_address != address(0), "Zero address detected");

        require(lambda_pools[pool_address] == false, "Address already exists");
        lambda_pools[pool_address] = true; 
        lambda_pools_array.push(pool_address);

        emit PoolAdded(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerGovernanceOrController {
        require(pool_address != address(0), "Zero address detected");
        require(lambda_pools[pool_address] == true, "Address nonexistant");
        
        // Delete from the mapping
        delete lambda_pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < lambda_pools_array.length; i++){ 
            if (lambda_pools_array[i] == pool_address) {
                lambda_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }

        emit PoolRemoved(pool_address);
    }

    function setRedemptionFee(uint256 red_fee) public onlyByOwnerGovernanceOrController {
        redemption_fee = red_fee;

        emit RedemptionFeeSet(red_fee);
    }

    function setMintingFee(uint256 min_fee) public onlyByOwnerGovernanceOrController {
        minting_fee = min_fee;

        emit MintingFeeSet(min_fee);
    }  

    function setLambdaStep(uint256 _new_step) public onlyByOwnerGovernanceOrController {
        lambda_step = _new_step;

        emit LambdaStepSet(_new_step);
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerGovernanceOrController {
        price_target = _new_price_target;

        emit PriceTargetSet(_new_price_target);
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerGovernanceOrController {
    	refresh_cooldown = _new_cooldown;

        emit RefreshCooldownSet(_new_cooldown);
    }

    function setController(address _controller_address) external onlyByOwnerGovernanceOrController {
        require(_controller_address != address(0), "Zero address detected");

        controller_address = _controller_address;

        emit ControllerSet(_controller_address);
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerGovernanceOrController {
        price_band = _price_band;

        emit PriceBandSet(_price_band);
    }

    function setShareTokenAddress(address _shareToken_address) public onlyByOwnerGovernanceOrController {
        require(_shareToken_address != address(0), "Zero address detected");
        shareToken = IERC20(_shareToken_address);
        emit ShareTokenAddressSet(_shareToken_address);
    }

    function setLambdaOracle(address _lambda_oracle_address) public onlyByOwnerGovernanceOrController {
        require((_lambda_oracle_address != address(0)), "Zero address detected");
        lambda_oracle_address = _lambda_oracle_address;
        emit LambdaOracleSet(_lambda_oracle_address);
    }

    function setShareTokenOracle(address _shareToken_oracle_address) public onlyByOwnerGovernanceOrController {
        require((_shareToken_oracle_address != address(0)), "Zero address detected");
        shareToken_oracle_address = _shareToken_oracle_address;
        emit ShareTokenOracleSet(_shareToken_oracle_address);
    }

    function toggleCollateralRatio() public onlyByOwnerGovernanceOrController {
        collateral_ratio_paused = !collateral_ratio_paused;
        emit CollateralRatioToggled(collateral_ratio_paused);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyByOwnerGovernanceOrController {
        // Can only be triggered by owner or governance
        TransferHelper.safeTransfer(tokenAddress, owner, tokenAmount);
        
        emit Recovered(tokenAddress, tokenAmount);
    }

    /* ========== EVENTS ========== */
    event LambdaBurned(address indexed from, address indexed to, uint256 amount);
    event LambdaMinted(address indexed from, address indexed to, uint256 amount);
    event ShareTokenBurned(address indexed from, address indexed to, uint256 amount);
    event ShareTokenMinted(address indexed from, address indexed to, uint256 amount);

    event CollateralRatioRefreshed(uint256 global_collateral_ratio);
    event PoolAdded(address pool_address);
    event PoolRemoved(address pool_address);
    event RedemptionFeeSet(uint256 red_fee);
    event MintingFeeSet(uint256 min_fee);
    event LambdaStepSet(uint256 new_step);
    event PriceTargetSet(uint256 new_price_target);
    event RefreshCooldownSet(uint256 new_cooldown);
    event ShareTokenAddressSet(address _shareToken_address);


    event ControllerSet(address controller_address);
    event PriceBandSet(uint256 price_band);

    event CollateralRatioToggled(bool collateral_ratio_paused);
    event LambdaOracleSet(address lambda_oracle_address);
    event ShareTokenOracleSet(address shareToken_oracle_address);

    event Recovered(address token, uint256 amount);
}