/**
 *Submitted for verification at FtmScan.com on 2022-11-06
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

/**
 * @title Interface for ERC20 token contracts.
 * @dev https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract AcuityRPC {

    function getAccountBalances(address[] calldata accounts)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](accounts.length);

        for (uint i = 0; i != accounts.length; i++) {
            values[i] = accounts[i].balance;
        }
    }

    function getStaticTokenMetadata(ERC20 token)
        view
        external
        returns (string memory name, string memory symbol, uint decimals)
    {
        name = token.name();
        symbol = token.symbol();
        decimals = token.decimals();
    }

    function getTokenAccountBalances(ERC20 token, address[] calldata accounts)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](accounts.length);

        for (uint i = 0; i != accounts.length; i++) {
            values[i] = token.balanceOf(accounts[i]);
        }
    }

    function getAccountTokenBalances(address account, ERC20[] calldata tokens)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](tokens.length);

        for (uint i = 0; i != tokens.length; i++) {
            values[i] = tokens[i].balanceOf(account);
        }
    }

    function getAccountTokenAllowances(address account, address spender, ERC20[] calldata tokens)
        view
        external
        returns (uint[] memory values)
    {
        values = new uint[](tokens.length);

        for (uint i = 0; i != tokens.length; i++) {
            values[i] = tokens[i].allowance(account, spender);
        }
    }

}