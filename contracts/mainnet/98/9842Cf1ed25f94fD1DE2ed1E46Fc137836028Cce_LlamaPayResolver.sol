// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ILlamaPay {
    function withdrawable(
        address from,
        address to,
        uint216 amountPerSecond
    ) external view returns (uint256 withdrawableAmount, uint256 lastUpdate, uint256 owed);

    function withdraw(
        address from,
        address to,
        uint216 amountPerSecond
    ) external;
}

contract LlamaPayResolver {
    function checkWithdrawAvailable(
        address from,
        address to,
        uint216 amountPerSecond,
        address llamaPay,
        uint256 withdrawAt,
        uint256 maxGasPriceGwei
    ) external view returns (bool canExec, bytes memory execPayload) {
        (uint256 withdrawable,,) = ILlamaPay(llamaPay).withdrawable(from, to, amountPerSecond);

        if (withdrawable < withdrawAt) return (false, bytes('Withdraw At not met'));
        if (tx.gasprice > (maxGasPriceGwei * 1 gwei)) return (false, bytes('Gas too expensive'));

        return (true, abi.encodeWithSelector(ILlamaPay.withdraw.selector, from, to, amountPerSecond));
    }
}