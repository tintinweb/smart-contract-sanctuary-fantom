/**
 *Submitted for verification at FtmScan.com on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRelayerPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

abstract contract RelayerFac {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function allPairsLength() external view virtual returns (uint256);
}

// - In order to quickly load up data from Uniswap-like market, this contract allows easy iteration with a single eth_call.
// - We use modified interface name to avoid mempool detection.
error StartGtStop(uint256 start, uint256 stop);
contract Relayer {
    struct Reserves {
        uint112 reserve0;
        uint112 reserve1;
        uint32 blockTimestampLast;
    }

    struct Pair {
        IRelayerPair pair;
        address token0;
        address token1;
    }

    struct FactoryData {
        RelayerFac factory;
        Pair[] pairs;
        uint256 totalPairs;
        Reserves[] reserves;
    }

    //  Externals
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // Get pairs for a single factory, starting and ending at a certain index.
    // - Use to update new listing pairs.
    function getPairsByIndexRange(RelayerFac factory, uint256 start, uint256 stop) external view returns (address[3][] memory)  {
        uint256 allPairsLength = factory.allPairsLength();

        if (stop > allPairsLength) {
            stop = allPairsLength;
        }

        if (stop < start) revert StartGtStop(start, stop);

        uint256 qty = stop - start;
        address[3][] memory result = new address[3][](qty);

        for (uint i; i < qty;) {
            IRelayerPair pair = IRelayerPair(factory.allPairs(start + i));
            result[i][0] = pair.token0();
            result[i][1] = pair.token1();
            result[i][2] = address(pair);

            unchecked {
                ++i;
            }
        }

        return result;
    }

    // Get reserves for a single pair.
    function getReservesOf(IRelayerPair pair) external view returns (Reserves memory result) {
        return _getReservesOf(pair);
    }

    // Get reserves for each pair.
    function getReservesOf(IRelayerPair[] calldata pairs) external view returns (Reserves[] memory) {
        return _getReservesOf(pairs);
    }

    // Gets all pairs for a dex factory address.
    function getAllPairsFrom(RelayerFac factory) external view returns (Pair[] memory) {
        return _getAllPairsFrom(factory);
    }

    // Gets all pair details for all factories.
    // - Used to initialize + prepare bot.
    function getAllPairsOf(RelayerFac[] calldata factories) external view returns (FactoryData[] memory) {
        FactoryData[] memory data = new FactoryData[](factories.length);

        for (uint256 i; i < factories.length; ) {
            data[i].factory = factories[i];
            data[i].pairs = _getAllPairsFrom(factories[i]);
            data[i].totalPairs = data[i].pairs.length;

            for (uint256 n; n < data[i].totalPairs; ) {
                data[i].reserves[n] = _getReservesOf(data[i].pairs[n].pair);
                unchecked {
                    ++n;
                }
            }

            unchecked {
                ++i;
            }
        }

        return data;
    }

    //  Privates
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function _getReservesOf(IRelayerPair pair) private view returns (Reserves memory result) {
        (
            result.reserve0, 
            result.reserve1, 
            result.blockTimestampLast
        ) = pair.getReserves();
    }

    function _getReservesOf(IRelayerPair[] calldata pairs) private view returns (Reserves[] memory) {
        Reserves[] memory results = new Reserves[](pairs.length);

        for (uint256 i; i < pairs.length; ) {
            (
                results[i].reserve0, 
                results[i].reserve1, 
                results[i].blockTimestampLast
            ) = pairs[i].getReserves();

            unchecked {
                ++i;
            }
        }

        return results;
    }
    
    function _getAllPairsFrom(RelayerFac factory) private view returns (Pair[] memory) {
        uint256 allPairsLength = factory.allPairsLength();

        Pair[] memory result = new Pair[](allPairsLength);

        for (uint256 i; i < allPairsLength; ) {            
            result[i].pair = IRelayerPair(factory.allPairs(i));
            result[i].token0 = result[i].pair.token0();
            result[i].token1 = result[i].pair.token1();

            unchecked {
                ++i;
            }
        }

        return result;
    }
}