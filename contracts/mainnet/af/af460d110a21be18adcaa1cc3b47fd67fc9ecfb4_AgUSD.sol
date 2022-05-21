/**
 *Submitted for verification at FtmScan.com on 2022-05-21
*/

/**
 *Submitted for verification at FtmScan.com on 2021-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract AGUSDErrors {

  struct Error {
    uint256 code;
    string message;
  }

  Error public NOT_ENOUGH_SENT = Error(1, "Not enough collateral sent");
  Error public NOT_ENOUGH_TO_REDEEM = Error(2, "Not enough AgUSD to redeem");
  Error public NOT_ENOUGH_COLLATERAL = Error(3, "Not enough collateral to redeem");

  Error public GATE_LOCKED = Error(101, "Cannot deposit with this collateral");

  Error public NOT_AUTH = Error(401, "Not authorized");
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Not authorized");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

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

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {

    function burn(uint256 amount) internal virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

interface yearnVault is IERC20 {
  function deposit(uint256 amount, address recipient) external returns (uint256);
}

contract AgUSD is ERC20, ERC20Burnable, Ownable, AGUSDErrors {
    /*
     *  AgUSD, Aggregated USD
     *  Aggregated USD is an overcollateralized stablecoin which works by:
     *
     *  1) User deposits DAI, fUSDT, USDC, MIM or FRAX
     *  2) 50% of stablecoin investment gets deposited to yearn.finance vaults, other stays in the contract, to allow for partial redemptions.
     *  3) yv[coin] gets sent to multisig treasury
     *
     *  - yv deposits ensure coins are ALWAYS earning yeild.
     *  - having many different dollar-pegged stables will help protect the peg if one coin depegs.
     *
     *  [ Scenario 1 ]
     *  Coin prices go from $1 each to:
     *  DAI | FUSDT | USDC | MIM | FRAX
     * ----+-------+------+-----+-------
     *  $1 |  $1   |  $1  | $.75| $1
     *
     * 5 AgUSD would be backed by $4.75, and 1 AgUSD would be backed by $0.95.
     *
     * [ Scenario 2 ]
     *  Coin prices go from $1 each to:
     *  DAI | FUSDT | USDC | MIM | FRAX
     * ----+-------+------+-----+-------
     *  $1 |  $0.1 |  $1  | $1  | $1
     *
     * 5 AgUSD would be backed by $4.1, and 1 AgUSD would be backed by $0.82.
     *
     * [ Scenario 3 ]
     *  Coin prices go from $1 each to:
     *  DAI | FUSDT | USDC | MIM | FRAX
     * ----+-------+------+-----+-------
     *  $1 |  $0.1 |  $1  | $.75| $1
     *
     * 5 AgUSD would be backed by $3.85, and 1 AgUSD would be backed by $0.77.
     *
     * You can see, that even in the most dire circumstances (1 token at $0.1 and/or another at $0.75), the AgUSD peg only loses [5|18|23]% of its peg!
     * This allows the treasury to grow more, while only having to spend minimal amounts on maintaining the peg.
     *
     */

    constructor() ERC20("Aggregated USD", "AgUSD") {}

    address private dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address private fusdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
    address private usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address private mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address private frax = 0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355;

    bool public mimGate = true;
    bool public daiGate = true;
    bool public usdcGate = true;
    bool public fusdtGate = true;
    bool public fraxGate = true;

    address private yvdai = 0x637eC617c86D24E421328e6CAEa1d92114892439;
    address private yvfusdt = 0x148c05caf1Bb09B5670f00D511718f733C54bC4c;
    address private yvusdc = 0xEF0210eB96c7EB36AF8ed1c20306462764935607;
    address private yvmim = 0x0A0b23D9786963DE69CB2447dC125c49929419d8;
    address private yvfrax = 0x357ca46da26E1EefC195287ce9D838A6D5023ef3;

    address private multisig = 0x3e522051A9B1958Aa1e828AC24Afba4a551DF37d;

    // these functions will be payable to optimise gas

    function mintFromDAI(uint256 amount) public payable {
        IERC20 daiToken = IERC20(dai);
        require(daiGate);
        require(
            daiToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvdai).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromUSDC(uint256 amount) public payable {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcGate);
        require(
            usdcToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvusdc).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromFUSDT(uint256 amount) public payable {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtGate);
        require(
            fusdtToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvfusdt).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromMIM(uint256 amount) public payable {
        IERC20 mimToken = IERC20(mim);
        require(mimGate);
        require(
            mimToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvmim).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function mintFromFRAX(uint256 amount) public payable {
        IERC20 fraxToken = IERC20(frax);
        require(fraxGate);
        require(
            fraxToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        yearnVault(yvfrax).deposit(amount/2, multisig);
        _mint(msg.sender, amount);
    }

    function AgusdToDai(uint256 amount) public payable {
        IERC20 daiToken = IERC20(dai);
        require(daiToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        daiToken.transfer(msg.sender, amount);
    }

    function AgusdToFusdt(uint256 amount) public payable {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        fusdtToken.transfer(msg.sender, amount / 10**12);
    }

    function AgusdToUsdc(uint256 amount) public payable {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        usdcToken.transfer(msg.sender, amount / 10**12);
    }

    function AgusdToMim(uint256 amount) public payable {
        IERC20 mimToken = IERC20(mim);
        require(mimToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        mimToken.transfer(msg.sender, amount);
    }

    function AgusdToFrax(uint256 amount) public payable {
        IERC20 fraxToken = IERC20(frax);
        require(fraxToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        fraxToken.transfer(msg.sender, amount);
    }

    function getUSDCBalance() public view returns(uint256) {
        return ERC20(usdc).balanceOf(address(this));
    }

    function getFUSDTBalance() public view returns(uint256) {
        return ERC20(fusdt).balanceOf(address(this));
    }

    function getDAIBalance() public view returns(uint256) {
        return ERC20(dai).balanceOf(address(this));
    }

    function getMIMBalance() public view returns(uint256) {
        return ERC20(mim).balanceOf(address(this));
    }

    function getFRAXBalance() public view returns(uint256) {
        return ERC20(mim).balanceOf(address(this));
    }

    function setMimGate(bool mimStatus) public onlyOwner {
        mimGate = mimStatus;
    }

    function setDaiGate(bool daiStatus) public onlyOwner {
        daiGate = daiStatus;
    }

    function setFusdtGate(bool fusdtStatus) public onlyOwner {
        fusdtGate = fusdtStatus;
    }

    function setUsdcGate(bool usdcStatus) public onlyOwner {
        usdcGate = usdcStatus;
    }

    function setFraxGate(bool fraxStatus) public onlyOwner {
        fraxGate = fraxStatus;
    }
}