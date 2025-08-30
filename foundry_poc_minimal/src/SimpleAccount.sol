// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "account-abstraction/contracts/interfaces/IAccount.sol";
import "account-abstraction/contracts/interfaces/UserOperation.sol";

contract SimpleAccount is IAccount {
    IEntryPoint public immutable entryPoint;
    uint256 public nonce;

    constructor(address _entryPoint) {
        entryPoint = IEntryPoint(_entryPoint);
    }

    function getNonce() public view returns (uint256) {
        return nonce;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        // This is a simplified validation that doesn't check signatures
        nonce++;
        return 0;
    }
}
