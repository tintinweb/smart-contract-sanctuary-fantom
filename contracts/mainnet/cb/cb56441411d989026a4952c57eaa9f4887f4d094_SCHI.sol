/**
 *Submitted for verification at FtmScan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Developer: [email protected]

contract SCHI {

    event Received(address indexed sender, uint256 amount);
    event Reimbursements(address indexed insured, Reimbursement reimbursement, uint256 amount, uint256 id, bool completed);

    address public owner; // insurance company

    bytes32 public constant EIP712_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant NAME_TYPEHASH =
        keccak256(bytes(
            "Smart Contracts in Health Insurance"
        ));

    bytes32 public constant VERSION_TYPEHASH = 
        keccak256(
            bytes("1")
        );

    bytes32 public constant PRESCRIPTION_TYPEHASH =
        keccak256(
            "Prescription(address patient,address healthProfessional,string title,string data,uint256 date)"
        );

    bytes32 public constant CLAIM_TYPEHASH =
        keccak256(
            "Claim(address lastEntity,uint256 lastDate,uint256 fee,string feeInfo,Prescription prescription)Prescription(address patient,address healthProfessional,string title,string data,uint256 date)"
        );

    bytes32 public constant REIMBURSEWITHSIGNATURE_TYPEHASH = 
        keccak256(
            "ReimburseWithSignature(uint256 reimbursementId,address insured)"
        );

    struct Prescription {
        address patient;
        address healthProfessional;
        string title;
        string data;
        uint256 date;
    }

    struct Claim {
        address lastEntity;
        uint256 lastDate;
        uint256 fee;
        string feeInfo;
        Prescription prescription;
    }

    struct Reimbursement {
        Claim claim;
        address[] signers;
        bytes[] signatures;
        uint256 percentage;
        uint256 totalFee;
    }

    struct ReimburseWithSignature {
        uint256 reimbursementId;
        address insured;
    }

    mapping(uint256 => bool) public reimbursements;
    mapping(uint256 => string) public database; // used to store encoded data

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function getReimbursementId(
        Reimbursement memory reimbursement
    ) 
        public pure returns (uint256) 
    {
        return uint256(keccak256(abi.encode(reimbursement)));
    }

    function recoverHpAddress(
        Prescription memory prescription,
        bytes memory hpSignature
    )
        public view returns (address)
    {
        bytes32 _hash = getHash(
            keccak256(abi.encode(
                PRESCRIPTION_TYPEHASH,
                prescription.patient,
                prescription.healthProfessional,
                keccak256(bytes(prescription.title)),
                keccak256(bytes(prescription.data)),
                prescription.date
            ))
        );

        return recover(_hash, hpSignature);
    }

    function recoverAddress(
        Claim memory claim,
        bytes memory signature
    )
        public view returns (address) 
    {
        bytes32 _hash = getHash(
            keccak256(abi.encode(
                CLAIM_TYPEHASH,
                claim.lastEntity,
                claim.lastDate,
                claim.fee,
                keccak256(bytes(claim.feeInfo)),
                keccak256(abi.encode(
                    PRESCRIPTION_TYPEHASH,
                    claim.prescription.patient,
                    claim.prescription.healthProfessional,
                    keccak256(bytes(claim.prescription.title)),
                    keccak256(bytes(claim.prescription.data)),
                    claim.prescription.date
                ))
            ))
        );

        return recover(_hash, signature);
    }

    function recoverAddresses(
        Claim memory claim,
        bytes[] memory signatures
    )
        public view returns (address[] memory signers) 
    {
        signers = new address[](signatures.length); 

        bytes32 _hash = getHash(
            keccak256(abi.encode(
                CLAIM_TYPEHASH,
                claim.lastEntity,
                claim.lastDate,
                claim.fee,
                keccak256(bytes(claim.feeInfo)),
                keccak256(abi.encode(
                    PRESCRIPTION_TYPEHASH,
                    claim.prescription.patient,
                    claim.prescription.healthProfessional,
                    keccak256(bytes(claim.prescription.title)),
                    keccak256(bytes(claim.prescription.data)),
                    claim.prescription.date
                ))
            ))
        );

        for (uint i = 0; i < signatures.length; i++) {
            signers[i] = recover(_hash, signatures[i]);
        }    
    }

    function reimburseWithSignature(
        Reimbursement memory reimbursement,
        bytes memory signature
    )
        public
    {
        address insured = msg.sender;
        uint256 id = getReimbursementId(reimbursement);
        require(!reimbursements[id], "This claim has already been reimbursed");

        address[] memory signers = recoverAddresses(reimbursement.claim, reimbursement.signatures);

        require(
            keccak256(abi.encode(reimbursement.signers)) == 
            keccak256(abi.encode(signers)),
            "Fraud detected: Invalid Signatures"
        );

        bytes32 _hash = getHash(
            keccak256(abi.encode(
                REIMBURSEWITHSIGNATURE_TYPEHASH,
                id,
                insured
            ))
        );

        require(recover(_hash, signature) == owner, "Invalid owner signature");
        uint256 amount = (reimbursement.totalFee * reimbursement.percentage) / 100;

        require(address(this).balance >= amount, "Contract doesn't have enough balance!");

        (bool success, ) = payable(insured).call{value: amount}("");
        require(success, "Transfer of tokens will fail for unknown reasons");

        reimbursements[id] = true;
        emit Reimbursements(insured, reimbursement, amount, id, true);
    }

    function reimburse(
        Reimbursement memory reimbursement,
        bool completed,
        address insured
    )
        public payable onlyOwner
    {
        uint256 id = getReimbursementId(reimbursement);
        address[] memory signers = recoverAddresses(reimbursement.claim, reimbursement.signatures);

        require(
            keccak256(abi.encode(reimbursement.signers)) == 
            keccak256(abi.encode(signers)),
            "Fraud detected: Invalid Signatures"
        );

        require(!reimbursements[id], "This claim has already been reimbursed");

        uint256 amount = (reimbursement.totalFee * reimbursement.percentage) / 100;
        require(address(this).balance >= amount, "Contract doesn't have enough balance!");

        (bool success, ) = payable(insured).call{value: amount}("");
        require(success, "Transfer of tokens will fail for unknown reasons");

        reimbursements[id] = completed;
        emit Reimbursements(insured, reimbursement, amount, id, completed);
    }

    function store(uint256 index, string memory data) public onlyOwner {
        database[index] = data;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function getHash(
        bytes32 hashStruct
    )
        internal view returns (bytes32) 
    {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                EIP712_TYPEHASH,
                NAME_TYPEHASH,
                VERSION_TYPEHASH,
                block.chainid,
                address(this)
            )
        );

        return keccak256(
            abi.encodePacked(
                "\x19\x01", 
                eip712DomainHash, 
                hashStruct
            )
        );
    }

    function recover(
        bytes32 _hash, 
        bytes memory _signature
    )
        internal pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        return ecrecover(_hash, v, r, s);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}