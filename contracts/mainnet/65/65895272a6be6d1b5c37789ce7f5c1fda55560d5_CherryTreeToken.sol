/**
 *Submitted for verification at FtmScan.com on 2022-09-09
*/

// CherryTreeToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * Cherry Tree Token (CHRT) contract
 *
 * Classic ERC20 contract.
 * No mint. No burn. No pause. No admin.
 * Fix supply: 100 000 Cherry Tree tokens
 *
 * Owner powers:
 *   - none
 */


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
}


// from OpenZepellin
// a bit hardened:
//   _transfer(), _approve() and _spendAllowance() are private
contract ERC20 is IERC20, IERC20Metadata {

    // ==== Storage ====

    uint256                                         private _totalSupply;
    string                                          private _name;
    string                                          private _symbol;
    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;


    // ==== Constructor ====

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    // ==== Views ====

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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    // ==== Mutators ====

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }


    // ==== Privates ====

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}



// Ownable from OpenZeppelin
abstract contract Ownable {

  // ==== Events ====

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  // ==== Storage ====

  address private _owner;


  // ==== Modifiers ====

  modifier onlyOwner() {
      _checkOwner();
      _;
  }


  // ==== Constructor ====

  constructor() {
    _transferOwnership(msg.sender);
  }


  // ==== Views ====

  function owner() public view virtual returns (address) {
    return _owner;
  }


  // ==== Mutators ====

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }


  // ==== Privates ====

  function _checkOwner() private view {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
  }

  function _transferOwnership(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

}



// And finaly the Cherry Tree token contract:

contract CherryTreeToken is ERC20, Ownable {

    constructor() ERC20("Cherry Tree", "CHRT") {
        // Supply is 100 000 for ever
        _mint(msg.sender, 100000 ether);
    }

}