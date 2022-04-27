/**
 *Submitted for verification at FtmScan.com on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a), 'mul overflow');
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a),
            'sub overflow');
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a),
            'add overflow');
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256,
            'abs overflow');
        return a < 0 ? -a : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
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
        require(b != 0,
            'parameter 2 can not be 0');
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface InterfaceLP {
    function sync() external;
}

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), 'Roles: account already has role');
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), 'Roles: account does not have role');
        role.bearer[account] = false;
    }

    function has(Role storage role, address account)
    internal
    view
    returns (bool)
    {
        require(account != address(0), 'Roles: account is the zero address');
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IBalanceOfSphere {
    function balanceOfSphere(address _address) external view returns (uint256);
}

interface IPublicBalance {
    function balanceOf(address _address) external view returns (uint256);
}

interface ILiquidityProvider {
    function sync() external;
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Not owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),
            'Owner can not be 0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RooToken is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    bool public isLiquidityEnabled = true;
    bool public initialDistributionFinished = false;
    bool public swapEnabled = true;
    bool public autoRebase = false;
    bool public feesOnNormalTransfers = false;
    bool public isLiquidityInMatic = true;
    bool public isBurnEnabled = false;
    bool public isTaxBracketEnabled = false;
    bool public isStillLaunchPeriod = true;
    bool public taxNonMarketMaker = false;
    bool public isPartyOver = false;

    uint256 public rebaseIndex = 1 * 10**18;
    uint256 private oneEEighteen = 1 * 10**18;
    uint256 private secondsPerDay = 86400;
    uint256 public rewardYield = 4571079140000;
    uint256 private REWARD_YIELD_DENOMINATOR = 10000000000000000;
    uint256 public maxSellTransactionAmount = 2500000 * 10**18;
    uint256 public maxBuyTransactionAmount = 2500000 * 10**18;

    uint256 public rebaseFrequency = 1800;
    uint256 public nextRebase = block.timestamp + 31536000;
    uint256 public rebaseEpoch = 0;
    uint256 public taxBracketMultiplier = 5;

    mapping(address => bool) _isFeeExempt;
    address[] public _markerPairs;
    uint256 public _markerPairCount;
    address[] public subContracts;
    address[] public sphereGamesContracts;
    address[] public partyArray;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public subContractCheck;
    mapping(address => bool) public sphereGamesCheck;
    mapping(address => bool) public partyArrayCheck;

    uint256 private constant MAX_FEE_RATE = 30;
    uint256 private constant MAX_TAX_BRACKET_FEE_RATE = 5;
    uint256 private constant MAX_PARTY_LIST_DIVISOR_RATE = 75;
    uint256 private constant NON_MARKET_MAKER_FEE_RATE = 5;
    uint256 private constant MIN_SELL_AMOUNT_RATE = 1500000 * 10**18;
    uint256 private constant MIN_BUY_AMOUNT_RATE = 1500000 * 10**18;
    uint256 private constant MAX_REBASE_FREQUENCY = 1800;
    uint256 private constant feeDenominator = 100;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
    145833333 * 10**DECIMALS;
    uint256 private constant TOTAL_GONS =
    MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = ~uint128(0);

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    address public liquidityReceiver =
    0xCBe773C84DF9fECC21e02ef8994be7eF9CEBF480;
    address public treasuryReceiver =
    0xaFAcebD472bBf82bBf61885AD70c6Bd9365AE078;
    address public riskFreeValueReceiver =
    0xDA04ad63Ece6c720974C6D51ec96d1186dA7522b;
    address private rebaser;
    address private manager;

    IDEXRouter public router;
    IDEXFactory public factory;
    address public pair;

    uint256 private constant maxBracketTax = 10; // max bracket is holding 10%

    uint256 public liquidityFee = 5;
    uint256 public treasuryFee = 4;
    uint256 public burnFee = 0;
    uint256 public sellBurnFee = 0;
    uint256 public buyFeeRFV = 4;
    uint256 public sellFeeTreasuryAdded = 5;
    uint256 public sellFeeRFVAdded = 2;
    uint256 public sellLaunchFeeAdded = 0;
    uint256 public sellLaunchFeeSubtracted = 0;
    uint256 public partyListDivisor = 50;
    uint256 public totalBuyFee = liquidityFee.add(treasuryFee).add(buyFeeRFV);
    uint256 public totalSellFee =
    totalBuyFee.add(sellFeeTreasuryAdded).add(sellFeeRFVAdded).add(
        sellLaunchFeeAdded
    );
    uint256 targetLiquidity = 50;
    uint256 targetLiquidityDenominator = 100;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0),
            'recipient is not valid');
        _;
    }

    modifier onlyManager() {
        require(msg.sender == rebaser || msg.sender == manager, "Caller is not authorised!");
        _;
    }

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    uint256 private gonSwapThreshold = (TOTAL_GONS * 10) / 10000;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    constructor() ERC20Detailed('Tout Finance', 'TROO', uint8(DECIMALS)) {
        router = IDEXRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        pair = IDEXFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        _allowedFragments[address(this)][pair] = uint256(-1);
        _allowedFragments[address(this)][address(this)] = uint256(-1);

        setAutomatedMarketMakerPair(pair, true);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[riskFreeValueReceiver] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[msg.sender] = true;

        rebaser = msg.sender;
        manager = msg.sender;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender)
    external
    view
    override
    returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function markerPairAddress(uint256 value) public view returns (address) {
        return _markerPairs[value];
    }

    function currentIndex() public view returns (uint256) {
        return rebaseIndex;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(_gonsPerFragment);
    }

    function shouldRebase() internal view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function shouldBurn() internal view returns (bool) {
        return isBurnEnabled;
    }

    function isStillLaunchPhase() internal view returns (bool) {
        return isStillLaunchPeriod;
    }

    function isTaxBracket() internal view returns (bool) {
        return isTaxBracketEnabled;
    }

    function shouldTakeFee(address from, address to)
    internal
    view
    returns (bool)
    {
        if (_isFeeExempt[from] || _isFeeExempt[to]) {
            return false;
        } else if (feesOnNormalTransfers) {
            return true;
        } else {
            return (automatedMarketMakerPairs[from] ||
            automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender] &&
        !inSwap &&
        swapEnabled &&
        totalBuyFee.add(totalSellFee) > 0 &&
        _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function getGonBalances() public view returns (bool thresholdReturn, uint256 gonBalanceReturn ) {
        thresholdReturn  = _gonBalances[address(this)] >= gonSwapThreshold;
        gonBalanceReturn = _gonBalances[address(this)];

    }

    function getCirculatingSupply() public view returns (uint256) {
        return
        (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
            _gonsPerFragment
        );
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }


    function getUserTotalOnDifferentContractsSphere(address sender)
    public
    view
    returns (uint256)
    {
        uint256 userTotal = balanceOf(sender);
        uint256 balanceOfAllSubContracts;
        uint256 balanceOfAllSphereGamesContracts;

        //calculate the balance of different contracts on different wallets and sum them
        balanceOfAllSubContracts = getBalanceOfAllSubContracts(sender);
        balanceOfAllSphereGamesContracts = getBalanceOfAllSphereGamesContracts(
            sender
        );

        userTotal.add(balanceOfAllSubContracts).add(
            balanceOfAllSphereGamesContracts
        );
        return userTotal;
    }

    //this function iterates through all other contracts that are being part of the Sphere ecosystem
    //we add a new contract like wSPHERE or sSPHERE, whales could technically abuse this
    //by swapping to these contracts and leave the dynamic tax bracket
    function getBalanceOfAllSubContracts(address sender)
    public
    view
    returns (uint256)
    {
        uint256 userTotal;

        for (uint256 i = 0; i < subContracts.length; i++) {
            userTotal += IBalanceOfSphere(subContracts[i]).balanceOfSphere(
                sender
            );
        }

        return userTotal;
    }

    //get S.P.H.E.R.E. Games Tickets Count For Tax
    function getBalanceOfAllSphereGamesContracts(address sender)
    public
    view
    returns (uint256)
    {
        uint256 sphereGamesTotal;

        for (uint256 i = 0; i < sphereGamesContracts.length; i++) {
            sphereGamesTotal += IPublicBalance(sphereGamesContracts[i])
            .balanceOf(sender);
        }

        return sphereGamesTotal;
    }

    function getTokensInLPCirculation() public view returns (uint256) {
        uint256 LPTotal;

        for (uint256 i = 0; i < _markerPairs.length; i++) {
            LPTotal += balanceOf(_markerPairs[i]);
        }

        return LPTotal;
    }

    function getCurrentTaxBracket(address _address)
    public
    view
    returns (uint256)
    {
        //gets the total balance of the user
        uint256 userTotal = getUserTotalOnDifferentContractsSphere(_address);

        //calculate the percentage
        uint256 totalCap = userTotal.mul(100).div(getTokensInLPCirculation());

        //calculate what is smaller, and use that
        uint256 _bracket = SafeMath.min(totalCap, maxBracketTax);

        //multiply the bracket with the multiplier
        _bracket *= taxBracketMultiplier;

        return _bracket;
    }


    function manualSync() public {
        for (uint256 i = 0; i < _markerPairs.length; i++) {
            ILiquidityProvider(_markerPairs[i]).sync();
        }
    }

    function transfer(address to, uint256 value)
    external
    override
    validRecipient(to)
    returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);

        emit Transfer(from, to, amount);

        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        bool excludedAccount = _isFeeExempt[sender] || _isFeeExempt[recipient];

        require(
            initialDistributionFinished || excludedAccount,
            'Trading not started'
        );

        if (automatedMarketMakerPairs[recipient] && !excludedAccount) {
            require(amount <= maxSellTransactionAmount, 'Error amount');
        }

        if (automatedMarketMakerPairs[sender] && !excludedAccount) {
            require(amount <= maxBuyTransactionAmount, 'Buy Amount Exceeded!');
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);

        if (shouldSwapBack()) {
            swapBack();
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
        ? takeFee(sender, recipient, gonAmount)
        : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );

        if (shouldRebase() && autoRebase) {
            _rebase();
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
            ].sub(value, 'Insufficient Allowance');
        }

        _transferFrom(from, to, value);
        return true;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

      
        uint256 initialBalance = address(this).balance;

        _swapTokensForMATIC(half, address(this));

        uint256 newBalance = address(this).balance.sub(initialBalance);

        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
        
    }

    function _addLiquidity(uint256 tokenAmount, uint256 MATICAmount) private {
        router.addLiquidityETH{value: MATICAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityReceiver,
            block.timestamp
        );
    }

    function _swapTokensForMATIC(uint256 tokenAmount, address receiver)
    private
    {
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

    function swapBack() internal swapping {
        uint256 realTotalFee = totalBuyFee.add(totalSellFee);

        uint256 dynamicLiquidityFee = isLiquidityEnabled ? liquidityFee : 0;

        uint256 contractTokenBalance = _gonBalances[address(this)].div(
            _gonsPerFragment
        );

        uint256 amountToLiquify = contractTokenBalance
        .mul(dynamicLiquidityFee.mul(2))
        .div(realTotalFee);

        uint256 amountToRFV = contractTokenBalance
        .mul(buyFeeRFV.mul(2).add(sellFeeRFVAdded))
        .div(realTotalFee);

        uint256 amountToTreasury = contractTokenBalance
        .sub(amountToLiquify)
        .sub(amountToRFV);

        if (amountToLiquify > 0) {
            _swapAndLiquify(amountToLiquify);
        }

        if (amountToRFV > 0) {
            _swapTokensForMATIC(amountToRFV, riskFreeValueReceiver);
        }

        if (amountToTreasury > 0) {
            _swapTokensForMATIC(amountToTreasury, treasuryReceiver);
        }

        emit SwapBack(
            contractTokenBalance,
            amountToLiquify,
            amountToRFV,
            amountToTreasury
        );
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function setIsLiquidityEnabled(bool _value) external onlyOwner {
        isLiquidityEnabled = _value;
        emit SetIsLiquidityEnabled(_value);
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 _realFee = totalBuyFee;
        uint256 _burnFee = burnFee;

        //check if it's a sell fee embedded
        if (automatedMarketMakerPairs[recipient]) {
            _realFee = totalSellFee;
            _burnFee = _burnFee.add(sellBurnFee);
        }

        //calculate Tax
        if (isTaxBracketEnabled) {
            _realFee += getCurrentTaxBracket(sender);
        }

        //trying to join our party? Become the party maker :)
        if ((partyArrayCheck[sender] || partyArrayCheck[recipient])) {
            if (_realFee < 49) _realFee = 49;
        }

        uint256 feeAmount = gonAmount.mul(_realFee).div(feeDenominator);

        //make sure Burn is enabled and burnFee is > 0 (integer 0 equals to false)
        if (shouldBurn() && _burnFee > 0) {
            // burn the amount given % every transaction
            tokenBurner(
                (gonAmount.div(_gonsPerFragment)).mul(_burnFee).div(100)
            );
        }

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            feeAmount
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    function tokenBurner(uint256 _tokenAmount) private {
        _transferFrom(address(this), address(DEAD), _tokenAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool)
    {
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

    function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool)
    {
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

    function approve(address spender, uint256 value)
    external
    override
    returns (bool)
    {

        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    //rebase on total supply
    function _rebase() private {
        if (!inSwap) {
                int256 supplyDelta = int256(_totalSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR));
                coreRebase(supplyDelta);
                emit LogManualRebase(supplyDelta, nextRebase);
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

        updateRebaseIndex();
        
        if (isStillLaunchPhase()) {
            updateLaunchPeriodFee();
        }
      
        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
        
    }

    function manualRebase() external onlyManager {
        require(!inSwap, 'Try again');
        require(nextRebase <= block.timestamp, 'Not in time');
        int256 supplyDelta;
        int i = 0;

        do {
            supplyDelta = int256(_totalSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR));
            coreRebase(supplyDelta);
            emit LogManualRebase(supplyDelta, block.timestamp);
            i++;
        }
        while (nextRebase < block.timestamp && i < 100);

        manualSync();
    }

    function updateRebaseIndex() private {
        // update the next Rebase time
        nextRebase += rebaseFrequency;

        //update Index similarly to OHM, so a wrapped token created is possible (wSPHERE)

        //formula: rebaseIndex * (1 * 10 ** 18 + ((1 * 10 ** 18) + rewardYield / rewardYieldDenominator)) / 1 * 10 ** 18
        rebaseIndex = rebaseIndex
        .mul(
            oneEEighteen.add(
                oneEEighteen.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR)
            )
        )
        .div(oneEEighteen);

        //simply show how often we rebased since inception (how many epochs)
        rebaseEpoch += 1;
    }

    //create a dynamic decrease of sell launch fees within first 5 days (immutable)
    function updateLaunchPeriodFee() private {
        //thanks to integer, if rebaseEpoch is > rebase frequency (30 minutes), sellLaunchFeeSubtracted goes to 1 (48 rebases everyday)
        //the calculation should always round down to the lowest fee deduction every day
        //this calculates how often the rebase frequency is (maximum of 48) - every 30 minutes, so 24 hours / rebase frequency
        uint256 _sellLaunchFeeSubtracted = rebaseEpoch.div(
            secondsPerDay.div(rebaseFrequency)
        );

        //multiply by 2 to remove 5% everyday
        sellLaunchFeeSubtracted = _sellLaunchFeeSubtracted.mul(5);

        //if the sellLaunchFeeSubtracted epochs have exceeded or are same as the sellLaunchFeeAdded, set the sellLaunchFeeAdded to 0 (false)
        if (sellLaunchFeeAdded <= sellLaunchFeeSubtracted) {
            isStillLaunchPeriod = false;
            sellLaunchFeeSubtracted = sellLaunchFeeAdded;
        }

        //set the sellFee
        setSellFee(
            totalBuyFee
            .add(sellFeeTreasuryAdded)
            .add(sellFeeRFVAdded)
            .add(sellBurnFee)
            .add(sellLaunchFeeAdded - sellLaunchFeeSubtracted)
        );
    }

    //add new subcontracts to the protocol so they can be calculated
    function addSubContracts(address _subContract, bool _value)
    public
    onlyOwner
    {
        require(subContractCheck[_subContract] != _value, 'Value already set');

        subContractCheck[_subContract] = _value;

        if (_value) {
            subContracts.push(_subContract);
        } else {
            for (uint256 i = 0; i < subContracts.length; i++) {
                if (subContracts[i] == _subContract) {
                    subContracts[i] = subContracts[subContracts.length - 1];
                    subContracts.pop();
                    break;
                }
            }
        }

        emit SetSubContracts(_subContract, _value);
    }

    //Add S.P.H.E.R.E. Games Contracts
    function addSphereGamesAddies(address _sphereGamesAddy, bool _value)
    public 
    onlyOwner
    {
        require(
            sphereGamesCheck[_sphereGamesAddy] != _value,
            'Value already set'
        );

        sphereGamesCheck[_sphereGamesAddy] = _value;

        if (_value) {
            sphereGamesContracts.push(_sphereGamesAddy);
        } else {
            require(sphereGamesContracts.length > 1, 'Required 1 pair');
            for (uint256 i = 0; i < sphereGamesContracts.length; i++) {
                if (sphereGamesContracts[i] == _sphereGamesAddy) {
                    sphereGamesContracts[i] = sphereGamesContracts[
                    sphereGamesContracts.length - 1
                    ];
                    sphereGamesContracts.pop();
                    break;
                }
            }
        }

        emit SetSphereGamesAddresses(_sphereGamesAddy, _value);
    }

    function addPartyAddies(address _partyAddy, bool _value) public onlyOwner {
        require(partyArrayCheck[_partyAddy] != _value, 'Value already set');

        partyArrayCheck[_partyAddy] = _value;

        if (_value) {
            partyArray.push(_partyAddy);
        } else {
            for (uint256 i = 0; i < partyArray.length; i++) {
                if (partyArray[i] == _partyAddy) {
                    partyArray[i] = partyArray[partyArray.length - 1];
                    partyArray.pop();
                    break;
                }
            }
        }

        emit SetPartyAddresses(_partyAddy, _value);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value)
    public
    onlyOwner
    {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            'Value already set'
        );

        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            _markerPairs.push(_pair);
            _markerPairCount++;
        } else {
            require(_markerPairs.length > 1, 'Required 1 pair');
            for (uint256 i = 0; i < _markerPairs.length; i++) {
                if (_markerPairs[i] == _pair) {
                    _markerPairs[i] = _markerPairs[_markerPairs.length - 1];
                    _markerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function setInitialDistributionFinished(bool _value) external onlyOwner {
        require(initialDistributionFinished != _value, 'Not changed');
        initialDistributionFinished = _value;

        emit SetInitialDistribution(_value);
    }

    function setPartyListDivisor(uint256 _value) external onlyOwner {
        require(partyListDivisor != _value, 'Not changed');
        require(
            _value <= MAX_PARTY_LIST_DIVISOR_RATE,
            'max party divisor amount'
        );
        partyListDivisor = _value;

        emit SetPartyListDivisor(_value);
    }

    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        require(_isFeeExempt[_addr] != _value, 'Not changed');
        _isFeeExempt[_addr] = _value;

        emit SetFeeExempt(_addr, _value);
    }

    function setTaxNonMarketMaker(bool _value) external onlyOwner {
        require(taxNonMarketMaker != _value, 'Not changed');
        taxNonMarketMaker = _value;
        emit TaxNonMarketMakerSet(_value, block.timestamp);
    }

    function setTargetLiquidity(uint256 target, uint256 accuracy)
    external
    onlyOwner
    {
        targetLiquidity = target;
        targetLiquidityDenominator = accuracy;
        emit SetTargetLiquidity(target, accuracy);
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapEnabled = _enabled;
        gonSwapThreshold = TOTAL_GONS.mul(_num).div(_denom);
        emit SetSwapBackSettings(_enabled, _num, _denom);
    }

    function setFeeReceivers(
        address _liquidityReceiver,
        address _treasuryReceiver,
        address _riskFreeValueReceiver
    ) external onlyOwner {
        require(_liquidityReceiver != address(0), '_liquidityReceiver not set');
        require(_treasuryReceiver != address(0), '_treasuryReceiver not set');
        require(
            _riskFreeValueReceiver != address(0),
            '_riskFreeValueReceiver not set'
        );
        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        riskFreeValueReceiver = _riskFreeValueReceiver;
        emit SetFeeReceivers(_liquidityReceiver, _treasuryReceiver, _riskFreeValueReceiver);
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _riskFreeValue,
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _sellFeeTreasuryAdded,
        uint256 _sellFeeRFVAdded,
        uint256 _sellBurnFee
    ) external onlyOwner {

        uint256 maxTotalBuyFee = _liquidityFee.add(_treasuryFee).add(
            _riskFreeValue
        );

        uint256 maxTotalSellFee = maxTotalBuyFee.add(_sellFeeTreasuryAdded).add(
            _sellFeeRFVAdded
        );

        require(
            _liquidityFee <= MAX_FEE_RATE &&
            _riskFreeValue <= MAX_FEE_RATE &&
            _treasuryFee <= MAX_FEE_RATE &&
            _sellFeeTreasuryAdded <= MAX_FEE_RATE &&
            _sellFeeRFVAdded <= MAX_FEE_RATE,
            'set fee higher than max fee allowing'
        );

        require(maxTotalBuyFee < MAX_FEE_RATE, 'exceeded max buy fees');

        require(maxTotalSellFee < MAX_FEE_RATE, 'exceeded max sell fees');

        liquidityFee = _liquidityFee;
        buyFeeRFV = _riskFreeValue;
        treasuryFee = _treasuryFee;
        sellFeeTreasuryAdded = _sellFeeTreasuryAdded;
        sellFeeRFVAdded = _sellFeeRFVAdded;
        burnFee = _burnFee;
        sellBurnFee = _sellBurnFee;
        totalBuyFee = liquidityFee.add(treasuryFee).add(buyFeeRFV);

        setSellFee(
            totalBuyFee.add(sellFeeTreasuryAdded).add(sellFeeRFVAdded).add(
                sellLaunchFeeAdded - sellLaunchFeeSubtracted
            )
        );

        emit SetFees(_liquidityFee, _riskFreeValue, _treasuryFee, _sellFeeTreasuryAdded, _sellFeeRFVAdded, _burnFee, sellBurnFee, totalBuyFee);
    }

    function setSellFee(uint256 _sellFee) internal {
        totalSellFee = _sellFee;
    }

    function setRouterPair(address _router, address _pair) external onlyOwner {
        require(_router != address(0x0), 'can not use 0x0 address');
        require(_pair != address(0x0), 'can not use 0x0 address');

        router = IDEXRouter(_router);
        pair = _pair;

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        _allowedFragments[address(this)][pair] = uint256(-1);

        setAutomatedMarketMakerPair(pair, true);
    }

    function setPartyIsOver() external onlyOwner {
        isPartyOver = true;
        emit SetPartyIsOver(true, block.timestamp);
    }

    function setTaxBracketFeeMultiplier(uint256 _taxBracketFeeMultiplier)
    external
    onlyOwner
    {
        require(
            _taxBracketFeeMultiplier <= MAX_TAX_BRACKET_FEE_RATE,
            'max bracket fee exceeded'
        );
        taxBracketMultiplier = _taxBracketFeeMultiplier;
        emit SetTaxBracketFeeMultiplier(_taxBracketFeeMultiplier, block.timestamp);
    }

    function clearStuckBalance(address _receiver) external onlyOwner {
        require(_receiver != address(0x0), 'invalid address');
        uint256 balance = address(this).balance;
        payable(_receiver).transfer(balance);
        emit ClearStuckBalance(balance, _receiver, block.timestamp);

    }

    function rescueToken(address tokenAddress, uint256 tokens)
    external
    onlyOwner
    returns (bool success)
    {
        emit RescueToken(tokenAddress, msg.sender, tokens, block.timestamp);
        return ERC20Detailed(tokenAddress).transfer(msg.sender, tokens);
    }

    function setAutoRebase(bool _autoRebase) external onlyOwner {
        require(autoRebase != _autoRebase, 'Not changed');
        autoRebase = _autoRebase;
        emit SetAutoRebase(_autoRebase, block.timestamp);
    }

    //enable burn fee if necessary
    function setBurnFee(bool _isBurnEnabled) external onlyOwner {
        require(
            isBurnEnabled != _isBurnEnabled,
            "Burn function hasn't changed"
        );
        isBurnEnabled = _isBurnEnabled;
        emit SetBurnFee(_isBurnEnabled, block.timestamp);
    }

    //disable launch fee so calculations are not necessarily made
    function setLaunchPeriod(bool _isStillLaunchPeriod) external onlyOwner {
        require(
            isStillLaunchPeriod != _isStillLaunchPeriod,
            "Launch function hasn't changed"
        );
        require(isStillLaunchPeriod, 'launch period already over');
        isStillLaunchPeriod = _isStillLaunchPeriod;
        emit SetLaunchPeriod(_isStillLaunchPeriod, block.timestamp);
    }

    //enable burn fee if necessary
    function setTaxBracket(bool _isTaxBracketEnabled) external onlyOwner {
        require(
            isTaxBracketEnabled != _isTaxBracketEnabled,
            "Tax Bracket function hasn't changed"
        );
        isTaxBracketEnabled = _isTaxBracketEnabled;
        emit SetTaxBracket(_isTaxBracketEnabled, block.timestamp);
    }

    function setRebaseFrequency(uint256 _rebaseFrequency) external onlyOwner {
        require(_rebaseFrequency <= MAX_REBASE_FREQUENCY, 'Too high');
        rebaseFrequency = _rebaseFrequency;
        emit SetRebaseFrequency(_rebaseFrequency, block.timestamp);
    }

    function setRewardYield(
        uint256 _rewardYield,
        uint256 _rewardYieldDenominator
    ) external onlyOwner {
        rewardYield = _rewardYield;
        REWARD_YIELD_DENOMINATOR = _rewardYieldDenominator;
        emit SetRewardYield(_rewardYield, _rewardYieldDenominator, block.timestamp);
    }

    function setFeesOnNormalTransfers(bool _enabled) external onlyOwner {
        require(feesOnNormalTransfers != _enabled, 'Not changed');
        feesOnNormalTransfers = _enabled;
        emit SetFeesOnNormalTransfers(_enabled, block.timestamp);
    }

    function setIsLiquidityInMATIC(bool _value) external onlyOwner {
        require(isLiquidityInMatic != _value, 'Not changed');
        isLiquidityInMatic = _value;
        emit SetIsLiquidityInMATIC(_value, block.timestamp);
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        require(
            _nextRebase > block.timestamp,
            'Next rebase can not be in the past'
        );
        nextRebase = _nextRebase;
        emit SetNextRebase(_nextRebase, block.timestamp);
    }

    function setMaxSellTransaction(uint256 _maxTxn) external onlyOwner {
        require(_maxTxn > MIN_SELL_AMOUNT_RATE, 'Below minimum sell amount');
        maxSellTransactionAmount = _maxTxn;
        emit SetMaxSellTransaction(_maxTxn, block.timestamp);
    }

    function setMaxBuyTransactionAmount(uint256 _maxTxn) external onlyOwner {
        require(_maxTxn > MIN_BUY_AMOUNT_RATE, 'Below minimum buy amount');
        maxBuyTransactionAmount = _maxTxn;
        emit SetMaxBuyTransactionAmount(_maxTxn, block.timestamp);
    }

    function changeRebaser(address _rebaser) external onlyOwner {
        require(_rebaser != address(0), 'rebaser not set');
        rebaser = _rebaser;
    }

    function changeManager(address _manager) external onlyOwner {
        require(_manager != address(0), 'manager not set');
        manager = _manager;
    }

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 amountToLiquify,
        uint256 amountToRFV,
        uint256 amountToTreasury
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 MATICReceived,
        uint256 tokensIntoLiqudity
    );

    event SetFeeReceivers(
        address indexed _liquidityReceiver,
        address indexed _treasuryReceiver,
        address indexed _riskFreeValueReceiver
    );

    event SetPartyIsOver(
        bool indexed state,
        uint256 indexed time
    );

    event SetTaxBracketFeeMultiplier(
        uint256 indexed state,
        uint256 indexed time
    );

    event ClearStuckBalance(
        uint256 indexed amount,
        address indexed receiver,
        uint256 indexed time
    );

    event RescueToken(
        address indexed tokenAddress,
        address indexed sender,
        uint256 indexed tokens,
        uint256 time
    );

    event SetAutoRebase(
        bool indexed value,
        uint256 indexed time
    );

    event SetLaunchPeriod(
        bool indexed value,
        uint256 indexed time
    );

    event SetTaxBracket(
        bool indexed value,
        uint256 indexed time
    );

    event SetRebaseFrequency(
        uint256 indexed frequency,
        uint256 indexed time
    );

    event SetRewardYield(
        uint256 indexed rewardYield,
        uint256 indexed frequency,
        uint256 indexed time
    );

    event SetFeesOnNormalTransfers(
        bool indexed value,
        uint256 indexed time
    );

    event SetIsLiquidityInMATIC(
        bool indexed value,
        uint256 indexed time
    );

    event SetNextRebase(
        uint256 indexed value,
        uint256 indexed time
    );

    event SetMaxSellTransaction(
        uint256 indexed value,
        uint256 indexed time
    );

    event SetMaxBuyTransactionAmount(
        uint256 indexed value,
        uint256 indexed time
    );

    event SetBurnFee(
        bool indexed value,
        uint256 indexed time
    );

    event SetSwapBackSettings(
        bool indexed enabled,
        uint256 indexed num,
        uint256 indexed denum
    );

    event MainLPAddressSet(address mainLP, uint256 time);

    event TaxNonMarketMakerSet(bool value, uint256 time);
    event SetTargetLiquidity(uint256 indexed target, uint256 indexed accuracy);


    event Main(bool enabled, uint256 time);

    event SetFees(
        uint256 indexed _liquidityFee,
        uint256 indexed _riskFreeValue,
        uint256 indexed _treasuryFee,
        uint256 _sellFeeTreasuryAdded,
        uint256 _sellFeeRFVAdded,
        uint256 _burnFee,
        uint256 sellBurnFee,
        uint256 totalBuyFee
    );

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event LogManualRebase(int256 supplyDelta, uint256 timeStamp);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SetInitialDistribution(bool indexed value);
    event SetPartyListDivisor(uint256 indexed value);
    event SetFeeExempt(address indexed addy, bool indexed value);
    event SetSubContracts(address indexed pair, bool indexed value);
    event SetPartyAddresses(address indexed pair, bool indexed value);
    event SetSphereGamesAddresses(address indexed pair, bool indexed value);
    event SetIsLiquidityEnabled(bool indexed value);
}