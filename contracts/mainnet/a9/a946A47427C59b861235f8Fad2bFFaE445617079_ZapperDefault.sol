pragma solidity ^0.8.12;
import "./ZapperBase.sol";

contract ZapperDefault is ZapperBase {
    function unzip(
        IERC20ForZapper token,
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

interface IERC20ForZapper {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

abstract contract ZapperBase {
    function unzip(
        IERC20ForZapper token,
        uint256 amount,
        address account,
        bytes32[] memory params
    ) external virtual;
}