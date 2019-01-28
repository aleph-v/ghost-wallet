pragma solidity ^0.5.1;

import "./p256.sol";

contract idenity is p256Lib{

    mapping(address => bool) isOwner;
    uint256 public_qx; //The coordinates of the registered public key
    uint256 public_qy;
    bytes32[] validApplicationId;
    bytes4 counter; //We use bytes4 since FIDO UF2 uses big endian for its counter
    byte userPresance = 0x01;
    // Metatransactional varibles
    mapping(bytes32 => bool) used;
    bytes4 constant  REMOVE = bytes4(keccak256(abi.encodePacked("remove")));
    bytes4 constant  ADD = bytes4(keccak256(abi.encodePacked("add")));
    bytes4 constant  CALL = bytes4(keccak256(abi.encodePacked("call")));

    constructor(uint256 _public_qx, uint _public_qy, bytes32 applicationId, bytes4 _counter) public{
        public_qx = _public_qx;
        public_qy = _public_qy;
        validApplicationId.push(applicationId);
        counter = _counter;
    }

    //@Dev - The signature will be a NIST P-256 signature of the raw data signature from the U2F FIDO standard
    function hardwareRootAccess(bytes4 _counter, bytes32 applicationParam,  uint r, uint s) external {
        uint256 startGas = gasleft();
        require(uint32(_counter) > uint32(counter));
        require(isIn(validApplicationId, applicationParam));

        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        hash = sha256(abi.encodePacked(applicationParam, userPresance, _counter, hash));
        //Use sha256 since UF2 is a non-ethereum system

        require(verify(uint256(hash),r,s,public_qx, public_qy));
        isOwner[msg.sender] = true;
        uint gasUsed = startGas - gasleft();
        (msg.sender).transfer(gasUsed + 21000);
    }

    //@Dev- Proxy forwarding for the idenity
    function forward(address payable _to, bytes memory _calldata) public payable {
      require(isOwner[msg.sender]);
      (bool success, ) = _to.call.value(msg.value)(_calldata);
      require(success);
    }

    function forwardDelegated(address payable _to, bytes memory _calldata, bytes32 salt, uint fee, bytes memory signature) public payable {
      bytes32 hash =keccak256(abi.encodePacked(address(this), fee, CALL, salt, _to, _calldata));
      address sender = recover_spec256(hash, signature);
      require(isOwner[sender]);
      require(!used[hash]);

      (bool success, ) = _to.call.value(msg.value)(_calldata);
      require(success);
      used[hash] = true;
      (msg.sender).transfer(fee);
    }

    //@Dev - Add an account which can can access the idenity
    function addAccount(address _add) external{
      require(isOwner[msg.sender]);
      isOwner[_add] = true;
    }

    //@Dev - Remove an account which can access the idenity
    function removeAccount(address _remove) external{
      require(isOwner[msg.sender]);
      isOwner[_remove] = false;
    }

    //@Dev - Add an account which can can access the idenity, overloaded meta transactional method
    function addAccount(address _add, bytes32 salt, uint fee, bytes calldata signature) external{
      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, ADD, salt, _add, salt));
      address signer = recover_spec256(hash, signature);
      require(isOwner[signer]);
      require(!used[hash]);

      isOwner[_add] = true;
      used[hash] = true;
      (msg.sender).transfer(fee);
    }

    //@Dev - Remove an account which can access the idenity, overloaded metatransactional method
    function removeAccount(address _remove, bytes32 salt, uint fee, bytes calldata signature) external{
      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, REMOVE, salt, _remove, salt));
      address signer = recover_spec256(hash, signature);
      require(isOwner[signer]);
      require(!used[hash]);

      isOwner[_remove] = false;
      used[hash] = true;
      (msg.sender).transfer(fee);
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

    //@Dev - Unsorted array search, note that this array should never hold more than 5 elements
    function isIn(bytes32[] memory array, bytes32 question) internal pure returns(bool){
        for(uint i =0 ; i < array.length; i++){
            if(array[i] == question){
                return(true);
            }
        }
        return(false);
    }

    //@Dev - Signature Recovery
    uint256 constant N  = 115792089210356248762697446949407573529996955224135760342422259061068512044369;
    //This is the curve order for spec256k

    function recover_spec256(bytes32 hash, bytes memory sig) internal pure returns(address){
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) return address(0);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        if (v < 27) {
          v += 27;
        }

        if (v != 27 && v != 28) return address(0);

        require(uint(s) < N/2); //We define that the lower s version of the signature is the valid one

        return ecrecover(hash, v, r, s);
    }
}
