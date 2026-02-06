// SPDX-License-Identifier: LicenseRef-DCL-1.0
// SPDX-FileCopyrightText: Copyright (c) 2020 Rain Open Source Software Ltd
pragma solidity =0.8.25;

import {
    LibTOFUTokenDecimalsImplementation,
    TOFUOutcome,
    TOFUTokenDecimalsResult
} from "src/lib/LibTOFUTokenDecimalsImplementation.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

contract LibTOFUTokenDecimalsImplementationTest is Test {
    function testDecimalsSelector() external pure {
        assertEq(LibTOFUTokenDecimalsImplementation.TOFU_DECIMALS_SELECTOR, IERC20.decimals.selector);
    }
}
