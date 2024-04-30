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

  const Underworld = await ethers.getContractFactory("Underworld");
  const underworld = await upgrades.deployProxy(Underworld, [], {
    kind: "uups",
  });
  await underworld.init();
  console.log(
    "UNDERWORLD contract POLY initialized, deployed at: ",
    underworld.target
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
