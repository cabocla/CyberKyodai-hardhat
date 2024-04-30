// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
  // TODO change to mainnet
  //   const lzEndpoint = process.env.LZENDPOINT_GOERLI; // process.env.LZENDPOINT_MAINNET

  const Underworld = await ethers.getContractFactory("Underworld");

  const underworld = await upgrades.upgradeProxy(
    "0xcAB0c9b0a9205543Cd20cB3701D7ED405d30009F",
    Underworld,
    [],
    {
      kind: "uups",
    }
  );

  // TODO change LZENDPOINT when deploying to mainnet
  // await kyodaiContract.init(process.env.LZENDPOINT_MAINNET);
  //   await kyodaiContract.init(lzEndpoint);

  console.log(
    // await kyodaiContract.name(),
    "UNDERWORLD contract MAINNET upgrade, deployed at: ",
    underworld.target
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
