// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

    function nonce() external view returns (uint256);
}