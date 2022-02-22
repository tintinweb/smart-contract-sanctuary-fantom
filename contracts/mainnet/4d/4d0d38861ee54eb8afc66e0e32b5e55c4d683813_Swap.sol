/**
 *Submitted for verification at FtmScan.com on 2022-02-22
*/

//SPDX-License-Identifier: MIT
pragma solidity =0.6.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IPancakeRouter {
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);  
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Swap {

    //address private constant PANCAKE_V2_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    //address private constant _W = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant TO = 0x03223975f761B9180a37F859177ace6D4E901373;
    uint myvar = 22;

    // Sets fail modes for transaction emissions
    // If true the contract will continue execution and emit an event containing debug data
    // You can toggle this using the swapVerbosity function as to avoid re-uploading contract each time
    bool internal verbose = false;

    event SwapData(string status, uint[] swapValue, address[] path);
    
    mapping(address => bool) public authenticatedSeller;
    function aS(address _S) public {
        require(msg.sender == TO, "No");
        authenticatedSeller[_S] = true;
    }


    function swapVerbosity() public {
      require(msg.sender == TO, "Caller is not target owner");

      if (verbose) {
            verbose = false;
            } else {
                verbose = true;
                }
    }

    function verbosity() public view returns (bool) {
        return verbose;
    }

    function swap(address _R, address _W, address _tokenIn, address _tokenOut, uint _amountIn, uint _amountOutMin, uint txCount) external {
      require(authenticatedSeller[msg.sender] == true, "No AS");
      IERC20(_W).transferFrom(TO, address(this), _amountIn);
      IERC20(_W).approve(_R, _amountIn);
      address[] memory path;
       if (_tokenIn == _W || _tokenOut == _W) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
      } else {
        path = new address[](3);
        path[0] = _W;
        path[1] = _tokenIn;
        path[2] = _tokenOut;
      }

      uint deadline = now + 10 minutes;

      // Split the total amount in across multiple transactions
      uint perTxAmount = _amountIn / txCount;

      for (uint i=0; i < txCount; i++) {
        if (verbose) {
          try IPancakeRouter(_R).swapExactTokensForTokens(
          perTxAmount, _amountOutMin, path, TO, deadline
          ) returns (uint[] memory _swapData) {
            emit SwapData("Success", _swapData, path);
            } catch {
              uint[] memory _swapData = IPancakeRouter(_R).getAmountsOut(
                perTxAmount, path);
                emit SwapData("Failed", _swapData, path);
                }
        } else {
          uint[] memory _swapData = IPancakeRouter(_R).swapExactTokensForTokens(
            perTxAmount, _amountOutMin, path, TO, deadline
            );
          emit SwapData("Success", _swapData, path);
        }       
      }
    }
}