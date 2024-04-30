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
  const kyodaiAddy = process.env.KYODAI_MUMBAI; // process.env.KYODAI_POLY
  const shateiAddy = process.env.SHATEI_MUMBAI; // process.env.SHATEI_POLY

  const oracleAddy = process.env.ORACLE_MUMBAI; // process.env.ORACLE_MUMBAI
  const neoyenAddy = process.env.NEOYEN_MUMBAI; // process.env.NEOYEN_MUMBAI
  const pinkieAddy = process.env.PINKIE_MUMBAI; // process.env.PINKIE_MUMBAI
  const traitGenAddy = process.env.TRAITGEN_MUMBAI; // process.env.TRAITGEN_MUMBAI
  const underworldAddy = process.env.UNDERWORLD_MUMBAI; // process.env.UNDERWORLD_MUMBAI

  // const multisig = process.env.MULTISIG;

  const kyodaiContract = await ethers.getContractAt(
    "CyberKyodaiPoly",
    kyodaiAddy
  );
  const shateiContract = await ethers.getContractAt(
    "CyberShateiPoly",
    shateiAddy
  );
  const neoYen = await ethers.getContractAt("NeoYen", neoyenAddy);
  const pinkie = await ethers.getContractAt("Pinkie", pinkieAddy);
  const oracle = await ethers.getContractAt("GameOracle", oracleAddy);
  const traitGen = await ethers.getContractAt("TraitGenPoly", traitGenAddy);
  const underworld = await ethers.getContractAt("Underworld", underworldAddy);

  // address traitGenAddy;    --> 0
  // address descriptorAddy;  --> 1
  // address pinkieAddy;      --> 2
  // address yenAddy;         --> 3
  // address underworldAddy;  --> 4
  // address gameOracle       --> 5
  await kyodaiContract.setNewAddy(0, traitGen.target);
  console.log("traitGen address set to KYODAI POLY contract");
  await kyodaiContract.setNewAddy(2, pinkie.target);
  console.log("pinkie address set to KYODAI POLY contract");
  await kyodaiContract.setNewAddy(3, neoYen.target);
  console.log("Neo Yen address set to KYODAI POLY contract");
  await kyodaiContract.setNewAddy(4, underworld.target);
  console.log("underworld address set to KYODAI POLY contract");
  await kyodaiContract.setNewAddy(5, oracle.target);
  console.log("oracle address set to KYODAI POLY contract");

  // address traitGenAddy;    --> 0
  // address descriptorAddy;  --> 1
  // address pinkyAddy;       --> 2
  // address yenAddy;         --> 3
  // address underworldAddy;  --> 4
  // address kyodaiAddy       --> 5
  // address gameOracle       --> 6
  await shateiContract.setNewAddy(0, traitGen.target);
  console.log("traitGen address set to SHATEI POLY contract");
  await shateiContract.setNewAddy(2, pinkie.target);
  console.log("pinkie address set to SHATEI POLY contract");
  await shateiContract.setNewAddy(3, neoYen.target);
  console.log("Neo Yen address set to SHATEI POLY contract");
  await shateiContract.setNewAddy(4, underworld.target);
  console.log("underworld address set to SHATEI POLY contract");
  await shateiContract.setNewAddy(5, kyodaiContract.target);
  console.log("kyodai address set to SHATEI POLY contract");
  await shateiContract.setNewAddy(6, oracle.target);
  console.log("oracle address set to SHATEI POLY contract");

  await oracle.setAuth(kyodaiContract.target, 2);
  console.log("kyodai address authorized at Game Oracle");
  await oracle.setAuth(shateiContract.target, 2);
  console.log("shatei address authorized at Game Oracle");
  await oracle.setAuth(traitGen.target, 2);
  console.log("traitgen address authorized at Game Oracle");
  await oracle.setAuth(underworld.target, 2);
  console.log("underworld address authorized at Game Oracle");

  await pinkie.setAuth(kyodaiContract.target, 2);
  console.log("kyodai address authorized at pinkie");
  await pinkie.setAuth(shateiContract.target, 2);
  console.log("shatei address authorized at pinkie");
  await pinkie.setAuth(underworld.target, 2);
  console.log("underworld address authorized at pinkie");

  // address kyodaiAddy;    --> 0
  // address shateiAddy;    --> 1
  // address dogtagAddy;    --> 2
  // address yenAddy;       --> 3
  // address gameOracle     --> 4
  await underworld.setNewAddy(0, kyodaiContract.target);
  console.log("kyodai address set to UNDERWORLD contract");
  await underworld.setNewAddy(1, shateiContract.target);
  console.log("shatei address set to UNDERWORLD contract");
  await underworld.setNewAddy(2, pinkie.target);
  console.log("pinkie address set to UNDERWORLD contract");
  await underworld.setNewAddy(3, neoYen.target);
  console.log("neoyen address set to UNDERWORLD contract");
  await underworld.setNewAddy(4, oracle.target);
  console.log("oracle address set to UNDERWORLD contract");

  // TODO transfer ownership of kyodai, shatei, neoyen, underworld, oracle, pinkie to multisig wallet
  // kyodaiContract.transferOwnership(multisig);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
