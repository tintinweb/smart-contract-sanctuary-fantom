/**
 *Submitted for verification at FtmScan.com on 2022-04-07
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

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
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface IPair {
    function sync() external;
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

contract LaserRoss is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_SUPPLY = type(uint128).max;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        100 * 10**9 * 10**DECIMALS;
    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private totalTokenSupply;

    function totalSupply() external view override returns (uint256) {
        return totalTokenSupply;
    }

    uint256 private gonsPerFragment;

    mapping(address => uint256) private gonBalance;
    mapping(address => mapping(address => uint256)) private allowedFragments;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = 0x0000000000000000000000000000000000000000;

    IDEXRouter public router;
    address public pair;

    mapping(address => bool) allowedTransferList;
    mapping(address => bool) feeExemptList;
    mapping(address => bool) blacklist;

    function setAllowTransfer(address _addr, bool _value) external onlyOwner {
        allowedTransferList[_addr] = _value;
    }

    function isAllowTransfer(address _addr) public view returns (bool) {
        return allowedTransferList[_addr];
    }

    function setFeeExempt(address _addr, bool _value) public onlyOwner {
        feeExemptList[_addr] = _value;
    }

    function isFeeExempt(address _addr) public view returns (bool) {
        return feeExemptList[_addr];
    }

    function setBlacklist(address _addr, bool _value) external onlyOwner {
        blacklist[_addr] = _value;
    }

    function isBlacklist(address _addr) public view returns (bool) {
        return blacklist[_addr];
    }

    constructor() ERC20Detailed("LaserRoss", "LSR", uint8(DECIMALS)) {
        router = IDEXRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        allowedFragments[address(this)][address(router)] = MAX_UINT256;

        totalTokenSupply = INITIAL_FRAGMENTS_SUPPLY;
        gonsPerFragment = TOTAL_GONS.div(INITIAL_FRAGMENTS_SUPPLY);
        gonBalance[msg.sender] = TOTAL_GONS;

        setFeeExempt(msg.sender, true);
        setFeeExempt(address(this), true);

        emit Transfer(address(0x0), msg.sender, totalTokenSupply);
    }

    // Fee actors
    address public buybackReceiver = 
        0x88A0352Ce526EB40f606Ff7b6793D68fC25Ba4AE;
    address public liquidityReceiver =
        0x4e5e1Ec8517D473b9DfD1EF376A7863e80078563;
    address public treasuryReceiver =
        0x04c28222D2C134e063e5b3387BF427703AaDfAF6;
    address public gamificationReceiver =
        0x82e293D9c5cEc1d7AA50A0d8D6F755d210AF305A;

    function setFeeReceivers(
        address _buybackReceiver,
        address _gamificationReceiver,
        address _liquidityReceiver,
        address _treasuryReceiver
    ) external onlyOwner {
        buybackReceiver = _buybackReceiver;
        gamificationReceiver = _gamificationReceiver;
        liquidityReceiver = _liquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
    }

    //Fee parameters
    uint256 private constant FEE_DENOMINATOR = 100;

    uint256 private constant MAX_TOTAL_BUY_FEE = 20;
    uint256 public buyBackBuyFee = 5;
    uint256 public liquidityBuyFee = 5;
    uint256 public treasuryBuyFee = 5;
    uint256 public gamificationBuyFee = 0;
    uint256 public totalBuyFee = 15;

    uint256 private constant MAX_TOTAL_SELL_FEE = 30;
    uint256 public buyBackSellFee = 6;
    uint256 public liquiditySellFee = 6;
    uint256 public treasurySellFee = 6;
    // The number of the beast
    uint256 public gamificationSellFee = 0;
    uint256 public totalSellFee = 18;

    function setBuyFees(
        uint256 _buybackFee,
        uint256 _gamificationFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        uint256 _totalFee = _buybackFee
            .add(_gamificationFee)
            .add(_liquidityFee)
            .add(_treasuryFee);
        require(
            _totalFee <= MAX_TOTAL_BUY_FEE,
            "Sum of buy fees exceed max value"
        );
        buyBackBuyFee = _buybackFee;
        gamificationBuyFee = _gamificationFee;
        liquidityBuyFee = _liquidityFee;
        treasuryBuyFee = _treasuryFee;
        totalBuyFee = _totalFee;
    }

    function setSellFees(
        uint256 _buybackFee,
        uint256 _gamificationFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee
    ) external onlyOwner {
        uint256 _totalFee = _buybackFee
            .add(_gamificationFee)
            .add(_liquidityFee)
            .add(_treasuryFee);
        require(
            _totalFee <= MAX_TOTAL_SELL_FEE,
            "Sum of sell fees exceed max value"
        );
        buyBackSellFee = _buybackFee;
        gamificationSellFee = _gamificationFee;
        liquiditySellFee = _liquidityFee;
        treasurySellFee = _treasuryFee;
        totalSellFee = _totalFee;
    }

    // Fee collection logic
    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal returns (uint256) {
        uint256 fee = totalBuyFee;
        if (recipient == pair) {
            fee = totalSellFee;
        }

        uint256 feeAmount = gonAmount.mul(fee).div(FEE_DENOMINATOR);

        gonBalance[address(this)] = gonBalance[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(gonsPerFragment));

        return gonAmount.sub(feeAmount);
    }

    // Fee collection parameters
    bool swapBackEnabled = true;
    bool liquidityEnabled = true;
    uint256 gonSwapThreshold = (TOTAL_GONS * 10) / 1000;

    function setSwapBackSettings(
        bool _swapBackEnabled,
        bool _liquidityEnabled,
        uint256 _num,
        uint256 _denom
    ) external onlyOwner {
        swapBackEnabled = _swapBackEnabled;
        liquidityEnabled = _liquidityEnabled;
        gonSwapThreshold = TOTAL_GONS.mul(_num).div(_denom);
    }

    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    // Fee distribution logic
    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            swapBackEnabled &&
            !inSwap &&
            gonBalance[address(this)] >= gonSwapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = gonBalance[address(this)].div(
            gonsPerFragment
        );

        uint256 totalFee = totalBuyFee.add(totalSellFee);

        uint256 buybackTransferAmount = contractTokenBalance
            .mul((buyBackBuyFee.add(buyBackSellFee)))
            .div(totalFee);
        if (buybackTransferAmount > 0) {
            _swapAndSend(buybackTransferAmount, buybackReceiver);
        }

        uint256 gamificationTransferAmount = contractTokenBalance
            .mul((gamificationBuyFee.add(gamificationSellFee)))
            .div(totalFee);
        if (gamificationTransferAmount > 0) {
            _swapAndSend(gamificationTransferAmount, gamificationReceiver);
        }

        uint256 dynamicLiquidityFee = liquidityEnabled
            ? liquidityBuyFee.add(liquiditySellFee)
            : 0;
        uint256 liquidityTransferAmount = contractTokenBalance
            .mul(dynamicLiquidityFee)
            .div(totalFee);
        if (liquidityTransferAmount > 0) {
            _addLiquidity(liquidityTransferAmount, liquidityReceiver);
        }

        uint256 treasuryTransferAmount = contractTokenBalance
            .mul((treasuryBuyFee.add(treasurySellFee)))
            .div(totalFee);
        if (treasuryTransferAmount > 0) {
            _swapAndSend(treasuryTransferAmount, treasuryReceiver);
        }

        emit SwapBack(
            contractTokenBalance,
            buybackTransferAmount,
            gamificationTransferAmount,
            liquidityTransferAmount,
            treasuryTransferAmount
        );
    }

    function _swapAndSend(uint256 _tokenAmount, address _receiver) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            _receiver,
            block.timestamp
        );
    }

    function _addLiquidity(uint256 _tokenAmount, address _receiver) private {
        uint256 coinBalance = address(this).balance;
        _swapAndSend(_tokenAmount.div(2), address(this));
        uint256 coinBalanceDifference = address(this).balance.sub(coinBalance);

        router.addLiquidityETH{value: coinBalanceDifference}(
            address(this),
            _tokenAmount.div(2),
            0,
            0,
            _receiver,
            block.timestamp
        );
    }

    // Rebase parameters and actors
    uint256 private constant REWARD_YIELD_DENOMINATOR = 10000000000;
    uint256 public rewardYield = 4189063;
    uint256 public rebaseFrequency = 1800;
    uint256 public nextRebase = block.timestamp + rebaseFrequency;

    function setRebaseParameters(
        uint256 _rewardYield,
        uint256 _rebaseFrequency,
        uint256 _nextRebase
    ) external onlyOwner {
        rewardYield = _rewardYield;
        rebaseFrequency = _rebaseFrequency;
        nextRebase = _nextRebase;
    }

    address public rebaseExecutor = 0xc1e79Bea7c15E434776a7C67361216b808650d78;

    function setRebaseExecutor(address _rebaseExecutor) external onlyOwner {
        rebaseExecutor = _rebaseExecutor;
    }

    modifier isExecutor() {
        require(msg.sender == rebaseExecutor);
        _;
    }

    function rebase(uint256 epoch, int256 supplyDelta) external onlyOwner {
        require(!inSwap, "Currently in swap, try again later.");
        _rebase(epoch, supplyDelta);
    }

    function executorRebase() external isExecutor {
        require(!inSwap, "Currently in swap, try again later.");

        uint256 epoch = block.timestamp;
        require(
            nextRebase <= block.timestamp,
            "Too soon since last automatic rebase."
        );

        int256 supplyDelta = int256(
            totalTokenSupply.mul(rewardYield).div(REWARD_YIELD_DENOMINATOR)
        );

        _rebase(epoch, supplyDelta);
    }

    function _rebase(uint256 epoch, int256 supplyDelta) private {
        if (supplyDelta < 0) {
            totalTokenSupply = totalTokenSupply.sub(uint256(-supplyDelta));
        } else {
            totalTokenSupply = totalTokenSupply.add(uint256(supplyDelta));
        }

        if (totalTokenSupply > MAX_SUPPLY) {
            totalTokenSupply = MAX_SUPPLY;
        }

        gonsPerFragment = TOTAL_GONS.div(totalTokenSupply);
        IPair(pair).sync();

        nextRebase = epoch + rebaseFrequency;

        emit LogRebase(epoch, totalTokenSupply);
    }

    // Approval and transfer logic
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowedFragments[owner][spender];
    }

    function balanceOf(address who) external view override returns (uint256) {
        return gonBalance[who].div(gonsPerFragment);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        allowedFragments[msg.sender][spender] = allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            allowedFragments[msg.sender][spender] = 0;
        } else {
            allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            allowedFragments[msg.sender][spender]
        );
        return true;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    function transfer(address to, uint256 amount)
        external
        override
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        return _transferFrom(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {
        if (allowedFragments[from][msg.sender] != MAX_UINT256) {
            allowedFragments[from][msg.sender] = allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        return _transferFrom(from, to, value);
    }

    function _transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (bool) {
        require(!isBlacklist(_sender), "Sender is blacklisted");
        require(!isBlacklist(_recipient), "Recipient is blacklisted");

        if (inSwap) {
            return _basicTransfer(_sender, _recipient, _amount);
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 _gonAmount = _amount.mul(gonsPerFragment);
        gonBalance[_sender] = gonBalance[_sender].sub(_gonAmount);

        uint256 _gonAmountReceived = (
            ((pair == _sender || pair == _recipient) && (!isFeeExempt(_sender)))
                ? takeFee(_sender, _recipient, _gonAmount)
                : _gonAmount
        );

        gonBalance[_recipient] = gonBalance[_recipient].add(_gonAmountReceived);
        emit Transfer(
            _sender,
            _recipient,
            _gonAmountReceived.div(gonsPerFragment)
        );
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(gonsPerFragment);
        gonBalance[from] = gonBalance[from].sub(gonAmount);
        gonBalance[to] = gonBalance[to].add(gonAmount);
        return true;
    }

    // Utilities
    function sendPresale(
        address[] calldata recipients,
        uint256[] calldata values
    ) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            _transferFrom(msg.sender, recipients[i], values[i]);
        }
    }

    bool initialDistributionFinished = false;

    modifier initialDistributionLock() {
        require(
            initialDistributionFinished ||
                isOwner() ||
                isAllowTransfer(msg.sender)
        );
        _;
    }

    function setInitialDistributionFinished() external onlyOwner {
        initialDistributionFinished = true;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return
            (TOTAL_GONS.sub(gonBalance[DEAD]).sub(gonBalance[ZERO])).div(
                gonsPerFragment
            );
    }

    function manualSync() external {
        IPair(pair).sync();
    }

    function isInSwap() external view returns (bool) {
        return inSwap;
    }

    function swapThreshold() external view returns (uint256) {
        return gonSwapThreshold.div(gonsPerFragment);
    }

    function rescueCoin(address _receiver, uint256 _amount) external onlyOwner {
        payable(_receiver).transfer(_amount);
    }

    function rescueToken(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        ERC20Detailed(_tokenAddress).transfer(msg.sender, _amount);
    }

    event SwapBack(
        uint256 contractTokenBalance,
        uint256 buybackTransferAmount,
        uint256 gamificationTransferAmount,
        uint256 liquidityTransferAmount,
        uint256 treasuryTransferAmount
    );
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
}