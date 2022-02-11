/**
 *Submitted for verification at FtmScan.com on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
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

interface IBEP20 {
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

contract CreditDistributor {

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external {}

    function setShare(address shareholder, uint256 amount) external {}

    function deposit() external payable {}

    function getOwner() external view returns (address) {}

    function process(uint256 gas) external {}
}

contract CreditReplicator is IBEP20 {
    using SafeMath for uint256;

    uint256 public constant MASK = type(uint128).max;
    address public WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Credit Replicator";
    string constant _symbol = "creditrep";
    uint8 constant _decimals = 6;

    uint256 _totalSupply = 1_000_000_000_000_000 * (10 ** _decimals);
    uint256 public _maxTxAmount = _totalSupply.div(100); // 1%
    uint256 public _maxWallet = _totalSupply.div(40); // 2.5%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isDividendProcessorExempt;
    mapping (address => bool) isMaxWalletExempt;

    uint256 liquidityFee = 200;
    uint256 reflectionFee = 800;
    uint256 marketingFee = 800;
    uint256 marketingFeePercent = 6;
    uint256 reflectionFeePercent = 4;
    uint256 feePercentageMultiplyer = 10;
    uint256 totalFeeSell = 1800;
    uint256 totalFeeBuy = 500;
    uint256 feeDenominator = 10000;

    address public marketingFeeReceiver= 0xf2ea250668446B072c4fd3CBCee79F7d56577eaD; // marketing address 

    IUniswapV2Router public router;
    address public pair;

    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    address internal owner;
    mapping (address => bool) internal authorizations;

    CreditDistributor distributor;

    uint256 distributorGas = 500000;

    constructor (address distributorAddress) {
        address _router = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

        owner = msg.sender;
        authorizations[msg.sender] = true;
        
        distributor = CreditDistributor(distributorAddress);
        router = IUniswapV2Router(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(WFTM, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        WFTM = router.WETH();
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[pair] = true;
        isFeeExempt[_router] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;        
        isTxLimitExempt[_router] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[_router] = true;

        isMaxWalletExempt[msg.sender] = true;
        isMaxWalletExempt[pair] = true;        
        isMaxWalletExempt[_router] = true;
        
        isDividendProcessorExempt[msg.sender] = true;
        isDividendProcessorExempt[_router] = true;

        approve(_router, _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyApproved() {
        require(msg.sender == owner || authorizations[msg.sender] == true); _;
    }
    
    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }    
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        bool isSellTransfer = false;
        bool isBuyTransfer = false;
        uint256 amountAfterFees = amount;

        if (launched()) {
            if (sender == pair && recipient != address(router)) { 
                isBuyTransfer = true;
            }
            else if (sender != owner && recipient == pair) {
                isSellTransfer = true;
            } 

            if (isSellTransfer && !isTxLimitExempt[sender]) {
                checkTxLimit(amount);
            }
            else if (isBuyTransfer && !isTxLimitExempt[recipient]) {
                checkTxLimit(amount);
            }

            if (!isMaxWalletExempt[recipient]) {
                require((_balances[recipient] + amount) <= _maxWallet, "Max wallet has been triggered");
            }

            if (isSellTransfer && !isFeeExempt[sender]) {
                amountAfterFees = takeFee(sender, amount, true);

                distributorProcess(sender);
            }
            else if (isBuyTransfer && !isFeeExempt[recipient]) {
                amountAfterFees = takeFee(sender, amount, false);

                distributorProcess(recipient);
            }
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");        
        _balances[recipient] = _balances[recipient].add(amountAfterFees);

        if (!isDividendExempt[sender]) { 
            try distributor.setShare(sender, _balances[sender]) {} catch {} 
        }

        if (!isDividendExempt[recipient]) { 
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        emit Transfer(sender, recipient, amountAfterFees);

        return true;
    }

    function distributorProcess(address sender) internal {
        if (!isDividendProcessorExempt[sender]) {
            try distributor.process(distributorGas) {} catch {}
        }
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public onlyApproved {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function checkTxLimit(uint256 amount) internal view {
        require(amount <= _maxTxAmount, "TX Limit Exceeded");
    }

    function setOwner(address newOwner) external onlyApproved {
        owner = newOwner;
    }

    function setAuthorised(address id, bool authorized) external onlyApproved {   
        authorizations[id] = authorized;
    }

    function takeFee(address sender, uint256 amount, bool isSellTransaction) internal returns (uint256) {
        uint256 fee = isSellTransaction ? totalFeeSell : totalFeeBuy;
        uint256 feeAmount = amount.mul(fee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        distributeFee(feeAmount);

        return amount.sub(feeAmount);
    }

    function distributeFee(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WFTM;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    
        uint256 amountFTM = address(this).balance.sub(balanceBefore);
        uint256 amountFTMMarketing = amountFTM.mul(marketingFeePercent).div(feePercentageMultiplyer);
        uint256 amountFTMReflection = amountFTM.mul(reflectionFeePercent).div(feePercentageMultiplyer);

        try distributor.deposit{value: amountFTMReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountFTMMarketing);
    }
    
    function Sweep() external onlyApproved {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function setMaxWallet(uint256 amount) external onlyApproved {
        require(amount >= _totalSupply / 1000);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external onlyApproved {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setFeePercentages(uint256 newMarketingFeePercent, uint256 newReflectionFeePercent, uint256 newPercentageMultiplyer) external onlyApproved {
        marketingFeePercent = newMarketingFeePercent;
        reflectionFeePercent = newReflectionFeePercent;
        feePercentageMultiplyer = newPercentageMultiplyer;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyApproved {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyApproved {
        isFeeExempt[holder] = exempt;
    }

    function setIsDividendProcessorExempt(address holder, bool exempt) external onlyApproved {
        isDividendProcessorExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyApproved {
        isTxLimitExempt[holder] = exempt;
    }

    function checkIsFeeExempt(address holder) external view returns(bool) {
        return isFeeExempt[holder];
    }

    function setIsMaxWalletLimitExempt(address holder, bool exempt) external onlyApproved {
        isMaxWalletExempt[holder] = exempt;
    }

    function checkIsMaxWalletLimitExempt(address holder) external view returns(bool) {
        return isMaxWalletExempt[holder];
    }

    function setFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _feeDenominator, uint256 _buyFee) external onlyApproved {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFeeSell = _liquidityFee.add(_reflectionFee).add(_marketingFee);
        totalFeeBuy = _buyFee;
        feeDenominator = _feeDenominator;
        require(totalFeeSell < feeDenominator/4);
    }

    function setFeeReceivers(address _marketingFeeReceiver) external onlyApproved {
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function getTotalFee(bool isSelling) public view returns (uint256) {
        return isSelling ? totalFeeSell : totalFeeBuy;
    }

    function setDistributorSettings(uint256 gas) external onlyApproved {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    } 
}