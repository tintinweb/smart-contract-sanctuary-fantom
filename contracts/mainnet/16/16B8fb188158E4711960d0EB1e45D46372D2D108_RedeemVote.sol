// Be name Khoda
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

import "./interfaces/IvDeus.sol";
import "./interfaces/ITrancheRedeem.sol";

contract RedeemVote {
    address public vDeus;
    address public trancheRedeem;

    constructor(address vDeus_, address trancheRedeem_) {
        vDeus = vDeus_;
        trancheRedeem = trancheRedeem_;
    }

    function balanceOf(address user) public view returns (uint256 balance) {
        uint256 count = IvDeus(vDeus).balanceOf(user);
        for (uint256 index = 0; index < count; index++) {
            uint256 tokenId = IvDeus(vDeus).tokenOfOwnerByIndex(user, index);
            balance += ITrancheRedeem(trancheRedeem).redemptions(tokenId).deiAmount;
        }
    }
}

//Dar panah khoda

// SPDX-License-Identifier: MIT

interface IvDeus {
    function balanceOf(address _owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

interface ITrancheRedeem {
    struct Redemption {
        uint256 deiAmount;
        // Redemption tranche
        uint8 tranche;
    }

    function redemptions(uint) external view returns (Redemption memory);
}