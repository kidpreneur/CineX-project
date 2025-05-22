;; title: CineX 
;; version: 1.0.0 
;; ========== Summary ==========
;;  Main Entry Point for all modules (crowdfunding, rewards, escrow) of the CineX film crowdfunding platform
;; => Acts as the center hub for the CineX platform.
;; => Manages administrators.
;; => Links the crowdfunding, rewards, and escrow modules dynamically (can upgrade them if needed).
;; => Provides read-only access to platform stats (module addresses)

;; ========== Description ==========
;; Decentralized crowdfunding platform for filmmakers, connecting them with supporters securely via blockchain.




;; ========== Import Traits (interfaces for modules) ==========

;; Import NFT Reward Trait - used to interact with NFT reward contracts
(use-trait hub-nft-token-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Import the rewards-nft-trait for minting NFTs as rewards
(use-trait hub-nft-reward-trait .rewards-nft-trait.rewards-nft-trait)

;; Import Crowdfunding Trait - for crowdfunding module functions
(use-trait hub-crowdfunding-trait .crowdfunding-module-traits.crowdfunding-trait)

;; Import Escrow Trait - for escrow module functions
(use-trait hub-escrow-trait .escrow-module-trait.escrow-trait)

;; Import Rewards Trait - for rewards module functions
(use-trait hub-rewards-trait .rewards-module-trait.rewards-trait)

 
;; ========== Constants ==========

;; Define the contract owner as whoever deploys the contract (tx-sender during deployment)
(define-constant contract-owner tx-sender)

;; ========== Admin Management ==========

;; Main admin variable (can set modules and admins) - initially contract deployer
(define-data-var contract-admin principal tx-sender)

;; Map to track admin status: principal => bool (true/false)
(define-map admins principal bool)

;; ========== Module Reference Variables ==========

;; Variable to store address of Crowdfunding Module
(define-data-var crowdfunding-module principal contract-owner)

;; Variable to store address of Rewards Module
(define-data-var rewards-module principal contract-owner)

;; Variable to store address of Escrow Module
(define-data-var escrow-module principal contract-owner)

;; ========== Error Constants ==========

;; Error for unauthorized access (error code 1000)
(define-constant ERR-NOT-AUTHORIZED (err u1000))

;; Error for trying to access a module that has not been set yet (error code 1001)
(define-constant ERR-MODULE-NOT-SET (err u1001))

;; ========== Admin Functions ==========

;; Public function to set or remove an admin
(define-public (set-admin (new-admin principal) (is-admin bool))
  (begin
    ;; Only current admin can set other admins
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Set new-admin as admin (true) or remove (false)
    (ok (map-set admins new-admin is-admin))
  )
)

;; Read-only function to check if a user is an admin
(define-read-only (check-admin-status (user principal))
  ;; Return true or false based on map lookup
  (default-to false (map-get? admins user))
)

;; ========== Module Management Functions ==========

;; Public function to dynamically set the crowdfunding module address
(define-public (set-crowdfunding-module (new-module principal))
  (begin
    ;; Only admin can set crowdfunding module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Update module address
    (ok (var-set crowdfunding-module new-module))
  )
)

;; Public function to dynamically set the rewards module address
(define-public (set-rewards-module (new-module principal))
  (begin
    ;; Only admin can set rewards module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Update module address
    (ok (var-set rewards-module new-module))
  )
)

;; Public function to dynamically set the escrow module address
(define-public (set-escrow-module (new-module principal))
  (begin
    ;; Only admin can set escrow module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Update module address
    (ok (var-set escrow-module new-module))
  )
)

;; ========== Module Accessor Functions ==========

;; Read-only function to get the current crowdfunding module address
(define-read-only (get-crowdfunding-module)
  (var-get crowdfunding-module)
)

;; Read-only function to get the current rewards module address
(define-read-only (get-rewards-module)
  (var-get rewards-module)
)

;; Read-only function to get the current escrow module address
(define-read-only (get-escrow-module)
  (var-get escrow-module)
)

;; ========== Platform-Wide Statistics Function ==========

;; Read-only function to get the addresses of all linked modules
(define-read-only (get-platform-stats)
  {
    crowdfunding-module: (var-get crowdfunding-module),
    rewards-module: (var-get rewards-module),
    escrow-module: (var-get escrow-module)
  }
)
