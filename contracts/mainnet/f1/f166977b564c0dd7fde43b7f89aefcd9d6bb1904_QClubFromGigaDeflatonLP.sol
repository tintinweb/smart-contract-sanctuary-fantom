/**
 *Submitted for verification at FtmScan.com on 2023-01-27
*/

// jiggedy jacked from Larkin's pgunk wrapper
// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.9;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}
interface IQCLUB {
    function mint(address to, uint256 amt) external;
}

contract QClubFromGigaDeflatonLP {
    //0xa8f8Ce6959D70Dc699d6D603319353547DAA3eaE FTM GigaDeflaton HyperLP
    //0x24623f2a4ec70E81862469FbAb10900b51389DF1 FTM GigaDeflaton SushiLP
    IUniswapV2Pair hypa = IUniswapV2Pair(0xa8f8Ce6959D70Dc699d6D603319353547DAA3eaE);
    IUniswapV2Pair sushi = IUniswapV2Pair(0x24623f2a4ec70E81862469FbAb10900b51389DF1);
    IQCLUB qclub = IQCLUB(0xD4aCBD42a6990BE368104a0c6Dc3c5dd1C540c00);
    address WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    function isFTM0 (bool isSushi )public view returns (bool) {
        address token0;
        if (isSushi) {
            token0 = sushi.token0();
        } else {
            token0 = hypa.token0();
        }
        if (token0 == WFTM) {
            return true;
        } else {
            return false;
        }
    }
    function getReserve0(bool isSushi) public view returns (uint112) {
        
        if (isSushi) {
            (uint112 r0, , )=sushi.getReserves();
            return r0;
        } else {
            (uint112 r0, , )=hypa.getReserves();
            return r0;
        }
    }
    function getReserve1(bool isSushi) public view returns (uint112) {
        if (isSushi) {
            (, uint112 r1, )=sushi.getReserves();
            return r1;
        } else {
            (, uint112 r1, )=hypa.getReserves();
            return r1;
        }
    }
    function getFTMinLP(uint256 amt, bool isSushi) public view returns (uint256) {
        uint256 share = (10 ** 18) * amt / sushi.totalSupply();
        if (isFTM0(isSushi)) {
            return share * getReserve0(isSushi) / 10 ** 18;
        } else {
            return share * getReserve1(isSushi) / 10 ** 18;
        }
    }

    function getFTMValueOfLP(uint256 amt, bool isSushi) public view returns (uint256) {
        return getFTMinLP(amt,isSushi) * 2;
    }

    function burnLPforQCLUB(uint256 amt, bool isSushi) public {
        if (isSushi) {
            require(sushi.balanceOf(msg.sender) >= amt, "user does not have enough sushi LP");
            sushi.transferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                amt
            );
            qclub.mint(msg.sender, getFTMValueOfLP(amt, isSushi));
        } else {
            require(hypa.balanceOf(msg.sender) >= amt, "user does not have enough hyper LP");
            hypa.transferFrom(
                msg.sender,
                address(0x000000000000000000000000000000000000dEaD),
                amt
            );
            qclub.mint(msg.sender, getFTMValueOfLP(amt, isSushi));
        }
        
    }

    constructor() {

    }


    

    
}