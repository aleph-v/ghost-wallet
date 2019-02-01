pragma solidity ^0.5.1;

import "./p256.sol";

//@Dev - This contract when deployed creates an idenity which regards any device capable of generating UF2 tokens as the holder of the idenity
//@Dev - It allows yubi keys, some models of cell phone, and other devices to sign transactions and grant access to the identity to ethereum accounts
//@Dev - Moreover it implements a full metatransactionl system which allows any ethereum account validated for this idenity to produce a signed message which when delateged to this account will produce a call from the identity
//@Dev - Since the meta transactional call is generic this contract can natively hold all forms of token and preform any action an ethereum account can preform [except with those contracts which spesificaly do not allow contract interaction]
//@Dev - It allows timestamping of ethereum address so that they expire [like access tokens to web2 websites]
//@Dev - To enable a network of senders to not worry about front running it also allows locking of metatransactionl methods to a fufiller address until the lock expires


contract idenity is p256Lib{

    mapping(address => bool) public isOwner;
    uint256 public public_qx; //The coordinates of the registered public key
    uint256 public public_qy;
    bytes32[] public validApplicationId;
    bytes4 public counter; //We use bytes4 since FIDO UF2 uses big endian for its counter
    byte constant public userPresance = 0x01;
    mapping(address => uint) public timelock; // Contains the experation time of an address, set to zero for no experation

    // Metatransactional varibles
    mapping(bytes32 => bool) used; //Mapping of burned hashes
    //Each of these constants will procceed the signed meta transactions [To lock them to the function they should be used on]
    bytes4 constant  REMOVE = bytes4(keccak256(abi.encodePacked("remove")));
    bytes4 constant  LOCKED_REMOVE = bytes4(keccak256(abi.encodePacked("locked_remove")));
    bytes4 constant  ADD = bytes4(keccak256(abi.encodePacked("add")));
    bytes4 constant  LOCKED_ADD = bytes4(keccak256(abi.encodePacked("locked_add")));
    bytes4 constant  CALL = bytes4(keccak256(abi.encodePacked("call")));
    bytes4 constant  LOCKED_CALL = bytes4(keccak256(abi.encodePacked("locked_call")));
    bytes4 constant  NEW = bytes4(keccak256(abi.encodePacked("new")));
    bytes4 constant  LOCKED_NEW = bytes4(keccak256(abi.encodePacked("locked_new")));
    bytes4 constant  ONETIME = bytes4(keccak256(abi.encodePacked("onetime")));
    bytes4 constant  LOCKED_ONETIME = bytes4(keccak256(abi.encodePacked("locked_onetime")));

    constructor(uint256 _public_qx, uint _public_qy, bytes32 applicationId, bytes4 _counter) public{
        public_qx = _public_qx;
        public_qy = _public_qy;
        validApplicationId.push(applicationId);
        counter = _counter;
        isOwner[msg.sender] = true; //We will assume that the person constructing the identity is the user, a purely meta transactional model may not do this
    }

    //@Dev - The signature will be a NIST P-256 signature of the raw data signature from the U2F FIDO standard
    function hardwareRootAccess(bytes4 _counter, bytes32 applicationParam,  uint r, uint s, uint fee, address newOwner, uint timestamp) external {
        require(uint32(_counter) > uint32(counter));
        require(isIn(validApplicationId, applicationParam));

        bytes32 hash = keccak256(abi.encodePacked(address(this), NEW, newOwner, timestamp, fee));
        hash = sha256(uf2Packed(applicationParam, userPresance, _counter, hash)); //TODO check against UF2 packing
        //Use sha256 since UF2 doesn't have keccak256 as an option

        require(verify(uint256(hash),r,s,public_qx, public_qy)); //Use the p256 library to check the spec256r/NIST 256 sig
        isOwner[newOwner] = true; //Add the new owner
        counter = _counter; //Update the record of the hardware counter
        timelock[newOwner] = timestamp; //Set the experiation time requested

        (msg.sender).transfer(fee); //Transfer gas repayment to sender
    }

    //@Dev - This version of hardware root access is locked to a single fulfiller until time 'lockExpire'
    function hardwareRootAccess(bytes4 _counter, bytes32 applicationParam,  uint r, uint s, uint fee, address newOwner, uint timestamp, address fufiller, uint lockExpire) external {
        require((msg.sender == fufiller) || (now > lockExpire));

        require(uint32(_counter) > uint32(counter));
        require(isIn(validApplicationId, applicationParam));

        bytes32 hash = keccak256(abi.encodePacked(address(this), LOCKED_NEW, fufiller, lockExpire, newOwner, timestamp, fee));
        hash = sha256(uf2Packed(applicationParam, userPresance, _counter, hash)); //TODO check against UF2 packing
        //Use sha256 since UF2 doesn't have keccak256 as an option

        require(verify(uint256(hash),r,s,public_qx, public_qy)); //Use the p256 library to check the spec256r/NIST 256 sig
        isOwner[newOwner] = true; //Add the new owner
        counter = _counter; //Update the record of the hardware counter
        timelock[newOwner] = timestamp; //Set the experiation time requested

        (msg.sender).transfer(fee); //Transfer gas repayment to sender
    }

    //@Dev - This function allows the creation of a one time transaction via UF2 token, instead of authorizing an address [Note because spec256r is non native this will be much more expensive for multiple transactions from an address]
    function oneTimeCall(address payable _to, uint _value, bytes calldata _calldata, uint fee, bytes4 _counter, bytes32 applicationParam,  uint r, uint s) external returns(bool){
      require(uint32(_counter) > uint32(counter));
      require(isIn(validApplicationId, applicationParam));

      bytes32 hash = keccak256(abi.encodePacked(address(this), ONETIME, _value, _to, fee, _calldata));
      hash = sha256(uf2Packed(applicationParam, userPresance, _counter, hash)); //TODO check against UF2 packing
      //Use sha256 since UF2 doesn't have keccak256 as an option

      require(verify(uint256(hash),r,s,public_qx, public_qy)); //Use the p256 library to check the spec256r/NIST 256 sig

      counter = _counter;
      (bool success, ) = _to.call.value(_value)(_calldata); //Attempts the call requested

      (msg.sender).transfer(fee); //Transfer gas repayment to sender
      return(success);
    }

    //@Dev - Extension of one time call locked to a single fufiller until time 'lockExpires'
    function oneTimeCall(address payable _to, uint _value, bytes calldata _calldata, uint fee, bytes4 _counter, bytes32 applicationParam,  uint r, uint s, address fufiller, uint lockExpire) external returns(bool){
      require((msg.sender == fufiller) || (now > lockExpire));
      require(uint32(_counter) > uint32(counter));
      counter = _counter;
      require(isIn(validApplicationId, applicationParam));

      if(oneTimeHashLock(fufiller, lockExpire, _value, _to, fee, _calldata, r, s, applicationParam)){

        counter = _counter;
        (bool success, ) = _to.call.value(_value)(_calldata); //Attempts the call requested

        (msg.sender).transfer(fee); //Transfer gas repayment to sender
        return(success);
      } else{
          revert();
      }
    }
    //@Dev - This internal function helps avoid stack errors
    function oneTimeHashLock(address _fufiller, uint _lockExpire, uint _value, address _to, uint _fee, bytes memory _calldata, uint r, uint s, bytes32 applicationParam) internal returns(bool){
        bytes32 hash = keccak256(abi.encodePacked(address(this), LOCKED_ONETIME, _value, _fufiller, _lockExpire, _to, _fee, _calldata));
        hash = sha256(uf2Packed(applicationParam, userPresance, counter, hash)); //TODO check against UF2 packing
        //Use sha256 since UF2 doesn't have keccak256 as an option

       return(verify(uint256(hash),r,s,public_qx, public_qy)); //Use the p256 library to check the spec256r/NIST 256 sig
    }

    //@Dev- Proxy forwarding for the idenity
    function forward(address payable _to, uint _value, bytes memory _calldata) public payable returns(bool) {
      require(checkOwnership(msg.sender)); //Checks that the sender is a valid owner
      (bool success, ) = _to.call.value(_value)(_calldata); //Attempts the call requested
      require(success); // Checks that the data is valid
    }

    //@Overload the meta transactional forward method
    function forward(address payable _to, uint _value, bytes memory _calldata, bytes32 salt, uint fee, bytes memory signature) public payable returns(bool) {
      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, CALL, salt, _value, _to, _calldata)); //Calculates the hash to be signed
      address sender = recover_spec256(hash, signature); //Calls the ethereum version of the recover library
      require(checkOwnership(sender));// Checks that the signer is the owner
      require(!used[hash]); // Checks that the hash hasn't been burnt

      (bool success, ) = _to.call.value(_value)(_calldata); //Calls the _to with the value and call data inputed
      used[hash] = true; //Burns the hash
      (msg.sender).transfer(fee); // Sends the fee
      return(success); // Returns whether or not the call is successful
    }

    //@Overload the meta transactional forward method, with locking for fulfiller address [avoiding race conditions]
    function forward(address payable _to, uint _value, bytes memory _calldata, bytes32 salt, uint fee, bytes memory signature, address fufiller, uint lockExpire) public payable returns(bool) {
      require((msg.sender == fufiller) || (now > lockExpire));

      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, LOCKED_CALL, salt, fufiller, lockExpire, _to, _value, _calldata)); //Calculates the hash to be signed
      address sender = recover_spec256(hash, signature); //Calls the ethereum version of the recover library
      require(checkOwnership(sender));// Checks that the signer is the owner
      require(!used[hash]); // Checks that the hash hasn't been burnt

      (bool success, ) = _to.call.value(_value)(_calldata); //Calls the _to with the value and call data inputed
      used[hash] = true; //Burns the hash
      (msg.sender).transfer(fee); // Sends the fee
      return(success); // Returns whether or not the call is successful
    }

    //@Dev - Add an account which can can access the idenity
    function addAccount(address _add, uint timestamp) external{
      require(checkOwnership(msg.sender));
      timelock[_add] = timestamp;
      isOwner[_add] = true;
    }

    //@Dev - Remove an account which can access the idenity
    function removeAccount(address _remove) external{
      require(checkOwnership(msg.sender));
      isOwner[_remove] = false;
    }

    //@Dev - Add an account which can can access the idenity, overloaded meta transactional method
    function addAccount(address _add, uint timestamp, bytes32 salt, uint fee, bytes calldata signature) external{
      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, ADD, salt, _add, timestamp)); //Hashes the needed data for the transaciton
      address signer = recover_spec256(hash, signature); //Uses the ethereum address recovery method
      require(checkOwnership(signer)); //Checks the ownership
      require(!used[hash]); //Checks that the hash hasn't been used

      isOwner[_add] = true; //Add the owner
      timelock[_add] = timestamp; // Adds the expiration date for this address
      used[hash] = true; //Burns the hash
      (msg.sender).transfer(fee); //Sends the fee to the person who completed the meta transaction
    }

    //@Dev - Add an account which can can access the idenity, overloaded meta transactional method and locked to one fufiller till time 'lockExpire'
    function addAccount(address _add, uint timestamp, bytes32 salt, uint fee, bytes calldata signature, address fufiller, uint lockExpire) external{
      require((msg.sender == fufiller) || (now > lockExpire));

      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, LOCKED_ADD, salt, fufiller, lockExpire, _add, timestamp)); //Hashes the needed data for the transaciton
      address signer = recover_spec256(hash, signature); //Uses the ethereum address recovery method
      require(checkOwnership(signer)); //Checks the ownership
      require(!used[hash]); //Checks that the hash hasn't been used

      isOwner[_add] = true; //Add the owner
      timelock[_add] = timestamp; // Adds the expiration date for this address
      used[hash] = true; //Burns the hash
      (msg.sender).transfer(fee); //Sends the fee to the person who completed the meta transaction
    }

    //@Dev - Remove an account which can access the idenity, overloaded metatransactional method
    function removeAccount(address _remove, bytes32 salt, uint fee, bytes calldata signature) external{
      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, REMOVE, salt, _remove)); //Hahses the needed data
      address signer = recover_spec256(hash, signature); //Uses the ethereum method to check who signed
      require(checkOwnership(signer)); //Checks that the signer is the owner
      require(!used[hash]);

      isOwner[_remove] = false; //Removes the owner
      used[hash] = true; //Burns the hash
      (msg.sender).transfer(fee); //Gives the implementor thier fee
    }

    //@Dev - Remove an account which can access the idenity, overloaded metatransactional method which is locked to a single fufiller till time 'lockExpire'
    function removeAccount(address _remove, bytes32 salt, uint fee, bytes calldata signature, address fufiller, uint lockExpire) external{
      require((msg.sender == fufiller) || (now > lockExpire));

      bytes32 hash = keccak256(abi.encodePacked(address(this), fee, LOCKED_REMOVE, fufiller, lockExpire, salt, _remove)); //Hahses the needed data
      address signer = recover_spec256(hash, signature); //Uses the ethereum method to check who signed
      require(checkOwnership(signer)); //Checks that the signer is the owner
      require(!used[hash]);

      isOwner[_remove] = false; //Removes the owner
      used[hash] = true; //Burns the hash
      (msg.sender).transfer(fee); //Gives the implementor thier fee
    }

    //@Dev - Add an applicationParam
    function addAppParam(bytes32 applicationParam) external {
        require(checkOwnership(msg.sender));
        validApplicationId.push(applicationParam);
    }

    //@Dev - Remove an applicationParam
    function removeAppParam(bytes32 applicationParam) external {
        require(checkOwnership(msg.sender));
        for(uint i =0 ; i < validApplicationId.length; i++){
            if(validApplicationId[i] == applicationParam){
                delete validApplicationId[i];
            }
        }
    }

    //@Dev - Allows contracts to check if from is in the same idenity as owner
    function checkAddress(address _owner) external view{
        require(checkOwnership(_owner));
    }

    //@Dev - Unsorted array search, note that this array should never hold more than 5 elements
    function isIn(bytes32[] memory array, bytes32 question) private pure returns(bool){
        for(uint i =0 ; i < array.length; i++){
            if(array[i] == question){
                return(true);
            }
        }
        return(false);
    }

    function uf2Packed(bytes32 _applicationParam, byte _userPresance, bytes4 _counter, bytes32 _hash) private pure returns(bytes memory _b){
        assembly{
            mstore(_b, 0x45)
            mstore(add(_b,0x20), _applicationParam)
            mstore(add(_b, 0x40), _userPresance)
            mstore(add(_b,0x41), _counter)
            mstore(add(_b,0x45), _hash)
        }
    }

    function checkOwnership(address proposed) private view returns(bool){
      return (isOwner[proposed])&&(timelock[proposed] > now || timelock[proposed] == 0);
    }

    //@Dev - Signature Recovery
    uint256 constant N  = 115792089210356248762697446949407573529996955224135760342422259061068512044369;
    //This is the curve order for spec256k

    function recover_spec256(bytes32 hash, bytes memory sig) private pure returns(address){
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
