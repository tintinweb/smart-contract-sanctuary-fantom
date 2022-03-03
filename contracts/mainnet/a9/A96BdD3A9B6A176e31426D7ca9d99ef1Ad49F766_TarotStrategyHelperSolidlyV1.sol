// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IGauge.sol";
import "./interfaces/ILpDepositor.sol";
import "./interfaces/IBoostMaxxer.sol";
import "./interfaces/IBaseV1Pair.sol";

contract TarotStrategyHelperSolidlyV1 {
    IBaseV1Pair public constant vamm_xTAROT_TAROT = IBaseV1Pair(0x4FE782133af0f7604B9B89Bf95893ADDE265FEFD);
    IGauge public constant gauge = IGauge(0xA0813bcCc899589B4E7d9Ac42193136D0313F4Eb);
    IBoostMaxxer public constant boostMaxxer = IBoostMaxxer(0xe21ca4536e447C13C79B807C0Df4f511A21Db6c7);
    ILpDepositor public constant lpDepositor = ILpDepositor(0x26E1A0d851CF28E697870e1b7F053B605C8b060F);

    constructor() {}

    function getLpBalance(address _user) public view returns (uint256 amount) {
        amount =
            boostMaxxer.userDepositedAmountInfo(address(vamm_xTAROT_TAROT), _user) +
            lpDepositor.userBalances(_user, address(vamm_xTAROT_TAROT)) +
            gauge.balanceOf(_user) +
            vamm_xTAROT_TAROT.balanceOf(_user);
    }

    function getVotes(address _user) public view returns (uint256 amount) {
        (uint256 reserve0, , ) = vamm_xTAROT_TAROT.getReserves();
        uint256 lpTotalSupply = vamm_xTAROT_TAROT.totalSupply();
        if (lpTotalSupply > 0) {
            amount = (reserve0 * getLpBalance(_user)) / lpTotalSupply;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IGauge {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ILpDepositor {
    function userBalances(address pool, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBoostMaxxer {
    function userDepositedAmountInfo(address pool, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBaseV1Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function balanceOf(address) external view returns (uint);
    function totalSupply() external view returns (uint);
}