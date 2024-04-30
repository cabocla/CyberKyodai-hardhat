// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../token/ERC721K.sol";
import "../utils/Libraries.sol";

import {IKyodai, INeoYen, IShatei, IPinkie, IKyodaiDesc, ITraitGen, IUnderworld} from "../interfaces/Interfaces.sol";

contract CyberKyodai is IKyodai, ERC721K, ERC2981Upgradeable, UUPSUpgradeable {
    using KyodaiLibrary for uint256;
    using BitMaps for BitMaps.BitMap;

    error InvalidMintPhase();
    error MintedOut();
    error InvalidProof();
    error InvalidAmount();

    // uint256 public mintActive; // 1 - not active | 2 - phase 1 whitelist mint | 3 - phase 2 whitelist mint | 4 - public mint

    // address traitGenAddy;    --> 0
    // address descriptorAddy;  --> 1
    // address dogtagAddy;      --> 2
    // address yenAddy;         --> 3
    // address underworldAddy;  --> 4
    mapping(uint256 => address) public officialAddys;
    mapping(uint256 => uint256) public allianceSupply;
    bytes32 public merkleRoot;
    uint256 internal ownerMinted;

    // TODO remove this modifier to enable ERC4337 Account Abstraction
    modifier noCheating() {
        require(
            msg.sender == tx.origin && !KyodaiLibrary.isContract(msg.sender),
            "you're trying to cheat"
        );
        _;
    }

    /// @dev required for UUPS Proxy Pattern
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function init(address _endpoint) external initializer {
        // mintActive = 1;
        _init("CyberKyodai", "KYODAI");
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

    // function mint(
    //     bytes32[] memory _merkleProof,
    //     uint256 alliance
    // ) external payable noCheating {
    //     alliance %= 3;
    //     uint256 mintPhase = mintActive;
    //     if (mintPhase != 2 && mintPhase != 3) revert InvalidMintPhase();
    //     if (mintPhase == 2 && msg.value != 0.033 ether) revert InvalidAmount();

    //     // require(mintActive == 2, "presale not active");

    //     if (whitelistClaimed.get(uint256(uint160(msg.sender))))
    //         revert WhitelistClaimed();
    //     // require(
    //     //   !whitelistClaimed.get(uint256(uint160(msg.sender))),
    //     //   "whitelist claimed"
    //     // );

    //     if (
    //         !MerkleProof.verify(
    //             _merkleProof,
    //             merkleRoot,
    //             keccak256(abi.encodePacked(msg.sender))
    //         )
    //     ) revert InvalidProof();
    //     //       require(
    //     //   MerkleProof.verify(
    //     //     _merkleProof,
    //     //     merkleRoot,
    //     //     keccak256(abi.encodePacked(msg.sender))
    //     //   ),
    //     //   "invalid proof"
    //     // );

    //     if (
    //         totalSupply() + (mintPhase == 2 ? 2 : 1) >
    //         (mintPhase == 2 ? 1998 : 3232)
    //     ) revert MintedOut();
    //     if (allianceSupply[alliance] + (mintPhase == 2 ? 2 : 1) > 1111)
    //         revert MintedOut();
    //     // require(_totalSupply + 1 < 3334, "fully minted");

    //     whitelistClaimed.set(uint256(uint160(msg.sender)));
    //     mintInternal(msg.sender, alliance);
    //     if (mintPhase == 2) mintInternal(msg.sender, alliance);
    // }

    // function publicMint(uint256 alliance) external payable noCheating {
    //     alliance %= 3;
    //     if (mintActive != 4) revert InvalidMintPhase();
    //     // require(mintActive == 3, "public not active");
    //     // TODO uncomment when deploying to mainnet
    //     // require(!publicMinted.get(uint256(uint160(msg.sender))), "minted");
    //     // if(_totalSupply + 1 > 3232) revert MintedOut();
    //     // require(_totalSupply + 1 < 3334, "fully minted");
    //     if (msg.value != 0.033 ether) revert InvalidAmount();
    //     if (allianceSupply[alliance] + 1 > 1111) revert MintedOut();

    //     // TODO uncomment when deploying to mainner
    //     // publicMinted.set(uint256(uint160(msg.sender)));
    //     mintInternal(msg.sender, alliance);
    // }

    // function mintInternal(address to, uint256 alliance) internal {
    //     uint256 tokenId = totalSupply() + 1;
    //     kyodais[tokenId] = KyodaiLibrary.kyodaiInUint(
    //         bytes20(0),
    //         ITraitGen(officialAddys[0]).genKyodaiHash(tokenId, to, 0, alliance),
    //         1,
    //         0
    //     );
    //     // ++_totalSupply;
    //     ++allianceSupply[alliance];
    //     _mint(to, tokenId);
    // }

    // // TODO manually mint until 100 token max for owner
    // // TODO need to mint on ehtereum to provide for sudoswap liquidity pool
    // // TODO mint on polygon (?)
    // // mint only after whitelist and public mint done
    // function ownerMint(uint256 _amount) external onlyOwner {
    //     require(ownerMinted < 102);
    //     require(totalSupply() + _amount < 3334);
    //     for (uint256 i = 0; i < _amount; ) {
    //         mintInternal(owner(), i % 3);
    //         unchecked {
    //             ++i;
    //         }
    //     }
    //     ownerMinted += _amount;
    // }

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

    function totalSupply() public view override returns (uint256 _supply) {
        for (uint256 i = 0; i < 3; ) {
            _supply += allianceSupply[i];
            unchecked {
                ++i;
            }
        }
    }

    function getKyodai(
        uint256 tokenId
    ) external view override returns (uint256) {
        return kyodais[tokenId];
    }

    function getManyKyodai(
        uint256[] calldata tokenIds
    ) external view override returns (uint256[] memory) {
        uint256[] memory _kyodais = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _kyodais[i] = kyodais[tokenIds[i]];
        }
        return _kyodais;
    }

    function ownerOf(
        uint256 tokenId
    ) public view override(IKyodai, ERC721Upgradeable) returns (address) {
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

    /// @notice Toggle mint status
    /// @param status 1 - not active | 2 - phase 1 whitelist mint | 3 - phase 2 whitelist mint | 4 - puublic mint
    // function toggleMint(uint256 status) public onlyOwner {
    //     mintActive = status;
    // }

    /// @notice Set address of CyberKyodai ecosystem contract
    /// @param index the index of address
    /// @param newAddy address of contract
    /// @dev  traitGenAddy   = 0
    /// @dev  descriptorAddy = 1
    /// @dev  dogtagAddy     = 2
    /// @dev  yenAddy        = 3
    /// @dev  underworldAddy = 4
    function setNewAddy(uint256 index, address newAddy) public onlyOwner {
        officialAddys[index] = newAddy;
    }

    function setMerkleRoot(bytes32 rootHash) public onlyOwner {
        merkleRoot = rootHash;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    uint256[46] private __gap;
}
