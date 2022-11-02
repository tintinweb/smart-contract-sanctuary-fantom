// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract BaseV2PairFactoryInterface {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        bool stable,
        address pair,
        uint256
    );

    function allPairs(uint256) external view returns (address) {}

    function allPairsLength() external view returns (uint256) {}

    function childInterfaceAddress()
        external
        view
        returns (address _childInterface)
    {}

    function childSubImplementationAddress()
        external
        view
        returns (address _childSubImplementation)
    {}

    function createFees() external returns (address fees) {}

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair) {}

    function feesFactory() external view returns (address) {}

    function getPair(
        address,
        address,
        bool
    ) external view returns (address) {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress)
    {}

    function initialize(address _feesFactory) external {}

    function interfaceSourceAddress() external view returns (address) {}

    function isPair(address) external view returns (bool) {}

    function isPaused() external view returns (bool) {}

    function pairCodeHash() external pure returns (bytes32) {}

    function setPause(bool _state) external {}

    function updateChildInterfaceAddress(address _childInterfaceAddress)
        external
    {}

    function updateChildSubImplementationAddress(
        address _childSubImplementationAddress
    ) external {}
}