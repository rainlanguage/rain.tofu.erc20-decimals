// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {LibTOFUTokenDecimals, TOFUOutcome} from "src/lib/LibTOFUTokenDecimals.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsDecimalsForTokenReadOnlyTest is Test {
    constructor() {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        address deployedAddress = LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode);
        assertEq(deployedAddress, address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT));

        // Check that ensure deployed finds the contract correctly.
        LibTOFUTokenDecimals.ensureDeployed();
    }

    function testDecimalsForTokenReadOnlyAddressZero() external view {
        (TOFUOutcome tofuOutcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(address(0));
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(decimals, 0);
    }

    function testDecimalsForTokenReadOnlyValidValue(uint8 decimalsA, uint8 decimalsB) external {
        address token = makeAddr("TokenA");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsA));

        (TOFUOutcome tofuOutcome, uint8 readDecimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, decimalsA);

        // As this is read only we are still uninitialized so always get initial
        // back again.
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimalsB));
        (tofuOutcome, readDecimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.Initial));
        assertEq(readDecimals, decimalsB);
    }

    function testDecimalsForTokenReadOnlyInvalidValueTooLarge(uint256 decimals) external {
        vm.assume(decimals > 0xff);
        address token = makeAddr("TokenB");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));
        (TOFUOutcome tofuOutcome, uint8 readDecimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);
    }

    function testDecimalsForTokenReadOnlyInvalidValueNotEnoughData(bytes memory data, uint256 length) external {
        length = bound(length, 0, 0x1f);
        if (data.length > length) {
            assembly ("memory-safe") {
                mstore(data, length)
            }
        }
        address token = makeAddr("TokenC");
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), data);
        (TOFUOutcome tofuOutcome, uint8 readDecimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);
    }

    function testDecimalsForTokenReadOnlyTokenContractRevert() external {
        address token = makeAddr("TokenD");
        vm.etch(token, hex"fd");
        (TOFUOutcome tofuOutcome, uint8 readDecimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(token);
        assertEq(uint256(tofuOutcome), uint256(TOFUOutcome.ReadFailure));
        assertEq(readDecimals, 0);
    }
}
