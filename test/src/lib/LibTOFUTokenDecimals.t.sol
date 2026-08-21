// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibTOFUTokenDecimals, TOFUOutcome} from "src/lib/LibTOFUTokenDecimals.sol";
import {Test} from "forge-std-1.16.1/src/Test.sol";

/// @title LibTOFUTokenDecimalsTest
/// @notice Every `LibTOFUTokenDecimals` path that reaches the singleton with
/// nothing usable at the pinned address: no code at all, and code with the
/// wrong hash. These need no concrete, because what they assert is that the
/// call is refused before it happens.
///
/// The happy paths are NOT here. `ensureDeployed` pins the codehash, so the
/// only thing that satisfies it is the real singleton bytecode, which only the
/// deploy half compiles. Those suites, and the assertions that this repo's
/// pinned address, code hash and creation code are what that bytecode produces,
/// live in
/// [rain.tofu.erc20-decimals.deploy](https://github.com/rainlanguage/rain.tofu.erc20-decimals.deploy).
contract LibTOFUTokenDecimalsTest is Test {
    function externalEnsureDeployed() external view {
        LibTOFUTokenDecimals.ensureDeployed();
    }

    function externalDecimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8) {
        return LibTOFUTokenDecimals.decimalsForTokenReadOnly(token);
    }

    function externalDecimalsForToken(address token) external returns (TOFUOutcome, uint8) {
        return LibTOFUTokenDecimals.decimalsForToken(token);
    }

    function externalSafeDecimalsForToken(address token) external returns (uint8) {
        return LibTOFUTokenDecimals.safeDecimalsForToken(token);
    }

    function externalSafeDecimalsForTokenReadOnly(address token) external view returns (uint8) {
        return LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(token);
    }

    function testEnsureDeployedRevert() external {
        vm.expectRevert(
            abi.encodeWithSelector(
                LibTOFUTokenDecimals.TOFUTokenDecimalsNotDeployed.selector,
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)
            )
        );
        this.externalEnsureDeployed();
    }

    function testEnsureDeployedRevertWrongCodeHash() external {
        // Deploy a contract to the expected address but with different code to test the code hash check.
        vm.etch(
            address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT),
            hex"600060005260206000f3" // simple contract with different code hash
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                LibTOFUTokenDecimals.TOFUTokenDecimalsNotDeployed.selector,
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)
            )
        );
        this.externalEnsureDeployed();
    }

    function testDecimalsForTokenReadOnlyRevert() external {
        address token = makeAddr("TokenA");
        vm.expectRevert(
            abi.encodeWithSelector(
                LibTOFUTokenDecimals.TOFUTokenDecimalsNotDeployed.selector,
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)
            )
        );
        this.externalDecimalsForTokenReadOnly(token);
    }

    function testDecimalsForTokenRevert() external {
        address token = makeAddr("TokenB");
        vm.expectRevert(
            abi.encodeWithSelector(
                LibTOFUTokenDecimals.TOFUTokenDecimalsNotDeployed.selector,
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)
            )
        );
        this.externalDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenRevert() external {
        address token = makeAddr("TokenC");
        vm.expectRevert(
            abi.encodeWithSelector(
                LibTOFUTokenDecimals.TOFUTokenDecimalsNotDeployed.selector,
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)
            )
        );
        this.externalSafeDecimalsForToken(token);
    }

    function testSafeDecimalsForTokenReadOnlyRevert() external {
        address token = makeAddr("TokenD");
        vm.expectRevert(
            abi.encodeWithSelector(
                LibTOFUTokenDecimals.TOFUTokenDecimalsNotDeployed.selector,
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT)
            )
        );
        this.externalSafeDecimalsForTokenReadOnly(token);
    }
}
