/**
 *Submitted for verification at FtmScan.com on 2022-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
}

contract arraytest {
    
    address public router = 0xA1B1742e9c32C7cAa9726d8204bD5715e3419861;
    IERC20 public usdc = IERC20(0xC42C30aC6Cc15faC9bD938618BcaA1a1FaE8501d);  // NEAR
    IERC20 public token = IERC20(0xC4bdd27c33ec7daa6fcfd8532ddB524Bf4038096); // LUNA
    IERC20 public pooltoken1 = IERC20(0x80A16016cC4A2E6a2CACA8a4a498b1699fF0f844); // AVAX
    IERC20 public pooltoken2 = IERC20(0x12c87331f086c3C926248f964f8702C0842Fd77F); // BRL

    address[] public tokenTousdc;
    address[] public tokenTopooltoken1;
    address[] public tokenTopooltoken2;

    address public owner;

    address proposedOwner = address(0);

    constructor() {
        owner = msg.sender;
                
        tokenTousdc = [address(token), address(usdc)];
        tokenTopooltoken1 = [address(token), address(pooltoken1)];
        tokenTopooltoken2 = [address(token), address(pooltoken1), address(pooltoken2)];
    }
    
    function inCaseTokensGetStuck(
        address _token
    ) public {
        require(msg.sender == owner, "inCaseTokensGetStuck");
        IERC20 t = IERC20(_token);
        uint256 balance = t.balanceOf(address(this));
        t.transfer(msg.sender, balance);
    }

    function setToken(address _token) public {
        require(msg.sender == owner);
        token = IERC20(_token);
    }

    function setPoolTokens(address _pooltoken1, address _pooltoken2) public {
        require(msg.sender == owner);
        pooltoken1 = IERC20(_pooltoken1);
        pooltoken2 = IERC20(_pooltoken2);
    }

    function setTokenToUSDC(address[] memory _tokenTousdc) public {
        require(msg.sender == owner);
        tokenTousdc = _tokenTousdc;
    }

    function setTokenToPooltoken1(address[] calldata _tokenTopooltoken1) public {
        require(msg.sender == owner);
        tokenTopooltoken1 = _tokenTopooltoken1;
    }

   function setTokenToPooltoken2(address[] memory _tokenTopooltoken2) public {
        require(msg.sender == owner);
        tokenTopooltoken2 = _tokenTopooltoken2;
    }

    function deleteElement(uint256 id) public {
        delete tokenTopooltoken2[id];
    }

    function deleteArray1() public {
        delete tokenTopooltoken1;
    }

    function deleteArray2() public {
        delete tokenTopooltoken2;
    }

    function getLength() public view returns (uint256, uint256) {
        return (tokenTopooltoken1.length, tokenTopooltoken2.length);
    }

    function changeOwner(address _owner) public {
        require(msg.sender == owner);
        proposedOwner = _owner;
    }
    
    function acceptOwnership() public {
        require(msg.sender == proposedOwner);
        owner = proposedOwner;
    }
}