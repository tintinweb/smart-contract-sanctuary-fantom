// SPDX-FileCopyrightText: 2020 Lido <[email protected]>

// SPDX-License-Identifier: GPL-3.0

// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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


pragma solidity ^0.8.0;

contract DogDog is IERC20, IERC20Metadata, Ownable {
    
    struct RebaseData {
        uint8 currentEra;
        uint32 eraTargetMultiplier;
        uint16 deltaFirstEra;
        uint16 deltaSecondEra;
        uint16 deltaDecimalPrecision;
        uint32 lastRebaseTime;
        uint32 epochFirstEra;
        uint32 epochSecondEra;
    }

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 0;
    string private _name = "Dog Dog";
    string private _symbol = "WOOF";

    uint256 public multiplier = 1000000000;

    RebaseData public rebaseData;

    constructor() {
        _mint(msg.sender, 69 * (10**18));
        _initialize();
    }

    function _initialize() private {
        rebaseData.currentEra = 0;
        rebaseData.eraTargetMultiplier = 700000000;
        rebaseData.deltaFirstEra = 169;
        rebaseData.deltaSecondEra = 972;
        rebaseData.deltaDecimalPrecision = 10000;
        rebaseData.lastRebaseTime = 0;
        rebaseData.epochFirstEra = 0; // 10mins
        rebaseData.epochSecondEra = 0; // 1 hour
    }

    // Public View

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _toMultipliedAmount(_totalSupply);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _toMultipliedAmount(_balances[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _toMultipliedAmount(_allowances[owner][spender]);
    }

    // Public

    // Called externally, therefore amount is post multiplier
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, _fromMultipliedAmount(amount));
        return true;
    }

    // Called externally, therefore amount is post multiplier
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, _fromMultipliedAmount(amount));
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 baseAmount = _fromMultipliedAmount(amount);

        _transfer(sender, recipient, baseAmount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= baseAmount, "DD: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - baseAmount);
        }

        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + _fromMultipliedAmount(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 baseAmount = _fromMultipliedAmount(subtractedValue);

        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= baseAmount, "DD: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - baseAmount);
        }

        return true;
    }

    function rebase() public returns (bool) {
        return _rebase();
    }

    function transferAndRebase(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, _fromMultipliedAmount(amount));
        return _rebase();
    }

    // Internal 
    
    // Calls to _transfer should use base amounts before the multiplier is applied
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "DD: transfer from the zero address");
        require(recipient != address(0), "DD: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "DD: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "DD: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "DD: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "DD: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "DD: approve from the zero address");
        require(spender != address(0), "DD: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {}

    function _toMultipliedAmount(uint256 amount) private view returns (uint256) {
        return amount * multiplier;
    } 

    function _fromMultipliedAmount(uint256 amount) private view returns (uint256) {
        return amount / multiplier;
    }

    function _rebase() private returns(bool) {
        if (rebaseData.currentEra == 3) {
            // Era 3 - Rebase completed, Multiplier == 1.0
            return false;
        }else if (rebaseData.currentEra == 2) {
            // Era 2
            if (block.timestamp > rebaseData.lastRebaseTime + rebaseData.epochSecondEra) {
                // Execute Era 2 Rebase
                uint256 numerator = multiplier * (rebaseData.deltaDecimalPrecision - rebaseData.deltaSecondEra);

                if(numerator < rebaseData.deltaDecimalPrecision) {
                    rebaseData.currentEra = 3;
                    multiplier = 1;
                    rebaseData.lastRebaseTime = uint32(block.timestamp);
                    return true;
                }

                rebaseData.lastRebaseTime = uint32(block.timestamp);
                multiplier = numerator / rebaseData.deltaDecimalPrecision;

                return true;
            }else {
                // Still in the last epoch
                return false;
            }
        }else {
            // Era 1
            if (block.timestamp > rebaseData.lastRebaseTime + rebaseData.epochFirstEra) {
                // Execute Era 1 Rebase
                multiplier = multiplier * (rebaseData.deltaDecimalPrecision - rebaseData.deltaFirstEra) / rebaseData.deltaDecimalPrecision;

                if (multiplier < rebaseData.eraTargetMultiplier) {
                    rebaseData.currentEra = 2;
                }

                rebaseData.lastRebaseTime = uint32(block.timestamp);

                return true;
            }else {
                // Still in the last epoch
                return false;
            }
        }
    }
}