// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {TOFUOutcome, TokenDecimalsReadFailure} from "src/interface/ITOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Smoke test for the TOFUTokenDecimals concrete contract's
/// safeDecimalsForToken. Verifies the pass-through wiring to
/// LibTOFUTokenDecimalsImplementation without a fork.
contract TOFUTokenDecimalsSafeDecimalsForTokenTest is Test {
    TOFUTokenDecimals internal concrete;

    function setUp() external {
        concrete = new TOFUTokenDecimals();
    }

    /// First call for an uninitialized token succeeds and returns the freshly
    /// read decimals.
    function testSafeDecimalsForToken(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        uint8 result = concrete.safeDecimalsForToken(token);
        assertEq(result, decimals);
    }

    /// Second call with matching decimals succeeds (`Consistent` path).
    function testSafeDecimalsForTokenConsistent(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        concrete.safeDecimalsForToken(token);

        uint8 result = concrete.safeDecimalsForToken(token);
        assertEq(result, decimals);
    }

    /// Second call with different decimals reverts with
    /// `TokenDecimalsReadFailure` and the `Inconsistent` outcome.
    function testSafeDecimalsForTokenInconsistentReverts(uint8 decimalsA, uint8 decimalsB) external {
        vm.assume(decimalsA != decimalsB);
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        concrete.safeDecimalsForToken(token);

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));

        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.Inconsistent));
        concrete.safeDecimalsForToken(token);
    }

    /// A reverting token causes `TokenDecimalsReadFailure` with the
    /// `ReadFailure` outcome.
    function testSafeDecimalsForTokenReadFailureReverts() external {
        address token = makeAddr("token");
        vm.mockCallRevert(token, abi.encodeWithSelector(IERC20.decimals.selector), "");

        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        concrete.safeDecimalsForToken(token);
    }
}
