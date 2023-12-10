// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "hardhat/console.sol";

contract PayWalletV1 is Ownable {
    using ECDSA for bytes32;
    using Address for address;
    using SafeERC20 for IERC20;

    bytes32 private cardCode;
    address private cardKey;
    address private  immutable tokenAddress;

    Transaction[] public transactions;

    /*********** MODIFIER ********************************/
    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );

    enum StateTransaction {
        START,
        SUBMITED,
        EXECUTED,
        CANCELED
    }

    struct Transaction {
        address to;
        address tokenAddress;
        uint value;
        bytes message;
        bytes signature;
        bool executed;
        uint numConfirmations;
    }

    /*************************EVENTS *****************************************/
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    constructor(
        address key,
        address ownerAddr,
        address tokenAddr
    ) Ownable(ownerAddr) {
        cardKey = key;
        tokenAddress = tokenAddr;
        _transferOwnership(ownerAddr);
    }

    function getMessageHash(
        address to,
        uint256 amount,
        string memory message,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, amount, message, nonce));
    }

    function getEthSignedMessageHash(
        bytes32 messageHash
    ) public pure returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(messageHash);
    }

    function recoverSigner(
        bytes memory message,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 ethMesgHash = MessageHashUtils.toEthSignedMessageHash(message);

        address receivedAddress = ECDSA.recover(ethMesgHash, signature);
        return receivedAddress;
    }

    function pay(
        address to,
        uint256 amount,
        bytes memory signature,
        bytes memory message
    ) public payable {
        address paydAddress = recoverSigner(message, signature);
        console.log("Pay recover", Strings.toHexString(paydAddress));
        require(paydAddress == cardKey, "invalid signature");
        IERC20(tokenAddress).safeTransfer(to, amount);
    }

    /////////////////////////////

    /**
     *
     *  Only Seller Send transaction  - verify
     *  Verify balance of card
     *  Lock balance
     */
    function submitTransaction(
        address _to,
        address _tokenAddress,
        uint _value,
        bytes memory signature,
        bytes memory message
    ) public {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                tokenAddress: _tokenAddress,
                value: _value,
                signature: signature,
                message: message,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, message);
    }

    function getTransaction(
        uint _txIndex
    )
        public
        view
        returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.signature,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function revokeConfirmation(
        uint _txIndex
    ) public txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        //require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");
        //transaction.numConfirmations -= 1;
        //isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    function confirmTransaction(
        uint _txIndex,
        bytes memory signatureCode
    ) public txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        //transaction.numConfirmations += 1;

        //isConfirmed[_txIndex][msg.sender] = true;

        /* address to,
        uint256 amount,
        bytes memory signature,
        bytes memory message
       // pay(transaction.to,transaction.amount,transaction.)

        */
        emit ConfirmTransaction(msg.sender, _txIndex);
    }
}
