// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {TOFUOutcome, TokenDecimalsReadFailure} from "src/interface/ITOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Smoke tests for the TOFUTokenDecimals concrete contract. Verifies the
/// pass-through wiring to LibTOFUTokenDecimalsImplementation without a fork.
contract TOFUTokenDecimalsTest is Test {
    TOFUTokenDecimals internal concrete;

    function setUp() external {
        concrete = new TOFUTokenDecimals();
    }

    function testDecimalsForToken(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimals);
    }

    function testDecimalsForTokenReadOnly(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimals);
    }

    function testSafeDecimalsForToken(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        uint8 result = concrete.safeDecimalsForToken(token);
        assertEq(result, decimals);
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
