// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakedFrogToken is IERC20 {

    string public constant symbol = "sFRG";
    string public constant name = "Staked Frog Nation DAO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    uint256 public lockPeriod = 24 hours;

    mapping(address => uint256) private _lockedUntil;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    IERC20 public immutable token;

    constructor(
        address token_
    ) {
        token = IERC20(token_);
    }

    function approve(
        address spender,
        uint256 shares
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = shares;
        emit Approval(msg.sender, spender, shares);
        return true;
    }

    function mint(
        uint256 amount
    ) public returns (bool) {
        _mint(msg.sender, amount);
        return true;
    }

    function burn(
        uint256 shares
    ) public returns (bool) {
        _burn(msg.sender, shares);
        return true;
    }

    function burnFrom(
        address account,
        uint256 shares
    ) public returns (bool) {
        _useAllowance(account, shares);
        _burn(account, shares);
        return true;
    }

    function transfer(
        address to,
        uint256 shares
    ) public returns (bool) {
        _transfer(msg.sender, to, shares);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 shares
    ) public returns (bool) {
        _useAllowance(from, shares);
        _transfer(from, to, shares);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(
        address account
    ) public view returns (uint256) {
        return _balances[account];
    }

    function lockedUntil(
        address account
    ) public view returns (uint256) {
        return _lockedUntil[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 shares
    ) internal {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(block.timestamp >= _lockedUntil[from], "locked");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= shares, "transfer amount exceeds balance");

        _balances[from] = fromBalance - shares;
        _balances[to] += shares;

        emit Transfer(from, to, shares);
    }

    function _mint(
        address account,
        uint256 amount
    ) internal {
        require(account != address(0), "transfer to the zero address");

        uint256 totalTokens = token.balanceOf(address(this));
        uint256 shares = totalSupply == 0 ? amount : (amount * totalSupply) / totalTokens;

        _lockedUntil[account] = block.timestamp + lockPeriod;
        _balances[account] += shares;
        totalSupply += shares;

        token.transferFrom(account, address(this), amount);
        emit Transfer(address(0), account, shares);
    }

    function _burn(
        address account,
        uint256 shares
    ) internal {
        require(account != address(0), "transfer to the zero address");
        require(block.timestamp >= _lockedUntil[account], "locked");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= shares, "burn amount exceeds balance");

        uint256 totalTokens = token.balanceOf(address(this));
        uint256 amount = (shares * totalTokens) / totalSupply;

        _balances[account] = accountBalance - shares;
        totalSupply -= shares;

        token.transfer(account, amount);
        emit Transfer(account, address(0), shares);
    }

    function _useAllowance(
        address from,
        uint256 shares
    ) internal {
        if (msg.sender != from) {
            uint256 spenderAllowance = _allowances[from][msg.sender];
            if (spenderAllowance != type(uint256).max) {
                require(spenderAllowance >= shares, "low allowance");
                _allowances[from][msg.sender] = spenderAllowance - shares;
            }
        }
    }

}