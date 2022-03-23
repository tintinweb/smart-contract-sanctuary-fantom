/**
 *Submitted for verification at FtmScan.com on 2022-03-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

interface IERC20 {
    function transferFrom(address,address,uint) external returns (bool);
    function burn(uint) external;
    function mint(address, uint) external;
}

contract ContDutchAuction {

    uint public r; // y amount distributed per second
    uint public s; // total y sold
    uint public g = block.timestamp; // genesis time
    uint public constant P = 1 ether; // precision
    address public operator;
    IERC20 public immutable tokenX; // purchase token
    IERC20 public immutable tokenY; // payout token

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR");
        _;
    }

    constructor(uint _r, IERC20 _tokenX, IERC20 _tokenY) {
        operator = msg.sender;
        r = _r;
        tokenX = _tokenX;
        tokenY = _tokenY;
    }

    function changeOperator(address _operator) public onlyOperator {
        operator = _operator;
    }

    function getY(uint x) public view returns (uint) {
        return (x*r*getT() - x*s) / (P+x);
    }

    // Not for precise calculations
    function getX(uint y) public view returns (uint) {
        return (y*P) / (r*getT() - s - y);
    }

    function getT() public view returns (uint) {
        return block.timestamp - g;
    }

    function swap(uint x, uint minY) public returns (uint y) {
        y = getY(x);
        require(y >= minY, "Insufficient Y");
        s += y;
        tokenX.transferFrom(msg.sender, address(this), x);
        tokenX.burn(x);
        tokenY.mint(msg.sender, y);
    }

    function setR(uint _r) public onlyOperator {
        r = _r;
    }
}