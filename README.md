# CineX-project
 This is a decentralized crowdfunding platform for indie filmmakers. It holds the following modules for managing issues within the app:

## Features/management modules
- CineX-project: 
   Main Entry Point or Hub for all of CineX's modules (crowdfunding, rewards, escrow) of the CineX film crowdfunding platform
 => Acts as the center hub for the CineX platform.
 => Manages administrators.
 => Links the crowdfunding, rewards, and escrow modules dynamically (can upgrade them if needed).
;; => Provides read-only access to platform stats (module addresses)

- CineX-rewards-sip09:
  The SIP09 SIP-09 compliant NFT contract for the CineX platform's reward system

- Crowdfunding-module:
  => Manages the funding camapaign processes
- Escrow module:
  => Takes care of secure fund management of campaign funds

- Rewards-module:
 => acts like a "Reward Manager" 
    => collecting minting fees, 
    => ensuring only the right people can give rewards, recording who earned what, 
    => and organizing mass (batch) reward distribution; the actual NFT minting is done separately by the NFT contract.

 ### Traits
 To keep a consistent definition of functions in the modules, the CineX-project also possesses traits that were defined 
 and used/implemented within the different modules, and as much as possible were hardcoded in such way to avoid circular dependency

 They include: crowdfunding-module-traits; escrow-module-trait; rewards-module-trait; rewards-nft-trait (this defines the traits 
 for batch minting of rewards, since the standard sip-09 contract does not define a mint function.

 
