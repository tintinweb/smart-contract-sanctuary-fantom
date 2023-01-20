/**
 *Submitted for verification at FtmScan.com on 2023-01-20
*/

// SPDX-License-Identifier: None
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ISpookyRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IMasterchef { 
    function harvestAllRewards(address to) external;
    function deposit(uint256 pid, uint256 amount, address to) external;
    function emergencyWithdraw(uint256 pid, address to) external;
}

interface IStaker {
    function withdrawableBalance(address user) external view returns (uint256 amount, uint256 penaltyAmount);
    function withdraw(uint256 amount) external;
    function emergencyWithdraw() external;
}

contract WonderlyCompounder {
    address public immutable owner;
    ISpookyRouter public Router = ISpookyRouter(0x31F63A33141fFee63D4B26755430a390ACdD8a4d);
    IERC20[] public Token = [
        IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83), // WFTM
        IERC20(0xB6d8Ff34968e0712c56DE561b2f9Debd526a348c) // GFX
    ];
    IERC20[] public LP = [
        IERC20(0x63B560616CcCc218ade162bB580579f55c3320bb), // GFX/WFTM
        IERC20(0x8B74DF2FFa35464cb6CB96888FF8eecae29f728F) // GFTM/WFTM
    ];
    IMasterchef public Chef = IMasterchef(0x6646346DEe3cfb1C479a65009B9ed6DA47D41771);
    IStaker public Staker = IStaker(0x29f3e86280014d703BCaE532b6751fFa9Fca0df9);

    constructor() {
        owner = msg.sender;
        Token[0].approve(address(Router), 2 ** 256 - 1);
        Token[1].approve(address(Router), 2 ** 256 - 1);
        LP[0].approve(address(Chef), 2 ** 256 - 1);
        LP[1].approve(address(Chef), 2 ** 256 - 1);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    function harvestStaker() public {
        (uint256 amount, uint256 penaltyAmount) = Staker.withdrawableBalance(address(this));
        Staker.withdraw(amount);
    }

    function compoundPart1() external {
        Chef.harvestAllRewards(address(this));
    }

    function compoundPart2() external {
        harvestStaker();

        address[] memory path = new address[](2);
        path[0] = address(Token[1]);
        path[1] = address(Token[0]);

        Router.swapExactTokensForTokens(
            (Token[1].balanceOf(address(this)) / 2),
            0,
            path,
            address(this),
            block.timestamp + 999999
        );

        Router.addLiquidity(
            address(Token[0]),
            address(Token[1]),
            Token[0].balanceOf(address(this)),
            Token[1].balanceOf(address(this)),
            1,
            1,
            address(this),
            block.timestamp + 999999
        );

        Chef.deposit(0, LP[0].balanceOf(address(this)), address(this));

    }

    function deposit(uint256 _pid) external onlyOwner {
        Chef.deposit(_pid, LP[_pid].balanceOf(address(this)), address(this));
    }

    function withdrawAndHarvest() external onlyOwner {
        Chef.harvestAllRewards(address(this));
        Chef.emergencyWithdraw(0, address(this));
        Chef.emergencyWithdraw(1, address(this));
    }

    function recover(address _contract) external onlyOwner {
        IERC20 newToken = IERC20(_contract);
        newToken.transfer(owner, newToken.balanceOf(address(this)));
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "external call failed");
        return result;
    }
}