// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HttpLib} from "../src/HttpLib.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Operation, ISafeLike} from "../src/interfaces/ISafeLike.sol";
import {Test, console2 as console} from "forge-std/Test.sol";
import {SafeTransactionServiceLib} from "../src/SafeTransactionServiceLib.sol";

contract SafeTxServiceTest is Test {
    using stdJson for string;

    address safe = 0xe563de46C8F40D4b1bb14456DC7085bb3187A0A0;
    address safeSigner = 0xF108412695bDe69025fdCC7DA7048f4fFa43BC59;
    uint256 privateKey;
    string chainName;

    mapping(uint256 => string) public chainIdToName;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        vm.createSelectFork("sepolia");

        chainIdToName[1] = "mainnet";
        chainIdToName[11_155_111] = "sepolia";

        chainName = chainIdToName[block.chainid];
    }

    function testPostSafeMultisigTransaction() public {
        string memory endpoint = SafeTransactionServiceLib.constructApiEndpoint(
            string.concat("v1/safes/", vm.toString(safe), "/multisig-transactions/"), chainName
        );

        address to = address(0xDeaD);
        uint256 value = 1;
        bytes memory data = "";
        Operation operation = Operation.Call;
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address refundReceiver = address(0);
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

        bytes memory signature = signAndFormatSignature(txHash);

        (string memory jsonBody, string[] memory headers) = SafeTransactionServiceLib
            .postSafeMultisigTransaction(
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

        string memory response = HttpLib.postWithHeaders(endpoint, jsonBody, headers);
        console.log("Response from testPostSafeMultisigTransaction:");
        console.log(response);
    }

    function testPostSafeDelegate() public {
        string memory endpoint =
            SafeTransactionServiceLib.constructApiEndpoint("v2/delegates/", chainName);

        address delegate = address(0x1234567890123456789012345678901234567890);

        bytes32 typedDataHash = SafeTransactionServiceLib.getDelegateTypedDataHash(
            delegate, block.chainid, block.timestamp
        );

        bytes memory signature = signAndFormatSignature(typedDataHash);

        (string memory jsonBody, string[] memory headers) =
            SafeTransactionServiceLib.postSetDelegate(safe, delegate, safeSigner, signature);

        string memory response = HttpLib.postWithHeaders(endpoint, jsonBody, headers);
        console.log("Response from testPostSafeDelegate:");
        console.log(response);
    }

    function testRemoveSafeDelegate() public {
        address delegate = address(0x1234567890123456789012345678901234567890);
        string memory endpoint = SafeTransactionServiceLib.constructApiEndpoint(
            string.concat("v2/delegates/", vm.toString(delegate), "/"), chainName
        );

        console.log(endpoint);

        bytes32 typedDataHash = SafeTransactionServiceLib.getDelegateTypedDataHash(
            delegate, block.chainid, block.timestamp
        );

        bytes memory signature = signAndFormatSignature(typedDataHash);

        (string memory jsonBody, string[] memory headers) =
            SafeTransactionServiceLib.delDelegate(safe, delegate, safeSigner, signature);

        string memory response = HttpLib.delWithHeaders(endpoint, jsonBody, headers);
        console.log("Response from testDelSafeDelegate:");
        console.log(response);
    }

    function testGetSafeMultisigTransactions() public {
        string memory endpoint = SafeTransactionServiceLib.getMultisigTransactions(safe, chainName);
        string memory response = HttpLib.get(endpoint);

        assertTrue(bytes(response).length > 0, "No response");
        console.log("Response from testGetSafeMultisigTransactions:");
        console.log(response);
    }

    function testGetPendingTransactions() public {
        (string memory queryParams, string[] memory headers) =
            SafeTransactionServiceLib.getSafePendingTransactions(safe);
        string memory endpoint = string.concat(
            SafeTransactionServiceLib.getMultisigTransactions(safe, chainName), queryParams
        );

        string memory response = HttpLib.getWithHeaders(endpoint, headers);

        assertTrue(bytes(response).length > 0, "No response");
        console.log("Response from testGetPendingTransactions:");
        console.log(response);
    }

    function testProposeTransactionWithDelegate() public {
        uint256 delegatePrivateKey = 0xA11CE;
        address delegate = vm.addr(delegatePrivateKey);

        string memory delegateEndpoint =
            SafeTransactionServiceLib.constructApiEndpoint("v2/delegates/", chainName);

        uint256 totp = block.timestamp / 3600; // basically the signature expires in an hour and can't be replayed

        bytes32 domainSeparator = getEIP712DomainSeparator();

        bytes32 structHash = keccak256(
            abi.encode(keccak256("Delegate(address delegateAddress,uint256 totp)"), delegate, totp)
        );

        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        bytes memory signature1 = signAndFormatSignature(typedDataHash);

        string memory delegateJsonBody = string.concat(
            "{",
            '"safe":"',
            vm.toString(safe),
            '",',
            '"delegate":"',
            vm.toString(delegate),
            '",',
            '"delegator":"',
            vm.toString(safeSigner),
            '",',
            '"signature":"',
            vm.toString(signature1),
            '",',
            '"label":"Test Delegate"',
            "}"
        );

        string[] memory delegateHeaders = new string[](1);
        delegateHeaders[0] = "Content-Type: application/json";

        string memory delegateResponse =
            HttpLib.postWithHeaders(delegateEndpoint, delegateJsonBody, delegateHeaders);
        console.log("Response from delegate creation:");
        console.log(delegateResponse);

        address to = address(0x420);
        uint256 value = 1;
        bytes memory data = "";
        Operation operation = Operation.Call;
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address refundReceiver = address(0);
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

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(delegatePrivateKey, txHash);
        bytes memory delegateSignature = abi.encodePacked(r2, s2, v2);

        string memory jsonString = string.concat(
            "{",
            '"safe":"',
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
            vm.toString(delegate),
            '",',
            '"signature":"',
            "0x",
            vm.toString(delegateSignature),
            '",',
            '"origin":null',
            "}"
        );

        string memory endpoint = SafeTransactionServiceLib.constructApiEndpoint(
            string.concat("v1/safes/", vm.toString(safe), "/multisig-transactions/"), chainName
        );
        string[] memory transactionHeaders = new string[](1);
        transactionHeaders[0] = "Content-Type: application/json";

        string memory transactionResponse =
            HttpLib.postWithHeaders(endpoint, jsonString, transactionHeaders);
        console.log("Response from transaction proposal:");
        console.log(transactionResponse);
    }

    function generateSafeMultisigTransactionJson() internal view returns (string memory) {
        address to = address(0x000000000000000000000000000000000000dEaD);
        uint256 value = 1;
        bytes memory data = "0x";
        Operation operation = Operation.Call;
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address refundReceiver = address(0);
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

        bytes memory signature = signAndFormatSignature(txHash);

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

    function getEIP712DomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId)"),
                keccak256("Safe Transaction Service"),
                keccak256("1.0"),
                block.chainid
            )
        );
    }

    function signAndFormatSignature(
        bytes32 hash
    ) internal view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        return abi.encodePacked(r, s, v);
    }
}
