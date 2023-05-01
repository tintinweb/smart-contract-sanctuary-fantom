/**
 *Submitted for verification at FtmScan.com on 2023-04-27
*/

contract S {
    struct CurveRoute {
        address[9] route;
        uint256[3][4] swapParams;
        uint minAmount; // minimum amount to be swapped to native
    }
    CurveRoute[] public curveRewards;

    function curveReward(uint i) external view returns (address[9] memory, uint256[3][4] memory, uint) {
        return (curveRewards[i].route, curveRewards[i].swapParams, curveRewards[i].minAmount);
    }

    function curveReward0(uint i) external view returns (CurveRoute memory) {
        return curveRewards[i];
    }

    function addReward(address[9] calldata _rewardToNativeRoute, uint[3][4] calldata _swapParams, uint _minAmount) external {
        address token = _rewardToNativeRoute[0];    
        curveRewards.push(CurveRoute(_rewardToNativeRoute, _swapParams, _minAmount));
    }
}