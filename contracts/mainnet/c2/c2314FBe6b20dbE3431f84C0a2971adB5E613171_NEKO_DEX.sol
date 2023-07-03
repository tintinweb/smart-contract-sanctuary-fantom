/**
 *Submitted for verification at FtmScan.com on 2023-07-03
*/

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: contracts/NEKO_DEX.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title NEKO DEX Liquidity Pool
/// @author gas-limit.eth
/// @notice This contract establishes a liquidity pool for the NEKO DEX, allowing users to contribute liquidity and make a positive difference in the lives of cats requiring assistance.
/// Charitable organizations benefit from a 0.3% fee imposed on all trades, which is utilized to finance cat rescue operations.
/// @dev This contract is based on the Uniswap V2 Pair contract.

/*
⠀⠀⠀⠀⠀⠀⠀⢀⡖⣛⡒⠤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠤⢖⣛⡳⡄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢸⢹⠁⠈⠙⣦⠉⠓⢶⢻⣿⢹⣿⢓⡖⠒⠋⢡⡞⠉⠀⢱⣳⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡇⠸⠤⠔⠊⠁⠀⠀⠘⠾⠙⠞⠙⠟⠀⠀⠀⠀⠉⠒⠤⠼⢹⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⠇⠀⠀⠀⣀⣠⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⣀⡀⠀⠀⠈⣇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⡎⠀⠀⠀⠘⠛⠉⠉⠻⠆⠀⠀⠀⠀⠀⠀⠾⠋⠉⠙⠛⠀⠀⠀⠸⡆⢀⣠⣤⣄⡀⠀
⠀⠀⠀⠀⠀⢸⠀⠖⠒⠒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡒⠒⠒⣿⠋⢳⡄⢳⠹⡆
⠀⠀⠀⠀⠀⣹⠐⢛⣉⣭⠄⠀⠀⠰⣦⣀⣀⣠⠴⢦⣄⣀⣀⣠⠄⠀⠀⢸⣍⣉⠓⢽⣤⣼⣥⣾⣤⠇
⠀⠀⠀⠀⠀⠸⡆⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠉⢁⣟⠀𝐍 𝐄 𝐊 𝐎⠈⡇⠀
⠀⠀⠀⠀⠀⣰⣿⢦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣿⡿⠀⠀𝐃 𝐄 𝐗⠀⢰⡇⠀
⠀⠀⠀⣠⠞⠁⠙⢾⣼⣽⠷⣶⣶⢤⡤⣤⣤⣤⣤⣤⣤⣤⡤⣤⢴⠶⡖⣿⣿⠼⠛⠎⠎⠎⠎⢀⠞⠀⠀
⠀⠀⣰⠃⠀⠀⠀⣼⢋⢹⡀⡎⢹⢾⣦⣷⠛⠉⠙⢷⠾⢦⡧⠼⠾⠛⠋⠉⠀⠀⠀⠀⠐⣤⠎⠀⠀⠀
⢀⣾⣻⠀⠀⠀⠀⠹⣟⡭⠟⢹⠟⠾⣆⣻⡀⠰⡆⣸⢤⡄⡷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀
⢸⣇⠻⣄⠀⠀⠀⢀⡐⢷⡖⢛⣰⠉⣋⣹⣏⡛⠛⠣⠼⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡇⠀⠀⠀
⠘⣇⡙⣿⣦⣀⠀⠀⠉⣷⣟⣇⣨⣿⠟⠉⠉⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀
⠀⠻⣌⣹⣣⠈⡟⢳⣞⣽⣥⣼⣟⣥⡄⠀⢀⣸⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⠇⠀⠀⠀
⠀⠀⠈⠛⢧⡀⡗⢋⣉⠭⣽⣿⡉⠛⠁⢀⠏⡴⢻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡞⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠙⣏⠁⣠⠖⢹⣿⣇⠀⠀⠘⣄⣧⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠴⠋⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠈⠓⠳⠖⠛⠿⠿⣷⣖⣉⣁⣀⣀⣀⣀⣀⣀⣀⣤⠤⠴⠒⠊⠉⠀⠀⠀⠀⠀⠀⠀⠀
 */

contract NEKO_DEX is ERC20 {
    
    IERC20 public token0; // first asset   
    IERC20 public token1; // second asset
    address public feeReceiver; // charity foundation address

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    address burnAddress;

    /// @notice Creates a new liquidity pool for the given assets.
    /// @param _token0 The first asset.
    /// @param _token1 The second asset.
    /// @param _feeReceiver The charity foundation address.
    /// @param _name The name of the liquidity token.
    /// @param _symbol The symbol of the liquidity token.
    constructor(IERC20 _token0, IERC20 _token1, address _feeReceiver, string memory _name, string memory _symbol,address _burnAddress) ERC20(_name,_symbol) {
        token0 = _token0; 
        token1 = _token1; 
        feeReceiver = _feeReceiver; 
        burnAddress = _burnAddress;
    }

    /*//////////////////////////////////////////////////////////////
                            LIQUIDITY LOGIC
    //////////////////////////////////////////////////////////////*/


    /// @notice deposit tokens to the liquidity pool
    /// @param token0Amount The amount of the first asset to deposit.
    /// @param token1Amount The amount of the second asset to deposit.
    function addLiquidity(uint256 token0Amount, uint256 token1Amount) external {
        require(token0Amount > 0 && token1Amount > 0, "Invalid token amounts");

        // transfer tokens from sender to this contract
        token0.transferFrom(msg.sender, address(this), token0Amount); 
        token1.transferFrom(msg.sender, address(this), token1Amount); 

        // calculate liquidity
        // How is liquidity calculated? liquidity is calculated:
        // as the minimum of the two amounts multiplied by the total supply of the pool divided by the reserves of the token in the pool.
        // liquidity = min(x*totalSupply/xPool, y*totalSupply/yPool)
        // x is the amount of token0, y is the amount of token1
        // totalSupply is the total supply of the liquidity token
        // xPool is the amount of token0 in the pool, yPool is the amount of token1 in the pool
        // if the pool is empty, the liquidity is the square root of the product of the two amounts
        // for example, if the pool is empty, and the user deposits 1000 token0 and 1000 token1, the liquidity is sqrt(1000*1000) = 1000
        // if the pool is not empty, and the user deposits 1000 token0 and 1000 token1, the liquidity is min(1000*1000/1000, 1000*1000/1000) = 1000
    
        uint256 liquidity = 0;
        uint256 _totalSupply = totalSupply();
        // if the pool is empty, the liquidity is the square root of the product of the two amounts
        if (_totalSupply == 0) {
            // liquidity = sqrt(x*y)
            liquidity = sqrt(token0Amount * token1Amount) - MINIMUM_LIQUIDITY;
            _mint(burnAddress, MINIMUM_LIQUIDITY);

        } else {
            // liquidity = min(x*totalSupply/xPool, y*totalSupply/yPool)
            liquidity = min(token0Amount * _totalSupply / token0.balanceOf(address(this)), token1Amount * _totalSupply / token1.balanceOf(address(this))); 
        }

        require(liquidity > 0, "Insufficient liquidity");
        // mint liquidity tokens to sender
        _mint(msg.sender, liquidity);
    }

    /// @notice remove liquidity from the liquidity pool
    /// @param liquidity The amount of liquidity to remove.
    /// @dev The amount of liquidity to remove must be greater than 0.
    /// @dev The amount of liquidity to remove must be less than or equal to the total supply of the liquidity token.
    function removeLiquidity(uint256 liquidity) external {
        require(liquidity > 0, "Invalid liquidity amount");
        require(liquidity <= totalSupply(), "Insufficient liquidity");

        uint256 token0Amount = token0.balanceOf(address(this)) * liquidity / totalSupply();
        uint256 token1Amount = token1.balanceOf(address(this)) * liquidity / totalSupply();

        _burn(msg.sender, liquidity);
        token0.transfer(msg.sender, token0Amount);
        token1.transfer(msg.sender, token1Amount);
    }

    /*//////////////////////////////////////////////////////////////
                                SWAP LOGIC
    //////////////////////////////////////////////////////////////*/


    /// @notice swap tokens
    /// @param token0In The amount of the first asset to swap in.
    /// @param token1In The amount of the second asset to swap in.
    /// @param token0OutMin The minimum amount of the first asset to swap out.
    /// @param token1OutMin The minimum amount of the second asset to swap out.
function swap(uint256 token0In, uint256 token1In, uint256 token0OutMin, uint256 token1OutMin) external {
    require(token0In > 0 || token1In > 0, "Invalid input amount");
    require(token0In == 0 || token1In == 0, "Only one token should be input");

    uint256 token0Out; // the amount of token0 to swap out
    uint256 token1Out; // the amount of token1 to swap out

    uint _fee; // the fee
    
    /// @dev swap token0 for token1
    /// @dev swap token1 for token0
    /// @dev the swap is done by calculating the output amount based on the input amount and the reserves of the two tokens in the pool

    // swap token0 for token1
    if (token0In > 0) {
        token0.transferFrom(msg.sender, address(this), token0In); // transfer token0 from sender to this contract
        token1Out = getOutputAmountWithFee(token0In, true); // calculate the output amount of token1 based on the input amount of token0
        require(token1Out >= token1OutMin, "Slippage protection"); // check if the output amount of token1 is greater than the minimum output amount of token1
        _fee = getOutputAmountNoFee(token0In,true) - token1Out; // calculate the fee
        token1.transfer(msg.sender, token1Out); // transfer token1 to sender
        token1.transfer(feeReceiver,_fee); // transfer fee to feeReceiver
        
    } else {
    // swap token1 for token0
        token1.transferFrom(msg.sender, address(this), token1In); // transfer token1 from sender to this contract
        token0Out = getOutputAmountWithFee(token1In,false); // calculate the output amount of token0 based on the input amount of token1
        require(token0Out >= token0OutMin, "Slippage protection"); // check if the output amount of token0 is greater than the minimum output amount of token0
        _fee = getOutputAmountNoFee(token1In,false) - token0Out; // calculate the fee
        token0.transfer(msg.sender, token0Out); // transfer token0 to sender
        token0.transfer(feeReceiver,_fee); // transfer fee to feeReceiver
    }

}

    /// @notice get the output amount without fee
    /// @param inputAmount The amount of the input token.
    /// @param isToken0 Whether the input token is token0.
    /// @dev The output amount is calculated based on the input amount and the reserves of the two tokens in the pool.
    function getOutputAmountNoFee(uint256 inputAmount, bool isToken0) public view returns (uint256) {
    uint256 token0Balance = token0.balanceOf(address(this));
    uint256 token1Balance = token1.balanceOf(address(this));

    uint256 numerator;
    uint256 denominator;
    if (isToken0) {
        numerator = inputAmount * token1Balance;
        denominator = token0Balance + inputAmount;
    } else {
        numerator = inputAmount * token0Balance;
        denominator = token1Balance + inputAmount;
    }

        return numerator / denominator;
    }

    /// @notice get the output amount with fee
    /// @param inputAmount The amount of the input token.
    /// @param isToken0 Whether the input token is token0.
    /// @dev The output amount is calculated based on the input amount and the reserves of the two tokens in the pool.
    function getOutputAmountWithFee(uint256 inputAmount, bool isToken0) public view returns (uint256) {
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));

        uint256 inputAmountWithFee = inputAmount * 997;

        uint256 numerator;
        uint256 denominator;

        if (isToken0) {
            numerator = inputAmountWithFee * token1Balance;
            denominator = token0Balance * 1000 + inputAmountWithFee;
        } else {
            numerator = inputAmountWithFee * token0Balance;
            denominator = token1Balance * 1000 + inputAmountWithFee;
        }

        return numerator / denominator;
    }

    /*//////////////////////////////////////////////////////////////
                                UTILITIES
    //////////////////////////////////////////////////////////////*/


    /// @notice Returns the square root of a number.
    function sqrt(uint256 x) private pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /// @notice Returns the minimum of two numbers.
    /// what is a minimum number? It is a number that is less than or equal to all other numbers. 
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    

    


    /*//////////////////////////////////////////////////////////////
                            FRONT END GETTERS
    /////////////////////////////////////////////////////////////*/

    function getToken0Balance() public view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function getToken1Balance() public view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }

}