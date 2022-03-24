/**
 *Submitted for verification at FtmScan.com on 2022-03-23
*/

/**
 *Submitted for verification at FtmScan.com on 2022-03-21
*/

// File: contracts/swap/interfaces/IMoroccoSwapV2Factory.sol

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IMoroccoSwapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;
    function PERCENT100() external view returns (uint256);
    function DEADADDRESS() external view returns (address);
    
    function lockFee() external view returns (uint256);
    // function sLockFee() external view returns (uint256);
    function pause() external view returns (bool);
    function InoutTax() external view returns (uint256);
    function swapTax() external view returns (uint256);
    function setRouter(address _router) external ;
    function InOutTotalFee()external view returns (uint256);
    function feeTransfer() external view returns (address);

    function setFeeTransfer(address)external ;
    
}

// File: contracts/swap/interfaces/IERC20.sol


pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/swap/interfaces/IBank.sol

pragma solidity 0.6.12;



interface IBank{
    function addReward(address token0, address token1, uint256 amount0, uint256 amount1) external;
     function addrewardtoken(
        address token,
        uint256 amount
    ) external;
}

interface IFarm{
    
     function addLPInfo(
        IERC20 _lpToken,
        IERC20 _rewardToken0,
        IERC20 _rewardToken1
    ) external;

    function addReward(address _lp,address token0, address token1, uint256 amount0, uint256 amount1) external;

    function addrewardtoken(
        address _lp,
        address token,
        uint256 amount
    ) external;

}


// File: contracts/swap/libraries/TransferHelper.sol


pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/swap/libraries/SafeMath.sol


pragma solidity 0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathMoroccoSwap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

// File: contracts/swap/MoroccoSwapFeeTransfer.sol

pragma solidity 0.6.12;






contract MoroccoSwapFeeTransfer {
    using SafeMathMoroccoSwap for uint256;

    uint256 public constant PERCENT100 = 1000000;
    address public constant DEADADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public factory;
    address public router;

    address public roulette;
    address public farm;
    // Bank address
    address public antiBank;
    address public usdtxBank;
    address public goldxBank;
    address public btcxBank;
    address public ethxBank;

    address public storageprovider;
    address public computation;
    address public metaverse;
    address public hotspot;
    address public ligaMatch;
    address public blockReward;

    //Inout fee
    uint256 public bankFee = 1000;
    uint256 public rouletteFee = 500;
    uint256 public blockRewardFee = 2500;
    uint256 public metaverseFee = 1000;
    uint256 public storageFee = 2500;
    uint256 public computationFee = 1000;
    uint256 public totalFee = 12500;

    // Swap fee
    uint256 public sfarmFee = 900;
    uint256 public sLockFee = 500;
    uint256 public sblockRewardFee = 300;
    uint256 public sUSDTxFee = 50;
    uint256 public srouletteFee = 100;
    uint256 public sstorageFee = 300;
    uint256 public scomputationFee = 50;
    uint256 public smetaverseFee = 150;
    uint256 public shotspotFee = 100;
    uint256 public sLigaMatchFee = 50;

    uint256 public swaptotalFee = 2500;

    address public feeSetter;

    constructor(
        address _factory,
        address _router,
        address _feeSetter
    ) public {
        factory = _factory;
        router = _router;
        feeSetter = _feeSetter;
    }

    function takeSwapFee(
        address lp,
        address token,
        uint256 amount
    ) public returns (uint256) {
        uint256 PERCENT = PERCENT100;

        uint256[10] memory fees;
   
        fees[0] = amount.mul(sfarmFee).div(PERCENT); //_sFarmFee
        fees[1] = amount.mul(sLockFee).div(PERCENT); //_sLockFee
        fees[2] = amount.mul(sblockRewardFee).div(PERCENT); //_sblockRewardFee
        fees[3] = amount.mul(sUSDTxFee).div(PERCENT); //_sUSDTxFee
        fees[4] = amount.mul(srouletteFee).div(PERCENT); //_sRouletteFee
        fees[5] = amount.mul(sstorageFee).div(PERCENT); //_sstorageFee
        fees[6] = amount.mul(scomputationFee).div(PERCENT); //_scomputationFee
        fees[7] = amount.mul(smetaverseFee).div(PERCENT); //_smetaverseFee
        fees[8] = amount.mul(shotspotFee).div(PERCENT); //_shotspotFee
        fees[9] = amount.mul(sLigaMatchFee).div(PERCENT); //_sLigaMatchFee

        _approvetokens(token, farm, amount);
        IFarm(farm).addrewardtoken(lp, token, fees[0]);

        TransferHelper.safeTransfer(token, DEADADDRESS, fees[1]);
        TransferHelper.safeTransfer(token, blockReward, fees[2]);

        _approvetokens(token, usdtxBank, amount);
        IBank(usdtxBank).addrewardtoken(token, fees[3]);
        TransferHelper.safeTransfer(token, roulette, fees[4]);

        TransferHelper.safeTransfer(token, storageprovider, fees[5]);
        TransferHelper.safeTransfer(token, computation, fees[6]);
        TransferHelper.safeTransfer(token, metaverse, fees[7]);
        TransferHelper.safeTransfer(token, hotspot, fees[8]);
        TransferHelper.safeTransfer(token, ligaMatch, fees[9]);

    }

    function takeLiquidityFee(
        address _token0,
        address _token1,
        uint256 _amount0,
        uint256 _amount1
    ) public {
        uint256 PERCENT = PERCENT100;

        address[5] memory bankFarm = [
            antiBank,
            usdtxBank,
            goldxBank,
            btcxBank,
            ethxBank
                    ];


        uint256[6] memory bankFee0;
        bankFee0[0] = _amount0.mul(bankFee).div(PERCENT);
        bankFee0[1] = _amount0.mul(rouletteFee).div(PERCENT);
        bankFee0[2] = _amount0.mul(blockRewardFee).div(PERCENT);
        bankFee0[3] = _amount0.mul(metaverseFee).div(PERCENT);
        bankFee0[4] = _amount0.mul(storageFee).div(PERCENT);
        bankFee0[5] = _amount0.mul(computationFee).div(PERCENT);
     

        uint256[6] memory bankFee1;
        bankFee1[0] = _amount1.mul(bankFee).div(PERCENT);
        bankFee1[1] = _amount1.mul(rouletteFee).div(PERCENT);
        bankFee1[2] = _amount1.mul(blockRewardFee).div(PERCENT);
        bankFee1[3] = _amount1.mul(metaverseFee).div(PERCENT);
        bankFee1[4] = _amount1.mul(storageFee).div(PERCENT);
        bankFee1[5] = _amount1.mul(computationFee).div(PERCENT);

        TransferHelper.safeTransfer(_token0, roulette, bankFee0[1]);
        TransferHelper.safeTransfer(_token1, roulette, bankFee1[1]);

        TransferHelper.safeTransfer(_token0, blockReward, bankFee0[2]);
        TransferHelper.safeTransfer(_token1, blockReward, bankFee1[2]);

        TransferHelper.safeTransfer(_token0, metaverse, bankFee0[3]);
        TransferHelper.safeTransfer(_token1, metaverse, bankFee1[3]);

        TransferHelper.safeTransfer(_token0, storageprovider, bankFee0[4]);
        TransferHelper.safeTransfer(_token1, storageprovider, bankFee1[4]);

        TransferHelper.safeTransfer(_token0, computation, bankFee0[5]);
        TransferHelper.safeTransfer(_token1, computation, bankFee1[5]);

        _approvetoken(_token0, _token1, bankFarm[0], _amount0, _amount1);
        _approvetoken(_token0, _token1, bankFarm[1], _amount0, _amount1);
        _approvetoken(_token0, _token1, bankFarm[2], _amount0, _amount1);
        _approvetoken(_token0, _token1, bankFarm[3], _amount0, _amount1);
        _approvetoken(_token0, _token1, bankFarm[4], _amount0, _amount1);

        IBank(bankFarm[0]).addReward(
            _token0,
            _token1,
            bankFee0[0],
            bankFee1[0]
        );
        IBank(bankFarm[1]).addReward(
            _token0,
            _token1,
            bankFee0[0],
            bankFee1[0]
        );
        IBank(bankFarm[2]).addReward(
            _token0,
            _token1,
            bankFee0[0],
            bankFee1[0]
        );
        IBank(bankFarm[3]).addReward(
            _token0,
            _token1,
            bankFee0[0],
            bankFee1[0]
        );
        IBank(bankFarm[4]).addReward(
            _token0,
            _token1,
            bankFee0[0],
            bankFee1[0]
        );

    }

    function _approvetoken(
        address _token0,
        address _token1,
        address _receiver,
        uint256 _amount0,
        uint256 _amount1
    ) private {
        if (
            _token0 != address(0x000) ||
            IERC20(_token0).allowance(address(this), _receiver) < _amount0
        ) {
            IERC20(_token0).approve(_receiver, _amount0);
        }
        if (
            _token1 != address(0x000) ||
            IERC20(_token1).allowance(address(this), _receiver) < _amount1
        ) {
            IERC20(_token1).approve(_receiver, _amount1);
        }
    }

    function _approvetokens(
        address _token,
        address _receiver,
        uint256 _amount
    ) private {
        if (
            _token != address(0x000) ||
            IERC20(_token).allowance(address(this), _receiver) < _amount
        ) {
            IERC20(_token).approve(_receiver, _amount);
        }
    }

    function configure(
        address _roulette,
        address _farm,
        address[5] memory _bank,
        address  _storageprovider,
        address  _computation,
        address  _metaverse,
        address  _hotspot,
        address  _ligaMatch,
        address  _blockReward
    ) external {
        require(msg.sender == feeSetter, "Only fee setter");

        roulette = _roulette;
        farm = _farm;
        antiBank = _bank[0];
        usdtxBank = _bank[1];
        goldxBank = _bank[2];
        btcxBank = _bank[3];
        ethxBank = _bank[4];

        storageprovider = _storageprovider;
        computation = _computation ;
        metaverse = _metaverse ;
        hotspot = _hotspot ;
        ligaMatch = _ligaMatch;
        blockReward = _blockReward;

    }
}