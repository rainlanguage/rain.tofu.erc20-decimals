// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {LibTOFUTokenDecimals} from "src/lib/LibTOFUTokenDecimals.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {TokenDecimalsReadFailure, TOFUOutcome} from "src/lib/LibTOFUTokenDecimalsImplementation.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsSafeDecimalsForTokenReadOnlyTest is Test {
    constructor() {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        address deployedAddress = LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode);
        assertEq(deployedAddress, address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT));

        // Check that ensure deployed finds the contract correctly.
        LibTOFUTokenDecimals.ensureDeployed();
    }

    function testSafeDecimalsForTokenReadOnlyAddressZero() external {
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, address(0), TOFUOutcome.ReadFailure));
        LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(address(0));
    }

    function testSafeDecimalsForTokenReadOnlyValidValue(uint8 decimals) external {
        address token = makeAddr("TokenA");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));
        assertEq(LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(token), decimals);
    }

    function testSafeDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256 decimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(token);
    }

    function testSafeDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes memory data, uint256 length) external {
        length = bound(length, 0, 0x1f);
        if (data.length > length) {
            assembly ("memory-safe") {
                mstore(data, length)
            }
        }
        address token = makeAddr("TokenC");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), data);
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(token);
    }

    function testSafeDecimalsForTokenReadOnlyContractRevert() external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        vm.expectRevert(abi.encodeWithSelector(TokenDecimalsReadFailure.selector, token, TOFUOutcome.ReadFailure));
        LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(token);
    }
}
