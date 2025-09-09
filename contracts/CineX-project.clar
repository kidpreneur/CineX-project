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

;; Variable to store address of Verification-mgt-extension
(define-data-var verification-mgt-ext principal contract-owner)

;; ========== Emergency State ========
;; Variable to hold state of operations 'not paused (false)' until when necessary 
(define-data-var emergency-pause bool false) 

;; Counter for emergency recovery operations
(define-data-var emergency-recovery-ops-counter uint u0)

;; State to track how many blocks until transfer suggestion expires (about 24 hours)
(define-data-var pending-admin-transfer-timeout uint u144)

;; Track when optional pending-admin-transfer was proposed
(define-data-var admin-transfer-proposed-at (optional uint) none)


;; Map to track emergency recovery operations for audit trail
    ;; key-tuple value - uint (for unique recovery operation id)
(define-map emergency-fund-recovery-log uint {
  module-contract: principal,
  amount: uint,
  recipient: principal,
  admin: principal,
  block-height: uint,
  fund-recovery-reason: (string-ascii 100)
})

;; ========== Error Constants ==========
(define-constant ERR-NOT-AUTHORIZED (err u200)) ;; Error for unauthorized access 
(define-constant ERR-MODULE-NOT-SET (err u201)) ;; Error for trying to access a module that has not been set yet
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u202)) ;; Error for trying to access campaign not found
(define-constant ERR-TRANSFER-FAILED (err u203)) ;; Error for failed transfer transactions
(define-constant ERR-SYSTEM-PAUSED (err u204)) ;; Error for trying to access a paused system, or an unpaused system as well
(define-constant ERR-SYSTEM-NOT-PAUSED (err u205)) ;; Error for trying to access a system not paused  
(define-constant ERR-INVALID-MODULE (err u206)) ;; Error for trying an invalid module
(define-constant ERR-INVALID-AMOUNT (err u207)) ;; Error for trying to withdraw Invalid amount durng emergency recovery 
(define-constant ERR-NO-FUNDS-TO-RECOVER (err u208)) ;; Error for trying to validate non-existent funds from a module
(define-constant ERR-INSUFFICIENT-FUNDS (err u209)) ;; Error for trying send ear-marked recovery amount that is less than or equal to u0
(define-constant ERR-INVALID-RECIPIENT (err u210))
(define-constant ERR-CANNOT-SEND-TO-SELF (err u211)) ;; Admin error for tryng to recover funds to oneself instead of to the platform
(define-constant ERR-ABOVE-EMERGENCY-WITHDRAWAL-LIMIT (err u212))
(define-constant ERR-EMERGENCY-WTIHDRAWAL-FAILED (err u213))
(define-constant ERR-PAUSE-OR-NOT-PAUSED-FAILED (err u214))
(define-constant ERR-PAUSE-STATE-RESULT (err u215))
(define-constant ERR-FUNDING-GOAL-NOT-REACHED (err u216))
(define-constant ERR-ALREADY-INITIALIZED (err u217))
(define-constant ERR-DUPLICATE-MODULE (err u218))

;; Error messages for admin transfers
(define-constant ERR-TRANSFER-TIMEOUT (err u219))   ;; Transfer took too long - longer than standard 24 hours (u144)
(define-constant ERR-NO-PENDING-TRANSFER (err u220)) ;; No transfer waiting

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

;; Read-only function to check system status
(define-read-only (is-system-paused) 
  (var-get emergency-pause)
)



;; ========== SAFE MODULE OPERATION - VALIDATE BEFORE USING ==========
;; Function to safely call a module after validation
  ;; @param: module - <module-base>;
(define-public (validate-safe-module (module-base <core-module-base>) (emergency-module <core-emergency-module>)) 
  (let 
    (
      ;; Get module base contract address
      (base-contract (contract-of module-base))

      ;; Get module version
      (current-module-version (unwrap! (contract-call? module-base get-module-version) ERR-INVALID-MODULE))

      ;; Get current-module-active-status
      (current-module-active-status (unwrap! (contract-call? module-base is-module-active) ERR-INVALID-MODULE))

      (current-emergency-pause-state (var-get emergency-pause))
    ) 

     ;; BASIC ADDRESS VALIDATION
    ;; Ensure module address is not burn address
    (asserts! (not (is-eq base-contract BURN-ADDRESS)) ERR-INVALID-MODULE)

    ;; Ensure the version is compatible? (must be v1 or higher)
    (asserts! (>= current-module-version u1) ERR-INVALID-MODULE)
    
    ;; Validate that the module is the one we expect
    (asserts! (is-contract-expected module-base) ERR-INVALID-MODULE)

    ;; Check that the module is active
    (asserts! current-module-active-status ERR-INVALID-MODULE)

    ;; SYSTEM STATE VALIDATION
    ;; If system is paused, only emergency modules should be accessible
    (if (var-get emergency-pause) 
      ;; During emergency, ensure only emergency-capable modules are allowed to run
      (asserts! (is-emergency-module-capable emergency-module) ERR-INVALID-MODULE)
      
      ;; Else, During normal operation, all registered modules are valid and allowed
      true
        
    )
    (ok true)

    
  )

)


;; Helper to check if a contract is one we expect - general activity and versioning validation  
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

;; Helper to check if module supports emergency operations
(define-private (is-emergency-module-capable (emergency-module <core-emergency-module>)) 
  (let 
    (
      ;;Get contract address of emergency module
      (module-contract (contract-of emergency-module))
      
    ) 
      
      ;; Now we can check if the trait implementation of each module is the same as one of our registered modules
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

      ;; Get all current module addresses dynamically 
      (crowdfunding-addr (var-get crowdfunding-module))
      (escrow-addr (var-get escrow-module))
      (film-ver-addr (var-get film-verification-module))
      (rewards-addr (var-get rewards-module))
      (ver-mgt-ext-addr (var-get verification-mgt-ext))
      (co-ep-addr (var-get co-ep-module))
      
    ) 
    ;; Only admin can pause/unpause the system
    (asserts! (is-eq tx-sender current-contract-admin) ERR-NOT-AUTHORIZED)

    ;; Set main hub emergency-pause state to new pause state
    (var-set emergency-pause pause)

    ;; Notify all modules of emergency new pause state
     ;; In the course of updating each module, if partcular module-name in pause-module helper fails, others still work
     ;; Use try! to handle responses properly
     (try! (pause-module .crowdfunding-module pause "crowdfunding"))
     (try! (pause-module .escrow-module pause "escrow"))
     (try! (pause-module .film-verification-module pause "film verification"))
     (try! (pause-module .rewards-module pause "rewards"))
     (try! (pause-module .verification-mgt-extension pause "verification mgt"))
     (try! (pause-module .Co-EP-rotating-fundings pause "Co-Executive Producers pool"))

    ;; Print log for efficient Audit trails
     (print
      {
        event: "system pause update",
        new-state: pause,
        admin: tx-sender,
        block-height: block-height,
        note: "check individual module logs for detailed results"
      }
           
    )
    (ok true)
  )
)


;; Helper function to pause a single module with proper error handling
(define-private (pause-module (module <core-emergency-module>) (pause bool) (module-name (string-ascii 50)))  
  (match (contract-call? module set-pause-state pause) 
        pause-successful (begin 
                          (print 
                            {
                              module: module-name,
                              status: "updated",
                              pause: pause
                            })

                          (ok pause-successful)

                        ) 
        error (begin 
              (print 
                {
                  module: module-name,
                  status: "failed",
                  error: error,
                  pause: pause
                }) 

            ERR-PAUSE-OR-NOT-PAUSED-FAILED  

            )
  )

)



;; Function to check pause state consistency across all modules
(define-read-only (get-system-pause-status) 
  (let 
    (
      ;; get pause-state of main hub as well as the other modules
      (hub-paused (var-get emergency-pause))
      (crowdfunding-paused (contract-call? .crowdfunding-module is-system-paused))
      (escrow-paused (contract-call? .escrow-module is-system-paused))
      (film-verification-paused (contract-call? .film-verification-module is-system-paused))
      (rewards-paused (contract-call? .rewards-module is-system-paused))
      (verf-mgt-ext-paused (contract-call? .verification-mgt-extension is-system-paused))
      (co-ep-paused (contract-call? .Co-EP-rotating-fundings is-system-paused))

    ) 
    
    {
      ;; Return tuple data details of system-pause state of each module including the main hub
      hub-paused: hub-paused,
      modules: {
        crowdfunding: crowdfunding-paused,
        escrow: escrow-paused,
        film-verification: film-verification-paused,
        rewards: rewards-paused,
        verf-ext: verf-mgt-ext-paused,
        co-ep: co-ep-paused

       },

       ;; tuple data ensures that system-pause state in main-hub is consistent (is-eq) 
            ;; with the same system-pause state in each module
      is-consistent: (and   
          (is-eq hub-paused crowdfunding-paused)
          (is-eq hub-paused escrow-paused)
          (is-eq hub-paused film-verification-paused)
          (is-eq hub-paused rewards-paused)
          (is-eq hub-paused verf-mgt-ext-paused)
          (is-eq hub-paused co-ep-paused)
      
        )
       
    }
    
  )
)



;; Emergency fund recovery
  ;; @func: It works by calling the emergency-withdraw function on whichever module is specified, allowing the admin 
    ;; to recover funds from any module during emergencies 
    ;; Dynamic calling: Can work with any "module" that has the emergency-withdraw function
    ;; Delegation: This function doesn't actually move money - it tells the target module to do it
(define-public (emergency-fund-recovery (module <core-emergency-module>) (module-base <core-module-base>) (amount uint) (recipient principal) (recovery-reason (string-ascii 100))) 
  (let 
    ( ;; Get the contract address of the module we're trying to recover funds from
        ;; This tells us which specific contract holds the funds
      (module-contract (contract-of module))

      ;; Get the actual STX balance available in that module contract - the maximum amount info we could possibly recover from (get-specific-module-recoverable-balance (module-address principal))
          ;; get-module-balance-info
      (module-balance-info  (get-specific-module-recoverable-balance module-contract))
      
          ;; get actual-module-balance from the maximum amount info
      (actual-module-balance (get module-balance module-balance-info))

          ;; get has-funds module's STX balance status is greater than 0 microstacks (u0), and false otherwise.
      (module-has-funds-status (get has-balance module-balance-info))

      ;; Get current emergency recovery counter for logging purposes
      (current-recovery-ops-counter (var-get emergency-recovery-ops-counter))
      ;; next-recovery-ops-counter
      (next-recovery-ops-counter (+ u1 current-recovery-ops-counter))
    ) 
    
    ;; Ensure only admin can perform emergency recovery
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

    ;; Ensure system must be paused,else trigger ERR-SYSTEM-NOT-PAUSED
      ;; If (var-get emergency-pause) gets/returns 'false', (asserts!) sees 'false', throws ERR-SYSTEM-NOT-PAUSED,
       ;; and Emergency recovery is BLOCKED 
      ;; If (var-get emergency-pause) gets/returns 'true', (asserts!) sees 'true' and allows execution
      ;; of emergency-fund-recovery to continue
    (asserts! (var-get emergency-pause) ERR-SYSTEM-NOT-PAUSED)

    ;; Ensure the module is actually one of our registered modules to prevent unauthorized access
    (asserts! (is-contract-expected module-base) ERR-INVALID-MODULE)

    ;; FUND VALIDATION
    ;; Validation of funds availability- if the target module actually has any funds to recover
      ;; No point trying to recover from an empty contract
    (asserts! (is-some module-has-funds-status) ERR-NO-FUNDS-TO-RECOVER)

     ;; Validate that requested recovery "amount" is not zero
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

     ;; Ensure there is some actual-module-balance and that we're not trying to recover more than what's actually available
      ;; This prevents the transaction from failing due to insufficient funds
    (asserts! (and (is-some actual-module-balance) (>= (unwrap-panic actual-module-balance) amount)) ERR-INSUFFICIENT-FUNDS)

    ;; RECIPIENT VALIDATION
    ;; Ensure recovered funds are not mistakenly sent to a BURN-ADDRESS as recipient
    (asserts! (not (is-eq recipient BURN-ADDRESS)) ERR-INVALID-RECIPIENT)

    ;; Prevent admin from recovering funds directly to themselves
    ;; This adds transparency and prevents appearance of self-sabotage
    (asserts! (not (is-eq tx-sender recipient)) ERR-CANNOT-SEND-TO-SELF)

    ;; LARGE RECOVERY ADDITIONAL VALIDATION 
    ;; Check IF recovery amount is too large, that is, larger than large-fund-recovery-limit, 
    (asserts! (<= amount LARGE-FUND-RECOVERY-LIMIT) ERR-ABOVE-EMERGENCY-WITHDRAWAL-LIMIT)
 
    ;; Next, Record this emergency recovery operation in the map state (emergency-fund-recovery) for future audit 
    ;; and transparency
    (map-set emergency-fund-recovery-log next-recovery-ops-counter {
      module-contract: module-contract,
      amount: amount,
      recipient: recipient,
      admin: tx-sender,
      block-height: block-height,
      fund-recovery-reason: recovery-reason
    })
    
    ;; Update the recovery operation counter for next operation
    (var-set emergency-recovery-ops-counter next-recovery-ops-counter)
    
    ;; Now we EXECUTE THE ACTUAL RECOVERY
      ;; Call the emergency-withdraw function on the specified module, delegating the actual fund transfer to the module itself
      ;; @func: The module is responsible for transferring/recovering 'amount' STX to 'recipient'
    (match (contract-call? module emergency-withdraw amount recipient) 
      emergency-recovery-success 
        (begin 
          (print  
            {
              event: "recovery-successful",
              operation-id: next-recovery-ops-counter,
              module: module-contract,
              amount: amount,
              recipient: recipient,
              admin: tx-sender,
              emergency-withdrawal-reason: recovery-reason,
              block-height: block-height

            })
          (ok emergency-recovery-success)
        ) 
      error-result
        (begin 
          (print 
            {
              event: "emergency-recovery-failed", 
              operation-id: next-recovery-ops-counter,
              module: module-contract,
              error: error-result
            })
          ERR-EMERGENCY-WTIHDRAWAL-FAILED
        )

    )
        
  )
        
)

    
;; Get total-recoverable-funds
  ;; @func: This function calculates the actual funds that can be recovered during emergency
   ;; by querying the real locations where funds are stored in the CineX system
(define-read-only (get-total-recoverable-funds) 
  (let 
    (
      ;; Get the actual STX balance held by the escrow module contract - that is, where campaign contributions are actually stored
        ;; first, by getting the escrow state
      (escrow-module-address (var-get escrow-module))
      ;; then secondly, getting the actual escrow STX balance 
      (escrow-stx-balance (stx-get-balance escrow-module-address))

      ;; Get the actual STX balance held by the crowdfunding module contract - might have platform fees or unclaimed funds
        ;; first, by getting the crowdfunding module state
      (crowdfunding-address (var-get crowdfunding-module))
        ;; then, get the actual crowdfunding STX balance
      (crowdfunding-stx-balance (stx-get-balance crowdfunding-address))

      ;; Get the actual STX balance held by the rewards module contract - this might have reward funds waiting to be distributed
      (rewards-address (var-get rewards-module))
        ;; then, get the actual rewards STX balance
      (rewards-stx-balance (stx-get-balance rewards-address))

      ;; Get the STX balance held by the main hub contract itself
        ;; This might have collected fees or emergency reserves
      (hub-stx-balance (stx-get-balance (as-contract tx-sender)))
     
     ;; Calculate total recoverable funds across all contract addresses
      ;; where CineX platform actually stores STX tokens
      (total-recoverable-stx (+ (+ (+ escrow-stx-balance crowdfunding-stx-balance) rewards-stx-balance) hub-stx-balance))  
      
    ) 
    ;; Return the total amount that could theoretically be recovered during an emergency situation across all CineX contracts
    {
      escrow-balance: escrow-stx-balance,
      crowdfunding-balance: crowdfunding-stx-balance,
      rewards-balance: rewards-stx-balance,
      hub-balance: hub-stx-balance,
      total-recoverable-balance: total-recoverable-stx
    }
    

  )
)



;; Helper function to get the actual STX balance of a specific module
  ;; @func: allows explicit confirmation that a module (or any address) has (or doesn't have) funds. It's a transparency tool for admins or auditors 
  ;; to call it to verify no unexpected funds are "leaking" into other contracts; and if there are any funds in such specific module, we simply can 
  ;; tell how much, therefore, needs to be recovere
  ;; For example, if a bug caused funds to end up in an unintended address, this could detect it without needing a full system scan.
(define-read-only (get-specific-module-recoverable-balance (module-address principal))
  (let 
    (
      ;; Get the actual STX balance held by the specified module contract
        ;; this retrieves any stx balance sitting/hidden in that specific module
      (module-stx-balance (stx-get-balance module-address))
    ) 
     ;; Check that module-address is a valid module - not a BURN-ADDRESS 
    (if (not (is-eq module-address BURN-ADDRESS))
      ;; Return both the "some" balance and whether recovery is possible from this valid module address 
    (some {
      module-balance: module-stx-balance,
      has-balance: (> module-stx-balance u0) ;; returns balance if such amount of stx is greater than u0
     })
      ;; Return "none" for invalid module-address
      none
    )

 )
    
)


;; Get emergency-fund-recovery-log state
(define-read-only (get-fund-recovery-log (fund-recovery-ops-id uint)) 
  (map-get? emergency-fund-recovery-log fund-recovery-ops-id)
)

;; Get emergency-recovery-ops-counter state
(define-read-only (get-fund-recovery-counter)
  (var-get emergency-recovery-ops-counter)
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


;; Public function to dynamically set the verification-mgt extension
(define-public (set-verification-ext (new-module principal))
  (let
    (
      (old-module (var-get verification-mgt-ext))
    )
    ;; Only admin can set escrow module
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR-NOT-AUTHORIZED)

       ;; Prevent setting module to another existing module address
    (asserts! (not (is-our-contract-address new-module)) ERR-INVALID-MODULE)
    
    ;; Update module address
    (var-set verification-mgt-ext new-module)

    ;; Print log for efficient Audit trails
    (print
      {
        event: "module updated",
        module-type: "verification mgt",
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
    (var-set verification-mgt-ext verf-ext)

    ;; Mark platform as initiialized 
    (var-set platform-initialized true)
    (var-set initialization-block-height (some block-height))

    ;; Log successful initialization
    (print
      {
        event: "platform-initialized",
        admin: tx-sender,
        block-height: block-height
      }
    
    )

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


