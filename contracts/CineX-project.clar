;; title: CineX 
;; version: 1.0.0 
;; Author: Victor Omenai 
;; Created: 2025

;; ========== Summary ==========
;;  Main Entry Point for all modules (crowdfunding, rewards, escrow) of the CineX film crowdfunding platform
;; => Acts as the center hub for the CineX platform.
;; => Manages administrators.
;; => Links the crowdfunding, rewards, and escrow modules dynamically (can upgrade them if needed).
;; => Provides read-only access to platform stats (module addresses)

;; ========== Description ==========
;; Decentralized crowdfunding platform for filmmakers, connecting them with supporters securely via blockchain.
;; Strategic purpose: Main Hub that implements the "Key Partners" component of the Business Model Canvas of CineX
 
;; ========== Constants ==========

;; Define the contract owner as whoever deploys the contract (tx-sender during deployment)
(define-constant contract-owner tx-sender)

;; ========== Admin Management ==========

;; Main admin variable (can set modules and admins) - initially contract deployer
(define-data-var contract-admin principal tx-sender)

;; Map to track admin status: principal => bool (true/false)
(define-map admins principal bool)

;; ========== Module Reference Variables ==========
;; Add variable to store address of Verification Module
(define-data-var film-verification-module principal contract-owner)

;; Variable to store address of Crowdfunding Module
(define-data-var crowdfunding-module principal contract-owner)

;; Variable to store address of Rewards Module
(define-data-var rewards-module principal contract-owner)

;; Variable to store address of Escrow Module
(define-data-var escrow-module principal contract-owner)

;; Variable to store address of Co-EP Module
(define-data-var co-ep-module principal contract-owner)

;; ========== Error Constants ==========

;; Error for unauthorized access 
(define-constant ERR-NOT-AUTHORIZED (err u1000))

;; Error for trying to access a module that has not been set yet
(define-constant ERR-MODULE-NOT-SET (err u1001))

(define-constant ERR-CAMPAIGN-NOT-FOUND (err u1002))
(define-constant ERR-TRANSFER-FAILED (err u1003))

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
;; Public function to set the verification module address
(define-public (set-film-verification-module (new-module principal))
  (begin 
    ;; Only admin can set crowdfunding module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Update module address
    (ok (var-set film-verification-module new-module))    
  )
)

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

;; Public function to dynamically set the co-ep module address
(define-public (set-co-ep-module (new-module principal))
  (begin
    ;; Only admin can set escrow module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Update module address
    (ok (var-set co-ep-module new-module))
  )
)



;; ========== VERIFICATION INTEGRATION FUNCTIONS ==========
;; Function to get filmmaker portfolio
(define-public (check-is-portfolio-present (new-filmmaker principal) (new-id uint)) 
  (contract-call? .film-verification-module is-portfolio-available new-filmmaker new-id)
)

;; Function to check if a filmmaker is verified through the verification module
(define-public (check-is-filmmaker-verified (new-filmmaker principal)) 
  (contract-call? .film-verification-module is-filmmaker-currently-verified new-filmmaker)
)

;; Function to get filmmaker verification 
(define-public (check-endorsement-status (new-filmmaker principal) (new-id uint))
  (contract-call? .film-verification-module is-endorsement-available new-filmmaker new-id)
)

;; ========== CROWDFUNDING INTEGRATION FUNCTIONS ==========
;; Direct contract calls for crowdfunding operations
(define-public (create-campaign-via-hub (description (string-ascii 500)) 
    (funding-goal uint) 
    (duration uint) 
    (reward-tiers uint) 
    (reward-description (string-ascii 150)))
  (contract-call? .crowdfunding-module create-campaign description funding-goal u0 duration reward-tiers reward-description)    
)

(define-public (contribute-to-campaign (campaign-id uint) (amount uint))
  (contract-call? .crowdfunding-module contribute-to-campaign campaign-id amount)
) 

;; Centralized fund claiming with proper authorization
(define-public (claim-campaign-funds (campaign-id uint))
  (let 
    (
      ;; Get campaign details to verify ownership
      (campaign (unwrap! (contract-call? .crowdfunding-module get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))
       ;; Get campaign owner 
       (owner (get owner campaign))
    ) 
    ;; Ensure caller is campaign owner 
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)

    ;;Authorize withdrawal in escrow module 
    (unwrap! (contract-call? .escrow-module authorize-withdrawal campaign-id tx-sender) ERR-TRANSFER-FAILED)

    ;; Authorize fee collection in escrow module
    (unwrap! (contract-call? .escrow-module authorize-fee-collection campaign-id tx-sender) ERR-TRANSFER-FAILED)

    ;; Call the crowdfunding module toprocess the claim
    (contract-call? .crowdfunding-module claim-campaign-funds campaign-id)
  )
  
)

;; ========== ESCROW INTEGRATION FUNCTIONS ==========
;; Direct contract calls for escrow operations
(define-public (deposit-to-escrow-via-hub (campaign-id uint) (amount uint))
  (contract-call? .escrow-module deposit-to-campaign campaign-id amount)
)

;; Centralized withdrawal with proper authorization
(define-public (withdraw-from-escrow-via-hub (campaign-id uint) (amount uint))
  (let 
    (
      ;; Get campaign details to verify ownership
      (campaign (unwrap! (contract-call? .crowdfunding-module get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))
       ;; Get campaign owner 
       (owner (get owner campaign))
    ) 
    ;; Ensure caller is campaign owner 
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)

    ;;Authorize withdrawal in escrow module 
    (unwrap! (contract-call? .escrow-module authorize-withdrawal campaign-id tx-sender) ERR-TRANSFER-FAILED)

     ;; Call the escrow module to process the claim
     (contract-call? .escrow-module withdraw-from-campaign campaign-id amount)

  )
  
)

;; ========== REWARDS INTEGRATION FUNCTIONS ==========
;; Direct contract calls for rewards operations
(define-public (award-reward-via-hub (campaign-id uint) (contributor principal) (tier uint) (description (string-ascii 150))) 
  (contract-call? .rewards-module award-campaign-reward campaign-id contributor tier description)
)



;; ========== Module Accessor Functions ==========
;; Read-only function to get the current film verification module address
(define-read-only (get-verification-module)
  (var-get film-verification-module)
)

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

;; Read-only function to get the current escrow module address
(define-read-only (get-co-ep-module)
  (var-get co-ep-module)
)
;; ========== Platform-Wide Statistics Function ==========

;; Read-only function to get the addresses of all linked modules
(define-read-only (get-platform-stats)
  {
    crowdfunding-module: (var-get crowdfunding-module),
    rewards-module: (var-get rewards-module),
    escrow-module: (var-get escrow-module),
    film-verification-module: (var-get film-verification-module),
    co-ep-module: (var-get co-ep-module)
  }
)

;; ========== INITIALIZATION FUNCTION ==========
;; Master initialization function to set all modules at once
(define-public (initialize-platform (verification principal) (crowdfunding principal) (rewards principal) (escrow principal) (co-ep principal))
  (begin 
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (var-set film-verification-module verification)
    (var-set crowdfunding-module crowdfunding)
    (var-set rewards-module rewards)
    (var-set escrow-module escrow)
    (var-set co-ep-module co-ep)
    (ok true)
  
  )

)

