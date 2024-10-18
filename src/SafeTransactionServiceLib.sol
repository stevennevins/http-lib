// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HttpLib} from "./HttpLib.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Operation, ISafeLike} from "../src/interfaces/ISafeLike.sol";

import {Vm} from "forge-std/Vm.sol";

library SafeTransactionServiceLib {
    // TODO: Should start thinking about API authorization

    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    struct SafeMultisigTransaction {
        address safe;
        address safeSigner;
        address to;
        uint256 value;
        bytes data;
        Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address refundReceiver;
        bytes signature;
    }

    struct MinimalMultisigTransaction {
        address safe;
        address safeSigner;
        address to;
        bytes data;
        bytes signature;
    }

    function constructApiEndpoint(
        string memory path,
        string memory chainName
    ) internal pure returns (string memory) {
        return string.concat("https://safe-transaction-", chainName, ".safe.global/api/", path);
    }

    /// Start Build API Endpoint Strings

    function getMultisigTransactions(
        address safe,
        string memory chainName
    ) internal pure returns (string memory) {
        return constructApiEndpoint(
            string.concat("v1/safes/", vm.toString(safe), "/multisig-transactions/"), chainName
        );
    }

    function getDelegates(
        string memory chainName
    ) internal pure returns (string memory) {
        return constructApiEndpoint("v2/delegates/", chainName);
    }

    function getTransactions(
        address safe,
        string memory chainName
    ) internal pure returns (string memory) {
        return constructApiEndpoint(
            string.concat("v1/safes/", vm.toString(safe), "/multisig-transactions/"), chainName
        );
    }

    /// End Build API Endpoint Strings

    function generateSafeMultisigTransactionJson(
        address safe,
        address safeSigner,
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signature
    ) internal view returns (string memory) {
        /// TODO: Verify here that the signature recovers to the signer and the txhash matches
        /// Before sending it off to the API
        uint256 nonce = ISafeLike(safe).nonce();
        bytes32 txHash = ISafeLike(safe).getTransactionHash(
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            nonce
        );

        string memory jsonString = string(
            abi.encodePacked(
                '{"safe":"',
                vm.toString(safe),
                '",',
                '"to":"',
                vm.toString(to),
                '",',
                '"value":',
                vm.toString(value),
                ",",
                '"data":"',
                vm.toString(data),
                '",',
                '"operation":',
                vm.toString(uint256(operation)),
                ",",
                '"safeTxGas":',
                vm.toString(safeTxGas),
                ",",
                '"baseGas":',
                vm.toString(baseGas),
                ",",
                '"gasPrice":',
                vm.toString(gasPrice),
                ",",
                '"nonce":',
                vm.toString(nonce),
                ",",
                '"contractTransactionHash":"',
                vm.toString(txHash),
                '",',
                '"sender":"',
                vm.toString(safeSigner),
                '",',
                '"signature":"',
                "0x",
                vm.toString(signature),
                '",',
                '"origin":null}'
            )
        );

        return jsonString;
    }

    function postSafeMultisigTransaction(
        address safe,
        address safeSigner,
        address to,
        uint256 value,
        bytes memory data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signature
    ) internal view returns (string memory, string[] memory) {
        string memory jsonBody = generateSafeMultisigTransactionJson(
            safe,
            safeSigner,
            to,
            value,
            data,
            operation,
            safeTxGas,
            baseGas,
            gasPrice,
            gasToken,
            refundReceiver,
            signature
        );

        string[] memory headers = new string[](1);
        headers[0] = "Content-Type: application/json";

        return (jsonBody, headers);
    }

    function getDelegateTypedDataHash(
        address delegate,
        uint256 chainId,
        uint256 timestamp
    ) internal pure returns (bytes32) {
        uint256 totp = timestamp / 3600; // TOTP changes every hour ie, expiring sig

        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId)"),
                keccak256("Safe Transaction Service"),
                keccak256("1.0"),
                chainId
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(keccak256("Delegate(address delegateAddress,uint256 totp)"), delegate, totp)
        );

        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    function postSetDelegate(
        address safe,
        address delegate,
        address delegator,
        bytes memory signature
    ) internal pure returns (string memory, string[] memory) {
        string memory jsonBody = string(
            abi.encodePacked(
                '{"safe":"',
                vm.toString(safe),
                '","delegate":"',
                vm.toString(delegate),
                '","delegator":"',
                vm.toString(delegator),
                '","signature":"',
                vm.toString(signature),
                '","label":"Test Delegate"}'
            )
        );

        string[] memory headers = new string[](1);
        headers[0] = "Content-Type: application/json";

        return (jsonBody, headers);
    }
}
