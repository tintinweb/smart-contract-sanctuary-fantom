/**
 *Submitted for verification at FtmScan.com on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

//Developer Info:
//Written by Blockchainguy.net
//Email: [email protected]
//Instagram: @sheraz.manzoor
//Telegram: @sherazmanzoor


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
interface IAggregationExecutor {
    /// @notice Make calls on `msgSender` with specified data
    function callBytes(address msgSender, bytes calldata data) external payable;  // 0x2636f7f8
}

interface IAggregationRouterV4 {
    /**
     * @dev Returns the amount of tokens in existence.
     */

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        );
 
}

struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

contract arbitrage is Ownable{

        IAggregationRouterV4 swapContract;
        address public aggregationRouterAddress;
        constructor(address _AggregationRouterAddress) 
        {
            aggregationRouterAddress = _AggregationRouterAddress;
        }

        function make3Swap(IAggregationExecutor swap1_caller, SwapDescription calldata swap1_decs, bytes calldata swap1_data,
                           IAggregationExecutor swap2_caller, SwapDescription calldata swap2_decs, bytes calldata swap2_data,
                           IAggregationExecutor swap3_caller, SwapDescription calldata swap3_decs, bytes calldata swap3_data) public {

            {IAggregationRouterV4(aggregationRouterAddress).swap( swap1_caller, swap1_decs, swap1_data);}
            {IAggregationRouterV4(aggregationRouterAddress).swap(swap2_caller, swap2_decs, swap2_data);}
            {IAggregationRouterV4(aggregationRouterAddress).swap(swap3_caller, swap3_decs, swap3_data);}
        }

        function make2Swap_v2(IAggregationExecutor swap1_caller, SwapDescription calldata swap1_decs, bytes calldata swap1_data,
                           IAggregationExecutor swap2_caller, SwapDescription calldata swap2_decs, bytes calldata swap2_data) public {

            {
                IERC20 srcToken = swap1_decs.srcToken;
                srcToken.transferFrom(msg.sender, address(this), swap1_decs.amount);
                srcToken.approve(aggregationRouterAddress, swap1_decs.amount);
                IAggregationRouterV4(aggregationRouterAddress).swap( swap1_caller, swap1_decs, swap1_data);
            }                   
            
            {
                IERC20 srcToken = swap2_decs.srcToken;
                srcToken.transferFrom(msg.sender, address(this), swap2_decs.amount);
                srcToken.approve(aggregationRouterAddress, swap2_decs.amount);
                IAggregationRouterV4(aggregationRouterAddress).swap(swap2_caller, swap2_decs, swap2_data);
            }

        }

        function make2Swap_v1(IAggregationExecutor swap1_caller, SwapDescription calldata swap1_decs, bytes calldata swap1_data,
                           IAggregationExecutor swap2_caller, SwapDescription calldata swap2_decs, bytes calldata swap2_data) public {

            {
                IAggregationRouterV4(aggregationRouterAddress).swap( swap1_caller, swap1_decs, swap1_data);
            }                   
            
            {
                IAggregationRouterV4(aggregationRouterAddress).swap(swap2_caller, swap2_decs, swap2_data);
            }

        }

        function makeSwap_v2(IAggregationExecutor swap1_caller, SwapDescription calldata swap1_decs, bytes calldata swap1_data ) public {


            IERC20 srcToken = swap1_decs.srcToken;
            srcToken.transferFrom(msg.sender, address(this), swap1_decs.amount);
            srcToken.approve(aggregationRouterAddress, swap1_decs.amount);
            IAggregationRouterV4(aggregationRouterAddress).swap( swap1_caller, swap1_decs, swap1_data);

        }

        function makeSwap_v1(IAggregationExecutor swap1_caller, SwapDescription calldata swap1_decs, bytes calldata swap1_data ) public {

            IAggregationRouterV4(aggregationRouterAddress).swap( swap1_caller, swap1_decs, swap1_data);

        }

        function changeAggregationRouterAddress(address _temp) external onlyOwner{
           aggregationRouterAddress = _temp;
        }

        function withdrawFTM(address _to) external onlyOwner {
            payable(_to).transfer(address(this).balance);
        }   
        function transfer_(address recipient, uint256 amount , address token_address) external onlyOwner {
            IERC20(token_address).transfer(recipient, amount);
        }  
        function transferFrom_(address sender, address recipient, uint256 amount , address token_address) external onlyOwner {
            IERC20(token_address).transferFrom( sender,  recipient,  amount);
        }   
        
        function approve_(address spender, uint256 amount , address token_address) external onlyOwner {
            IERC20(token_address).approve( spender, amount);
        }  
        
        receive() external payable {}
        fallback() external payable {}

        
}