// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {LibExtrospectBytecode} from "rain.extrospection/lib/LibExtrospectBytecode.sol";
import {EVM_OP_SELFDESTRUCT, EVM_OP_DELEGATECALL, EVM_OP_CALLCODE} from "rain.extrospection/lib/EVMOpcodes.sol";

contract TOFUTokenDecimalsImmutabilityTest is Test {
    /// The deployed bytecode of TOFUTokenDecimals MUST NOT contain any
    /// reachable opcodes that could allow the contract to be mutated or
    /// destroyed after deployment.
    function testNoMutableOpcodes() external {
        TOFUTokenDecimals concrete = new TOFUTokenDecimals();
        bytes memory bytecode = address(concrete).code;

        uint256 reachable = LibExtrospectBytecode.scanEVMOpcodesReachableInBytecode(bytecode);

        // SELFDESTRUCT would allow the contract to be destroyed.
        assertEq(reachable & (1 << EVM_OP_SELFDESTRUCT), 0, "SELFDESTRUCT is reachable");
        // DELEGATECALL would allow arbitrary code execution in the contract's
        // storage context.
        assertEq(reachable & (1 << EVM_OP_DELEGATECALL), 0, "DELEGATECALL is reachable");
        // CALLCODE would allow arbitrary code execution in the contract's
        // storage context.
        assertEq(reachable & (1 << EVM_OP_CALLCODE), 0, "CALLCODE is reachable");
    }
}
