// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "../utils/NonblockingReceiverUpgradeable.sol";
import "../utils/Libraries.sol";

contract ERC721KPoly is ERC721Upgradeable, NonblockingReceiverUpgradeable {
    using KyodaiLibrary for *;

    error TokenLocked();
    error InvalidDestination();
    error InsufficientMsgFee();

    event ActionMade(
        address indexed owner,
        uint256 indexed id,
        uint8 indexed action
    );
    event TokenReceived(address indexed owner, uint256 indexed id);

    uint256 gasForDestinationLzReceive;
    string internal baseURI;
    uint256 internal _totalSupply;
    //     struct Kyodai {
    //         uint16 lvlProgress;
    //         uint16 level;
    //         bytes8 traitHash;
    //         bytes20 name;
    //     }
    mapping(uint256 => uint256) public kyodais; //list of kyodais or shateis in uint

    //     struct Activity {
    //         address location; (bytes20 / uint160)
    //         Action action;     (uint8)
    //         uint88 timestamp;
    //     }
    // }
    mapping(uint256 => uint256) public activities; //list of activity in uint

    // TODO remove this modifier to enable ERC4337 Account Abstraction
    modifier noCheating() {
        require(
            msg.sender == tx.origin && !KyodaiLibrary.isContract(msg.sender),
            "you're trying to cheat"
        );
        _;
    }

    modifier isKyodaiOwner(address who_, uint256 id) {
        require(
            ownerOf(id) == who_,
            // || activities[id].owner == who_
            "kyodai not owned"
        );
        _;
    }

    function _init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing {
        baseURI = "";
        gasForDestinationLzReceive = 350000;
        __ERC721_init(name_, symbol_);
        // __ERC721Enumerable_init();
        // __ERC721Enumerable_init_unchained();
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    // This function transfers the nft from your address on the
    // source chain to the same address on the destination chain
    function traverseChains(
        uint16 _chainId,
        uint256 tokenId
    ) public payable isKyodaiOwner(msg.sender, tokenId) {
        if (uint256(uint8(activities[tokenId] >> 160)) != 0)
            revert TokenLocked();

        // require(
        //   uint256(uint8(activities[tokenId] >> 160)) == 0,
        //   // (        activities[tokenId] >> 160).getLastNBits(8) == 0, // check if action is UNSTAKED
        //   "Token is staked"
        // );

        bytes memory _destination = trustedRemoteLookup[_chainId];

        if (_destination.length == 0) revert InvalidDestination();
        // require(_destination.length != 0, "Chain unavailable for travel");

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(
            msg.sender,
            tokenId,
            kyodais[tokenId]
        );

        delete activities[tokenId];
        delete kyodais[tokenId];

        _burn(tokenId);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            _chainId,
            address(this),
            payload,
            false,
            adapterParams
        );

        if (msg.value < messageFee) revert InsufficientMsgFee();
        // require(
        //   msg.value >= messageFee,
        //   "msg.value not enough to cover messageFee. Send gas for message fees"
        // );

        endpoint.send{value: msg.value}(
            _chainId, // destination chainId
            _destination, // destination address of nft contract
            payload, // abi.encoded()'ed bytes
            payable(msg.sender), // refund address
            address(0x0), // 'zroPaymentAddress' unused for this
            adapterParams // txParameters
        );
    }

    function _LzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        // decode
        (address _to, uint256 _tokenId, uint256 _kyodai) = abi.decode(
            _payload,
            (address, uint256, uint256)
        );

        activities[_tokenId] = KyodaiLibrary.activityInUint(
            address(this),
            0,
            block.timestamp
        );
        kyodais[_tokenId] = _kyodai;
        if (_exists(_tokenId)) _burn(_tokenId);
        _mint(_to, _tokenId);
        emit TokenReceived(_to, _tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) {
        revert();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721Upgradeable) {
        revert();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721Upgradeable) {
        revert();
    }

    function decodeKyodai(
        uint256 tokenId
    ) public view returns (bytes20, uint256, uint256, uint256) {
        return KyodaiLibrary.decodeKyodai(kyodais[tokenId]);
    }

    function decodeActivity(
        uint256 tokenId
    ) public view returns (address, uint8, uint256) {
        return KyodaiLibrary.decodeActivity(activities[tokenId]);
    }

    function getKyodaiAlliance(uint256 tokenId) public view returns (uint8) {
        //TODO return kyodai allience from trait hash
        (, uint256 _traitHash, , ) = kyodais[tokenId].decodeKyodai();
        return uint8(_traitHash);
    }

    function changeURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function setLzEndpoint(address _lzEndpoint) public onlyOwner {
        endpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }
}
