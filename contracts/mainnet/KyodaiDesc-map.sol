// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/Libraries.sol";
import {IKyodaiDesc} from "../interfaces/Interfaces.sol";

//TODO change all from MiniMiao to CyberKyodai
//TODO add off-chain IPFS for PNG for twitter profile picture. So the art is both on and off chain
contract KyodaiDesc is IKyodaiDesc, Ownable {
    using KyodaiLibrary for *;

    string constant description =
        "Decades after oppresion from the government, a new era dawns as the Kyodais resurges to seize control over the enigmatic Neo Tokyo underworld. Reach supremacy through competitive and strategic gameplay. All Kyodais are fully generated and encoded on-chain.";
    string constant unrevealedImage = "";

    mapping(uint256 => mapping(uint256 => string)) public pngs;

    constructor() {}

    function addPNGs(
        uint256 traitType,
        uint256 traitIndex,
        string memory image
    ) public onlyOwner {
        pngs[traitType][traitIndex] = image;
    }

    // TODO add if block to return legendary kyodai metadata
    function tokenURI(
        uint256 tokenId,
        bytes20 name,
        uint256 traitHash,
        uint256 level,
        string memory baseURI
    ) external view override returns (string memory) {
        // string memory _hash = traitHash.bytes8ToString();
        // KyodaiLibrary.bytes8ToString(traitHash);
        string memory header = "data:application/json;base64,";

        //TODO uninitiated metadata and SVG
        if (traitHash == 0)
            return
                string(
                    abi.encodePacked(
                        header,
                        KyodaiLibrary.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '{"name":',
                                        string(
                                            abi.encodePacked(
                                                '"Cyber Kyodai #',
                                                tokenId.toString()
                                            )
                                        ),
                                        '", "description": "',
                                        description,
                                        '","image": "data:image/svg+xml;base64,',
                                        unrevealedImage,
                                        '","attributes":[{"trait_type":"Status","value":"Uninitiated"}]}'
                                    )
                                )
                            )
                        )
                    )
                );

        return
            string(
                abi.encodePacked(
                    header,
                    KyodaiLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":',
                                    // keccak256(abi.encodePacked(kyodai.name)) ==
                                    //     keccak256(abi.encodePacked(""))
                                    name == bytes20(0)
                                        ? string(
                                            abi.encodePacked(
                                                '"Cyber Kyodai #',
                                                tokenId.toString()
                                                // KyodaiLibrary.toString(tokenId)
                                            )
                                        )
                                        : string(
                                            abi.encodePacked(
                                                '"',
                                                name.bytes20ToString()
                                            )
                                        ),
                                    '", "description": "',
                                    description,
                                    '",',
                                    keccak256(abi.encodePacked(baseURI)) ==
                                        keccak256(abi.encodePacked(""))
                                        ? '"image_data": "'
                                        : string(
                                            abi.encodePacked(
                                                '"image":"',
                                                baseURI,
                                                tokenId,
                                                '.png","vector": "'
                                            )
                                        ),
                                    "data:image/svg+xml;base64,",
                                    // KyodaiLibrary.encode(
                                    //     bytes(hashToSVG(_hash))
                                    // ),
                                    bytes(hashToSVG(traitHash)).encode(),
                                    '","attributes":',
                                    hashToMetadata(traitHash, level),
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(
        // string memory _hash
        uint256 traitHash
    ) internal view returns (string memory) {
        /* hash order: 
    0 - alliance
    8 - background
    16 - body
    24 - earring
    32 - cloth
    40 - cyber
    48 - face
    56 - head
    */
        if (traitHash < 11) {
            // legendary SVG
        }
        string
            memory imgHeader = '<image width="84" height="84" image-rendering="pixelated" preserveAspectRatio="xMidYMid" href="data:image/png;base64,';
        string memory imgFooter = '"/>';
        string[9] memory parts;

        //head  // TODO buat shatei, headnya ga ada none
        parts[0] = uint256(uint8(traitHash >> 48)) == 0
            ? ""
            : string(
                abi.encodePacked(
                    imgHeader,
                    pngs[0][uint256(uint8(traitHash >> 48))],
                    imgFooter
                )
            );

        //face
        parts[1] = uint256(uint8(traitHash >> 40)) == 0
            ? ""
            : string(
                abi.encodePacked(
                    imgHeader,
                    pngs[1][uint256(uint8(traitHash >> 40))],
                    imgFooter
                )
            );

        //earring
        parts[2] = uint256(uint8(traitHash >> 24)) == 0
            ? ""
            : string(
                abi.encodePacked(
                    imgHeader,
                    pngs[2][uint256(uint8(traitHash >> 24))],
                    imgFooter
                )
            );

        //attire
        parts[3] = uint256(uint8(traitHash >> 32)) == 0
            ? ""
            : string(
                abi.encodePacked(
                    imgHeader,
                    pngs[3][uint256(uint8(traitHash >> 32))],
                    imgFooter
                )
            );

        //cyber
        parts[4] = uint256(uint8(traitHash >> 56)) == 0
            ? ""
            : string(
                abi.encodePacked(
                    imgHeader,
                    pngs[4][uint256(uint8(traitHash >> 56))],
                    imgFooter
                )
            );

        //irezumi
        parts[5] = string(
            abi.encodePacked(
                imgHeader,
                pngs[5][uint256(uint8(traitHash))],
                imgFooter
            )
        );

        //body
        parts[6] = string(
            abi.encodePacked(
                imgHeader,
                pngs[6][uint256(uint8(traitHash >> 16))],
                imgFooter
            )
        );

        //logo
        parts[7] = string(
            abi.encodePacked(
                imgHeader,
                pngs[7][uint256(uint8(traitHash))],
                imgFooter
            )
        );

        //background
        parts[8] = string(
            abi.encodePacked(
                imgHeader,
                pngs[8][uint256(uint8(traitHash >> 8))],
                imgFooter
            )
        );
        return
            string(
                abi.encodePacked(
                    '<svg id="kyodai" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" image-rendering="pixelated" viewBox="0 0 84 84" style="shape-rendering:crispedges"> ',
                    parts[8], // background
                    parts[7], // clan logo
                    parts[6], // body
                    parts[5], // irezumi
                    parts[4], // cyber
                    parts[3], // cloth
                    parts[2], // earring
                    parts[1], // face
                    parts[0], // head
                    "<style>#kyodai{image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
                )
            );
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(
        // string memory _hash,
        uint256 traitHash,
        uint256 level
    ) internal view returns (string memory) {
        /* hash order: 
    0 - alliance
    8 - background
    16 - body
    24 - earring
    32 - cloth
    40 - cyber
    48 - face
    56 - head
       */

        if (traitHash < 11) {
            // legendary metadata
        }
        string memory _traitType = '{"trait_type":"';
        string memory metadataString;
        string[7] memory traitNames;
        traitNames[0] = allianceNames[uint256(uint8(traitHash))];
        traitNames[1] = bgNames[uint256(uint8(traitHash >> 8))];
        traitNames[2] = earringNames[uint256(uint8(traitHash >> 24))];
        traitNames[3] = attireNames[uint256(uint8(traitHash >> 32))];
        traitNames[4] = faceNames[uint256(uint8(traitHash >> 40))];
        traitNames[5] = headNames[uint256(uint8(traitHash >> 48))];
        traitNames[6] = cyberNames[uint256(uint8(traitHash >> 56))];

        for (uint i = 0; i < 7; ) {
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    _traitType,
                    traitTypes[i],
                    '","value":"',
                    traitNames[i],
                    '"},'
                )
            );

            // if (i != 5)
            //   metadataString = string(abi.encodePacked(metadataString, ","));

            unchecked {
                ++i;
            }
        }

        metadataString = string(
            abi.encodePacked(
                metadataString,
                _traitType,
                "Level",
                '","value":',
                level.toString(),
                "}"
            )
        );
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    string[7] traitTypes = [
        "Alliance",
        "Background",
        "Earring",
        "Attire",
        "Face",
        "Head",
        "Cyberware"
    ];

    string[8] bgNames = [
        "Blue",
        "Green",
        "Purple",
        "Red",
        "Blue",
        "Green",
        "Purple",
        "Red"
    ];

    string[3] allianceNames = ["Ryuichi-kai", "Torahide-gumi", "Nobu-rengo"];
    string[10] earringNames = [
        "None",
        "Cross",
        "Diamond",
        "Helix",
        "Hoop",
        "Red Stud",
        "Bar",
        "Black Stud"
    ];
    string[34] attireNames = [
        "None",
        "Jail Jumpsuit",
        "Jersey",
        "Kimono",
        "Kombini",
        "Leather Jacket",
        "Nanowave Jacket",
        "Neon Hoodie",
        "Rocker Jacket",
        "Sarashi",
        "School Uniform",
        "Shirt",
        "Suit With Scarf",
        "Suit",
        "Sukajan Nobu",
        "Sukajan Ryu",
        "Sukajan Tora",
        "Tactical Vest",
        "Tanktop",
        "Techwear Hoodie",
        "Techwear Kimono",
        "Techwear Turtleneck",
        "Training Suit",
        "Turtleneck Suit",
        "Varsity Jacket",
        "Akira",
        "Bartender",
        "Bloodstain Tanktop",
        "Body Suit",
        "Coat",
        "Cyborg",
        "Dress Shirt",
        "Fastfood Apron",
        "Fur Collar Jacket"
    ];
    string[50] headNames = [
        "None",
        "Cowboy Hat",
        "Crew Cut",
        "Curtain Platinum",
        "Curtain",
        "Cyber Jingasan",
        "Faux Hawk Red",
        "Flatcap",
        "Gentelman Hat",
        "Jojo Cap",
        "Mullet Kinpatsu",
        "Mullet",
        "Pompadour",
        "Punchperm",
        "Punk Cap",
        "Punk",
        "Skate Helmet",
        "Skinhead",
        "Slick Curtain",
        "Slick Curtain",
        "Snapback",
        "Spiky Blue",
        "Suave Cut",
        "Suave Undercut Red",
        "Suave Undercut",
        "Swept Back",
        "Techcap",
        "Trucker Cap",
        "Twisted Hachimaki",
        "Undercut Dredlock",
        "Undercut Dredlock Green",
        "Undercut Green",
        "Undercut",
        "Ushanka",
        "Visor Cap",
        "Zero Hachimaki",
        "Akira",
        "Bandana",
        "Banie",
        "Baseball Cap",
        "Bowlcut",
        "Braided Ombre",
        "Braided",
        "Buckethat",
        "Bun",
        "Buzz Cut Kinpatsu",
        "Buzz Cut",
        "Buzz Mohawk",
        "Chonmage",
        "Conical Hat"
    ];

    string[24] faceNames = [
        "None",
        "Halfmask Hannya",
        "Hannya Mask",
        "Jason Mask",
        "Led Mask",
        "Pipe Smoke",
        "Scar",
        "Skull Half Face",
        "Sun Glasses",
        "Tactical Mask",
        "Aviator Glasses",
        "Bandaid",
        "Bandana Mask",
        "Beard And Moustache",
        "Bloodstain",
        "Bubblegum",
        "Cigarette",
        "Cyclop Glasses",
        "Cyclop",
        "E-Smoker",
        "Eye Patch",
        "Eyes",
        "Gasmask",
        "Glasses"
    ];

    string[5] cyberNames = [
        "None",
        "Jaw Half Neck",
        "Neck",
        "Cyber 1",
        "Cyber 2"
    ];
}
