/**
 *Submitted for verification at FtmScan.com on 2022-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Marketplace {

    event CreateCollection(
        address indexed _operator, 
        // NFT contract address, can be ERC721 or ERC1144. No need to verify.
        address indexed _nft_contract_addr
    );

    event SetLoyalty(
        address indexed _operator, 
        // NFT contract address.
        address indexed _nft_contract_addr, 
        // Loyalty receiver address.
        address _loyalty_recv_addr, 
        // Loyalty ratio in micros, i.e. 1000000 = 100%, if it's 0 then we won't
        // use loyalty mechanism.
        uint256 _loyalty_micros
    );

    event List(
        address indexed _operator, 
        // Sell NFT contract address.
        address indexed _nft_contract_addr,
        // Sell NFT token id.
        uint256 _nft_token_id,
        // Sell price.
        uint256 _mars_quantity
    );

    event Cancel(
        address indexed _operator, 
        // Sell NFT contract address.
        address indexed _nft_contract_addr,
        // Sell NFT token id.
        uint256 _nft_token_id
    );

    function createCollection(address nft_conract) external {
        emit CreateCollection(msg.sender, nft_conract);
    }

    function setLoyalty(address nft_contract, address recv_addr, uint256 loyality) external {
        emit SetLoyalty(msg.sender, nft_contract, recv_addr, loyality);
    }

    function list(address nft_contract, uint256 token_id, uint256 price) external {
        emit List(msg.sender, nft_contract, token_id, price);
    }

    function cancel(address nft_contract, uint256 token_id) external {
        emit Cancel(msg.sender, nft_contract, token_id);
    }

}