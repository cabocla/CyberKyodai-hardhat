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
  const chainlinkAddy = process.env.LINK_MUMBAI; // process.env.LINK_POLY
  const vrfCoordinator = process.env.VRF_COORDINATOR_MUMBAI; //  process.env.VRF_COORDINATOR_POLY
  const subId = process.env.SUB_ID;
  const keyHash =
    "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f"; // mumbai 500gwei
  // "0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd"; // poly 500gwei

  const oracle = await ethers.deployContract("GameOracle", [
    chainlinkAddy,
    vrfCoordinator,
    subId,
    keyHash,
  ]);
  console.log("oracle deployed at: ", oracle.target);

  await hre.run("verify:verify", {
    address: oracle.target,
    constructorArguments: [chainlinkAddy, vrfCoordinator, subId, keyHash],
  });
  console.log("GameOracle verified at ", oracle.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
