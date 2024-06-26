// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
  // deploy script for: Neoyen, Pinkie, Game Oracle, Underworld, Traitgen

  //TODO change value for mainnet
  const lzEndpoint = process.env.LZENDPOINT_MUMBAI; // process.env.LZENDPOINT_POLY
  const neoYen = await ethers.deployContract("NeoYen", [lzEndpoint]);
  console.log("Neo Yen deployed at: ", neoYen.target);

  await hre.run("verify:verify", {
    address: neoYen.target,
    constructorArguments: [lzEndpoint],
  });
  console.log("NeoYen verified at ", neoYen.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
