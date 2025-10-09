// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

enum TOFUOutcome {
    /// Token's decimals have not been read from the external contract before.
    Initial,
    /// Token's decimals are consistent with the stored value.
    Consistent,
    /// Token's decimals are inconsistent with the stored value.
    Inconsistent,
    /// Token's decimals could not be read from the external contract.
    ReadFailure
}

/// Thrown when a TOFU decimals safe read fails.
/// @param token The token that failed to read decimals.
/// @param tofuOutcome The outcome of the TOFU read.
error TokenDecimalsReadFailure(address token, TOFUOutcome tofuOutcome);

interface ITOFUTokenDecimals {
    function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8);

    function decimalsForToken(address token) external returns (TOFUOutcome, uint8);

    function safeDecimalsForToken(address token) external returns (uint8);
}
