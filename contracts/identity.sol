pragma solidity ^0.4.25;

import "./BigNum.sol";

contract idenity{
    using BigNumber for *;

    mapping(address => bool) isOwner;
    instance publicExponent;
    instance modulus;

    constructor(bytes _exponet, uint _exponetLength, bytes _modulus, uint _modulusLegth) public{
      publicExponent = _exponet._new(false, _exponetLength);
      modulus = _modulus._new(false, _modulusLength);
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
    //@Dev - The signature should be the RSA [openPGP/other] signature of the keccak256 hash of the address to be given access
    function hardwareRootAccess(bytes32 _pubHash, bytes _sig, uint _sigBitlen) external view{
      instance memory signature = _sig._new(false, _sigBitlen);
      instance memory result = signature.prepare_modexp(exponet, modulus);
       
    }

    function forward(address _to, bytes _calldata) public payable {
      require(isOwner[msg.sender]);
      require(_to.call.value(msg.value)(_calldata));
    }
}
