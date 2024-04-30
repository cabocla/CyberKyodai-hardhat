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
  const shateiAddy = process.env.SHATEI_GOERLI; // process.env.SHATEI_MAINNET

  const KyodaiDescOffChain =
    await ethers.getContractFactory("KyodaiDescOffChain");
  const kyodaiDescOffChain = await KyodaiDescOffChain.deploy(
    "https://cyberkyodai.com/api/metadata/"
  );

  console.log(
    "Kyodai Descriptor Off Chain deployed at: ",
    kyodaiDescOffChain.target
  );

  const kyodaiContract = await ethers.getContractAt("CyberKyodai", kyodaiAddy);
  const shateiContract = await ethers.getContractAt("CyberShatei", shateiAddy);

  await kyodaiContract.setNewAddy(1, kyodaiDescOffChain.target).then((_) => {
    console.log("Descriptor address set at Kyodai contract");
  });

  await shateiContract.setNewAddy(1, kyodaiDescOffChain.target).then((_) => {
    console.log("Descriptor address set at Shatei contract");
  });
  // TODO transfer ownership to multisig wallet
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
