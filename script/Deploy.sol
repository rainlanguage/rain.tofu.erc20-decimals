// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Script} from "forge-std-1.16.1/src/Script.sol";
import {LibRainDeploy} from "rain-deploy-0.1.3/src/lib/LibRainDeploy.sol";
import {TOFUTokenDecimals} from "../src/concrete/TOFUTokenDecimals.sol";
import {LibTOFUTokenDecimals} from "../src/lib/LibTOFUTokenDecimals.sol";

/// @dev Hash of the "tofu-token-decimals" deployment suite string.
bytes32 constant DEPLOYMENT_SUITE_TOFU_TOKEN_DECIMALS = keccak256("tofu-token-decimals");

/// @title Deploy
/// @notice Deploys the `TOFUTokenDecimals` singleton via the Zoltu
/// deterministic factory across all supported networks. Requires the
/// `DEPLOYMENT_KEY` environment variable to be set to the deployer's private
/// key.
contract Deploy is Script {
    /// @notice Storage mapping for dependency code hashes, required by
    /// `LibRainDeploy.deployAndBroadcast` to track dependency integrity
    /// across the check and deploy phases.
    mapping(string => mapping(address => bytes32)) internal sDepCodeHashes;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYMENT_KEY");

        bytes32 suite = keccak256(bytes(vm.envOr("DEPLOYMENT_SUITE", string("tofu-token-decimals"))));
        if (suite == DEPLOYMENT_SUITE_TOFU_TOKEN_DECIMALS) {
            LibRainDeploy.deployAndBroadcast(
                vm,
                LibRainDeploy.supportedNetworks(),
                deployerPrivateKey,
                type(TOFUTokenDecimals).creationCode,
                "src/concrete/TOFUTokenDecimals.sol:TOFUTokenDecimals",
                address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT),
                LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH,
                new address[](0),
                sDepCodeHashes
            );
        } else {
            revert(
                "Invalid deployment suite specified. Please set the DEPLOYMENT_SUITE environment variable to 'tofu-token-decimals'."
            );
        }
    }
}
