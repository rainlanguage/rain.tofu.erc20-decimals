// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {Test} from "forge-std/Test.sol";
import {LibTOFUTokenDecimals, TOFUOutcome} from "src/lib/LibTOFUTokenDecimals.sol";
import {LibRainDeploy} from "rain.deploy/lib/LibRainDeploy.sol";
import {TOFUTokenDecimals} from "src/concrete/TOFUTokenDecimals.sol";

/// Integration tests that call the library against real mainnet ERC20 tokens
/// on a fork. Validates that the inline assembly `staticcall` works correctly
/// with real-world ABI encoding, not just `vm.mockCall` mocks.
contract LibTOFUTokenDecimalsRealTokensTest is Test {
    /// WETH — 18 decimals.
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    /// USDC — 6 decimals.
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    /// WBTC — 8 decimals.
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    /// DAI — 18 decimals.
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    constructor() {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        address deployedAddress = LibRainDeploy.deployZoltu(type(TOFUTokenDecimals).creationCode);
        assertEq(deployedAddress, address(LibTOFUTokenDecimals.TOFU_DECIMALS_DEPLOYMENT));
        LibTOFUTokenDecimals.ensureDeployed();
    }

    /// WETH returns 18 decimals on initial read and consistent on re-read.
    function testRealTokenWETH() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForToken(WETH);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 18);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForToken(WETH);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 18);
    }

    /// USDC returns 6 decimals on initial read and consistent on re-read.
    function testRealTokenUSDC() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForToken(USDC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 6);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForToken(USDC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 6);
    }

    /// WBTC returns 8 decimals on initial read and consistent on re-read.
    function testRealTokenWBTC() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForToken(WBTC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 8);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForToken(WBTC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 8);
    }

    /// DAI returns 18 decimals on initial read and consistent on re-read.
    function testRealTokenDAI() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForToken(DAI);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 18);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForToken(DAI);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 18);
    }

    /// decimalsForTokenReadOnly returns Initial then Consistent for WETH.
    function testRealTokenDecimalsForTokenReadOnlyWETH() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(WETH);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 18);

        LibTOFUTokenDecimals.decimalsForToken(WETH);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(WETH);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 18);
    }

    /// decimalsForTokenReadOnly returns Initial then Consistent for USDC.
    function testRealTokenDecimalsForTokenReadOnlyUSDC() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(USDC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 6);

        LibTOFUTokenDecimals.decimalsForToken(USDC);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(USDC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 6);
    }

    /// decimalsForTokenReadOnly returns Initial then Consistent for WBTC.
    function testRealTokenDecimalsForTokenReadOnlyWBTC() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(WBTC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 8);

        LibTOFUTokenDecimals.decimalsForToken(WBTC);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(WBTC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 8);
    }

    /// decimalsForTokenReadOnly returns Initial then Consistent for DAI.
    function testRealTokenDecimalsForTokenReadOnlyDAI() external {
        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(DAI);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Initial));
        assertEq(decimals, 18);

        LibTOFUTokenDecimals.decimalsForToken(DAI);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForTokenReadOnly(DAI);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 18);
    }

    /// safeDecimalsForToken succeeds on WETH.
    function testRealTokenSafeDecimalsForTokenWETH() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForToken(WETH);
        assertEq(decimals, 18);

        decimals = LibTOFUTokenDecimals.safeDecimalsForToken(WETH);
        assertEq(decimals, 18);
    }

    /// safeDecimalsForToken succeeds on USDC.
    function testRealTokenSafeDecimalsForTokenUSDC() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForToken(USDC);
        assertEq(decimals, 6);

        decimals = LibTOFUTokenDecimals.safeDecimalsForToken(USDC);
        assertEq(decimals, 6);
    }

    /// safeDecimalsForToken succeeds on WBTC.
    function testRealTokenSafeDecimalsForTokenWBTC() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForToken(WBTC);
        assertEq(decimals, 8);

        decimals = LibTOFUTokenDecimals.safeDecimalsForToken(WBTC);
        assertEq(decimals, 8);
    }

    /// safeDecimalsForToken succeeds on DAI.
    function testRealTokenSafeDecimalsForTokenDAI() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForToken(DAI);
        assertEq(decimals, 18);

        decimals = LibTOFUTokenDecimals.safeDecimalsForToken(DAI);
        assertEq(decimals, 18);
    }

    /// safeDecimalsForTokenReadOnly succeeds on WETH.
    function testRealTokenSafeDecimalsForTokenReadOnlyWETH() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(WETH);
        assertEq(decimals, 18);

        LibTOFUTokenDecimals.decimalsForToken(WETH);

        decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(WETH);
        assertEq(decimals, 18);
    }

    /// safeDecimalsForTokenReadOnly succeeds on USDC.
    function testRealTokenSafeDecimalsForTokenReadOnlyUSDC() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(USDC);
        assertEq(decimals, 6);

        LibTOFUTokenDecimals.decimalsForToken(USDC);

        decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(USDC);
        assertEq(decimals, 6);
    }

    /// safeDecimalsForTokenReadOnly succeeds on WBTC.
    function testRealTokenSafeDecimalsForTokenReadOnlyWBTC() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(WBTC);
        assertEq(decimals, 8);

        LibTOFUTokenDecimals.decimalsForToken(WBTC);

        decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(WBTC);
        assertEq(decimals, 8);
    }

    /// safeDecimalsForTokenReadOnly succeeds on DAI.
    function testRealTokenSafeDecimalsForTokenReadOnlyDAI() external {
        uint8 decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(DAI);
        assertEq(decimals, 18);

        LibTOFUTokenDecimals.decimalsForToken(DAI);

        decimals = LibTOFUTokenDecimals.safeDecimalsForTokenReadOnly(DAI);
        assertEq(decimals, 18);
    }

    /// Cross-token isolation: initializing multiple real tokens does not
    /// cross-contaminate storage.
    function testRealTokenCrossTokenIsolation() external {
        LibTOFUTokenDecimals.decimalsForToken(WETH);
        LibTOFUTokenDecimals.decimalsForToken(USDC);

        (TOFUOutcome outcome, uint8 decimals) = LibTOFUTokenDecimals.decimalsForToken(WETH);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 18);

        (outcome, decimals) = LibTOFUTokenDecimals.decimalsForToken(USDC);
        assertEq(uint256(outcome), uint256(TOFUOutcome.Consistent));
        assertEq(decimals, 6);
    }
}
