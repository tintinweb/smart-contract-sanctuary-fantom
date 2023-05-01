/**
 *Submitted for verification at FtmScan.com on 2023-05-01
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/*


  /$$$$$$  /$$                                         /$$           /$$
 /$$__  $$|__/                                        |__/          | $$
| $$  \__/ /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$ /$$  /$$$$$$ | $$
| $$$$    | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/| $$ |____  $$| $$
| $$_/    | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$  /$$$$$$$| $$
| $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$ /$$__  $$| $$
| $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$| $$|  $$$$$$$| $$
|__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/|__/ \_______/|__/
                                                                        
                                                                        
                                                                        
  /$$$$$$                                    /$$                        
 /$$__  $$                                  | $$                        
| $$  \__//$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$/$$$$ 
| $$$$   /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$| $$_  $$_  $$
| $$_/  | $$  \__/| $$$$$$$$| $$$$$$$$| $$  | $$| $$  \ $$| $$ \ $$ \ $$
| $$    | $$      | $$_____/| $$_____/| $$  | $$| $$  | $$| $$ | $$ | $$
| $$    | $$      |  $$$$$$$|  $$$$$$$|  $$$$$$$|  $$$$$$/| $$ | $$ | $$
|__/    |__/       \_______/ \_______/ \_______/ \______/ |__/ |__/ |__/
                                                                        
                                                                        
                                                                        
*/



contract Financial_Freedom {
    string public name = "Financial Freedom";
    string public symbol = "FIFR";
    uint256 public decimals = 18;
    uint256 public totalSupply = 400000000 * (10**decimals);
    uint256 public buyFee = 5;
    uint256 public sellFee = 5;
    bool public buyEnabled = false;
    bool public feeModifiable = false;
    bool public txPause = false;
    bool public blackListEnabled = false;
    bool public whiteListEnabled = false;
    uint256 public maxTxAmount = 0;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(!txPause, "Transfers are paused");
        require(value <= balanceOf[msg.sender], "Insufficient balance");
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(!txPause, "Transfers are paused");
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        _transfer(from, to, value);
        allowance[from][msg.sender] -= value;
        emit Approval(from, msg.sender, allowance[from][msg.sender]);
        return true;
    }
    
    function setBuyFee(uint256 newFee) public {
        require(feeModifiable, "Fee modification is not allowed");
        buyFee = newFee;
    }
    
    function setSellFee(uint256 newFee) public {
        require(feeModifiable, "Fee modification is not allowed");
        sellFee = newFee;
    }
    
    function enableBuy() public {
        buyEnabled = true;
    }
    
    function disableBuy() public {
        buyEnabled = false;
    }
    
    function enableFeeModification() public {
        feeModifiable = true;
    }
    
    function disableFeeModification() public {
        feeModifiable = false;
    }
    
    function pauseTransfers() public {
        txPause = true;
    }
    
    function unpauseTransfers() public {
        txPause = false;
    }
    
    function enableBlackList() public {
        blackListEnabled = true;
    }
    
    function disableBlackList() public {
        blackListEnabled = false;
    }
    
    function enableWhiteList() public {
        whiteListEnabled = true;
    }
    
    function disableWhiteList() public {
        whiteListEnabled = false;
    }
    
    function setMaxTxAmount(uint256 amount) public {
        maxTxAmount = amount;
    }
    
    function addToBlackList(address[] memory addresses) public {
        require(blackListEnabled, "Blacklist is not enabled");
        for (uint256 i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = 0;
        }
    }
    
        function addToWhiteList(address[] memory addresses) public {
        require(whiteListEnabled, "Whitelist is not enabled");
        for (uint256 i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = totalSupply / 2;
        }
    }

    
    
    function removeFromBlackList(address[] memory addresses) public {
        require(blackListEnabled, "Blacklist is not enabled");
        for (uint256 i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = totalSupply / 2;
        }
    }
    
    function removeFromWhiteList(address[] memory addresses) public {
        require(whiteListEnabled, "Whitelist is not enabled");
        for (uint256 i = 0; i < addresses.length; i++) {
            balanceOf[addresses[i]] = 0;
        }
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "Transfer from the zero address");
        require(to != address(0), "Transfer to the zero address");
        require(value > 0, "Transfer amount must be greater than zero");
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= maxTxAmount || maxTxAmount == 0, "Transfer amount exceeds maximum");
        
        uint256 fee = 0;
        if (from != msg.sender && buyEnabled && msg.sender != address(this)) {
            fee = (value * buyFee) / 100;
        }
        if (from != msg.sender && !buyEnabled && msg.sender != address(this)) {
            fee = (value * sellFee) / 100;
        }
        uint256 netValue = value - fee;
        balanceOf[from] -= value;
        balanceOf[to] += netValue;
        balanceOf[address(this)] += fee;
        
        emit Transfer(from, to, netValue);
        if (fee > 0) {
            emit Transfer(from, address(this), fee);
        }
    }
    
    function withdraw(uint256 amount) public {
        require(amount <= balanceOf[address(this)], "Insufficient balance");
        balanceOf[address(this)] -= amount;
        balanceOf[msg.sender] += amount;
        emit Transfer(address(this), msg.sender, amount);
    }
    
    function withdrawAll() public {
        uint256 amount = balanceOf[address(this)];
        balanceOf[address(this)] = 0;
        balanceOf[msg.sender] += amount;
        emit Transfer(address(this), msg.sender, amount);
    }
}