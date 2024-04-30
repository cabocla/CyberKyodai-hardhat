// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers } = require("hardhat");

async function main() {
  // deploy script for: Neoyen, Pinkie, Game Oracle, Underworld, Traitgen

  //TODO change value for mainnet
  const kyodaiAddy = process.env.KYODAI_MUMBAI; // process.env.KYODAI_POLY
  const shateiAddy = process.env.SHATEI_MUMBAI; // process.env.SHATEI_POLY
  const oracleAddy = process.env.ORACLE_MUMBAI; // process.env.ORACLE_POLY
  const traitGen = await ethers.deployContract("TraitGenPoly", [
    kyodaiAddy,
    shateiAddy,
    oracleAddy,
  ]);
  console.log("traitGen deployed at: ", traitGen.target);

  await hre.run("verify:verify", {
    address: traitGen.target,
    constructorArguments: [kyodaiAddy, shateiAddy, oracleAddy],
  });
  console.log("Traitgen verified at ", traitGen.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
