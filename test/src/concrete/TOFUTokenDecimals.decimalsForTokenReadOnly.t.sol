// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {TOFUOutcome} from "src/interface/ITOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Smoke test for the TOFUTokenDecimals concrete contract's
/// decimalsForTokenReadOnly. Verifies the pass-through wiring to
/// LibTOFUTokenDecimalsImplementation without a fork.
contract TOFUTokenDecimalsDecimalsForTokenReadOnlyTest is Test {
    TOFUTokenDecimals internal concrete;

    function setUp() external {
        concrete = new TOFUTokenDecimals();
    }

    function testDecimalsForTokenReadOnly(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimals);
    }
}
