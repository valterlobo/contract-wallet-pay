// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library PayWalletLibrary {

    using ECDSA for bytes32;
    using Address for address;

    // =========  ERRORS ========= //
    error NotSigner(address signer, bytes hash, bytes signature);
    error TransactionExist(uint256 id);
    error TransactionNotExist(uint256 id);


    enum StateTransaction {
        START,
        SUBMITED,
        EXECUTED,
        CANCELED
    }

    struct Transaction {
        uint256 id; 
        address to;
        address tokenAddress;
        uint value;
        bytes message;
        bytes signature;
        bytes signatureSeller; 
        StateTransaction state; 
        uint256 timeExecuted; 
    }

    function recoverSigner(
        bytes memory message,
        bytes memory signature
    ) public pure returns (address) {

        bytes32 ethMesgHash = MessageHashUtils.toEthSignedMessageHash(message);
        address receivedAddress = ECDSA.recover(ethMesgHash, signature);
        return receivedAddress;

    }
}
