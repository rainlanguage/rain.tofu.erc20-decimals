// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {LibTOFUTokenDecimalsDeploy} from "../src/lib/LibTOFUTokenDecimalsDeploy.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        vm.startBroadcast(deployerPrivateKey);

        address deployedAddress = LibTOFUTokenDecimalsDeploy.deployZoltu();
        console2.log("Deployed TOFUTokenDecimals to:", deployedAddress);

        vm.stopBroadcast();
    }
}
