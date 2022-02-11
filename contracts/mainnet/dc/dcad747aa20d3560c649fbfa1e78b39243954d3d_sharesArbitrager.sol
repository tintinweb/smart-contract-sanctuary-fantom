/**
 *Submitted for verification at FtmScan.com on 2022-02-11
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
    function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

contract sharesArbitrager {
    address public owner;
    IERC20 public WFTM = IERC20(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20 public USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
    IRouter public Spooky = IRouter(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    IRouter public Spirit = IRouter(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);

    constructor() {
        owner = msg.sender;
        WFTM.approve(address(Spooky), 2 ** 256 - 1);
        WFTM.approve(address(Spirit), 2 ** 256 - 1);
        USDC.approve(address(Spooky), 2 ** 256 - 1);
        USDC.approve(address(Spirit), 2 ** 256 - 1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Caller is not the deployer");
        _;
    }

    function arbitrageSpookyShares(address _token1, address _token2) public onlyOwner {
        require(WFTM.balanceOf(address(this)) > 0, "Insufficient WFTM balance");
        IERC20 STABLE = IERC20(_token1);
        IERC20 SHARES = IERC20(_token2);

        address[] memory pathToStable = new address[](2);
        pathToStable[0] = address(WFTM);
        pathToStable[1] = address(STABLE);

        address[] memory pathStableToShares = new address[](2);
        pathStableToShares[0] = address(STABLE);
        pathStableToShares[1] = address(SHARES);

        address[] memory pathToWFTM = new address[](2);
        pathToWFTM[0] = address(SHARES);
        pathToWFTM[1] = address(WFTM);

        Spooky.swapExactTokensForTokens(
            WFTM.balanceOf(address(this)),
            0,
            pathToStable,
            address(this),
            (block.timestamp + 1200)
        );
        Spooky.swapExactTokensForTokens(
            STABLE.balanceOf(address(this)),
            0,
            pathStableToShares,
            address(this),
            (block.timestamp + 1200)
        );
        Spooky.swapExactTokensForTokens(
            SHARES.balanceOf(address(this)),
            0,
            pathToWFTM,
            address(this),
            (block.timestamp + 1200)
        );
    }

    function arbitrageSpiritShares(address _token1, address _token2) public onlyOwner {
        require(WFTM.balanceOf(address(this)) > 0, "Insufficient WFTM balance");
        IERC20 STABLE = IERC20(_token1);
        IERC20 SHARES = IERC20(_token2);

        address[] memory pathToStable = new address[](2);
        pathToStable[0] = address(WFTM);
        pathToStable[1] = address(STABLE);

        address[] memory pathStableToShares = new address[](2);
        pathStableToShares[0] = address(STABLE);
        pathStableToShares[1] = address(SHARES);

        address[] memory pathToWFTM = new address[](2);
        pathToWFTM[0] = address(SHARES);
        pathToWFTM[1] = address(WFTM);

        Spirit.swapExactTokensForTokens(
            WFTM.balanceOf(address(this)),
            0,
            pathToStable,
            address(this),
            (block.timestamp + 1200)
        );
        Spirit.swapExactTokensForTokens(
            STABLE.balanceOf(address(this)),
            0,
            pathStableToShares,
            address(this),
            (block.timestamp + 1200)
        );
        Spirit.swapExactTokensForTokens(
            SHARES.balanceOf(address(this)),
            0,
            pathToWFTM,
            address(this),
            (block.timestamp + 1200)
        );
    }

        function arbitrageCustomShares(address _router, address _token1, address _token2) public onlyOwner {
        require(WFTM.balanceOf(address(this)) > 0, "Insufficient WFTM balance");
        IRouter Router = IRouter(_router);
        IERC20 STABLE = IERC20(_token1);
        IERC20 SHARES = IERC20(_token2);

        address[] memory pathToStable = new address[](2);
        pathToStable[0] = address(WFTM);
        pathToStable[1] = address(STABLE);

        address[] memory pathStableToShares = new address[](2);
        pathStableToShares[0] = address(STABLE);
        pathStableToShares[1] = address(SHARES);

        address[] memory pathToWFTM = new address[](2);
        pathToWFTM[0] = address(SHARES);
        pathToWFTM[1] = address(WFTM);

        Router.swapExactTokensForTokens(
            WFTM.balanceOf(address(this)),
            0,
            pathToStable,
            address(this),
            (block.timestamp + 1200)
        );
        Router.swapExactTokensForTokens(
            STABLE.balanceOf(address(this)),
            0,
            pathStableToShares,
            address(this),
            (block.timestamp + 1200)
        );
        Router.swapExactTokensForTokens(
            SHARES.balanceOf(address(this)),
            0,
            pathToWFTM,
            address(this),
            (block.timestamp + 1200)
        );
    }

    function approveTokens(address _token1) public onlyOwner {
        IERC20 token1 = IERC20(_token1);

        token1.approve(address(Spooky), 2 ** 256 - 1);
        token1.approve(address(Spirit), 2 ** 256 - 1);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "Arb: external call failed");
        return result;
    }

    function withdrawTokensFromContract(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }
}