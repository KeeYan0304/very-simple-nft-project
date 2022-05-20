// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const NAME = "Blindbox"

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const NFT = await hre.ethers.getContractFactory(NAME);
  const contract = await NFT.deploy(
    4013,
    '0x6168499c0cFfCaCD319c818142124B7A15E857ab',
    '0x01BE23585060835E02B77ef475b0Cc51aA1e0709',
    '0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc',
    'MetaBlindBox',
    'MBB'
  );

  await contract.deployed();
  
  console.log("Contract deployed to:", contract.address); //run smart contract on local machine
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
