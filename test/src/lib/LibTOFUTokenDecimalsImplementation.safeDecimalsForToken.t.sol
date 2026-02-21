// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {
    LibTOFUTokenDecimalsImplementation,
    TOFUOutcome,
    TOFUTokenDecimalsResult,
    TokenDecimalsReadFailure
} from "src/lib/LibTOFUTokenDecimalsImplementation.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsImplementationSafeDecimalsForTokenTest is Test {
    mapping(address => TOFUTokenDecimalsResult) internal sTokenDecimals;

    function externalSafeDecimalsForToken(address token) external returns (uint8) {
        return LibTOFUTokenDecimalsImplementation.safeDecimalsForToken(sTokenDecimals, token);
    }

    function testSafeDecimalsForTokenAddressZeroUninitialized() external {
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, address(0), TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(address(0));
    }

    function testSafeDecimalsForTokenAddressZeroInitialized(uint8 storedDecimals) external {
        sTokenDecimals[address(0)] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, address(0), TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(address(0));
    }

    /// The Initial path through safeDecimalsForToken must succeed and return
    /// the correct decimals.
    function testSafeDecimalsForTokenInitial(uint8 decimals) external {
        address token = makeAddr("TokenInitial");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        assertEq(this.externalSafeDecimalsForToken(token), decimals);
    }

    function testSafeDecimalsForTokenValidValue(uint8 decimalsA, uint8 decimalsB) external {
        address token = makeAddr("TokenA");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            LibTOFUTokenDecimalsImplementation.decimalsForToken(sTokenDecimals, token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, decimalsA);

        // mock decimalsB.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        if (decimalsA == decimalsB) {
            assertEq(this.externalSafeDecimalsForToken(token), decimalsA);
        } else {
            vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.Inconsistent));
            this.externalSafeDecimalsForToken(token);
        }
    }

    function testSafeDecimalsForTokenInvalidValueTooLargeUninitialized(uint256 decimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenInvalidValueTooLargeInitialized(uint256 decimals, uint8 storedDecimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenInvalidValueNotEnoughDataUninitialized(bytes memory data, uint256 length)
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

        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenInvalidValueNotEnoughDataInitialized(
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
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenTokenContractRevertUninitialized() external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenTokenContractRevertInitialized(uint8 storedDecimals) external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        sTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: uint8(storedDecimals)});
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        this.externalSafeDecimalsForToken(token);
    }
}
