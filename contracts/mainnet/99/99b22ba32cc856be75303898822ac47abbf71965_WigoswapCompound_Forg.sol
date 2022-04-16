/**
 *Submitted for verification at FtmScan.com on 2022-04-16
*/

//SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IWigoVault {
    function harvest() external;
}

interface IRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

contract WigoswapCompound_Forg {
    address public owner;
    IWigoVault public Wigovault = IWigoVault(0x4178E335bd36295FFbC250490edbB6801081D022);
    IRouter public Router = IRouter(0x5023882f4D1EC10544FCB2066abE9C1645E95AA0);
    IERC20 public WIGO = IERC20(0xE992bEAb6659BFF447893641A378FbbF031C5bD6);
    address private WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    constructor() {
        owner = msg.sender;
        WIGO.approve(address(Router), 2**256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    function compound() external onlyOwner {
        Wigovault.harvest();

        address[] memory path = new address[](2);
        path[0] = address(WIGO);
        path[1] = WFTM;

        Router.swapExactTokensForETH(
            WIGO.balanceOf(address(this)),
            0,
            path,
            owner,
            block.timestamp + 1200
        );
    }

    function recoverTokens(address _token) external onlyOwner {
        IERC20 Token = IERC20(_token);
        Token.transfer(owner, Token.balanceOf(address(this)));
    }
}