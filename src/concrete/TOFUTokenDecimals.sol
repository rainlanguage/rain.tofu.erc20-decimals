// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {TOFUOutcome, TOFUTokenDecimalsResult, LibTOFUTokenDecimals} from "../lib/LibTOFUTokenDecimals.sol";

contract TOFUTokenDecimals {
    // forge-lint: disable-next-line(mixed-case-variable)
    mapping(address token => TOFUTokenDecimalsResult tofuTokenDecimals) internal sTOFUTokenDecimals;

    function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8) {
        return LibTOFUTokenDecimals.decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
    }

    function decimalsForToken(address token) external returns (TOFUOutcome, uint8) {
        return LibTOFUTokenDecimals.decimalsForToken(sTOFUTokenDecimals, token);
    }

    function safeDecimalsForToken(address token) external returns (uint8) {
        return LibTOFUTokenDecimals.safeDecimalsForToken(sTOFUTokenDecimals, token);
    }
}
