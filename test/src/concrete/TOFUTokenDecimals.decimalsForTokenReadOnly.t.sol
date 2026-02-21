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

    /// Read-only call on an uninitialized token returns `Initial` with the
    /// freshly read decimals value.
    function testDecimalsForTokenReadOnly(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimals);
    }

    /// Read-only call after initialization with matching decimals returns
    /// `Consistent` and the stored value.
    function testDecimalsForTokenReadOnlyConsistent(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        concrete.decimalsForToken(token);

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(result, decimals);
    }

    /// Read-only call after initialization with differing decimals returns
    /// `Inconsistent` and the originally stored value.
    function testDecimalsForTokenReadOnlyInconsistent(uint8 decimalsA, uint8 decimalsB) external {
        vm.assume(decimalsA != decimalsB);
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        concrete.decimalsForToken(token);

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Inconsistent));
        assertEq(result, decimalsA);
    }

    /// A reverting token produces `ReadFailure` with zero decimals when
    /// uninitialized.
    function testDecimalsForTokenReadOnlyReadFailure() external {
        address token = makeAddr("token");
        vm.mockCallRevert(token, abi.encodeWithSelector(IERC20.decimals.selector), "");

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(result, 0);
    }

    /// A reverting token produces `ReadFailure` with the stored decimals
    /// when the token was previously initialized.
    function testDecimalsForTokenReadOnlyReadFailureInitialized(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        concrete.decimalsForToken(token);

        vm.mockCallRevert(token, abi.encodeWithSelector(IERC20.decimals.selector), "");

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForTokenReadOnly(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(result, decimals);
    }

    /// Calling `decimalsForTokenReadOnly` does not persist state; a
    /// subsequent stateful call still sees `Initial`.
    function testDecimalsForTokenReadOnlyDoesNotWriteStorage(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        concrete.decimalsForTokenReadOnly(token);

        (TOFUOutcome outcome,) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
    }
}
