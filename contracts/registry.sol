pragma solidity ^0.5.1;

//@Dev - This contract can be centrally deployed as a backend database to allow a user to figure out which smart contract identity is thiers
//@Dev - The intended use patern is that when the user regisers with the site they call to reserve thier username and label the identity it is attached too
//@Dev - Then if they need to register a new computer or make a one time call they can enter thier user name into the site and pull up the list of thier identies to format a call to the correct one

contract registry {
  mapping(bytes32 => address[]) public whoIs;

  function register(string calldata username, address identity) external {
    require(whoIs[keccak256(abi.encodePacked(username))].length == 0);
    whoIs[keccak256(abi.encodePacked(username))].push(identity);
  }
  function addIdentity(string calldata username, address _new) external{
    require(isOwner(username, msg.sender));
    whoIs[keccak256(abi.encodePacked(username))].push(_new);
  }
  function isOwner(string memory username, address proposed) public view returns(bool) {
    uint len = whoIs[keccak256(abi.encodePacked(username))].length;
    for(uint i=0; i < len; i++){
      if(whoIs[keccak256(abi.encodePacked(username))][i] == proposed){
        return true;
      }
    }
    return false;
  }
}
