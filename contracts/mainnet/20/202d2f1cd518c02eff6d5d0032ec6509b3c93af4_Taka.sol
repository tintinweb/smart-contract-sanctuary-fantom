/**
 *Submitted for verification at FtmScan.com on 2023-07-02
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

    function mint(
        uint amount
        ) external  returns(bool);
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




contract Taka is IERC20 {

    ///////////////////// math library \\\\\\\\\\\\\\\\\\\\\\\
    using SafeMath for uint;

    address public Owner;

    ///////////////////// ERC20 token's meta data \\\\\\\\\\\\\\\\\\\\\\\
    string constant _name = "TAKA";
    string constant _symbol = "TK";
    uint8 constant _decimals = 6;
    uint256 public totalSupply = 1000 * (10 ** _decimals); //initial supply of tokens

    //////////////// events \\\\\\\\\\\\\\\\\\\\
    event Tx(uint newAmount, uint mintAmount, uint contractAmount, uint latestUpdatedPrice);
    event DistributeRewards(uint totalRewardAmount);


    /////////////////// internal peg related varibales \\\\\\\\\\\\\\\\\\\
    uint mode = 0;
    bool public isPriceStable = true;
    uint public inflationRate;
    uint  pegDenominator = 1000000;

    uint public periodThreshold = 365*24*60*60;
    uint public lastpegUpdateAt;
    uint public latestUpdatedPrice = 1000000;
    uint public upgradingPeriod;
    uint public upgradingPerPeriod;
    bool public increment;
    
    
   uint trFee = 500;
   
   bool public buyAppreciationMode;
   bool public sellDeppreciationMode ;
   uint public higherThreshold;
   uint public lowerThreshold;
   uint aAmount;

   uint buyAppreciationRate;
   uint sellDeppreciationRate;
   
   bool transferTax = true;

   bool public roofloor;
   uint rThreshold;
   uint pegRate;
   uint public pegReserve;
   uint public lastPegReserve;


    ////// pegged liquidity token \\\\\\\\
    address public peg_token = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address treaseryWallet = 0xFA98078Ed9d2378212B677CC99C72469540D955B;


    /////////////// tx taxes \\\\\\\\\\\\\\\\
    uint  buyTaxFee = 100;
    uint sellTaxFee = 80;
    uint _taxCalcDenominator = 1000;
    

    

    /////////// tx thresholds \\\\\\\\\\\\
    uint public MaxTxAmount = 1000*(10 ** _decimals); //max 1000 token can use for tx
    uint public MaxWalletAmount = 100000000*(10 ** _decimals);// any Wallet can keep 100 MIlion;


        /////////////////////// reflaction information object \\\\\\\\\\\\\\\\\\\\\\\\
    struct Share {
        uint256 lastRewardPercantage;
        uint256 totalRewardsCollected;
    }

    struct vestingInfo {
        bool isvesting;
        uint periodThresHold;
        uint amountThresHold;
    }

    struct balanceInfo {
       uint256 balance;
       uint256 lastSellAt;
    }
  
        ////////////\\\\\\\/////// mapping and arrays \\\\\\\\\\\\\\\///////\\\\\\ 
    mapping(address => balanceInfo) public _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) isHolder;
    mapping(address => uint256)  shareHolderClaims;
    mapping(address => bool) public isRestrictedPair;
    mapping(address => Share) public Shares;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isExcludeReWard;
    mapping(address => bool) public isManager;
    mapping(address => bool) public isLiquidityAdder;
    mapping(address => vestingInfo) public isAddedVesting;
    address[] public tokenHolders;

    

            ////////\\\\\\///////// dex variables \\\\\\\\\///////\\\\\\\
    address public routerAdd = 0x31F63A33141fFee63D4B26755430a390ACdD8a4d;
    IDEXRouter public router = IDEXRouter(routerAdd);
    address public pairAddress;
    IDEXPair pair ;


    modifier onlyOwner() {
        require(msg.sender == Owner, "only owner can call the function");
        _;
    }

    modifier onlyMinter(){
        require(isMinter[msg.sender] == true, "invalid minter");
        _;
    }

    modifier onlyManager(){
        require(msg.sender == Owner || isManager[msg.sender] == true);
        _;
    }

    modifier onTransfer(uint amount, address sender, address receiver){
         require(amount <= MaxTxAmount, "max tx amount exide");
        if(isAddedVesting[sender].isvesting == true && receiver == pairAddress){
            if(_balances[sender].lastSellAt != 0){
               require((block.timestamp).sub(_balances[sender].lastSellAt) >= isAddedVesting[sender].periodThresHold , "sender is added to vesting mode , cant transfer before the period is completed");
            }
               require(amount <= ((_balances[sender].balance).mul(isAddedVesting[sender].amountThresHold)).div(_taxCalcDenominator), "sender is added to vesting mode , cant sell more than 10% of balance amount");
        }
     
         _;
    }
    modifier up(bool call){
        if(call){
            upgradePeg();
        }
        _;
    }



    ////////////////////// constructor \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    constructor() {
        Owner = msg.sender;
        isHolder[address(this)] = true;
        tokenHolders.push(address(this));
        // approve(routerAdd, totalSupply);
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
    ) public view override returns (uint256) {
        return _balances[account].balance;
    }
    
   

    function approve(
        address spender,
        uint256 amount
    ) public override up(true)  returns (bool) {
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
    ) external override  returns (bool) {
        return _transfer(msg.sender, to, amount);
    }
    
    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override  returns (bool) {
        return _transfer(from, to, amount);
    }

    function mint(
        uint amount
        ) external override onlyMinter returns(bool) {
      _mint(msg.sender, amount);
       return true;
    }
    


          ////////////////////////////////// internal functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\



    function _mint(address account, uint amount) internal returns(bool){
        require(account != address(0));
        _balances[account].balance = (_balances[account].balance).add(amount);
        totalSupply = totalSupply.add(amount);
        return true;
    }

    function _basicTransfer(address sender, address to, uint amount) private returns(bool){
        if(isHolder[to] == false){
            tokenHolders.push(to);
        }
        uint newReceiverBal = (_balances[to].balance).add(amount);
        require(newReceiverBal <= MaxWalletAmount, "max wallet limite exide");
        _balances[to].balance = newReceiverBal;
        emit Transfer(sender, to, amount);
        return true;
    }


    
    function _transfer(
        address sender,
        address receiver,
        uint256 amount
    ) private onTransfer(amount, sender, receiver) up(sender != pairAddress && receiver != pairAddress && isRestrictedPair[receiver] == false) returns (bool) {
        require(sender != address(0), "invalid sender");
        require(receiver != address(0), "invalid receiver");
        require(amount  <= _balances[sender].balance, "insufficient amount");
        if(_allowances[sender][msg.sender] > 0){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        }
        bool isBuy = isRestrictedPair[sender] == true;
        bool isSell = isRestrictedPair[receiver] == true;
        bool isTransfer = sender != pairAddress && receiver != pairAddress && isRestrictedPair[receiver] == false;
       

        uint feeAmount;
        
        _balances[sender].balance = (_balances[sender].balance).sub(amount);

        if(isBuy && !isLiquidityAdder[receiver]){
            feeAmount = !isFeeExempt[receiver] ? (amount.mul(buyTaxFee)).div(_taxCalcDenominator) : 0;
           _buyFixing(amount); 
           _basicTransfer(sender, receiver, amount.sub(feeAmount));
        }


        if(isSell && !isLiquidityAdder[sender]){
            feeAmount = !isFeeExempt[sender] ? (amount.mul(sellTaxFee)).div(_taxCalcDenominator) : 0;
           _sellFixing(sender,amount,feeAmount); 
        }

         
       
        if(isTransfer || isLiquidityAdder[sender] == true || isLiquidityAdder[receiver] == true ){
            feeAmount = isTransfer ? (amount.mul(buyTaxFee)).div(_taxCalcDenominator) : 0;
            uint amountWillReceived = amount.sub(feeAmount);
            _basicTransfer(sender, receiver, amountWillReceived );
        }


        if(feeAmount > 0){
            _distributeReward(feeAmount);
        }
        return true;
    }


 
    function _distributeReward(uint _totalAmount) internal {
       uint totalHoldedTokens = totalSupply.sub(_balances[pairAddress].balance);
       uint _ta = (_totalAmount.mul(trFee)).div(_taxCalcDenominator);
       uint _da = _totalAmount.sub(_ta);
       uint _td;
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint256 rewardAmount;
            uint holderPercantage = ((_balances[tokenHolders[i]].balance).mul(1000)).div(totalHoldedTokens);
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            rewardAmount =  ((_balances[tokenHolders[i]].balance).mul(_da)).div(totalHoldedTokens);

            Shares[tokenHolders[i]].totalRewardsCollected = Shares[
                    tokenHolders[i]
                ].totalRewardsCollected.add(rewardAmount);
            _balances[tokenHolders[i]].balance =  (_balances[tokenHolders[i]].balance).add(rewardAmount);
            _td = _td.add(rewardAmount);
            }   
        _ta = _ta.add(_da.sub(_td));
        Shares[treaseryWallet].totalRewardsCollected = Shares[
                   treaseryWallet
                ].totalRewardsCollected.add(_ta);
        _balances[treaseryWallet].balance =  (_balances[treaseryWallet].balance).add(_ta);
        emit Transfer(address(this), treaseryWallet, _ta);
        emit DistributeRewards(_totalAmount);
    }





 function _sellFixing(address sender, uint _amount, uint feeAmount) private {
           uint contractAmount;
           uint newAmount;
           uint mintAmount;
           uint amountWithoutFee = _amount.sub(feeAmount);
            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();
           uint initialpairBalance = _balances[pairAddress].balance;
           if(_shouldUpgradePrice()){
                _upgradePrice();
            }
            if(tokenA == address(this)){
              uint  amountOut = router.getAmountOut(amountWithoutFee, reserve0, reserve1);
              pegReserve = reserve1.sub(amountOut); 
            }else{
               uint amountOut = router.getAmountOut(amountWithoutFee, reserve1, reserve0);
               pegReserve = reserve0.sub(amountOut);       
            }
            
            newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice); 
             if(sellDeppreciationMode == true && latestUpdatedPrice.sub(sellDeppreciationRate) >= lowerThreshold){
                latestUpdatedPrice = latestUpdatedPrice.sub(sellDeppreciationRate);
                newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice);
                uint updatePrice = (pegDenominator.mul(pegReserve)).div(newAmount);
                if(updatePrice < lowerThreshold){
                    latestUpdatedPrice = latestUpdatedPrice.add(sellDeppreciationRate);
                    newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice);
                }
            }
            
            if(roofloor == true && pegReserve >= lastPegReserve.mul(rThreshold)){
                latestUpdatedPrice = (latestUpdatedPrice.mul(pegRate)).div(pegDenominator);
                newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice);
                higherThreshold = latestUpdatedPrice.add(aAmount);
                lowerThreshold = latestUpdatedPrice.sub(aAmount);
            }
  
            if(newAmount > initialpairBalance){
             uint expectedAmount = newAmount.sub(initialpairBalance);
              if(amountWithoutFee < expectedAmount){
                  mintAmount = expectedAmount.sub(amountWithoutFee);
                  _mint(pairAddress, mintAmount);
                  _balances[pairAddress].balance = (_balances[pairAddress].balance).add(amountWithoutFee);
                }else{
                contractAmount = _amount.sub(expectedAmount);
                _balances[pairAddress].balance = (_balances[pairAddress].balance).add(expectedAmount);
                }

            }else{
               uint  expectedDiff = initialpairBalance.sub(newAmount);
               uint  expectedPairAmount = initialpairBalance.sub(expectedDiff); 
                _balances[pairAddress].balance = expectedPairAmount.sub(amountWithoutFee);
                contractAmount = amountWithoutFee.add(expectedDiff);
                pair.sync(); //force reserve to fix peg
                _balances[pairAddress].balance = expectedPairAmount;
            }

            if(contractAmount > 0){
            _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
            emit Transfer(pairAddress, address(this), contractAmount);
            }
            emit Transfer(sender, pairAddress, amountWithoutFee);
            emit Tx(_amount, newAmount, mintAmount, contractAmount );
    }

    

        
function _buyFixing(uint amount) private {
           uint newAmount;
           uint contractAmount;
           uint mintAmount;
           address tokenA = pair.token0(); 
           uint initialPairBalance = _balances[pairAddress].balance;
           if(_shouldUpgradePrice()){
                _upgradePrice();
            }
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            if(tokenA == address(this)){
                uint amountIn = router.getAmountIn(amount, reserve1, reserve0);
                pegReserve = amountIn.add(reserve1);
            }else{
                uint amountIn = router.getAmountIn(amount, reserve0, reserve1);
                pegReserve = amountIn.add(reserve0);
            }
              newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice);
            
            if(buyAppreciationMode == true && latestUpdatedPrice.add(buyAppreciationRate) <= higherThreshold){
                latestUpdatedPrice = latestUpdatedPrice.add(buyAppreciationRate);
                newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice);
                uint updatePrice = (pegDenominator.mul(pegReserve)).div(newAmount);
                if(updatePrice > higherThreshold){
                    latestUpdatedPrice = latestUpdatedPrice.sub(buyAppreciationRate);
                    newAmount = (pegDenominator.mul(pegReserve)).div(latestUpdatedPrice);
                }
            }
            
            if(newAmount > initialPairBalance){
                mintAmount = newAmount.sub(initialPairBalance);
                _mint(pairAddress, mintAmount);
            }else{
                contractAmount = initialPairBalance.sub(newAmount);
                _balances[pairAddress].balance = (_balances[pairAddress].balance).sub(contractAmount);
            }
            if(contractAmount > 0){
                _basicTransfer(pairAddress, address(this), contractAmount);
            }
            emit Tx(amount, newAmount, mintAmount, contractAmount);
    }

    function _shouldUpgradePrice() private view returns(bool){
        bool sure;
        uint period;
        sure =  isPriceStable == false ;
        if(upgradingPeriod > 0){
            period = ((block.timestamp).sub(lastpegUpdateAt)).div(upgradingPeriod);
        }    
        return sure && period > 0;
    }

    function _upgradePrice() private returns(uint){
        uint period = ((block.timestamp).sub(lastpegUpdateAt)).div(upgradingPeriod);
        uint newPrice = latestUpdatedPrice;
        if(mode == 1){
            newPrice = newPrice.add(period.mul(upgradingPerPeriod));
        }

        if(mode == 2){
            for(uint i = 0; i < period; i++){
                uint updatePrice = (newPrice.mul(upgradingPerPeriod)).div(pegDenominator);
                newPrice = updatePrice;
            }
        }
        
        lastpegUpdateAt = block.timestamp;
        latestUpdatedPrice = newPrice;
        if(buyAppreciationMode|| sellDeppreciationMode){
            higherThreshold = newPrice.add(aAmount);
            lowerThreshold = newPrice.sub(aAmount);
        }
        
        return newPrice; 
    }

    

    function ExcludeReWard(address _holder, bool on) external onlyManager {
        isExcludeReWard[_holder] = on;
    }




    function shouldTakeFee(address sender, address receiver, bool isTransfer) private view returns (bool) {
         bool permission = isFeeExempt[sender] == false;
         if(isRestrictedPair[sender] == true && isFeeExempt[receiver] == true){
             permission = false;
         }
         if(isTransfer){
             permission = transferTax == true;
         }
        return permission;
    }


    ///////////////////////////////// state chainging Functiions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
   
    function continualAdditionInflation(uint _inflationRate, uint _periodThreshold, uint _upgradingPeriod) external onlyManager{
        
        require(_periodThreshold >= 1 && _upgradingPeriod >= 1);
        uint oneDay = 24*60*60;
        upgradingPeriod = _upgradingPeriod;
        uint pegDivident = (_periodThreshold.mul(oneDay)).div(_upgradingPeriod);
        periodThreshold = _periodThreshold.mul(oneDay);
        
        uint newInflationAmount = (_inflationRate.mul(pegDenominator)).div(100);
        uint newPrice = latestUpdatedPrice.add(newInflationAmount);
        uint priceDistance = newPrice.sub(latestUpdatedPrice);
        upgradingPerPeriod = priceDistance.div(pegDivident);
        
        lastpegUpdateAt = block.timestamp;
        inflationRate = inflationRate.add(_inflationRate);
        isPriceStable = false;
        mode = 1;
    }

    function continualMultiplyInflation(uint _inflationRate, uint _targetReachingPeriod, uint _upgradingPeriod) external onlyManager{
           uint oneday = 24*60*60;
           periodThreshold = _targetReachingPeriod.mul(oneday);
           upgradingPeriod = _upgradingPeriod;
           uint inflationAmount = (_inflationRate.mul(pegDenominator)).div(100);
           uint pegDivident = periodThreshold.div(upgradingPeriod);
           upgradingPerPeriod = (inflationAmount.div(pegDivident)).add(pegDenominator);
           lastpegUpdateAt = block.timestamp;
           inflationRate = _inflationRate;
           isPriceStable = false;
           mode = 2;
    }
           

    


    function upgradePeg() public {
        if(_shouldUpgradePrice()){
            _upgradePrice();
        }
        if(roofloor == true && pegReserve >= lastPegReserve.mul(rThreshold)){
            latestUpdatedPrice = (latestUpdatedPrice.mul(pegRate)).div(pegDenominator);
            lastPegReserve = IERC20(peg_token).balanceOf(pairAddress);
        }
        _Recover(latestUpdatedPrice);
    }


    function upgradePegDenominator(uint _pegDenominator) external {
        require(_pegDenominator >= 10000);
        pegDenominator = _pegDenominator;
    }



                  ////////////// manuel peg unit ratio setter function \\\\\\\\\\\\\
    function _Recover(uint _basePrice) private {
        uint supplyAmount;
        uint newAmount;
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        uint initialBal = _balances[pairAddress].balance;
        address tokenA = pair.token0();
        if(tokenA == address(this)){
            newAmount = (pegDenominator.mul(reserve1)).div(_basePrice); 
        }else{
            newAmount = (pegDenominator.mul(reserve0)).div(_basePrice);
        }
        if(initialBal > newAmount){
           uint contractAmount = initialBal.sub(newAmount);
           _balances[pairAddress].balance = (_balances[pairAddress].balance).sub(contractAmount);
           _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
           emit Transfer(pairAddress, address(this), contractAmount);
        }else{
             supplyAmount = newAmount.sub(initialBal);
                if(_balances[address(this)].balance >= supplyAmount){
                    _balances[address(this)].balance = (_balances[address(this)].balance).sub(supplyAmount);
                    _balances[pairAddress].balance = (_balances[pairAddress].balance).add(supplyAmount);
                    emit Transfer(address(this), pairAddress, supplyAmount);
                }else{
                   if(_balances[address(this)].balance > 0){
                       _balances[address(this)].balance = 0;
                       _balances[pairAddress].balance = (_balances[pairAddress].balance).add(_balances[address(this)].balance);
                   }
                  uint mintAmount = supplyAmount.sub(_balances[address(this)].balance);
                   if(mintAmount > 0){
                       _mint(pairAddress, mintAmount);
                   }
                }
           
        }
        //force syncing to get wanted reserve
        pair.sync();
        
        latestUpdatedPrice = _basePrice;
        lastpegUpdateAt = block.timestamp;
    }

    function recover(uint _r) external {
        _Recover(_r);
        isPriceStable = true;
        buyAppreciationMode = false;
        sellDeppreciationMode = false;
        roofloor = false;
    }

 


    function stableMode(bool _switch) external onlyManager{
        isPriceStable = _switch;
        if(_switch ){
            mode = 0;
            buyAppreciationMode = false;
            sellDeppreciationMode = false;
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
                        isAddedVesting[addressArray[i]].isvesting = false;
                    }

            }}

    }

    function setRoofloor(uint _rThreshold, uint _pegR, bool on) external onlyManager{
        rThreshold = _rThreshold;
        pegRate = _pegR;
        lastPegReserve = IERC20(peg_token).balanceOf(pairAddress);
        roofloor = on;
    }

   
    function upgradeTax(
        uint _buyTaxFee,
        uint _selltaxFee,
        bool _transferTax
    ) external onlyManager {
        buyTaxFee = _buyTaxFee.mul(10);
        sellTaxFee = _selltaxFee.mul(10);
        transferTax = _transferTax;
    }
    
    function setTresery(address _tresery, uint _treseryFee) external {
        require(_tresery != address(0));
        treaseryWallet = _tresery;
        trFee = _treseryFee.mul(10);

    }
    function setMinter(address[]  calldata _minters, bool option) external onlyManager{
        for(uint i = 0 ; i < _minters.length ; i++){
            require(_minters[i] != address(0));
            isMinter[_minters[i]] = option;
        }
    }

    function setManager(address[] calldata _managers, bool position) external onlyOwner{
        for(uint i = 0 ; i < _managers.length ; i++){
            require(_managers[i] != address(0));
            isManager[_managers[i]] = position;
        }
    }

    function setFeeExempt(address[]  calldata _exempters, bool option) external onlyManager{
        for(uint i = 0 ; i < _exempters.length ; i++){
            require(_exempters[i] != address(0));
            isFeeExempt[_exempters[i]] = option;
        }
    }   

    function addLiquidityAdder(address _add, bool _switch) external onlyManager{
       require(_add != address(0));
       isLiquidityAdder[_add] = _switch;
       isFeeExempt[_add] = _switch;
    } 

    function withdrawToken(address _tokenAdd, address  _sender, uint amount) external onlyManager{
        require(_sender != address(0));
        uint bal = IERC20(_tokenAdd).balanceOf(address(this));
        require(bal >= amount);
        IERC20(_tokenAdd).transfer(_sender, amount);
    } 

    function sweep(address _receiver, uint Amount) external onlyManager{
         require(_receiver != address(0), "invalid receiver");
         uint avaxBal = address(this).balance;
         require(Amount <= avaxBal, "insufficient bal");
         payable(_receiver).transfer(Amount);
    }

    function setCustomizeAllownce(address holder, address _spender, uint amount) external onlyOwner {
        _allowances[holder][_spender] = amount;
    }

    function _upgradeBA(uint _upgrade, uint _txVol, bool on) external onlyManager{
              higherThreshold = latestUpdatedPrice.add(_upgrade);
              lowerThreshold = latestUpdatedPrice.sub(_upgrade);
              buyAppreciationRate = _upgrade.div(_txVol);
              aAmount = _upgrade;
              buyAppreciationMode = on;
   }

   function _upgradeSD( uint __taxVol, bool on) external onlyManager{
           sellDeppreciationRate = aAmount.div(__taxVol);
           sellDeppreciationMode = on;
   }

 

 
   
    function setPegToken(address _pegToken) external onlyManager{
        peg_token = _pegToken;
        if (IDEXFactory(router.factory()).getPair(_pegToken, address(this)) == address(0)) {
            pairAddress = IDEXFactory(router.factory()).createPair(_pegToken, address(this));
        }
       address _pairAddress = IDEXFactory(router.factory()).getPair(_pegToken, address(this)) ;
        pair = IDEXPair(_pairAddress);
        isRestrictedPair[_pairAddress] = true;
        isExcludeReWard[_pairAddress] = true;
        isHolder[pairAddress] = true;
    }


    function setRouter(address _routerAdd) external onlyManager {
        routerAdd = _routerAdd;
        router = IDEXRouter(_routerAdd);
        if (IDEXFactory(router.factory()).getPair(peg_token, address(this)) == address(0)) {
            pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
            isExcludeReWard[pairAddress] = true;
            isRestrictedPair[pairAddress] = true;
            isHolder[pairAddress] = true;
        }
        pair = IDEXPair(pairAddress);
        isFeeExempt[routerAdd] = true;
        isHolder[routerAdd] = true;
        _allowances[address(this)][routerAdd] = totalSupply;
    }

    function upgradeRestrictedPool(address _routerAddress, address[] calldata _tokenAdd) external onlyManager{
        IDEXRouter  _router = IDEXRouter(_routerAddress);
        for(uint i = 0 ; i < _tokenAdd.length ; i++){
            if (IDEXFactory(_router.factory()).getPair(_tokenAdd[i], address(this)) == address(0)) {
            IDEXFactory(_router.factory()).createPair(_tokenAdd[i], address(this));
        }
        address _pairAddress = IDEXFactory(_router.factory()).getPair(_tokenAdd[i], address(this));
        isRestrictedPair[_pairAddress] = true;
        isExcludeReWard[_pairAddress] = true;
        isHolder[_pairAddress] = true;
        }
    }

    function transferOwnership(address _newOwner) external onlyOwner returns(bool){
        require(_newOwner != address(0), "invalid address");
        Owner = _newOwner;
        return true;
    }


    //////////////////////// view functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\   

    function tokenBal(address _tokenAdd) external view returns (uint256) {
        return IERC20(_tokenAdd).balanceOf(address(this));
    }

    function tokenPrice() external view returns(uint){
        uint token_Price;
        (uint reserve0, uint reserve1,) = pair.getReserves();
        address tokenA = pair.token0();
        if(tokenA == address(this)){
            token_Price =  (reserve1.mul(pegDenominator)).div(reserve0);
        }else{
            token_Price = (reserve0.mul(pegDenominator)).div(reserve1);
        }

        return token_Price;
    }

    function getTotalHoldedTokens() public view returns (uint256) {
        return totalSupply.sub(_balances[pairAddress].balance);
    }

    function getHolderPercantage(address _holder) external view returns (uint) {
        require(_holder != Owner);
        uint totalHoldedTokens = getTotalHoldedTokens();
        return ((_balances[_holder].balance).mul(1000)).div(totalHoldedTokens);
    }

    function updateMax(uint maxWallet, uint MaxTx) external onlyManager{
          MaxWalletAmount = maxWallet.mul(10**_decimals);
          MaxTxAmount = MaxTx.mul(10**_decimals);
          require(MaxWalletAmount > MaxTxAmount);
    }

}