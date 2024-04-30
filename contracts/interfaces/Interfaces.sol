// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../utils/Libraries.sol";

// interface KyodaiContext {
//     enum Action {
//         UNSTAKED,
//         AWAY,
//         TRAINING,
//         FARMING
//     }

//     struct Kyodai {
//         uint32 lvlProgress;
//         uint16 level;
//         bytes8 traitHash;
//         bytes18 name;
//     }

//     struct Activity {
//         address location;
//         Action action;
//         uint88 timestamp;
//     }
// }

interface ITraitGen {
    function genKyodaiHash(
        uint256 _t,
        address _a,
        uint256 _c,
        uint256 _alliance
    ) external returns (uint256);
}

interface ITraitGenPoly {
    function genKyodaiHash(
        uint256 tokenId,
        uint256 _alliance
    ) external returns (uint256 traitHash);

    function genShateiHash(
        uint256 tokenId,
        uint256 _alliance
    ) external returns (uint256 traitHash);
}

interface IKyodaiDesc {
    function tokenURI(
        uint256 tokenId,
        bytes20 name,
        uint256 traitHash,
        uint256 level,
        string memory baseURI
    ) external view returns (string memory);
}

interface IKyodai {
    function ownerOf(uint256 tokenId) external view returns (address);

    // function checkLevel(uint256 tokenId) external returns (uint16);
    function getKyodai(uint256 tokenId) external returns (uint256);

    function getManyKyodai(
        uint256[] calldata tokenIds
    ) external returns (uint256[] memory);
}

interface IShatei {
    // enum Class {
    //     DRUGGIE,
    //     HACKER,
    //     CYBORG
    // }

    function ownerOf(uint256 tokenId) external view returns (address);

    // function checkLevel(uint256 tokenId) external returns (uint16);

    // function checkClass(uint256 tokenId) external returns (Class);
    // function mint(uint256 tagId) external;
    function burn(uint256 tokenId, address who) external;

    function getKyodai(uint256 tokenId) external returns (uint256);

    function getManyKyodai(
        uint256[] calldata tokenIds
    ) external returns (uint256[] memory);
}

interface IKyodaiPoly {
    function ownerOf(uint256 tokenId) external view returns (address);

    // function checkLevel(uint256 tokenId) external returns (uint16);
    function getKyodai(uint256 tokenId) external returns (uint256);

    function getManyKyodai(
        uint256[] calldata tokenIds
    ) external returns (uint256[] memory);

    function burn(uint256 tokenId, address who) external;

    function burnAuth(uint256 tokenId) external;
}

interface IShateiPoly {
    // enum Class {
    //     DRUGGIE,
    //     HACKER,
    //     CYBORG
    // }

    function ownerOf(uint256 tokenId) external view returns (address);

    // function checkLevel(uint256 tokenId) external returns (uint16);

    // function checkClass(uint256 tokenId) external returns (Class);
    // function mint(uint256 tagId) external;
    function getKyodai(uint256 tokenId) external returns (uint256);

    function getManyKyodai(
        uint256[] calldata tokenIds
    ) external returns (uint256[] memory);

    function burn(uint256 tokenId, address who) external;

    function burnAuth(uint256 tokenId) external;
}

interface INeoYen {
    function mint(address to, uint256 amount) external;

    function burnAuth(address from, uint256 amount) external;

    // function burn(address from, uint256 amount) external;
}

interface IPinkie {
    function mint(uint256 tokenId, address who_) external;

    function burn(uint256 tokenId, address who_, uint256 amount_) external;
}

interface IUnderworld {
    // function startDeploymentMany(
    //   uint256[] calldata tokenIds,
    //   uint8 target_,
    //   bool double_
    // ) external;

    // function stake(uint256 tokenId, address who_) external;
    function stakeMany(
        uint256[] calldata tokenIds,
        uint256[] calldata kyodais,
        address owner,
        uint256 location,
        uint256 action
    ) external;

    function unstake(uint256 tokenId) external;
}

interface IGameOracle {
    function requestRandom(uint256 tokenId) external;

    function getRandom(uint256 tokenId) external returns (uint256 random);
}

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

interface ILayerZeroReceiverPoly {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}
