// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface KittensHD {
  function getGeneralMintCounter() external returns (uint256);

  function getPrice(uint256 quantity) external returns (uint256);

  function unpauseMinting() external;

  function pauseMinting() external;

  function daoAnyClaim(uint256 quantity) external;

  function safeTransferFrom(
    address a,
    address b,
    uint256 tokenId
  ) external;
}

contract Airdrop is IERC721Receiver {
  KittensHD public kittensHD;
  address public owner;

  constructor(address kittensHDAddress) {
    owner = msg.sender;
    kittensHD = KittensHD(kittensHDAddress);
  }

  function airdrop(address[] memory holders, uint256 amountEach) external {
    require(msg.sender == owner, "not owner");

    for (uint256 i = 0; i < holders.length; i++) {
      kittensHD.daoAnyClaim(amountEach);
      uint256 currentIndex = kittensHD.getGeneralMintCounter();
      for (uint256 j = 0; j < amountEach; j++) {
        kittensHD.safeTransferFrom(address(this), holders[i], currentIndex + j);
      }
    }
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}