/**
 *Submitted for verification at FtmScan.com on 2023-04-11
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

    Ivault public constant vault = Ivault(0xEF0210eB96c7EB36AF8ed1c20306462764935607); // Yearn usdc vault
    IRouter public constant router = IRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);  // UniswapV2 router 
    address public constant usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;  // usdc ERC20 address
    address public constant usdt = 0x049d68029688eAbF473097a2fC38ef61633A3C7A; // usdt ERC20 address
    
    constructor() {
        IERC20(usdt).approve(address(router), ~uint256(0)); // blindely trust uniswapv2 router
        IERC20(usdc).approve(address(vault), ~uint256(0)); // and Yearn vault

    }

    function deposit_usdt(uint amount) external {

        // gas savings
        IERC20  usdt_interface = IERC20(usdt);
        IERC20  usdc_interface = IERC20(usdc);
        address this_contract = address(this);
        address user = msg.sender;
        // end
        require(usdt_interface.allowance(user, this_contract) >= amount, "approve usdt");
        require(usdt_interface.transferFrom(user, this_contract, amount), "fail!");
        address[] memory routePath = new address[](2);
        routePath[0] = usdt;
        routePath[1] = usdc;

        uint usdc_balance = usdc_interface.balanceOf(this_contract);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, routePath, this_contract, block.timestamp);

        // could be done using amounts returned from swapExactTokensForTokens, but method below is more trusted  
        uint got_usdc = usdc_interface.balanceOf(this_contract) - usdc_balance;

        vault.deposit(got_usdc,user);

    }

    function withdraw_usdc_all() external {
        address user = msg.sender;
        address this_contract = address(this);
        uint user_balance = IERC20(address(vault)).balanceOf(user);

        require(IERC20(address(vault)).allowance(user, this_contract) >= user_balance, "approve LP tokens first!");
        require(IERC20(address(vault)).transferFrom(user, this_contract, user_balance), "transferFrom failed!");
        vault.withdraw(user_balance, user);
    }

    function withdraw_usdc_all(uint maxLoss) external {
       
        IERC20 vault_as_erc20 = IERC20(address(vault));
        address this_contract = address(this);
        address user = msg.sender;

        uint user_balance = vault_as_erc20.balanceOf(user);
        require(vault_as_erc20.allowance(user, this_contract) >= user_balance, "approve LP tokens!");
        require(vault_as_erc20.transferFrom(user, this_contract, user_balance), "failed!");
        vault.withdraw(user_balance, user, maxLoss);
    }

    function withdraw_usdc(uint shares) external {
        IERC20 vault_as_erc20 = IERC20(address(vault));
        address this_contract = address(this);
        address user = msg.sender;

        require(vault_as_erc20.allowance(user, this_contract) >= shares, "approve LP tokens first!");
        require(vault_as_erc20.transferFrom(user, this_contract, shares), "transferFrom failed!");
        vault.withdraw(shares, user);
    }


    function withdraw_usdc(uint shares, uint maxLoss) external {
        IERC20 vault_as_erc20 = IERC20(address(vault));
        address this_contract = address(this);
        address user = msg.sender;

        require(vault_as_erc20.allowance(user, this_contract) >= shares, "approve LP tokens first!");
        require(vault_as_erc20.transferFrom(user, this_contract, shares), "transferFrom failed!");
        vault.withdraw(shares, user, maxLoss);
    }

}