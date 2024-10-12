// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HttpLib} from "./HttpLib.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Operation, ISafeLike} from "../src/interfaces/ISafeLike.sol";

import {Vm} from "forge-std/Vm.sol";

library SafeTransactionServiceLib {
    using stdJson for string;

    Vm constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

}