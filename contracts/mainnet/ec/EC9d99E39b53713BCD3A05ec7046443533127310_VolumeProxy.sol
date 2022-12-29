pragma solidity ^0.8.0;

contract VolumeProxy {

    address public immutable router;
    address public immutable WETH;
    bytes4 constant FUNC_SELECTOR = bytes4(keccak256(bytes('testSome(uint256)')));

    constructor(address _router,address _WETH){
        router = _router;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {

        //bytes4 FUNC_SELECTOR = bytes4(keccak256("swapExactTokensForTokens(uint,uint,address[],address,uint)"));

       // (bool success, bytes memory data) = router.call(abi.encodeWithSelector(FUNC_SELECTOR, amountIn, amountOutMin,path,to,deadline));
        (bool success, bytes memory data) = router.call(abi.encodeWithSelector(FUNC_SELECTOR, uint256(777)));

        // require(success && data.length > 0,'swap: SWAP_FAILED' );
        return abi.decode(data, (uint []));
    }
}