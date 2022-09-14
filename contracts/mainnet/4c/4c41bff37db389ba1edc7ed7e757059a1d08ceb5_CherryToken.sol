/**
 *Submitted for verification at FtmScan.com on 2022-09-13
*/

// Cherry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Cherry Token (CHRY) contract
 *
 * ERC20 + burn() + mint()
 *
 * Burning:
 *  - token owners can burn their tokens
 *  - approved address can burn tokens from approvers
 *  - nobody else can burn tokens
 *
 * Minting:
 *  - only allowed to minter
 *  - only once per epoch
 *  - never mint more than 5% supply / epoch (unless low supply)
 *
 * Owner powers:
 *   - setMinter() as long as contract is not sealed
 *   - seal()      seal contract so that minter cannot be changed ever after
 */


abstract contract Ownable {

  // ==== Events      ====
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  // ==== Storage     ====
  // Private so it cannot be changed by inherited contracts
  address private _owner;


  // ==== Constructor ====
  constructor() {
    _transferOwnership(msg.sender);
  }


  // ==== Modifiers   ====
  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }


  // ==== Views       ====
  function owner() public view virtual returns (address) {
    return _owner;
  }


  // ==== Mutators    ====

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner_) public virtual onlyOwner {
    require(newOwner_ != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner_);
  }


  // ==== Internals   ====

  function _transferOwnership(address newOwner_) internal virtual {
    address oldOwner = owner();
    _owner = newOwner_;
    emit OwnershipTransferred(oldOwner, newOwner_);
  }
}


interface IERC20 {

    event Transfer(address indexed from,  address indexed to,      uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply()                             external view returns (uint256);
    function balanceOf(address account)                external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(     address to,                uint256 amount)  external returns (bool);
    function approve(      address spender,           uint256 amount)  external returns (bool);
    function transferFrom( address from,  address to, uint256 amount ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name()     external view returns (string memory);
    function symbol()   external view returns (string memory);
    function decimals() external view returns (uint8);
}


abstract contract ERC20 is IERC20, IERC20Metadata {

    // ==== Storage ====

    uint   private _totalSupply;

    // Strings cannot be immutable
    string private _name;
    string private _symbol;

    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    // ==== Constructor ====

    constructor(string memory name_, string memory symbol_) {
      _name = name_;
      _symbol = symbol_;
    }


    // ==== Views      ====

    function name() public view virtual override returns (string memory) {
      return _name;
    }

    function symbol() public view virtual override returns (string memory) {
      return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
      return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
      return _balances[account];
    }


    // ==== Mutators   ====

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
      address owner = msg.sender;
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
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    // ==== Internals ====

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to   != address(0), "ERC20: transfer to the zero address");

        uint fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply       += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner   != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}


// Minimal interface for Minter contract
interface IMinter {
  // returns the token address that the minter wants to mint
  function token() external view returns (address);
}


contract CherryToken is ERC20, Ownable {

  // ==== Constants ====
  uint    constant PERIOD    = 6 hours;
  uint    constant minSupply = 10000 ether;

  // ==== Storage   ====
  bool    public isSealed;
  uint32  public epoch;
  address public minter;


  // ==== Constructor ====
  constructor() ERC20("Cherry", "CHRY") {
      //   10 000 for initial liquidity pool
      // + 10 000 for airdrops and Cherrific team
      _mint(msg.sender, 20000 ether);
  }


  // ==== Governance  ====

  // seal contract for ever
  function seal() external onlyOwner {
    isSealed = true;
  }

  // set minter as long as contract isn't sealed
  function setMinter(address minter_) external onlyOwner {
    // function disabled once contract is sealed
    require( ! isSealed , "Contract is sealed");

    // Safeguard: make sure we set the correct minter
    // If this fails, it means minter is not set correctly
    require( IMinter(minter_).token() == address(this), "Minter not correctly set");

    minter = minter_;
  }


  // ==== Views    ====

  // Current epoch
  function getEpoch() public view returns (uint) {
    return block.timestamp / PERIOD;
  }


  // ==== Mutators ====

  // from OpenZeppelin
  function burn(uint256 amount) external returns (bool) {
    _burn(msg.sender, amount);
    return true;
  }

  // from OpenZeppelin
  function burnFrom(address account, uint256 amount) external returns (bool) {
    _spendAllowance(account, msg.sender, amount);
    _burn(account, amount);
    return true;
  }




  // only minter can mint
  function mint(address recipient_, uint256 amount_) external returns (bool) {

    require(msg.sender == minter, "Only minter can mint");

    uint newEpoch = getEpoch();
    require(newEpoch > epoch, "Mint only once per epoch");

    // all below code can only run once per epoch

    epoch = uint32(newEpoch);

    // make sure we don't mint too much
    uint supply = totalSupply();
    if (supply < minSupply) {
      // during low supply, we don't want to mint up to more than 120% minSupply
      require( supply + amount_ <= (minSupply * 120) / 100, "Minting too much while low supply");
    } else {
      // make sure minter does not go crazy
      // don't mint more than 5% of total supply per epoch
      // +5 if to allow for rounding errors on the minter side
      require( amount_ <= (supply / 20) + 5, "Don't mint > 5% supply per epoch");
    }

    _mint(recipient_, amount_);
    return true;
  }

}