// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Base {
    uint256 base1;
    uint256[49] __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {Base} from './Base.sol';

contract Child is Base {
    uint256 child;
}