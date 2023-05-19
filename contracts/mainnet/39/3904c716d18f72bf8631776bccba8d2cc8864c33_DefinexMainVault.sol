/**
 *Submitted for verification at FtmScan.com on 2023-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;


interface IERC20Simplified {    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IERC20 {    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20MetadataS is IERC20Simplified {   
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC20Metadata is IERC20 {   
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library Address {   
    function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
           
            if (returndata.length > 0) {               

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20Simplified is Context, IERC20Simplified, IERC20MetadataS {
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

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
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

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


interface Strat {
    function WETH() external view returns (address);
    function router() external view returns (address);
    function lpToken() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function farm() external view returns (address);
    function pid() external view returns (uint256);
    function hasPid() external view returns (bool);
    function getTotalCapitalInternal() external view returns (uint256);
    function getTotalCapital() external view returns (uint256);
    function getAmountLPFromFarm() external view returns (uint256);
    function getPendingDFX(address) external view returns (uint256);
    function claimDFX(address) external;
    function setRouter(address) external;
    function setFeeCompound(uint) external;
    function setTokenReward(address) external;
    function requestWithdraw(address, uint256) external;
    function withdrawCollectedFee(address) external;
    function emergencyWithdraw(address) external;
    function autoCompound() external;
    function deposit() external payable returns (uint256);
    function depositAsMigrate() external;
    function migrate(uint256) external;
    function updateTWAP() external;
    function token1TWAP() external view returns (uint256);
    function token0TWAP() external view returns (uint256);
    function token1Price() external view returns (uint256);
    function token0Price() external view returns (uint256);
}

contract DefinexMainVault is ERC20Simplified, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;
    
    mapping(uint256 => bool) public nameExist;
    mapping(uint256 => address) public strategies;
    mapping(address => bool) public strategyExist;    
          
    address public governance;

    uint256[] private names;

    uint256 totalDepositToVault;
    
    event DepositToVault(uint256 amount);
    event Withdraw();
    event PartialMigrate(uint256 amount);
    event Migrate(uint256 amount);

    constructor() ERC20Simplified("Definex Vault Yield", "DVY") {        
        governance = 0x797DBFde2D607D0770BfceEacA0F808268baf2CE;
    }

    receive() external payable {
        deposit();
    }

    modifier onlyOwnerOrGovernance() {
        require(
            owner() == _msgSender() || governance == _msgSender(),
            "You are not owner or governance"
        );
        _;
    }

    modifier onlyGovernance() {
        require(governance == _msgSender(), "You are not governance");
        _;
    }

    function deposit() public payable {
        updateTWAPInternal();                
        require(names.length != 0);
        uint256 shares;        
        uint256 totalCapital = getTotalCapitalInternal();
        uint256 depositorCapitalValue = msg.value;                            
        for (uint256 i = 0; i < names.length; i++) {  
            uint256 depositValueForFarms = depositorCapitalValue / names.length;         
            Strat(strategies[names[i]]).deposit{value: depositValueForFarms}();
        }
        if (totalCapital == 0 || totalSupply() == 0) {
            shares = depositorCapitalValue;
        } else {
            uint256 ethShare = totalCapital * (10**12) / totalSupply();
            shares = depositorCapitalValue * (10**12) / ethShare;
        }
        _mint(msg.sender, shares);
        emit DepositToVault(depositorCapitalValue);
    }

    function requestWithdraw(uint256 _shares) public {
        require(names.length != 0, "NO Strat");
        require(totalSupply() != 0, "NO Shares");
        require(_shares > 0, "NO Shares");
        updateTWAPInternal();
        autoCompound();
        uint256 percent = _shares * 100 * 10**12 / totalSupply();
        require(_shares <= totalSupply(), "Shares canot be more than TotalSupply");
        _burn(msg.sender, _shares);
        withdrawStrategy(msg.sender, percent);
        emit Withdraw();
    }

    function claimableDFX() public {        
        updateTWAPInternal();
        autoCompound();        
        uint256 _DFXtoken = 0;
        uint256 _AmountDFX = 0;
        for (uint256 i; i < names.length; i++) {
            _DFXtoken = Strat(strategies[names[i]]).getPendingDFX(msg.sender);
            if(_DFXtoken > 0) {
                Strat(strategies[names[i]]).claimDFX(msg.sender);
                _AmountDFX += _DFXtoken;
            }
        }
        require(_AmountDFX > 0, "Dont have amount to claim");
    }
  
    function getPendingDFX(address _address) public view returns (uint256 _pendingDFX) {
        for (uint256 i; i < names.length; i++) {
            _pendingDFX += Strat(strategies[names[i]]).getPendingDFX(_address);
        }
    }   

    function nameIDs() public view returns (uint256[] memory) {
        return names;
    }

    function nameIDLength() public view returns(uint256) {
        return names.length;
    }
 
    function strategyInfo(uint256 _nameID) public view returns (
        address _router,
        address _lpToken,
        address _token1,
        address _token0,
        address _farm,
        string memory _pid,
        uint256 _totalLP,
        uint256 _totalCapital,
        uint256 _totalCapitalInternal) {
        require(nameExist[_nameID]);
        _router = Strat(strategies[_nameID]).router();
        _lpToken = Strat(strategies[_nameID]).lpToken();
        _token1 = Strat(strategies[_nameID]).token1();
        _token0 = Strat(strategies[_nameID]).token0();
        _farm = Strat(strategies[_nameID]).farm();
        if(Strat(strategies[_nameID]).hasPid()) {
            _pid = Strings.toString(Strat(strategies[_nameID]).pid());
        } else {
            _pid = "No pid";
        }
        _totalCapital = Strat(strategies[_nameID]).getTotalCapital();
        _totalCapitalInternal = Strat(strategies[_nameID]).getTotalCapitalInternal();
        _totalLP = Strat(strategies[_nameID]).getAmountLPFromFarm();
    }

    function strategyInfo2(uint256 _nameID) public view returns (
        uint256 _token1TWAP,
        uint256 _token0TWAP,
        uint256 _token1Price,
        uint256 _token0Price) {
        require(nameExist[_nameID]);
        address _strategy = strategies[_nameID];
        _token1TWAP = Strat(_strategy).token1TWAP();
        _token0TWAP = Strat(_strategy).token0TWAP();
        _token1Price = Strat(_strategy).token1Price();
        _token0Price = Strat(_strategy).token0Price();
    }
    
    function getTotalCapitalInternal() public view returns (uint256 totalCapital) {
        require(names.length != 0);
        for (uint256 i = 0; i < names.length; i++) {
            totalCapital += Strat(strategies[names[i]]).getTotalCapitalInternal();
        }
    }

    function autoCompound() public  {
        require(names.length != 0);
        for (uint256 i = 0; i < names.length; i++) {
            Strat(strategies[names[i]]).autoCompound();
        }
    }

    function getTotalCapital() public view returns (uint256 _totalCapital) {
        require(names.length != 0);
        for (uint256 i = 0; i < names.length; i++) {
            _totalCapital += Strat(strategies[names[i]]).getTotalCapital();
        }
    }

    function withdrawFee() onlyOwner public {
        for(uint256 i = 0; i < names.length; i++) {
            Strat(strategies[names[i]]).withdrawCollectedFee(msg.sender);
        }
    }

    function updateTWAPInternal() internal {
        for(uint256 i = 0; i < names.length; i++) {
            Strat(strategies[names[i]]).updateTWAP();
        }        
    }

    function updateTWAP() onlyOwner public {
        for(uint256 i = 0; i < names.length; i++) {
            Strat(strategies[names[i]]).updateTWAP();
        }        
    }

    function emergencyWithdraw() public onlyGovernance {
        for (uint256 i; i < names.length; i++) {
            Strat(strategies[names[i]]).emergencyWithdraw(msg.sender);
        }
    }

    function setGovernance(address _governance) external onlyOwner {
        require(
            _governance != address(0),
            "Government can not be a zero address"
        );
        governance = _governance;
    }

    function addStrategy(address _newStrategy, uint256 _nameID) public onlyOwnerOrGovernance {
        require(_newStrategy != address(0), "The strategy can not be a zero address");
        require(strategies[_nameID] == address(0), "This strategy is not empty");
        require(!strategyExist[_newStrategy], "This strategy already exists");
        if (!nameExist[_nameID]) {
            names.push(_nameID);
            nameExist[_nameID] = true;
            strategyExist[_newStrategy] = true;
        }
        strategies[_nameID] = _newStrategy;
    }

    function removeStrategy(uint256 _nameID) public onlyOwnerOrGovernance {
        _checkParameters(_nameID);        
        require(Strat(strategies[_nameID]).getTotalCapitalInternal() == 0,
            "Total capital internal is not zero"
        );
        require(Strat(strategies[_nameID]).getTotalCapital() == 0,
            "Total capital is not zero"
        );

        nameExist[_nameID] = false;
        strategyExist[strategies[_nameID]] = false;
        strategies[_nameID] = address(0);
        if(names.length != 1) {
            for(uint256 i = 0; i < names.length; i++){
                if(names[i] == _nameID) {
                    if(i != names.length-1) {
                        names[i] = names[names.length-1];
                    }
                    names.pop();
                }
            }
        } else {
            names.pop();
        }
    }

    function setTokenRewardForStrategy(address _token) public onlyOwnerOrGovernance{
        for (uint256 i; i < names.length; i++) {
            Strat(strategies[names[i]]).setTokenReward(_token);
        }
    }

    function setRouterForStrategy(address _newRouter, uint256 _nameID) public onlyOwnerOrGovernance {
        _checkParameters(_nameID);
        require(_newRouter != address(0), "Router canot null");
        Strat(strategies[_nameID]).setRouter(_newRouter);
    }

    function setFeeRewardForStrategy(uint _fee) public onlyOwnerOrGovernance {
        require(_fee > 0 && _fee <= 20);
        for (uint256 i; i < names.length; i++) {
            Strat(strategies[names[i]]).setFeeCompound(_fee);
        }
       
    }

    function migrate(
        uint256 _nameIdFrom,
        uint256 _amountInPercent,
        uint256 _nameIdTo) public onlyOwnerOrGovernance {
        _migrate(_nameIdFrom, _amountInPercent, _nameIdTo);
    }

    function withdrawSuddenTokens(address _token) public onlyOwner {
        IERC20(_token).transfer(payable(msg.sender), IERC20(_token).balanceOf(address(this)));
    }

    function _checkParameters(uint256 _nameID) internal view {
        require(names.length > 1, "Not enough strategies");
        require(nameExist[_nameID]);
    }

    function _migrate(uint256 _nameIdFrom, uint256 _amountInPercent, uint256 _nameIdTo) internal {
         
        _checkParameters(_nameIdFrom);
        require(nameExist[_nameIdTo], "The _nameIdTo value does not exist");
        require(
            _amountInPercent > 0 && _amountInPercent <= 100,
            "The _amountInPercent value sould be more than 0 and less than 100"
        );
        autoCompound();
        address WETH = Strat(strategies[_nameIdFrom]).WETH();
        // take Native Tokens from old strategy
        Strat(strategies[_nameIdFrom]).migrate(_amountInPercent);
        uint256 _balance = IERC20(WETH).balanceOf(address(this));
        if(_balance > 0){
            // put Native Tokens to new strategy
            IERC20(WETH).safeTransfer(strategies[_nameIdTo], _balance);
            Strat(strategies[_nameIdTo]).depositAsMigrate();
        }
        emit PartialMigrate(_amountInPercent);
    }

    function withdrawStrategy(address _receiver, uint256 _percent) internal {
        for (uint256 i; i < names.length; i++) {
            Strat(strategies[names[i]]).requestWithdraw(_receiver, _percent);
        }
    }


}