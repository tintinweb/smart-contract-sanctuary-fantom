/**
 *Submitted for verification at FtmScan.com on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Auth is Context{
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface InterfaceLP {
    function sync() external;
}

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract Test5 is ERC20Detailed, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    bool public initialDistributionFinished = false;
    bool public autoRebase = false;
    bool public feesOnNormalTransfers = false;
    bool public isLiquidityInFtm = true;
    bool public isRfvInFtm = true;
    bool public isLiquidityEnabled = true;

    uint256 public rewardYield = 1402777;
    uint256 public rebaseFrequency = 600;
    uint256 public nextRebase = block.timestamp + 31536000;
    uint256 public maxSellTransactionAmount = 2000000 * 10 ** 18;
    uint256 public swapThreshold = 400000 * 10**18;

    mapping(address => bool) _isFeeExempt;
    address[] private _makerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private constant REWARD_YIELD_DENOMINATOR = 10000000000;
    uint256 private constant MAX_TOTAL_BUY_FEE_RATE = 250;
    uint256 private constant MAX_TOTAL_SELL_FEE_RATE = 500;
    uint256 private constant FEE_DENOMINATOR = 1000;
    uint256 private constant MIN_MAX_SELL_AMOUNT = 1000 * 10**18;
    uint256 private constant MAX_REBASE_FREQUENCY = 1800;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 15 * 10**8 * 10**DECIMALS;
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;
    address public constant usdcToken = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    
    address public liquidityReceiver = 0x3ff8970f17d463b83D289827B7B8E5Eed61Cc3e8;
    address public treasuryReceiver = 0x3ff8970f17d463b83D289827B7B8E5Eed61Cc3e8;
    address public riskFreeValueReceiver = 0x14c02711A4678fc7De388e77e99B07753C856e84;
    address public xLiberoReceiver = 0x3ff8970f17d463b83D289827B7B8E5Eed61Cc3e8;

    IDEXRouter public router;
    address public pair;

    uint256 public liquidityFee = 40;
    uint256 public treasuryFee = 30;
    uint256 public buyFeeRFV = 50;
    uint256 public buyBurnFee = 20;
    uint256 public buyxLiberoFee = 20;
    uint256 public sellFeeTreasuryAdded = 20;
    uint256 public sellFeeRFVAdded = 40;
    uint256 public sellBurnFeeAdded = 0;
    uint256 public sellxLiberoFeeAdded = 30;
    uint256 public totalBuyFee = liquidityFee.add(treasuryFee).add(buyFeeRFV).add(buyBurnFee).add(buyxLiberoFee);
    uint256 public totalSellFee = totalBuyFee.add(sellFeeTreasuryAdded).add(sellFeeRFVAdded).add(sellBurnFeeAdded).add(sellxLiberoFeeAdded);

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    constructor() ERC20Detailed("Test5", "TEST5", uint8(DECIMALS)) Auth(msg.sender) {
        router = IDEXRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
        address pairUsdc = IDEXFactory(router.factory()).createPair(address(this), usdcToken);

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        _allowedFragments[address(this)][pair] = uint256(-1);
        _allowedFragments[address(this)][address(this)] = uint256(-1);
        _allowedFragments[address(this)][pairUsdc] = uint256(-1);

        setAutomatedMarketMakerPair(pair, true);
        setAutomatedMarketMakerPair(pairUsdc, true);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[riskFreeValueReceiver] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[msg.sender] = true;

        IERC20(usdcToken).approve(address(router), uint256(-1));
        IERC20(usdcToken).approve(address(pairUsdc), uint256(-1));
        IERC20(usdcToken).approve(address(this), uint256(-1));

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender) external view override returns (uint256){
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        if(_isFeeExempt[from] || _isFeeExempt[to]){
            return false;
        }else if (feesOnNormalTransfers){
            return true;
        }else{
            return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender] &&
        !inSwap &&
        swapThreshold > 0 &&
        totalBuyFee.add(totalSellFee) > 0 &&
        balanceOf(address(this)) >= swapThreshold;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(_gonsPerFragment);
    }

    function manualSync() public {
        for(uint i = 0; i < _makerPairs.length; i++){
            try InterfaceLP(_makerPairs[i]).sync() {

            }catch Error (string memory reason) {
                emit GenericErrorEvent("manualSync(): _makerPairs.sync() Failed");
                emit GenericErrorEvent(reason);
            }
        }
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool){
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function _basicTransfer(address from, address to, uint256 amount) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);

        emit Transfer(from, to, amount);

        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        bool excludedAccount = _isFeeExempt[sender] || _isFeeExempt[recipient];

        require(initialDistributionFinished || excludedAccount, "Trading not started");

        if (
            automatedMarketMakerPairs[recipient] &&
            !excludedAccount
        ) {
            require(amount <= maxSellTransactionAmount, "Error amount");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, gonAmount) : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(gonAmountReceived);

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );

        if(
            shouldRebase() &&
            autoRebase &&
            !automatedMarketMakerPairs[sender] &&
            !automatedMarketMakerPairs[recipient]
        ) {
            _rebase();
            manualSync();
        }

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
            ].sub(value, "Insufficient Allowance");
        }

        _transferFrom(from, to, value);
        return true;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        if(isLiquidityInFtm){
            uint256 initialBalance = address(this).balance;

            _swapTokensForFTM(half, address(this));

            uint256 newBalance = address(this).balance.sub(initialBalance);

            _addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
        }else{
            uint256 initialBalance = IERC20(usdcToken).balanceOf(address(this));

            _swapTokensForUsdc(half, address(this));

            uint256 newBalance = IERC20(usdcToken).balanceOf(address(this)).sub(initialBalance);

            addLiquidityUsdc(otherHalf, newBalance);

            emit SwapAndLiquifyUsdc(half, newBalance, otherHalf);
        }
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ftmAmount) private {
        router.addLiquidityETH{value: ftmAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }

    function addLiquidityUsdc(uint256 tokenAmount, uint256 usdcAmount) private {
        router.addLiquidity(
            address(this),
            usdcToken,
            tokenAmount,
            usdcAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }

    function _swapTokensForFTM(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }
    function _swapTokensForUsdc(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = router.WETH();
        path[2] = usdcToken;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function swapBack() internal swapping {
        uint256 realTotalFee = totalBuyFee.add(totalSellFee);

        uint256 dynamicLiquidityFee = isLiquidityEnabled ? liquidityFee : 0;
        uint256 contractTokenBalance = _gonBalances[address(this)].div(_gonsPerFragment);

        uint256 amountToLiquify = contractTokenBalance.mul(dynamicLiquidityFee.mul(2)).div(realTotalFee);
        uint256 amountToBurn = contractTokenBalance.mul(buyBurnFee.mul(2).add(sellBurnFeeAdded)).div(realTotalFee);
        uint256 amountToRFV = contractTokenBalance.mul(buyFeeRFV.mul(2).add(sellFeeRFVAdded)).div(realTotalFee);
        uint256 amountToxLibero = contractTokenBalance.mul(buyxLiberoFee.mul(2).add(sellxLiberoFeeAdded)).div(realTotalFee);
        uint256 amountToTreasury = contractTokenBalance.sub(amountToLiquify).sub(amountToBurn).sub(amountToRFV).sub(amountToxLibero);

        if(amountToLiquify > 0){
            _swapAndLiquify(amountToLiquify);
        }

        if(amountToBurn > 0){
            _basicTransfer(address(this), DEAD, amountToBurn);
        }

        if(amountToRFV > 0){
            if(isRfvInFtm){
                _swapTokensForFTM(amountToRFV, riskFreeValueReceiver);
            }else{
                _swapTokensForUsdc(amountToRFV, riskFreeValueReceiver);
            }
        }

        if(amountToxLibero > 0){
            _swapTokensForUsdc(amountToxLibero, xLiberoReceiver);
        }

        if(amountToTreasury > 0){
            _swapTokensForFTM(amountToTreasury, treasuryReceiver);
        }

        emit SwapBack(contractTokenBalance, amountToLiquify, amountToRFV, amountToTreasury);
    }

    function takeFee(address sender, address recipient, uint256 gonAmount) internal returns (uint256){
        uint256 _realFee = totalBuyFee;
        if(automatedMarketMakerPairs[recipient]) _realFee = totalSellFee;

        uint256 feeAmount = gonAmount.mul(_realFee).div(FEE_DENOMINATOR);

        _gonBalances[address(this)] = _gonBalances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool){
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
        spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool){
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function _rebase() private {
        if(!inSwap) {
            int256 supplyDelta = int256(_totalSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR));

            coreRebase(supplyDelta);
        }
    }

    function coreRebase(int256 supplyDelta) private returns (uint256) {
        uint256 epoch = block.timestamp;

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        nextRebase = epoch + rebaseFrequency;

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function manualRebase() external authorized{
        require(!inSwap, "Try again");
        require(nextRebase <= block.timestamp, "Not in time");

        int256 supplyDelta = int256(_totalSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR));

        coreRebase(supplyDelta);
        manualSync();
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

        automatedMarketMakerPairs[_pair] = _value;

        if(_value){
            _makerPairs.push(_pair);
        }else{
            require(_makerPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < _makerPairs.length; i++) {
                if (_makerPairs[i] == _pair) {
                    _makerPairs[i] = _makerPairs[_makerPairs.length - 1];
                    _makerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function setInitialDistributionFinished(bool _value) external onlyOwner {
        require(initialDistributionFinished != _value, "Not changed");
        initialDistributionFinished = _value;
    }

    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        require(_isFeeExempt[_addr] != _value, "Not changed");
        _isFeeExempt[_addr] = _value;
    }

    function setSwapThreshold(uint256 _value) external onlyOwner {
        require(swapThreshold != _value, "Not changed");
        swapThreshold = _value;
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _treasuryReceiver,
        address _riskFreeValueReceiver,
        address _xLiberoReceiver
    ) external onlyOwner {
        require(_liquidityReceiver != address(0), "Invalid _liquidityReceiver");
        require(_treasuryReceiver != address(0), "Invalid _treasuryReceiver");
        require(_riskFreeValueReceiver != address(0), "Invalid _riskFreeValueReceiver");
        require(_xLiberoReceiver != address(0), "Invalid _xLiberoReceiver");

        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        xLiberoReceiver = _xLiberoReceiver;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _riskFreeValue,
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _xLiberoFee,
        uint256 _sellFeeTreasuryAdded,
        uint256 _sellFeeRFVAdded,
        uint256 _sellBurnFeeAdded,
        uint256 _sellxLiberoFeeAdded
    ) external onlyOwner {
        liquidityFee = _liquidityFee;
        buyFeeRFV = _riskFreeValue;
        treasuryFee = _treasuryFee;
        buyBurnFee = _burnFee;
        buyxLiberoFee = _xLiberoFee;
        sellFeeTreasuryAdded = _sellFeeTreasuryAdded;
        sellFeeRFVAdded = _sellFeeRFVAdded;
        sellBurnFeeAdded = _sellBurnFeeAdded;
        sellxLiberoFeeAdded = _sellxLiberoFeeAdded;

        totalBuyFee = liquidityFee.add(treasuryFee).add(buyFeeRFV).add(buyBurnFee).add(buyxLiberoFee);
        totalSellFee = totalBuyFee.add(sellFeeTreasuryAdded).add(sellFeeRFVAdded).add(sellBurnFeeAdded).add(sellxLiberoFeeAdded);

        require(totalBuyFee < MAX_TOTAL_BUY_FEE_RATE, "Total buy fee too high");
        require(totalSellFee < MAX_TOTAL_SELL_FEE_RATE, "Total sell fee too high");
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
    }

    function rescueToken(address tokenAddress) external onlyOwner returns (bool success){
        require(tokenAddress != address(this),"Not allow recuse Libero");
        uint256 amount = ERC20Detailed(tokenAddress).balanceOf(address(this));
        return ERC20Detailed(tokenAddress).transfer(msg.sender, amount);
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        require(autoRebase != _autoRebase, "Not changed");
        autoRebase = _autoRebase;
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        require(_rebaseFrequency <= MAX_REBASE_FREQUENCY, "Too high");
        rebaseFrequency = _rebaseFrequency;
    }

    function setRewardYield(uint256 _rewardYield) external onlyOwner {
        require(rewardYield != _rewardYield, "Not changed");
        rewardYield = _rewardYield;
    }

    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        require(feesOnNormalTransfers != _enabled, "Not changed");
        feesOnNormalTransfers = _enabled;
    }

    function setIsLiquidityEnabled(bool _value) external onlyOwner {
        require(isLiquidityEnabled != _value, "Not changed");
        isLiquidityEnabled = _value;
    }

    function setIsLiquidityInFtm(bool _value) external onlyOwner {
        require(isLiquidityInFtm != _value, "Not changed");
        isLiquidityInFtm = _value;
    }

    function setIsRfvInFtm(bool _value) external onlyOwner {
        require(isRfvInFtm != _value, "Not changed");
        isRfvInFtm = _value;
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        nextRebase = _nextRebase;
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        require(_maxTxn >= MIN_MAX_SELL_AMOUNT, "Too small");
        maxSellTransactionAmount = _maxTxn;
    }

    event SwapBack(uint256 contractTokenBalance,uint256 amountToLiquify,uint256 amountToRFV,uint256 amountToTreasury);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ftmReceived, uint256 tokensIntoLiqudity);
    event SwapAndLiquifyUsdc(uint256 tokensSwapped, uint256 usdcReceived, uint256 tokensIntoLiqudity);
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GenericErrorEvent(string reason);
}