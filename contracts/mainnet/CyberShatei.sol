// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../token/ERC721K.sol";
import "../utils/NonblockingReceiverUpgradeable.sol";
import "../utils/Libraries.sol";
import {IKyodai, INeoYen, IShatei, IPinkie, IKyodaiDesc, ITraitGen, IUnderworld} from "../interfaces/Interfaces.sol";

contract CyberShatei is
    IShatei,
    ERC721K,
    ERC2981Upgradeable,
    UUPSUpgradeable
{
    using KyodaiLibrary for uint256;
    using BitMaps for BitMaps.BitMap;

    mapping(uint256 => uint256) public supplyPerClass;

    // address traitGenAddy;    --> 0
    // address descriptorAddy;  --> 1
    // address dogTagAddy;      --> 2
    // address yenAddy;         --> 3
    // address underworldAddy;  --> 4
    // address kyodaiAddy       --> 5
    mapping(uint256 => address) public officialAddys;

    //@dev required for UUPS Proxy Pattern
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function init(address _endpoint) external initializer {
        _init("CyberShatei", "SHATEI");
        __Ownable_init();
        __ERC2981_init();

        endpoint = ILayerZeroEndpoint(_endpoint);
    }

    /*
               _       __     ____                 __  _           
   ____ ___  (_)___  / /_   / __/_  ______  _____/ /_(_)___  ____ 
  / __ `__ \/ / __ \/ __/  / /_/ / / / __ \/ ___/ __/ / __ \/ __ \
 / / / / / / / / / / /_   / __/ /_/ / / / / /__/ /_/ / /_/ / / / /
/_/ /_/ /_/_/_/ /_/\__/  /_/  \__,_/_/ /_/\___/\__/_/\____/_/ /_/ 
                                                                  
   */

    function burn(
        uint256 tokenId,
        address who
    ) public override isKyodaiOwner(who, tokenId) {
        delete kyodais[tokenId];
        delete activities[tokenId];
        _burn(tokenId);
    }

    /*/////////////////////////////////////////
                 ACTIONS
//////////////////////////////////////////// */

    // function doAction(
    //   uint256 tokenId,
    //   uint8 action
    // ) public isKyodaiOwner(msg.sender, tokenId) noCheating {
    //   _doAction(tokenId, msg.sender, action);
    // }

    // function doActionMany(
    //   uint256[] calldata tokenIds,
    //   uint8 action
    // ) external noCheating {
    //   for (uint256 i = 0; i < tokenIds.length; ) {
    //     doAction(tokenIds[i], action);
    //     unchecked {
    //       ++i;
    //     }
    //   }
    // }

    // function claim(uint256[] calldata tokenIds) external {
    //   for (uint256 i=0; i < tokenIds.length; ) {
    //     _claim(tokenIds[i]);
    //     unchecked {
    //       ++i;
    //     }
    //   }
    // }

    // function sendToUnderworld(uint256[] calldata tokenIds) external noCheating {
    //   address underworldAddy = officialAddys[4];
    //   for (uint256 i = 0; i < tokenIds.length; ) {
    //     require(msg.sender == ownerOf(tokenIds[i]), "kyodai not owned");

    //     (, uint8 _action, ) = activities[tokenIds[i]].decodeActivity();
    //     require(_action == 0, "token not available");
    //     activities[tokenIds[i]] = KyodaiLibrary.activityInUint(
    //       underworldAddy,
    //       1,
    //       block.timestamp
    //     );
    //     unchecked {
    //       ++i;
    //     }
    //   }
    //   IUnderworld(underworldAddy).stakeMany(tokenIds); //add to list in underworld contract
    // }

    // function returnManyFromUnderworld(
    //   uint256[] calldata tokenIds,
    //   uint8 action_
    // ) public noCheating {
    //   for (uint256 i = 0; i < tokenIds.length; ) {
    //     require(msg.sender == ownerOf(tokenIds[i]), "kyodai not owned");
    //     (address _location, uint8 _action, ) = activities[tokenIds[i]]
    //       .decodeActivity();
    //     require(_action == 1, "kyodai is home");
    //     IUnderworld underworld = IUnderworld(_location);
    //     underworld.unstake(tokenIds[i]);
    //     _doAction(tokenIds[i], msg.sender, action_);
    //     unchecked {
    //       ++i;
    //     }
    //   }
    // }

    // function changeName(
    //   uint256 tokenId,
    //   bytes calldata newName
    // ) public isKyodaiOwner(msg.sender, tokenId) {
    //   require(newName.length > 0 && newName.length < 21, "invalid name length");
    //   bytes20 _name = bytes20(newName);
    //   uint256 kyodai = kyodais[tokenId];
    //   require(_name != bytes20(uint160(kyodai)), "same as current name");

    //   //TODO burn neoyen
    //   INeoYen(officialAddys[3]).burnAuth(msg.sender, 100 * 1 ether); //TODO set change name cost
    //   kyodais[tokenId] = kyodai.updateKyodai(_name, 0);
    // }

    /*/////////////////////////////////////////
                 INTERNAL
//////////////////////////////////////////// */
    // function _doAction(
    //   uint256 tokenId,
    //   address who,
    //   uint8 action_
    // ) internal isKyodaiOwner(who, tokenId) {
    //   (, uint8 _action, uint256 _timestamp) = activities[tokenId]
    //     .decodeActivity();
    //   require(_action != 1, "token is away");
    //   require(_action != action_, "already doing that");

    //   if (_action == 2 || _action == 3) {
    //     if (block.timestamp > _timestamp) _claim(tokenId);
    //   }

    //   activities[tokenId] = KyodaiLibrary.activityInUint(
    //     address(this),
    //     action_,
    //     block.timestamp > _timestamp ? block.timestamp : _timestamp
    //   );

    //   emit ActionMade(who, tokenId, uint8(action_));
    // }

    // function _claim(uint256 tokenId) internal noCheating {
    //   (address _location, uint8 _action, uint256 _timestamp) = activities[tokenId]
    //     .decodeActivity();

    //   if (block.timestamp < _timestamp) return;

    //   (, , uint256 _level, ) = kyodais[tokenId].decodeKyodai();

    //   uint256 timeDiff = block.timestamp - _timestamp;

    //   if (_action == 2) {
    //     kyodais[tokenId] = kyodais[tokenId].updateKyodai(
    //       0,
    //       ((timeDiff * 3000) / 1 days)
    //     );
    //   }
    //   if (_action == 3) {
    //     INeoYen(officialAddys[3]).mint(
    //       ownerOf(tokenId),
    //       claimableNeoYen(timeDiff, _level)
    //     );
    //   }
    //   activities[tokenId] = KyodaiLibrary.activityInUint(
    //     _location,
    //     _action,
    //     block.timestamp
    //   );
    // }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override{
        if (uint256(uint8(activities[tokenId] >> 160)) != 0)
            revert TokenLocked();

        // require(
        //   uint256(uint8(activities[tokenId] >> 160)) == 0,
        //   "token unavailable to transfer"
        // );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override  {
        if (uint256(uint8(activities[tokenId] >> 160)) != 0)
            revert TokenLocked();

        // require(
        //   uint256(uint8(activities[tokenId] >> 160)) == 0,
        //   "token unavailable to transfer"
        // );
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        if (uint256(uint8(activities[tokenId] >> 160)) != 0)
            revert TokenLocked();
        // require(
        //   uint256(uint8(activities[tokenId] >> 160)) == 0,
        //   "token unavailable to transfer"
        // );
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*
                        __   ____                 __  _           
   ________  ____ _____/ /  / __/_  ______  _____/ /_(_)___  ____ 
  / ___/ _ \/ __ `/ __  /  / /_/ / / / __ \/ ___/ __/ / __ \/ __ \
 / /  /  __/ /_/ / /_/ /  / __/ /_/ / / / / /__/ /_/ / /_/ / / / /
/_/   \___/\__,_/\__,_/  /_/  \__,_/_/ /_/\___/\__/_/\____/_/ /_/ 
                                                                                                                                                    
*/

    function totalSupply() public view override returns (uint256 _supply) {
        for (uint256 i = 0; i < 3; ) {
            _supply += supplyPerClass[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(_exists(_tokenId));
        (bytes20 _name, uint256 _traitHash, uint256 _level, ) = kyodais[
            _tokenId
        ].decodeKyodai();
        return
            IKyodaiDesc(officialAddys[1]).tokenURI(
                _tokenId,
                _name,
                _traitHash,
                _level,
                // kyodais[_tokenId],
                // kyodais[_tokenId].traitHash,
                // kyodais[_tokenId].level,
                baseURI
            );
    }

    // function claimableNeoYen(
    //   uint256 timeDiff,
    //   uint256 lvl
    // ) internal pure returns (uint256) {
    //   //yen production based on level. Increase production by 1 yen per 5 lvl plus base production of 5 yen. Max output 15 yen per day
    //   uint256 production = lvl < 50 ? (lvl / 5) + 5 : 15;
    //   return production * 1 ether * (timeDiff / 1 days);
    // }
    function getKyodai(
        uint256 tokenId
    ) external view override returns (uint256) {
        return kyodais[tokenId];
    }

    function getManyKyodai(
        uint256[] calldata tokenIds
    ) external view override returns (uint256[] memory _kyodais) {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _kyodais[i] = kyodais[tokenIds[i]];
        }
    }

    function ownerOf(
        uint256 tokenId
    ) public view override(IShatei, ERC721Upgradeable) returns (address) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // function claimable(uint256 id) external view returns (uint256 _claimable) {
    //     Activity memory activity = activities[id];
    //     uint256 timeDiff = block.timestamp > activity.timestamp
    //         ? block.timestamp - activity.timestamp
    //         : 0;
    //     _claimable = activity.action == Action.FARMING
    //         ? claimableYen(timeDiff, checkLevel(id))
    //         : (timeDiff * 2000) / 1 days;
    // }

    //   function checkLevel(
    //     uint256 tokenId
    //   ) public view override returns (uint16 _level) {
    //     // return IStatManager(statAddress).getLevel(tokenId);
    //     return kyodais[tokenId].level;
    //   }

    /*
                                    ____                 __  _           
  ____ _      ______  ___  _____   / __/_  ______  _____/ /_(_)___  ____ 
 / __ \ | /| / / __ \/ _ \/ ___/  / /_/ / / / __ \/ ___/ __/ / __ \/ __ \
/ /_/ / |/ |/ / / / /  __/ /     / __/ /_/ / / / / /__/ /_/ / /_/ / / / /
\____/|__/|__/_/ /_/\___/_/     /_/  \__,_/_/ /_/\___/\__/_/\____/_/ /_/ 
                                                                         
    */

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent);
    }

    function setNewAddy(uint256 index, address newAddy) public onlyOwner {
        officialAddys[index] = newAddy;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    uint256[48] private __gap;
}
