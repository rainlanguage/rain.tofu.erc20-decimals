// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {LibTOFUTokenDecimals, TOFUOutcome} from "src/lib/LibTOFUTokenDecimals.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {Test} from "forge-std/Test.sol";

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

    function testDeployAddress() external {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        address deployedAddress = LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode);
        assertEq(deployedAddress, address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT));

        // Check that ensure deployed finds the contract correctly.
        LibTOFUTokenDecimals.ensureDeployed();
    }

    function testExpectedCodeHash() external {
        TOFUTokenDecimals tofuTokenDecimals = new TOFUTokenDecimals();

        assertEq(address(tofuTokenDecimals).codehash, LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH);
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
}
