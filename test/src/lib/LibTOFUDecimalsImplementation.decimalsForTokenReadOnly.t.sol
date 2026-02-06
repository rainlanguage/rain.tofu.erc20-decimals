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

contract LibTOFUDecimalsImplementationDecimalsForTokenReadOnlyTest is Test {
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
        } else {
            assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Inconsistent));
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
