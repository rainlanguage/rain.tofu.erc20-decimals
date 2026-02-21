// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {TOFUOutcome} from "src/interface/ITOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Smoke test for the TOFUTokenDecimals concrete contract's decimalsForToken.
/// Verifies the pass-through wiring to LibTOFUTokenDecimalsImplementation
/// without a fork.
contract TOFUTokenDecimalsDecimalsForTokenTest is Test {
    TOFUTokenDecimals internal concrete;

    function setUp() external {
        concrete = new TOFUTokenDecimals();
    }

    /// First call for an uninitialized token returns `Initial` with the
    /// freshly read decimals value.
    function testDecimalsForToken(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimals);
    }

    /// Second call with the same decimals returns `Consistent` and the
    /// stored value.
    function testDecimalsForTokenConsistent(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        concrete.decimalsForToken(token);

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(result, decimals);
    }

    /// Second call with different decimals returns `Inconsistent` and the
    /// originally stored value, not the new one.
    function testDecimalsForTokenInconsistent(uint8 decimalsA, uint8 decimalsB) external {
        vm.assume(decimalsA != decimalsB);
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        concrete.decimalsForToken(token);

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Inconsistent));
        assertEq(result, decimalsA);
    }

    /// A reverting token produces `ReadFailure` with zero decimals when
    /// uninitialized.
    function testDecimalsForTokenReadFailure() external {
        address token = makeAddr("token");
        vm.mockCallRevert(token, abi.encodeWithSelector(IERC20.decimals.selector), "");

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(result, 0);
    }

    /// A reverting token produces `ReadFailure` but returns the previously
    /// stored decimals when already initialized.
    function testDecimalsForTokenReadFailureInitialized(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));
        concrete.decimalsForToken(token);

        vm.mockCallRevert(token, abi.encodeWithSelector(IERC20.decimals.selector), "");

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(result, decimals);
    }

    /// Initializing two different tokens does not cross-contaminate their
    /// stored decimals.
    function testDecimalsForTokenCrossTokenIsolation(uint8 decimalsA, uint8 decimalsB) external {
        address tokenA = makeAddr("tokenA");
        address tokenB = makeAddr("tokenB");
        vm.mockCall(tokenA, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));
        vm.mockCall(tokenB, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));

        concrete.decimalsForToken(tokenA);
        concrete.decimalsForToken(tokenB);

        (TOFUOutcome outcomeA, uint8 resultA) = concrete.decimalsForToken(tokenA);
        assertEq(uint256(outcomeA), uint256(TOFUOutcome.Consistent));
        assertEq(resultA, decimalsA);

        (TOFUOutcome outcomeB, uint8 resultB) = concrete.decimalsForToken(tokenB);
        assertEq(uint256(outcomeB), uint256(TOFUOutcome.Consistent));
        assertEq(resultB, decimalsB);
    }

    /// A `ReadFailure` after initialization does not corrupt the stored value;
    /// restoring the token recovers `Consistent`.
    function testDecimalsForTokenStorageImmutableOnReadFailure(uint8 decimals) external {
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));
        concrete.decimalsForToken(token);

        vm.mockCallRevert(token, abi.encodeWithSelector(IERC20.decimals.selector), "");
        concrete.decimalsForToken(token);

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(result, decimals);
    }

    /// An `Inconsistent` outcome does not overwrite the stored value; the
    /// original decimals remain and can still produce `Consistent`.
    function testDecimalsForTokenStorageImmutableOnInconsistent(uint8 decimalsA, uint8 decimalsB) external {
        vm.assume(decimalsA != decimalsB);
        address token = makeAddr("token");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));
        concrete.decimalsForToken(token);

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        concrete.decimalsForToken(token);

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        (TOFUOutcome outcome, uint8 result) = concrete.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(result, decimalsA);
    }
}
