// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PayWalletLibrary.sol";
import "hardhat/console.sol";

contract PayWallet is Ownable {
    using SafeERC20 for IERC20;

    bytes private cardCode;
    address private cardKey;
    mapping(uint256 => PayWalletLibrary.Transaction) public transactions;
    uint256[] idxTransactions; //TODO IDX ID transactions

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

        if (IERC20(tokenAddress).balanceOf(address(this)) < value) {
            revert PayWalletLibrary.InsufficientBalance(tokenAddress, value);
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

        transactions[id] = PayWalletLibrary.Transaction({
            id: id,
            to: to,
            tokenAddress: tokenAddress,
            value: value,
            message: message,
            signature: signature,
            signatureSeller: signatureSeller,
            state: PayWalletLibrary.StateTransaction.SUBMITED,
            timeExecuted: block.timestamp
        });

        //TODO EVENT
    }

    function cancelTransaction(uint256 id) external {
        if (!existsTransaction(id)) {
            revert PayWalletLibrary.TransactionNotExist((id));
        }

        PayWalletLibrary.Transaction storage transaction = transactions[id];

        if (cardKey != msg.sender) {
            revert PayWalletLibrary.TransactionNotCard(msg.sender);
        }

        if (transaction.state != PayWalletLibrary.StateTransaction.SUBMITED) {
            revert PayWalletLibrary.TransactionFinish((id));
        }

        transaction.state = PayWalletLibrary.StateTransaction.CANCELED;
    }

    function confirmTransaction(
        uint256 id,
        bytes memory signatureCode
    ) external {
        if (!existsTransaction(id)) {
            revert PayWalletLibrary.TransactionNotExist((id));
        }

        PayWalletLibrary.Transaction storage transaction = transactions[id];

        if (cardKey != msg.sender) {
            revert PayWalletLibrary.TransactionNotCard(msg.sender);
        }

        if (
            transaction.state == PayWalletLibrary.StateTransaction.CANCELED ||
            transaction.state == PayWalletLibrary.StateTransaction.EXECUTED
        ) {
            revert PayWalletLibrary.TransactionFinish((id));
        }

        if (
            IERC20(transaction.tokenAddress).balanceOf(address(this)) <
            transaction.value
        ) {
            revert PayWalletLibrary.InsufficientBalance(
                transaction.tokenAddress,
                transaction.value
            );
        }

        if (keccak256(signatureCode) != keccak256(cardCode)) {
            revert PayWalletLibrary.InvalidCode(id, signatureCode);
        }

        IERC20(transaction.tokenAddress).safeTransfer(
            transaction.to,
            transaction.value
        );
        transaction.state = PayWalletLibrary.StateTransaction.EXECUTED;
        transaction.timeExecuted = block.timestamp;
    }

    function getTransaction(
        uint256 id
    ) external view returns (PayWalletLibrary.Transaction memory) {
        if (!existsTransaction(id)) {
            revert PayWalletLibrary.TransactionNotExist((id));
        }

        return transactions[id];
    }

    function withdraw(uint256 amount, address tokenAddress) external onlyOwner {
        if (IERC20(tokenAddress).balanceOf(address(this)) > amount) {
            revert PayWalletLibrary.InsufficientBalance(tokenAddress, amount);
        }
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function balanceOf(
        address tokenAddress
    ) external view onlyOwner returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function existsTransaction(uint256 id) public view returns (bool) {
        return transactions[id].id != 0;
    }
}
