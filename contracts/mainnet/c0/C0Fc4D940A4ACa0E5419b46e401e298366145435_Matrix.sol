// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IUniswapV2ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./Ownable.sol";

// MatrixMaker is MasterChef's left hand and kinda a wizard. He can cook up WFTM from pretty much anything!
// This contract handles "serving up" rewards for PILLS holders by trading tokens collected from fees for MorpheusSwap.

contract ConstantNeo {
    function updateRewardPerSec(uint256 newAmount) external {}
}

// T1 - T4: OK
contract Matrix is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // V1 - V5: OK
    IUniswapV2Factory public immutable factory;
    // 0x9C454510848906FDDc846607E4baa27Ca999FBB6
    address public multisig;
    address public oracle;


    // ConstantNeo public neo;
    address public neo;

    // V1 - V5: OK
    address private immutable wftm;
    // 0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83

    address[] public addresses;
    uint256[] public points;

    // V1 - V5: OK
    mapping(address => address) internal _bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountWFTM
    );

    constructor(
        address _factory,
        address _multisig,
        address _oracle,
        address _wftm,
        address _neo
    ) {
        factory = IUniswapV2Factory(_factory);
        multisig = _multisig;
        oracle = _oracle;
        wftm = _wftm;
        neo = _neo;
    }

    // add new recipient
    function setRecipient(address _address, uint8 _points) public onlyOwner {
        uint index = 0;

        // check t see if recipieint is already in list
        for(uint j = 0; j < addresses.length; j++) {
            if(addresses[j] != _address) continue;
            index = j + 1;
            break;
        }

        // create new
        if(index == 0) {
            addresses.push(_address);
            points.push(_points);

        // update existing
        } else {
            points[index - 1] = _points;
        }
    }

    // return total points
    function totalPoints() public view returns (uint _points) {
        _points = 0;
        for(uint j = 0; j < points.length; j++)
            _points = _points.add(points[j]);
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = wftm;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != wftm && token != bridge,
            "MatrixtMaker: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    modifier onlyZion() {
        require(msg.sender == oracle || msg.sender == owner(), "MatrixMaker: must be from a Zion operative.");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, "MatrixMaker: must come from the all mighty multisig.");
        _;
    }

    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

    function setMultisig(address _multisig) public onlyMultisig {
        multisig = _multisig;
    }

    // pC1
    function convert(address token0, address token1) external onlyZion returns (uint) {
        return _convert(token0, token1);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1
    ) external onlyZion {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        uint totalAmount;

        // pC1
        for (uint256 i = 0; i < len; i++) {
            totalAmount += _convert(token0[i], token1[i]);
        }

        // send any extra wftm in contract's balance to rev share
        uint balance = IERC20(wftm).balanceOf(address(this));
        // uint256 amountToNeo;
        // if (0 < balance) 
            // (,amountToNeo) =
        totalAmount += _distributeFTM(balance);


        // X1 - X5: OK
        // pC1
        uint j = 0;
        for(j = 0; j < addresses.length; j++) 
            if(addresses[j] == neo) break;
            else continue;
        // pC1
        uint _totalPoints = totalPoints();
        uint256 neoAmount = (points[j] * totalAmount).div(_totalPoints);

        // call update reward per sec
        ConstantNeo(neo).updateRewardPerSec(neoAmount);
    }

    // F1 - F10: OK
    // C1- C24: OK
    // pC1
    function _convert(address token0, address token1) internal returns (uint amountOut) {
        // Interactions
        // S1 - S4: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "MatrixMaker: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }
        // pC1
        amountOut = _convertStep(token0, token1, amount0, amount1);
        emit LogConvert(
            msg.sender,
            token0,
            token1,
            amount0,
            amount1,
            amountOut
        );
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toSPIRIT, _convertStep: X1 - X5: OK
    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns (uint256 wftmOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == wftm) {
                _distributeFTM(amount);
                wftmOut = amount;
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this));
                wftmOut = _convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == wftm) {
            wftmOut = _distributeFTM(_swap(token1, wftm, amount1, address(this)).add(amount0));
        } else if (token1 == wftm) {
            wftmOut = _distributeFTM(_swap(token0, wftm, amount0, address(this)).add(amount1));
        } else {
            // eg. DAI - MIM
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. DAI - MIM - and bridgeFor(DAI) = MIM
                wftmOut = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. MIM - DAI - and bridgeFor(DAI) = MIM
                wftmOut = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                wftmOut = _convertStep(
                    bridge0,
                    bridge1, // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair = IUniswapV2Pair(
            factory.getPair(fromToken, toToken)
        );
        require(address(pair) != address(0), "MatrixMaker: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        // 3.3
        uint256 amountInWithFee = amountIn.mul(9985);
        if (fromToken == pair.token0()) {
            // 3.3
            amountOut =
                amountInWithFee.mul(reserve1) /
                reserve0.mul(10000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            // 3.3
            amountOut =
                amountInWithFee.mul(reserve0) /
                reserve1.mul(10000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _distributeFTM(uint256 amount)
        internal
        returns (uint256 amountOut)
    {
        uint _totalPoints = totalPoints();

        // X1 - X5: OK
        for(uint j = 0; j < addresses.length; j++) 
            IERC20(wftm).safeTransfer(address(addresses[j]), (points[j] * amount).div(_totalPoints));

        amountOut = amount;
    }

    function emergencyWithdrawal(address token) external onlyMultisig {
        IERC20(token).safeTransfer(address(multisig), IERC20(token).balanceOf(address(this)));
    }
}