# Ghost Wallet
The proposal is to build a passwordless web3 authentication system which can take a yubikey hardware root of trust and allow access to your ether and tokens. This system means that you can then use the same hardware key you use to access all other services to interact with your ethereum systems.

## Architecture Plan:
The two major componets of the system will be (1) An ethereum smart contract identity manager which verifies NIST P-256 ECDSA signatures from the U2F FIDO standard and has a proxy fallback forwarding system to interact with other contracts. [Accomplished as of the most recent commit] (2) A web3 passwordless server which functions as a personal funding faucet.
The proposed user interaction pattern is that if a person is on a computer without access to their account they then can create a new account via metamask [or another service] and then use the passwordless web3 personal faucet to fund the new account enough to register it and send a few transactions, finally they use that funding to register with their identity contract and then the user has full access to their ghost wallet.

Resources:
https://fidoalliance.org/specs/fido-u2f-v1.2-ps-20170411/fido-u2f-raw-message-formats-v1.2-ps-20170411.html
http://www.secg.org/sec1-v2.pdf
ftp://ftp.iks-jena.de/mitarb/lutz/standards/ansi/X9/x963-7-5-98.pdf
"0xa41a41a12a799548211c410c65d8133afde34d28bdd542e4b680cf2899c8a8c4","0x2b42f576d07f4165ff65d1f3b1500f81e44c316f1f0b3ef57325b69aca46104f","0xdc42c2122d6392cd3e3a993a89502a8198c1886fe69d262c4b329bdb6b63faf1","0xb7e08afdfe94bad3f1dc8c734798ba1c62b3a0ad1e9ea2a38201cd0889bc7a19","0x3603f747959dbf7a4bb226e41928729063adc7ae43529e61b563bbc606cc5e09"
