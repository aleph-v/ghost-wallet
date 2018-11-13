# Ghost Wallet
The proposal is to build a passwordless web3 authentication system which can take a yubikey hardware root of trust and allow access to your ether and tokens. This system means that you can then use the same hardware key you use to access all other services to interact with your ethereum systems.

## Architecture Plan:
The two major componets of the system will be (1) An ethereum smart contract identity manager which verifies PGP signatures and has a proxy fallback forwarding system to interact with other contracts. (2) A web3 passwordless server which functions as a personal funding faucet.
The proposed user interaction pattern is that if a person is on a computer without access to their account they then can create a new account via metamask [or another service] and then use the passwordless web3 personal faucet to fund the new account enough to register it and send a few transactions, finally they use that funding to register with their identity contract and then the user has full access to their ghost wallet.
