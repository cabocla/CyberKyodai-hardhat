// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../utils/Libraries.sol";
import "../interfaces/Interfaces.sol";

contract TraitGen is ITraitGen {
    using KyodaiLibrary for uint8;
    using BitMaps for BitMaps.BitMap;

    uint256 internal SEED_NONCE;

    // mapping of index hash to index bool.
    // Key is mapping index, Value is uint containing bits as bool.
    // Hash is pointer to bit location in uint256.
    BitMaps.BitMap internal kyodaiHashToMinted;

    uint8[][4] public rarities;
    uint8[][4] public aliases;

    bytes32 internal entropySauce;
    address internal kyodaiAddy;

    constructor(address _kyodaiAddy) {
        // TODO change rarities and aliases value
        // TODO lower rarity than polygon TraitGen
        // TODO only half of total trait in Ethereum, other half can be generated in Polygon to prevent identical trait

        kyodaiAddy = _kyodaiAddy;
        // background, skin, clan, and earring traits have the same weight so no need rarity tier
        kyodaiHashToMinted.set(0);
        // cloth
        rarities[0] = [
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
        aliases[0] = [
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
        rarities[1] = [255, 30, 60, 60, 150, 156];
        aliases[1] = [0, 0, 0, 0, 0, 0];

        // head
        rarities[2] = [
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
        aliases[2] = [
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
        rarities[3] = [255];
        aliases[3] = [0];
    }

    //TODO determine clan based on owned kyodai clan
    function genKyodaiHash(
        uint256 _t,
        address _a,
        uint256 _c,
        uint256 _alliance
    ) external override returns (uint256) {
        require(msg.sender == kyodaiAddy, "unauthorized");
        return hashKyodai(_t, _a, _c, _alliance);
    }

    /// @dev Determine rarity based on uint16 seed and alias
    ///  @param _trait The input from 0 - 255 to use for rarity tier.
    ///  @param traitType The trait type to determined.

    function selectTrait(
        uint32 _trait,
        uint32 _alias,
        uint16 traitType
    ) internal view returns (uint256 trait) {
        uint8[] storage _rarities = rarities[traitType];
        trait = _trait % _rarities.length;
        if ((_alias % 256) > _rarities[trait])
            trait = aliases[traitType][trait];
    }

    /**
     * @dev Generates a 7 digit hash from a tokenId, address, and random number.
     * @param _t The token id to be used within the hash.
     * @param _a The address to be used within the hash.
     * @param _c The custom nonce to be used within the hash.
     */

    //TODO integrate with chainlink VRF
    function hashKyodai(
        uint256 _t,
        address _a,
        uint256 _c,
        uint256 _alliance
    ) internal returns (uint256 currentHash) {
        require(_c < 10);

        // This will generate a 6 character string.
        // string memory currentHash;
        uint256 seed = getRandInput(_t, _a, _c);

        // loop 3 times for cloth, face, and head. Cyberware only available on polygon trait gen. Bg, body type, clan, and earrings don't have rarity tier so just chosen randomly without weight
        SEED_NONCE++;
        for (uint8 i = 0; i < 3; ) {
            // currentHash |= rarityGen(uint256(uint32(seed >> (i * 32))),i) << (i * 8);
            currentHash |=
                selectTrait(
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
            return hashKyodai(_t, _a, _c + 1, _alliance);

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

    function getRandInput(
        uint256 _t,
        address _a,
        uint256 _c
    ) internal view returns (uint256) {
        return
            // uint16(
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.prevrandao,
                        _t,
                        _a,
                        _c,
                        SEED_NONCE
                    )
                )
            );
        // % 10000 );
    }
}
