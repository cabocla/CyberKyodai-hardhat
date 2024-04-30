// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../token/ERC721KPoly.sol";
import {IKyodaiPoly, INeoYen, IPinkie, IKyodaiDesc, ITraitGenPoly, IUnderworld, IGameOracle} from "../interfaces/Interfaces.sol";

contract CyberKyodaiPoly is IKyodaiPoly, ERC721KPoly, UUPSUpgradeable {
    using KyodaiLibrary for uint256;
    using BitMaps for BitMaps.BitMap;

    error UnauthorizedAddress(address _address);
    error AlreadyRevealed(uint256 _traitHash);
    error TokenNotOwned(address _address);
    error InvalidInput();
    error MintedOut();
    error InvalidMintPhase();
    error InvalidProof();
    error WhitelistClaimed();
    error InvalidAmount();

    // address traitGenAddy;    --> 0
    // address descriptorAddy;  --> 1
    // address pinkieAddy;      --> 2
    // address yenAddy;         --> 3
    // address underworldAddy;  --> 4
    // address gameOracle       --> 5
    mapping(uint256 => address) public officialAddys;
    mapping(uint256 => uint256) public allianceSupply;

    // 1 - not active
    // 2- phase 2 whitelist mint
    // 3 - public mint
    uint256 public mintActive;
    bytes32 public merkleRoot;
    BitMaps.BitMap whitelistClaimed; // mapping of address to claimed whitelist allo
    bool internal ownerMinted;

    // modifier noCheating() {
    //     require(
    //         msg.sender == tx.origin && !KyodaiLibrary.isContract(msg.sender),
    //         "you're trying to cheat"
    //     );
    //     _;
    // }

    // modifier isKyodaiOwner(address who_, uint256 id) {
    //     require(
    //         ownerOf(id) == who_,
    //         // || activities[id].owner == who_
    //         "kyodai not owned"
    //     );
    //     _;
    // }

    ///@dev required for UUPS Proxy Pattern
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function init(address _lzEndpoint) external initializer {
        mintActive = 1;
        _init("CyberKyodai", "KYODAI");
        __Ownable_init();

        endpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    //TODO modifier to validate signature using ECDSA to prevent bot mint

    /*
               _       __     ____                 __  _           
   ____ ___  (_)___  / /_   / __/_  ______  _____/ /_(_)___  ____ 
  / __ `__ \/ / __ \/ __/  / /_/ / / / __ \/ ___/ __/ / __ \/ __ \
 / / / / / / / / / / /_   / __/ /_/ / / / / /__/ /_/ / /_/ / / / /
/_/ /_/ /_/_/_/ /_/\__/  /_/  \__,_/_/ /_/\___/\__/_/\____/_/ /_/ 
                                                                  
   */

    function mint(
        bytes32[] memory _merkleProof,
        uint256 mintAmount
    ) external payable noCheating {
        if (totalSupply() + 1 > 3333) revert MintedOut();

        // 1 - not active
        // 2- phase 1 or 2 whitelist mint
        // 3 - public mint
        uint256 mintPhase = mintActive;

        if (mintPhase != 2 && mintPhase != 3) revert InvalidMintPhase();
        if (mintPhase == 2) {
            // whitelist mint

            if (whitelistClaimed.get(uint256(uint160(msg.sender))))
                revert WhitelistClaimed();
            if (
                !MerkleProof.verify(
                    _merkleProof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                )
            ) revert InvalidProof();

            whitelistClaimed.set(uint256(uint160(msg.sender)));

            mintInternal(msg.sender);
            if (msg.value == 0.0099 ether) mintInternal(msg.sender);
        }
        if (mintPhase == 3) {
            // public mint
            if (mintAmount == 0 || mintAmount > 5) revert InvalidAmount();
            if (msg.value != mintAmount * 0.0099 ether) revert InvalidAmount();
            for (uint256 i = 0; i < mintAmount; ) {
                mintInternal(msg.sender);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function mintKyodai() public payable noCheating {
        if (totalSupply() + 1 > 6666) revert MintedOut();
        IPinkie pinky = IPinkie(officialAddys[2]);

        uint256 minTier = currentMinPinkyTier(totalSupply());
        for (uint256 i = 0; i < 3; ) {
            pinky.burn((minTier * 3) + i, msg.sender, 3); //TODO amount pinky to burn to mint kyodai (?)
            unchecked {
                ++i;
            }
        }
        mintInternal(msg.sender);
    }

    // total supply 6,666
    // returns min pinkie tier per supply
    function currentMinPinkyTier(
        uint256 _supply
    ) internal pure returns (uint256) {
        if (_supply < 4000) return 0;
        if (_supply > 3999 && _supply < 4666) return 1;
        if (_supply > 4665 && _supply < 5332) return 2;
        if (_supply > 5331 && _supply < 5998) return 3;
        if (_supply > 5997 && _supply < 6666) return 4;

        revert();
    }

    // TODO manually mint until 100 token max for owner
    // 100 for team for marketing, etc
    function ownerMint() external onlyOwner {
        require(!ownerMinted);
        for (uint256 i = 0; i < 100; ) {
            mintInternal(owner());
            unchecked {
                ++i;
            }
        }
        ownerMinted = true;
    }

    function mintInternal(address to) internal {
        uint256 tokenId = totalSupply() + 1;
        // kyodais[tokenId] = KyodaiLibrary.kyodaiInUint(bytes20(0), 0, 1, 0);
        activities[tokenId] = KyodaiLibrary.activityInUint(
            address(this),
            1, // set to away before reveal, only revealed Kyodai can play the game
            block.timestamp
        );
        IGameOracle(officialAddys[5]).requestRandom(tokenId);

        ++_totalSupply;
        _mint(to, tokenId);
    }

    // sakazuki ceremony to officially accept a member into yakuza family
    function reveal(
        uint256 tokenId,
        uint256 alliance
    ) external isKyodaiOwner(msg.sender, tokenId) {
        alliance %= 3;
        (, uint256 traitHash, , ) = KyodaiLibrary.decodeKyodai(
            kyodais[tokenId]
        );

        if (traitHash != 0) revert AlreadyRevealed(traitHash);
        // require(traitHash == 0, "revealed already");
        if (allianceSupply[alliance] + 1 > 2222) revert MintedOut();

        traitHash = ITraitGenPoly(officialAddys[0]).genKyodaiHash(
            tokenId,
            alliance
        );
        ++allianceSupply[alliance];
        kyodais[tokenId] = KyodaiLibrary.kyodaiInUint(
            bytes20(0),
            traitHash,
            1,
            0
        );
        activities[tokenId] = KyodaiLibrary.activityInUint(
            address(this),
            0,
            block.timestamp
        );
    }

    function burn(
        uint256 tokenId,
        address who
    ) public override isKyodaiOwner(who, tokenId) {
        delete kyodais[tokenId];
        delete activities[tokenId];
        _burn(tokenId);
    }

    function burnAuth(uint256 tokenId) external override {
        if (msg.sender != officialAddys[4])
            revert UnauthorizedAddress(msg.sender);
        delete kyodais[tokenId];
        delete activities[tokenId];
        _burn(tokenId);
    }

    /*/////////////////////////////////////////
                 ACTIONS
//////////////////////////////////////////// */

    // TODO ganti jadi training dan claim level aja, NEOYEN farming dan battle di underworld
    /// @notice
    /// @param action 0 - unstake | 1 - away | 2 - training
    function doAction(
        uint256 tokenId,
        uint8 action
    ) public isKyodaiOwner(msg.sender, tokenId) noCheating {
        _doAction(tokenId, msg.sender, action);
    }

    function doActionMany(
        uint256[] calldata tokenIds,
        uint8 action
    ) external noCheating {
        for (uint256 i = 0; i < tokenIds.length; ) {
            doAction(tokenIds[i], action);
            unchecked {
                ++i;
            }
        }
    }

    function claim(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ) {
            _claim(tokenIds[i], activities[tokenIds[i]]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice stake to this contract to battle or farm $NEOYEN
    /// @param tokenIds tokens to be staked
    /// @param location location district to be staked. 0 = usntaked | 1 - 7 = districts
    /// @param action 0 - unstaked | 1 - 5 = working | 6 - battle
    function sendToUnderworld(
        uint256[] calldata tokenIds,
        uint256 location,
        uint256 action
    ) external noCheating {
        address underworldAddy = officialAddys[4];
        uint256[] memory _kyodais = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ) {
            if (msg.sender != ownerOf(tokenIds[i]))
                revert TokenNotOwned(msg.sender);
            // require(msg.sender == ownerOf(tokenIds[i]), "kyodai not owned");

            (, uint8 _action, ) = activities[tokenIds[i]].decodeActivity();
            if (_action != 0) revert TokenLocked();
            // require(_action == 0, "token not available");

            activities[tokenIds[i]] = KyodaiLibrary.activityInUint(
                underworldAddy,
                1,
                block.timestamp
            );
            _kyodais[i] = kyodais[tokenIds[i]];
            unchecked {
                ++i;
            }
        }
        IUnderworld(underworldAddy).stakeMany(
            tokenIds,
            _kyodais,
            msg.sender,
            location,
            action
        ); //add to list in underworld contract
    }

    function returnManyFromUnderworld(
        uint256[] calldata tokenIds,
        uint8 action_
    ) public noCheating {
        for (uint256 i = 0; i < tokenIds.length; ) {
            if (msg.sender != ownerOf(tokenIds[i]))
                revert TokenNotOwned(msg.sender);
            // require(msg.sender == ownerOf(tokenIds[i]), "kyodai not owned");
            (address _location, uint8 _action, ) = activities[tokenIds[i]]
                .decodeActivity();
            require(_action == 1, "kyodai is home");
            IUnderworld underworld = IUnderworld(_location);
            underworld.unstake(tokenIds[i]);
            _doAction(tokenIds[i], msg.sender, action_);
            unchecked {
                ++i;
            }
        }
    }

    function changeName(
        uint256 tokenId,
        bytes calldata newName
    ) public isKyodaiOwner(msg.sender, tokenId) {
        // require(newName.length > 0 && newName.length < 21, "invalid name length");
        bytes20 _name = bytes20(newName);
        uint256 kyodai = kyodais[tokenId];
        // require(_name != bytes20(uint160(kyodai)), "same as current name");
        if (
            newName.length == 0 ||
            newName.length > 20 ||
            _name == bytes20(uint160(kyodai))
        ) revert InvalidInput();

        INeoYen(officialAddys[3]).burnAuth(msg.sender, 333 * 1 ether); //TODO set change name cost
        kyodais[tokenId] = kyodai.updateKyodai(_name, 0);
    }

    /*/////////////////////////////////////////
                 INTERNAL
//////////////////////////////////////////// */
    function _doAction(
        uint256 tokenId,
        address who,
        uint8 action_
    ) internal isKyodaiOwner(who, tokenId) {
        uint256 _activity = activities[tokenId];
        (, uint8 _action, uint256 _timestamp) = _activity.decodeActivity();
        require(_action != 1, "token is away");
        require(_action != action_, "already doing that");

        // uint256 timestamp = block.timestamp > _timestamp
        //     ? block.timestamp
        //     : _timestamp;

        if (_action == 2) {
            if (block.timestamp > _timestamp) _claim(tokenId, _activity);
        }

        activities[tokenId] = KyodaiLibrary.activityInUint(
            address(this),
            action_,
            block.timestamp > _timestamp ? block.timestamp : _timestamp
        );

        emit ActionMade(who, tokenId, action_);
    }

    function _claim(uint256 tokenId, uint256 _activity) internal noCheating {
        (address _location, uint8 _action, uint256 _timestamp) = _activity
            .decodeActivity();

        if (block.timestamp < _timestamp) return;
        uint256 kyodai = kyodais[tokenId];
        // (, , uint256 _level, ) = kyodai.decodeKyodai();

        uint256 timeDiff = block.timestamp - _timestamp;

        if (_action == 2) {
            //if action is TRAINING
            kyodais[tokenId] = kyodai.updateKyodai(
                0,
                ((timeDiff * 3000) / 1 days)
            );
        }

        activities[tokenId] = KyodaiLibrary.activityInUint(
            _location,
            _action,
            block.timestamp
        );
    }

    /*
                        __   ____                 __  _           
   ________  ____ _____/ /  / __/_  ______  _____/ /_(_)___  ____ 
  / ___/ _ \/ __ `/ __  /  / /_/ / / / __ \/ ___/ __/ / __ \/ __ \
 / /  /  __/ /_/ / /_/ /  / __/ /_/ / / / / /__/ /_/ / /_/ / / / /
/_/   \___/\__,_/\__,_/  /_/  \__,_/_/ /_/\___/\__/_/\____/_/ /_/                                                                                                                                                 
*/
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
                baseURI
            );
    }

    // // TODO move to underworld contract
    // function claimableNeoYen(
    //     uint256 timeDiff,
    //     uint256 lvl
    // ) internal pure returns (uint256) {
    //     //yen production based on level. Increase production by 2 yen per 5 lvl plus base production of 5 yen. Max output 35 yen per day
    //     uint256 production = lvl < 50 ? ((lvl * 2) / 5) + 5 : 25;
    //     return production * 1 ether * (timeDiff / 1 days);
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
    ) public view override(IKyodaiPoly, ERC721Upgradeable) returns (address) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

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

    uint256[44] private __gap;
}
