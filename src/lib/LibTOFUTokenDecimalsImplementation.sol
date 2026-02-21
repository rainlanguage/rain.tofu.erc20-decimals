// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {TOFUTokenDecimalsResult, TOFUOutcome, ITOFUTokenDecimals} from "../interface/ITOFUTokenDecimals.sol";

/// @title LibTOFUTokenDecimalsImplementation
/// @notice This library contains the implementation logic for reading token decimals
/// with a trust on first use (TOFU) approach. It provides functions to read
/// token decimals, store them on first read, and check for consistency on
/// subsequent reads. The library is designed to be used in `TOFUTokenDecimals`,
/// which handles the storage of token decimals as a concrete contract.
library LibTOFUTokenDecimalsImplementation {
    /// @dev The selector for the `decimals()` function in the ERC20 standard.
    bytes4 constant TOFU_DECIMALS_SELECTOR = 0x313ce567;

    /// @notice As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`. Works as
    /// `decimalsForToken` but does not store any state, simply checking for
    /// consistency if we have a stored value.
    /// @param sTOFUTokenDecimals The storage mapping of token addresses to
    /// TOFUTokenDecimalsResult structs that will be used to track the initial
    /// reads of token decimals and allows consistency checks on subsequent
    /// reads.
    /// @param token The token to read the decimals for.
    /// @return tofuOutcome The outcome of the TOFU read.
    /// @return tokenDecimals The token's decimals. On `Initial`, the freshly
    /// read value. On `Consistent` or `Inconsistent`, the previously stored
    /// value. On `ReadFailure`, the stored value (zero if uninitialized).
    function decimalsForTokenReadOnly(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    ) internal view returns (TOFUOutcome, uint8) {
        TOFUTokenDecimalsResult memory tofuTokenDecimals = sTOFUTokenDecimals[token];

        // We need to handle all errors or unexpected return values as read
        // failures so that the calling context can decide whether to revert the
        // current transaction or continue with the stored value.
        // E.g. withdrawals if a vault may prefer to continue than trap funds,
        // while deposits may prefer to revert and prevent new funds entering the
        // vault.
        bytes4 selector = TOFU_DECIMALS_SELECTOR;
        bool success;
        uint256 readDecimals = 0;
        assembly ("memory-safe") {
            mstore(0, selector)
            success := staticcall(gas(), token, 0, 0x04, 0, 0x20)
            if lt(returndatasize(), 0x20) {
                success := 0
            }
            if success {
                readDecimals := mload(0)
                if gt(readDecimals, 0xff) {
                    success := 0
                }
            }
        }

        // In case of a read failure, return the stored value (which may be
        // uninitialized) along with the ReadFailure outcome.
        if (!success) {
            return (TOFUOutcome.ReadFailure, tofuTokenDecimals.tokenDecimals);
        }

        // If we have no stored value, return the read value with the Initial
        // outcome.
        if (!tofuTokenDecimals.initialized) {
            // We check that the read value fits in a uint8 above, so this cast
            // is safe.
            // forge-lint: disable-next-line(unsafe-typecast)
            return (TOFUOutcome.Initial, uint8(readDecimals));
        } else {
            // We have a stored value, check for consistency.
            return (
                readDecimals == tofuTokenDecimals.tokenDecimals ? TOFUOutcome.Consistent : TOFUOutcome.Inconsistent,
                tofuTokenDecimals.tokenDecimals
            );
        }
    }

    /// @notice As per `ITOFUTokenDecimals.decimalsForToken`. Trust on first use
    /// (TOFU) token decimals.
    /// The first time we read the decimals from a token we store them in a
    /// mapping. If the token's decimals change we will always use the stored
    /// value. This is because the token's decimals could technically change and
    /// are NOT intended for onchain use as they are optional, but we're doing
    /// it anyway to convert to floating point numbers.
    ///
    /// If we have nothing stored we read from the token, store and return it
    /// with TOFUOutcome.Initial.
    ///
    /// If the stored value is consistent with the token's decimals we return
    /// the stored value and TOFUOutcome.Consistent.
    ///
    /// If the call to `decimals` is not a success that deserializes cleanly to
    /// a `uint8` we return the stored value and TOFUOutcome.ReadFailure.
    ///
    /// If the stored value is inconsistent with the token's decimals we return
    /// the stored value and TOFUOutcome.Inconsistent.
    /// @param sTOFUTokenDecimals The storage mapping of token addresses to
    /// TOFUTokenDecimalsResult structs that will be used to track the initial
    /// reads of token decimals and allows consistency checks on subsequent
    /// reads.
    /// @param token The token to read the decimals for.
    /// @return tofuOutcome The outcome of the TOFU read.
    /// @return tokenDecimals The token's decimals. On `Initial`, the freshly
    /// read value. On `Consistent` or `Inconsistent`, the previously stored
    /// value. On `ReadFailure`, the stored value (zero if uninitialized).
    function decimalsForToken(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    )
        internal
        returns (TOFUOutcome, uint8)
    {
        (TOFUOutcome tofuOutcome, uint8 tokenDecimals) = decimalsForTokenReadOnly(sTOFUTokenDecimals, token);

        if (tofuOutcome == TOFUOutcome.Initial) {
            sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: tokenDecimals});
        }
        return (tofuOutcome, tokenDecimals);
    }

    /// @notice As per `ITOFUTokenDecimals.safeDecimalsForToken`. Trust on first
    /// use (TOFU) token decimals.
    /// Same as `decimalsForToken` but reverts with `ITOFUTokenDecimals.TokenDecimalsReadFailure`
    /// if the token's decimals are inconsistent or the read fails. On the
    /// first read the decimals are never considered inconsistent.
    /// @param sTOFUTokenDecimals The storage mapping of token addresses to
    /// TOFUTokenDecimalsResult structs that will be used to track the initial
    /// reads of token decimals and allows consistency checks on subsequent
    /// reads.
    /// @param token The token to read the decimals for.
    /// @return The token's decimals.
    function safeDecimalsForToken(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    ) internal returns (uint8) {
        (TOFUOutcome tofuOutcome, uint8 tokenDecimals) = decimalsForToken(sTOFUTokenDecimals, token);
        if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
            revert ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome);
        }
        return tokenDecimals;
    }

    /// @notice As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`.
    /// Same as `safeDecimalsForToken` but read-only. Does not store the decimals
    /// on first read. WARNING: Before initialization, each call is a fresh
    /// `Initial` read with no stored value to check against, so inconsistency
    /// between calls cannot be detected. Callers needing TOFU protection must
    /// ensure `decimalsForToken` has been called at least once for the token.
    /// @param sTOFUTokenDecimals The storage mapping of token addresses to
    /// TOFUTokenDecimalsResult structs that will be used to track the initial
    /// reads of token decimals and allows consistency checks on subsequent
    /// reads.
    /// @param token The token to read the decimals for.
    /// @return The token's decimals.
    function safeDecimalsForTokenReadOnly(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    ) internal view returns (uint8) {
        (TOFUOutcome tofuOutcome, uint8 tokenDecimals) = decimalsForTokenReadOnly(sTOFUTokenDecimals, token);
        if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
            revert ITOFUTokenDecimals.TokenDecimalsReadFailure(token, tofuOutcome);
        }
        return tokenDecimals;
    }
}
