/**
 *Submitted for verification at FtmScan.com on 2023-06-20
*/

//SPDX-License-Identifier: UNDEFINED

pragma solidity 0.8.17;

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);


}

//IDEXFactory interface to create token pool pair address
interface IDEXFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
}



//IDEXRouter interface to integrate Tarder Joe(liquidity pool) router
interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
        uint amountAVAXMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForTokens(
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

     function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);
}

interface IDEXPair{
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function sync() external;
}

    //////// intefaces of stable usd token mint function  \\\\\\\\
interface Istable is IERC20 {
    function mint(
        uint amount
        ) external  returns(bool);
}


interface IPrinter {
    function setShare(address shareholder, uint256 amount) external;
    function deposit(uint _cp, uint denominator) external payable  returns(uint);
    function shareHolderBal(address _tokenAdd, address shareHolder) external view returns(uint);
    function claimPrintReflaction(address _tokenAdd, address _sender) external;
    function withdrawToken(address _tokenAdd, address receiver) external;
}

contract Printer is IPrinter {

    ///////// using libraries \\\\\\\\\
    using SafeMath for uint256;

    address  _callerToken;  // authority contract which can regulate this 
    address public printTokenAddress; // printing token address
    address public  nativeCoin; // native Wrraped coin address 
    address  routerAddress; //dex router address
    
         //////////////// contract instances \\\\\\\\\\\\\\\\\\
    IERC20 printToken;     
    Istable liquidityAddingToken;
    IDEXRouter router;
      
    mapping (address => mapping(address => uint256)) shareholderClaims;  // USd reward claiming mapping
    mapping (address => uint) public totalRewardReflaction;
    mapping (address => uint) public totalRewardDistributed;
    mapping (address => uint) public totalPayableReward;




    modifier onlyToken() {
        require(msg.sender == _callerToken); _;
    }

    constructor (address _routerAdd, address _printToken, address _nativeCoin) {
        require(_routerAdd  != address(0), "invalid router address");
        require(_printToken != address(0), "invalid pegToken Address");
        require(_nativeCoin != address(0), "invalid nativeCoin address");
        routerAddress = _routerAdd;
        router = IDEXRouter(_routerAdd);
        printTokenAddress = _printToken;
        printToken = IERC20(_printToken);
        nativeCoin = _nativeCoin;
        _callerToken = msg.sender;
    }

    receive() external payable { }

   function surplasBal(address _printToken) public view returns(uint){
       return (totalRewardReflaction[_printToken].sub(totalRewardDistributed[_printToken])).sub(totalPayableReward[_printToken]);
   }

    
     
    function setPrintToken(address _printToken)
        external
        onlyToken
    {   
        require(_printToken != address(0), "invalid  printer addiing address");
        printTokenAddress = _printToken;
        printToken = IERC20( _printToken);
    }

    event HolderRewardAdded(address _shareHolder, uint _amount);

    function setShare(address shareholder, uint256 amount) external override onlyToken {
      shareholderClaims[printTokenAddress][shareholder] = shareholderClaims[printTokenAddress][shareholder].add(amount);
      totalPayableReward[printTokenAddress] = totalPayableReward[printTokenAddress].add(amount);
      emit  HolderRewardAdded(shareholder, amount);
    }

    function shareHolderBal(address _tokenAdd, address shareHolder) external view override returns(uint){
    return shareholderClaims[_tokenAdd][shareHolder];
    }

    event swapPrintedToken(uint _printAmount);

    function deposit(uint _cp, uint denominator) external payable  onlyToken returns(uint){
        uint tokenAmount;
        uint256 balanceBefore = printToken.balanceOf(address(this));   

        address[] memory path = new address[](2);
        path[0] = nativeCoin;
        path[1] = printTokenAddress;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = (printToken.balanceOf(address(this))) - balanceBefore;
        if(_cp > 0){
            tokenAmount = (amount.mul(_cp)).div(denominator);
            if(tokenAmount > 0){
            IERC20(printTokenAddress).transfer(_callerToken, tokenAmount);
            }
        }
       
    
        emit swapPrintedToken(amount);
        
        totalRewardReflaction[printTokenAddress] = totalRewardReflaction[printTokenAddress].add(amount.sub(tokenAmount));
        return tokenAmount;
    }
    
    function avaxSwap(address _tokenAdd, uint tokenAmount) external  onlyToken returns(uint){
        IERC20(_tokenAdd).approve(routerAddress, tokenAmount);
        uint256 initialSwapBal = (_callerToken).balance;
        
        address[] memory path = new address[](2);
        path[0] = _tokenAdd;
        path[1] = nativeCoin;
       

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _callerToken,
            block.timestamp
        );
        uint256 swapAmount = (_callerToken.balance).sub(initialSwapBal);
        return swapAmount;
    }

    

    function withdrawToken(address _tokenAdd, address receiver) external onlyToken{
        require(receiver != address(0));
        uint amount = surplasBal(_tokenAdd);
         totalRewardDistributed[_tokenAdd] = totalRewardDistributed[_tokenAdd].add(amount);
        totalPayableReward[_tokenAdd] = totalPayableReward[_tokenAdd].sub(amount);
        IERC20(_tokenAdd).transfer(receiver, amount);
    }

   event TransferPrint(address from, address to, uint amount);

    function claimPrintReflaction(address _tokenAdd, address _receiver) external onlyToken{
       if(shareholderClaims[_tokenAdd][_receiver] >0){
        uint amount = shareholderClaims[_tokenAdd][_receiver];
        shareholderClaims[_tokenAdd][_receiver] = 0;
        totalRewardDistributed[_tokenAdd] = totalRewardDistributed[_tokenAdd].add(amount);
        totalPayableReward[_tokenAdd] = totalPayableReward[_tokenAdd].sub(amount);
        IERC20(_tokenAdd).transfer(_receiver, amount) ;
        emit TransferPrint(address(this),_receiver, amount);
       }
    }

}




contract TROFAST is IERC20 {

    ///////////////////// math library \\\\\\\\\\\\\\\\\\\\\\\
    using SafeMath for uint;

    address public Owner;

    ///////////////////// ERC20 token's meta data \\\\\\\\\\\\\\\\\\\\\\\
    string constant  _name = "TROFAST";
    string constant  _symbol = "TFST";
    uint8 constant _decimals = 18;
    uint constant  public  totalSupply = 100000000000*(10**_decimals); // 100 bilion hardcoded;
   
    

    //////////////// events \\\\\\\\\\\\\\\\\\\\

        ///////////////////////////////////////trading mode \\\\\\\\\\\\\\\\\\\\\\\\\\\\
    bool public printingMode = true;
    bool public nativeReflaction = true;
    bool public antibotMode = false;
    bool public transferTax = true;
    bool public ALPMood = true;
    uint public mode = 2;

        ////////////////////////////////// additional token info \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    address  nativeCoin;
    address  printToken;
    address  selfliquidityTokenAdd;

    //token unique variables(fee calculating variables)
    uint constant _taxCalcDenominator = 1000; // fee calculation denominator by 1000
    //taxes 
    uint printingFee = 10;
    uint reflactionFee = 10;
    uint marketingFee = 10;
    uint ALPF = 10;


    uint constant maxTotalFee = 100;  // tax cant exceed over 10% (except antibot mode)

   

    //additional Fee
    uint contractReflactionPortion = 900;
    uint contractPrintingPortion = 500;
    uint gurdianLpRewardFee = 10; //1% of token liquidity;
    uint largeSellFee = 20; // 2% of tx amount(applicable when selling 0.5% of supply token)
    uint mediumSellFee = 10; // 2% of tx amount(applicable when selling 0.2% of supply token )
    uint HFTFee = 20; //High frequency trade fee (if anyone trade within short time period below 24 hours)
    uint quickSellFee = 10; //(1%) applicable if anybody sell within a week
    uint antibotFee = 500; // applicable if wanna buy and sell although you are not a whitlisted in private mode(not for pubic mode)
    // storing on buy swaping tax amount to swap later on sell
    uint public  reserveMarketingCollection; 
    uint public   reserveALPCollection;
    uint public  reservePrintingCollection;
    
    //thresholds
    uint  LPDriverThreshold = (totalSupply.mul(10)).div(_taxCalcDenominator);  // 1% of totalSupply
    uint  MaxWalletAmount = (totalSupply.mul(10)).div(_taxCalcDenominator); // only 1% token you can keep in your wallet(not pplicable for maxExempt holder)
    uint  MaxTxAmount = (MaxWalletAmount.mul(500)).div(_taxCalcDenominator);
    uint  largeSellAmountThreshold = (totalSupply.mul(5)).div(_taxCalcDenominator); // 0.5% of totalSupply
    uint  mediumSellAmountThreshold = (totalSupply.mul(2)).div(_taxCalcDenominator); // 0.05% of totalsupply
    uint  HFTTimingThreshold = 1*60*60; // 1 hour
    uint  quickSellTimingThreshold = 7*24*60*60; // in a week;

   
    
     
    
     //struct for contract internal functions
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalNativeRewards;
    }

    mapping(address => mapping(address  => uint)) public totalPrintRewards;

    struct vestingInfo {
        bool isvesting;
        uint periodThresHold;
        uint amountThresHold;
    }

    
    struct balanceInfo {
       uint256 balance;
       uint256 updatedAt;
       uint256 lastSellAt;
    }



    mapping(address => balanceInfo)  _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    // token internal mapping
    mapping(address => bool) public isWhitelisted;
    mapping(address => vestingInfo) public isAddedVesting;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isGurdian;
    mapping(address => bool) public isManager;
    mapping(address => bool)  isExcludeReWard;
    mapping(address => bool) public isMaxExempt;
    //reflaction related mapping
    mapping(address => uint256)  holderByIndex;
    mapping(address => uint256)  shareHolderClaims;
    mapping(address => Share) public Shares;
    address[] public tokenHolders;
    
    
    



    //tax fee receiver
    address  marketingFeeReceiver;



    Printer printer;
    address public printerAddress;
    
    //dex variables
    address  routerAddress;
    IDEXRouter  router;
    IDEXPair lTank;
    address public tAddress;
    bool  swapEnabled = true;

    bool inSwap;
    modifier swaping() { inSwap = true; _; inSwap = false; }

    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can call the function");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == Owner || isManager[msg.sender] == true, "caller isnt gurdian nor Owner");
        _;
    }

    modifier onlyValidSender(address sender, address receipient, uint amount){
        if(isAddedVesting[sender].isvesting == true && receipient == tAddress){
            if(_balances[sender].lastSellAt != 0){
               require((block.timestamp).sub(_balances[sender].lastSellAt) >= isAddedVesting[sender].periodThresHold , "sender is added to vesting mode , cant transfer before the period is completed");
            }
               require(amount <= (amount.mul(isAddedVesting[sender].amountThresHold)).div(_taxCalcDenominator), "sender is added to vesting mode , cant sell more than 10% of balance amount");
        }

       if(mode == 0 && !antibotMode || mode == 1 && !antibotMode){
            require(isWhitelisted[receipient] == true, "not whitelisted receiver");
            require(isWhitelisted[sender] == true, "not whitelisted sender");
        }
        
        _;
    }

    modifier printPaymentFirst() {
        if (msg.sender != address(this) && printToken != nativeCoin) {
            uint amount = printer.shareHolderBal(printToken, msg.sender);
            if ( amount > 0) {
                totalPrintRewards[msg.sender][printToken] = 0;
                try printer.claimPrintReflaction(printToken, msg.sender) {} catch {}
                
            }
        }else{
            IERC20(nativeCoin).transfer(msg.sender, totalPrintRewards[msg.sender][printToken]);
             totalPrintRewards[msg.sender][printToken] = 0;
        }
        _;
    }

    modifier lpdriver(bool permission){
        if(_balances[address(this)].balance >= LPDriverThreshold && permission == true){
            _lpDriver();
        }
        _;
    }

 

 
constructor(address _routerAddress, address _mfr, address _ptA) {
        Owner = msg.sender;
        marketingFeeReceiver = _mfr;
        printToken = _ptA;
        routerAddress = _routerAddress;
        router = IDEXRouter(routerAddress);
        nativeCoin = router.WETH();
        tAddress = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        lTank = IDEXPair(tAddress);
        printer = new Printer(routerAddress, _ptA, router.WETH());
        printerAddress = address(printer);
        tokenHolders.push(msg.sender);
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)]= true;
        isFeeExempt[printerAddress] = true;
        isMaxExempt[printerAddress] = true;
        isMaxExempt[tAddress] = true;
        isMaxExempt[msg.sender] = true;
        isMaxExempt[address(this)] = true;
        isWhitelisted[tAddress] = true;
        isWhitelisted[address(this)] = true;
        isWhitelisted[printerAddress] = true;
        _allowances[address(this)][address(router)] = totalSupply;
        approve(routerAddress, totalSupply);
        _balances[msg.sender].balance = totalSupply; 
    }

    receive() external payable { }

    ////////////// standard function of IERC20Metadata and IER20 interface \\\\\\\\\\\\\\\\\\\\
    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }


    function balanceOf(
        address account
    ) public view override  returns (uint256) {
        return _balances[account].balance;
    }
    


    function approve(
        address spender,
        uint256 amount
    ) public override printPaymentFirst lpdriver(true) returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function transfer(
        address to,
        uint256 amount
    ) external override onlyValidSender(msg.sender, to, amount)   returns (bool) {

        return _transfer(msg.sender, to, amount);
    }
    
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override onlyValidSender(from, to, amount) returns (bool) {
        return _transfer(from, to, amount);
    }



    function _basicTransfer(address sender, address to, uint amount) internal returns(bool){
        if(_balances[to].balance == 0 && to != tAddress && to != address(this)) {       
              holderByIndex[to] = tokenHolders.length;
              tokenHolders.push(to); 
        }
        _balances[to].balance = (_balances[to].balance).add(amount);
        require(isMaxExempt[to] ? true : _balances[to].balance <= MaxWalletAmount, "Max wallet amount exceed");
        _balances[to].updatedAt = block.timestamp;
        _balances[sender].updatedAt = block.timestamp; 
        if(to == tAddress){
             _balances[sender].lastSellAt = block.timestamp;
        }
        emit Transfer(sender, to, amount);
        return true;
    }

    
   

    function _transfer(
        address from,
        address to,
        uint256 amount
     ) internal printPaymentFirst lpdriver(from != tAddress) returns (bool) {
        require(from != address(0), "invalid sender");
        require(to != address(0), "invalid receiver");
        require(isMaxExempt[from] ? true : amount <= MaxTxAmount, "Max Tx Amount Exceed");
        require(_balances[from].balance >= amount, "insufficient amount");
        uint feeAmount;
        bool W2W = from != tAddress && to != tAddress;
        if(_allowances[from][msg.sender] > 0 && from != address(this)){
            _allowances[from][msg.sender] = (_allowances[from][msg.sender]).sub(amount);
        }
   
        _balances[from].balance = (_balances[from].balance).sub(amount);
        bool isTransferTax = W2W  && transferTax == true && isFeeExempt[from] == false ;
        bool isTakeFee =  W2W == false && isFeeExempt[from] == false;
        if(isTakeFee || isTransferTax){
            feeAmount = takeFee(from, to , amount);
             if(from != tAddress && from != address(this) && feeAmount > 0 && _balances[address(this)].balance < LPDriverThreshold){
             uint totalSwapAmount = reserveMarketingCollection + reserveALPCollection.div(2) + reservePrintingCollection;
             if(shouldSwapBack(totalSwapAmount)){
                swapBack(true);
            }
        }
        }

       _basicTransfer(from, to, amount.sub(feeAmount));
       
        return true;
    }


    function takeFee(address sender, address receipient, uint _amount) private returns(uint){
      
        uint feeAmount;
        uint nativeReflactionAmount;
        uint contractAmount;
        uint printingAmount;
        uint marketingAmount;
        uint antibotTaxAmount;
        uint alpfeeAmount;
        uint totalTax = printingFee + marketingFee + ALPF + reflactionFee;
        address from = sender;
        uint amount = _amount;
        
        if(mode == 1 || mode == 2){

            feeAmount = (amount.mul(totalTax)).div(_taxCalcDenominator);
            nativeReflactionAmount = nativeReflaction ? (amount.mul(reflactionFee)).div(_taxCalcDenominator) : 0;
            printingAmount = printingMode ? (amount.mul(printingFee)).div(_taxCalcDenominator) : 0;
            alpfeeAmount = ALPMood ? (amount.mul(ALPF)).div(_taxCalcDenominator) : 0;
            marketingAmount =  feeAmount.sub(nativeReflactionAmount + printingAmount + alpfeeAmount);
            reserveMarketingCollection += marketingAmount;
            reservePrintingCollection += printingAmount;
            reserveALPCollection += alpfeeAmount;
            contractAmount = marketingAmount + alpfeeAmount + printingAmount;
            
        }
        
        if(receipient == tAddress && from != address(this) && mode != 0){
          
            uint largeAmountTax = amount >= largeSellAmountThreshold ? (amount.mul(largeSellFee)).div(_taxCalcDenominator) : 0;
            uint mediumAmountTax = amount >= mediumSellAmountThreshold ? (amount.mul(mediumSellFee)).div(_taxCalcDenominator) : 0;
            uint HFTaxAmount = (block.timestamp).sub(_balances[from].updatedAt) <= HFTTimingThreshold ? (amount.mul(HFTFee)).div(_taxCalcDenominator) :
           (block.timestamp).sub(_balances[from].updatedAt) <= quickSellTimingThreshold ? (amount.mul(quickSellFee)).div(_taxCalcDenominator) : 0;
            
            {
            feeAmount += (largeAmountTax + mediumAmountTax + HFTaxAmount);
            marketingAmount = marketingAmount + largeAmountTax + mediumAmountTax + HFTaxAmount;
            reserveMarketingCollection = reserveMarketingCollection.add(largeAmountTax + mediumAmountTax + HFTaxAmount);
            contractAmount = contractAmount.add(largeAmountTax + mediumAmountTax + HFTaxAmount);
            }
        }



        if(antibotMode == true && mode != 2){
            require(from == tAddress || receipient == tAddress);
                if(isWhitelisted[from] == false || isWhitelisted[receipient] == false){
                    antibotTaxAmount = (amount.mul(antibotFee)).div(_taxCalcDenominator);
                    if(antibotTaxAmount > feeAmount){
                        uint antibotMarketingAmount = antibotTaxAmount.sub(feeAmount);
                        feeAmount = feeAmount.add(antibotMarketingAmount);
                        reserveMarketingCollection = reserveMarketingCollection.add(antibotMarketingAmount);
                        contractAmount = contractAmount.add(antibotMarketingAmount);
                    }
                }
        }


        if(nativeReflaction == true && nativeReflactionAmount > 0){
            _dToken(nativeReflactionAmount, 1);
        }

        if(contractAmount > 0){
        _basicTransfer(from, address(this), contractAmount);
        }

        return feeAmount;
    }



    //reward distribute events
    event DistributeRewards(uint totalRewardAmount);

    function _dToken(uint _totalAmount, uint num) internal {
        //1 for native token  2 for print token
       uint totalHoldedTokens = totalSupply.sub(_balances[tAddress].balance);
       uint _td;
       uint _cr;
       uint _da;
       if(num == 1){
          _cr = (_totalAmount.mul(contractReflactionPortion)).div(_taxCalcDenominator);
          _da = _totalAmount.sub(_cr);
       }else{
         _da = _totalAmount;
       }
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint256 rewardAmount ;
          if(isExcludeReWard[tokenHolders[i]] == false){
              uint holderPercantage = ((_balances[tokenHolders[i]].balance).mul(1000)).div(totalHoldedTokens);
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            rewardAmount = ((_balances[tokenHolders[i]].balance).mul(_da)).div(totalHoldedTokens);
            if (num == 1) {
                Shares[tokenHolders[i]].totalNativeRewards = Shares[
                    tokenHolders[i]
                ].totalNativeRewards.add(rewardAmount);
                _balances[tokenHolders[i]].balance = (_balances[tokenHolders[i]].balance).add(rewardAmount);
                _td = _td.add(rewardAmount);
            }
            if (num == 2) {
                totalPrintRewards[tokenHolders[i]][printToken] = totalPrintRewards[tokenHolders[i]][printToken].add(rewardAmount);
               if(printToken != nativeCoin) { try printer.setShare(tokenHolders[i], rewardAmount) {} catch {}}
                _td = _td.add(rewardAmount);
            }}}
        uint contractAmount = _cr.add(_da.sub(_td));
           if(num == 1){
               Shares[address(this)].totalNativeRewards = Shares[
                    address(this)
                ].totalNativeRewards.add(contractAmount);
               _balances[address(this)].balance  = (_balances[address(this)].balance).add(contractAmount);
            }
        
        emit DistributeRewards(_totalAmount);
    }


    
   

    event DistributeSwapBack(uint Reflaction_Print, uint WAVAX_liquidity, uint WAVAX_marketing);

    function swapBack(bool debug) public swaping {
        uint liquidity;
        bool selpLpDriver = _balances[address(this)].balance >= LPDriverThreshold;
        uint totalAmountToSwap = reserveMarketingCollection + reserveALPCollection.div(2) + reservePrintingCollection;
        if(totalAmountToSwap > 0){
           require(_balances[address(this)].balance >= totalAmountToSwap, "insufficient contract balance to swap");      
              uint256 printingAmount;
              uint256 liquidityAmount;
              uint256 marketingAmount;
             

        uint256 initialSwapBal = (address(this)).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = nativeCoin;
       

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            totalAmountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 swapAmount = ((address(this)).balance).sub(initialSwapBal);


        if(reserveMarketingCollection > 0){
           marketingAmount = (swapAmount.mul(reserveMarketingCollection)).div(totalAmountToSwap);
            payable(marketingFeeReceiver).transfer(marketingAmount);
            reserveMarketingCollection = 0;
        }
        
        if(printingMode == true && reservePrintingCollection > 0){
             printingAmount = (swapAmount.mul(reservePrintingCollection)).div(totalAmountToSwap);
             if(printToken != nativeCoin){
                  uint printAmount = printer.deposit{value: printingAmount}(contractPrintingPortion, _taxCalcDenominator);
                  totalPrintRewards[address(this)][printToken] = totalPrintRewards[address(this)][printToken].add(printAmount);
                  if(debug == true){
                       uint surplasPrintBal = printer.surplasBal(printToken);
                       _dToken(surplasPrintBal, 2);
                  }
                  
             }else{
                 _dToken(printingAmount, 2);
             }
            reservePrintingCollection = 0;
        } 
        

        

        if(ALPMood == true || selpLpDriver){
            liquidityAmount = swapAmount.sub(printingAmount + marketingAmount);
            uint liquidityToken = reserveALPCollection.sub(reserveALPCollection.div(2));
          (, ,  liquidity)  = router.addLiquidityETH{value : liquidityAmount}(
                address(this),
                liquidityToken,
                0,
                0,
                Owner,
                block.timestamp
            );
            reserveALPCollection = 0;
        }
       
        emit DistributeSwapBack( printingAmount, liquidity, marketingAmount);  
        }
    }

    function _lpDriver() private {
            uint gurdianReward;
            uint256 lpDriverAmount;
            uint256 lpDriverAvax;
            lpDriverAmount = LPDriverThreshold.div(2);
            lpDriverAvax = LPDriverThreshold.sub(lpDriverAmount);
            _balances[printerAddress].balance = (_balances[printerAddress].balance).add(lpDriverAvax);
            _balances[address(this)].balance = (_balances[address(this)].balance).sub(lpDriverAvax);
            uint liquidityAvaxAmount =  printer.avaxSwap(address(this), lpDriverAvax);
            (, , uint nativeLiquidity) = router.addLiquidityETH{value:liquidityAvaxAmount}(
                address(this),
                lpDriverAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
          if(isGurdian[msg.sender] == true){
              gurdianReward = (nativeLiquidity.mul(gurdianLpRewardFee)).div(_taxCalcDenominator);
              IERC20(selfliquidityTokenAdd).transfer(msg.sender, gurdianReward);
          }
          
        
    }

    function selfLpDriver() external {
        require(isGurdian[msg.sender] == true|| isManager[msg.sender] == true || msg.sender == Owner);
        require(_balances[address(this)].balance >= LPDriverThreshold);
        _lpDriver();
    }

    
                                             ///////// state Update functions \\\\\\\\\\\
   //-----------------------------------------------------------------------------------------------------------------------------------
   
     
    function shouldSwapBack(uint256 _amount) internal view returns (bool) {
        return msg.sender != tAddress
        && !inSwap
        && swapEnabled
        && _balances[address(this)].balance >= _amount;
    }

    function updateFeeExempt(address[] calldata addressArray, bool exempt ) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             require(addressArray[i] != address(0), "invalid address");
             isFeeExempt[addressArray[i]] = exempt;
        }
        
    }

 

    function updateWhitelisted(address[] calldata  _holders, bool position) external onlyManager {
        for(uint i =0 ; i < _holders.length; i++){
            require(_holders[i] != address(0), "invalid Address");
            isWhitelisted[_holders[i]] = position;
        }

    }

    function updateVesting(address[] calldata addressArray, bool _switch, uint[] calldata periodArray, uint[] calldata amountArray ) external onlyManager{
            require(addressArray.length == periodArray.length, "invalid Vesting periods");
            require(addressArray.length == amountArray.length, "invalid Vesting amounts");
            
                for(uint i = 0; i < addressArray.length ; i++){
                    if(addressArray[i] != address(0)){
                    if(_switch == true){
                        isAddedVesting[addressArray[i]].isvesting = true;
                        isAddedVesting[addressArray[i]].periodThresHold = periodArray[i];
                        isAddedVesting[addressArray[i]].amountThresHold = amountArray[i].mul(10);
                    }else{
                        isAddedVesting[addressArray[i]].isvesting =false;
                    }
            }}
    }

    function updateManager(address _add, bool position) external onlyOwner{
        require(_add != address(0));
        isManager[_add]  = position;
    }

  
   function updateGurdian(address _add, bool on) external {
       isGurdian[_add] = on;
   }



    function updateMaxExempt(address[] calldata addressArray, bool option) external onlyManager{
        for(uint i = 0 ; i < addressArray.length ; i++){
             if(addressArray[i] != address(0)){
           isMaxExempt[addressArray[i]] = option;
        }}
    }

    function updateRewardExempt(address[] calldata addressArray, bool option) external onlyManager{
         for(uint i = 0 ; i < addressArray.length ; i++){
            if(addressArray[i] != address(0)){
           isExcludeReWard[addressArray[i]] = option;
            }
        } 
    }


 

    function claimReward(address _tokenAdd, address receiver) external {
        if(_tokenAdd == nativeCoin){
            require(receiver != address(this));
            require(totalPrintRewards[receiver][nativeCoin] > 0 , "insufficient balance");
            IERC20(nativeCoin).transfer(receiver, totalPrintRewards[msg.sender][nativeCoin]);
        }else{
           require(printer.shareHolderBal(_tokenAdd, receiver) > 0 , "insufficient balance");
             try printer.claimPrintReflaction(_tokenAdd, receiver) {} catch {}
        }
             
    }

   

    function updatePeriodThreshold(
        uint _hftPeriod,
        uint _quickSellPeriod
    ) external onlyManager{
        
        HFTTimingThreshold = _hftPeriod;
        quickSellTimingThreshold = _quickSellPeriod;
    }

    function updateMax(
        uint _maxTx,
        uint _maxWallet,
        uint _largeSell, 
        uint _mediumSell
    ) external onlyManager{
        if(_largeSell > 0 && _mediumSell > 0){
            largeSellAmountThreshold = _largeSell.mul(10**_decimals);
            mediumSellAmountThreshold = _mediumSell.mul(10**_decimals);
        }else{
            MaxWalletAmount = _maxWallet.mul(10**_decimals);
            MaxTxAmount = _maxTx.mul(10**_decimals);
            require(MaxWalletAmount > MaxTxAmount, "Max tx exceed maxWallet");
        }
    }


    function switchAntibot(uint _antibotFee)external onlyManager{
        require(mode == 0 || mode == 1);
        antibotMode = true;
        antibotFee = _antibotFee;
    }

    function switchMode(
        bool _prinitingSwitch,
        bool _nativeReflactionSwitch,
        bool _autoLiquiditySwitch,
        bool _transferSwitch,
        uint _mode,
        bool _payit
        )external onlyManager{
            
        if(_payit == true && reservePrintingCollection > 0 && !inSwap &&  _balances[address(this)].balance >= (reservePrintingCollection + reserveMarketingCollection + reserveALPCollection)){
            swapBack(true);
           }
 
            printingMode = _prinitingSwitch;
            nativeReflaction = _nativeReflactionSwitch;
            ALPMood = _autoLiquiditySwitch;
            antibotMode = false;
            transferTax = _transferSwitch;
            mode = _mode;
        }


    function updateTax(
        uint mFee,
        uint pFee,
        uint rFee,
        uint _alpf
    ) external onlyManager  {
        uint totalTax = mFee +  pFee + rFee + _alpf;
        require((totalTax.mul(10)).add(HFTFee.add(largeSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)).add(HFTFee.add(mediumSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)).add(quickSellFee.add(mediumSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)).add(quickSellFee.add(largeSellFee)) <= maxTotalFee);
        require((totalTax.mul(10)) <= maxTotalFee, "total tax exceed the max total tax");
        marketingFee = mFee.mul(10);
        printingFee = pFee.mul(10);
        reflactionFee = rFee.mul(10);
        ALPF = _alpf.mul(10);
       
    }

    



    function sell(uint amount) external returns(uint){
        uint avaxAmount;
        uint feeAmount;
        if(isFeeExempt[msg.sender] == false){
           feeAmount = takeFee(msg.sender, tAddress, amount);
        }
        uint amountToSell = amount.sub(feeAmount);
        _balances[msg.sender].balance = (_balances[msg.sender].balance).sub(amount);
        _basicTransfer(msg.sender, address(this), amount.sub(feeAmount));
        uint256 initialSwapBal = (msg.sender).balance;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = nativeCoin;
       

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSell,
            0,
            path,
            msg.sender,
            block.timestamp
        );
        avaxAmount = ((msg.sender).balance).sub(initialSwapBal);
        return avaxAmount;
    }

    function updateAdditionalTax(
        uint _hftTax,
        uint _quickSellTax,
        uint _mediumSellTax,
        uint _largerSellTax
    ) external onlyManager {
        uint totalTax = marketingFee + printingFee + ALPF + reflactionFee;
       require(totalTax.add(_hftTax.add(_largerSellTax)) <= maxTotalFee);
       require(totalTax.add(_hftTax.add(_mediumSellTax)) <= maxTotalFee);
       require(totalTax.add(_quickSellTax.add(_mediumSellTax)) <= maxTotalFee);
       require(totalTax.add(_quickSellTax.add(_largerSellTax)) <= maxTotalFee);

       largeSellFee = _largerSellTax.mul(10);
       HFTFee = _hftTax.mul(10);
       mediumSellFee = _mediumSellTax.mul(10);
       quickSellFee = _quickSellTax.mul(10);
    }

  

    function setRouter(address _routerAdd, address _pairToken) external onlyManager {
        routerAddress = _routerAdd;
        router = IDEXRouter(_routerAdd);
        nativeCoin = router.WETH();
        tAddress = IDEXFactory(router.factory()).getPair(_pairToken, address(this));
        if(tAddress == address(0)){
            tAddress = IDEXFactory(router.factory()).createPair(nativeCoin, address(this));
        }
        isFeeExempt[routerAddress] = true;
    }


    function updateFeeReceiver(address _marketFeeReceiver) external onlyManager{
        require(_marketFeeReceiver != address(0));
        marketingFeeReceiver = _marketFeeReceiver;
    }

    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }


    

    function Sweep(address _tokenAdd, address _receiver, uint amount, bool _printer) external onlyManager {
        require(_receiver != address(0));
        if(_tokenAdd == address(0)){
         uint256 balance = address(this).balance;
         require(balance >= amount, "insufficient balance");
         payable(_receiver).transfer(amount);
        }else{
            if(_printer == true){
              try printer.withdrawToken(_tokenAdd, _receiver) {} catch {}
            }else{
                uint tokenBalance = IERC20(_tokenAdd).balanceOf(address(this)); 
                require(tokenBalance >= amount, "insufficient balance");
                IERC20(_tokenAdd).transfer(_receiver, amount);
            }
        }
    }

    function updateCP(uint rP, uint pp) external onlyManager{
         contractPrintingPortion = pp.mul(10);
         contractReflactionPortion = rP.mul(10); 
    }

    function upgradeTokenAddress( address _printToken) external onlyManager{
        require(_printToken != address(0));
          try printer.setPrintToken(_printToken) {} catch {}
          printToken = _printToken;
       

    }


    function airdropToken(address _tokenAdd, address[] calldata receiverArray, uint[] calldata receiverAmount) external onlyManager{
        require(receiverArray.length == receiverAmount.length, "totalNumber of address and totalNumber of value doesnt match");
        for(uint i = 0; i < receiverArray.length; i++){
            address receipient = receiverArray[i];
            uint amount = receiverAmount[i];
            uint senderBal = IERC20(_tokenAdd).balanceOf(msg.sender);
            require(senderBal >= amount, "insufficient balances for airdrop");
            IERC20(_tokenAdd).transferFrom(msg.sender, receipient, amount);
            
        }
    }

    function printerdetails(address _tokenAdd, address receiver) external view returns(uint, uint, uint, uint){
         uint holderPortion;
        uint totalcollection = printer.totalRewardReflaction(_tokenAdd);
        if(receiver != address(0)){
          holderPortion = printer.shareHolderBal(_tokenAdd, receiver);
        }
        uint totalDistributed = printer.totalRewardDistributed(_tokenAdd);
        uint payableReward = printer.totalPayableReward(_tokenAdd);
        return (holderPortion, totalcollection, totalDistributed,payableReward);

    }
  
}