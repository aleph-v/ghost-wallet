pragma solidity ^0.4.25;

import "./p256.sol";

contract idenity is p256Lib{

    mapping(address => bool) isOwner;
    bytes ownerKey;

    constructor(bytes _ownerKey) public{
      ownerKey = _ownerKey;
    }

    //@Dev - Add an account which can can access the idenity
    function addAccount(address _add) external{
      require(isOwner[msg.sender]);
      isOwner[_add] = true;
    }

    //@Dev - Allows contracts to check if from is in the same idenity as owner
    function verify(address _owner) external view{
        require(isOwner[_owner]);
    }
    //@Dev - The signature will be a NIST P-256 signature of the raw data signature from the U2F FIDO standard
    function hardwareRootAccess(uint32 _counter, bytes _sig) external view{

       
    }

    function forward(address _to, bytes _calldata) public payable {
      require(isOwner[msg.sender]);
      require(_to.call.value(msg.value)(_calldata));
    }
}
