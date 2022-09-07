/**
 *Submitted for verification at FtmScan.com on 2022-09-07
*/

contract transform {
    function _toBytes(address a) external pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }
    function _bytesToAddress(bytes memory bys)
        external
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
 }