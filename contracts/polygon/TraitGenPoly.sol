// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/Libraries.sol";
import {ITraitGenPoly, IKyodaiPoly, IShateiPoly, IGameOracle} from "../interfaces/Interfaces.sol";

contract TraitGenPoly is ITraitGenPoly, Ownable {
    using KyodaiLibrary for uint8;
    using BitMaps for BitMaps.BitMap;

    error UnauthorizedAddress();

    // address kyodaiAddy;      --> 0
    // address shateiAddy;      --> 1
    // address oracleAddy;      --> 2
    mapping(uint256 => address) public officialAddys;

    mapping(uint256 => uint256) public tokenTraits;

    // uint16[][6] internal TIERS;
    // uint16[5] internal SHATEI_LVL_TIER;
    uint256 internal SEED_NONCE;

    // mapping(bytes8 => bool) internal kyodaiHashToMinted;
    // mapping(bytes8 => bool) internal shateiHashToMinted;

    // mapping of index hash to index bool.
    // Key is mapping index, Value is uint containing bits as bool.
    // Hash is pointer to bit location in uint256.
    BitMaps.BitMap internal kyodaiHashToMinted;
    BitMaps.BitMap internal shateiHashToMinted;

    bytes32 internal entropySauce;

    uint8[][4] public kyodaiRarities;
    uint8[][4] public kyodaiAliases;
    uint8[][4] public shateiRarities;
    uint8[][4] public shateiAliases;

    constructor(
        address kyodaiAddy,
        address shateiAddy,
        address gameOracleAddy
    ) {
        officialAddys[0] = kyodaiAddy;
        officialAddys[1] = shateiAddy;
        officialAddys[2] = gameOracleAddy;

        kyodaiHashToMinted.set(0);
        shateiHashToMinted.set(0);

        // TODO change rarities and aliases value

        // cloth
        kyodaiRarities[0] = [
            190,
            215,
            240,
            100,
            110,
            135,
            160,
            185,
            80,
            210,
            235,
            240,
            80,
            80,
            100,
            100,
            100,
            245,
            250,
            255
        ];
        kyodaiAliases[0] = [
            1,
            2,
            4,
            0,
            5,
            6,
            7,
            9,
            0,
            10,
            11,
            17,
            0,
            0,
            0,
            0,
            4,
            18,
            19,
            19
        ];

        // face
        kyodaiRarities[1] = [255, 30, 60, 60, 150, 156];
        kyodaiAliases[1] = [0, 0, 0, 0, 0, 0];
        // head
        kyodaiRarities[2] = [
            221,
            100,
            181,
            140,
            224,
            147,
            84,
            228,
            140,
            224,
            250,
            160,
            241,
            207,
            173,
            84,
            254,
            220,
            196,
            140,
            168,
            252,
            140,
            183,
            236,
            252,
            224,
            255
        ];
        kyodaiAliases[2] = [
            1,
            2,
            5,
            0,
            1,
            7,
            1,
            10,
            5,
            10,
            11,
            12,
            13,
            14,
            16,
            11,
            17,
            23,
            13,
            14,
            17,
            23,
            23,
            24,
            27,
            27,
            27,
            27
        ];

        // cyber
        kyodaiRarities[3] = [255, 191, 255, 191, 191];
        kyodaiAliases[3] = [0, 1, 0, 0, 2];

        // cloth
        shateiRarities[0] = [255];
        shateiAliases[0] = [0];
        // head
        shateiRarities[1] = [255];
        shateiAliases[1] = [0];
        // face
        shateiRarities[2] = [255];
        shateiAliases[2] = [0];
        // cyber
        shateiRarities[3] = [255];
        shateiAliases[3] = [0];
    }

    function genKyodaiHash(
        uint256 tokenId,
        uint256 _alliance
    ) external returns (uint256 traitHash) {
        require(msg.sender == officialAddys[0], "unauthorized address");
        traitHash = hashKyodai(
            IGameOracle(officialAddys[2]).getRandom(tokenId),
            0,
            _alliance
        );
        // kyodaiContract.genKyodai(tokenId, hash);
    }

    function genShateiHash(
        uint256 tokenId,
        uint256 _alliance
    ) external returns (uint256 traitHash) {
        require(msg.sender == officialAddys[1], "unauthorized address");
        traitHash = hashShatei(
            IGameOracle(officialAddys[2]).getRandom(tokenId),
            0,
            _alliance
        );
        // shateiContract.genShatei(tokenId, hash);
    }

    /// @dev Determine rarity based on uint8 seed and alias
    /// @param _trait The random input from 0 - 255 to use for rarity tier.
    /// @param _alias The random input from 0 - 255 to use to determine if obtained trait or aliases.
    /// @param traitType The trait type to determined.
    function selectKyodaiTrait(
        uint32 _trait,
        uint32 _alias,
        uint8 traitType
    ) internal view returns (uint256 trait) {
        uint8[] storage rarities = kyodaiRarities[traitType];

        trait = _trait % rarities.length;
        if ((_alias % 256) > rarities[trait])
            trait = kyodaiAliases[traitType][trait];
        if (traitType == 3) ++trait; // for cyber trait in polygon, all have cyber trait
    }

    /// @notice for shatei trait, the face trait is above head trait.
    function selectShateiTrait(
        uint32 _trait,
        uint32 _alias,
        uint8 traitType
    ) internal view returns (uint256 trait) {
        uint8[] storage rarities = shateiRarities[traitType];

        trait = _trait % rarities.length;
        if ((_alias % 256) > rarities[trait])
            trait = shateiAliases[traitType][trait];
    }

    /**
     * @dev Generates a 8 digit hash from uint256 random number.
     * @param random The random numbers generated from Chainlink VRF.
     * @param nonce The custom nonce to be used within the hash.
     */

    //TODO integrate with chainlink VRF
    function hashKyodai(
        uint256 random,
        uint256 nonce,
        uint256 _alliance
    ) internal returns (uint256 currentHash) {
        require(nonce < 10);

        // TODO change to encode pack with nonce for new randomness
        uint256 seed = getRands(random, nonce);

        // legendary only for polygon
        if ((seed % 666) == 0) {
            // 1 for every 666 or 10 for every 6666 get Legendary Kyodai
            // 10 legendary Kyodai can only be found in polygon
            uint256 _special = seed % 10;
            if (!kyodaiHashToMinted.get(_special)) return _special; // return 1 out of 10 legendary kyodai
        }

        // loop 4 times for cloth, face, head, and cyber. Bg, skin, clan, and earrings don't have rarity tier so just chosen randomly without weight
        for (uint8 i = 0; i < 4; ) {
            SEED_NONCE++;

            // currentHash |= rarityGen(uint256(uint32(seed >> (i * 32))),i) << (i * 8);
            currentHash |=
                selectKyodaiTrait(
                    uint32(seed >> (i * 32)),
                    uint32(seed >> ((i + 1) * 32)),
                    i
                ) <<
                ((i + 4) * 8);

            unchecked {
                ++i;
            }
        }

        if (kyodaiHashToMinted.get(currentHash))
            return hashKyodai(random, nonce + 1, _alliance);
        kyodaiHashToMinted.set(currentHash);

        //alliance
        currentHash |= _alliance;
        //background
        currentHash |= (uint256(uint32(seed >> 160)) % 8) << 8;
        //body type
        currentHash |= (uint256(uint32(seed >> 192)) % 3) << 16;
        //earrings
        currentHash |= (uint256(uint32(seed >> 224)) % 8) << 24;
    }

    /**
     * @dev Generates a 8 digit hash from uint256 random number.
     * @param random The random numbers generated from Chainlink VRF.
     * @param nonce The custom nonce to be used within the hash.
     */

    //TODO change trait generation to suit the shatei traits
    function hashShatei(
        uint256 random,
        uint256 nonce,
        uint256 _alliance
    ) internal returns (uint256 currentHash) {
        require(nonce < 10);

        uint256 seed = getRands(random, nonce);

        // loop 4 times for cloth, cyberware, head and face. Bg, skin, clan, and earrings don't have rarity tier so just chosen randomly without weight
        for (uint8 i = 0; i < 4; ) {
            SEED_NONCE++;

            // currentHash |= rarityGen(uint256(uint32(seed >> (i * 32))),i) << (i * 8);
            currentHash |=
                selectShateiTrait(
                    uint32(seed >> (i * 32)),
                    uint32(seed >> ((i + 1) * 32)),
                    i
                ) <<
                ((i + 4) * 8);

            unchecked {
                ++i;
            }
        }

        if (shateiHashToMinted.get(currentHash))
            return hashShatei(random, nonce + 1, _alliance);
        shateiHashToMinted.set(currentHash);

        //alliance
        currentHash |= _alliance;
        //background
        currentHash |= (uint256(uint32(seed >> 160)) % 8) << 8;
        //body type
        currentHash |= (uint256(uint32(seed >> 192)) % 3) << 16;
        //earrings
        currentHash |= (uint256(uint32(seed >> 224)) % 8) << 24;
    }

    function setNewAddy(uint256 index, address newAddy) public onlyOwner {
        officialAddys[index] = newAddy;
    }

    function getRands(
        uint256 random,
        uint256 nonce
    ) internal view returns (uint256 _random) {
        _random = uint256(
            keccak256(abi.encodePacked(random, block.timestamp, nonce))
        );
    }
}
