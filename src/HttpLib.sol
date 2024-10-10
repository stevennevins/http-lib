// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {stdJson} from "forge-std/StdJson.sol";
import {Vm} from "forge-std/Vm.sol";

library HttpLib {
    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function get(
        string memory url
    ) internal returns (string memory) {
        string[] memory inputs = new string[](3);
        inputs[0] = "curl";
        inputs[1] = "-s"; // Silent mode
        inputs[2] = url;

        bytes memory result = vm.ffi(inputs);

        return string(result);
    }

    function post(string memory url, string memory data) internal returns (string memory) {
        string[] memory inputs = new string[](7);
        inputs[0] = "curl";
        inputs[1] = "-s";
        inputs[2] = "-X";
        inputs[3] = "POST";
        inputs[4] = "-d";
        inputs[5] = data;
        inputs[6] = url;

        bytes memory result = vm.ffi(inputs);

        return string(result);
    }

    function getWithHeaders(
        string memory url,
        string[] memory headers
    ) internal returns (string memory) {
        uint256 headerCount = headers.length;
        string[] memory inputs = new string[](3 + headerCount * 2);
        inputs[0] = "curl";
        inputs[1] = "-s";

        uint256 index = 2;

        for (uint256 i = 0; i < headerCount; i++) {
            inputs[index] = "-H";
            index += 1;
            inputs[index] = headers[i];
            index += 1;
        }

        inputs[index] = url;

        bytes memory result = vm.ffi(inputs);

        return string(result);
    }

    function postWithHeaders(
        string memory url,
        string memory data,
        string[] memory headers
    ) internal returns (string memory) {
        uint256 headerCount = headers.length;
        string[] memory inputs = new string[](7 + headerCount * 2);
        inputs[0] = "curl";
        inputs[1] = "-s";
        inputs[2] = "-X";
        inputs[3] = "POST";

        uint256 index = 4;

        for (uint256 i = 0; i < headerCount; i++) {
            inputs[index] = "-H";
            index += 1;
            inputs[index] = headers[i];
            index += 1;
        }

        inputs[index] = "-d";
        inputs[index + 1] = data;
        inputs[index + 2] = url;

        bytes memory result = vm.ffi(inputs);

        return string(result);
    }
}
