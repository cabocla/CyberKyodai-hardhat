// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "./token/ERC1155/ERC1155.sol";
import "../interfaces/Interfaces.sol";
import "../utils/Libraries.sol";

//TODO add boost item to increase kyodai level instantly. And other premium boost item
contract Pinkie is ERC1155, IPinkie, ERC2981, Ownable {
    using KyodaiLibrary for *;

    // 1 - false || 2 - true
    mapping(address => uint256) public authorizedAddys;

    string[15] tokenColor = [
        "#ebbd91",
        "#ffffff",
        "#b8b6c4",
        "#fff88c",
        "#433f6b"
    ];

    // TODO SVGs of pinkie of Borg, Doper, & Runner
    string[3] pinkeSVGs = ["", "", ""];

    string[5] tierName = ["Iron", "Bronze", "Silver", "Gold", "Platinum"];
    string[3] className = ["Borg", "Doper", "Runner"];

    constructor()
        ERC1155("")
    {}

    // ID start at 1
    function mint(uint256 tokenId, address who_) external override {
        require(authorizedAddys[msg.sender] == 2, "not authorized");
        _mint(who_, tokenId, 1, "");
    }

    function burn(
        uint256 tokenId,
        address who_,
        uint256 amount_
    ) external override {
        require(authorizedAddys[msg.sender] == 2, "not authorized");
        _burn(who_, tokenId, amount_);
    }

    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Pinkie #',
                                _tokenId.toString(),
                                //TODO edit desctription
                                '", "description": "Pinkie to mint Kyodai and Shatei. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API.","image": "data:image/svg+xml;base64,',
                                bytes(getTokenSVG(_tokenId)).encode(),
                                '","attributes":',
                                hashToMetadata(_tokenId),
                                "}"
                            )
                        )
                    ).encode()
                )
            );
    }

    function getTokenSVG(
        uint256 _tokenId
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg id="pinkie" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg" image-rendering="pixelated" viewBox="0 0 24 24" style="shape-rendering:crispedges">',
                    string(
                        abi.encodePacked(
                            '<path style="fill:',
                            tokenColor[_tokenId],
                            '" d="M5 8h1v1H5Zm0 1h1v1H5Zm0 1h1v1H5Zm0 1h1v1H5Zm0 1h1v1H5Zm1 1h1v1H6Zm1 3h1v1H7Zm0-1h1v1H7Zm0-1h1v1H7Zm1 0h1v1H8Zm1 0h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm-5 3h1v1H7Zm1 0h1v1H8Zm1-1h1v1H9Zm0 1h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm2-1h1v1h-1zm-1 1h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1Zm-1-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm0 1h1v1h-1zm1 1h1v1h-1zm0 1h1v1h-1zm-1 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1Zm-1-1h1v1h-1zm-1 1h1v1h-1zm-1 1h1v1h-1zm-1 0h1v1h-1ZM9 8h1v1H9ZM8 8h1v1H8ZM7 7h1v1H7ZM6 6h1v1H6ZM5 7h1v1H5Z"/>'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            '<path style="fill:',
                            tokenColor[_tokenId],
                            '" d="M8 15h1v1H8Zm1 0h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0 1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm1 1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm1 0h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-8 1h1v1H8Zm2 0h1v1h-1zm-1 0h1v1H9Zm3 0h1v1h-1zm0-1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1H9Zm-1 0h1v1H8Zm3 2h1v1h-1zm-1 0h1v1h-1zm-2 0h1v1H8Zm-1 0h1v1H7Zm0-2h1v1H7Zm-1 0h1v1H6Zm0 1h1v1H6Zm0 1h1v1H6Zm1 1h1v1H7Zm1 0h1v1H8Zm1 0h1v1H9Zm1 0h1v1h-1zm1 0h1v1h-1zm1-1h1v1h-1zm0 1h1v1h-1zm1-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-1h1v1h-1zm0-2h1v1h-1zm-1 1h1v1h-1zm0 1h1v1h-1zm-1 0h1v1h-1zm-1 0h1v1h-1ZM9 9h1v1H9ZM8 9h1v1H8ZM7 9h1v1H7ZM6 9h1v1H6Zm1-1h1v1H7Zm2 4h1v1H9ZM6 7h1v1H6Z"/>'
                        )
                    ),
                    '<path style="fill:#ff8acb" d="M13 8h1v1h-1ZM6 8h1v1H6Z"/></svg>'
                )
            );
    }

    function hashToMetadata(
        uint256 _tokenId
    ) internal view returns (string memory) {
        string memory metadataString;
        for (uint8 i = 0; i < 2; ) {
            string memory traitType;
            string memory traitName;
            if (i == 0) {
                traitType = "Tier";
                traitName = tierName[uint16((_tokenId - 1) / 3)];
            }
            if (i == 1) {
                traitType = "Class";
                traitName = className[_tokenId % 3];
            }
            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    traitName,
                    '"}'
                )
            );
            if (i != 5)
                metadataString = string(abi.encodePacked(metadataString, ","));
            unchecked {
                ++i;
            }
        }
        return string(abi.encodePacked("[", metadataString, "]"));
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override  {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    // 1 - false || 2 - true
    function setAuth(address address_, uint256 auth_) external onlyOwner {
        authorizedAddys[address_] = auth_;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}
