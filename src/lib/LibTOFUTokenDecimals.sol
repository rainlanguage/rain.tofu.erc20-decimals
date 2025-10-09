// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {TOFUOutcome, ITOFUTokenDecimals, TokenDecimalsReadFailure} from "../interface/ITOFUTokenDecimals.sol";

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

/// @dev The selector for the `decimals()` function in the ERC20 standard.
bytes constant TOFU_DECIMALS_SELECTOR = hex"313ce567";

library LibTOFUTokenDecimals {
    ITOFUTokenDecimals constant TOFU_DECIMALS_DEPLOYMENT =
        ITOFUTokenDecimals(0x4f1C29FAAB7EDdF8D7794695d8259996734Cc665);

    function decimalsForTokenReadOnly(address token) internal view returns (TOFUOutcome, uint8) {
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token);
    }

    function decimalsForToken(address token) internal returns (TOFUOutcome, uint8) {
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token);
    }

    function safeDecimalsForToken(address token) internal returns (uint8) {
        return TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForToken(token);
    }

    function decimalsForTokenReadOnlyImplementation(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    ) internal view returns (TOFUOutcome, uint8) {
        TOFUTokenDecimalsResult memory tofuTokenDecimals = sTOFUTokenDecimals[token];

        // The default solidity try/catch logic will error if the return is a
        // success but fails to deserialize to the target type. We need to handle
        // all errors as read failures so that the calling context can decide
        // whether to revert the current transaction or continue with the stored
        // value. E.g. withdrawals if a vault may prefer to continue than trap
        // funds, while deposits may prefer to revert and prevent new funds
        // entering the vault.
        //slither-disable-start low-level-calls
        //slither-disable-start calls-loop
        (bool success, bytes memory returnData) = token.staticcall(TOFU_DECIMALS_SELECTOR);
        //slither-disable-end low-level-calls
        //slither-disable-end calls-loop
        if (!success || returnData.length != 0x20) {
            return (TOFUOutcome.ReadFailure, tofuTokenDecimals.tokenDecimals);
        }

        uint256 decodedDecimals = abi.decode(returnData, (uint256));
        if (decodedDecimals > type(uint8).max) {
            return (TOFUOutcome.ReadFailure, tofuTokenDecimals.tokenDecimals);
        }
        // We already handled the case of decodedDecimals > type(uint8).max
        // above so this cast is safe.
        // forge-lint: disable-next-line(unsafe-typecast)
        uint8 readDecimals = uint8(decodedDecimals);

        if (!tofuTokenDecimals.initialized) {
            return (TOFUOutcome.Initial, readDecimals);
        } else {
            return (
                readDecimals == tofuTokenDecimals.tokenDecimals ? TOFUOutcome.Consistent : TOFUOutcome.Inconsistent,
                tofuTokenDecimals.tokenDecimals
            );
        }
    }

    /// Trust on first use (TOFU) token decimals.
    /// The first time we read the decimals from a token we store them in a
    /// mapping. If the token's decimals change we will always use the stored
    /// value. This is because the token's decimals could technically change and
    /// are NOT intended for onchain use as they are optional, but we're doing
    /// it anyway to convert to floating point numbers.
    ///
    /// If we have nothing stored we read from the token, store and return it
    /// with TOFUOUTCOME.Initial.
    ///
    /// If the call to `decimals` is not a success that deserializes cleanly to
    /// a `uint8` we return the stored value and TOFUOUTCOME.ReadFailure.
    ///
    /// If the stored value is inconsistent with the token's decimals we return
    /// the stored value and TOFUOUTCOME.Inconsistent.
    function decimalsForTokenImplementation(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    ) internal returns (TOFUOutcome, uint8) {
        (TOFUOutcome tofuOutcome, uint8 readDecimals) =
            decimalsForTokenReadOnlyImplementation(sTOFUTokenDecimals, token);

        if (tofuOutcome == TOFUOutcome.Initial) {
            sTOFUTokenDecimals[token] = TOFUTokenDecimalsResult({initialized: true, tokenDecimals: readDecimals});
        }
        return (tofuOutcome, readDecimals);
    }

    /// Trust on first use (TOFU) token decimals.
    /// Same as `decimalsForToken` but reverts with a standard error if the
    /// token's decimals are inconsistent. On the first read the decimals are
    /// never considered inconsistent.
    /// @return The token's decimals.
    // forge-lint: disable-next-line(mixed-case-variable)
    function safeDecimalsForTokenImplementation(
        // forge-lint: disable-next-line(mixed-case-variable)
        mapping(address => TOFUTokenDecimalsResult) storage sTOFUTokenDecimals,
        address token
    ) internal returns (uint8) {
        (TOFUOutcome tofuOutcome, uint8 readDecimals) = decimalsForTokenImplementation(sTOFUTokenDecimals, token);
        if (tofuOutcome != TOFUOutcome.Consistent && tofuOutcome != TOFUOutcome.Initial) {
            revert TokenDecimalsReadFailure(token, tofuOutcome);
        }
        return readDecimals;
    }
}
