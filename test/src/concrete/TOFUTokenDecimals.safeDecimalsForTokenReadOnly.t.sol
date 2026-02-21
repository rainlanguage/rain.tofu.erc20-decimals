// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Smoke test for the TOFUTokenDecimals concrete contract's
/// safeDecimalsForTokenReadOnly. Verifies the pass-through wiring to
/// LibTOFUTokenDecimalsImplementation without a fork.
contract TOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest is Test {
    TOFUTokenDecimals internal concrete;

    function setUp() external {
        concrete = new TOFUTokenDecimals();
    }

    function testSafeDecimalsForTokenReadOnly(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        // Initialize state first so read-only has something to check against.
        concrete.decimalsForToken(token);

        uint8 result = concrete.safeDecimalsForTokenReadOnly(token);
        assertEq(result, decimals);
    }
}
