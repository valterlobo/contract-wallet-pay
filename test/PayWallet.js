const { expect } = require("chai");
const { hre } = require("hardhat");
const { ethersx, toBeArray, isBytesLike, toUtf8Bytes, BigNumber } = require("ethers");
const {
    time,
    loadFixture
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");



describe("PayWallet", function () {


    async function deployContracts() {

        const [owner, cardKey, cardOwner, buyer, seller] = await ethers.getSigners()
        const mockToken = await ethers.deployContract("MockToken")

        //address key, address owner, address tokenAddr


        const PayWalletLibrary = await ethers.getContractFactory("PayWalletLibrary")
        const payWalletLibrary = await PayWalletLibrary.deploy()

        const PayWallet = await ethers.getContractFactory("PayWallet", {
            libraries: {
                PayWalletLibrary: await payWalletLibrary.getAddress(),
            },
        })


        const code = "4040"
        const signatureCode = await cardKey.signMessage(code)
        const signerAddress = await ethers.verifyMessage(code, signatureCode)
        const signerHashOwner = await owner.signMessage(signatureCode)
        const signerOwnerAddress = await ethers.verifyMessage(signatureCode, signerHashOwner)
        console.log("======================================================")
        console.log("owner               ", await owner.getAddress())
        console.log("Signer owner        ", signerOwnerAddress)
        console.log("Signer Address      ", signerAddress)
        console.log("card key address    ", await cardKey.getAddress())

        console.log("signatureCode         ", signatureCode)
        console.log("signerHashOwner       ", signerHashOwner)

        const bytesSignCode = toUtf8Bytes(signatureCode)
        console.log(isBytesLike(bytesSignCode))


        /*
                bytes32 hashCode,
        bytes32 signedCode,
        address key,
        address ownerAddr
        */
        const payWallet = await PayWallet.deploy(bytesSignCode, signerHashOwner, cardKey.getAddress(), owner.getAddress(), mockToken.getAddress())
        await mockToken.transfer(await payWallet.getAddress(), ethers.parseEther("1000"))
        console.log("======================================================")
        return { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller };
    }

    describe("PayWallet", function () {

        it("submitTransaction", async () => {

            console.log("Pay Transaction")

            const { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller } = await loadFixture(deployContracts)




            const amount = ethers.parseEther("10")
            const nonce = 1024 | 4
            //console.log(nonce)
            const toPay = await seller.getAddress()
            const addrTK = await mockToken.getAddress()
            console.log(amount)
            const message = toPay + '' + addrTK + '' + amount


            const signatureSeller = await seller.signMessage(message)
            const signature = await cardKey.signMessage(message)
            const bytesMessage = toUtf8Bytes(message)

            await payWallet.connect(seller).submitTransaction(123, await seller.getAddress(), await mockToken.getAddress(), amount, signatureSeller, signature, bytesMessage)


            const transaction = await payWallet.connect(seller).getTransaction(123)
            console.log(transaction)
            expect(await seller.getAddress()).equal(transaction[1])

        });


        it("cancelTransaction", async () => {

            console.log("cancelTransaction")

            const { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller } = await loadFixture(deployContracts)

            const amount = ethers.parseEther("10")
            const nonce = 1024 | 4
            //console.log(nonce)
            const toPay = await seller.getAddress()
            const addrTK = await mockToken.getAddress()
            console.log(amount)
            const message = toPay + '' + addrTK + '' + amount


            const signatureSeller = await seller.signMessage(message)
            const signature = await cardKey.signMessage(message)
            const bytesMessage = toUtf8Bytes(message)

            await payWallet.connect(seller).submitTransaction(123, await seller.getAddress(), await mockToken.getAddress(), amount, signatureSeller, signature, bytesMessage)

            await payWallet.connect(cardKey).cancelTransaction(123)

            const transaction = await payWallet.connect(seller).getTransaction(123)
            console.log(transaction)
            expect(await seller.getAddress()).equal(transaction[1])
            expect(3n).equal(transaction[7])

        });


        it("confirmTransaction", async () => {

            console.log("confirmTransaction")

            const { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller } = await loadFixture(deployContracts)

            const amount = ethers.parseEther("100.56")
            const nonce = 1024 | 4
            //console.log(nonce)
            const toPay = await seller.getAddress()
            const addrTK = await mockToken.getAddress()
            console.log(amount)
            const message = toPay + '' + addrTK + '' + amount

            const signatureSeller = await seller.signMessage(message)
            const signature = await cardKey.signMessage(message)
            const bytesMessage = toUtf8Bytes(message)

            await payWallet.connect(seller).submitTransaction(123, await seller.getAddress(), await mockToken.getAddress(), amount, signatureSeller, signature, bytesMessage)



            const transaction = await payWallet.connect(seller).getTransaction(123)
            //console.log(transaction)
            expect(await seller.getAddress()).equal(transaction[1])
            expect(1n).equal(transaction[7])

            //BEFORE
            const balanceSellerBefore = await mockToken.balanceOf(seller.getAddress())
            const balanceCardBefore = await mockToken.balanceOf(payWallet.getAddress())
            console.log("Before card balance:%s  seller: %s", balanceCardBefore, balanceSellerBefore)
            //
            const code = "4040"
            const signatureCode = await cardKey.signMessage(code)
            const bytesSignCode = toUtf8Bytes(signatureCode)
            await payWallet.connect(cardKey).confirmTransaction(123, bytesSignCode)


            //AFTER 
            const balanceCardAfter = await mockToken.balanceOf(payWallet.getAddress())
            const balanceSeller = await mockToken.balanceOf(seller.getAddress())
            console.log("After card:%s  seller: %s", balanceCardAfter, balanceSeller)

            const transactionAfter = await payWallet.connect(seller).getTransaction(123)
            //console.log(transactionAfter)
            expect(await seller.getAddress()).equal(transactionAfter[1])
            expect(2n).equal(transactionAfter[7])


        });


        it("withdraw", async () => {

            console.log("withdraw")

            const { payWallet, owner, cardOwner, cardKey, mockToken, buyer, seller } = await loadFixture(deployContracts)


            const balanceToken = await mockToken.balanceOf(payWallet.getAddress())
            
            console.log(balanceToken)

         


           await  payWallet.connect(owner).withdraw(balanceToken,  await mockToken.getAddress())
          
            const balanceTokenOwner = await mockToken.balanceOf(owner.getAddress())
            console.log(balanceTokenOwner)


        });


    });

});
