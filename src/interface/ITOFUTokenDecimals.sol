// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

/// Encodes the token's decimals for a token. Includes a bool to indicate if
/// the token's decimals have been read from the external contract before. This
/// guards against the default `0` value for unset storage data being
/// misinterpreted as a valid token decimal value `0`.
/// @param initialized True if the token's decimals have been read from the
/// external contract before.
/// @param tokenDecimals The token's decimals.
// forge-lint: disable-next-line(pascal-case-struct)
struct TOFUTokenDecimalsResult {
    bool initialized;
    uint8 tokenDecimals;
}

/// Outcomes for TOFU token decimals reads.
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

/// @title ITOFUTokenDecimals
/// Interface for a contract that reads and stores token decimals with a trust
/// on first use (TOFU) approach. This is used to read the decimals of ERC20
/// tokens and store them for future use, to guard against the possibility of
/// tokens changing their decimals after the first read.
/// Contracts that need to convert amounts, such as moving between different
/// fixed point representations, or from fixed to floating point logic, do need
/// to know the token decimals to do so correctly. If these contracts can assume
/// the decimals do not change over time they can greatly simplify the internal
/// logic to not guard against secondary conversions of previously calculated
/// values.
/// As we only care about avoiding secondary conversions, it is sufficient to
/// rely on a TOFU scheme and use whatever decimals we first read as long as it
/// is consistent with the current read on subsequent uses.
/// Callers are strongly recommended to implement logic that gracefully handles
/// the possibility of inconsistent decimals being detected, e.g. allowing users
/// to withdraw their funds but preventing further deposits or trading until the
/// issue is resolved.
interface ITOFUTokenDecimals {
    /// Reads the decimals for a token in a read only manner. This does not store
    /// the decimals and is intended for callers to check that the decimals are
    /// either uninitialized or consistent with the stored value, without
    /// modifying state.
    /// This is relatively useless until after `decimalsForToken` has been
    /// called at least once for the token to initialize the stored decimals.
    /// The caller is advised to handle the uninitialized case appropriately
    /// when using read only decimals.
    /// @param token The token to read the decimals for.
    /// @return tofuOutcome The outcome of the TOFU read.
    /// @return tokenDecimals The token's decimals. On `Initial`, the freshly
    /// read value. On `Consistent` or `Inconsistent`, the previously stored
    /// value. On `ReadFailure`, the stored value (zero if uninitialized).
    function decimalsForTokenReadOnly(address token) external view returns (TOFUOutcome, uint8);

    /// Reads the decimals for a token, storing them if this is the first read.
    /// The outcome enum needs to be handled by the caller to detect and
    /// respond to inconsistent decimals, or other failures.
    /// @param token The token to read the decimals for.
    /// @return tofuOutcome The outcome of the TOFU read.
    /// @return tokenDecimals The token's decimals. On `Initial`, the freshly
    /// read value. On `Consistent` or `Inconsistent`, the previously stored
    /// value. On `ReadFailure`, the stored value (zero if uninitialized).
    function decimalsForToken(address token) external returns (TOFUOutcome, uint8);

    /// Safely reads the decimals for a token, reverting if the read fails or
    /// is inconsistent with the stored value.
    /// @param token The token to read the decimals for.
    /// @return tokenDecimals The token's decimals.
    function safeDecimalsForToken(address token) external returns (uint8);

    /// Safely reads the decimals for a token in a read only manner, reverting
    /// if the read fails or is inconsistent with the stored value.
    /// @param token The token to read the decimals for.
    /// @return tokenDecimals The token's decimals.
    function safeDecimalsForTokenReadOnly(address token) external view returns (uint8);
}
