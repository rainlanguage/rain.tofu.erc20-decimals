// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {TOFUTokenDecimals} from "../src/concrete/TOFUTokenDecimals.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        // DataContractMemoryContainer container = LibDecimalFloatDeploy.dataContract();

        vm.startBroadcast(deployerPrivateKey);

        new TOFUTokenDecimals();

        // container.writeZoltu();

        // LibDecimalFloatDeploy.decimalFloatZoltu();

        vm.stopBroadcast();
    }
}
