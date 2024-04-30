// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {IKyodaiDesc} from "../interfaces/Interfaces.sol";

contract KyodaiDescOffChain is IKyodaiDesc, Ownable {
    string public url;

    constructor(string memory _url) {
        url = _url;
    }

    function tokenURI(
        uint256 tokenId,
        bytes20 name,
        uint256 traitHash,
        uint256 level,
        string memory baseURI
    ) external view returns (string memory) {
        return getTokenURI(tokenId, traitHash);
    }

    function getTokenURI(
        uint256 tokenId,
        uint256 traitHash
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    url,
                    "?tokenId=",
                    Strings.toString(tokenId),
                    "&trait=",
                    Strings.toString(uint64(traitHash))
                )
            );
    }

    function changeURL(string memory newURL) public onlyOwner {
        url = newURL;
    }
}
