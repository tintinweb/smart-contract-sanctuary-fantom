/**
 *Submitted for verification at FtmScan.com on 2022-03-02
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

// I AM BORED OKAY?

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

interface ITreasury {
    function redeemBonds(uint256 _bondAmount, uint256 targetPrice) external returns (bool);
    function getTombPrice() external view returns (uint256 tombPrice);
}

contract tBONDArbitrage {
    address public owner;

    IERC20 public TOMB = IERC20(0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7);
    IERC20 public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20 public TBOND = IERC20(0x24248CD1747348bDC971a5395f4b3cd7feE94ea0);

    IRouter public tombswap = IRouter(0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7);
    IRouter public spooky = IRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);

    ITreasury public treasury = ITreasury(0xF50c6dAAAEC271B56FCddFBC38F0b56cA45E6f0d);

    constructor() {
        owner == msg.sender;
        TOMB.approve(address(spooky), 2**256 - 1);
        TOMB.approve(address(tombswap), 2**256 - 1);
        TOMB.approve(address(treasury), 2**256 - 1);
        WFTM.approve(address(spooky), 2**256 - 1);
        WFTM.approve(address(tombswap), 2**256 - 1);
        TBOND.approve(address(tombswap), 2**256 - 1);
        TBOND.approve(address(treasury), 2**256 - 1);
    }
    
    modifier onlyOwner {
        require(owner == msg.sender, "Arb: Caller is not the deployer");
        _;
    }

    function arbitrage(uint256 _amount) external onlyOwner {
        require(_amount <= WFTM.balanceOf(address(this)), "Arb: Invalid WFTM balance");

        address[] memory path = new address[](2);
        path[0] = address(WFTM);
        path[1] = address(TOMB);

        address[] memory path1 = new address[](2);
        path[0] = address(TOMB);
        path[1] = address(TBOND);

        address[] memory path2 = new address[](2);
        path[0] = address(TOMB);
        path[1] = address(WFTM);

        spooky.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 1200
        );

        tombswap.swapExactTokensForTokens(
            TOMB.balanceOf(address(this)),
            0,
            path1,
            address(this),
            block.timestamp + 1200
        );

        uint256 price = treasury.getTombPrice();

        treasury.redeemBonds(
            TBOND.balanceOf(address(this)),
            price
        );

        spooky.swapExactTokensForTokens(
            TOMB.balanceOf(address(this)),
            0,
            path2,
            address(this),
            block.timestamp + 1200
        );
    }

    function destroy(address payable _to) public {
        require(owner == msg.sender, "Arb: Caller is not the deployer");
        selfdestruct(_to);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "IronVault: external call failed");
        return result;
    }
}