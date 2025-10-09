// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {ITOFUTokenDecimals} from "../interface/ITOFUTokenDecimals.sol";
import {TOFUOutcome, TOFUTokenDecimalsResult, LibTOFUTokenDecimals} from "../lib/LibTOFUTokenDecimals.sol";

contract TOFUTokenDecimals is ITOFUTokenDecimals {
    // forge-lint: disable-next-line(mixed-case-variable)
    mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;

    /// @inheritdoc ITOFUTokenDecimals
    function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8) {
        return LibTOFUTokenDecimals.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
    }

    /// @inheritdoc ITOFUTokenDecimals
    function decimalsForToken(address token) external returns (TOFUOutcome, uint8) {
        return LibTOFUTokenDecimals.decimalsForToken(sTOFUTokenDecimals, token);
    }

    /// @inheritdoc ITOFUTokenDecimals
    function safeDecimalsForToken(address token) external returns (uint8) {
        return LibTOFUTokenDecimals.safeDecimalsForToken(sTOFUTokenDecimals, token);
    }
}
