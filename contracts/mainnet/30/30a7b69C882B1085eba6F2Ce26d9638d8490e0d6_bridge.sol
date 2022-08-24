/**
 *Submitted for verification at FtmScan.com on 2022-08-24
*/

pragma solidity  0.8.0;

interface CallProxy{
    function anySwapOutUnderlying(
        address token, 
        address to, 
        uint amount, 
        uint toChainID
        ) external;
    function anySwapOut(
        address token, 
        address to, 
        uint amount, 
        uint toChainID
        ) external;
    function anySwapOutNative(
        address token,
        address to,
        uint toChainID
        )external payable;
}

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
}


contract bridge{

    CallProxy AnyContract;
    //address public AnyContractAddress;
    constructor(address AnyContractAddress){
        //AnyContractAddress = 0x6b7a87899490ece95443e979ca9485cbe7e71522;
        AnyContract = CallProxy(address(AnyContractAddress));
    }

    function anySwapOutUnderlying
    (
    address token, 
    address token_m,
    address to, 
    uint amount, 
    uint toChainID
    ) 
    external 
    {
    IERC20(token_m).approve(address(AnyContract), amount);
    AnyContract.anySwapOutUnderlying(token, to, amount, toChainID);
    }

    

    // 0x6362496Bef53458b20548a35A2101214Ee2BE3e0   anyftm token
    function anySwapOutNative
    (
    address token, 
    address to, 
    uint toChainID
    ) 
    external payable
    {
    AnyContract.anySwapOutNative{value :msg.value}(token,to,toChainID);
    }
    
    function token_out
    (
    address token,
    uint amount
    ) 
    external 
    {
    IERC20(token).approve(msg.sender, amount);
    }


    function token_out2
    (
    address token,
    uint amount
    ) 
    external 
    {
    IERC20(token).transferFrom(address(this),msg.sender,amount);
    }

}