// ExampleTest.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract ExampleTest is Test {
    function testAddition() public {
        assertEq(1 + 1, 2);
    }
}
