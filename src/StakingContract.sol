// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.10;

contract StakingContract {
    address public admin;

    struct Operator {
        address addr;
        string name;
        uint256 keys;
        uint256 funded;
        uint256 limit;
        uint256 limitSetTimestamp;
        mapping(uint256 => bytes) publicKeys;
        mapping(uint256 => bytes) signatures;
    }

    Operator[] public operators;

    error FundedValidatorDeletionAttempt();

    constructor(address _admin) {
        admin = _admin;
    }

    function addOperator(address _operator, string memory _name) public {
        require(msg.sender == admin, "Only admin");
        operators.push();
        Operator storage operatorInfo = operators[operators.length - 1];
        operatorInfo.addr = _operator;
        operatorInfo.name = _name;
    }

    function addValidators(uint256 _operatorIndex, uint256 _amount, bytes memory _publicKeys, bytes memory _signatures)
        public
    {
        Operator storage operatorInfo = operators[_operatorIndex];
        require(msg.sender == operatorInfo.addr, "Only operator");
        for (uint256 i = 0; i < _amount; i++) {
            operatorInfo.publicKeys[operatorInfo.keys + i] = new bytes(48);
            operatorInfo.signatures[operatorInfo.keys + i] = new bytes(96);
        }
        operatorInfo.keys += _amount;
    }

    function deposit() public payable {
        require(msg.value == 32 ether, "Must deposit 32 ETH");
        // In a real scenario, this would find the next unfunded validator
        // and fund it. For this PoC, we just increment the funded count.
        for (uint256 i = 0; i < operators.length; i++) {
            if (operators[i].funded < operators[i].keys) {
                operators[i].funded++;
                return;
            }
        }
    }

    function setOperatorLimit(uint256 _operatorIndex, uint256 _limit, uint256 _timestamp) public {
        require(msg.sender == admin, "Only admin");
        operators[_operatorIndex].limit = _limit;
        operators[_operatorIndex].limitSetTimestamp = _timestamp;
    }

    function removeValidators(uint256 _operatorIndex, uint256[] memory _indexes) public {
        Operator storage operatorInfo = operators[_operatorIndex];
        require(msg.sender == operatorInfo.addr, "Only operator");

        if (_indexes[_indexes.length - 1] < operatorInfo.funded) {
            revert FundedValidatorDeletionAttempt();
        }

        for (uint256 i = 0; i < _indexes.length; i++) {
            uint256 indexToRemove = _indexes[i];
            operatorInfo.publicKeys[indexToRemove] = operatorInfo.publicKeys[operatorInfo.keys - 1];
            delete operatorInfo.publicKeys[operatorInfo.keys - 1];
            operatorInfo.keys--;
        }
    }

    function getOperator(uint256 _operatorIndex)
        public
        view
        returns (address, string memory, uint256, uint256, uint256, uint256, uint256)
    {
        Operator storage operatorInfo = operators[_operatorIndex];
        return (
            operatorInfo.addr,
            operatorInfo.name,
            operatorInfo.keys,
            operatorInfo.funded,
            operatorInfo.limit,
            operatorInfo.limitSetTimestamp,
            0
        );
    }

    function getValidator(uint256 _operatorIndex, bytes memory _publicKey)
        public
        view
        returns (bytes memory, bytes memory)
    {
        Operator storage operatorInfo = operators[_operatorIndex];
        for (uint256 i = 0; i < operatorInfo.keys; i++) {
            // A simple byte comparison for the PoC
            if (keccak256(operatorInfo.publicKeys[i]) == keccak256(_publicKey)) {
                return (operatorInfo.publicKeys[i], operatorInfo.signatures[i]);
            }
        }
        revert("Validator not found");
    }

    function withdraw(bytes memory _publicKey) public {
        revert("Withdrawal failed - new message");
    }
}
