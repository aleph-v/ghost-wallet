pragma solidity ^0.4.24;

import "./p256.sol";

contract idenity is p256Lib{

    mapping(address => bool) isOwner;
    uint256 public_qx; //The coordinates of the registered public key
    uint256 public_qy;
    bytes32[] validApplicationId;
    bytes4 counter; //We use bytes4 since FIDO UF2 uses big endian for its counter
    byte userPresance = 0x01;

    constructor(uint256 _public_qx, uint _public_qy, bytes32 applicationId, bytes4 _counter) public{
        public_qx = _public_qx;
        public_qy = _public_qy;
        validApplicationId.push(applicationId);
        counter = _counter;
    }

    //@Dev - The signature will be a NIST P-256 signature of the raw data signature from the U2F FIDO standard
    function hardwareRootAccess(bytes4 _counter, bytes32 applicationParam,  uint r, uint s) external {
        require(uint32(_counter) > uint32(counter));
        require(isIn(validApplicationId, applicationParam));

        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        hash = sha256(abi.encodePacked(applicationParam, userPresance, _counter, hash));
        //Use sha256 since UF2 is a non-ethereum system

        require(verify(uint256(hash),r,s,public_qx, public_qy));
        isOwner[msg.sender] = true;
    }

    //@Dev- Proxy forwarding for the idenity
    function forward(address _to, bytes _calldata) public payable {
      require(isOwner[msg.sender]);
      require(_to.call.value(msg.value)(_calldata));
    }

    //@Dev - Add an account which can can access the idenity
    function addAccount(address _add) external{
      require(isOwner[msg.sender]);
      isOwner[_add] = true;
    }

    //@Dev - Add an applicationParam
    function addAppParam(bytes32 applicationParam) external {
        require(isOwner[msg.sender]);
        validApplicationId.push(applicationParam);
    }

    //@Dev - Remove an applicationParam
    function removeAppParam(bytes32 applicationParam) external {
        require(isOwner[msg.sender]);
        for(uint i =0 ; i < validApplicationId.length; i++){
            if(validApplicationId[i] == applicationParam){
                delete validApplicationId[i];
            }
        }
    }

    //@Dev - Allows contracts to check if from is in the same idenity as owner
    function checkAddress(address _owner) external view{
        require(isOwner[_owner]);
    }

    function getChallange(address proposed) external pure returns(bytes32){
        return(keccak256(abi.encodePacked(proposed)));
    }

    //@Dev - Unsorted array search
    function isIn(bytes32[] memory array, bytes32 question) internal pure returns(bool){
        for(uint i =0 ; i < array.length; i++){
            if(array[i] == question){
                return(true);
            }
        }
        return(false);
    }
}
