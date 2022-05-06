/**
 *Submitted for verification at FtmScan.com on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC1155 {
    function uri(uint256 tokenId) external view returns (string memory);
}

contract IERC1155Helper {
    function maximumId(IERC1155 token, uint256 startIndex) public view returns (uint256 maximum) {
        for (startIndex; startIndex < type(uint256).max; startIndex++) {
            try token.uri(startIndex) {
                maximum = startIndex;
            } catch {
                break;
            }
        }
    }
}