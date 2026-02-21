// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Smoke test for the TOFUTokenDecimals concrete contract's
/// safeDecimalsForToken. Verifies the pass-through wiring to
/// LibTOFUTokenDecimalsImplementation without a fork.
contract TOFUTokenDecimalsSafeDecimalsForTokenTest is Test {
    TOFUTokenDecimals internal concrete;

    function setUp() external {
        concrete = new TOFUTokenDecimals();
    }

    function testSafeDecimalsForToken(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        uint8 result = concrete.safeDecimalsForToken(token);
        assertEq(result, decimals);
    }
}
