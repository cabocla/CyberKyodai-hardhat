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
  const chainlinkAddy = process.env.LINK_MUMBAI; // process.env.LINK_POLY
  const vrfCoordinator = process.env.VRF_COORDINATOR_MUMBAI; //  process.env.VRF_COORDINATOR_POLY
  const subId = process.env.SUB_ID;
  const keyHash =
    "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f"; // mumbai 500gwei
  // "0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd"; // poly 500gwei

  const kyodaiContract = await ethers.getContractAt(
    "CyberKyodaiPoly",
    kyodaiAddy
  );
  const shateiContract = await ethers.getContractAt(
    "CyberShateiPoly",
    shateiAddy
  );

  const Underworld = await ethers.getContractFactory("Underworld");
  const underworld = await upgrades.deployProxy(Underworld, [], {
    kind: "uups",
  });
  await underworld.init();
  console.log(
    "UNDERWORLD contract POLY initialized, deployed at: ",
    underworld.target
  );

  const oracle = await ethers.deployContract("GameOracle", [
    chainlinkAddy,
    vrfCoordinator,
    subId,
    keyHash,
  ]);
  console.log("oracle deployed at: ", oracle.target);
  const traitGen = await ethers.deployContract("TraitGenPoly", [
    kyodaiAddy,
    shateiAddy,
    oracle.target,
  ]);
  console.log("traitGen deployed at: ", traitGen.target);
  const pinkie = await ethers.deployContract("Pinkie");
  console.log("Pinkie deployed at: ", pinkie.target);
  const neoYen = await ethers.deployContract("NeoYen", [
    process.env.LZENDPOINT_MUMBAI,
  ]);
  console.log("Neo Yen deployed at: ", neoYen.target);

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
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
