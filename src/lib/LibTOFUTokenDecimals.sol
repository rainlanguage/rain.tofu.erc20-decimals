// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {TOFUOutcome, ITOFUTokenDecimals, TokenDecimalsReadFailure} from "../interface/ITOFUTokenDecimals.sol";

/// @title LibTOFUTokenDecimals
/// Library for reading and storing token decimals with a trust on first use
/// (TOFU) approach. This is used to read the decimals of ERC20 tokens and store
/// them for future use, under the assumption that the decimals will not change
/// after the first read. As this involves storing the decimals, which is a state
/// change, there is a read only version of the logic to simply check that
/// decimals are either uninitialized or consistent, without storing anything.
/// The caller is responsible for ensuring that read/write and read only versions
/// are used appropriately for their use case without introducing inconsistency.
///
/// This library is for the caller to use the deployed TOFUTokenDecimals contract
/// externally with the convenience of an internal function interface to the lib.
/// Essentially it removes the need for callers to be aware of or deal with the
/// zoltu deployments directly.
library LibTOFUTokenDecimals {
    /// Thrown when attempting to use an address that is not deployed.
    error TOFUTokenDecimalsNotDeployed(address deployedAddress);

    /// The deployed TOFUTokenDecimals contract address. The deploy script uses
    /// Zoltu for deterministic deployments so this address is fixed across all
    /// supported networks.
    ITOFUTokenDecimals constant TOFU_DECIMALS_DEPLOYMENT =
        ITOFUTokenDecimals(0xF66761F6b5F58202998D6Cd944C81b22Dc6d4f1E);

    /// Ensures that the TOFUTokenDecimals contract is deployed. Having an
    /// explicit guard prevents silent call failures and gives a clear error
    /// message for easier debugging.
    function ensureDeployed() internal view {
        if (address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0) {
            revert TOFUTokenDecimalsNotDeployed(address(TOFU_DECIMALS_DEPLOYMENT));
        }
    }

    /// As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`.
    function decimalsForTokenReadOnly(address token) internal view returns (TOFUOutcome, uint8) {
        ensureDeployed();
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token);
    }

    /// As per `ITOFUTokenDecimals.decimalsForToken`.
    function decimalsForToken(address token) internal returns (TOFUOutcome, uint8) {
        ensureDeployed();
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token);
    }

    /// As per `ITOFUTokenDecimals.safeDecimalsForToken`.
    function safeDecimalsForToken(address token) internal returns (uint8) {
        ensureDeployed();
        return TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForToken(token);
    }
}
