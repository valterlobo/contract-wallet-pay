const { expect } = require("chai");
const { hre } = require("hardhat");
const { ethersx, toBeArray, isBytesLike, toUtf8Bytes, BigNumber } = require("ethers");
const {
    time,
    loadFixture
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");



describe("PayWalletV1", function () {


    async function deployContracts() {

        const [owner, cardKey, cardOwner, buyer, seller] = await ethers.getSigners()
        const mockToken = await ethers.deployContract("MockToken")
        const PayWallet = await ethers.getContractFactory("PayWalletV1")
        //address key, address owner, address tokenAddr


        const payWallet = await PayWallet.deploy(cardKey.getAddress(), owner.getAddress(), mockToken.getAddress())
        await mockToken.transfer(await payWallet.getAddress(), ethers.parseEther("1000"))
        return { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller };
    }

    describe("Pay", function () {

        it("Pay Sucess", async () => {

            console.log("Pay Sucess")

            const { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller } = await loadFixture(deployContracts)

            const balanceWallet = await mockToken.balanceOf(payWallet.getAddress())
            //console.log(balanceWallet)
            expect(balanceWallet).to.equal(
                ethers.parseEther("1000"))


            const amount = ethers.parseEther("10")
            const nonce = 1024 | 4
            //console.log(nonce)
            const addr = await seller.getAddress()
            const addrTK = await mockToken.getAddress()
            //console.log(amount)
            const message = addr + '' + addrTK + '' + amount
            //const message = addrTK
            console.log(message)

            const hashPay = await payWallet.getMessageHash(addr, amount, message, nonce)
            console.log("hash:", hashPay)

            //const messageBytes  = ethersx.arrayify(hashPay);

            //const arraySigner =  ethersx.Utils.arrayify(hashPay)

            ///const arraySigner  = ethersx.toBeArray(hashPay)


            const signature = await cardKey.signMessage(message)
            console.log(signature)

            const valid = ethers.verifyMessage(message, signature)
            console.log("valid ", valid)
            console.log("validx", await cardKey.getAddress())


            //const ethHash = await payWallet.getEthSignedMessageHash(message);
            //console.log("ETH HASH", ethHash);

            const bytesMessage = toUtf8Bytes(message)
            console.log(isBytesLike(bytesMessage))
            console.log("signer          ", await cardKey.getAddress())
            console.log("recovered signer", await payWallet.recoverSigner(bytesMessage, signature))


            const balanceSellerBefore = await mockToken.balanceOf(seller.getAddress())
            const balanceCardBefore = await mockToken.balanceOf(payWallet.getAddress())
            console.log("Before card balance:%s  seller: %s", balanceCardBefore, balanceSellerBefore)
            //to, tokenAddress, amount, nonce
            //console.log(bytesMessage)
            await payWallet.connect(seller).pay(addr, amount, signature, bytesMessage)
            //BALANCE 
            const balanceCardAfter = await mockToken.balanceOf(payWallet.getAddress())
            const balanceSeller = await mockToken.balanceOf(seller.getAddress())
            console.log("After card:%s  seller: %s", balanceCardAfter, balanceSeller)


        });

        it("Pay Transaction", async () => {

            console.log("Pay Transaction")

            const { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller } = await loadFixture(deployContracts)

            const balanceWallet = await mockToken.balanceOf(payWallet.getAddress())
            //console.log(balanceWallet)
            expect(balanceWallet).to.equal(
                ethers.parseEther("1000"))


            const amount = ethers.parseEther("10")
            const nonce = 1024 | 4
            //console.log(nonce)
            const toPay = await seller.getAddress()
            const addrTK = await mockToken.getAddress()
            console.log(amount)
            const message = toPay + '' + addrTK + '' + amount
            //const message = addrTK
            console.log(message)
            const bytesMessage = toUtf8Bytes(message)
            console.log(isBytesLike(bytesMessage))

            const hashPay = await payWallet.getMessageHash(toPay, amount, message, nonce)
            console.log("hash:", hashPay)

            //const messageBytes  = ethersx.arrayify(hashPay);

            //const arraySigner =  ethersx.Utils.arrayify(hashPay)

            ///const arraySigner  = ethersx.toBeArray(hashPay)


            const signature = await cardKey.signMessage(message)
            console.log(signature)

            const valid = ethers.verifyMessage(message, signature)
            console.log("valid ", valid)
            console.log("validx", await cardKey.getAddress())

            console.log("--------------------------------------")

            /*
                   address _to,
        address _tokenAddress,
        uint _value,
        bytes memory signature,
        bytes memory message
            */

            await payWallet.connect(seller).submitTransaction(
                toPay,
                addrTK,
                ethers.parseEther("10.56"),
                signature, bytesMessage)


            const idx = await payWallet.connect(seller).getTransactionCount();

            console.log(idx)
            //const bigIdx = BigNumber.from(idx)
            const transaction = await payWallet.connect(seller).getTransaction(idx - 1n)
            console.log(transaction)

            await payWallet.connect(seller).revokeConfirmation(idx - 1n)

            const code = '1020'
            const bytesCode = toUtf8Bytes(code)

            const signatureCode = await cardKey.signMessage(code)
            console.log(signatureCode)


            const validCode = ethers.verifyMessage(code, signatureCode)
            console.log("valid code ", validCode)
            console.log("validx", await cardKey.getAddress())

            //await payWallet.connect(seller).confirmTransaction(idx - 1n)





            //////////


        });


    });

});
