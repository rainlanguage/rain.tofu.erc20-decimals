// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    LibTOFUTokenDecimalsImplementation,
    TOFUOutcome,
    TOFUTokenDecimalsResult
} from "src/lib/LibTOFUTokenDecimalsImplementation.sol";
import {ITOFUTokenDecimals} from "src/interface/ITOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenReadOnlyTest is Test {
    mapping(address => TOFUTokenDecimalsResult) internal sTokenDecimals;

    function externalSafeDecimalsForTokenReadOnly(address token) external view returns (uint8) {
        return LibTOFUTokenDecimalsImplementation.safeDecimalsForTokenReadOnly(sTokenDecimals, token);
    }

    function testSafeDecimalsForTokenReadOnlyAddressZeroUninitialized() external {
        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, address(0), TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(address(0));
    }

    function testSafeDecimalsForTokenReadOnlyAddressZeroInitialized(uint8 storedDecimals) external {
        sTokenDecimals[address(0)] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, address(0), TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(address(0));
    }

    function testSafeDecimalsForTokenReadOnlyValidValue(uint8 decimalsA, uint8 decimalsB) external {
        address token = makeAddr("TokenA");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        // Read only never stores, so first read is always Initial.
        assertEq(this.externalSafeDecimalsForTokenReadOnly(token), decimalsA);

        // Manually initialize storage to test Consistent/Inconsistent.
        sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(decimalsA)});

        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        if (decimalsA == decimalsB) {
            assertEq(this.externalSafeDecimalsForTokenReadOnly(token), decimalsA);
        } else {
            vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.Inconsistent));
            this.externalSafeDecimalsForTokenReadOnly(token);
        }
    }

    function testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeUninitialized(uint256 decimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(token);
    }

    function testSafeDecimalsForTokenReadOnlyInvalidValueTooLargeInitialized(uint256 decimals, uint8 storedDecimals)
        external
    {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(token);
    }

    function testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataUninitialized(bytes memory data, uint256 length)
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

        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(token);
    }

    function testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughDataInitialized(
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

        sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(token);
    }

    function testSafeDecimalsForTokenReadOnlyTokenContractRevertUninitialized() external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(token);
    }

    /// Initializes storage via `decimalsForToken` then reads back through
    /// `safeDecimalsForTokenReadOnly`, verifying cross-function storage
    /// agreement at the implementation layer.
    function testSafeDecimalsForTokenReadOnlyAfterDecimalsForToken(uint8 decimalsA, uint8 decimalsB) external {
        address token = makeAddr("TokenE");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        // Initialize storage via decimalsForToken.
        LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenDecimals, token);

        // Read back via safeDecimalsForTokenReadOnly.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        if (decimalsA == decimalsB) {
            assertEq(this.externalSafeDecimalsForTokenReadOnly(token), decimalsA);
        } else {
            vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.Inconsistent));
            this.externalSafeDecimalsForTokenReadOnly(token);
        }
    }

    function testSafeDecimalsForTokenReadOnlyTokenContractRevertInitialized(uint8 storedDecimals) external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(ITOFUTokenDecimals.TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForTokenReadOnly(token);
    }
}
