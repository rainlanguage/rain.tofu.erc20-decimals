// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity ^0.8.25;

import {TOFUTokenDecimals} from "../concrete/TOFUTokenDecimals.sol";

library LibTOFUTokenDecimalsDeploy {
    function deployZoltu() internal returns (address deployedAddress) {
        //slither-disable-next-line too-many-digits
        bytes memory code = type(TOFUTokenDecimals).creationCode;
        bool success;
        assembly ("memory-safe") {
            mstore(0, 0)
            success := call(gas(), 0x7A0D94F55792C434d74a40883C6ed8545E406D12, 0, add(code, 0x20), mload(code), 12, 20)
            deployedAddress := mload(0)
        }
        if (!success) {
            revert("DecimalFloat: deploy failed");
        }
    }
}
