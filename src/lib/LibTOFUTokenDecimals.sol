// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {TOFUOutcome, ITOFUTokenDecimals} from "../interface/ITOFUTokenDecimals.sol";

/// @title LibTOFUTokenDecimals
/// @notice Library for reading and storing token decimals with a trust on first use
/// (TOFU) approach. This is used to read the decimals of ERC20 tokens and store
/// them for future use, under the assumption that the decimals will not change
/// after the first read. As this involves storing the decimals, which is a state
/// change, there is a read-only version of the logic to simply check that
/// decimals are either uninitialized or consistent, without storing anything.
/// The caller is responsible for ensuring that read/write and read-only versions
/// are used appropriately for their use case without introducing inconsistency.
///
/// This library is for the caller to use the deployed TOFUTokenDecimals contract
/// externally with the convenience of an internal function interface to the lib.
/// Essentially it removes the need for callers to be aware of or deal with the
/// zoltu deployments directly.
library LibTOFUTokenDecimals {
    /// @notice Thrown when the singleton is not deployed or has an unexpected codehash.
    /// @param deployedAddress The address that was expected to have the singleton.
    error TOFUTokenDecimalsNotDeployed(address deployedAddress);

    /// @notice The deployed TOFUTokenDecimals contract address. The deploy
    /// script uses Zoltu for deterministic deployments so this address is fixed
    /// across all supported networks.
    ITOFUTokenDecimals constant TOFU_DECIMALS_DEPLOYMENT =
        ITOFUTokenDecimals(0x200e12D10bb0c5E4a17e7018f0F1161919bb9389);

    /// @notice The expected code hash of the deployed TOFUTokenDecimals
    /// contract. Used to verify that the contract at the expected address is
    /// indeed the correct contract, providing an additional layer of safety
    /// against misconfiguration or malicious interference.
    bytes32 constant TOFU_DECIMALS_EXPECTED_CODE_HASH =
        0x1de7d717526cba131d684e312dedbf0852adef9cced9e36798ae4937f7145d41;

    /// @notice The expected creation code of the TOFUTokenDecimals contract.
    /// This is the init bytecode that, when deployed via the Zoltu factory,
    /// produces the contract at TOFU_DECIMALS_DEPLOYMENT with
    /// TOFU_DECIMALS_EXPECTED_CODE_HASH.
    // slither-disable-next-line too-many-digits
    bytes constant TOFU_DECIMALS_EXPECTED_CREATION_CODE =
        hex"6080604052348015600e575f80fd5b5061044b8061001c5f395ff3fe608060405234801561000f575f80fd5b506004361061004a575f3560e01c80630782d7e11461004e57806354636d2b14610078578063b7bad1b11461009d578063f5c36eaf146100b0575b5f80fd5b61006161005c366004610363565b6100c3565b60405161006f929190610403565b60405180910390f35b61008b610086366004610363565b6100d8565b60405160ff909116815260200161006f565b6100616100ab366004610363565b6100e9565b61008b6100be366004610363565b6100f5565b5f806100cf5f84610100565b91509150915091565b5f6100e35f836101f0565b92915050565b5f806100cf5f84610281565b5f6100e35f83610356565b73ffffffffffffffffffffffffffffffffffffffff81165f9081526020838152604080832081518083019092525460ff8082161515835261010090910416818301527f313ce56700000000000000000000000000000000000000000000000000000000808452839283908190816004818a5afa915060203d1015610182575f91505b811561019857505f5160ff811115610198575f91505b816101af57505050602001516003925090506101e9565b83516101c3575f955093506101e992505050565b836020015160ff1681146101d85760026101db565b60015b846020015195509550505050505b9250929050565b5f805f6101fd8585610281565b909250905060018260038111156102165761021661039d565b1415801561023557505f8260038111156102325761023261039d565b14155b156102795783826040517fee07877f000000000000000000000000000000000000000000000000000000008152600401610270929190610421565b60405180910390fd5b949350505050565b5f805f8061028f8686610100565b90925090505f8260038111156102a7576102a761039d565b0361034b576040805180820182526001815260ff838116602080840191825273ffffffffffffffffffffffffffffffffffffffff8a165f908152908b9052939093209151825493517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00009094169015157fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ff161761010093909116929092029190911790555b909590945092505050565b5f805f6101fd8585610100565b5f60208284031215610373575f80fd5b813573ffffffffffffffffffffffffffffffffffffffff81168114610396575f80fd5b9392505050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52602160045260245ffd5b600481106103ff577f4e487b71000000000000000000000000000000000000000000000000000000005f52602160045260245ffd5b9052565b6040810161041182856103ca565b60ff831660208301529392505050565b73ffffffffffffffffffffffffffffffffffffffff831681526040810161039660208301846103ca56";

    /// @notice Ensures that the TOFUTokenDecimals contract is deployed. Having
    /// an explicit guard prevents silent call failures and gives a clear error
    /// message for easier debugging.
    function ensureDeployed() internal view {
        if (
            address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0
                || address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH
        ) {
            revert TOFUTokenDecimalsNotDeployed(address(TOFU_DECIMALS_DEPLOYMENT));
        }
    }

    /// @notice As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`.
    /// @param token The token to read the decimals for.
    /// @return tofuOutcome The outcome of the TOFU read.
    /// @return tokenDecimals The token's decimals. On `Initial`, the freshly
    /// read value. On `Consistent` or `Inconsistent`, the previously stored
    /// value. On `ReadFailure`, the stored value (zero if uninitialized).
    function decimalsForTokenReadOnly(address token) internal view returns (TOFUOutcome, uint8) {
        ensureDeployed();
        // false positive in slither.
        // slither-disable-next-line unused-return
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token);
    }

    /// @notice As per `ITOFUTokenDecimals.decimalsForToken`.
    /// @param token The token to read the decimals for.
    /// @return tofuOutcome The outcome of the TOFU read.
    /// @return tokenDecimals The token's decimals. On `Initial`, the freshly
    /// read value. On `Consistent` or `Inconsistent`, the previously stored
    /// value. On `ReadFailure`, the stored value (zero if uninitialized).
    function decimalsForToken(address token) internal returns (TOFUOutcome, uint8) {
        ensureDeployed();
        // false positive in slither.
        // slither-disable-next-line unused-return
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token);
    }

    /// @notice As per `ITOFUTokenDecimals.safeDecimalsForToken`.
    /// @param token The token to read the decimals for.
    /// @return tokenDecimals The token's decimals.
    function safeDecimalsForToken(address token) internal returns (uint8) {
        ensureDeployed();
        return TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForToken(token);
    }

    /// @notice As per `ITOFUTokenDecimals.safeDecimalsForTokenReadOnly`.
    /// @param token The token to read the decimals for.
    /// @return tokenDecimals The token's decimals.
    function safeDecimalsForTokenReadOnly(address token) internal view returns (uint8) {
        ensureDeployed();
        return TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForTokenReadOnly(token);
    }
}
