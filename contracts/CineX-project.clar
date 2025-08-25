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


;; Import to use the emergency-module-trait interface 
(use-trait core-emergency-module .emergency-module-trait.emergency-module-trait)

;; Import to use the module-base-trait
(use-trait core-module-base .module-base-trait.module-base-trait)

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

;; Variable to store address of Verification-mgt-extension
(define-data-var verification-mgt-ext principal contract-owner)

;; ========== Emergency State  ========
;; Variable to hold state of operations 'not paused (false)' until when necessary 
(define-data-var emergency-pause bool false) 

;; ========== Error Constants ==========
(define-constant ERR-NOT-AUTHORIZED (err u200)) ;; Error for unauthorized access 
(define-constant ERR-MODULE-NOT-SET (err u201)) ;; Error for trying to access a module that has not been set yet
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u202)) ;; Error for trying to access campaign not found
(define-constant ERR-TRANSFER-FAILED (err u203)) ;; Error for failed transfer transactions
(define-constant ERR-SYSTEM-PAUSED (err u204)) ;; Error for trying to access a paused system, or an unpaused system as well
(define-constant ERR-SYSTEM-NOT-PAUSED (err u205)) ;; Error for trying to access a system not paused  
(define-constant ERR-INVALID-MODULE (err u206)) ;; Error for trying an invalid module

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

;; Read-only function to check system status
(define-read-only (is-system-paused) 
  (var-get emergency-pause)
)



;; ========== SAFE MODULE OPERATION - VALIDATE BEFORE USING ==========
;; Function to safely call a module after validation
  ;; @param: module - <module-base>;
(define-public (validate-safe-module (module-base <core-module-base>)) 
  (let 
    (
      ;; Get module version
      (current-module-version (unwrap! (contract-call? module-base get-module-version) ERR-INVALID-MODULE))
    ) 
    ;; Ensure the version is compatible? (must be v1 or higher)
    (asserts! (>= current-module-version u1) ERR-INVALID-MODULE)
    
    ;; Validate that the module is the one we expect
    (asserts! (is-contract-expected module-base) ERR-INVALID-MODULE)

    ;; Check that the module is active
    (try! (contract-call? module-base is-module-active))

    ;; If we get here, module is valid!
    (ok true)
  )

)


;; Helper to check if a contract is one we expect 
(define-private (is-contract-expected (module-base <core-module-base>))
  (let 
    (
      ;; Get contract address of module-base-trait for us to check contract ID/address of modules 
      (module-contract (contract-of module-base))
    ) 
    (or 
      (is-eq module-contract (var-get film-verification-module))
      (is-eq module-contract (var-get crowdfunding-module)) 
      (is-eq module-contract (var-get rewards-module)) 
      (is-eq module-contract (var-get escrow-module)) 
      (is-eq module-contract (var-get co-ep-module)) 
      (is-eq module-contract (var-get verification-mgt-ext)) 
    )
   
  )
)   



;; ========== Emergency Control Function ==========
;; Public function to activate Emergency pause-or-not-pause system 
(define-public (emergency-pause-or-not-pause-system (pause bool)) 
  (let 
    (
      ;; Get current-contract-admin
      (current-contract-admin (var-get contract-admin))
      (rotating-pool-contract (var-get co-ep-module))
    ) 
    ;; Only admin can pause/unpause the system
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Set emergency-pause state to new pause state
    (var-set emergency-pause pause)

    ;; Notify all modules of emergency new pause state
    (try! (contract-call? .crowdfunding-module set-pause-state pause))
    (try! (contract-call? .escrow-module set-pause-state pause))
    (try! (contract-call? .film-verification-module set-pause-state pause))
    (try! (contract-call? .rewards-module set-pause-state pause))
    (try! (contract-call? .verification-mgt-extension set-pause-state pause))
    (try! (contract-call? .Co-EP-rotating-fundings set-pause-state pause))

    (ok true)
      
  )
)

;; Emergency fund recovery
  ;; @func: It works by calling the emergency-withdraw function on whichever module is specified, allowing the admin 
    ;; to recover funds from any module during emergencies 
    ;; Dynamic calling: Can work with any "module" that has the emergency-withdraw function
    ;; Delegation: This function doesn't actually move money - it tells the target module to do it
(define-public (emergency-fund-recovery (module <core-emergency-module>) (amount uint) (recipient principal)) 
  (begin 
    ;; Ensure only admin can perform emergency recovery
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Ensure system must be paused,else trigger ERR-SYSTEM-NOT-PAUSED
      ;; If (var-get emergency-pause) gets/returns 'false', (asserts!) sees 'false', throws ERR-SYSTEM-NOT-PAUSED,
       ;; and Emergency recovery is BLOCKED 
      ;; If (var-get emergency-pause) gets/returns 'true', (asserts!) sees 'true' and allows execution
      ;; of emergency-fund-recovery to continue
    (asserts! (var-get emergency-pause) ERR-SYSTEM-NOT-PAUSED)

    ;; Call the emergency-withdraw function on the specified module
    (contract-call? module emergency-withdraw amount recipient)
   
  )

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


;; Public function to dynamically set the verification-mgt extension
(define-public (set-verification-ext (new-module principal))
  (begin
    ;; Only admin can set escrow module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Update module address
    (ok (var-set verification-mgt-ext new-module))
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
    co-ep-module: (var-get co-ep-module),
    verification-mgt: (var-get verification-mgt-ext)
  }
)

;; ========== INITIALIZATION FUNCTION ==========
;; Master initialization function to set all modules at once
(define-public (initialize-platform (verification principal) 
                (crowdfunding principal) 
                (rewards principal) 
                (escrow principal) 
                (co-ep principal)
                (verf-ext principal))
  (begin 
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    (var-set film-verification-module verification)
    (var-set crowdfunding-module crowdfunding)
    (var-set rewards-module rewards)
    (var-set escrow-module escrow)
    (var-set co-ep-module co-ep)
    (var-set verification-mgt-ext verf-ext)
    (ok true)
  
  )

)

