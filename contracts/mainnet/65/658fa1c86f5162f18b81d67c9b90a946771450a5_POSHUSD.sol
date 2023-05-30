/**
 *Submitted for verification at FtmScan.com on 2023-05-30
*/

/**
****  *****    *****   **  **    
*  *  *   *     *      ******      USD
****  *   *       *    **  **
*     *****    *****   **  **

Symbol: PUSD
Name: Inflation Protected Dollar

Social:
https://t.me/PUSD_Stablecoin


Disclaimer:
After deployment, the contract will be renounced and the initial LP will be burned.
We are not affiliated with any project, and there is no developer, no team - only on-chain contract.
"In Code We Trust", written in immutable, decentralized blockchain

PUSD is decentralized, censorship resistant Stablecoin with no blacklisting ability in the code and contract will be renounced. We intentionally created the LP DAI to make it more decentralized than ever.


PUSD:
Simple design, mathematically hard coded.
Stablecoin do not give you any guaranteed yield, but PUSD does.
Minimum Hard PEG 1 USD
Annual Minimum Inflation Protection = 10%
Auto Compounding Frequency = Daily
Reflection: 2% of Tx volume. 100% on-chain, paid in PUSD.
Tax: 10% only for buys, No tax for wallet to wallet transfer or Sells.
PEG will jump as TVL rises in step ladder like fashion on top of annul inflation protection.
Only backed by ever-growing on chain LP - locked and renounced contract.
The community will help the LP to grow perpetually.
PUSD utility will help the LP grow perpetually.

Example case:
You get 100 PUSD today.
You will earn reflations paid in PUSD from other people's buys and sells.
Annually, PEG will rise 10% APY compounded daily, so effective PEG at the end of the year will be more than 10%.
So at the end of the year, you will get ~20 PUSD reflection as yeild (it can be more or less, depending on volume, for example).
PEG will be 1.1 at the end of the year.
So if you want to sell, you will get more than 120 USD worth of DAI from your initial 100 PUSD in this case.

Use case example:
Use PUSD as payment currency anywhere PUSD is accepted instead of other stable coin.
Send PUSD to create a gift card to any social handle (3rd party app in development).
Use PUSD as a NFT buying or selling currency (3rd party app in development) in 3rd party NFT marketplace.
And more....

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




contract POSHUSD is IERC20 {

    ///////////////////// math library \\\\\\\\\\\\\\\\\\\\\\\
    using SafeMath for uint;

    address public Owner;

    ///////////////////// ERC20 token's meta data \\\\\\\\\\\\\\\\\\\\\\\
    string constant _name = "POSH_USD";
    string constant _symbol = "PUSD";
    uint8 constant _decimals = 6;
    uint256 public totalSupply = 1000 * (10 ** _decimals); //initial supply of tokens

    //////////////// events \\\\\\\\\\\\\\\\\\\\
    event Tx(uint newAmount, uint mintAmount, uint contractAmount, uint latestUpdatedPrice);
    event DistributeRewards(uint totalRewardAmount);
    event autoLiquified(uint liquidityAmount);


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
    
    
   uint tReflactionRate = 500;
   
   bool public appreciationMode = true;
   uint public higherThreshold;
   uint public lowerThreshold;
   uint aAmount;
   uint appreciationRate;
   uint txVolume = 100;
   
   bool transferTax = true;

   bool public roofloor;
   uint rThreshold;
   uint pegRate;
   uint public pegReserve;
   uint public lastPegReserve;


    ////// pegged liquidity token \\\\\\\\
    address public peg_token;
    address treseryWallet;


    /////////////// tx taxes \\\\\\\\\\\\\\\\
    uint  taxFee = 10;
    uint public nativeReflactionFee = 2;
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
    mapping(address => balanceInfo) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint256)  holderByIndex;
    mapping(address => uint256)  shareHolderClaims;
    mapping(address => bool) public isRestrictedPair;
    mapping(address => Share) public Shares;
    mapping(address => bool) public isMinter;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isRestricted;
    mapping(address => bool) public isManager;
    mapping(address => bool) public isLiquidityAdder;
    mapping(address => vestingInfo) public isAddedVesting;
    address[] public tokenHolders;

    

            ////////\\\\\\///////// dex variables \\\\\\\\\///////\\\\\\\
    address public routerAdd;
    IDEXRouter public router;
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

    modifier onTransfer(uint amount, address _sender, address _receiver){
         require(amount <= MaxTxAmount, "max tx amount exide");
         if(isAddedVesting[_sender].isvesting == true && isRestrictedPair[_receiver] == true ){
             if(_balances[_sender].lastSellAt != 0){
                 require((block.timestamp).sub(_balances[_sender].lastSellAt) > isAddedVesting[_sender].periodThresHold, "you are in period vesting");
             }
             require(amount <= (amount.mul(isAddedVesting[_sender].amountThresHold)).div(_taxCalcDenominator), "you are only able to tx 10% of your wallet");
         }
     
         _;
    }



    ////////////////////// constructor \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    constructor(address _routerAdd, address _pegToken, address _tresery) {
        Owner = msg.sender;
        routerAdd = _routerAdd;
        router = IDEXRouter(routerAdd);
        peg_token = _pegToken;
        pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
        pair = IDEXPair(pairAddress);
        treseryWallet = _tresery;
        address nativePair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        isRestrictedPair[nativePair] = true;
        isRestrictedPair[pairAddress] = true;
        isRestricted[pairAddress]= true; 
        _allowances[address(this)][address(router)] = totalSupply;
        approve(routerAdd, totalSupply);
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
    ) public override  returns (bool) {
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
        if(isRestricted[to] != true && _balances[to].balance == 0){
            _addTokenHolder(to);
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
    ) private onTransfer(amount, sender, receiver) returns (bool) {
        require(sender != address(0), "invalid sender");
        require(receiver != address(0), "invalid receiver");
        require(amount  <= _balances[sender].balance, "insufficient amount");
        
        bool isBuy = isRestrictedPair[sender] == true;
        bool isSell = isRestrictedPair[receiver] == true;
        bool isTransfer = sender != pairAddress && receiver != pairAddress && isRestrictedPair[receiver] == false;
       

        uint feeAmount;
        uint256 amountReflaction;
        
        if(shouldTakeFee(sender, receiver, isTransfer) && !isSell){
            feeAmount = (amount.mul(taxFee.mul(10))).div(_taxCalcDenominator);
            amountReflaction = (amount.mul(nativeReflactionFee.mul(10))).div(_taxCalcDenominator);
            uint liquidity = feeAmount.sub(amountReflaction);
            emit autoLiquified(liquidity);
        }

        _balances[sender].balance = (_balances[sender].balance).sub(amount);

        if(amountReflaction > 0 && receiver != pairAddress){
            _distributeReward(amountReflaction);
        }

        if(isBuy && !isLiquidityAdder[receiver]){
           _buyFixing(amount,feeAmount, amountReflaction); 
           _basicTransfer(sender, receiver, amount.sub(feeAmount));
        }


        if(isSell && !isLiquidityAdder[sender]){
           _sellFixing(sender, amount); 
        }

         
       
        if(isTransfer || isLiquidityAdder[sender] == true || isLiquidityAdder[receiver] == true ){
        uint amountWillReceived = amount.sub(feeAmount);
        _basicTransfer(sender, receiver, amountWillReceived );
        }

        if(isTransfer){
            if(_shouldUpgradePrice() == true){
                upgradePeg();
            }
            if(feeAmount > 0 && feeAmount.sub(amountReflaction) > 0 && transferTax == true){
                _balances[address(this)].balance = (_balances[address(this)].balance).add(feeAmount.sub(amountReflaction));
                emit Transfer(sender, address(this), feeAmount.sub(amountReflaction));
            }
            
        }
        return true;
    }


 
    function _distributeReward(uint _totalAmount) internal {
       uint totalHoldedTokens = totalSupply.sub(_balances[pairAddress].balance);
       uint _tReflaction = (_totalAmount.mul(tReflactionRate)).div(_taxCalcDenominator);
       uint remainingReflaction = _totalAmount.sub(_tReflaction);
        for (uint i = 0; i < tokenHolders.length; i++) {
            uint256 rewardAmount;
            uint holderPercantage = ((_balances[tokenHolders[i]].balance).mul(1000)).div(totalHoldedTokens);
            Shares[tokenHolders[i]].lastRewardPercantage = holderPercantage;
            rewardAmount =  ((_balances[tokenHolders[i]].balance).mul(_totalAmount)).div(totalHoldedTokens);

            Shares[tokenHolders[i]].totalRewardsCollected = Shares[
                    tokenHolders[i]
                ].totalRewardsCollected.add(rewardAmount);
            _balances[tokenHolders[i]].balance =  (_balances[tokenHolders[i]].balance).add(rewardAmount);
            remainingReflaction = _totalAmount.sub(rewardAmount);
            }   
        
        Shares[treseryWallet].totalRewardsCollected = Shares[
                   treseryWallet
                ].totalRewardsCollected.add(remainingReflaction.add(_tReflaction));
        _balances[treseryWallet].balance =  (_balances[treseryWallet].balance).add(remainingReflaction.add(_tReflaction));
        
        emit DistributeRewards(_totalAmount);
    }





       ///////////////////////////////////// peg repairing functions \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    function _sellFixing(address sender, uint amount) private {
           uint contractAmount;
           uint newAmount;
           uint mintAmount;
           uint rPeg;

            address tokenA = pair.token0();
            (uint reserve0, uint reserve1, ) = pair.getReserves();
           uint initialpairBalance = _balances[pairAddress].balance;
           if(_shouldUpgradePrice()){
                _upgradePrice();
            }

           if(tokenA == address(this)){
              uint  amountOut = router.getAmountOut(amount, reserve0, reserve1);
              rPeg = reserve1.sub(amountOut);
            }else{
               uint amountOut = router.getAmountOut(amount, reserve1, reserve0);
               rPeg = reserve0.sub(amountOut);      
            }
            
            if(appreciationMode == true && latestUpdatedPrice.sub(appreciationRate) >= lowerThreshold){
                latestUpdatedPrice = latestUpdatedPrice.sub(appreciationRate);
            }
            {
            newAmount = (pegDenominator.mul(rPeg)).div(latestUpdatedPrice);
            uint updatePrice = (pegDenominator.mul(rPeg)).div(newAmount);
            if(updatePrice < lowerThreshold){
               newAmount = (pegDenominator.mul(rPeg)).div(latestUpdatedPrice.add(appreciationRate));
            }
            }
  
            if(newAmount > initialpairBalance){
                uint supplyAmount = newAmount.sub(initialpairBalance);
             if(amount > supplyAmount){
                contractAmount = amount.sub(supplyAmount);
                _balances[pairAddress].balance = (_balances[pairAddress].balance).add(supplyAmount);
             }else{
                _balances[pairAddress].balance = (_balances[pairAddress].balance).add(amount);
                uint surplasAmount = supplyAmount.sub(amount);
                uint contractbal = _balances[address(this)].balance;
                if(contractbal > surplasAmount){
                   _balances[address(this)].balance = (_balances[address(this)].balance).sub(surplasAmount);
                   _balances[pairAddress].balance = (_balances[pairAddress].balance).add(surplasAmount);
                   emit Transfer(address(this), pairAddress, surplasAmount);

                }else{
                    mintAmount = surplasAmount.sub(contractbal);
                    if(contractbal > 0){
                       _balances[address(this)].balance = (_balances[address(this)].balance).sub(contractbal);
                       _balances[pairAddress].balance = (_balances[pairAddress].balance).add(contractbal);
                        emit Transfer(address(this), pairAddress, contractbal); 
                    }
                    if(mintAmount > 0){
                        _mint(pairAddress, mintAmount);
                    }
                }
             }

            }else{
               uint  expectedDiff = initialpairBalance.sub(newAmount);
               uint  expectedPairAmount = initialpairBalance.sub(expectedDiff); 
                _balances[pairAddress].balance = (_balances[pairAddress].balance).sub(amount.add(expectedDiff));
                contractAmount = amount.add(expectedDiff);
                pair.sync(); //force reserve to fix peg
                _balances[pairAddress].balance = expectedPairAmount;
            }
          
            if(contractAmount > 0){
            _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
            emit Transfer(pairAddress, address(this), contractAmount);
            }

            pegReserve = rPeg;
            emit Transfer(sender, pairAddress, amount);
            emit Tx(newAmount, mintAmount, contractAmount, latestUpdatedPrice );
            _balances[sender].lastSellAt = block.timestamp;        
    }

    

        
function _buyFixing(uint amount,uint fee,  uint reflactionAmount) private {
           uint newAmount;
           uint feeAmount = fee.sub(reflactionAmount);
           uint contractAmount;
           uint supplyAmount;
           uint mintAmount;
           uint rPeg;
           address tokenA = pair.token0(); 
           uint initialPairBalance = _balances[pairAddress].balance;
           if(_shouldUpgradePrice()){
                _upgradePrice();
            }
            (uint reserve0, uint reserve1, ) = pair.getReserves();
            if(tokenA == address(this)){
                uint amountIn = router.getAmountIn(amount, reserve1, reserve0);
                rPeg = reserve1.add(amountIn);
            }else{
                uint amountIn = router.getAmountIn(amount, reserve0, reserve1);
                rPeg = reserve0.add(amountIn);
            }

            
            if(appreciationMode == true && latestUpdatedPrice.add(appreciationRate) <= higherThreshold){
                latestUpdatedPrice = latestUpdatedPrice.add(appreciationRate);
                newAmount = (pegDenominator.mul(rPeg)).div(latestUpdatedPrice);
                uint updatePrice = (pegDenominator.mul(rPeg)).div(newAmount);
                if(updatePrice > higherThreshold){
                newAmount = (pegDenominator.mul(rPeg)).div(latestUpdatedPrice.sub(appreciationRate));
                }
            }
            pegReserve = rPeg;
            if(roofloor == true && rPeg >= lastPegReserve.mul(rThreshold)){
                latestUpdatedPrice = (latestUpdatedPrice.mul(pegRate)).div(pegDenominator);
                newAmount = (pegDenominator.mul(rPeg)).div(latestUpdatedPrice);
                lastPegReserve = rPeg;
            }

            if(newAmount > initialPairBalance){
                supplyAmount = newAmount.sub(initialPairBalance);
                uint reserveBal = (_balances[address(this)].balance).add(feeAmount);
                if(reserveBal > supplyAmount){
                    contractAmount = reserveBal.sub(supplyAmount);
                    uint withoutFee = supplyAmount.sub(feeAmount);
                    if(withoutFee > 0){
                     _balances[address(this)].balance = (_balances[address(this)].balance).sub(withoutFee);
                     emit Transfer(address(this), pairAddress, withoutFee);
                     }
                    _balances[pairAddress].balance = (_balances[pairAddress].balance).add(supplyAmount);
                }else{ 
                    mintAmount = supplyAmount.sub(reserveBal);
                    uint withoutFee = reserveBal.sub(feeAmount);
                    if(withoutFee > 0){
                        _balances[address(this)].balance = (_balances[address(this)].balance).sub(withoutFee);
                        emit Transfer(address(this), pairAddress, withoutFee);
                    }
                    _balances[pairAddress].balance = (_balances[pairAddress].balance).add(reserveBal);
                    if(mintAmount > 0){
                        _mint(pairAddress, mintAmount);
                    }

                }   
            }
        
           else{
                contractAmount = initialPairBalance.sub(newAmount);
                _balances[pairAddress].balance = (_balances[pairAddress].balance).sub(contractAmount);
                contractAmount = contractAmount.add(feeAmount);
            }

            if(contractAmount > 0){
              _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
              emit Transfer(pairAddress, address(this), contractAmount);
            }
        
        
            emit Tx(amount, newAmount, mintAmount, latestUpdatedPrice);
    }

    function _shouldUpgradePrice() public view returns(bool){
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
        if(appreciationMode == true){
            higherThreshold = newPrice.add(aAmount);
            lowerThreshold = newPrice.sub(aAmount);
        }
        
        return newPrice; 
    }

    function _addTokenHolder(address _holder) private {
        if(_holder != msg.sender){
            holderByIndex[_holder] = tokenHolders.length;
            tokenHolders.push(_holder);
        }
    }

    function _removeHolder(address _holder) private {
        tokenHolders[holderByIndex[_holder]] = tokenHolders[
            tokenHolders.length - 1
        ];
        tokenHolders.pop();
        delete Shares[_holder];
    }




    function shouldTakeFee(address sender, address receiver, bool isTransfer) public view returns (bool) {
         bool permission = !isFeeExempt[sender];
         if(sender == pairAddress && isFeeExempt[receiver]){
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

    function continualMultiplyInflation(uint _inflationRate, uint _targetReachingPeriod, uint _upgradingPeriod) public onlyManager{
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
        uint newAmount;
        uint contractAmount;
        if(_shouldUpgradePrice()){
            _upgradePrice();
        }
        uint initialpairBalance ;
        address tokenA = pair.token0();
        (uint reserve0, uint reserve1, ) = pair.getReserves();
        if(tokenA == address(this)){
             newAmount = (pegDenominator.mul(reserve1)).div(latestUpdatedPrice);
             initialpairBalance = reserve0;
        }else{
             newAmount = (pegDenominator.mul(reserve0)).div(latestUpdatedPrice);
             initialpairBalance = reserve1;
        }
        if(newAmount > initialpairBalance){
            uint mintAmount = newAmount.sub(initialpairBalance);
            _mint(address(this), mintAmount);
        }else{
            contractAmount = initialpairBalance.sub(newAmount);
            _balances[pairAddress].balance = (_balances[pairAddress].balance).sub(contractAmount);
            _balances[address(this)].balance = (_balances[address(this)].balance).add(contractAmount);
            emit Transfer(pairAddress, address(this), contractAmount);
        }
       pair.sync();
    }


    function upgradePegDenominator(uint _pegDenominator) external {
        require(_pegDenominator >= 10000);
        pegDenominator = _pegDenominator;
    }



                  ////////////// manuel peg unit ratio setter function \\\\\\\\\\\\\
    function _Recover(uint _basePrice) external {
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
        isPriceStable = true;
    }

 


    function stableMode(bool _switch) external onlyManager{
        isPriceStable = _switch;
        if(_switch == true){
            mode = 0;
            appreciationMode = true;
        }
    }
    
    function updateVesting(address[] calldata addressArray, bool _switch, uint[] calldata periodArray, uint[] calldata amountArray ) external onlyManager{
            require(addressArray.length == periodArray.length, "invalid Vesting periods");
            require(addressArray.length == amountArray.length, "invalid Vesting amounts");
            uint oneDay = 24*60*60;
                for(uint i = 0; i < addressArray.length ; i++){
                    if(addressArray[i] != address(0)){
                    if(_switch == true){
                        isAddedVesting[addressArray[i]].isvesting = true;
                        isAddedVesting[addressArray[i]].periodThresHold = periodArray[i].mul(10);
                        isAddedVesting[addressArray[i]].amountThresHold = amountArray[i].mul(oneDay);
                    }else{
                        isAddedVesting[addressArray[i]].isvesting =false;
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
        uint _taxFee,
        uint reflactionFee,
        bool _transferTax
    ) external onlyManager {
        taxFee = _taxFee;
        nativeReflactionFee = reflactionFee; 
        transferTax = _transferTax;
    }
    
    function setTresery(address _tresery, uint _treseryFee) external {
        treseryWallet = _tresery;
        tReflactionRate = _treseryFee;

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

    function _upgradeAppreciation(uint _upgrade, uint _txVol) internal onlyManager{
              higherThreshold = latestUpdatedPrice.add(_upgrade);
              lowerThreshold = latestUpdatedPrice.sub(_upgrade);
              uint distance = higherThreshold.sub(lowerThreshold);
              require(distance > _txVol);
              appreciationRate = distance.div(_txVol);
              txVolume = _txVol;
   }

   function upgradeAppreciation(uint _update,uint devident,  bool on) external onlyManager{
        if(on == true){
           _upgradeAppreciation(_update, devident);
           appreciationMode = true;
        }else{
            appreciationMode = false;
        }
   }

 
   
    function setPegToken(address _pegToken) external onlyManager{
        peg_token = _pegToken;
        if (IDEXFactory(router.factory()).getPair(_pegToken, address(this)) == address(0)) {
            pairAddress = IDEXFactory(router.factory()).createPair(_pegToken, address(this));
        }
       address _pairAddress = IDEXFactory(router.factory()).getPair(_pegToken, address(this)) ;
        pair = IDEXPair(_pairAddress);
        isRestrictedPair[_pairAddress] = true;
        isRestricted[_pairAddress] = true;
    }


    function setRouter(address _routerAdd) external onlyManager {
        routerAdd = _routerAdd;
        router = IDEXRouter(_routerAdd);
        if (IDEXFactory(router.factory()).getPair(peg_token, address(this)) == address(0)) {
            pairAddress = IDEXFactory(router.factory()).createPair(peg_token, address(this));
        }
        pair = IDEXPair(pairAddress);
        isFeeExempt[routerAdd] = true;
        _allowances[address(this)][routerAdd] = totalSupply;
    }

    function upgradeRestrictedPool(address _routerAddress, address[] calldata _tokenAdd, bool on) external onlyManager{
        IDEXRouter  _router = IDEXRouter(_routerAddress);
        for(uint i = 0 ; i < _tokenAdd.length ; i++){
            if (IDEXFactory(_router.factory()).getPair(_tokenAdd[i], address(this)) == address(0)) {
            IDEXFactory(_router.factory()).createPair(_tokenAdd[i], address(this));
        }
        address _pairAddress = IDEXFactory(_router.factory()).getPair(_tokenAdd[i], address(this));
        isRestrictedPair[_pairAddress] = on;
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

}