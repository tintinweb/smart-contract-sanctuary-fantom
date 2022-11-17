/**
 *Submitted for verification at FtmScan.com on 2022-11-17
*/

// File: IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: EarlySupportersRewarder.sol


pragma solidity ^0.8.0;




/**
    @title Blue Blur contract for receiving donations and send BB tokens as a reward.
    @author Blue Blur.
    @notice Contract for receiving donations. 
    The contract can send back reward tokens for donators.
 */
contract EarlySupportersReward is Ownable {
    IUniswapV2Router01 public spookyRouter = IUniswapV2Router01(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    address[] public WETHUSDTAddresses = [0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83, 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75];
    uint256 BLURPrice;

    /**
        @dev Variable with amount of donations for all time.
     */
    uint256 public donationsCount;
    /**
        @dev Total amount of donated funds for all time.
     */
    uint256 public totalDonationsAmount;
    /**
        @dev 
        Params to store information about highest donation.
     */
    uint256 private highestDonation;
    address private highestDonator;
    /**
        @dev Address of token that will be sent back as a reward for donation. 
     */
    IERC20 public rewardToken;
    /**
        @dev There is an opportunity to configure the minimum amount for donations.
     */
    uint256 public donationMinimalValue;

    /**
        @dev All donators addresses.
     */
    address[] public donatorsAdresses;
    /**
        @dev Amount of donations for every address.
     */
    mapping(address => uint256) private adressesDonations;
    /**
        @dev Variable store information about participation for address. 
        If address participate - value 'true', if not - 'false'.
        This is necessary for creation an donators addresses array without repeating addressses.
     */
    mapping(address => bool) private isAddressDonatedBefore;


    constructor() {
        BLURPrice = 600; // started price for BLUR Token 0.0006 USDC (10^6 decimals)
    }

    /**
        @dev Event emits when donation comes.
     */
    event Donation(
        address indexed _donor,
        uint256 _value
    );

    /**
        @dev Event emits when donations withdraw from contract.
     */
    event Withdraw(
        address indexed _recipient,
        uint256 _amount
    );

    /**
        @dev Function for receiving donations.
     */
    receive() external payable {
        require(msg.value > donationMinimalValue, "donation amount should be greater than minimum donation");
        if (address(rewardToken) != address(0)){
            uint256 rewardAmount = getAwardedBlurAmount(msg.value);
            rewardToken.transfer(msg.sender, rewardAmount);
        }

        if (!isAddressDonatedBefore[msg.sender]){
            isAddressDonatedBefore[msg.sender] = true;
            donatorsAdresses.push(msg.sender);
        }

        adressesDonations[msg.sender] += msg.value;
        totalDonationsAmount += msg.value;
        donationsCount += 1;

        if (highestDonation < msg.value){
            highestDonation = msg.value;
            highestDonator = msg.sender;
        }

        emit Donation(msg.sender, msg.value);
    }

    /**
        @dev Set minimum amount of donation in native currency.
        @param _minimalValue New minimum value. 
     */
    function setDonationMinimalValue(uint256 _minimalValue) public onlyOwner {
        donationMinimalValue = _minimalValue;
    }

    /**
        @dev Setting up reward token.
        @param _rewardTokenAddress New address of the reward token.
     */
    function setRewardToken(address _rewardTokenAddress) public onlyOwner {
        require(_rewardTokenAddress != address(0), "zero address");
        rewardToken = IERC20(_rewardTokenAddress);
    }

    /**
        @dev Get highest donation with donator address.
     */
    function getHighestDonation() view public returns(uint256, address) {
        return (highestDonation, highestDonator);
    }
    
    /**
        @dev Get total donation for address.
        @param _donator Address of the donator.
     */
    function getDonationForAddress(address _donator) view public returns(uint256) {
        return adressesDonations[_donator];
    }

    /**
        @dev Get all donators addresses.
     */
    function getDonators() view public returns(address[] memory){
        return donatorsAdresses;
    }

    /**
        @dev Destroy contract.
        @param _recipient Address of the funds recipient.
     */
    function destroy(address _recipient) public onlyOwner {
        selfdestruct(payable(_recipient));
    }

    /**
        @dev Function for withdraw donations.
        @param _recipient Address of the donations recipient.
        @param _amount Amount of tokens to withdraw.
     */
    function withdrawDonations(address _recipient, uint256 _amount) public onlyOwner {
        payable(_recipient).transfer(_amount);

        emit Withdraw(_recipient, _amount);
    }
    
    /**
        @dev Withdraw reward tokens.
        
        @param _recipient Address of the reward tokens recipient.
        @param _amount Amount of tokens to withdraw.
     */
    function withdrawFunds(address _recipient, uint256 _amount) public onlyOwner {
        rewardToken.transfer(_recipient, _amount);
    }

    function setBlurTokenPrice(uint256 _blurPrice) public onlyOwner {
        require(_blurPrice != 0, "incorrect params");
        BLURPrice = _blurPrice;
    }

    function getAwardedBlurAmount(uint256 _nativeAmount) public view returns(uint256){
        uint256 fantomPrice = spookyRouter.getAmountsOut(_nativeAmount, WETHUSDTAddresses)[1];
        uint256 blurAmount = fantomPrice / BLURPrice;
        return blurAmount * 10 ** 18;
    }
}