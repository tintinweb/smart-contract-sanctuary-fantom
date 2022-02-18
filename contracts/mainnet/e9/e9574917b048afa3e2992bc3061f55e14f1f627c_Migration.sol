/**
 *Submitted for verification at FtmScan.com on 2022-02-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface OldCard {
    function exists(uint256 id) external view returns (bool);

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

interface NewCard {
    function mintBatch(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external;
}

contract Migration is Ownable {
    using Address for address;

    address oldCardAddress = 0x5A91EeF74683DE4d647F2847e15bE9192Df2CceB;
    address newCardAddress = 0xa95D7adEcb3349b9e98e87C14726aFa53511a38D;

    OldCard oldCard = OldCard(oldCardAddress);
    NewCard newCard = NewCard(newCardAddress);

    address[] public holderAddresses;
    uint256[] public tokenIds;

    constructor() {
        for (uint256 i = 0; i < 236; i++) {
            tokenIds.push(i + 1);
        }
    }

    struct Data {
        uint256[] tokenAmounts;
    }

    mapping(address => Data) private data;

    function assignHolders(address[] memory _to) public onlyOwner {
        holderAddresses = _to;
    }

    function getHowManyOfEachTokenTheHolderHave1(address _address)
        public
        onlyOwner
    {
        for (uint256 a = 0; a < tokenIds.length / 2; a++) {
            uint256 _tokenAmountOfSpecificId = oldCard.balanceOf(
                _address,
                tokenIds[a]
            );

            data[_address].tokenAmounts.push(_tokenAmountOfSpecificId);
        }
    }

    function getHowManyOfEachTokenTheHolderHave2(address _address)
        public
        onlyOwner
    {
        for (uint256 a = tokenIds.length / 2; a < tokenIds.length; a++) {
            uint256 _tokenAmountOfSpecificId = oldCard.balanceOf(
                _address,
                tokenIds[a]
            );

            data[_address].tokenAmounts.push(_tokenAmountOfSpecificId);
        }
    }

    function getFirstSliceOfHowManyOfEachTokenTheHolderHave(address _to)
        public
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory firstSlice = new uint256[](tokenIds.length / 2);
        for (uint256 i = 0; i < tokenIds.length / 2; i++) {
            firstSlice[i] = data[_to].tokenAmounts[i];
        }
        return firstSlice;
    }

    function getSecondSliceOfHowManyOfEachTokenTheHolderHave(address _to)
        public
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory secondSlice = new uint256[](tokenIds.length / 2);
        for (uint256 i = tokenIds.length / 2; i < tokenIds.length / 2; i++) {
            secondSlice[i] = data[_to].tokenAmounts[i];
        }
        return secondSlice;
    }

    function getFirstSliceOfTotalUniqueTokens()
        public
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory firstSlice = new uint256[](tokenIds.length / 2);
        for (uint256 i = 0; i < tokenIds.length / 2; i++) {
            firstSlice[i] = tokenIds[i];
        }
        return firstSlice;
    }

    function getSecondSliceOfTotalUniqueTokens()
        public
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory secondSlice = new uint256[](tokenIds.length / 2);
        for (uint256 i = tokenIds.length / 2; i < tokenIds.length; i++) {
            secondSlice[i] = tokenIds[i];
        }
        return secondSlice;
    }

    function mintBatchAirdrop1(address _to) public onlyOwner {
        newCard.mintBatch(
            _to,
            getFirstSliceOfTotalUniqueTokens(),
            getFirstSliceOfHowManyOfEachTokenTheHolderHave(_to)
        );
    }

    function mintBatchAirdrop2(address _to) public onlyOwner {
        newCard.mintBatch(
            _to,
            getSecondSliceOfTotalUniqueTokens(),
            getSecondSliceOfHowManyOfEachTokenTheHolderHave(_to)
        );
    }
}