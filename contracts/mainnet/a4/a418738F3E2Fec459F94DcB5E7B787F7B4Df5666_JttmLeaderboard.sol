// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title JttmLeaderboard
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract JttmLeaderboard {
    address private constant ERC20_ADDRESS = 0x7980602A62D0E133A318D193Ce495A55128a130A; // Replace with the new ERC20 contract address

    address private constant ADMIN_ADDRESS = 0x2c75e9e927CAc571069E9a6849489F39C1ceA105; // Replace with the desired admin address

    mapping(address => uint256) balances;
    mapping(uint256 => address) leaderboard;

    /**
     * @dev Modifier to check if the sender is the admin address
     */
    modifier onlyAdmin() {
        require(msg.sender == ADMIN_ADDRESS, "Caller is not the admin");
        _;
    }

    /**
     * @dev Store value in variable
     */
    function store() public {
        IERC20 erc20 = IERC20(ERC20_ADDRESS);
        uint256 balance = erc20.balanceOf(msg.sender);
        balances[msg.sender] = balance;
    }

    /**
     * @dev Return balance of a user
     * @param user User address
     * @return Balance of the user
     */
    function retrieveBalance(address user) public view returns (uint256) {
        uint256 balance = balances[user];
        return balance;
    }

    /**
     * @dev Check balance of the connected wallet for the hardcoded ERC20 contract address
     * @return Balance of the connected wallet for the ERC20 contract
     */
    function checkERC20Balance() public view returns (uint256) {
        IERC20 erc20 = IERC20(ERC20_ADDRESS);
        uint256 balance = erc20.balanceOf(msg.sender);
        return balance;
    }

    /**
     * @dev Approve the contract to spend ERC20 tokens from the connected wallet
     */
    function approveERC20Tokens() public {
        IERC20 erc20 = IERC20(ERC20_ADDRESS);
        uint256 balance = erc20.balanceOf(msg.sender);
        erc20.approve(address(this), balance);
    }

    /**
     * @dev Update the leaderboard with the user's balance as the score
     */
    function updateLeaderboard() public {
        address sender = msg.sender;
        IERC20 erc20 = IERC20(ERC20_ADDRESS);
        uint256 balance = erc20.balanceOf(sender);

        uint256 lowestScore = balances[leaderboard[9]];
        if (balance > lowestScore) {
            uint256 index = 9;
            while (index > 0 && balance > balances[leaderboard[index - 1]]) {
                leaderboard[index] = leaderboard[index - 1];
                index--;
            }
            leaderboard[index] = sender;
        }
    }

    /**
     * @dev Reset the leaderboard for a specific user (admin-only function)
     * @param user User address to reset
     */
    function resetUser(address user) public onlyAdmin {
        delete balances[user];
        updateLeaderboard();
    }

    /**
     * @dev Get the leaderboard addresses and scores
     * @return The addresses and scores of the top 10 leaderboard entries
     */
    function getLeaderboard() public view returns (address[10] memory, uint256[10] memory) {
        address[10] memory addresses;
        uint256[10] memory scores;

        for (uint256 i = 0; i < 10; i++) {
            addresses[i] = leaderboard[i];
            scores[i] = balances[leaderboard[i]];
        }

        return (addresses, scores);
    }
}