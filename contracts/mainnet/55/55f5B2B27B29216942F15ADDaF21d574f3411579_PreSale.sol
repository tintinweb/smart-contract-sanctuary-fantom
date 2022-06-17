/**
 *Submitted for verification at FtmScan.com on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PreSale is Ownable {

    using SafeMath for uint256;

    struct UserInfo {
        address buyer;
        uint256 ptokenAmount;
    }

    IERC20 public PTOKEN;
    IERC20 public RCTOKEN = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    uint256 public constant PTOKEN_DECIMAL = 9;
    uint256 public constant RCTOKEN_DECIMAL = 6;
    address public Recipient = 0xFCe23edEaBbEF3d2f96F2e1a60248e8b1dBC0346;

    uint256 public tokenPerEth = 70000; // 70 ptoken per 1 usdc
    uint256 public minBuyLimit = 1 * 10 ** RCTOKEN_DECIMAL;
    uint256 public maxBuyLimit = 1500 * 10 ** RCTOKEN_DECIMAL;

    uint256 public softCap = 100000 * 10 ** RCTOKEN_DECIMAL;
    uint256 public hardCap = 150000 * 10 ** RCTOKEN_DECIMAL;

    uint256 public totalRaisedAmount = 0; // total USDC raised by sale
    uint256 public totaltokenSold = 0;

    uint256 public startTime = 1655641800;
    uint256 public endTime = 1655901000;

    bool public claimOpened;
    bool public contractPaused; // circuit breaker

    mapping(address => uint256) private _totalPaid;
    mapping(address => UserInfo) public userinfo;

    event Deposited(uint amount);
    event Claimed(address receiver, uint amount);

    modifier checkIfPaused() {
        require(contractPaused == false, "contract is paused");
        _;
    }
    
    function setPresaleToken(address tokenaddress) external onlyOwner {
        require( tokenaddress != address(0) );
        PTOKEN = IERC20(tokenaddress);
    }

    function setRecipient(address recipient) external onlyOwner {
        Recipient = recipient;
    }

    function setTokenPerEth(uint256 rate) external onlyOwner {
        tokenPerEth = rate;
    }

    function setMinBuyLimit(uint256 amount) external onlyOwner {
        minBuyLimit = amount;    
    }

    function setMaxBuyLimit(uint256 amount) external onlyOwner {
        maxBuyLimit = amount;    
    }
    
    function updateCap(uint256 _hardcap, uint256 _softcap) external onlyOwner {
        softCap = _softcap;
        hardCap = _hardcap;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, 'past timestamp');
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        require(_endTime > startTime, 'should be bigger than start time');
        endTime = _endTime;
    }

    function openClaim(address pTokenaddress, bool value) external onlyOwner {
        require( pTokenaddress != address(0) );
        require(value != claimOpened, 'Already opened');
        PTOKEN = IERC20(pTokenaddress);
        claimOpened = value;
    }

    function togglePause() external onlyOwner returns (bool){
        contractPaused = !contractPaused;
        return contractPaused;
    }

    function deposit(uint256 amount) public checkIfPaused {
        require(block.timestamp > startTime, 'Sale has not started');
        require(block.timestamp < endTime, 'Sale has ended');
        require(totalRaisedAmount <= hardCap, 'HardCap exceeded');
        require(
                _totalPaid[msg.sender].add(amount) <= maxBuyLimit
                && _totalPaid[msg.sender].add(amount) >= minBuyLimit,
                "Investment Amount Invalid."
        );

        uint256 tokenAmount = amount.mul(tokenPerEth);
        if (userinfo[msg.sender].buyer == address(0)) {
            UserInfo memory l;
            l.buyer = msg.sender;
            l.ptokenAmount = tokenAmount;
            userinfo[msg.sender] = l;
        }
        else {
            userinfo[msg.sender].ptokenAmount += tokenAmount;
        }

        totalRaisedAmount = totalRaisedAmount.add(amount);
        totaltokenSold = totaltokenSold.add(tokenAmount);
        _totalPaid[msg.sender] = _totalPaid[msg.sender].add(amount);
        IERC20(RCTOKEN).transferFrom(msg.sender, Recipient, amount);
        emit Deposited(amount);
    }

    function claim() public {
        UserInfo storage l = userinfo[msg.sender];
        require(claimOpened, "Claim not open yet");
        require(l.buyer == msg.sender, "You are not allowed to claim");
        require(l.ptokenAmount > 0, "Invaild");

        uint256 amount = l.ptokenAmount;
        l.ptokenAmount = 0;
        require(amount <= PTOKEN.balanceOf(address(this)), "Insufficient balance");
        PTOKEN.transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function getUnsoldTokens(address token, address to) external onlyOwner {
        require(block.timestamp > endTime, "You cannot get tokens until the presale is closed.");
        if(token == address(0)){
            payable(to).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(to, IERC20(token).balanceOf(address(this)));
        }
    }

    function getUserRemainingAllocation(address account) external view returns ( uint256 ) {
        return maxBuyLimit.sub(_totalPaid[account]);
    }
}