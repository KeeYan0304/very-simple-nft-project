// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const NAME = "FreeGuy"

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
    'MetaBlinbBox',
    'ipfs://QmZS5cJ1b6W1n9QtiNj9NuwV1hjPnvJjHqxdJmeGEHe2qV',
    'MBB',
  );

  await contract.deployed();
  
  console.log("Contract deployed to:", freeGuy.address); //run smart contract on local machine
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
