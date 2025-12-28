// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {LibTOFUTokenDecimalsDeploy} from "src/lib/LibTOFUTokenDecimalsDeploy.sol";
import {LibTOFUTokenDecimals} from "src/lib/LibTOFUTokenDecimals.sol";
import {Test} from "forge-std/Test.sol";

contract LibTOFUTokenDecimalsTest is Test {
    function testDeployAddress() external {
        vm.createSelectFork("https://eth.llamarpc.com");
        address deployedAddress = LibTOFUTokenDecimalsDeploy.deployZoltu();
        assertEq(deployedAddress, address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT));
    }
}
