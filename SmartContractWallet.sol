// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
* NOTE:
* 
*/

contract Consumer {

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SmartContractWallet {
    
    address payable public owner;
    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;

    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint guardiansResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3; //The guardian need 3 votes to be the new owner

    constructor() {
        owner = payable(msg.sender);
    }

    function setGuardian(address _guardian, bool _isGuardian) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        guardians[_guardian] = _isGuardian;
    }

    function proposeNewOwner(address payable _newOwner) public {
        require(guardians[msg.sender], "You are not guardian of this wallet, aborting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "You already voted, aborting");

        if(_newOwner != nextOwner) {
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    function setAllowance(address _for, uint _amount) public { 
        require(msg.sender == owner, "You are not the owner, aborting");
        allowance[_for] = _amount;

        if(_amount > 0) {
            isAllowedToSend[_for] = true;
        }else {
            isAllowedToSend[_for] = false;
        }
    }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory) {
        require(msg.sender == owner, "You are not the owner, aborting");

        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Aborting call was not successfull");
        return returnData;
    }
}