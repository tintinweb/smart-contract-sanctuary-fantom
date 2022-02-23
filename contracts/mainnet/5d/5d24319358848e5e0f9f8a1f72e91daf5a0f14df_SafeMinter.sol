/**
 *Submitted for verification at FtmScan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INFT {
    function totalSupply() external view returns (uint256);
    function price() external view returns (uint256);
    function buySpirit(uint256 amount) external payable;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract SafeMinter is IERC721Receiver {
    event ReceivedERC721(
        address operator,
        address from,
        uint256 tokenId,
        bytes data,
        uint256 gas
    );

    INFT public target = INFT(0x4162977558eB5830e6fc5adEb67bF6625F458929);

    function totalSupply() public view returns (uint256) {
        return target.totalSupply();
    }

    function price() public view returns (uint256) {
        return target.price();
    }

    function buySpirit(uint256 tokenId) public payable {
        require(tokenId == totalSupply());
        target.buySpirit{value: msg.value}(1);
        require(target.ownerOf(tokenId) == address(this));
        target.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        emit ReceivedERC721(operator, from, tokenId, data, gasleft());

        return IERC721Receiver.onERC721Received.selector;
    }
}