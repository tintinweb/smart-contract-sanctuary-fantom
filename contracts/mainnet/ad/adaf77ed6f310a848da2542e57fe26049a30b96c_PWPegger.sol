//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IPWPegger.sol";
import "./interfaces/ICalibratorProxy.sol";
import "./interfaces/dependencies/IEACAggregatorProxy.sol";
import "./interfaces/dependencies/IERC20.sol";
import "./interfaces/dependencies/IUniswapV2Pair.sol";

import "./libraries/PWLibrary.sol";
import "./libraries/PWConfig.sol";



struct PoolData {
    uint g;
    uint u; 
    uint p1; 
    uint lp;
}

contract PWPegger is IPWPegger {
    PWConfig private pwconfig;
    bool statusPause;
    uint round;

    modifier onlyAdmin() {
        require(msg.sender == pwconfig.admin, "Error: must be admin EOA or multisig only");
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == pwconfig.admin || msg.sender == pwconfig.keeper, 
            "Error: must be admin or keeper EOA/multisig only");
        _;
    }

    modifier onlyNotPaused() {
        require(!statusPause, "PWPeggerMock in on Pause now");
        _;
    }

    constructor(PWConfig memory _pwconfig) {
        uint _dec = _pwconfig.decimals;

        require(
            _dec > 0 &&
            _pwconfig.frontrunth > 0 && 
            _pwconfig.volatilityth > _pwconfig.frontrunth &&
            _pwconfig.emergencyth > _pwconfig.volatilityth,
            "Error: wrong config parameters. Check th params and decimals"
        );
        require(msg.sender != _pwconfig.admin, "Error: deployer cannot be an admin");
        pwconfig = _pwconfig;
        statusPause = false;
        round = 0;
    }

    function updPWConfig(PWConfig memory _pwconfig) external onlyAdmin() {
        pwconfig = _pwconfig;
    }

    function updAdmin(address _newAdmin) external override onlyAdmin() {
        pwconfig.admin = _newAdmin;
    }

    function updKeeper(address _newKeeper) external override onlyAdmin() {
        pwconfig.keeper = _newKeeper;
    }

    function updPathwayDONRef(address _newPwpegdonRef) external override onlyAdmin() {
        pwconfig.pwpegdonRef = _newPwpegdonRef;
    }

    function updCalibratorProxyRef(address _newCalibrator) external override onlyAdmin() {
        pwconfig.calibrator = _newCalibrator;
    }

    function updVaultRef(address _newVault) external override onlyAdmin() {
        pwconfig.vault = _newVault;
    }

    function setPauseOn() external override onlyKeeper() onlyNotPaused() {
        statusPause = true;
    }

    function setPauseOff() external override onlyAdmin() {
        statusPause = false;
    }

    function getPauseStatus() external override view returns (bool) {
        return statusPause;
    }

    function updPoolRef(address _pool) external override onlyAdmin() {
        pwconfig.pool = _pool;
    }

    function updTokenRef(address _token) external override onlyAdmin() {
        pwconfig.token = _token;
    }

    function updEmergencyTh(uint _newEmergencyth) external override onlyAdmin() {
        pwconfig.emergencyth = _newEmergencyth;
    }

    function updVolatilityTh(uint _newVolatilityth) external override onlyAdmin() {
        pwconfig.volatilityth = _newVolatilityth;
    }

    function updFrontRunProtectionTh(uint _newFrontrunth) external override onlyAdmin() {
        pwconfig.frontrunth = _newFrontrunth;
    }

    function _checkThConditionsOrRaiseException(uint _currPrice, uint _pwPrice) view internal {
        uint priceDiff = _currPrice > _pwPrice ? _currPrice - _pwPrice : _pwPrice - _currPrice;

        require(priceDiff < pwconfig.emergencyth, 
            "Th Emergency Error: price diff exceeds emergency threshold");
        require(priceDiff <  pwconfig.volatilityth, 
            "Th Volatility Error: price diff exceeds volatility threshold");
    }

    function _checkThFrontrunOrRaiseException(uint _currPrice, uint _keeperPrice) view internal {
        uint priceDiff = _currPrice > _keeperPrice ? _currPrice - _keeperPrice : _keeperPrice - _currPrice;

        require(priceDiff < pwconfig.frontrunth, 
            "Th FrontRun Error: current price is much higher than keeperPrice");
        require(priceDiff <  pwconfig.emergencyth, 
            "Th Emergency Error: current price is much higher than keeperPrice");
    }

    // those functions are reading and convert data to the correct decimals for price data
    function _readDONPrice(address _refDON) view internal returns (uint) {
        IEACAggregatorProxy priceFeed = IEACAggregatorProxy(_refDON);
        (            
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint decimals = priceFeed.decimals();
        require(decimals >= 0 && answer > 0, 'DON Error: price data and decimals must be higher than 0');
        uint n = 10**pwconfig.decimals;
        uint d = 10**decimals;
        return (uint(answer)*n/d);
    }

    function _preparePWData(IUniswapV2Pair _pool, address _tokenGRef) view internal returns (PoolData memory) {
        (
            uint112 reserve0, 
            uint112 reserve1, 
            uint32 blockTimestampLast
        ) = _pool.getReserves();

        IERC20 tokenG = IERC20(_pool.token0() == _tokenGRef ? _pool.token0() : _pool.token1());
        IERC20 tokenU = IERC20(!(_pool.token0() == _tokenGRef) ? _pool.token0() : _pool.token1());

        uint decimalsG = uint(tokenG.decimals());
        uint decimalsU = uint(tokenU.decimals());

        uint n = 10**pwconfig.decimals;

        uint g = n*uint(_pool.token0() == _tokenGRef ? reserve0 : reserve1)/(10**decimalsG);
        uint u = n*uint(!(_pool.token0() == _tokenGRef) ? reserve0 : reserve1)/(10**decimalsU);

        return PoolData(
            g, 
            u, 
            n*u/g, 
            _pool.totalSupply());
    }

    function callIntervention(uint _keeperCurrentPrice) external override onlyKeeper() onlyNotPaused() {
        require(_keeperCurrentPrice > 0, 'Call Error: _keeperCurrentPrice must be higher than 0');

        IUniswapV2Pair pool = IUniswapV2Pair(pwconfig.pool);
        uint pPrice = _readDONPrice(pwconfig.pwpegdonRef);

        PoolData memory poolData = _preparePWData(pool, pwconfig.token);

        _checkThConditionsOrRaiseException(poolData.p1, pPrice);
        _checkThFrontrunOrRaiseException(poolData.p1, _keeperCurrentPrice);

        // Step-I: what to do - up or down
        PWLibrary.EAction act = pPrice > poolData.p1 ? PWLibrary.EAction.Up : PWLibrary.EAction.Down;

        // Step-II: how many LPs
        uint xLPs = PWLibrary.computeXLPForDirection(
            poolData.g, 
            poolData.u, 
            poolData.p1, 
            pPrice,
            act, 
            poolData.lp,
            pwconfig.decimals
        );

        // Step-II: execute:
        pool.transferFrom(pwconfig.vault, address(this), xLPs);
        pool.approve(address(pwconfig.calibrator), xLPs);

        ICalibratorProxy calibrator = ICalibratorProxy(pwconfig.calibrator);

        if (act == PWLibrary.EAction.Up) {
            calibrator.calibratePurelyViaPercentOfLPs_UP(
                pool,
                xLPs,
                1,
                1,
                pwconfig.vault
            );
        } else if (act == PWLibrary.EAction.Down) {
            calibrator.calibratePurelyViaPercentOfLPs_DOWN(
                pool,
                xLPs,
                1,
                1,
                pwconfig.vault
            );
        } else {
            revert("invalid pw action");
        }
    }

    function getPWConfig() external override view returns (PWConfig memory) {
        return pwconfig;
    }

    function getLastRoundNumber() external override view returns (uint) {
        return round;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../libraries/PWConfig.sol";

interface IPWPegger {
    // admin (permissioned) - EOA or multisig account who is able to chnage configuration of the PW
    function updAdmin(address) external; // admin only

    // keeper (permissioned) - EOA or multisig oracle account who is able to call sc invocation
    function updKeeper(address) external; // admin only

    // admin only is able to update DONs EACAggregatorProxy, used as price and peg data refferences
    function updPathwayDONRef(address) external; // admin only

    // admin only is able to update Corrector SCs refference: CalibratorProxy
    // increasing/decreasing gov token price on AMM during pw-intervention call
    function updCalibratorProxyRef(address) external; // admin only

    // admin only is able to update vault account associated with pw as funds and LP ops storage
    function updVaultRef(address) external; // admin only

    // admin and keeper oracle are able to pause sc, but only admin can activate it back
    function setPauseOn() external; // keeper and admin
    function setPauseOff() external; // admin only
    function getPauseStatus() external view returns(bool);

    // amm pool data
    function updPoolRef(address) external; // admin only
    function updTokenRef(address) external; // admin only

    // admin only is able to update threshold parameters in %*BASE_DECIMALS: 0.1% => 100 if BASE_DECIMALS == 10^3
    // emergency threshold used to set pause on if price and peg DONs are far from each other
    function updEmergencyTh(uint) external; // admin only
    // volatility threshold used to succefully do or don't pw intervention
    function updVolatilityTh(uint) external; // admin only
    // volatility threshold used to prevent front run attack during an intervention call
    function updFrontRunProtectionTh(uint) external; // admin only
    // threasholds values must be: E > V > F > 0

    // callIntervention is a main function initializing pw-intervention, called by keeper oracle
    // intervention is comparing keeperCurrentPrice with currentPrice to prevent frontrun
    function callIntervention(uint _keeperCurrentPrice) external; // keeper and admin

    function getPWConfig() external view returns (PWConfig memory);

    // counting how many times intervention succesfully happened
    function getLastRoundNumber() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./dependencies/IUniswapV2Pair.sol";

interface ICalibratorProxy {
    function calibratePurelyViaPercentOfLPs_UP(
        IUniswapV2Pair pool,
        uint256 _liquidity,
        uint256 n,
        uint256 d,
        address to
    ) external; 

    function calibratePurelyViaPercentOfLPs_DOWN(
        IUniswapV2Pair pool,
        uint256 _liquidity,
        uint256 n,
        uint256 d,
        address to
    ) external; 
  }

// https://etherscan.io/address/0xdc3ea94cd0ac27d9a86c180091e7f78c683d3699#code

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IEACAggregatorProxy {
    function latestRoundData() external view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
    
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    // Pool balance interface
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    // LP token interface
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    // ERC20 LP interface
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library PWLibrary {

  enum EAction {
    Up,
    Down
  }

  function computeXLP(uint _g, uint _pRatio, uint _lps, uint decimals) internal pure returns (uint _xlps) {
    require(_pRatio > 0 && _g > 0 && _lps > 0, "Error: computeLP2Calibrator wrong input args");
    // g*P1 + u = g’*P2 + u’, where P1 is a price of g in u; u == u' =>
    // => dg = g’ - g or dg = g*(P1/P2 - 1) => mdg = g*(1 - P1/P2)
    uint n = 10**decimals;
    uint mdg = _g*_pRatio;
    uint hasToBeExtractedG = mdg/2;
    uint hasToBeExtractedLPShare = n*hasToBeExtractedG/_g;
    _xlps = _lps*hasToBeExtractedLPShare/n; //_lps has its own decimals
  }

  function computeXLPForDirection(uint _g, uint _u, uint _p1, uint _pG2, EAction _type, uint _lpsupply, uint decimals) internal pure returns (uint _xlps) {
    uint n = 10**decimals;
    uint pRatio;

    if (_type == EAction.Up) {
      pRatio = computePRatio(n, _p1, _pG2);
    } else if (_type == EAction.Down) {
      uint p1 = n * _g / _u;
      uint p2 = n / _pG2;
      pRatio = computePRatio(n, p1, p2);
    } else {
      revert("unknown type");
    }

    _xlps = computeXLP(_g, pRatio, _lpsupply, decimals);
  }

  function computePRatio(uint n, uint p1, uint p2) internal pure returns (uint _ratio) {
    return (n - (p1 * n / p2)) / n;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct PWConfig { 
    address admin;
    address keeper;
    address pwpegdonRef;
    address calibrator;
    address vault;
    address pool;
    address token;
    uint emergencyth;
    uint volatilityth;
    uint frontrunth;
    uint decimals;
}