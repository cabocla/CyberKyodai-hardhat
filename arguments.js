const chainlinkAddy = process.env.LINK_MUMBAI; // process.env.LINK_POLY
const vrfCoordinator = process.env.VRF_COORDINATOR_MUMBAI; //  process.env.VRF_COORDINATOR_POLY
const subId = process.env.SUB_ID;
const keyHash =
  "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f"; // mumbai 500gwei
// "0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd"; // poly 500gwei

module.exports = [chainlinkAddy, vrfCoordinator, subId, keyHash];
