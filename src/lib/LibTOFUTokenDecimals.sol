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
        ITOFUTokenDecimals(0x8b40CC241745D8eAB9396EDC12401Cfa1D5940c9);

    /// The expected code hash of the deployed TOFUTokenDecimals contract. This
    /// is used to verify that the contract at the expected address is indeed the
    /// correct contract, providing an additional layer of safety against
    /// misconfiguration or malicious interference.
    bytes32 constant TOFU_DECIMALS_EXPECTED_CODE_HASH =
        0x535e6c51d2ca2fe0bc29f8c0897fe88abe4ce78f7d522ff4b9f9272c26f27b1c;

    /// The expected creation code of the TOFUTokenDecimals contract. This is
    /// the init bytecode that, when deployed via the Zoltu factory, produces
    /// the contract at TOFU_DECIMALS_DEPLOYMENT with TOFU_DECIMALS_EXPECTED_CODE_HASH.
    // slither-disable-next-line too-many-digits
    bytes constant TOFU_DECIMALS_EXPECTED_CREATION_CODE =
        hex"6080604052348015600e575f80fd5b506104158061001c5f395ff3fe608060405234801561000f575f80fd5b506004361061003f575f3560e01c80630782d7e11461004357806354636d2b1461006d578063b7bad1b114610092575b5f80fd5b61005661005136600461032d565b6100a5565b6040516100649291906103cd565b60405180910390f35b61008061007b36600461032d565b6100ba565b60405160ff9091168152602001610064565b6100566100a036600461032d565b6100cb565b5f806100b15f846100d7565b91509150915091565b5f6100c55f836101c7565b92915050565b5f806100b15f84610258565b73ffffffffffffffffffffffffffffffffffffffff81165f9081526020838152604080832081518083019092525460ff8082161515835261010090910416818301527f313ce56700000000000000000000000000000000000000000000000000000000808452839283908190816004818a5afa915060203d1015610159575f91505b811561016f57505f5160ff81111561016f575f91505b8161018657505050602001516003925090506101c0565b835161019a575f955093506101c092505050565b836020015160ff1681146101af5760026101b2565b60015b846020015195509550505050505b9250929050565b5f805f6101d48585610258565b909250905060018260038111156101ed576101ed610367565b1415801561020c57505f82600381111561020957610209610367565b14155b156102505783826040517fee07877f0000000000000000000000000000000000000000000000000000000081526004016102479291906103eb565b60405180910390fd5b949350505050565b5f805f8061026686866100d7565b90925090505f82600381111561027e5761027e610367565b03610322576040805180820182526001815260ff838116602080840191825273ffffffffffffffffffffffffffffffffffffffff8a165f908152908b9052939093209151825493517fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00009094169015157fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00ff161761010093909116929092029190911790555b909590945092505050565b5f6020828403121561033d575f80fd5b813573ffffffffffffffffffffffffffffffffffffffff81168114610360575f80fd5b9392505050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52602160045260245ffd5b600481106103c9577f4e487b71000000000000000000000000000000000000000000000000000000005f52602160045260245ffd5b9052565b604081016103db8285610394565b60ff831660208301529392505050565b73ffffffffffffffffffffffffffffffffffffffff8316815260408101610360602083018461039456";

    /// Ensures that the TOFUTokenDecimals contract is deployed. Having an
    /// explicit guard prevents silent call failures and gives a clear error
    /// message for easier debugging.
    function ensureDeployed() internal view {
        if (
            address(TOFU_DECIMALS_DEPLOYMENT).code.length == 0
                || address(TOFU_DECIMALS_DEPLOYMENT).codehash != TOFU_DECIMALS_EXPECTED_CODE_HASH
        ) {
            revert TOFUTokenDecimalsNotDeployed(address(TOFU_DECIMALS_DEPLOYMENT));
        }
    }

    /// As per `ITOFUTokenDecimals.decimalsForTokenReadOnly`.
    function decimalsForTokenReadOnly(address token) internal view returns (TOFUOutcome, uint8) {
        ensureDeployed();
        // false positive in slither.
        // slither-disable-next-line unused-return
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForTokenReadOnly(token);
    }

    /// As per `ITOFUTokenDecimals.decimalsForToken`.
    function decimalsForToken(address token) internal returns (TOFUOutcome, uint8) {
        ensureDeployed();
        // false positive in slither.
        // slither-disable-next-line unused-return
        return TOFU_DECIMALS_DEPLOYMENT.decimalsForToken(token);
    }

    /// As per `ITOFUTokenDecimals.safeDecimalsForToken`.
    function safeDecimalsForToken(address token) internal returns (uint8) {
        ensureDeployed();
        return TOFU_DECIMALS_DEPLOYMENT.safeDecimalsForToken(token);
    }
}
