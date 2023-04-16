// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GamblingGame {
     address private BAY_TOKEN_CONTRACT;
    uint256 private constant DEPOSIT_AMOUNT = 10 * 10**18; // 10 BAY tokens with 18 decimals
    uint256 private constant WINNING_PROBABILITY = 40; // 40% chance of winning

    IERC20 private _bayToken;

    constructor(address tokenAddress) {
        BAY_TOKEN_CONTRACT = tokenAddress;
        _bayToken = IERC20(BAY_TOKEN_CONTRACT);
    }

    function depositTokensAndPlay() external {
        uint256 userBalance = _bayToken.balanceOf(msg.sender);
        require(userBalance >= DEPOSIT_AMOUNT, "Insufficient BAY tokens");

        // Transfer 10 BAY tokens from user to the contract
        _bayToken.transferFrom(msg.sender, address(this), DEPOSIT_AMOUNT);

        // Determine if the user wins or loses
        bool userWins = _isUserWinner();

        // Handle the game outcome
        _handleGameOutcome(userWins);
    }

    function _isUserWinner() private view returns (bool) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        return randomNumber < WINNING_PROBABILITY;
    }

    function _handleGameOutcome(bool userWins) private {
        if (userWins) {
            uint256 reward = 5 * 10**18; // 5 BAY tokens with 18 decimals
            uint256 contractBalance = _bayToken.balanceOf(address(this));

            // If the contract has enough tokens, return the deposit and reward
            if (contractBalance >= DEPOSIT_AMOUNT + reward) {
                _bayToken.transfer(msg.sender, DEPOSIT_AMOUNT + reward);
            } else {
                // If the contract doesn't have enough tokens, just return the deposit
                _bayToken.transfer(msg.sender, DEPOSIT_AMOUNT);
            }
        } else {
            // User loses, tokens remain in the contract
        }
    }
}