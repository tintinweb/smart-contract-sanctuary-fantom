// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/ITFUSD.sol";
import "./interfaces/ITokenBuffer.sol";
import "./interfaces/IThriftyRole.sol";

contract Thrifty is IERC20Metadata, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  mapping (address => bool) public managers;

  struct balanceInfo {
    uint256 balance;
    uint256 updatedAt;
  }
  mapping(address => balanceInfo) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint256 private _cap = 10**12 * 10**18;

  address public uniRouter;
  address public uniFactory;
  address public pairAddress;
  address public peggedToken;
  address public tFUSD;
  address public tokenBuffer;
  
  struct reflectionInfo {
    uint256 totalRAmount;
    uint256 rFee;
    uint256 daiFee;
    uint256 reflectedAt;
  }

  reflectionInfo[] public reflections;
  // map block number to reflections index
  mapping(uint256 => uint256) public reflectionPerBlock;
  mapping(address => bool) public excludedAddress;
  mapping(address => bool) public vipAddress;
  mapping(address => bool) public noTradeLimitAddress;
  uint256 public totalRSupply;
  mapping(address => uint256) public lastDaiClaimed;
  // account -> blocknumber -> balance
  mapping(address => balanceInfo[]) public balanceLogs;

  uint256 public manageDecimal = 6;

  address public roleManager;

  event ClaimReward(address account, uint256 amount);


  constructor(
    string memory name_,
    string memory symbol_,
    address _unirouter,
    address _peggedToken,
    address _tFUSD,
    address _tokenBuffer,
    address _roleManager
  ) {
    _name = name_;
    _symbol = symbol_;
    uniRouter = _unirouter;
    uniFactory = IUniswapV2Router(uniRouter).factory();
    peggedToken = _peggedToken;
    tFUSD = _tFUSD;
    tokenBuffer = _tokenBuffer;
    roleManager = _roleManager;

    _mint(address(this), _cap);

    IUniswapV2Factory(uniFactory).createPair(address(this), peggedToken);
    pairAddress = IUniswapV2Factory(uniFactory).getPair(address(this), peggedToken);
    excludedAddress[pairAddress] = true;

    excludedAddress[_tokenBuffer] = true;
  }

  receive() external payable {
  }

  modifier onlyManager() {
    require(managers[msg.sender], "!manager");
    _;
  }

  modifier onlyTFUSD() {
    require(msg.sender == tFUSD, "!tFUSD");
    _;
  }

  function fTransfer(address to, uint256 amount) public {
    _transfer(address(this), to, amount);
  }

  /*********************************************************************************************/
  /******************                    AUTO LP                    ****************************/
  /*********************************************************************************************/
  function addLiquidity() public payable onlyManager {
    uint256 amountP = msg.value;
    uint256 amountT = totalSupply().div(2);
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
    if (reserve0 != 0 || reserve1 != 0) {
      if (address(this) < peggedToken) {
        amountT = amountP.mul(reserve0).div(reserve1);
      }
      else {
        amountT = amountP.mul(reserve1).div(reserve0);
      }
    }

    uint256 currentalance = balanceOf(address(this));
    require(currentalance > amountT, "Thrifty: exceed Thrifty");
    IWETH(peggedToken).deposit{value: amountP}();
    _addLiquidity(amountT, amountP);
  }

  function removeLiquidity(uint256 liquidity, address lpSrc) public onlyManager {
    IERC20(pairAddress).safeTransferFrom(lpSrc, address(this), liquidity);
    require(IERC20(pairAddress).balanceOf(address(this)) >= liquidity, "Thrifty: low liquidity");
    _approveTokenIfNeeded(pairAddress, uniRouter, liquidity);
    (address token0, address token1) = (address(this) < peggedToken) ?
      (address(this), peggedToken) : (address(this), peggedToken);
    (uint256 amountA, uint256 amountB) = IUniswapV2Router(uniRouter).removeLiquidity(token0, token1, liquidity, 0, 0, address(this), block.timestamp);
    if (token0 == address(this)) {
      IWETH(peggedToken).withdraw(amountB);
      (bool success, ) = payable(msg.sender).call{value: amountB}("");
      require(success, "Thrifty: remove lp");
    }
    else {
      IWETH(peggedToken).withdraw(amountA);
      (bool success, ) = payable(msg.sender).call{value: amountA}("");
      require(success, "Thrifty: remove lp");
    }
  }

  function changePeggedToken(address pegToken) public onlyManager {
    peggedToken = pegToken;
    address pairAddr = IUniswapV2Factory(uniFactory).getPair(address(this), pegToken);
    if (pairAddr != pairAddress) {
      IUniswapV2Factory(uniFactory).createPair(address(this), pegToken);
      pairAddress = IUniswapV2Factory(uniFactory).getPair(address(this), pegToken);
    }
    excludedAddress[pairAddress] = true;
  }

  /**
   * t is swap percent with fee = 0.997
   * T is Thrifty reserved amount
   * d is overflowed amount than 50% of total supply
   * deltaT = (sqrt((1+t)^2 * T^2 + 4*t*d*T) - (1+t)*T) / (2*t)
   */
  function selfLP() public {
    require(IThriftyRole(roleManager).guardianMode() == true, "Thrifty: disable guardian");
    require(IThriftyRole(roleManager).hasManualSelfLpRole(msg.sender), "Unauthorized");

    uint256 inAmount = getAutoLpThriftyInAmount();

    _autoLp(inAmount);
  }

  function setAutoLpFromTFUSD(uint256 inAmount) public onlyTFUSD {
    _autoLp(inAmount);
  }

  function getAutoLpThriftyInAmount() public view returns (uint256) {
    uint256 amountD = balanceOf(address(this)).sub(totalSupply().div(2));
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
    uint256 amountT = (address(this) < peggedToken) ? uint256(reserve0) : uint256(reserve1);
    
    uint256 v1 = amountT.mul(amountT).mul(1997).mul(1997);
    uint256 v2 = amountT.mul(amountD).mul(4).mul(997).mul(1000);
    uint256 rootV = sqrt(v1.add(v2));
    if (rootV > amountT.mul(1997)) {
      return rootV.sub(amountT.mul(1997)).div(2).div(997);
    }
    return 0;
  }

  function _autoLp(uint256 inAmount) internal {
    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
    (uint256 amountT, uint256 amountP) = (address(this) < peggedToken) ?
      (uint256(reserve0), uint256(reserve1)) : (uint256(reserve1), uint256(reserve0));
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = peggedToken;
    uint256[] memory amounts = IUniswapV2Router(uniRouter).getAmountsOut(inAmount, path);
    uint256 amountIn = amounts[1].mul(amountT).div(amountP);
    if (amountIn > 0) {
      _approveTokenIfNeeded(address(this), uniRouter, inAmount);
      amounts = IUniswapV2Router(uniRouter).swapExactTokensForTokens(inAmount, 0, path, tokenBuffer, block.timestamp);
      ITokenBuffer(tokenBuffer).moveBalance(path[1], amounts[1]);
      (reserve0, reserve1,) = IUniswapV2Pair(pairAddress).getReserves();
      (amountT, amountP) = (address(this) < peggedToken) ?
        (uint256(reserve0), uint256(reserve1)) : (uint256(reserve1), uint256(reserve0));
      amountIn = amounts[1].mul(amountT).div(amountP);

      _addLiquidity(amountIn, amounts[1]);
    }
  }

  function _addLiquidity(uint256 amountT, uint256 amountP) internal {
    (uint256 amount0, uint256 amount1) = (address(this) < peggedToken) ?
      (amountT, amountP) : (amountP, amountT);
    (address token0, address token1) = (address(this) < peggedToken) ?
      (address(this), peggedToken) : (address(this), peggedToken);
    _approveTokenIfNeeded(address(this), uniRouter, amountT);
    _approveTokenIfNeeded(peggedToken, uniRouter, amountP);
    (, , uint256 liquidity) = IUniswapV2Router(uniRouter).addLiquidity(token0, token1, amount0, amount1, 0, 0, address(this), block.timestamp);

    uint256 guadianFee = liquidity.mul(IThriftyRole(roleManager).feeGuardianLp()).div(10**manageDecimal);
    IERC20(pairAddress).safeTransfer(msg.sender, guadianFee);
    IERC20(pairAddress).safeTransfer(IThriftyRole(roleManager).autoLpReceiver(), liquidity.sub(guadianFee));
  }

  function sqrt(uint256 y) internal pure returns (uint256 z) {
    unchecked {
      if (y > 3) {
        z = y;
        uint256 x = y / 2 + 1;
        while (x < z) {
          z = x;
          x = (y / x + x) / 2;
        }
      } else if (y != 0) {
        z = 1;
      }
    }
  }

  /*********************************************************************************************/
  /******************                  MANAGE TFUSD                 ****************************/
  /*********************************************************************************************/
  function addTFUSDLp(uint256 daiAmount) public {
    require(IThriftyRole(roleManager).guardianMode() == true, "Thrifty: disable guardian");
    require(IThriftyRole(roleManager).hasTFUSDLpRole(msg.sender), "Unauthorized");
    address token = ITFUSD(tFUSD).peggedToken();
    IERC20(token).safeTransferFrom(msg.sender, address(this), daiAmount);
    _approveTokenIfNeeded(token, tFUSD, daiAmount);
    ITFUSD(tFUSD).addLiquidity(daiAmount);
    _sendGuadianceFee();
  }

  /**
   * autoLp if tfusd -> pegged true, else false
   */
  function pegTFUSD(bool autoLp) public {
    require(IThriftyRole(roleManager).guardianMode() == true, "Thrifty: disable guardian");
    require(IThriftyRole(roleManager).hasTFUSDLpRole(msg.sender), "Unauthorized");
    if (autoLp == false) {
      uint256 daiAmount = ITFUSD(tFUSD).getSwapInAmount(false);
      address token = ITFUSD(tFUSD).peggedToken();
      IERC20(token).safeTransferFrom(msg.sender, address(this), daiAmount);
      _approveTokenIfNeeded(token, tFUSD, daiAmount);
    }
    ITFUSD(tFUSD).peg(autoLp);
    _sendGuadianceFee();
  }

  function mintTfusd(address account, uint256 amount) public onlyManager {
    ITFUSD(tFUSD).mint(account, amount);
  }

  function _sendGuadianceFee() internal {
    address tfusdLp = ITFUSD(tFUSD).pairAddress();
    uint256 amount = IERC20(tfusdLp).balanceOf(address(this));
    if (amount > 0) {
      IERC20(tfusdLp).safeTransfer(msg.sender, amount);
    }
  }

  /*********************************************************************************************/
  /******************                     REWAED                    ****************************/
  /*********************************************************************************************/
  function getRewardAmount(address account) public view returns(uint256) {
    uint256 len = balanceLogs[account].length;
    if (len == 0) return 0;
    uint256 x = 0;
    uint256 y = 0;
    for (; balanceLogs[account][x].updatedAt<lastDaiClaimed[account] && x < len; x++) {}
    len = reflections.length;
    for (; reflections[y].reflectedAt < balanceLogs[account][x].updatedAt && y < len; y++) {}

    uint256 daiAmount = 0;
    for (; x<len; x++) {
      uint256 uAmount = balanceLogs[account][x].balance;
      uint256 nextTs = x+1<len ? balanceLogs[account][x+1].updatedAt : type(uint256).max;
      for (; reflections[y].reflectedAt < nextTs && y < len; y++) {
        uint256 rAmount = uAmount.mul(reflections[y].rFee).div(reflections[y].totalRAmount.sub(reflections[y].rFee));
        uAmount = uAmount.add(rAmount);
        daiAmount = daiAmount.add(reflections[y].daiFee.mul(uAmount).div(reflections[y].totalRAmount));
      }
    }

    return daiAmount;
  }

  function claimReward() public {
    uint256 amount = getRewardAmount(msg.sender);
    if (amount > 0) {
      address token = ITFUSD(tFUSD).peggedToken();
      IERC20(token).transfer(msg.sender, amount);
      emit ClaimReward(msg.sender, amount);
    }
    lastDaiClaimed[msg.sender] = block.timestamp;
  }

  /*********************************************************************************************/
  /******************                     ERC20                     ****************************/
  /*********************************************************************************************/
  function name() public view returns (string memory) {
      return _name;
  }
  function symbol() public view returns (string memory) {
      return _symbol;
  }
  function decimals() public pure returns (uint8) {
      return 18;
  }
  function totalSupply() public view returns (uint256) {
      return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    balanceInfo memory bInfo = _balances[account];
    uint256 uAmount = bInfo.balance;
    if ( excludedAddress[account] == true) {
      return uAmount;
    }
    else if (bInfo.updatedAt > 0) {
      uint256 len = reflections.length;
      uint256 x = reflectionPerBlock[bInfo.updatedAt] > 0 ? reflectionPerBlock[bInfo.updatedAt].sub(1) : len;
      for (; x < len; x ++) {
        uint256 rAmount = uAmount.mul(reflections[x].rFee).div(reflections[x].totalRAmount.sub(reflections[x].rFee));
        uAmount = uAmount.add(rAmount);
      }
      return uAmount;
    }
    else {
      return 0;
    }
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = msg.sender;
    _transfer(owner, to, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = balanceOf(from);
    uint256 toBalance = balanceOf(to);
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    require (IThriftyRole(roleManager).blackListId(from) == 0 && IThriftyRole(roleManager).blackListId(to) == 0, "Thrifty: BL");
    require (IThriftyRole(roleManager).onlyWhitelist() == false ||
      (IThriftyRole(roleManager).onlyWhitelist() == true &&
      IThriftyRole(roleManager).whiteListId(from) > 0 && IThriftyRole(roleManager).whiteListId(to) > 0), "Thrifty: WL");
    bool isSell = to == pairAddress && msg.sender == uniRouter;
    bool opVesting = IThriftyRole(roleManager).enableVesting();
    bool canSell = IThriftyRole(roleManager).ableToSell(from, fromBalance, amount);
    require(isSell == false || opVesting == false || (isSell == true && opVesting == true && canSell == true), "Thrifty: vesting limit");
    if (isSell == true && opVesting == true && canSell == true) {
      IThriftyRole(roleManager).addSellLog(from, amount, block.timestamp);
    }
    unchecked {
      balanceInfo memory fBal = balanceInfo({
        balance: fromBalance.sub(amount),
        updatedAt: block.timestamp
      });
      _balances[from] = fBal;
      balanceLogs[from].push(fBal);
      if (excludedAddress[to] == true) {
        balanceInfo memory tBal = balanceInfo({
          balance: toBalance.add(amount),
          updatedAt: block.timestamp
        });
        _balances[to] = tBal;
        balanceLogs[to].push(tBal);
        if (excludedAddress[from] == false) {
          totalRSupply = totalRSupply.sub(amount);
        }
      }
      else {
        (uint256 receiveAmount, uint256 reflectFee, uint256 rewardFee) = _getFee(from, to, amount);

        bool onReflect = IThriftyRole(roleManager).enableReflect() == true;
        toBalance = onReflect == true ? toBalance.add(receiveAmount) : toBalance.add(receiveAmount).add(reflectFee);
        balanceInfo memory tBal = balanceInfo({
          balance: toBalance,
          updatedAt: block.timestamp
        });
        _balances[to] = tBal;
        balanceLogs[to].push(tBal);
        if (excludedAddress[from] == true) {
          totalRSupply = totalRSupply.add(receiveAmount).add(reflectFee);
        }

        if (reflectFee > 0 && onReflect == true) {
          reflectionInfo memory info = reflectionInfo({
            totalRAmount: totalRSupply,
            rFee: reflectFee,
            daiFee: rewardFee,
            reflectedAt: block.timestamp
          });
          reflections.push(info);
          if (reflectionPerBlock[block.timestamp] == 0) {
            reflectionPerBlock[block.timestamp] = reflections.length;
          }
        }
      }
    }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");
    require(_totalSupply + amount <= _cap, "ERC20Capped: cap exceeded");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    if (excludedAddress[account] == false) {
      totalRSupply = totalRSupply.add(amount);
    }
    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      uint256 userBalance = balanceOf(account);
      _balances[account] = balanceInfo({
        balance: userBalance.add(amount),
        updatedAt: block.timestamp
      });
    }
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = balanceOf(account);
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = balanceInfo({
        balance: accountBalance.sub(amount),
        updatedAt: block.timestamp
      });
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply -= amount;
      if (excludedAddress[account] == false) {
        totalRSupply = totalRSupply.sub(amount);
      }
    }

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

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
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
  ) internal virtual {
    if (
      (from == address(0) || to == address(0) ||
      from == address(this) || to == address(this) ||
      from == pairAddress || to == pairAddress) == false
    ) {
      uint256 curBal = balanceOf(address(this));
      uint256 limit = totalSupply().mul(IThriftyRole(roleManager).selfLpRate()).div(10 ** manageDecimal);
      if (curBal > limit) {
        amount = getAutoLpThriftyInAmount();
        _autoLp(amount);
      }
    }

    if (IThriftyRole(roleManager).enableTFUSDAutoLp()) {
      amount = ITFUSD(tFUSD).getSwapInAmount(true);
      if (amount > 0) {
        ITFUSD(tFUSD).peg(true);
        _sendGuadianceFee();
      }
    }
  }

  function _getFee(address from, address to, uint256 amount) internal
    returns(uint256 receiveAmount, uint256 reflectFee, uint256 rewardFee)
  {
    if (vipAddress[from] == true || vipAddress[to] == true) {
      return (amount, 0, 0);
    }
    bool isBuy = from == pairAddress && msg.sender == uniRouter;
    bool isSell = to == pairAddress && msg.sender == uniRouter;
    bool isTrade = isBuy || isSell;
    bool isNoLimit = (noTradeLimitAddress[from] == true || noTradeLimitAddress[to] == true) ? true : false;
    address trader = isBuy == true ? to : (isSell == true ? from : address(0));

    // receiveAmount, marketingFee, treasuryFee, reflectFee, printFee, rewardFee, extraFee
    uint256[7] memory f = IThriftyRole(roleManager).getFee(totalSupply(), trader, amount, isTrade, isSell, isNoLimit);

    receiveAmount = f[0];
    reflectFee = f[3];
    rewardFee = f[5];

    rewardFee = _processFee(f[1], f[2], f[4], f[5], f[6]);
  }

  function _processFee(uint256 marketingFee, uint256 treasuryFee, uint256 printFee, uint256 rewardFee, uint256 extraFee) internal returns(uint256 rewardAmount) {
    uint256 totalFee = marketingFee + treasuryFee + printFee + rewardFee + extraFee;
    if (totalFee > 0) {
      _approveTokenIfNeeded(address(this), uniRouter, totalFee);
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = peggedToken;
      uint256[] memory amounts = IUniswapV2Router(uniRouter).swapExactTokensForTokens(totalFee, 0, path, tokenBuffer, block.timestamp);
      ITokenBuffer(tokenBuffer).moveBalance(path[1], amounts[1]);

      uint256 marketingF = amounts[1].mul(marketingFee).div(totalFee);
      uint256 daiAmount = amounts[1].mul(printFee.add(rewardFee)).div(totalFee);
      uint256 wethamount = amounts[1].sub(daiAmount);

      if (daiAmount > 0) {
        _approveTokenIfNeeded(peggedToken, uniRouter, daiAmount);
        path[0] = peggedToken;
        path[1] = ITFUSD(tFUSD).peggedToken();
        amounts = IUniswapV2Router(uniRouter).swapExactTokensForTokens(daiAmount, 0, path, address(this), block.timestamp);
        uint256 addLpAmount = amounts[1].mul(printFee).div(printFee.add(rewardFee));
        rewardAmount = amounts[1].sub(addLpAmount);
        if (addLpAmount > 0) {
          _approveTokenIfNeeded(path[1], tFUSD, addLpAmount);
          ITFUSD(tFUSD).addLiquidity(addLpAmount);
        }
      }

      uint256 beforeBalance = address(this).balance;
      IWETH(peggedToken).withdraw(wethamount);
      address mrkWallet = IThriftyRole(roleManager).marketingWallet();
      if (mrkWallet != address(0) && marketingF > 0) {
        (bool success, ) = payable(mrkWallet).call{value: marketingF}("");
        require(success, "Thrifty: fee marketing");
      }
      address trsWallet = IThriftyRole(roleManager).treasuryWallet();
      if (trsWallet != address(0)) {
        uint256 currentBalance = address(this).balance;
        uint256 tmp = currentBalance.sub(beforeBalance);
        if (tmp > 0) {
          (bool success, ) = payable(trsWallet).call{value: tmp}("");
          require(success, "Thrifty: fee marketing");
        }
      }
    }
  }

  /*********************************************************************************************/
  /******************                    Manager                    ****************************/
  /*********************************************************************************************/
  function setVipAddress(address account, bool allow) public onlyManager {
    vipAddress[account] = allow;
  }

  function setNoTradeLimitAddress(address account, bool allow) public onlyManager {
    noTradeLimitAddress[account] = allow;
  }

  function setExcludedAddress(address account, bool excluded) public onlyManager {
    uint256 accountBalance = balanceOf(account);
    _balances[account] = balanceInfo({
      balance: accountBalance,
      updatedAt: block.timestamp
    });

    if (excludedAddress[account] == true && excluded == false) {
      totalRSupply = totalRSupply.add(accountBalance);
    }
    else if (excludedAddress[account] == false && excluded == true) {
      totalRSupply = totalRSupply.sub(accountBalance);
    }
    excludedAddress[account] = excluded;
  }

  function setUniRouter(address _unirouter) public onlyManager {
    uniRouter = _unirouter;
    uniFactory = IUniswapV2Router(uniRouter).factory();
    managers[uniRouter] = true;
  }

  function setManager(address account, bool access) public onlyOwner {
    managers[account] = access;
  }

  function withdraw(address token, address dest, uint256 amount) public onlyOwner {
    if (token == address(0)) {
      require(address(this).balance >= amount, "Thrifty: exceed balance");
      (bool success, ) = payable(dest).call{value: amount}("");
      require(success, "Thrifty: Failed redeem");
    }
    else if (token == address(this)) {
      require(balanceOf(address(this)) >= amount, "Thrifty: exceed balance");
      transfer(dest, amount);
    }
    else {
      require(IERC20(token).balanceOf(address(this)) >= amount, "Thrifty: exceed balance");
      IERC20(token).safeTransfer(dest, amount);
    }
  }

  function _approveTokenIfNeeded(address token, address spender, uint256 allowAmount) private {
    uint256 oldAllowance = IERC20(token).allowance(address(this), spender);
    if (oldAllowance < allowAmount) {
      IERC20(token).approve(spender, allowAmount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IUniswapV2Router {
    function factory() external view returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

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

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IUniswapV2Pair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IUniswapV2Factory {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ITokenBuffer {
  function Thirty() external returns(address);
  function TFUSD() external returns(address);

  function moveBalance(address token, uint256 amount) external;
  function setThirty(address _Thirty) external;
  function setTFUSD(address _TFUSD) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface IThriftyRole {
  function autoLpReceiver() external returns(address);
  function marketingWallet() external returns(address);
  function treasuryWallet() external returns(address);
  function selfLpRate() external returns(uint256);
  
  struct vestingInfo {
    uint256 percent;
    uint256 period;
  }
  function vestingWallet(address account) external view returns(vestingInfo memory);
  function addSellLog(address account, uint256 amount, uint256 sellAt) external;
  function ableToSell(address account, uint256 userBalance, uint256 amount) external view returns (bool);

  function enableReflect() external returns(bool);
  function enableTax() external returns(bool);
  function enablePrint() external returns(bool);
  function enableDaiReward() external returns(bool);
  function onlyWhitelist() external returns(bool);
  function enableFreeTransfer() external returns(bool);
  function enableVesting() external returns(bool);

  function whiteList(uint256 id) external returns(address);
  function blackList(uint256 id) external returns(address);
  function whiteListId(address wallet) external returns(uint256);
  function blackListId(address wallet) external returns(uint256);

  function guardianMode() external returns(bool);
  function feeGuardianLp() external returns(uint256);
  function guardians(uint256 id) external returns(address);
  function guardianId(address wallet) external returns(uint256);

  function hasManualSelfLpRole(address account) external view returns(bool);
  function hasTFUSDLpRole(address account) external view returns(bool);

  function getFee(uint256 totalSupply, address trader, uint256 amount, bool isTrade, bool isSell, bool noLimitAdress)
    external returns(uint256[7] memory fees);

  function feeMarketing() external returns(uint256);
  function feeTreasury() external returns(uint256);
  function feeReflection() external returns(uint256);
  function feePrint() external returns(uint256);
  function feeDaiReward() external returns(uint256);
  function feeLargeSell() external returns(uint256);
  function feeMediumSell() external returns(uint256);
  function feeFreqTrade() external returns(uint256);
  function feeQuickSell() external returns(uint256);
  function thresholdLargeSell() external returns(uint256);
  function thresholdMediumSell() external returns(uint256);
  function thresholdFreqTrade() external returns(uint256);
  function thresholdQuickSell() external returns(uint256);

  function enableTFUSDAutoLp() external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

interface ITFUSD {
  function uniRouter() external view returns(address);
  function pairAddress() external view returns(address);
  function peggedToken() external view returns(address);
  
  function addLiquidity(uint256 pegAmount) external;
  function removeLiquidity(uint256 liquidity, address lpSrc) external;
  function changePeggedToken(address pegToken) external;
  function getSwapInAmount(bool isTfusd) external view returns(uint256 amount);
  function peg(bool autoLp) external;
  function getPeggedRatio() external view returns(uint256);
  function getDepeggedRatio() external view returns(uint256);
  function requiredAutoLp() external view returns(bool);
  function requiredManualLp() external view returns(bool);
  function autoPegAndAddFeeLiquidity() external;

  function mint(address account, uint256 amount) external;
  
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
  function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}