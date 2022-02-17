// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../../interfaces/common/IUniswapRouterETH.sol";
import "../../interfaces/bshare/IMasterChef.sol";
import "../../interfaces/curve/IRewardsGauge.sol";
import "../../interfaces/curve/ICurveSwap.sol";
import "../../interfaces/geist/IAToken.sol";

contract StrategyBased3Crv is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // pool id
    uint256 public constant PID = 3;

    // contracts
    address public constant CHEF = 0xAc0fa95058616D7539b6Eecb6418A68e7c18A746;

    address public constant G3CRV_POOL = 0x0fa949783947Bf6c1b171DB13AEACBB488845B3f;

    address public constant SPOOKY_ROUTER = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

    // tokens
    address public constant G3CRV_TOKEN = 0xD02a30d33153877BC20e5721ee53DeDEE0422B2F;

    address public constant G3CRV_GAUGE = 0xd4F94D0aaa640BBb72b5EEc2D85F6D114D81a88E;

    address public constant BSHARE = 0x49C290Ff692149A4E16611c694fdED42C954ab7a;

    address public constant CRV = 0x1E4F97b9f9F913c46F1632781732927B9019C68b;
    // token 0
    address public constant DAI = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;

    address public constant gDAI = 0x07E6332dD090D287d3489245038daF987955DCFB;

    address public constant GEIST = 0xd8321AA83Fb0a4ECd6348D4577431310A6E0814d;
    // token 1
    address public constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public constant gUSDC = 0xe578C856933D8e1082740bf7661e379Aa2A30b26;
    // token 2
    address public constant USDT = 0x049d68029688eAbF473097a2fC38ef61633A3C7A;
    address public constant gUSDT = 0x940F41F0ec9ba1A34CF001cc03347ac092F5F6B5;

    address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    bool public useBshare;
    bool public harvestCrv;
    address public want;
    address public g3CrvWant;
    address public output;
    address public vault;
    uint256 public totalProfit;
    uint256 public lastHarvest;
    uint256 public minOutputBshare;
    uint256 public minOutputCrv;
    uint256 public minOutputWftm;
    uint256 public minOutputGeist;

    // Routes
    address[] public bShareToWantRoute;
    address[] public crvToWantRoute;
    address[] public geistToWantRoute;
    address[] public wftmToWantRoute;

    event Deposit(uint256 tvl);
    event Withdraw(uint256 tvl);

    modifier ownerOrVault() {
        require(msg.sender == vault || msg.sender == owner(), "not owner or vault");
        _;
    }

    constructor(address _vault) public {
        vault = _vault;
        want = G3CRV_TOKEN;
        output = BSHARE;
        minOutputBshare = 30000000000;
        minOutputCrv = 31000000000000;
        minOutputWftm = 50000000000000;
        minOutputGeist = 500000000000000;

        totalProfit = 0;
        g3CrvWant = USDT;
        bShareToWantRoute = [BSHARE, WFTM, g3CrvWant];
        crvToWantRoute = [CRV, WFTM, g3CrvWant];
        geistToWantRoute = [GEIST, WFTM, g3CrvWant];
        wftmToWantRoute = [WFTM, g3CrvWant];
        useBshare = true;
        harvestCrv = false;
        _giveAllowances();
    }

    function depositGauge() public whenNotPaused {
        uint256 gaugeBal = balanceOfGauge();
        if (gaugeBal > 0) {
            IMasterChef(CHEF).deposit(PID, gaugeBal);
        }
    }

    function withdrawGauge(uint256 _amount) public ownerOrVault {
        uint256 wantBal = balanceOfWant();
        if (wantBal < _amount) {
            IMasterChef(CHEF).withdraw(PID, _amount.sub(wantBal));
        }
    }

    function stake() public whenNotPaused {
        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            IRewardsGauge(G3CRV_GAUGE).deposit(wantBal, address(this), true);
        }
    }

    function unstake() public ownerOrVault {
        uint256 gaugeBal = balanceOfGauge();
        if (gaugeBal > 0) {
            IRewardsGauge(G3CRV_GAUGE).withdraw(gaugeBal, true);
        }
    }

    // puts the funds to work
    function deposit() public whenNotPaused {
        stake();
        if (useBshare) {
            depositGauge();
        }
        emit Deposit(balanceOf());
    }

    function withdraw(uint256 _amount) external ownerOrVault {
        if (useBshare) {
            withdrawGauge(_amount);
            swapBasedRewards();
        }

        unstake();

        if (harvestCrv) {
            swapCrvRewards();
        }

        addLiquidity();

        IERC20(want).safeTransfer(vault, balanceOfWant());
        emit Withdraw(balanceOf());
    }

    function managerHarvest() external onlyOwner {
        managerHarvestBshare();
        managerHarvestCrv();
    }

    function managerHarvestBshare() public onlyOwner {
        IMasterChef(CHEF).deposit(PID, 0);
        uint256 bshareBal = IERC20(BSHARE).balanceOf(address(this));
        IERC20(BSHARE).safeTransfer(owner(), bshareBal);
    }

    function managerHarvestCrv() public onlyOwner {
        IRewardsGauge(G3CRV_GAUGE).claim_rewards();

        uint256 wftmBal = IERC20(WFTM).balanceOf(address(this));
        IERC20(WFTM).safeTransfer(owner(), wftmBal);

        uint256 crvBal = IERC20(CRV).balanceOf(address(this));
        IERC20(CRV).safeTransfer(owner(), crvBal);

        uint256 geistBal = IERC20(GEIST).balanceOf(address(this));
        IERC20(GEIST).safeTransfer(owner(), geistBal);
    }

    function harvest() external virtual {
        _harvest();
    }

    // compounds earnings and charges performance fee
    function _harvest() internal {
        IMasterChef(CHEF).deposit(PID, 0);
        if (harvestCrv) {
            IRewardsGauge(G3CRV_GAUGE).claim_rewards();
            swapCrvRewards();
        }
        swapBasedRewards();
        addLiquidity();
        uint256 wantBal = balanceOfWant();
        deposit();
        totalProfit += wantBal;
        lastHarvest = block.timestamp;
    }

    function swapCrvRewards() internal {
        uint256 geistBal = IERC20(GEIST).balanceOf(address(this));
        uint256 crvBal = IERC20(CRV).balanceOf(address(this));
        uint256 wftmBal = IERC20(WFTM).balanceOf(address(this));

        if (geistBal > minOutputGeist) {
            IUniswapRouterETH(SPOOKY_ROUTER).swapExactTokensForTokens(
                geistBal,
                0,
                geistToWantRoute,
                address(this),
                block.timestamp
            );
        }

        if (crvBal > minOutputCrv) {
            IUniswapRouterETH(SPOOKY_ROUTER).swapExactTokensForTokens(
                crvBal,
                0,
                crvToWantRoute,
                address(this),
                block.timestamp
            );
        }

        if (wftmBal > minOutputWftm) {
            IUniswapRouterETH(SPOOKY_ROUTER).swapExactTokensForTokens(
                wftmBal,
                0,
                wftmToWantRoute,
                address(this),
                block.timestamp
            );
        }
    }

    function swapBasedRewards() internal {
        uint256 bShareBal = IERC20(BSHARE).balanceOf(address(this));

        if (bShareBal > minOutputBshare) {
            IUniswapRouterETH(SPOOKY_ROUTER).swapExactTokensForTokens(
                bShareBal,
                0,
                bShareToWantRoute,
                address(this),
                block.timestamp
            );
        }
    }

    function addLiquidity() internal {
        uint256 daiBal = IERC20(DAI).balanceOf(address(this));
        uint256 usdcBal = IERC20(USDC).balanceOf(address(this));
        uint256 usdtBal = IERC20(USDT).balanceOf(address(this));

        if (daiBal > 0 || usdcBal > 0 || usdtBal > 0) {
            uint256[3] memory amounts = [daiBal, usdcBal, usdtBal];
            ICurveSwap3(G3CRV_POOL).add_liquidity(amounts, 0, true);
        }
    }

    // BALANCE FUNCTIONS

    function balanceOf() public view returns (uint256) {
        return balanceOfWant().add(balanceOfGauge()).add(balanceOfPool());
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfGauge() public view returns (uint256) {
        return IERC20(G3CRV_GAUGE).balanceOf(address(this));
    }

    function balanceOfPool() public view returns (uint256) {
        (uint256 _amount, ) = IMasterChef(CHEF).userInfo(PID, address(this));
        return _amount;
    }

    function balanceInTokens()
        public
        view
        returns (
            uint256 token0,
            uint256 token1,
            uint256 token2
        )
    {
        token0 = IAToken(gDAI).balanceOf(G3CRV_POOL);
        token1 = IAToken(gUSDC).balanceOf(G3CRV_POOL);
        token2 = IAToken(gUSDT).balanceOf(G3CRV_POOL);

        uint256 totalSupply = IERC20(G3CRV_TOKEN).totalSupply();

        uint256 triBal = balanceOf();

        token0 = token0.mul(triBal).div(totalSupply);
        token1 = token1.mul(triBal).div(totalSupply);
        token2 = token2.mul(triBal).div(totalSupply);
    }

    function profitInTokens()
        public
        view
        returns (
            uint256 token0,
            uint256 token1,
            uint256 token2
        )
    {
        token0 = IAToken(gDAI).balanceOf(G3CRV_POOL);
        token1 = IAToken(gUSDC).balanceOf(G3CRV_POOL);
        token2 = IAToken(gUSDT).balanceOf(G3CRV_POOL);

        uint256 totalSupply = IERC20(G3CRV_TOKEN).totalSupply();

        token0 = token0.mul(totalProfit).div(totalSupply);
        token1 = token1.mul(totalProfit).div(totalSupply);
        token2 = token2.mul(totalProfit).div(totalSupply);
    }

    function balanceInScaledTokens()
        public
        view
        returns (
            uint256 token0,
            uint256 token1,
            uint256 token2
        )
    {
        token0 = IAToken(gDAI).scaledBalanceOf(G3CRV_POOL);
        token1 = IAToken(gUSDC).scaledBalanceOf(G3CRV_POOL);
        token2 = IAToken(gUSDT).scaledBalanceOf(G3CRV_POOL);

        uint256 totalSupply = IERC20(G3CRV_TOKEN).totalSupply();

        uint256 triBal = balanceOf();

        token0 = token0.mul(triBal).div(totalSupply);
        token1 = token1.mul(triBal).div(totalSupply);
        token2 = token2.mul(triBal).div(totalSupply);
    }

    function profitInScaledTokens()
        public
        view
        returns (
            uint256 token0,
            uint256 token1,
            uint256 token2
        )
    {
        token0 = IAToken(gDAI).scaledBalanceOf(G3CRV_POOL);
        token1 = IAToken(gUSDC).scaledBalanceOf(G3CRV_POOL);
        token2 = IAToken(gUSDT).scaledBalanceOf(G3CRV_POOL);

        uint256 totalSupply = IERC20(G3CRV_TOKEN).totalSupply();

        token0 = token0.mul(totalProfit).div(totalSupply);
        token1 = token1.mul(totalProfit).div(totalSupply);
        token2 = token2.mul(totalProfit).div(totalSupply);
    }

    // REWARD AVAIL

    function rewardsAvailable()
        public
        view
        returns (
            uint256 bshare,
            uint256 crv,
            uint256 geist,
            uint256 wftm
        )
    {
        bshare = bshareAvailable();
        crv = crvAvailable();
        geist = geistAvailable();
        wftm = wftmAvailable();
    }

    function bshareAvailable() public view returns (uint256) {
        return IMasterChef(CHEF).pendingShare(PID, address(this));
    }

    function crvAvailable() public view returns (uint256) {
        return IRewardsGauge(G3CRV_GAUGE).claimable_reward(address(this), CRV);
    }

    function geistAvailable() public view returns (uint256) {
        return IRewardsGauge(G3CRV_GAUGE).claimable_reward(address(this), GEIST);
    }

    function wftmAvailable() public view returns (uint256) {
        return IRewardsGauge(G3CRV_GAUGE).claimable_reward(address(this), WFTM);
    }

    // ADMIN FUNCTIONS

    function setHarvestCrv(bool _harvestCrv) external onlyOwner {
        harvestCrv = _harvestCrv;
    }

    function setUseBshare(bool _useBshare) external onlyOwner {
        useBshare = _useBshare;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    // want for depositing in tripool
    function setG3CrvWant(address _g3CrvWant) external onlyOwner {
        require(_g3CrvWant == DAI || _g3CrvWant == USDC || _g3CrvWant == USDT, "not g3Crv want");
        g3CrvWant = _g3CrvWant;
    }

    function setBshareToWantRoute(address[] memory _bShareToWantRoute) external onlyOwner {
        require(_bShareToWantRoute[0] == BSHARE, "bShareToWantRoute[0] != BSHARE");
        require(
            _bShareToWantRoute[_bShareToWantRoute.length - 1] == g3CrvWant,
            "bShareToWantRoute[last] != want"
        );
        bShareToWantRoute = _bShareToWantRoute;
    }

    function setCrvToWantRoute(address[] memory _crvToWantRoute) external onlyOwner {
        require(_crvToWantRoute[0] == CRV, "crvToWantRoute[0] != CRV");
        require(
            _crvToWantRoute[_crvToWantRoute.length - 1] == g3CrvWant,
            "crvToWantRoute[last] != want"
        );
        crvToWantRoute = _crvToWantRoute;
    }

    function setWftmToWantRoute(address[] memory _wftmToWantRoute) external onlyOwner {
        require(_wftmToWantRoute[0] == WFTM, "wftmToWantRoute[0] != WFTM");
        require(
            _wftmToWantRoute[_wftmToWantRoute.length - 1] == g3CrvWant,
            "wftmToWantRoute[last] != want"
        );
        wftmToWantRoute = _wftmToWantRoute;
    }

    function setMinOutputBshare(uint256 _minOutputBshare) external onlyOwner {
        minOutputBshare = _minOutputBshare;
    }

    function setMinOutputCrv(uint256 _minOutputCrv) external onlyOwner {
        minOutputCrv = _minOutputCrv;
    }

    function setMinOutputGeist(uint256 _minOutputGeist) external onlyOwner {
        minOutputGeist = _minOutputGeist;
    }

    function setMinOutputWftm(uint256 _minOutputWftm) external onlyOwner {
        minOutputWftm = _minOutputWftm;
    }

    // EMERGENCY FUNCTIONS

    function emergencyStake() external onlyOwner {
        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            IRewardsGauge(G3CRV_GAUGE).deposit(wantBal);
        }
    }

    function emergencyUnstake() public onlyOwner {
        uint256 gaugeBal = balanceOfGauge();
        if (gaugeBal > 0) {
            IRewardsGauge(G3CRV_GAUGE).withdraw(gaugeBal);
        }
    }

    function panic() public onlyOwner {
        pause();
        retireStrat();
    }

    function pause() public onlyOwner {
        _pause();
        _removeAllowances();
    }

    function unpause() external onlyOwner {
        _unpause();

        _giveAllowances();

        deposit();
    }

    function retireStrat() public ownerOrVault {
        IMasterChef(CHEF).emergencyWithdraw(PID);
        emergencyUnstake();
        uint256 wantBal = balanceOfWant();
        IERC20(want).transfer(vault, wantBal);
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(owner(), amount);
    }

    function inCaseFTMGetStuck() external onlyOwner {
        (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }

    // ALLOWANCES

    function _giveAllowances() internal {
        IERC20(DAI).safeApprove(G3CRV_POOL, uint256(-1));
        IERC20(USDC).safeApprove(G3CRV_POOL, uint256(-1));
        IERC20(USDT).safeApprove(G3CRV_POOL, uint256(-1));
        IERC20(BSHARE).safeApprove(SPOOKY_ROUTER, uint256(-1));
        IERC20(CRV).safeApprove(SPOOKY_ROUTER, uint256(-1));
        IERC20(GEIST).safeApprove(SPOOKY_ROUTER, uint256(-1));
        IERC20(WFTM).safeApprove(SPOOKY_ROUTER, uint256(-1));
        IERC20(G3CRV_TOKEN).safeApprove(G3CRV_GAUGE, 0);
        IERC20(G3CRV_TOKEN).safeApprove(G3CRV_GAUGE, uint256(-1));
        IERC20(G3CRV_GAUGE).safeApprove(CHEF, 0);
        IERC20(G3CRV_GAUGE).safeApprove(CHEF, uint256(-1));
    }

    function _removeAllowances() internal {
        IERC20(DAI).safeApprove(G3CRV_POOL, 0);
        IERC20(USDC).safeApprove(G3CRV_POOL, 0);
        IERC20(USDT).safeApprove(G3CRV_POOL, 0);
        IERC20(BSHARE).safeApprove(SPOOKY_ROUTER, 0);
        IERC20(CRV).safeApprove(SPOOKY_ROUTER, 0);
        IERC20(GEIST).safeApprove(SPOOKY_ROUTER, 0);
        IERC20(WFTM).safeApprove(SPOOKY_ROUTER, 0);
        IERC20(G3CRV_TOKEN).safeApprove(G3CRV_GAUGE, 0);
        IERC20(G3CRV_GAUGE).safeApprove(CHEF, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IUniswapRouterETH {
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

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IMasterChef {
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function pendingShare(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IRewardsGauge {
    function balanceOf(address account) external view returns (uint256);

    function claimable_reward(address _addr, address _token) external view returns (uint256);

    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function deposit(uint256 _value) external;

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    function withdraw(uint256 _value) external;

    function withdraw(uint256 _value, bool _claim_rewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface ICurveSwap {
    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    function coins(uint256 arg0) external view returns (address);
}

interface ICurveSwap2 {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;
}

interface ICurveSwap3 {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    function add_liquidity(
        address _pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external;
}

interface ICurveSwap4 {
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;

    function add_liquidity(
        address _pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external;
}

interface ICurveSwap5 {
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external;
}

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.6.0;

interface IAToken is IERC20 {
    function decimals() external view returns (uint256);

    function getAssetPrice() external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    function scaledBalanceOf(address user) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}