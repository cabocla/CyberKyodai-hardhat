// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
  // TODO change to mainnet
  const lzEndpoint = process.env.LZENDPOINT_MUMBAI; // process.env.LZENDPOINT_POLY

  const CyberKyodai = await ethers.getContractFactory("CyberKyodaiPoly");
  const kyodaiContract = await upgrades.deployProxy(CyberKyodai, [], {
    kind: "uups",
  });

  // await kyodaiContract.init(process.env.LZENDPOINT_POLY);
  await kyodaiContract.init(lzEndpoint);
  console.log(
    // await kyodaiContract.name(),
    "kyodai contract POLY initialized, deployed at: ",
    kyodaiContract.target
  );

  // TODO set trusted remote
  // TODO transfer ownership to multisig wallet
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
