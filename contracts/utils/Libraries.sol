// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// import "./Base64.sol";
import "solady/src/utils/Base64.sol";

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(
        bytes32[] memory proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; ++i) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }
}

/// @dev a collection of solidity snippets from various libraries.
library KyodaiLibrary {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        return Base64.encode(data);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // function parseInt(
    //     string memory _a
    // ) internal pure returns (uint8 _parsedInt) {
    //     bytes memory bresult = bytes(_a);
    //     uint8 mint;
    //     for (uint8 i; i < bresult.length; ++i) {
    //         if (
    //             (uint8(uint8(bresult[i])) >= 48) &&
    //             (uint8(uint8(bresult[i])) <= 57)
    //         ) {
    //             mint *= 10;
    //             mint += uint8(bresult[i]) - 48;
    //         }
    //     }
    //     return mint;
    // }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; ++i) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function decodeHashIndex(
        string memory hash
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < 64; ) {
            if (
                stringToBytes32(hash) ==
                stringToBytes32(substring(TABLE, i, i + 1))
            ) return i;
            unchecked {
                ++i;
            }
        }
        revert();
    }

    function bytes20ToString(
        bytes20 _bytes20
    ) internal pure returns (string memory) {
        uint256 i = 0;
        while (i < 20 && _bytes20[i] != 0) {
            unchecked {
                ++i;
            }
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 20 && _bytes20[i] != 0; i++) {
            bytesArray[i] = _bytes20[i];
        }
        return string(bytesArray);
    }

    function stringToBytes32(
        string memory source
    ) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(
        bytes32 _bytes32
    ) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; ++i) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function bytes8ToString(
        bytes8 _bytes8
    ) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 8 && _bytes8[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 8 && _bytes8[i] != 0; ++i) {
            bytesArray[i] = _bytes8[i];
        }
        return string(bytesArray);
    }

    function getLastNBits(uint x, uint n) internal pure returns (uint) {
        // Example, last 3 bits
        // x        = 1101 = 13
        // mask     = 0111 = 7
        // x & mask = 0101 = 5
        uint mask = (1 << n) - 1;
        return x & mask;
    }

    function getBits(
        uint x,
        uint n,
        uint fromRight
    ) internal pure returns (uint) {
        uint mask = (1 << n) - 1;
        return (x >> fromRight) & mask;
    }

    // Get first n bits from x
    // len = length of bits in x = position of most significant bit of x, + 1
    function getFirstNBits(
        uint x,
        uint n,
        uint len
    ) internal pure returns (uint) {
        // Example
        // x        = 1110 = 14, n = 2, len = 4
        // mask     = 1100 = 12
        // x & mask = 1100 = 12
        uint mask = ((1 << n) - 1) << (len - n);
        return x & mask;
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }

    function decodeKyodai(
        uint256 _kyodai
    )
        internal
        pure
        returns (
            bytes20 _name,
            uint256 _traitHash,
            uint256 _level,
            uint256 _lvlProgress
        )
    {
        _name = bytes20(uint160(_kyodai));
        _lvlProgress = uint256(uint16(_kyodai >> 160));
        //  uint16(_kyodai>>160);
        _level = uint256(uint16(_kyodai >> 176));
        //  uint16(_kyodai>>176);
        _traitHash = uint256(uint64(_kyodai >> 192));
    }

    function decodeActivity(
        uint256 _activity
    )
        internal
        pure
        returns (address _location, uint8 _action, uint256 _timestamp)
    {
        _location = address(uint160(_activity));
        _action = uint8(_activity >> 160);
        //  uint8(_activity>>160);
        _timestamp = _activity >> 168;
    }

    function updateKyodai(
        uint256 _oldKyodai,
        bytes20 _name,
        uint256 _exp
    ) internal pure returns (uint256 _newKyodai) {
        uint256 totalExp = uint256(uint16(_oldKyodai >> 160)) + _exp;
        _newKyodai = _name != 0
            ? uint256(uint160(_name))
            : uint256(uint160(_oldKyodai)); //update name
        _newKyodai |= (totalExp % 1000) << 160; //update lvl progress
        uint256 _newLevel = uint256(uint16(_oldKyodai >> 176)) +
            (totalExp / 1000);
        _newKyodai |= _newLevel > 65535 ? 65535 << 176 : _newLevel << 176; //update level, not more than uint16 max value
        _newKyodai |= (_oldKyodai >> 192) << 192; //trait hash unchanged
        // getFirstNBits(_oldKyodai, 64, 256);
    }

    function activityInUint(
        address _location,
        uint8 _action,
        uint256 _timestamp
    ) internal pure returns (uint256 _activity) {
        _activity = uint256(uint160(_location));
        _activity |= uint256(_action) << 160;
        _activity |= _timestamp << 168;
    }

    function kyodaiInUint(
        bytes20 _name,
        uint256 _traitHash,
        uint256 _level,
        uint256 _lvlProgress
    ) internal pure returns (uint256 _kyodai) {
        _kyodai = uint256(uint160(bytes20(_name)));
        _kyodai |= _lvlProgress << 160; //lvl progress
        _kyodai |= _level << 176;
        _kyodai |= _traitHash << 192;
    }

    /// @notice snippet from Solady FixedPointMathLib library (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    /// @dev Returns the log10 of `x`.
    /// Returns 0 if `x` is zero.
    function log10(uint256 x) public pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 100000000000000000000000000000000000000)) {
                x := div(x, 100000000000000000000000000000000000000)
                r := 38
            }
            if iszero(lt(x, 100000000000000000000)) {
                x := div(x, 100000000000000000000)
                r := add(r, 20)
            }
            if iszero(lt(x, 10000000000)) {
                x := div(x, 10000000000)
                r := add(r, 10)
            }
            if iszero(lt(x, 100000)) {
                x := div(x, 100000)
                r := add(r, 5)
            }
            r := add(
                r,
                add(gt(x, 9), add(gt(x, 99), add(gt(x, 999), gt(x, 9999))))
            )
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
