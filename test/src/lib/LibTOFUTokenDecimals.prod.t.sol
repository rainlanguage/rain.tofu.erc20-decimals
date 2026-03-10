// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibTOFUTokenDecimals, TOFUOutcome} from "src/lib/LibTOFUTokenDecimals.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// Verifies the TOFU singleton deployment on every supported production
/// network. Each test forks a network and checks the deployed address,
/// codehash, and basic functionality against the real on-chain contract.
contract LibTOFUTokenDecimalsProdTest is Test {
    function testProdDeploymentArbitrum() external {
        _verifyDeployment("arbitrum");
    }

    function testProdDeploymentBase() external {
        _verifyDeployment("base");
    }

    function testProdDeploymentBaseSepolia() external {
        _verifyDeployment("base_sepolia");
    }

    function testProdDeploymentFlare() external {
        _verifyDeployment("flare");
    }

    function testProdDeploymentPolygon() external {
        _verifyDeployment("polygon");
    }

    function _verifyDeployment(string memory network) internal {
        vm.createSelectFork(network);

        address singleton = address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT);

        // Contract must exist at the expected address.
        assertTrue(singleton.code.length > 0, string.concat("No code at singleton on ", network));

        // Codehash must match.
        assertEq(
            singleton.codehash,
            LibTOFUTokenDecimals.TOFU_DECIMALS_EXPECTED_CODE_HASH,
            string.concat("Codehash mismatch on ", network)
        );

        // ensureDeployed must not revert.
        LibTOFUTokenDecimals.ensureDeployed();

        // Basic functional test: reading decimals for a mock token should work.
        address token = makeAddr(string.concat("ProdTestToken_", network));
        vm.mockCall(token, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint8(18)));
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForToken(token);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 18);
    }
}
