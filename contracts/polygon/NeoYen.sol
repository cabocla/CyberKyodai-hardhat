// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/NonblockingReceiver.sol";
import "../interfaces/Interfaces.sol";

// import "./token/ERC20/ERC20.sol";

contract NeoYen is INeoYen, ERC20, NonblockingReceiver {
    uint256 gasForDestinationLzReceive = 350000;

    //polygon traverse chain
    //contracts with permission to mint (game contract)
    mapping(address => bool) public isMinter;

    constructor(address _lzEndpoint) ERC20("Neo Yen", "NEOYEN") {
        endpoint = ILayerZeroEndpoint(_lzEndpoint);

        // TODO init supply for liquidity pool (?)
        // _mint(owner(), 5_000_000);
    }

    function mint(address to, uint256 amount) external override {
        require(isMinter[msg.sender], "not allowed to mint");
        _mint(to, amount);
    }

    function burnAuth(address from, uint256 amount) external override {
        require(isMinter[msg.sender], "not allowed to burn");
        _burn(from, amount);
    }

    // function burn(address from, uint256 amount) external override {
    //   require(isMinter[msg.sender], "Not allowed to burn");
    //   _burn(from, amount);
    // }

    function traverseChains(uint256 _chainId, uint256 amount) public payable {
        require(balanceOf(msg.sender) >= amount, "you don't have enough token");
        require(
            trustedRemoteLookup[uint16(_chainId)].length != 0,
            "chain unavailable for travel"
        );

        // safeTransferFrom(msg.sender, address(this), tokenId);
        _burn(msg.sender, amount);

        // abi.encode() the payload with the values to send
        bytes memory payload = abi.encode(msg.sender, amount);

        // encode adapterParams to specify more gas for the destination
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // get the fees we need to pay to LayerZero + Relayer to cover message delivery
        // you will be refunded for extra gas paid
        (uint256 messageFee, ) = endpoint.estimateFees(
            uint16(_chainId),
            address(this),
            payload,
            false,
            adapterParams
        );

        require(
            msg.value >= messageFee,
            "msg.value not enough to cover messageFee. Send gas for message fees"
        );

        endpoint.send{value: msg.value}(
            uint16(_chainId), // destination chainId
            trustedRemoteLookup[uint16(_chainId)], // destination address of nft contract
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
        (address toAddr, uint256 amount) = abi.decode(
            _payload,
            (address, uint256)
        );
        _mint(toAddr, amount);
    }

    function setMinter(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
    }

    // just in case this fixed variable limits us from future integrations
    function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
        gasForDestinationLzReceive = newVal;
    }
}
