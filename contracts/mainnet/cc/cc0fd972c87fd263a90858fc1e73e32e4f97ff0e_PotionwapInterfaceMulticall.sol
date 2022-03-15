/**
 *Submitted for verification at FtmScan.com on 2022-03-15
*/

// File: contracts/MultiCall.sol

//                                          ..      s       .                                   ..       .. 
//                                    x .d88"      :8      @88>                           x .d88"  x .d88"  
//    ..    .     :       x.    .      5888R      .88      %8P                             5888R    5888R   
//  .888: x888  x888.   [email protected]  z88u    '888R     :888ooo    .             .         u      '888R    '888R   
// ~`8888~'888X`?888f` ~"8888 ^8888     888R   -*8888888  [email protected]      .udR88N     us888u.    888R     888R   
//   X888  888X '888>    8888  888R     888R     8888    ''888E`    <888'888k [email protected] "8888"   888R     888R   
//   X888  888X '888>    8888  888R     888R     8888      888E     9888 'Y"  9888  9888    888R     888R   
//   X888  888X '888>    8888  888R     888R     8888      888E     9888      9888  9888    888R     888R   
//   X888  888X '888>    8888 ,888B .   888R    .8888Lu=   888E     9888      9888  9888    888R     888R   
//  "*88%""*88" '888!`  "8888Y 8888"   .888B .  ^%888*     888&     ?8888u../ 9888  9888   .888B .  .888B . 
//    `~    "    `"`     `Y"   'YP     ^*888%     'Y"      R888"     "8888P'  "888*""888"  ^*888%   ^*888%  
//                                       "%                 ""         "P'     ^Y"   ^Y'     "%       "%    
                                                                                                         
                                                                                                         
                                                                                                         


pragma solidity =0.7.6;
pragma abicoder v2;

/// @notice A fork of Multicall2 specifically tailored for the PotionSwap Interface
contract PotionwapInterfaceMulticall {
    struct Call {
        address target;
        uint256 gasLimit;
        bytes callData;
    }

    struct Result {
        bool success;
        uint256 gasUsed;
        bytes returnData;
    }

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function multicall(Call[] memory calls) public returns (uint256 blockNumber, Result[] memory returnData) {
        blockNumber = block.number;
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (address target, uint256 gasLimit, bytes memory callData) =
                (calls[i].target, calls[i].gasLimit, calls[i].callData);
            uint256 gasLeftBefore = gasleft();
            (bool success, bytes memory ret) = target.call{gas: gasLimit}(callData);
            uint256 gasUsed = gasLeftBefore - gasleft();
            returnData[i] = Result(success, gasUsed, ret);
        }
    }
}