// SPDX-License-Identifier: MIT
//  ________   _______     _______.___________.   .______   .______        ______   .___________.  ______     ______   ______    __
// |       /  |   ____|   /       |           |   |   _  \  |   _  \      /  __  \  |           | /  __  \   /      | /  __  \  |  |
// `---/  /   |  |__     |   (----`---|  |----`   |  |_)  | |  |_)  |    |  |  |  | `---|  |----`|  |  |  | |  ,----'|  |  |  | |  |
//    /  /    |   __|     \   \       |  |        |   ___/  |      /     |  |  |  |     |  |     |  |  |  | |  |     |  |  |  | |  |
//   /  /----.|  |____.----)   |      |  |        |  |      |  |\  \----.|  `--'  |     |  |     |  `--'  | |  `----.|  `--'  | |  `----.
//  /________||_______|_______/       |__|        | _|      | _| `._____| \______/      |__|      \______/   \______| \______/  |_______|
// Twitter: @ProtocolZest
// https://zestprotocol.fi

pragma solidity 0.8.4;

interface IVe {
    function create_staking_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256);

    function create_airdrop_lock_for(
        uint256 _value,
        uint256 _lock_duration,
        address _to
    ) external returns (uint256);

    function withdraw_staking(uint256 _tokenId) external;

    function balanceOf(address _owner) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex)
        external
        view
        returns (uint256);

    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    function locked__amount(uint256 _tokenId) external view returns (uint256);

    function increase_amount_staking(uint256 _tokenId, uint256 _value) external;

    function locked__end(uint256 _tokenId) external view returns (uint256);

    function token() external view returns (address);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
//  ________   _______     _______.___________.   .______   .______        ______   .___________.  ______     ______   ______    __
// |       /  |   ____|   /       |           |   |   _  \  |   _  \      /  __  \  |           | /  __  \   /      | /  __  \  |  |
// `---/  /   |  |__     |   (----`---|  |----`   |  |_)  | |  |_)  |    |  |  |  | `---|  |----`|  |  |  | |  ,----'|  |  |  | |  |
//    /  /    |   __|     \   \       |  |        |   ___/  |      /     |  |  |  |     |  |     |  |  |  | |  |     |  |  |  | |  |
//   /  /----.|  |____.----)   |      |  |        |  |      |  |\  \----.|  `--'  |     |  |     |  `--'  | |  `----.|  `--'  | |  `----.
//  /________||_______|_______/       |__|        | _|      | _| `._____| \______/      |__|      \______/   \______| \______/  |_______|
// Twitter: @ProtocolZest
// https://zestprotocol.fi
pragma solidity 0.8.4;

import "../interfaces/IVe.sol";

// Provides governence of Zest Protocol by returning an accounts total vlZest balance from all their owned veZest NFTs

contract vlZest {
    address immutable ve = 0x1FD52F5f94f5844514c51E3079a419545f32A50D;

    function _getVlZestBalance(address account, uint256 t) internal view returns (uint256) {
        uint256 numTokens = IVe(ve).balanceOf(account);
        if (numTokens == 0) {
            return 0;
        }

        uint256 total;

        for (uint256 index = 0; index < numTokens; index++) {
            uint256 tokenId = IVe(ve).tokenOfOwnerByIndex(account, index);
            total += IVe(ve).balanceOfNFTAt(tokenId, t);
        }

        return total;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _getVlZestBalance(account, block.timestamp);
    }

    function balanceOfAt(address account, uint256 t) public view returns (uint256) {
        return _getVlZestBalance(account, t);
    }
}