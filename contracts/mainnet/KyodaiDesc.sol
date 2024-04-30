// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../utils/Libraries.sol";
import {IKyodaiDesc} from "../interfaces/Interfaces.sol";

//TODO change all from MiniMiao to CyberKyodai
//TODO add off-chain IPFS for PNG for twitter profile picture. So the art is both on and off chain
//TODO ue zipped contract
contract KyodaiDesc1 is IKyodaiDesc {
    using KyodaiLibrary for *;

    string constant description =
        "Decades after oppresion from the government, a new era dawns as the Kyodais resurges to seize control over the enigmatic Neo Tokyo underworld. Reach supremacy through competitive and strategic gameplay. All Kyodais are fully generated and encoded on-chain.";
    string constant unrevealedImage = "";

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

        //TODO
        if (traitHash == 0)
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        KyodaiLibrary.encode(
                            bytes(
                                string(
                                    abi.encodePacked(
                                        '{"name":Cyber Kyodai #',
                                        tokenId.toString(),
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
                    "data:application/json;base64,",
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
                                                name,
                                                '", "description": "'
                                            )
                                        ),
                                    description,
                                    '",',
                                    keccak256(abi.encodePacked(baseURI)) ==
                                        keccak256(abi.encodePacked(""))
                                        ? '"image_data": "'
                                        : string(
                                            abi.encodePacked(
                                                '"image": "',
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
        string
            memory imgHeader = '<image width="85" height="85" image-rendering="pixelated" preserveAspectRatio="xMidYMid" href="data:image/png;base64,';
        string memory imgFooter = '"/>';
        string[9] memory parts;

        //head
        parts[0] = string(
            abi.encodePacked(
                imgHeader,
                headSVGs[uint256(uint8(traitHash >> 56))],
                imgFooter
            )
        );

        //face
        parts[1] = string(
            abi.encodePacked(
                imgHeader,
                faceSVGs[uint256(uint8(traitHash >> 48))],
                imgFooter
            )
        );

        //earring
        parts[2] = string(
            abi.encodePacked(
                imgHeader,
                earringSVGs[uint256(uint8(traitHash >> 24))],
                imgFooter
            )
        );

        //attire
        parts[3] = string(
            abi.encodePacked(
                imgHeader,
                attireSVGs[uint256(uint8(traitHash >> 32))],
                imgFooter
            )
        );
        //attire
        parts[4] = string(
            abi.encodePacked(
                imgHeader,
                cyberSVGs[uint256(uint8(traitHash >> 40))],
                imgFooter
            )
        );
        //irezumi
        parts[5] = string(
            abi.encodePacked(
                imgHeader,
                irezumiSVGs[uint256(uint8(traitHash))],
                imgFooter
            )
        );
        //body
        parts[6] = string(
            abi.encodePacked(
                imgHeader,
                bodySVGs[uint256(uint8(traitHash >> 16))],
                imgFooter
            )
        );
        //logo
        parts[7] = string(
            abi.encodePacked(
                imgHeader,
                logoSVGs[uint256(uint8(traitHash))],
                imgFooter
            )
        );
        //background
        parts[8] = string(
            abi.encodePacked(
                imgHeader,
                bgSVGs[uint256(uint8(traitHash >> 8))],
                imgFooter
            )
        );
        return
            string(
                abi.encodePacked(
                    // TODO logo clan disesuain ke ukuran 84x84 px
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
                    "<style>#kyodai{shape-rendering: crispedges; image-rendering: -webkit-crisp-edges; image-rendering: -moz-crisp-edges; image-rendering: crisp-edges; image-rendering: pixelated; -ms-interpolation-mode: nearest-neighbor;}</style></svg>"
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

        string memory metadataString;

        for (uint i = 0; i < 8; ) {
            uint256 thisTraitIndex = uint256(uint8(traitHash >> (i * 8)));
            string memory traitName;

            //TODO checking trait category gausah pake loop. loop cuma buat iterate aarray traitName aja
            if (i == 0) {
                traitName = allianceNames[thisTraitIndex];
            }
            if (i == 1) {
                traitName = bgNames[thisTraitIndex];
            }

            if (i == 3) {
                traitName = earringNames[thisTraitIndex];
            }
            if (i == 4) {
                traitName = attireNames[thisTraitIndex];
            }
            if (i == 5) {
                traitName = cyberNames[thisTraitIndex];
            }
            if (i == 6) {
                traitName = faceNames[thisTraitIndex];
            }
            if (i == 7) {
                traitName = headNames[thisTraitIndex];
            }

            if (i != 2)
                metadataString = string(
                    abi.encodePacked(
                        metadataString,
                        '{"trait_type":"',
                        traitTypes[i],
                        '","value":"',
                        traitName,
                        '"}'
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
                '{"trait_type":"Level","value":"',
                level,
                '"}'
            )
        );
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    string[7] traitTypes = [
        "Alliance",
        "Background",
        "Earring",
        "Attire",
        "Cyberware",
        "Face",
        "Head"
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

    string[8] earringSVGs;
    string[3] logoSVGs;
    string[3] bodySVGs;
    string[3] irezumiSVGs;
    string[5] cyberSVGs;
    string[34] attireSVGs;
    string[24] faceSVGs;
    string[50] headSVGs;
    string[8] bgSVGs;

    constructor() {
        // TODO out of gas when deploying descriptor. Turn PNG list into mapping and put one by one through transaction. Or use zipped contract

        earringSVGs = [
            "",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAQMAAAACOzoZAAAABlBMVEUAAADExMQAXpOwAAAAAXRSTlMAQObYZgAAABhJREFUKM9jGAUjAbAgsfnQxBHsUTCiAAA4hgAboyH+QAAAAABJRU5ErkJggg==",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAADFBMVEUAAACoqKjMzMyEhIRCK1XTAAAAAXRSTlMAQObYZgAAABxJREFUOMtjGAWjYBQMcjABu3ABwygYBaNgeAMA+sABAay0ymwAAAAASUVORK5CYII=",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAADFBMVEUAAAAWFhYzMzNoaGh6ke9yAAAAAXRSTlMAQObYZgAAADJJREFUOMtjGAWjYCgABezCBtiFBXCY0oBVlJEklzA2UNlrhN39ALtwAMMoGAWjYHgDAG/mAqOHHIzhAAAAAElFTkSuQmCC",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAADFBMVEUAAADciwDEfACbYgDZXRNvAAAAAXRSTlMAQObYZgAAAB9JREFUOMtjGAWjYBQMcqCAXVgAu7ABwygYBaNgmAAAfIIAYZrnPGgAAAAASUVORK5CYII=",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAADFBMVEUAAACYAD66AExwAC5eTLu2AAAAAXRSTlMAQObYZgAAABxJREFUOMtjGAWjYBQMcjABu3ABwygYBaNgeAMA+sABAay0ymwAAAAASUVORK5CYII=",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAACVBMVEUAAAAdHR1JSUlX2J/DAAAAAXRSTlMAQObYZgAAACNJREFUOMtjGAWjYBQMcqBAkmoBkoQVcAiTaPYoGAWjgBYAAFIhAKGHkYGbAAAAAElFTkSuQmCC",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAADFBMVEUAAAArKys/Pz8TExPZz1czAAAAAXRSTlMAQObYZgAAABxJREFUOMtjGAWjYBQMcjABu3ABwygYBaNgeAMA+sABAay0ymwAAAAASUVORK5CYII="
        ];
        logoSVGs = [
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAgMAAABFm0DJAAAADFBMVEUAAAAAAAAAAAAAAAA16TeWAAAABHRSTlMAWVUEEF8erQAAASNJREFUOMvtlMFtwzAMRdnW3KA6dIDuwRF0ILtB91+hNfWlL8so6kMC5JAPxBQfqC+CkS1P/aGXiNoD9Rq/MpGI+Jp42bGLxq6pOGXfGXr5WxZTPO8gupPRept55sA0MmIdPYbvy3dilNuMM/kY5/mMFR7Etbu0xQELrIm9z4spo4YfcWA0te1yQY7BWMMVGHkPHWPxySwVaAUnGTA629AnsSVmgoKaGDOQgX1gJVZuFIwR2E9LzpQr3gfjgjjzCGL+7T0MKW8sTuQtrD1Q8ESgObFM0pYXWNMcOK2pgWnNCelFXDqWSxgv9z2wAvutcYKKJzXq9CIWYLuGS8Oy4sBjbRxb1lbwpi4Ky9+qsmM5SSu+JItc1OQsxSdtlZk8iDb5Vz/vR3/oTfhcgQAAAABJRU5ErkJggg==",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAQMAAAACOzoZAAAABlBMVEUAAAAAAAClZ7nPAAAAAnRSTlMAWWQkJGgAAABOSURBVCjPYxgZoP4/CHwAs/+DwQ8QkxHC/kMZG2Emil0QIP//ANwV/P8b4Gz2/wwUsxFmIuyCOg3uOGYY+x9t2Ai7CPqX1n4f8LgeYgAAqbb9tZWxiF4AAAAASUVORK5CYII=",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVAQMAAAACOzoZAAAABlBMVEUAAAAAAAClZ7nPAAAAAnRSTlMAWWQkJGgAAAC3SURBVCjP1ZOxDcMwDATfcKHSI2gULRbAHk2jeASXLAJ9aMoBIShunKTwF8IVhPhPifhSBRil4sgFU6kcmBFZeeKKxMU4csPM3HGigFx/xWe9Oj/B+PCvNamgaq+XgwfBA85PvEXKR565tdzXDORxT9HG1ENsgoGkTTEwG0ea40l5Udd7EmNN03CiROVMS1R1if2es16NH/fZ+vdcnvfarJx9/s79e407F/j73uIf+r74Hvl+/UUvo9pWjKQ1RSMAAAAASUVORK5CYII="
        ];
        bodySVGs = [
            "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"
        ];
        irezumiSVGs = [
            "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"
        ];
        cyberSVGs = [
            "",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVBAMAAADK27VpAAAAGFBMVEUAAAAtLS1DQ0NYWFggICBnZ2f/OwDGLgBaW26KAAAAAXRSTlMAQObYZgAAARBJREFUSMftkkFuwyAQRQe72XtsDmA+6t6GqmsTcYJcogfo/aWOWzu7wHQRqZV4smQJPb4+DNRoNBpE/dPcRS8vf6GwXu48qZmfdrjuF8FhVps9tKeL6OGULuaodXv5wKQkBs/0ogsOULsRWC1llbvH2qxzo7g56dz+x9107mqTtSr34l3OiVUlbsGm/KYqfIHbzNWnWoko3GDJsE9ccQPwKrHEmJKrlOgAOEs0hjTKv4hhZruJ65N3tcJZ2PdMaZ8zlTmyTAq2esXD6a5XgPOmcIlHIMa11Hm9u3j/+BS5NIvTnWQqARgeq4jL0TdGSA1XUBmnG8Bk+GGsARPf+7IsDIWhkZpvdT4eBjUajf/BF1qGJDk1EaioAAAAAElFTkSuQmCC",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVBAMAAADK27VpAAAAFVBMVEUAAAAbGxsxMTFJSUlcXFx4eHijo6PHUV8eAAAAAXRSTlMAQObYZgAAALhJREFUSMftk9ENglAMRYt1AG43aAn+gzoBE2BcwA/3X8HXMACXP0N6Ev5OTm4hSFEURVH8JQ9e1UUurPtsbk9m37ME74b37IQAjrgg39hsrKuLp0tmYQ6QWYzgjru27AdBuS17W8GNaNkv9o/TfBy2wvYHRwMpOnHbACBFT5VzAyAOm9LNFR3lmsGY7n3ILIz5EprNdIVwEZ6uMK5tGzquG2B/oGl88e6RLhKhUGxZOiwkmtmiOBc/OW0W1wbsr40AAAAASUVORK5CYII=",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVBAMAAADK27VpAAAALVBMVEUAAADMsqFDQ0MoKCiFaldfX199XUZSQTZyUDmMdGS3l4PExMTu0QCahnnFrQCisW/6AAAAAXRSTlMAQObYZgAAAM1JREFUSMftkrENwjAUBZ+RiYAKr+CIHuEFXDAAipSKhooJkNIwREZgBxZhEIYAftLnCmiQT/KvTqcv2yoUJliPA+A+I8AsV50dnl1Tl2fdmPX7jN3rc49X6LoLd6XJsAvB1pVMJt2sacIwvCZZBmft0AswuBJ2H9TlLMaj6iRKlStBzqZSPNjXxvfdygb7EDd7apRdyeiVsbv0wq7P+mPmUZS2qXH1GLc4e0+iNIll21aKCV5APMzhtrN6t4m1mJtSxJeQ3qhQKBQKP+YFD+oTeixfy50AAAAASUVORK5CYII=",
            "iVBORw0KGgoAAAANSUhEUgAAAFUAAABVBAMAAADK27VpAAAAJFBMVEUAAACtl4ieg3AeHh55ZFaNaU+BWkA2NjaXeGJzW0vKsgCVggCcsVwHAAAAAXRSTlMAQObYZgAAAKhJREFUSMdjGAWjgHpAAEwKEqOUEaKUeGMZiXQChCDOCSSohRBDyrkgtQbEe415AfFqrUgwd/EGwmpZoYQ1A/FqNxCrlo2wOogymoK0AKJcy5YAxEAW0YAktUxUV+sCJjmIM7ADRLUT9pGSkhIDQxOQLCZsqiWEmm5ORJKshFCTiTCWwQRCORsQoZYFQjkQFWIOEB1UV8sC1kCS2lEwCkbBKBgFo2DQAQAIOQ164r+UAwAAAABJRU5ErkJggg=="
        ];
        attireSVGs = [
            "",
            "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"
        ];
        faceSVGs = [
            "",
            "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"
        ];

        headSVGs = [
            "",
            "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"
        ];

        bgSVGs = [
            "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"
        ];
    }
}
