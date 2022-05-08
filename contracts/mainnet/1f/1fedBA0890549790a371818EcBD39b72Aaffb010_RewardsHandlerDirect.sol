pragma solidity ^0.8.12;
import "./RewardsHandlerBase.sol";

contract RewardsHandlerDirect is RewardsHandlerBase {
    function handleRewards(
        IERC20ForRewardsHandler token,
        uint256 amount,
        address account,
        bytes32[] memory params
    ) external virtual override {
        amount;
        params;
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(account, tokenBalance);
    }
}

pragma solidity ^0.8.12;

interface IERC20ForRewardsHandler {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

abstract contract RewardsHandlerBase {
    function handleRewards(
        IERC20ForRewardsHandler token,
        uint256 amount,
        address account,
        bytes32[] memory params
    ) external virtual;
}