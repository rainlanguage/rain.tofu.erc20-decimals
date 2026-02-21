// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    LibTOFUTokenDecimalsImplementation,
    TOFUOutcome,
    TOFUTokenDecimalsResult
} from "src/lib/LibTOFUTokenDecimalsImplementation.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsImplementationDecimalsForTokenTest is Test {
    mapping(address => TOFUTokenDecimalsResult) internal sTokenTokenDecimals;

    function testDecimalsForTokenAddressZero(uint8 storedDecimals) external {
        (TOFUOutcome tofuOutcome, uint8 decimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, address(0));
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(decimals, 0);

        sTokenTokenDecimals[address(0)] =
            TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, decimals) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, address(0));
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(decimals, uint8(storedDecimals));
    }

    function testDecimalsForTokenValidValue(uint8 decimalsA, uint8 decimalsB) external {
        address token = makeAddr("TokenA");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, decimalsA);

        // decimalsForToken will update the stored value on the initial read, so
        // we mock a different return value to check that the consistency check
        // is working as expected.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        (tofuOutcome, readDecimals) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        if (decimalsA == decimalsB) {
            assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Consistent));
            assertEq(readDecimals, decimalsA);
        } else {
            assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Inconsistent));
            assertEq(readDecimals, decimalsA);
        }
    }

    function testDecimalsForTokenInvalidValueTooLarge(uint256 decimals, uint8 storedDecimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        sTokenTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }

    function testDecimalsForTokenInvalidValueNotEnoughData(bytes memory data, uint256 length, uint8 storedDecimals)
        external
    {
        length = bound(length, 0, 0x1f);
        if (data.length > length) {
            assembly ("memory-safe") {
                mstore(data, length)
            }
        }
        address token = makeAddr("TokenC");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), data);

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        sTokenTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }

    /// Storage must not be overwritten on non-Initial outcomes. Initializes
    /// with decimalsA, triggers a ReadFailure via too-large return, then
    /// confirms the stored value survives by checking for Consistent on a
    /// subsequent valid read.
    function testDecimalsForTokenNoStorageWriteOnNonInitial(uint8 decimalsA, uint256 tooLarge) external {
        vm.assume(tooLarge > 0xff);
        address token = makeAddr("TokenE");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        // Initial: stores decimalsA.
        (TOFUOutcome tofuOutcome,) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));

        // ReadFailure via too-large value: must not corrupt stored value.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(tooLarge));
        (tofuOutcome,) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));

        // Restore valid mock: should be Consistent, proving storage was not
        // overwritten by the ReadFailure call.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));
        (tofuOutcome,) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Consistent));
    }

    /// Inconsistent outcome must not overwrite the stored value. Initializes
    /// with decimalsA, triggers Inconsistent with decimalsB, then confirms
    /// the original stored value survives by checking for Consistent when
    /// decimalsA is restored.
    function testDecimalsForTokenNoStorageWriteOnInconsistent(uint8 decimalsA, uint8 decimalsB) external {
        vm.assume(decimalsA != decimalsB);
        address token = makeAddr("TokenF");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        // Initial: stores decimalsA.
        (TOFUOutcome tofuOutcome,) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));

        // Inconsistent: must not overwrite stored decimalsA with decimalsB.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        (tofuOutcome,) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Inconsistent));

        // Restore decimalsA: should be Consistent, proving Inconsistent did
        // not overwrite the stored value.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));
        (tofuOutcome,) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Consistent));
    }

    /// Storing decimals for one token must not affect a different token.
    function testDecimalsForTokenCrossTokenIsolation(uint8 decimalsA, uint8 decimalsB) external {
        address tokenA = makeAddr("TokenIsoA");
        address tokenB = makeAddr("TokenIsoB");
        vm.mockCall(tokenA, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));
        vm.mockCall(tokenB, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));

        // Initialize both tokens.
        (TOFUOutcome outcome, uint8 result) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, tokenA);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimalsA);

        (outcome, result) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, tokenB);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(result, decimalsB);

        // Re-read both: each should be Consistent with its own stored value.
        (outcome, result) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, tokenA);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(result, decimalsA);

        (outcome, result) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, tokenB);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(result, decimalsB);
    }

    /// A ReadFailure on the very first (uninitialized) call must not write
    /// storage. A subsequent valid call should still return Initial, proving
    /// the failed first attempt left storage untouched.
    function testDecimalsForTokenNoStorageWriteOnUninitializedReadFailure(uint8 decimalsA, uint256 tooLarge) external {
        vm.assume(tooLarge > 0xff);
        address token = makeAddr("TokenG");

        // First call: ReadFailure via too-large value on uninitialized storage.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(tooLarge));
        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        // Fix mock to return a valid value: should be Initial, not Consistent,
        // proving the ReadFailure did not initialize storage.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));
        (tofuOutcome, readDecimals) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, decimalsA);
    }

    function testDecimalsForTokenTokenContractRevert(uint8 storedDecimals) external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        sTokenTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) = LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }
}
