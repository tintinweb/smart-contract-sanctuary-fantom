// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './IRedemptionFactory.sol';
import './RedemptionPair.sol';

contract RedemptionFactory is IRedemptionFactory {
    address public override feeTo = 0x7eE8c4DAc9EB3c67d7Ed66A6173fe7102984B6C2;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    bool public paused = false;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    event Pause();
    event Unpause();

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    constructor(address _feeToSetter) public {
        require(_feeToSetter != address(0), '_feeToSetter cannot be zero address');
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(RedemptionPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override whenNotPaused returns (address pair) {
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(RedemptionPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        RedemptionPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'RedemptionV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'RedemptionV2: FORBIDDEN');
        require(_feeToSetter != address(0), '_feeToSetter cannot be zero address');
        feeToSetter = _feeToSetter;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public whenNotPaused {
        require(msg.sender == feeToSetter, 'RedemptionV2: FORBIDDEN');
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public whenPaused {
        require(msg.sender == feeToSetter, 'RedemptionV2: FORBIDDEN');
        paused = false;
        emit Unpause();
    }

    function isPaused() external view override returns (bool) {
        return paused;
    }
}