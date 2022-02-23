/**
 *Submitted for verification at FtmScan.com on 2022-02-23
*/

pragma solidity 0.8.5;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


interface IDividenDistributor {
    function claimReward(uint256 rewardId) external;
}


contract Vault is Context {

    struct Withdraw {
        uint256 withdrawAmount;
        uint256 withdrawTime;
    }

    bytes4 public constant DIVIDEN_DISTRIBUTOR = type(IDividenDistributor).interfaceId;

    // Fixed Parameters
    address public frockToken; // Address of Frock Token/Token that will be locked
    address public dividenDistributor;
    address public holder; // address of token's holder that lock the token
    uint256 public amountFrockTokenLocked; // amount token that locked
    uint256 public lockPeriode; // How long the token will be locked before will be able to withdraw
    uint256 public startLock; // start time of token's lock
    uint256 public endLock; // end time of token's lock
    uint256 public periodPerWithdraw; // Period of each withdrawal, ex : for a month only able to withdraw once
    uint256 public maxAmountPerWithdraw; // Amount fo token that able to withdraw per withdrawal's periode

    // Dynamic Parameter
    uint256 totalWithdraw;
    bool isLocked; // Lock State    
    mapping(uint256 => Withdraw) public withdrawalHistory; // Epoch withdrawal => time of withdrawal
    
    event Locked(
        address indexed holder, 
        uint256 amountFrockTokenLocked, 
        uint256 lockPeriode, 
        uint256 periodPerWithdraw, 
        uint256 amountPerWithdraw
    );
    event WithdrawToken(uint256 epoch, uint256 withdrawAmount);
    event ClaimDividen(uint256 rewardId, uint256 rewardAmount);

    constructor(address _frockToken, address _dividenDistributor) {
        frockToken = _frockToken;   
        dividenDistributor = _dividenDistributor;     
        isLocked = false;
    }

    function lockToken(
        uint256 amountFrockTokenLockedParam,
        uint256 lockPeriodeParam,    
        uint256 periodPerWithdrawParam,
        uint256 maxAmountPerWithdrawParam
    ) external {
        // Requirement
        require(!isLocked, "Vault: Already Locked");

        // Transfer Token
        require(
            IERC20(frockToken).transferFrom(_msgSender(), address(this), amountFrockTokenLockedParam),
            "Vault: Transfer Failed"
        );

        // Update State
        isLocked = true;
        holder = _msgSender();
        amountFrockTokenLocked = amountFrockTokenLockedParam;
        lockPeriode = lockPeriodeParam;
        startLock = block.timestamp;
        endLock = startLock + lockPeriode;
        periodPerWithdraw = periodPerWithdrawParam;
        maxAmountPerWithdraw = maxAmountPerWithdrawParam;        

        emit Locked(
            _msgSender(), 
            amountFrockTokenLockedParam, 
            lockPeriodeParam, 
            periodPerWithdrawParam, 
            maxAmountPerWithdrawParam
        );
    }

    function currentEpoch() public view returns(uint256) {
        require(block.timestamp > endLock, "Vault: Cannot Calculate Epoch");
        return (block.timestamp - (endLock))/periodPerWithdraw;
    }

    function withdraw(uint256 withdrawAmount) external {
        require(holder == _msgSender(), "Vault: Not the Holder");        
        require(withdrawAmount <= maxAmountPerWithdraw, "Vault: withdrawal exceed limit");
        require((amountFrockTokenLocked - totalWithdraw) >= withdrawAmount,"Vault: withdrawal exceed stocks");

        uint256 epoch = currentEpoch();
        require(withdrawalHistory[epoch].withdrawTime == 0, "Vault: Already Withdraw for This Period");

        // Update Value
        withdrawalHistory[epoch] = Withdraw(withdrawAmount, block.timestamp);
        totalWithdraw += withdrawAmount;

        // Transfer Token
        require(
            IERC20(frockToken).transfer(holder, withdrawAmount),
            "Vault: Transfer Failed"
        );

        emit WithdrawToken(epoch, withdrawAmount);
    }

    function claimDividen(uint256 rewardId) external returns(uint256 rewardAmount ) {
        if(IERC165Upgradeable(dividenDistributor).supportsInterface(DIVIDEN_DISTRIBUTOR)) {
            IDividenDistributor(dividenDistributor).claimReward(rewardId);
            rewardAmount = address(this).balance;
            _safeTransferETH(holder, rewardAmount);
            emit ClaimDividen(rewardId, rewardAmount);
            return rewardAmount;
        }
        revert("Vault: Address not support claimReward");
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Vault: ETH_TRANSFER_FAILED');
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    
}