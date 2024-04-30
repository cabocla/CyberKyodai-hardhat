// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

async function main() {
  //TODO change to mainnet
  const kyodaiAddy = process.env.KYODAI_GOERLI; // process.env.KYODAI_MAINNET

  const kyodaiContract = await ethers.getContractAt("CyberKyodai", kyodaiAddy);

  const traitGen = await ethers.deployContract("TraitGen", [kyodaiAddy]);
  console.log("Kyodai Trait Gen deployed at: ", traitGen.target);
  await kyodaiContract.setNewAddy(0, traitGen.target);
  console.log("Trait Gen address set at Kyodai contract");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
