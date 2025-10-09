// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script, console2} from "forge-std/Script.sol";
import {TOFUTokenDecimals} from "../src/concrete/TOFUTokenDecimals.sol";

contract Deploy is Script {
    function deployZoltu() internal returns (address deployedAddress) {
        //slither-disable-next-line too-many-digits
        bytes memory code = type(TOFUTokenDecimals).creationCode;
        bool success;
        assembly ("memory-safe") {
            mstore(0, 0)
            success := call(gas(), 0x7A0D94F55792C434d74a40883C6ed8545E406D12, 0, add(code, 0x20), mload(code), 12, 20)
            deployedAddress := mload(0)
        }
        if (!success) {
            revert("DecimalFloat: deploy failed");
        }
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        // DataContractMemoryContainer container = LibDecimalFloatDeploy.dataContract();

        vm.startBroadcast(deployerPrivateKey);

        address deployedAddress = deployZoltu();
        console2.log("Deployed TOFUTokenDecimals to:", deployedAddress);

        // new TOFUTokenDecimals();

        // container.writeZoltu();

        // LibDecimalFloatDeploy.decimalFloatZoltu();

        vm.stopBroadcast();
    }
}
