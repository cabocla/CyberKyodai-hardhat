// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CyberClan {
  /* 
    functions:
    - have gnosis safe wallet as vault
    - vault is controlled by members
    - can store ERC20, ERC721, and ERC1155 token in vault
    - can distribute ERC20 token evenly among members according to shares (hierarchy)
    - can initiate contract transaction
    - leader and officer can add or kick members
    - members can start voting to add or kick officer or leader
    - ragequit and get their share of ERc20 token 
    */

  //connect to gnosis safe wallet per clan to execute token distribution owned by clan
  //manage members
  //TODO adjust BASE_CREATE_COST
  uint256 public constant BASE_CREATE_COST = 500;
  mapping(uint256 => uint256) public clanAllegiances; // keep count of the number of clan according to its allegiance
  uint256 public constant PCT_DEN = 10_000; // Probabilities scale, where 10_000 == 100% and 0 == 0%
  enum Rank {
    KUMICHO,
    WAKAGASHIRA,
    KOBUN
  }
  struct Clan {
    bytes32 clanName;
    // address clanAddress; // clan wallet address || 20 bytes size
    uint8 alliance; // 0 - ryuichi || 1 - torahide || 2 - omi || determined by kumicho on clan creation
    uint8 clanLevel;
    uint8 acceptance; // set clan privacy
    uint8 kumichoShare; // percentage
    uint8 wakagashiraShare; // percentages
  }

  struct Member {
    address clanAddress;
    Rank rank; // 0 - kumicho || 1 - wakagashira || 2 - kobun
  }

  mapping(address => Clan) public clans; //mapping clan wallet to clan instance
  mapping(uint256 => Member) public members; //mapping clan members to clan address

  function createClan(
    uint8 allegiance,
    uint256 kumicho,
    uint256[] calldata officers,
    uint256[] calldata newMembers
  ) public {
    //require a kyodai to be kumicho
    //create safe wallet with officers as signers
    //birn gem token
    //adjust gem price to burn according to clan allegiance number. Less allegiance, cheaper gem cost to create clan
    //increase clan allegiance number
  }

  function joinClan(address clanAddress) public {
    //require clan is public
  }

  function inviteToClan(uint256[] calldata newMembers) public {
    // require kumicho of clan
    //require all new members not in other clan
  }

  function leaveOrDisbandClan(uint256 tokenId) public {
    //if kumicho, disband clan
    //if member, leave clan
    //reduce clan allegiance number
  }

  function upgradeClan(
    uint256 kumichoId,
    uint256[] calldata newOfficers
  ) public {
    // require kumicho of clan
    // burn gem
  }

  function createClanCost(uint256 _allegiance) internal view returns (uint256) {
    uint256 totalClanSupply;
    for (uint256 i = 0; i < 3; ) {
      totalClanSupply += clanAllegiances[i];
         unchecked{
      ++i;
      }
    }
    return
      BASE_CREATE_COST +
      ((BASE_CREATE_COST * clanAllegiances[_allegiance]) / totalClanSupply);
    //base cost plus discount or penalty based on clan allegiance number
  }

  function upgradeClanCost(uint256 _kumichoId) internal view returns (uint256) {
    //TODO adjust yen cost
    uint8 _clanLevel = clans[members[_kumichoId].clanAddress].clanLevel;
    if (_clanLevel == 0) return 100;
    if (_clanLevel == 1) return 200;
    if (_clanLevel == 2) return 400;
    if (_clanLevel == 3) return 800;
    if (_clanLevel == 4) return 1500;

    revert();
  }

  //TODO change to claimable rather than distribute. gas cost increases in proportion of number of members
  function distributeToken(uint256 _memberId) public {
    require(members[_memberId].rank != Rank.KOBUN, "insufficient rank");
    //call clan wallet address to distribute token
  }
}
