// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IGameOracle} from "../interfaces/Interfaces.sol";

contract GameOracle is IGameOracle, VRFConsumerBaseV2, Ownable {
    struct RequestRandom {
        uint256 requestId;
        uint256 randomness;
        uint248 tokenId;
        uint8 fulfilled; // 1 - false || 2 - true
    }

    VRFCoordinatorV2Interface vrfCoordinator;
    LinkTokenInterface LINK;
    uint256 subscriptionId;
    bytes32 keyHash;

    // 1 - false || 2 - true
    mapping(address => uint256) public authorizedAddys;

    // mapping tokenId to RequestRandom details
    mapping(uint256 => RequestRandom) public randoms; // --> in shatei contract

    // mapping requestId to tokenId
    mapping(uint256 => uint256) public randomIds;

    constructor(
        address link_,
        address vrfCoordinator_,
        uint256 subId_,
        bytes32 keyHash_
    ) VRFConsumerBaseV2(vrfCoordinator_) {
        // keyHash for Polygon mainnet at 500 gwei limit: 0xcc294a196eeeb44da2888d17c0625cc88d70d9760a69d58d853ba6581a9ab0cd

        LINK = LinkTokenInterface(link_);
        vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
        subscriptionId = subId_;
        keyHash = keyHash_;
    }

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomWords the VRF output expanded to the requested number of words
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        RequestRandom storage request = randoms[randomIds[requestId]];
        request.randomness = randomWords[0];
        request.fulfilled = 2;
    }

    function requestRandom(uint256 tokenId) external override {
        require(authorizedAddys[msg.sender] == 2, "not authorized");
        RequestRandom storage request = randoms[tokenId];
        require(request.requestId == 0, "wait for VRF");
        uint256 _requestId = _requestRandomWords();
        randomIds[_requestId] = tokenId;
        randoms[tokenId] = RequestRandom(_requestId, 0, uint248(tokenId), 1);
    }

    function _requestRandomWords() internal returns (uint256 s_requestId) {
        s_requestId = vrfCoordinator.requestRandomWords(
            //TODO change config to polygon version VRF
            keyHash,
            uint64(subscriptionId),
            3,
            2500000,
            1
        );
    }

    function getRandom(uint256 tokenId) external returns (uint256 random) {
        RequestRandom storage request = randoms[tokenId];
        require(request.fulfilled == 2, "wait for VRF");

        random = request.randomness;

        delete randomIds[request.requestId];
        request.requestId = 0;
        request.randomness = 0;
        request.fulfilled = 1;
        // delete randoms[tokenId];
    }

    // function initialize(
    //     address link_,
    //     address vrfCoordinator_,
    //     uint256 subId_,
    //     bytes32 keyHash_
    // ) external onlyOwner {
    //     LINK = LinkTokenInterface(link_);
    //     vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator_);
    //     subscriptionId = subId_;
    //     keyHash = keyHash_;
    // }

    function forceFullfill(
        uint256 requestId,
        uint248 tokenId,
        uint256 rand
    ) external onlyOwner {
        randomIds[requestId] = tokenId;
        randoms[tokenId] = RequestRandom(requestId, rand, tokenId, 2);
    }

    // 1 - false || 2 - true
    function setAuth(address address_, uint256 auth_) external onlyOwner {
        authorizedAddys[address_] = auth_;
    }
}
