pragma solidity = 0.6.12; //dexes use 0.6.12, version issues?

//import exchange routers and ERC20 interfaces
import './ISpookyRouter.sol';
import './ISpiritRouter.sol';
import './IERC20.sol';


//For now set up stricly for trading X to Y on Spookyswap then Y to X on Spiritswap
contract arbTx {

	address private owner;

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	address spookyRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
	address spiritRouterAddress = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

	//_amountIn0 is initial input  in fUSDT, _amountOutMin0 is min from first trade to wFTM, _amountOutMin1 is min from second trade back to fUSDT
	function arb(uint _amountIn0, uint _amountOutMin0, uint _amountOutMin1, address[] calldata _firstSwapPath, address[] calldata _secondSwapPath) external onlyOwner {

		uint[] memory _nextInput = spookyRouter(spookyRouterAddress).swapExactTokensForTokens(_amountIn0, _amountOutMin0, _firstSwapPath, address(this), block.timestamp);
		// if output is not greater than initial input, tx fails
		spiritRouter(spiritRouterAddress).swapExactTokensForTokens(_nextInput[1], _amountOutMin0, _secondSwapPath, address(this), block.timestamp);
	}

	//need to approve router contracts before calling arb
	function approveTokens(address _token, address _address, uint _amount) onlyOwner external {
		IERC20(_token).approve(_address, _amount);
	}

	//withdraw tokens from contract
	function withdrawTokens(uint _amount, address _token) onlyOwner external {
		IERC20(_token).transfer(msg.sender, _amount);
	}
	
}

pragma solidity = 0.6.12;

interface spookyRouter {
	function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

pragma solidity = 0.6.12;

interface spiritRouter {
	function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

pragma solidity >=0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}