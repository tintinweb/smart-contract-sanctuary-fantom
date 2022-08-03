// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ILlamaPay {
    function withdrawable(
        address from,
        address to,
        uint216 amountPerSecond
    )
        external
        view
        returns (
            uint256 withdrawableAmount,
            uint256 lastUpdate,
            uint256 owed
        );

    function withdraw(
        address from,
        address to,
        uint216 amountPerSecond
    ) external;
}

contract LlamaPayResolver {
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function checkWithdrawAvailable(
        address from,
        address to,
        uint216 amountPerSecond,
        address llamaPay,
        uint256 withdrawAt,
        uint256 maxGasPriceGwei
    ) external view returns (bool canExec, bytes memory execPayload) {
        (uint256 withdrawable, , ) = ILlamaPay(llamaPay).withdrawable(from, to, amountPerSecond);

        if (withdrawable < withdrawAt) return (false, bytes('Withdraw At not met'));
        if (tx.gasprice > (maxGasPriceGwei * 1 gwei)) return (false, bytes(string.concat('Gas too expensive: ', uint2str(tx.gasprice))));

        return (true, abi.encodeWithSelector(ILlamaPay.withdraw.selector, from, to, amountPerSecond));
    }
}