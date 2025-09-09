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

;; Large recovery operations
(define-constant LARGE-FUND-RECOVERY-LIMIT u100000000000) ;; 100,000 STX threshold for requiring co-signature 
(define-constant BURN-ADDRESS 'SP000000000000000000002Q6VF78) ;; known burn address to prevent accidental burn


;; ========== Admin Management ==========

;; Main admin variable (can set modules and admins) - initially contract deployer
(define-data-var contract-admin principal tx-sender)

;; State to store transfer of pending-admin status
(define-data-var pending-admin (optional principal) none) ;; (none) => no pending admin transfers yet on deployment and
                                                              ;; no pending-admin (optional principal) yet as well

;; Map to track admin status: principal => bool (true/false)
(define-map admins principal bool)

;; Track initialization state to prevent malicious re-initialization of existing initialized
(define-data-var platform-initialized bool false) ;; platform not yet initialize
(define-data-var initialization-block-height (optional uint) none) 


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


;; Current admin suggests a new admin (but doesn't transfer yet) with validation
(define-public (safe-propose-admin-transfer (new-admin principal))
  (begin 
    ;; Only current admin can propose transfer
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Don't allow sending to burn address (would lose admin forever!)
    (asserts! (not (is-eq tx-sender BURN-ADDRESS)) ERR-INVALID-RECIPIENT)

    ;; Prevent current admin self-transferring (redundant operation)
    (asserts! (not (is-eq tx-sender (var-get contract-admin))) ERR-INVALID-RECIPIENT)

    ;; Check that new-admin is not one of is-our-contract-address
    (asserts! (not (is-our-contract-address new-admin)) ERR-INVALID-RECIPIENT)

     ;; Set pending admin with prospective new-admin for confirmation 
     (var-set pending-admin (some new-admin))

     ;; Set optional block-height (time) when current-admin suggested it
     (var-set admin-transfer-proposed-at (some block-height))

     ;; Print log for efficient Audit trails
     (print
      {
        event: "admin-transfer-proposed",
        current-admin: tx-sender,
        proposed-admin: new-admin,
        block-height: block-height
      }
)

    
    (ok true)
  )
)


;; Prospective admin accepts proposed-new-admin 
(define-public (accept-pending-admin-transfer) 
  (let 
    (
      ;; From the pending-admin state (which has an optional admin value), get the person who was suggested 
          ;; to be new admin
      (current-pending-admin (unwrap! (var-get pending-admin) ERR-NO-PENDING-TRANSFER))
      
      ;; Get standard transfer-timeout
      (transfer-timeout (var-get pending-admin-transfer-timeout))

      ;; Get when optional pending-admin-transfer was suggested
      (transfer-proposed-at (unwrap! (var-get admin-transfer-proposed-at) ERR-NO-PENDING-TRANSFER))
      
      ;; Calculate how much time has passed since pending-admin-transfer was proposed
      (time-elapsed (- block-height transfer-proposed-at))

      ;; Reference  proposal time when it has passed the transfer timeout of 24 hours 
      (has-timed-out (> time-elapsed transfer-timeout))


    ) 

     ;; Only proposed admin can accept
     (asserts! (is-eq tx-sender current-pending-admin) ERR-NOT-AUTHORIZED)

     ;; If pending-admin-transfer has timed-out, prevent accepting expired transfers
     (asserts! (not has-timed-out) ERR-TRANSFER-TIMEOUT)

     ;; Execute the transfer to the new person
     (var-set pending-admin (some current-pending-admin))

     ;; Clear the pending-admin state with a none principal once again - back to its original optional state of "none"
     (var-set pending-admin none)

     ;; Clear the timestamp of when optional pending-admin-transfer was proposed - back to its original optional state of "none"
     (var-set admin-transfer-proposed-at none)

    ;; Print log for efficient Audit trails
     (print
      {
        event: "admin-transfer-completed",
        new-admin: current-pending-admin,
        block-height: block-height
      }
)
     (ok true)


  )
)

;; Our-current-contract-addresses
  ;; @func: To be used in safe-admin-transfer-propose function to check that proposed admin is not any
  ;; of our contracts currently in usage 
(define-private (is-our-contract-address (address principal)) 
  (or 
      (is-eq address (var-get film-verification-module))
      (is-eq address (var-get crowdfunding-module)) 
      (is-eq address (var-get rewards-module)) 
      (is-eq address (var-get escrow-module)) 
      (is-eq address (var-get co-ep-module)) 
      (is-eq address (var-get verification-mgt-ext))
  )
)


;; Read-only fuction to Get/Check status of pending admin transfer
(define-read-only (get-pending-admin) 
  (let 
    (
      ;; Get when optional pending-admin-transfer was suggested
      (transfer-proposed-at (unwrap! (var-get admin-transfer-proposed-at) ERR-NO-PENDING-TRANSFER))

      ;; Get standard transfer-timeout
      (transfer-timeout (var-get pending-admin-transfer-timeout))

    ) 

    ;; Retrieve optional pending-admin some-value
    (match (var-get pending-admin) 
    ;; If is a pending admin, assign the details  
    pending-admin-info 
      ;; Then, show details
      (some {
        pending-admin: pending-admin-info,
        proposed-at: transfer-proposed-at,
        expires-at: (+ transfer-proposed-at transfer-timeout)  ;; add transfer timeout of u144 to time admin transfer was proposed
       }) 

    ;; If no pending admin, return nothing 
      none
    )

    (ok true)
  )

)



 ;; Allow current admin to cancel pending transfer 
  ;; @func: While canceling any pending transfer made for any reason, Cancel also clears the timestamp
(define-public (cancel-admin-transfer) 
  (begin 
    ;; Only current admin can cancel
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Ensure there's a pending transfer to cancel
    (asserts! (is-some (var-get pending-admin)) ERR-NO-PENDING-TRANSFER)

    ;; Clear the pending-admin state with a none principal once again - back to its original optional state
    (var-set pending-admin none)

    (ok true)

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
  (let
    (
      (old-module (var-get film-verification-module))
    )
    ;; Only admin can set crowdfunding module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Prevent setting module to another existing module address 
    (asserts! (not (is-our-contract-address new-module)) ERR-INVALID-MODULE)

    ;; Update module address
    (var-set film-verification-module new-module)   

    ;; Print log for efficient Audit trails
    (print 
      {
        event: "module updated",
        module-type: "film verification",
        old-address: old-module,
        new-address: new-module,
        admin: tx-sender,
        block-height: block-height
      }
    
    )

    (ok true)
  )
)

;; Public function to dynamically set the crowdfunding module address
(define-public (set-crowdfunding-module (new-module principal))
  (let 
    (
      (old-module (var-get crowdfunding-module))
    )
   ;; Only admin can set crowdfunding module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)
    
    ;; Prevent setting module to another existing module address 
    (asserts! (not (is-our-contract-address new-module)) ERR-INVALID-MODULE)
    
    ;; Update module address
    (var-set crowdfunding-module new-module) 

    ;; Print log for efficient Audit trails
    (print 
      {
        event: "module updated",
        module-type: "crowdfunding",
        old-address: old-module,
        new-address: new-module,
        admin: tx-sender,
        block-height: block-height
      }
    )

    (ok true)
  )
)

;; Public function to dynamically set the rewards module address
(define-public (set-rewards-module (new-module principal))
  (let
    (
      (old-module (var-get rewards-module))
    )
    ;; Only admin can set rewards module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Prevent setting module to another existing module address 
    (asserts! (not (is-our-contract-address new-module)) ERR-INVALID-MODULE)
    
    ;; Update module address
    (var-set rewards-module new-module)

    ;; Print log for efficient Audit trails
    (print
      {
        event: "module updated",
        module-type: "rewards",
        old-address: old-module,
        new-address: new-module,
        admin: tx-sender,
        block-height: block-height

      }
    )

    (ok true)
  )
) 

;; Public function to dynamically set the escrow module address
(define-public (set-escrow-module (new-module principal))
  (let
    (
      (old-module (var-get escrow-module))
    )
    ;; Only admin can set escrow module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Prevent setting module to another existing module address 
    (asserts! (not (is-our-contract-address new-module)) ERR-INVALID-MODULE)
    
    ;; Update module address
    (var-set escrow-module new-module)

    ;; Print log for efficient Audit trails
    (print
      {
        event: "module updated",
        module-type: "escrow",
        old-address: old-module,
        new-address: new-module,
        admin: tx-sender,
        block-height: block-height

      }
    )

    (ok true)
  )
)

;; Public function to dynamically set the co-ep module address
(define-public (set-co-ep-module (new-module principal))
  (let
    (
      (old-module (var-get co-ep-module))
    )
    ;; Only admin can set escrow module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Prevent setting module to another existing module address 
    (asserts! (not (is-our-contract-address new-module)) ERR-INVALID-MODULE)
    
    ;; Update module address
    (var-set co-ep-module new-module)

    ;; Print log for efficient Audit trails
    (print
      {
        event: "module updated",
        module-type: "co-ep",
        old-address: old-module,
        new-address: new-module,
        admin: tx-sender,
        block-height: block-height

      }
    )

    (ok true)
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
  (let 
    (
      ;; Get crowdfunding contract
      (crowdfunding-contract (var-get crowdfunding-module))
    ) 

    ;; Ensure crowdfunding module is validated before using it
    (try! (validate-safe-module .crowdfunding-module .crowdfunding-module))

    ;; Ensure is not paused for normal operations
    (asserts! (is-eq (var-get emergency-pause) false) ERR-SYSTEM-PAUSED)

    (contract-call? .crowdfunding-module create-campaign description funding-goal u0 duration reward-tiers reward-description)    
  
  )
)


(define-public (contribute-to-campaign (campaign-id uint) (amount uint))
  (let 
    (
      ;; Get crowdfunding contract
      (crowdfunding-contract (var-get crowdfunding-module))
    ) 

     ;; Ensure crowdfunding module is validated before using it
    (try! (validate-safe-module .crowdfunding-module .crowdfunding-module))

    ;; Ensure is not paused for normal operations
    (asserts! (is-eq (var-get emergency-pause) false) ERR-SYSTEM-PAUSED)

    (contract-call? .crowdfunding-module contribute-to-campaign campaign-id amount)
  )
) 


;; Centralized fund claiming with proper authorization
(define-public (claim-campaign-funds (campaign-id uint))
  (let 
    (
      ;; Get campaign details to verify ownership
      (campaign (unwrap! (contract-call? .crowdfunding-module get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))

       ;; Get campaign owner, funding goal and current-total-raised so far
       (owner (get owner campaign))
       (current-funding-goal (get funding-goal campaign))
       (current-total-raised (get total-raised campaign))

      ;; Get crowdfunding contract
      (crowdfunding-contract (var-get crowdfunding-module))

    ) 
    ;; Ensure crowdfunding module is validated before using it
    (try! (validate-safe-module .crowdfunding-module .crowdfunding-module))

    ;; Ensure is not paused for normal operations
    (asserts! (is-eq (var-get emergency-pause) false) ERR-SYSTEM-PAUSED)

    ;; Ensure caller is campaign owner 
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)

    ;; Ensure funding goal was met, or execceded, else campaign is unsuccessful
    (asserts! (>= current-total-raised current-funding-goal) ERR-FUNDING-GOAL-NOT-REACHED)

    ;;Authorize withdrawal in escrow module 
    (try! (contract-call? .escrow-module authorize-withdrawal campaign-id tx-sender))

    ;; Authorize fee collection in escrow module
    (try! (contract-call? .escrow-module authorize-fee-collection campaign-id tx-sender))

    ;; Call the crowdfunding module to process the claim
    (try! (contract-call? .crowdfunding-module claim-campaign-funds campaign-id))

    ;; Log successful claim
    (print {
      event: "campaign claim successful",
      campaign-id: campaign-id,
      owner: owner,
      amount: current-total-raised,
      block-height: block-height

    })

    (ok true)
    
  )
  
)


;; ========== ESCROW INTEGRATION FUNCTIONS ==========
;; Direct contract calls for escrow operations
(define-public (deposit-to-escrow-via-hub (campaign-id uint) (amount uint))
  (let 
    (
      ;; Get crowdfunding contract
      (escrow-module-contract (var-get escrow-module))

    ) 

    ;; Ensure crowdfunding module is validated before using it
    (try! (validate-safe-module .escrow-module .escrow-module))

    ;; Ensure is not paused for normal operations
    (asserts! (is-eq (var-get emergency-pause) false) ERR-SYSTEM-PAUSED)

    (contract-call? .escrow-module deposit-to-campaign campaign-id amount)

  )
  
)

;; Centralized withdrawal with proper authorization
(define-public (withdraw-from-escrow-via-hub (campaign-id uint) (amount uint))
  (let 
    (
      ;; Get campaign details to verify ownership
      (campaign (unwrap! (contract-call? .crowdfunding-module get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))
       ;; Get campaign owner 
       (owner (get owner campaign))

       ;; Get crowdfunding contract
      (escrow-module-contract (var-get escrow-module))

    ) 
    ;; Ensure crowdfunding module is validated before using it
    (try! (validate-safe-module .escrow-module .escrow-module))

    ;; Ensure is not paused for normal operations
    (asserts! (is-eq (var-get emergency-pause) false) ERR-SYSTEM-PAUSED)

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
(define-public (award-reward-via-hub (campaign-id uint) 
    (contributor principal) 
    (tier uint) 
    (description (string-ascii 150)))
  (let 
    (
      ;; Get crowdfunding contract
      (rewards-module-contract (var-get rewards-module))

    ) 

    ;; Ensure crowdfunding module is validated before using it
    (try! (validate-safe-module .rewards-module .rewards-module))

    ;; Ensure is not paused for normal operations
    (asserts! (is-eq (var-get emergency-pause) false) ERR-SYSTEM-PAUSED)

    (contract-call? .rewards-module award-campaign-reward campaign-id contributor tier description)
  )
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

     ;; Prevent multiple initializations (critical security)
    (asserts! (not (var-get platform-initialized)) ERR-ALREADY-INITIALIZED)
     
     ;; Ensure none of the modules is a BURN ADDRESS
     (asserts! (not (is-eq verification BURN-ADDRESS)) ERR-INVALID-RECIPIENT)
     (asserts! (not (is-eq crowdfunding BURN-ADDRESS)) ERR-INVALID-RECIPIENT)
     (asserts! (not (is-eq rewards BURN-ADDRESS)) ERR-INVALID-RECIPIENT)
     (asserts! (not (is-eq escrow BURN-ADDRESS)) ERR-INVALID-RECIPIENT)
     (asserts! (not (is-eq co-ep BURN-ADDRESS)) ERR-INVALID-RECIPIENT)
     (asserts! (not (is-eq verf-ext BURN-ADDRESS)) ERR-INVALID-RECIPIENT)

     ;; Prevent setting modules to same address as other modules
     (asserts! (not (is-eq verification crowdfunding)) ERR-DUPLICATE-MODULE)
     (asserts! (not (is-eq verification rewards)) ERR-DUPLICATE-MODULE)
     (asserts! (not (is-eq verification escrow)) ERR-DUPLICATE-MODULE)
     (asserts! (not (is-eq verification co-ep )) ERR-DUPLICATE-MODULE)
     (asserts! (not (is-eq verification verf-ext)) ERR-DUPLICATE-MODULE)
    

    (var-set film-verification-module verification)
    (var-set crowdfunding-module crowdfunding)
    (var-set rewards-module rewards)
    (var-set escrow-module escrow)
    (var-set co-ep-module co-ep)
    (ok true)
  
  )

)


;; Read-only function to check initialization status
(define-read-only (get-initialization-status)
  (let 
    (
      ;; Get contract-admin
      (current-contract-admin (var-get contract-admin))

      ;; Get initialized state
      (current-init-state (var-get platform-initialized))

      ;; Get timestamp of initialization 
      (current-init-blockheight (var-get initialization-block-height))
    ) 
    {
      is-initialized: current-init-state,
      initialized-at: current-init-blockheight,
      admin: current-contract-admin
    }

    
  )
)


