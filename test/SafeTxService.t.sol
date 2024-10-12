import {HttpLib} from "../src/HttpLib.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Test} from "forge-std/Test.sol";

 enum Operation {
        Call,
        DelegateCall
}

interface ISafeLike {
        function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);
}

contract SafeTxServiceTest is Test {
    using stdJson for string;
    address safe =0x3C7Bd34335FdF1Edec641dAc9f069C8D8560d95D;
    string safeAddress = "0x3C7Bd34335FdF1Edec641dAc9f069C8D8560d95D";
    address safeSigner = 0x8b4528B6914DAb2f77232d51B02564350bC42A02;
    uint256 privateKey;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        vm.createSelectFork("sepolia");
        assertEq(block.chainid, 11155111, "Not on Sepolia network");
    }

    function testPostSafeMultisigTransaction() public {
        string memory endpoint = string(abi.encodePacked(
            "https://safe-transaction-sepolia.safe.global/api/v1/safes/",
            safeAddress,
            "/multisig-transactions/"
        ));

        string memory jsonBody = generateSafeMultisigTransactionJson();

        string[] memory headers = new string[](1);
        headers[0] = "Content-Type: application/json";

        string memory response = HttpLib.postWithHeaders(endpoint, jsonBody, headers);
        emit log_string("API Response:");
        emit log_string(response);
    }

    function generateSafeMultisigTransactionJson() internal view returns (string memory) {
        /// TODO: Need logic to get latest nonce


        /// TODO: Need logic to get transaction service pending transactions for correct noce diff
        ISafeLike safe = ISafeLike(safe);
        
        address to = address(0x000000000000000000000000000000000000dEaD);
        uint256 value = 1;
        bytes memory data = "";
        Operation operation = Operation.Call;
        uint256 safeTxGas = 0;
        uint256 baseGas = 0;
        uint256 gasPrice = 0;
        address gasToken = address(0);
        address refundReceiver = address(0);
        uint256 nonce = 0;

        bytes32 txHash = safe.getTransactionHash(
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

        string memory contractTransactionHash = vm.toString(txHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, txHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        string memory jsonString = string(abi.encodePacked(
            '{"safe":"', safeAddress, '",',
            '"to":"0x000000000000000000000000000000000000dEaD",',
            '"value":1,', // 1 wei
            '"data":"0x",',
            '"operation":0,',
            '"safeTxGas":0,',
            '"baseGas":0,',
            '"gasPrice":0,',
            '"nonce":0,',
            '"contractTransactionHash":"', contractTransactionHash,'",', /// Get the tx transaction hash and put here https://github.com/safe-global/safe-smart-account/blob/8ffae95faa815acf86ec8b50021ebe9f96abde10/contracts/Safe.sol#L435
            '"sender":"', vm.toString(safeSigner), '",', 
            '"signature":"', "0x", vm.toString(signature),'",', // Safe signer must sign the transaction hash
            '"origin":null}'
        ));

        return jsonString;
    }
}
