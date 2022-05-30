/**
 *Submitted for verification at FtmScan.com on 2022-05-29
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.11;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return payable(account);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

/*interface Claimer {
    function claimToken(address _to, address _token) external payable returns (uint256 amount);
}*/

contract ClaimTokens {
    using SafeERC20 for IERC20;

    address public owner;
    uint256 public totalClaims = 0;
    mapping(string => uint256) public amountPerCourse;
    mapping(string => address) public tokenForCourse;
    mapping(address => mapping(string => bool)) public courseCompleted;
    bytes32 private authString;

    constructor() {
        owner = msg.sender;
    }

    // Function used to claim funds. Although accessible by everyone, not everyone can just claim funds.
    // authString will be updated regularly but string won't be stored as is.
    // SHA256 hash will be stored leading to only a one-way check without allowing easy backtracking from hash.
    function claim(
        string memory _course,
        string memory _checkAuthencity
    ) external payable {
        require(!courseCompleted[msg.sender][_course], "Cannot claim amount for same course twice");
        require(sha256(abi.encodePacked(_checkAuthencity)) == authString, "Access To Method Not Allowed");
        IERC20(tokenForCourse[_course]).safeTransfer(msg.sender, amountPerCourse[_course]);
        courseCompleted[msg.sender][_course] = true;
        totalClaims += 1;
    }

    // Owner functions
    function setCourseClaimAmounts(string memory _course, address _token, uint256 _amount) external {
        require(msg.sender == owner, "Access To Method Not allowed");
        amountPerCourse[_course] = _amount;
        tokenForCourse[_course] = _token;
    }

    function emergencyRescueERC20(address token) external {
        require(msg.sender == owner, "Access To Method Not allowed");

        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner, amount);
    }

    function setAuthencity(string memory _value) external returns (bytes32 _sha256Encoded) {
        require(msg.sender == owner, "Access To Method Not allowed");
        authString = sha256(abi.encodePacked(_value));
        _sha256Encoded = authString;
        return _sha256Encoded;
    }

}