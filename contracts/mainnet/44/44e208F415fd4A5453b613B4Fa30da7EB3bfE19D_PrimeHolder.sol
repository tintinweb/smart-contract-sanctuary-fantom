pragma solidity ^0.8.0;

interface IERC20ForHolder {
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external;
}

contract PrimeHolder {

    event ProfitsMade(address indexed maker, uint usdAmount);

    address _admin;

    constructor () {
        _admin = msg.sender;
    }


    function onPoolFee(address token, uint amount, uint lpAmount, address maker) external returns (uint) {
        emit ProfitsMade(maker, amount);

        return 0;
    }

    function sweepToken(IERC20ForHolder token) external {
        require(msg.sender == _admin, "Only admin");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(_admin, balance);
    }
}