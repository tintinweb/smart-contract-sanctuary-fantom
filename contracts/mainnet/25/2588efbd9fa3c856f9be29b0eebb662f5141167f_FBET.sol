/**
 *Submitted for verification at FtmScan.com on 2022-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IUniswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getamountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getamountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getamountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getamountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


 
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = msg.sender;
        _owner = 0xCbeb3C6aEC7040e4949F22234573bd06B31DE83b;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    bool locked;
    modifier safe() {
        require(!locked, "Reentrancy");
        locked = true;
        _;
        locked = false;
    }
    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


 
 
library Address {
    
    function isContract(address account) internal view returns (bool) {
            uint256 size;
           assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

           (bool success, ) = recipient.call{ value: amount }("");
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

           (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

           (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

           (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
library EnumerableSet {
    
    
    
    
    
    
    
    

    struct Set {
           bytes32[] _values;

              mapping (bytes32 => uint256) _indexes;
    }

    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
                          set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    
    function _remove(Set storage set, bytes32 value) private returns (bool) {
           uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { 
                            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

                     bytes32 lastvalue = set._values[lastIndex];

                   set._values[toDeleteIndex] = lastvalue;
                   set._indexes[lastvalue] = valueIndex; 

                   set._values.pop();

                   delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    
    
    
    
    
    
    
    
    
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    

    struct Bytes32Set {
        Set _inner;
    }

    
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    
    
    
    
    
    
    
    
    
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    

    struct AddressSet {
        Set _inner;
    }

    
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    
    
    
    
    
    
    
    
    
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    

    struct UintSet {
        Set _inner;
    }

    
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    
    
    
    
    
    
    
    
    
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}







contract FBET is IERC20, Ownable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => uint256) public _sellLock;


    EnumerableSet.AddressSet private _excluded;
    EnumerableSet.AddressSet private _excludedFromSellLock;

    
    string public constant _name = 'FloorBet';
    string public constant _symbol = 'FBET';
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply= 100 * 10**9 * 10**_decimals;

    uint256 swapLimit = 500 * 10**6 * 10**_decimals; 
    bool isSwapPegged = true;

    
    uint16 public  BuyLimitDivider=100; // 1%
    
    uint8 public   BalanceLimitDivider=50; // 2%
    
    uint16 public  SellLimitDivider=100; // 1%
    
    uint16 public  MaxSellLockTime= 10 seconds;
    
    mapping (address => bool) isTeam;
    
    
    address public constant UniswapRouter=0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;
    address public middleware_address;

    uint256 public _circulatingSupply =InitialSupply;
    uint256 public  balanceLimit = _circulatingSupply;
    uint256 public  sellLimit = _circulatingSupply;
    uint256 public  buyLimit = _circulatingSupply;

    
    uint8 public _buyTax;
    uint8 public _sellTax;
    uint8 public _transferTax;
    uint8 public _liquidityTax;
    uint8 public _marketingTax;
    uint8 public _burnTax;
    uint8 public _devTax;

    bool isTokenSwapManual = false;
    bool public antisniper = true;

    address public _UniswapPairAddress;
    IUniswapRouter02 public  _UniswapRouter;

    
    modifier onlyTeam() {
        require(_isTeam(msg.sender), "Caller not in Team");
        _;
    }
    
    function _isTeam(address addr) private view returns (bool){
        return addr==owner()||isTeam[addr];
    }

    modifier middleware() {
        require(middleware_address == msg.sender, "Not allowed");
        _;
    }
    
    
    constructor () {
        uint256 deployerBalance=_circulatingSupply*9/10;
        middleware_address = 0xCbeb3C6aEC7040e4949F22234573bd06B31DE83b; // REPLACE WITH The right one
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint256 injectBalance=_circulatingSupply-deployerBalance;
        _balances[address(this)]=injectBalance;
        emit Transfer(address(0), address(this),injectBalance);
        _UniswapRouter = IUniswapRouter02(UniswapRouter);

        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory()).createPair(address(this), _UniswapRouter.WETH());

        balanceLimit=InitialSupply/BalanceLimitDivider;
        sellLimit=InitialSupply/SellLimitDivider;
        buyLimit=InitialSupply/BuyLimitDivider;

        
        sellLockTime=2 seconds;

        _buyTax=2;
        _sellTax=2;
        _transferTax=2;
        _liquidityTax=50;
        _marketingTax=50;
        _excluded.add(msg.sender);
        _excludedFromSellLock.add(UniswapRouter);
        _excludedFromSellLock.add(_UniswapPairAddress);
        _excludedFromSellLock.add(address(this));
    } 

    
    function _transfer(address sender, address recipient, uint256 amount) private{
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        bool isExcluded = (_excluded.contains(sender) || _excluded.contains(recipient) || isTeam[sender] || isTeam[recipient]);

        bool isContractTransfer=(sender==address(this) || recipient==address(this));

        bool isLiquidityTransfer = ((sender == _UniswapPairAddress && recipient == UniswapRouter)
        || (recipient == _UniswapPairAddress && sender == UniswapRouter));


        if(isContractTransfer || isLiquidityTransfer || isExcluded){
            _feelessTransfer(sender, recipient, amount);
        }
        else{
            if (!tradingEnabled) {
                if (sender != owner() && recipient != owner()) {
                    if (antisniper) {
                        emit Transfer(sender,recipient,0);
                        return;
                    }
                    else {
                        require(tradingEnabled,"trading not yet enabled");
                    }
                }
            }
                
            bool isBuy=sender==_UniswapPairAddress|| sender == UniswapRouter;
            bool isSell=recipient==_UniswapPairAddress|| recipient == UniswapRouter;
            _taxedTransfer(sender,recipient,amount,isBuy,isSell);


        }
    }
    
    
    function _taxedTransfer(address sender, address recipient, uint256 amount,bool isBuy,bool isSell) private{
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");


        swapLimit = sellLimit/2;

        uint8 tax;
        if(isSell){
            if(!_excludedFromSellLock.contains(sender)){
                           require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Seller in sellLock");
                           _sellLock[sender]=block.timestamp+sellLockTime;
            }
            
            require(amount<=sellLimit,"Dump protection");
            tax=_sellTax;

        } else if(isBuy){
                   require(recipientBalance+amount<=balanceLimit,"whale protection");
            require(amount<=buyLimit, "whale protection");
            tax=_buyTax;

        } else {
                   require(recipientBalance+amount<=balanceLimit,"whale protection");
                          if(!_excludedFromSellLock.contains(sender))
                require(_sellLock[sender]<=block.timestamp||sellLockDisabled,"Sender in Lock");
            tax=_transferTax;

        }
                 if((sender!=_UniswapPairAddress)&&(!manualConversion)&&(!_isSwappingContractModifier))
            _swapContractToken(amount);
           uint256 contractToken=_calculateFee(amount, tax, _marketingTax+_liquidityTax+_burnTax+_devTax);
           uint256 taxedAmount=amount-(contractToken);

           _removeToken(sender,amount);

           _balances[address(this)] += contractToken;

           _addToken(recipient, taxedAmount);

        emit Transfer(sender,recipient,taxedAmount);



    }
    
    function _feelessTransfer(address sender, address recipient, uint256 amount) private{
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
           _removeToken(sender,amount);
           _addToken(recipient, amount);

        emit Transfer(sender,recipient,amount);

    }
    
    function _calculateFee(uint256 amount, uint8 tax, uint8 taxPercent) private pure returns (uint256) {
        return (amount*tax*taxPercent) / 10000;
    }
    
    
    function _addToken(address addr, uint256 amount) private {
           uint256 newAmount=_balances[addr]+amount;
        _balances[addr]=newAmount;

    }


    
    function _removeToken(address addr, uint256 amount) private {
           uint256 newAmount=_balances[addr]-amount;
        _balances[addr]=newAmount;
    }

    
    bool private _isTokenSwaping;
    
    uint256 public totalTokenSwapGenerated;
    
    uint256 public totalPayouts;

    
    uint256 public marketingBalance;
    
    

    
    function _distributeFeesETH(uint256 ETHamount) private {
        marketingBalance+=ETHamount;

    }


    

    
    uint256 public totalLPETH;
    
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    
    
    function _swapContractToken(uint256 totalMax) private lockTheSwap{
        uint256 contractBalance=_balances[address(this)];
        uint16 totalTax=_liquidityTax+_marketingTax;
        uint256 tokenToSwap=swapLimit;
        if(tokenToSwap > totalMax) {
            if(isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
           if(contractBalance<tokenToSwap||totalTax==0){
            return;
        }
        uint256 tokenForLiquidity=(tokenToSwap*_liquidityTax)/totalTax;
        uint256 tokenForMarketing= (tokenToSwap*_marketingTax)/totalTax;

        uint256 liqToken=tokenForLiquidity/2;
        uint256 liqETHToken=tokenForLiquidity-liqToken;

        uint256 swapToken=liqETHToken+tokenForMarketing;
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH=(address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH*liqETHToken)/swapToken;
        _addLiquidity(liqToken, liqETH);
        uint256 generatedETH=(address(this).balance - initialETHBalance);
        _distributeFeesETH(generatedETH);
    }
    
    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_UniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapRouter.WETH();

        _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    
    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        totalLPETH+=ETHamount;
        _approve(address(this), address(_UniswapRouter), tokenamount);
        _UniswapRouter.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @notice Utilities

    function Control_getLimits() public view returns(uint256 balance, uint256 sell){
        return(balanceLimit/10**_decimals, sellLimit/10**_decimals);
    }

    function Control_getTaxes() public view returns(uint256 devTax, uint256 burnTax,uint256 liquidityTax,uint256 marketingTax, uint256 buyTax, uint256 sellTax, uint256 transferTax){
        return (_devTax, _burnTax,_liquidityTax,_marketingTax,_buyTax,_sellTax,_transferTax);
    }
    
    function Control_getAddressSellLockTimeInSeconds(address AddressToCheck) public view returns (uint256){
        uint256 lockTime=_sellLock[AddressToCheck];
        if(lockTime<=block.timestamp)
        {
            return 0;
        }
        return lockTime-block.timestamp;
    }
    function Control_getSellLockTimeInSeconds() public view returns(uint256){
        return sellLockTime;
    }

    bool public sellLockDisabled;
    uint256 public sellLockTime;
    bool public manualConversion;


    function Control_SetPeggedSwap(bool isPegged) public onlyTeam {
        isSwapPegged = isPegged;
    }

    function Control_SetMaxSwap(uint256 max) public onlyTeam {
        swapLimit = max;
    }


    /// @notice ACL Functions

    function Access_SetTeam(address addy, bool booly) public onlyTeam {
        isTeam[addy] = booly;
    }

    function Access_ExcludeAccountFromFees(address account) public onlyTeam {
        _excluded.add(account);
    }
    function Access_IncludeAccountToFees(address account) public onlyTeam {
        _excluded.remove(account);
    }
    
    function Access_ExcludeAccountFromSellLock(address account) public onlyTeam {
        _excludedFromSellLock.add(account);
    }
    function Access_IncludeAccountToSellLock(address account) public onlyTeam {
        _excludedFromSellLock.remove(account);
    }

    function Team_WithdrawMarketingETH() public onlyTeam{
        uint256 amount=marketingBalance;
        marketingBalance=0;
        address sender = 0xD489CEF6C37cC23b50Cdfd13493969FCE005c753;
        (bool sent,) =sender.call{value: (amount)}("");
        require(sent,"withdraw failed");
    }

    
    function Control_SwitchManualETHConversion(bool manual) public onlyTeam{
        manualConversion=manual;
    }
    
    function Control_DisableSellLock(bool disabled) public onlyTeam{
        sellLockDisabled=disabled;
    }
    
    function UTILIY_SetSellLockTime(uint256 sellLockSeconds)public onlyTeam{
        sellLockTime=sellLockSeconds;
    }

    
    function Control_SetTaxes(uint8 devTaxes, uint8 burnTaxes, uint8 liquidityTaxes, uint8 marketingTaxes,uint8 buyTax, uint8 sellTax, uint8 transferTax) public onlyTeam{
        require(buyTax <= 15, "Taxes are too high");
        require(sellTax <= 15, "Taxes are too high");
        require(transferTax <= 15, "Taxes are too high");
        uint8 totalTax=devTaxes + burnTaxes +liquidityTaxes+marketingTaxes;
        require(totalTax==100, "burn+liq+marketing needs to equal 100%");
        _devTax = devTaxes;
        _burnTax = burnTaxes;
        _liquidityTax=liquidityTaxes;
        _marketingTax=marketingTaxes;

        _buyTax=buyTax;
        _sellTax=sellTax;
        _transferTax=transferTax;
    }
    

    function Control_ManualGenerateTokenSwapBalance(uint256 _qty) public onlyTeam{
        _swapContractToken(_qty * 10**_decimals);
    }

    
    function Control_UpdateLimits(uint256 newBuyLimit ,uint256 newBalanceLimit, uint256 newSellLimit) public onlyTeam{
        newBuyLimit = newBuyLimit *10**_decimals;
        newBalanceLimit=newBalanceLimit*10**_decimals;
        newSellLimit=newSellLimit*10**_decimals;
        require(newSellLimit >= InitialSupply/200, "Blocked by antirug functions");
        require(newBalanceLimit >= InitialSupply/200, "Blocked by antirug functions");
        require(newBuyLimit >= InitialSupply/200, "Blocked by antirug functions");
        buyLimit = newBuyLimit;
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
    }
    

    bool public tradingEnabled;
    address private _liquidityTokenAddress;

    
    function Settings_EnableTrading() public onlyTeam{
        tradingEnabled = true;
    }

    
    function Settings_LiquidityTokenAddress(address liquidityTokenAddress) public onlyTeam{
        _liquidityTokenAddress=liquidityTokenAddress;
    }
    

    function Control_setContractTokenSwapManual(bool manual) public onlyTeam {
        isTokenSwapManual = manual;
    }


    receive() external payable {}
    fallback() external payable {}

    /////////////////////////////////////////////// START OF BETTING FUNCTIONS ///////////////////////////////////////////////

    /// @notice Betting utilities

    IERC20 fbet = IERC20(address(this));

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /// @notice Betting writes /////////////////////////////////////////

    event place_bet(address _actor, uint256 id, uint256 side, string chain, string coin, uint256 amount);
    event cancel_bet(address _actor, uint256 id, uint256 refund, string chain, string currency, bool done);
    event pay_bet(address _actor, uint256 id, uint256 _value, string chain, string currency, bool done);

    struct bet {
        bool exists;
        bool active;
        bool ended;
        uint256 start_time;
        uint256 end_time;
        mapping(string => mapping(string => mapping(uint256 => uint256))) side_balance; // Ex: side_balance["BSC"]["BUSD"][1] is the balance of side 1 in busd on bsc
        mapping(string => bool) chain_enabled;
        mapping(string => string) chain_wallet;
        uint256 sides;
        uint256 winner_side;
        uint256 loser_side;
    }
    
    uint256 bet_index;
    mapping(uint256 => bet) bets;

    struct better {
        bool active;
        bool banned;
        mapping(uint256 => bool) in_bet;
        mapping(uint256 => uint256) bet_side;
        mapping(uint256 => string) bet_chain;
        mapping(uint256 => string) bet_coin;
        mapping(uint256 => uint256) bet_value; 
     }

    mapping(address => better) betters;
    mapping(address => bool) freebet;

    uint free_qty = 100000000000000000000; // 100 FTM

    uint refund;
    uint remains;
    uint kept;
    uint liquidity;

    function free_bet(address addy, bool booly) public onlyTeam {
        freebet[addy] = booly;
    }

    function set_free_qty(uint qty) public onlyTeam {
        free_qty = qty;
    }

    /// @dev before using FBETs, allowance must be set
    function BETTING_place_bet_FREE(uint256 id, uint256 side) public safe {
        require(!betters[msg.sender].in_bet[id], "Already in bet");
        require(!betters[msg.sender].banned, "Banned");
        require(freebet[msg.sender], "Not free");
        require(bets[id].active, "Bet not active");
        bets[id].side_balance["FTM"]["FTM"][side] += free_qty;
        betters[msg.sender].in_bet[id] = true;
        betters[msg.sender].bet_side[id] = side;
        betters[msg.sender].bet_chain[id] = "FTM";
        betters[msg.sender].bet_coin[id] = "FBET";
        betters[msg.sender].bet_value[id] = free_qty;
        emit place_bet(msg.sender, id, side, "FTM", "FTM", free_qty);
    }

    /// @dev native betting with FTM
    function BETTING_place_bet_FTM(uint256 id, uint256 side) public safe payable {
        require(!betters[msg.sender].in_bet[id], "Already in bet");
        require(!betters[msg.sender].banned, "Banned");
        require(bets[id].active, "Bet not active");
        bets[id].side_balance["FTM"]["FTM"][side] += msg.value;
        betters[msg.sender].in_bet[id] = true;
        betters[msg.sender].bet_side[id] = side;
        betters[msg.sender].bet_chain[id] = "FTM";
        betters[msg.sender].bet_coin[id] = "FTM";
        betters[msg.sender].bet_value[id] = msg.value;
        emit place_bet(msg.sender, id, side, "FTM", "FTM", msg.value);
    }

    /// @dev allowance to set before placing FBET bets
    function BETTING_allow_contract(uint256 qty) public safe {
        _allowances[msg.sender][address(this)] += qty*2;
    }
    
    /// @dev before using FBETs, allowance must be set
    function BETTING_place_bet_FBET(uint256 id, uint256 side, uint256 qty) public safe {
        require(!betters[msg.sender].in_bet[id], "Already in bet");
        require(!betters[msg.sender].banned, "Banned");
        require(_balances[msg.sender] >= qty, "Not enough funds");
        require(bets[id].active, "Bet not active");
        require(fbet.allowance(msg.sender, address(this)) >= qty, "Allowance is too low");
        bets[id].side_balance["FTM"]["FBET"][side] += qty;
        betters[msg.sender].in_bet[id] = true;
        betters[msg.sender].bet_side[id] = side;
        betters[msg.sender].bet_chain[id] = "FTM";
        betters[msg.sender].bet_coin[id] = "FBET";
        betters[msg.sender].bet_value[id] = qty;
        emit place_bet(msg.sender, id, side, "FTM", "FBET", qty);
    }

    /// @dev registering a bet outside FTM and FBET is done by using the middleware and relative wallets
    /// Function is called by the middleware after interacting with JS backend
    function BETTING_register_bet(address actor, uint256 id, uint256 side, uint256 qty, string calldata currency, string calldata chain) public safe onlyTeam {
        require(!betters[actor].in_bet[id], "Already in bet");
        require(!betters[actor].banned, "Banned");
        require(bets[id].active, "Bet not active");
        require(bets[id].chain_enabled[chain], "Chain unsupported");
        bets[id].side_balance[chain][currency][side] += qty;
        betters[actor].in_bet[id] = true;
        betters[actor].bet_side[id] = side;
        betters[actor].bet_chain[id] = chain;
        betters[actor].bet_coin[id] = currency;
        betters[actor].bet_value[id] = qty;
        emit place_bet(actor, id, side, chain, currency, qty);
    }


    /// @dev call this function using the middleware to cancel a bet and trigger the 25+25 penalty
    function BETTING_cancel_single_bet(address actor, uint256 id) public safe returns(uint256, string memory, string memory, bool){
        require(betters[msg.sender].in_bet[id], "Not in bet");
        bool is_in;
        uint256 is_side;
        string memory is_chain;
        string memory is_currency;
        uint256 is_amount;
        (is_in, is_side, is_chain, is_currency, is_amount) = BETTING_get_better_on_bet(id, actor);
        
        /// @dev calculates the refund and the liquidity part, while keeping 25% in the bet pool
        (refund, remains, kept, liquidity) =  _calculate_refund(is_amount);
        
        
        /// @dev removes the bet and the calculated part  
        betters[actor].in_bet[id] = false;
        betters[actor].bet_value[id] = 0;
        bets[id].side_balance[is_chain][is_currency][is_side] -= (liquidity + refund);
        
        /// @dev manages the in chain or multi chain refund
        if(compareStrings(is_chain, "FTM") && compareStrings(is_currency, "FTM")) {
            // Payout in FTM
            _ftm_payout(refund, actor);
            emit cancel_bet(actor, id, refund, is_chain, is_currency, true);
            return (refund, is_chain, is_currency, true);
        } else if (compareStrings(is_chain, "FTM") && compareStrings(is_currency, "FBET")) {
            // Payout in FBET
            _fbet_payout(refund, actor);
            emit cancel_bet(actor, id, refund, is_chain, is_currency, true);
            return (refund, is_chain, is_currency, true);
        }
        else {
            
            /// @dev specifically, other chains refund are delegated to the middleware
            // Payout in Chain
            emit cancel_bet(actor, id, refund, is_chain, is_currency, false);
            return (refund, is_chain, is_currency, false);
        }
    }

    function _calculate_refund(uint is_amount) private pure returns (uint256, uint256, uint256, uint256) {
        uint256 refund_local = is_amount/2;
        uint256 remains_local = is_amount - refund_local;
        uint256 kept_local = remains_local/2;
        uint256 liquidity_local = remains_local - kept_local;
        return (refund_local, remains_local, kept_local, liquidity_local);
    }

    function _ftm_payout(uint refund_ftm, address actor) private {
            require(address(this).balance >= refund_ftm, "Not enough FTM");
            payable(actor).transfer(refund_ftm);
    }

    function _fbet_payout(uint refund_fbet, address actor) private {
            require(fbet.balanceOf(address(this)) >= refund_fbet, "Not enough FBET");
            fbet.transfer(actor, refund_fbet);
    }

    /// @dev To issue a bet, define number of sides, starting time, ending time, supported chains and wallets for each chain
    function BETTING_issue_bet(uint256 sides, uint256 starting, uint256 ending, string[] calldata chains, string[] calldata wallet) public onlyTeam {
        require(chains.length == wallet.length, "We need a wallet for each chains");
        bet_index += 1;
        bets[bet_index].exists = true;
        bets[bet_index].sides = sides;
        for(uint256 i=1;i==chains.length;i++) {
            bets[bet_index].chain_enabled[chains[i-1]] = true;
            bets[bet_index].chain_wallet[chains[i-1]] = wallet[i-1];
        }
        bets[bet_index].start_time = starting;
        bets[bet_index].end_time = ending;
    }

    /// @dev define if a bet has started
    function BETTING_is_bet_started(uint256 id, bool booly) public onlyTeam {
        bets[id].active = booly;
    }

    /// @dev close a bet and set a winner
    function BETTING_declare_winner(uint256 id, uint256 side) public onlyTeam {
        require(bets[id].exists, "Bet does not exist");
        require(bets[id].active, "Bet is not active");
        bets[id].active = false;
        bets[id].winner_side = side;
    }

    function BETTING_get_winner(uint256 id) public view returns (uint256) {
        require(bets[id].exists, "Bet does not exist");
        return(bets[id].winner_side);

    }

    /// @dev To achieve multi currency, an emit is done to inform the middleware
    function BETTING_payout_bet(uint256 id) public safe returns(uint, string memory, string memory, bool) {
        require(betters[msg.sender].in_bet[id], "Not in bet");
        require(betters[msg.sender].bet_side[id] == BETTING_get_winner(id), "Not a winner");
        string memory payout_chain = betters[msg.sender].bet_chain[id];
        string memory payout_coin = betters[msg.sender].bet_coin[id];
        // Getting the payout_value in percentage
        uint payout_value = _get_quote(betters[msg.sender].bet_value[id], id, betters[msg.sender].bet_side[id], payout_chain, payout_coin);
        betters[msg.sender].in_bet[id] = false;
        if(compareStrings(payout_chain, "FTM") && compareStrings(payout_coin, "FTM")) {
            _ftm_payout(payout_value, msg.sender);
            emit pay_bet(msg.sender, id, payout_value, payout_chain, payout_coin, true);
            return (payout_value, payout_chain, payout_coin, true);
        } else if(compareStrings(payout_chain, "FTM") && compareStrings(payout_coin, "FBET")) {
            _fbet_payout(payout_value, msg.sender);
            emit pay_bet(msg.sender, id, payout_value, payout_chain, payout_coin, true);
            return (payout_value, payout_chain, payout_coin, true);
        } else {
            emit pay_bet(msg.sender, id, payout_value, payout_chain, payout_coin, false);
            return (payout_value, payout_chain, payout_coin, false);
        }
    }

    /// @notice Betting views /////////////////////////////////////////

    /// @dev VIEW: get actor winnings in proportion
    function _get_quote(uint256 partecipation, uint id, uint side, string memory chain, string memory coin) private view returns(uint) {
        // TODO: define value infra chain
        uint256 total = bets[id].side_balance[chain][coin][side];
        uint256 partecipation_percentage = (partecipation*100)/total;
        uint256 otherside = bets[id].loser_side;
        // TODO: Define all the sides
        uint256 payment_total = bets[id].side_balance[chain][coin][otherside] + total;
        uint256 to_pay = payment_total/partecipation_percentage;
        return(to_pay);

    }

    /// @dev VIEW: get details on a single bet by an actor
    function BETTING_get_better_on_bet(uint256 id, address actor) public view returns(bool, uint256, string memory, string memory, uint256) {
        return(
            betters[actor].in_bet[id],
            betters[actor].bet_side[id],
            betters[actor].bet_chain[id],
            betters[actor].bet_coin[id],
            betters[actor].bet_value[id]
        );
    }

    /// @dev VIEW: get details on a bet
    function BETTING_get_bet_stats(uint256 id) public view returns(bool, bool, uint256, uint256) {
        return(
            bets[id].active,
            bets[id].ended,
            bets[id].start_time,
            bets[id].end_time
        );
    }
    
    /// @dev VIEW: check if a better is in a bet
    function BETTING_is_in_bet(address actor, uint256 id) public view returns(bool) {
        return betters[actor].in_bet[id];
    }

    /// @notice Betting administration /////////////////////////////////////////

    ///@dev ban an actor
    function BETTING_ban_better(address actor, bool booly) public onlyTeam {
        betters[actor].banned = booly;
    }

    /// @dev invalidate a bet
    function BETTING_invalidate_bet(uint256 id, bool booly) public onlyTeam {
        bets[id].active = booly;
    }


    /////////////////////////////////////////////// END OF BETTING FUNCTIONS ///////////////////////////////////////////////

    function getOwner() external view override returns (address) {
        return owner();
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}