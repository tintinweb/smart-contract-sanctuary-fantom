/**
 *Submitted for verification at FtmScan.com on 2021-11-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


// AgUSD Errors
contract AGUSDErrors {

  struct Error {
    uint256 code;
    string message;
  }

  Error internal NOT_ENOUGH_SENT = Error(1, "Not enough collateral sent");
  Error internal NOT_ENOUGH_TO_REDEEM = Error(2, "Not enough AgUSD to redeem");
  Error internal NOT_ENOUGH_COLLATERAL = Error(3, "Not enough collateral to redeem");

  Error internal GATE_LOCKED = Error(101, "Cannot deposit with this collateral");

  Error internal NOT_AUTH = Error(401, "Not authorized");
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

interface YvVault {
  function deposit () external returns (uint256);
  function deposit (uint256 _amount) external returns (uint256);
  function deposit (uint256 _amount, address recipient) external returns (uint256);
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

    address private multisig = 0x3e522051A9B1958Aa1e828AC24Afba4a551DF37d;

    uint256 public treasurySend = 2;


    event SetGate(string ASSET, bool NEWGATE);
    event ChangeSend(uint256 _original, uint256 _new);
    event ChangedMultisig(address _old, address _new);


    // these functions will be payable to optimise gas

    constructor() ERC20("AggregatedUSD", "AgUSD") {  }

    function mintFromDAI(uint256 amount) public payable {
        IERC20 daiToken = IERC20(dai);
        require(daiGate, GATE_LOCKED.message);
        require(
            daiToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        daiToken.transferFrom(
            address(this),
            multisig,
            amount / treasurySend
        );
        _mint(msg.sender, amount);
    }

    function mintFromUSDC(uint256 amount) public payable {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcGate, GATE_LOCKED.message);
        require(
            usdcToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ),
            'Could not transfer tokens from your address to this contract'
        );
        usdcToken.transferFrom(
            address(this),
            multisig,
            (amount / 10**12) / treasurySend
        );
        _mint(msg.sender, amount);
    }

    function mintFromFUSDT(uint256 amount) public payable {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtGate, GATE_LOCKED.message);
        require(
            fusdtToken.transferFrom(
                msg.sender,
                address(this),
                amount / 10**12
            ),
            'Could not transfer tokens from your address to this contract'
        );
        fusdtToken.transferFrom(
            address(this),
            multisig,
            (amount / 10**12) / treasurySend
        );
        _mint(msg.sender, amount);
    }

    function mintFromMIM(uint256 amount) public payable {
        IERC20 mimToken = IERC20(mim);
        require(mimGate, GATE_LOCKED.message);
        require(
            mimToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        mimToken.transferFrom(
            address(this),
            multisig,
            amount / treasurySend
        );
       _mint(msg.sender, amount);
    }

    function mintFromFRAX(uint256 amount) public payable {
        IERC20 fraxToken = IERC20(frax);
        require(fraxGate, GATE_LOCKED.message);
        require(
            fraxToken.transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            'Could not transfer tokens from your address to this contract'
        );
        fraxToken.transferFrom(
            address(this),
            multisig,
            amount / treasurySend
        );
       _mint(msg.sender, amount);
    }

    function AgUSDToDAI(uint256 amount) public payable {
        IERC20 daiToken = IERC20(dai);
        require(daiToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        daiToken.transfer(msg.sender, amount);
    }

    function AgUSDToFUSDT(uint256 amount) public payable {
        IERC20 fusdtToken = IERC20(fusdt);
        require(fusdtToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        fusdtToken.transfer(msg.sender, amount / 10**12);
    }

    function AgUSDToUSDC(uint256 amount) public payable {
        IERC20 usdcToken = IERC20(usdc);
        require(usdcToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        usdcToken.transfer(msg.sender, amount / 10**12);
    }

    function AgUSDToMIM(uint256 amount) public payable {
        IERC20 mimToken = IERC20(mim);
        require(mimToken.balanceOf(address(this)) >= amount, NOT_ENOUGH_TO_REDEEM.message);
        require(balanceOf(msg.sender) >= amount);
        burn(amount);
        mimToken.transfer(msg.sender, amount);
    }

    function AgUSDToFRAX(uint256 amount) public payable {
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
        return ERC20(frax).balanceOf(address(this));
    }

    function setMimGate(bool mimStatus) public onlyOwner {
        mimGate = mimStatus;
        emit SetGate("MIM", mimStatus);
    }

    function setDaiGate(bool daiStatus) public onlyOwner {
        daiGate = daiStatus;
        emit SetGate("DAI", daiStatus);
    }

    function setFusdtGate(bool fusdtStatus) public onlyOwner {
        fusdtGate = fusdtStatus;
        emit SetGate("fUSDT", fusdtStatus);
    }

    function setUsdcGate(bool usdcStatus) public onlyOwner {
        usdcGate = usdcStatus;
        emit SetGate("USDC", usdcStatus);
    }

    function setFraxGate(bool fraxStatus) public onlyOwner {
        fraxGate = fraxStatus;
        emit SetGate("FRAX", fraxStatus);
    }

    function setTreasurySent(uint256 newSend) public onlyOwner {
        emit ChangeSend(treasurySend, newSend);
        treasurySend = newSend;
    }

    function setMultisig(address newSig) public onlyOwner {
        emit ChangedMultisig(multisig, newSig);
        multisig = newSig;
    }
}