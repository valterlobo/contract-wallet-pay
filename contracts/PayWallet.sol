// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./PayWalletLibrary.sol";
import "hardhat/console.sol";

contract PayWallet is Ownable {
    bytes private cardCode;
    address private cardKey;
    mapping(uint256 => PayWalletLibrary.Transaction) public transactions;
    uint256[] idxTransactions;

    constructor(
        bytes memory hashCode,
        bytes memory signedCode,
        address key,
        address ownerAddr
    ) Ownable(ownerAddr) {
        cardKey = key;
        cardCode = hashCode;

        if (ownerAddr != PayWalletLibrary.recoverSigner(hashCode, signedCode)) {
            revert PayWalletLibrary.NotSigner(ownerAddr, hashCode, signedCode);
        }
    }

    /**
     *
     *  Only Seller Send transaction  - verify
     *  Verify balance of card
     *  Lock balance
     */
    function submitTransaction(
        uint256 id,
        address to,
        address tokenAddress,
        uint value,
        bytes memory signatureSeller,
        bytes memory signature,
        bytes memory message
    ) public {

        if (existsTransaction(id)) {
            revert PayWalletLibrary.TransactionExist(id);
        }

        address payAddress = PayWalletLibrary.recoverSigner(message, signature);

        address sellerAddress = PayWalletLibrary.recoverSigner(
            message,
            signatureSeller
        );

        console.log("Pay recover", Strings.toHexString(payAddress));
        console.log("Seller recover", Strings.toHexString(sellerAddress));
        console.log("SENDER        ", Strings.toHexString(msg.sender));

        if (payAddress != cardKey) {
            revert PayWalletLibrary.NotSigner(payAddress, message, signature);
        }

        if (sellerAddress != msg.sender) {
            revert PayWalletLibrary.NotSigner(
                sellerAddress,
                message,
                signatureSeller
            );
        }

        //check value 

        transactions[id] = PayWalletLibrary.Transaction({
            id: id,
            to: to,
            tokenAddress: tokenAddress,
            value: value,
            message: message,
            signature: signature,
            signatureSeller: signatureSeller,
            state: PayWalletLibrary.StateTransaction.START,
            timeExecuted: block.timestamp
        });

        //TODO EVENT
    }

    function getTransaction(
        uint256 id
    ) public view returns (PayWalletLibrary.Transaction memory) {

        if (!existsTransaction(id)) {
            revert PayWalletLibrary.TransactionNotExist((id));
        }
        
        return transactions[id];
    }

    function existsTransaction(uint256 id) public view returns (bool) {
        return transactions[id].id != 0;
    }
}
