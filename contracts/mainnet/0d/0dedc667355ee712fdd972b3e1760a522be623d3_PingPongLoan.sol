/**
 *Submitted for verification at FtmScan.com on 2023-03-20
*/

//SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint8);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

interface IFlashLoanReceiver {
    function onBorrow(
        IERC20 lentStablecoin,
        IERC20 repaymentStablecoin,
        uint256 loanAmount,
        uint256 minRepaymentAmount,
        bytes calldata params
    ) external;
}

contract PingPongLoan {
    using SafeMath for uint256;

    address public owner;

    struct stablecoin {
        bool lendable;
        bool repayable;
    }

    mapping(IERC20 => stablecoin) public stablecoins;

    constructor(IERC20[] memory _stablecoins) {
        for (uint8 i = 0; i < _stablecoins.length; i++) {
            stablecoins[_stablecoins[i]].lendable = true;
            stablecoins[_stablecoins[i]].repayable = true;
        }
        owner = msg.sender;
    }

    function stablecoinInfo(IERC20 _stablecoin)
        public
        view
        returns (bool lendable, bool repayable)
    {
        lendable = stablecoins[_stablecoin].lendable;
        repayable = stablecoins[_stablecoin].repayable;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function."
        );
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "New owner cannot be the zero address."
        );
        require(_newOwner != owner, "New owner cannot be the current owner.");
        owner = _newOwner;
    }

    function deposit(IERC20 _stablecoin, uint256 amount) external {
        require(
            stablecoins[_stablecoin].lendable,
            "Stablecoin not yet lendable"
        );
        _stablecoin.transferFrom(msg.sender, address(this), amount);
    }

    function depositAll(IERC20 _stablecoin) external {
        require(
            stablecoins[_stablecoin].lendable,
            "Stablecoin not yet lendable"
        );
        uint256 balance = _stablecoin.balanceOf(address(this));
        _stablecoin.transferFrom(msg.sender, address(this), balance);
    }

    function withdraw(IERC20 _stablecoin, uint256 amount) public onlyOwner {
        uint256 balance = _stablecoin.balanceOf(address(this));
        require(balance >= amount, "Insufficient balance");
        _stablecoin.transfer(msg.sender, amount);
    }

    function withdrawAll(IERC20 _stablecoin) external onlyOwner {
        uint256 balance = _stablecoin.balanceOf(address(this));
        require(balance > 0, "Insufficient balance");
        withdraw(_stablecoin, balance);
    }

    function loan(
        IERC20 lentStablecoin,
        IERC20 repaymentStablecoin,
        uint256 loanAmount,
        bytes calldata params
    ) external {
        require(
            stablecoins[lentStablecoin].lendable,
            "Stablecoin is not lendable."
        );

        // Check if the contract has enough balance to loan
        require(
            lentStablecoin.balanceOf(address(this)) >= loanAmount,
            "Insufficient balance"
        );

        // Transfer the stablecoins to the borrower
        lentStablecoin.transfer(msg.sender, loanAmount);


        // Calculate the minimum balance needed to be added to the current balance
        uint minRepaymentAmount = calculateRepayment(
            repaymentStablecoin,
            loanAmount
        );
        
        // Get the current balance of the repayment. 
        // This will avoid needing to transferFrom the borrower contract, and forcing an additional transfer to grow the loan.
        uint preBalance = IERC20(repaymentStablecoin).balanceOf(address(this));

        // We reweight the preBalance to prevent any precision loss that could allow a decimal steal...
        // That is repaying in an amount of lower decimals which would provide the lender a significant discount at high quantities lent....
        // When borrowing from a quantity in higher decimals.
        preBalance = preBalance.mul(lentStablecoin.decimals());

        //By combining both quantities, we can simply compare the balance to this new amount after lending. 
        minRepaymentAmount = preBalance.add(minRepaymentAmount);

        // Call the callback function on the borrower's contract
        IFlashLoanReceiver(msg.sender).onBorrow(
            lentStablecoin,
            repaymentStablecoin,
            loanAmount,
            minRepaymentAmount,
            params
        );

        // Runs some checks to authorize the 
        verifyPayment(lentStablecoin, repaymentStablecoin, minRepaymentAmount);
    }

    function verifyPayment(IERC20 lentStablecoin, IERC20 repaymentStablecoin, uint minRepaymentBalance)
        private view
    {
        // Check if the repayment stablecoin is accepted by the contract
        require(
            stablecoins[repaymentStablecoin].repayable,
            "Repayment stablecoin not accepted"
        );

        // Get the current repaid balance
        uint repaymentBalance = repaymentStablecoin.balanceOf(address(this)).mul(lentStablecoin.decimals());

        // Check if the repayment amount is at least equal to the initial loan amount by calculating the true amount of the loan.
        require(repaymentBalance >= minRepaymentBalance, "Insufficient repayment");
    }

    function calculateRepayment(
        IERC20 repaymentStablecoin,
        uint256 loanAmount
    ) public view returns (uint256 minRepaymentAmount) {
        // This is some funky math to approximate the repayment amount by adding the repaymentStablecoin's decimls
        minRepaymentAmount = loanAmount.mul(repaymentStablecoin.decimals());
    }

    function modifyStablecoin(
        bool _lendable,
        bool _repayable,
        IERC20 _stablecoin
    ) public onlyOwner {
        stablecoins[_stablecoin].lendable = _lendable;
        stablecoins[_stablecoin].repayable = _repayable;
    }
}