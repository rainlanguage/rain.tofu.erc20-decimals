// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ITOFUTokenDecimals, TOFUTokenDecimalsResult} from "../interface/ITOFUTokenDecimals.sol";
import {TOFUOutcome, LibTOFUTokenDecimals} from "../lib/LibTOFUTokenDecimals.sol";
import {LibTOFUTokenDecimalsImplementation} from "../lib/LibTOFUTokenDecimalsImplementation.sol";

/// @title TOFUTokenDecimals
/// Minimal implementation of the ITOFUTokenDecimals interface using
/// LibTOFUTokenDecimalsImplementation for the logic. The concrete contract
/// simply stores the mapping of token addresses to TOFUTokenDecimalsResult
/// structs and delegates all logic to the library.
contract TOFUTokenDecimals is ITOFUTokenDecimals {
    // forge-lint: disable-next-line(mixed-case-variable)
    mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;

    /// @inheritdoc ITOFUTokenDecimals
    function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8) {
        // slither-disable-next-line unused-return
        return LibTOFUTokenDecimalsImplementation.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
    }

    /// @inheritdoc ITOFUTokenDecimals
    function decimalsForToken(address token) external returns (TOFUOutcome, uint8) {
        // slither-disable-next-line unused-return
        return LibTOFUTokenDecimalsImplementation.decimalsForToken(sTOFUTokenDecimals, token);
    }

    /// @inheritdoc ITOFUTokenDecimals
    function safeDecimalsForToken(address token) external returns (uint8) {
        return LibTOFUTokenDecimalsImplementation.safeDecimalsForToken(sTOFUTokenDecimals, token);
    }
}
