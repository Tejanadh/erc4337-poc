// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "account-abstraction/contracts/interfaces/IPaymaster.sol";
import "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract VulnerablePaymaster is IPaymaster {
    uint256 public s_slot;

    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        return ("I am a context", 0);
    }

    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external override {
        for (uint i = 0; i < 100; i++) {
            s_slot = i;
        }
    }
}
