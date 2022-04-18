const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyNFT", function () {
  it("Should mint and transfer nft to someone", async function () {
    const FreeGuy = await ethers.getContractFactory("FreeGuy");
    const freeGuy = await FreeGuy.deploy();
    await freeGuy.deployed();

    const recipient = "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"; //account #2
    const metadataURI = "cid/test.png";

    let balance = await freeGuy.balanceOf(recipient);
    expect(balance).to.equal(0);

    const newlyMintedToken = await freeGuy.payToMint(recipient, metadataURI, { value: ethers.utils.parseEther('0.05')});

    //wait until the transaction is mined
    await newlyMintedToken.wait();

    balance = await freeGuy.balanceOf(recipient);
    console.log(balance);
    expect(balance).to.equal(1);

    expect(await freeGuy.isContentOwned(metadataURI)).to.equal(true);

  });
});
