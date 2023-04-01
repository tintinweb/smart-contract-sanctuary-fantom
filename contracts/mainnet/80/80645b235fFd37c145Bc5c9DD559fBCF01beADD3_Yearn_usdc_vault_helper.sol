/**
 *Submitted for verification at FtmScan.com on 2023-03-30
*/

pragma solidity 0.8.17;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)  external returns (bool);  
  function transferFrom(address from, address to, uint256 value)  external returns (bool);    
}


interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface Ivault {
    function deposit(uint amount, address to) external returns(uint);

    function withdraw(uint shares, address to) external returns(uint);
    function withdraw(uint shares, address to, uint maxLoss) external returns(uint);
}




contract Yearn_usdc_vault_helper {
    address public owner = msg.sender;
    Ivault public vault = Ivault(0xEF0210eB96c7EB36AF8ed1c20306462764935607); // Yearn usdc vault
    IRouter public router = IRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);  // UniswapV2 router 
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;  // usdc ERC20 address
    address public usdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A; // usdt ERC20 address
    


    function deposit_usdt(uint amount) external {
        require(IERC20(usdt).allowance(msg.sender, address(this)) >= amount, "approve usdt first!");
        require(IERC20(usdt).transferFrom(msg.sender, address(this), amount), "transferFrom failed!");
        address[] memory routePath = new address[](2);
        routePath[0] = usdt;
        routePath[1] = usdc;
        IERC20(usdt).approve(address(router), amount);

        uint usdc_balance = IERC20(usdc).balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, routePath, address(this), block.timestamp);

        // could be done using amounts returned from swapExactTokensForTokens, but method below is more trusted  
        uint got_usdc = IERC20(usdc).balanceOf(address(this)) - usdc_balance;

        IERC20(usdc).approve(address(vault), got_usdc);

        vault.deposit(got_usdc, msg.sender);

    }

    function withdraw_usdc_all() external {
        uint user_balance = IERC20(address(vault)).balanceOf(msg.sender);
        require(IERC20(address(vault)).allowance(msg.sender, address(this)) >= user_balance, "approve LP tokens first!");
        require(IERC20(address(vault)).transferFrom(msg.sender, address(this), user_balance), "transferFrom failed!");
        vault.withdraw(user_balance, msg.sender);
    }

    function withdraw_usdc_all(uint maxLoss) external {
        uint user_balance = IERC20(address(vault)).balanceOf(msg.sender);
        require(IERC20(address(vault)).allowance(msg.sender, address(this)) >= user_balance, "approve LP tokens first!");
        require(IERC20(address(vault)).transferFrom(msg.sender, address(this), user_balance), "transferFrom failed!");
        vault.withdraw(user_balance, msg.sender, maxLoss);
    }

    function withdraw_usdc(uint shares) external {
        require(IERC20(address(vault)).allowance(msg.sender, address(this)) >= shares, "approve LP tokens first!");
        require(IERC20(address(vault)).transferFrom(msg.sender, address(this), shares), "transferFrom failed!");
        vault.withdraw(shares, msg.sender);
    }


    function withdraw_usdc(uint shares, uint maxLoss) external {
        require(IERC20(address(vault)).allowance(msg.sender, address(this)) >= shares, "approve LP tokens first!");
        require(IERC20(address(vault)).transferFrom(msg.sender, address(this), shares), "transferFrom failed!");
        vault.withdraw(shares, msg.sender, maxLoss);
    }

}