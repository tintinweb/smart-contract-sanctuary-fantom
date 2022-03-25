/**
 *Submitted for verification at FtmScan.com on 2022-03-25
*/

pragma solidity 0.8.10;

interface IERC20 {
    function transferFrom(address,address,uint) external returns (bool);
    function burn(uint) external;
    function mint(address, uint) external;
}

contract ContDutchAuction {

    uint public r; // y amount distributed per second
    uint public s; // total y sold
    uint public immutable g = block.timestamp; // genesis time
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
        unchecked {
            uint numerator = sqrt(x**2 - 4*((x*s) - (x*r*getT()))) - x;
            return numerator / 2;
        }
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

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}