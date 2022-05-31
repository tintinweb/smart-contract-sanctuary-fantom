/**
 *Submitted for verification at FtmScan.com on 2022-05-31
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IFundNFT {
    function mint(
        address,
        uint256,
        uint256
    ) external;
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function decimals() external returns (uint8);
}

contract MintFundNFT {
    address immutable safe;
    address immutable token;
    address immutable fundNFT;

    constructor(
        address _safe,
        address _token,
        address _fundNFT
    ) {
        safe = _safe;
        token = _token;
        fundNFT = _fundNFT;
    }

    function deposit(uint256 value) external {
        uint256 decimals = uint256(IERC20(token).decimals());

        require(
            value % (100 * (10**decimals)) == 0 && value > 0,
            "value is not correct"
        );

        require(IERC20(token).transferFrom(msg.sender, safe, value));

        uint256 share = value / (100 * (10**decimals));
        IFundNFT(fundNFT).mint(msg.sender, share, value);
    }
}