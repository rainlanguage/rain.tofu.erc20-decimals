// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std-1.16.1/src/Test.sol";
import {
    LibTOFUTokenDecimalsImplementation,
    TOFUOutcome,
    TOFUTokenDecimalsResult
} from "src/lib/LibTOFUTokenDecimalsImplementation.sol";
import {IERC20} from "forge-std-1.16.1/src/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsImplementationDecimalsForTokenReadOnlyTest is Test {
    mapping(address => TOFUTokenDecimalsResult) internal sTOFUTokenDecimals;

    function testDecimalsForTokenReadOnlyAddressZero(uint8 storedDecimals) external {
        (TOFUOutcome tofuOutcome, uint8 decimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, address(0));
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(decimals, 0);

        sTOFUTokenDecimals[address(0)] =
            TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, decimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, address(0));
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(decimals, uint8(storedDecimals));
    }

    function testDecimalsForTokenReadOnlyValidValue(uint8 decimals, uint8 storedDecimals) external {
        address token = makeAddr("TokenA");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, decimals);

        sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        if (storedDecimals == uint8(decimals)) {
            assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Consistent));
            assertEq(readDecimals, storedDecimals);
        } else {
            assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Inconsistent));
            assertEq(readDecimals, storedDecimals);
        }
    }

    function testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256 decimals, uint8 storedDecimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }

    /// The uint8 fitness check rejects values strictly greater than `0xff`.
    /// The exact boundary value `0x100` (256), one past the largest valid
    /// uint8, must be treated as a `ReadFailure` and must not be truncated to
    /// `uint8(0x100) == 0`. Pins the upper bound at exactly `0xff` so a
    /// mutation loosening the check to `> 0x100` is caught.
    function testDecimalsForTokenReadOnlyExactBoundary256(uint8 storedDecimals) external {
        address token = makeAddr("TokenBoundary");
        // Exactly 256: one above the uint8 max.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint256(0x100)));

        // Uninitialized: must be ReadFailure, not Initial with decimals 0.
        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        // Initialized: must still be ReadFailure (returning the stored value),
        // never Inconsistent against the truncated value.
        sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }

    /// The largest valid uint8 value `0xff` (255) must be accepted as a normal
    /// read, pinning the lower edge of the rejection boundary so a mutation
    /// tightening the check to `> 0xfe` is caught.
    function testDecimalsForTokenReadOnlyExactBoundary255() external {
        address token = makeAddr("TokenBoundaryMax");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint256(0xff)));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, 0xff);
    }

    function testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(
        bytes memory data,
        uint256 length,
        uint8 storedDecimals
    ) external {
        length = bound(length, 0, 0x1f);
        if (data.length > length) {
            assembly ("memory-safe") {
                mstore(data, length)
            }
        }
        address token = makeAddr("TokenC");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), data);

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }

    function testDecimalsForTokenReadOnlyTokenContractRevert(uint8 storedDecimals) external {
        address token = makeAddr("TokenD");
        // Revert opcode.
        vm.etch(token, hex"fd");
        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);

        sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        (tofuOutcome, readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, uint8(storedDecimals));
    }
}
