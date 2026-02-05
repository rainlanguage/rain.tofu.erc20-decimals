// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {LibTOFUTokenDecimals} from "src/lib/LibTOFUTokenDecimals.sol";
import {Test} from "forge-std/Test.sol";

contract LibTOFUTokenDecimalsTest is Test {
    // function testDeployAddress() external {
    //     vm.createSelectFork(vm.envString("ETH_RPC_URL"));
    //     address deployedAddress = LibTOFUTokenDecimalsDeploy.deployZoltu();
    //     assertEq(deployedAddress, address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT));
    // }

    function testExpectedCodeHash() external {
        TOFUTokenDecimals tofuTokenDecimals = new TOFUTokenDecimals();

        assertEq(address(tofuTokenDecimals).codehash, LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH);
    }
}
