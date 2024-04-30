// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, upgrades } = require("hardhat");

async function main() {
  // TODO change to mainnet
  const kyodaiAddy = process.env.KYODAI_GOERLI; // process.env.KYODAI_MAINNET
  const lzEndpoint = process.env.LZENDPOINT_GOERLI; // process.env.LZENDPOINT_MAINNET

  const CyberShatei = await ethers.getContractFactory("CyberShatei");

  const shateiContract = await upgrades.deployProxy(CyberShatei, [], {
    kind: "uups",
  });

  // TODO
  // await shateiContract.init(process.env.LZENDPOINT_MAINNET);
  await shateiContract.init(lzEndpoint);
  console.log(
    await shateiContract.name(),
    "SHATEI contract MAINNET initialized, deployed at: ",
    shateiContract.target
  );

  // set kyodai address to shatei contract
  // await shateiContract.setNewAddy(5, process.env.KYODAI_MAINNET);
  await shateiContract.setNewAddy(5, kyodaiAddy);
  console.log("kyodai address set to SHATEI MAINNET contract");

  // TODO set trusted remote
  // TODO transfer ownership to multisig wallet
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
