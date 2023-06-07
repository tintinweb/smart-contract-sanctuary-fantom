// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {TestLib} from "./TestLib.sol";

contract Example {
    using TestLib for uint256;

    function testFunction() external view returns (uint256) {
        uint256 val = 555;
        return val.increment();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library TestLib {
    function increment(uint256 val) internal view returns (uint256) {
        return val + 1;
    }
}