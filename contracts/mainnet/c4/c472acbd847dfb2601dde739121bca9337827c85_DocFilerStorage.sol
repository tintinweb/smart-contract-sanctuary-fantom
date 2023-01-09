/**
 *Submitted for verification at FtmScan.com on 2023-01-09
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

contract DocFilerStorage {
    type timestampID is bytes32;
    type recordID is bytes32;

    struct Hash {
        string hash_alg;
        string hash_val;
    }

    struct Timestamp {
        Hash hash;
        address timestamped_by;
        uint block_timestamp;
        uint block_number;
    }

    struct Record {
        string name;
        string value;
    }

    /** modify pageSize when it's lower than 0 or gt 30 */
    modifier adjustPagination(uint pageSize) {
        // assert pageSize is not too large
        require(pageSize <= PAGE_LIMIT, "Page size too large");
        _;
    }

    modifier requireOwner() {
        require(msg.sender == owner, "Not Authorized");
        _;
    }

    event TimestampAdded(timestampID timestamp_id, Timestamp timestamp);

    event RecordAdded(
        timestampID timestamp_id,
        recordID record_id,
        Record record
    );

    address private owner = msg.sender;
    mapping(timestampID => Timestamp) public timestampStore;
    mapping(recordID => Record) public recordStore;
    mapping(timestampID => recordID[]) public timestampRecordIdList;
    timestampID[] public timestampIDsList;
    uint public PAGE_LIMIT = 30;

    function getOwner() public view returns (address) {
        return owner;
    }

    function setOwner(address newOwner) public requireOwner {
        owner = newOwner;
    }

    function getPageLimit() public view returns (uint) {
        return PAGE_LIMIT;
    }

    function setPageLimit(uint newPageLimit) public requireOwner {
        PAGE_LIMIT = newPageLimit;
    }

    function computeTimestampID(Hash calldata _hash)
        public
        pure
        returns (timestampID)
    {
        return
            timestampID.wrap(
                keccak256(abi.encodePacked(_hash.hash_alg, _hash.hash_val))
            );
    }

    function addTimestamp(Hash calldata hash) public requireOwner {
        timestampID id = computeTimestampID(hash);
        timestampStore[id] = Timestamp(
            hash,
            msg.sender,
            block.timestamp,
            block.number
        );
        timestampIDsList.push(id);
        emit TimestampAdded(id, timestampStore[id]);
    }

    function addManyTimestamp(Hash[] calldata hashes) public requireOwner {
        for (uint i = 0; i < hashes.length; i++) {
            addTimestamp(hashes[i]);
        }
    }

    function getTimestampCount() public view returns (uint) {
        return timestampIDsList.length;
    }

    function getTimestamp(timestampID id)
        public
        view
        returns (Timestamp memory)
    {
        return timestampStore[id];
    }

    function getManyTimestamp(uint pageN, uint pageSize)
        public
        view
        adjustPagination(pageSize)
        returns (Timestamp[] memory)
    {
        uint start = pageN * pageSize;

        if (start > timestampIDsList.length) {
            // there'll be for sure no results
            return new Timestamp[](0);
        }
        uint end = start + pageSize;

        if (end > timestampIDsList.length) {
            // adjust to end at the last element if out of bounds
            end = timestampIDsList.length;
        }
        Timestamp[] memory timestamps = new Timestamp[](end - start);
        for (uint i = start; i < end; i++) {
            timestamps[i - start] = timestampStore[timestampIDsList[i]];
        }
        return timestamps;
    }

    function computeRecordID(timestampID timestamp_id, Record memory record)
        public
        pure
        returns (recordID)
    {
        return
            recordID.wrap(
                keccak256(abi.encodePacked(timestamp_id, record.name))
            );
    }

    function addRecord(timestampID timestamp_id, Record calldata record)
        public
        requireOwner
    {
        recordID record_id = computeRecordID(timestamp_id, record);
        recordStore[record_id] = record;
        timestampRecordIdList[timestamp_id].push(record_id);
        emit RecordAdded(timestamp_id, record_id, record);
    }

    function addManyRecord(timestampID timestamp_id, Record[] calldata records)
        public
        requireOwner
    {
        for (uint i = 0; i < records.length; i++) {
            addRecord(timestamp_id, records[i]);
        }
    }

    function getRecordCount(timestampID timestamp_id)
        public
        view
        returns (uint)
    {
        return timestampRecordIdList[timestamp_id].length;
    }

    function getRecord(recordID record_id) public view returns (Record memory) {
        return recordStore[record_id];
    }

    function getManyRecord(
        timestampID id,
        uint pageN,
        uint pageSize
    ) public view adjustPagination(pageSize) returns (Record[] memory) {
        uint start = pageN * pageSize;

        if (start > timestampRecordIdList[id].length) {
            // there'll be for sure no results
            return new Record[](0);
        }
        uint end = start + pageSize;

        if (end > timestampRecordIdList[id].length) {
            // adjust to end at the last element if out of bounds
            end = timestampRecordIdList[id].length;
        }
        Record[] memory records = new Record[](end - start);
        for (uint i = start; i < end; i++) {
            records[i - start] = recordStore[timestampRecordIdList[id][i]];
        }
        return records;
    }
}