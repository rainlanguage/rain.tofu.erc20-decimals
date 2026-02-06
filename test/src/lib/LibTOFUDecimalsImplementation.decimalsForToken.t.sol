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

contract LibTOFUDecimalsImplementationDecimalsForTokenTest is Test {
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
        } else {
            assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Inconsistent));
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
