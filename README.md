# Ghost Wallet
The proposal is to build a passwordless web3 authentication system which can take a yubikey hardware root of trust and allow access to your ether and tokens. This system means that you can then use the same hardware key you use to access all other services to interact with your ethereum systems.

## Architecture Plan:
I have decided to pivot the system to using meta transactions for the identity calls. This will avoid a large amount of headache around how an approved account can access the identity without ethereum to make transactions to prove itself. As of now the system will be (1) An on chain component which accepts FIDO UF2 tokens signed by NIST-P256 /SPEC256r to add addresses to a list of valid addresses for an identity. This component will also expose meta-transactional methods which pay fees to persons who forward signed messages from approved accounts for the identity. Together these components will allow a user to manage a onchain identity with a yubi key being the primary method of access. (2) An offchain js site which will allow calculation of the the needed UF2 token which can be submitted through a normal transaction
Long term for many users this project will need a network/protocol to fulfill meta-transactional requests from a wide audience.


Resources:
https://fidoalliance.org/specs/fido-u2f-v1.2-ps-20170411/fido-u2f-raw-message-formats-v1.2-ps-20170411.html
http://www.secg.org/sec1-v2.pdf
ftp://ftp.iks-jena.de/mitarb/lutz/standards/ansi/X9/x963-7-5-98.pdf
Example UF2 Token:
"0xa41a41a12a799548211c410c65d8133afde34d28bdd542e4b680cf2899c8a8c4","0x2b42f576d07f4165ff65d1f3b1500f81e44c316f1f0b3ef57325b69aca46104f","0xdc42c2122d6392cd3e3a993a89502a8198c1886fe69d262c4b329bdb6b63faf1","0xb7e08afdfe94bad3f1dc8c734798ba1c62b3a0ad1e9ea2a38201cd0889bc7a19","0x3603f747959dbf7a4bb226e41928729063adc7ae43529e61b563bbc606cc5e09"    
