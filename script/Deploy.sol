// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std/Script.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {TOFUTokenDecimals} from "../src/concrete/TOFUTokenDecimals.sol";
import {LibTOFUTokenDecimals} from "../src/lib/LibTOFUTokenDecimals.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        LibRainDeploy.deployAndBroadcastToSupportedNetworks(
            vm,
            LibRainDeploy.supportedNetworks(),
            deployerPrivateKey,
            type(TOFUTokenDecimals).creationCode,
            "src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals",
            address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT),
            LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH,
            new address[](0)
        );
    }
}
