;; Title: escrow-module
;; Version: 1.0.0
;; Summary: Escrow Module for Secure Fund Management of campaign funds
;; Author: Victor Omenai 
;; Created: 2025
;; version: 1.0.0

;;;; ============= Description ==============
;; Implementation of Escrow module trait
;; Strategic Purpose: Secures and manages campaign funds
;; This addresses the "Key Resources for delivering Value propostion" component of the Business Model Canvas of CineX


;; Import the escrow trait interface to ensure the contract implements required functions
(impl-trait .escrow-module-trait.escrow-trait)

;; Implementing the emergency-module trait (interface) to follow expected emergency rules
(impl-trait .emergency-module-trait.emergency-module-trait)

;; Implementing the emergency-module trait (interface) to follow expected emergency rules
(impl-trait .module-base-trait.module-base-trait)

;; Import emergency module trait for proper emergency operations
(use-trait esc-emergency-module .emergency-module-trait.emergency-module-trait)

;; Import module base trait for standardized module operations
(use-trait esc-module-base .module-base-trait.module-base-trait)




;; ===========  Define custom error codes for standardized error handling
(define-constant ERR-NOT-AUTHORIZED (err u400))  ;; Caller is not authorized 
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u401)) ;; Campaign ID not found
(define-constant ERR-TRANSFER-FAILED (err u402)) ;; STX transfer failed
(define-constant ERR-INSUFFICIENT-BALANCE (err u403)) ;; Not enough funds in escrow
(define-constant ERR-INVALID-AMOUNT (err u404)) 
(define-constant ERR-SYSTEM-PAUSED (err u405))
(define-constant ERR-SYSTEM-NOT-PAUSED (err u406))
(define-constant ERR-INVALID-RECIPIENT (err u407))
(define-constant ERR-MODULE-INACTIVE (err u408)) ;; Module is not active - prevents operations when module disabled
(define-constant ERR-AUTHORIZATiON-EXPIRED (err u409));; Authorization has expired - prevents stale authorization usage
(define-constant ERR-DUPLICATE-AUTHORIZATION (err u409))  ;; Authorization already exists - prevents duplicate auths
(define-constant ERR-INVALID-CAMPAIGN-STATE (err u410));; Campaign in invalid state - ensures campaign validity
(define-constant ERR-BALANCE-OVERFLOW (err u412)) ;; Balance would overflow - prevents arithmetic overflow
(define-constant ERR-BALANCE-UNDERFLOW (err u412)) ;; Balance would underflow - prevents arithmetic underflow
(define-constant ERR-SELF-OPERATION-NOT-ALLOWED (err u413)) ;; Self operations not allowed - prevents self-funding
(define-constant ERR-CAMPAIGN-EXPIRED (err u414)) ;; Campaign has expired - prevents operations on expired campaigns
(define-constant ERR-OPERATION-TIMEOUT (err u415)) ;; Operation has timed out - prevents hanging operations
(define-constant ERR-INVALID-MODULE (err u416)) ;; Invalid module address - prevents invalid module references
(define-constant ERR-EMERGENCY-ONLY (err u417)) ;; Function only available during emergency - restricts emergency functions
(define-constant ERR-RATE-LIMIT-EXCEEDED (err u418)) ;; Too many operations in short time - prevents DOS attacks

;; Constant holding contract-owner principal
(define-constant CONTRACT-OWNER tx-sender)

;; ======== Operations Limit for Security: Constants aligned with main hub 
(define-constant BURN-ADDRESS 'SP000000000000000000002Q6VF78) ;; Burn address to prevent accidental burn

(define-constant MAX-SINGLE-DEPOSIT u100000000000) ;; 100, 000 STX maximum single deposit

(define-constant MIN-DEPOSIT-AMOUNT u1000000) ;; 1 STX minimum deposit - prevents dust attacks

(define-constant MAX-WITHDRAWAL-AMOUNT u100000000000) ;; MAX-WITHDRAWAL-AMOUNT 100,000 STX maximum single withdrawal

(define-constant MIN-WITHDRAWAL-AMOUNT u1000000) ;; MIN-WITHDRAWAL-AMOUNT 1 STX minimum withdrawal - prevents dust operations

(define-constant AUTHORIZATION-TIMEOUT u144) ;; AUTHORIZATION-TMEOUT 144 blocks = ~24 hours - prevents indefinite authorizations

(define-constant EMERGENCY-RECOVERY-LIMIT u100000000000) ;; EMERGENCY-RECOVERY-LIMIT 100,000 STX threshold for emergency recovery



;;;; ======== CONTRACT REFERENCES  ==========
;; Store the principal address of the core contract 
(define-data-var core-contract principal tx-sender)

;;  Contract principal variable as the crowdfunding module contract reference pointing to the crowdfunding contract
(define-data-var crowdfunding-contract principal tx-sender)

;;  Contract principal variable as the escrow module contract reference
(define-data-var escrow-contract principal tx-sender)

;; Contract principal variable as the reward module contract reference
(define-data-var rewards-contract principal tx-sender)

;; Contract principal as the verification module contract reference for campaign validation
(define-data-var verification-contract principal tx-sender)


;;;; ========== EMERGENCY STATE & OPERATION COUNTERS - for Comprehensive tracking and audit ========
;; Variable to hold state of operations  
(define-data-var emergency-pause bool false) ;; - default setting is 'not paused (false)' until when necessary

;; Variable to hold state of module-version  
(define-data-var module-version uint u1) ;; - initialized to the first version (V1) at deployment

;; Variable to hold state of module-active 
(define-data-var module-active bool true) ;; - initialized to true, implying module is actively running

;; Emergency operations counter for audit trail 
(define-data-var emergency-ops-counter uint u0) ;; initialized to u0 at deployment - no audit of emergency operations yet

;; Tracks global total deposits across all campaigns
(define-data-var total-deposit uint u0)

;; Tracks total withdrawals for reconciliation
(define-data-var total-withdrawal uint u0)

;; Tracks total fees collected for transparency
(define-data-var total-fees-collected uint u0)

;; Security tracking for rate limiting and DOS prevention
(define-data-var last-ops-block uint u0) ;; Tracks last operation block for rate limiting

(define-data-var ops-per-block uint u0) ;; Counts operations per block for Denial of Service (DOS) prevention


;;;; ============ DATA MAPS ========

;; Campaign metadata for validation and audit trails
(define-map campaign-metadata { campaign-id: uint } { 
  owner: principal, ;; campaign owner for authorization checks       
  created-at: uint, ;; campaign creation timestamp for audit
  is-active: bool, ;; active status for operation validation
  last-deposit-at: uint, ;; last withdrawal timestamp for activity tracking
  last-withdrawal-at: uint, ;; last withdrawal timestamp for activity tracking
  total-deposited: uint, ;; total deposited for reconciliation 
  total-withdrawn: uint, ;; total withdrawn for reconciliation
   })


;; Mapping to track each campaign's STX funds in escrow
(define-map campaign-escrow-balances uint uint)

;; Emergency operations log for audit trail
(define-map emergency-ops-log { ops-count-id: uint } { 
  emergency-ops-type: (string-ascii 150),
  campaign-id: uint,
  amount: uint,
  recipient: principal,
  admin: principal,
  block-height: uint,
  reason: (string-ascii 100),
  success: bool  
  })


;; Authorization map for withdrawals with expiration and limits
(define-map authorized-withdrawals { campaign-id: uint, requester: principal } {
  authorized: bool, ;; authorization status
  authorized-at: uint, ;; authorization timestamp for audit
  expires-at: uint, ;; expiration to prevent stale authorizations
  max-amount: uint ;; maximum amount limit for security 

})

;; Authorization map for fee collection with expiration and limits
(define-map authorized-fee-collections { campaign-id: uint, requester: principal } {
  authorized: bool, ;; authorization status
  authorized-at: uint, ;; authorization timestamp for audit
  expires-at: uint, ;; expiration to prevent stale authorizations
  max-amount: uint ;; maximum amount limit for security

})

;; Operation history for audit and rate limiting
(define-map rate-limiting-ops-history { campaign-id: uint, block-height: uint } { 
  deposit-count: uint, ;; deposits per block per campaign - for rate limiting
  withdrawal-count: uint, ;; withdrawals per block per campaign for rate limiting
  last-operator: principal ;; last operator for audit trail 
})


;; ========== SECURITY VALIDATION FUNCTIONS ==========
;; Safe add - maths - operations to prevent overflow

(define-private (safe-add (a uint) (b uint)) 
  (let 
    (
      
      (result (+ a b))
    ) 
    ;; Prevent overflow attacks
    (asserts! (>= result a) ERR-BALANCE-OVERFLOW) 
    (ok result)
    
  )

)

;; Safe subtract - maths - operations to prevent overflow
(define-private (safe-subtract (a uint) (b uint))
  (let 
    (
      (result (- a b))
    ) 
    ;; Prevent underflow attacks
    (asserts! (>= a b ) ERR-BALANCE-UNDERFLOW)
    (ok result)

    
  )

  
)


;; System-Pause Validation - checks that system is operational
(define-private (check-system-operational)
  (begin 
    (asserts! (not (var-get emergency-pause)) ERR-SYSTEM-PAUSED) ;; Ensures system not paused
    (asserts! (var-get module-active) ERR-MODULE-INACTIVE) ;; Ensures module is active
    (ok true)
  )
  
)


;; Comprehensive principal validation - ensuring address of module is not a wrong address
(define-private (is-valid-module (address principal))
  (and 
    (not (is-eq address BURN-ADDRESS)) ;; Ensure it's not BURN-ADDRESS
    (not (is-eq address CONTRACT-OWNER)) ;; Ensure it's not CONTRACT-OWNER
    (not (is-eq address (as-contract tx-sender))) ;; Ensure it's not the platform principal directly
    (not (is-eq address (var-get core-contract))) ;; Ensure it's not the core contract - that is, the main entry point 
  
  )
)

;; Rate limiting check function to prevent DOS attacks
(define-private (check-rate-limit)
  (let 
    (
      ;; Get block when last ops was done
      (last-ops (var-get last-ops-block))

      ;; Get running ops count  
      (ops-current-count (var-get ops-per-block))
      (next-ops-count (+ u1 ops-current-count))
    ) 
    ;; Check if last-ops is-eq block-height
    (if (is-eq last-ops block-height) 
      ;; then 
      (begin 
        ;; Ensure that ops-current-count is < u10 per block of 10 minutes, else trigger error - prevents spam
        (asserts! (< ops-current-count u10) ERR-RATE-LIMIT-EXCEEDED)
    
        ;; Update/Increment ops-per-block with/by next-ops-count
        (var-set ops-per-block next-ops-count)
        

      ) 
      ;; else - with no last-ops block  
      (begin 
        ;; Update last-ops block with new current block-height
        (var-set last-ops-block block-height)
      
        ;; Increment ops-per-block with/by next count u1
        (var-set ops-per-block u1)
        
      )
    )

    (ok true)

  )
  
)

;; Validate campaign exists and is active
(define-private (validate-campaign-active (campaign-id uint)) 
  (match (map-get? campaign-metadata { campaign-id: campaign-id }) 
    campaign (begin 
                (asserts! (get is-active campaign) ERR-INVALID-CAMPAIGN-STATE)
                (ok campaign)
    
            ) 
    
    ERR-CAMPAIGN-NOT-FOUND)

)




;; ========== CORE ESCROW FUNCTIONS ==========

;; Public function: Allows any user to deposit funds into a campaign's escrow balance
(define-public (deposit-to-campaign (campaign-id uint) (amount uint))
  (let
    (
      ;; Retrieve current campaign escrow balance, defaulting to 0 if campaign does not exist yet
      (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))
      ;; Calculate the new balance after deposit
      (new-balance (+ current-balance amount))

      ;; Retrieve campaign metadata,defaulting its values as follows if campaign metadata does not exist
      (campaign-meta (unwrap! (validate-campaign-active campaign-id) ERR-CAMPAIGN-NOT-FOUND))

      ;; Get current rate limiting ops history
      (current-rate-limiting-ops (default-to 
        { deposit-count: u0, withdrawal-count: u0, last-operator: tx-sender } 
          (map-get? rate-limiting-ops-history { campaign-id: campaign-id, block-height: block-height }))
      )

      ;; Retrieve deposit count from current rate limiting ops,and calculate next deposit count
      (current-deposit-count (get deposit-count current-rate-limiting-ops))
      (next-deposit-count (+ current-deposit-count u1))

      ;; Retrieve current total deposited per campaign meta
      (current-campaign-deposit (get total-deposited campaign-meta))

      ;; Get campaign meta owner
      (owner-campaign-meta (get owner campaign-meta))

      ;; Retrieve global total deposits across all campaigns
      (current-global-deposits (var-get total-deposit))

      ;; Calculate the new campaign escrow balance after user adds amount to current-balance.
        ;; If safe-add succeeds, new-balance gets the sum. If it fails (overflow), the contract triggers error and stops.
      (new-escrow-balance (unwrap! (safe-add current-balance amount) ERR-BALANCE-OVERFLOW))

      ;; Update the total deposits for a specific campaign, unwrapping the result or throw an error on overflow.
      (new-campaign-deposit-total (unwrap! (safe-add current-campaign-deposit amount) ERR-BALANCE-OVERFLOW))

      ;; Update the global total deposits across all campaigns, equally unwrapping the result or handling overflow.
      (new-global-deposit-total (unwrap! (safe-add current-global-deposits amount) ERR-BALANCE-OVERFLOW))


    )
    ;; Ensure system is operational
    (try! (check-system-operational))

    ;; Prevent DOS attacks
    (try! (check-rate-limit))

    ;; Validate sender
    (asserts! (is-valid-module tx-sender) ERR-INVALID-RECIPIENT)

    ;; Validate amount
    (asserts! (and (>= amount MIN-DEPOSIT-AMOUNT) (<= amount MAX-SINGLE-DEPOSIT)) ERR-INVALID-AMOUNT)

    ;; Prevent self funding by owner of campaign
    (asserts! (not (is-eq tx-sender owner-campaign-meta)) ERR-SELF-OPERATION-NOT-ALLOWED)

    ;; Transfer the STX from sender to contract address
    (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) ERR-TRANSFER-FAILED)
    
    ;; Update the escrow balance with new-balance for the campaign
    (map-set campaign-escrow-balances campaign-id new-balance)

    ;; Update campaign meta data with trail of the recent last-deposit, and total deposit forthis unique campaign
    (map-set campaign-metadata { campaign-id: campaign-id } 
    
    (merge campaign-meta {
      last-deposit-at: block-height,;; Track last deposit activity
      total-deposited: new-campaign-deposit-total ;; Track total unique campaign deposit 
    }))

    ;; Update global total deposit counters for system tracking 
    (var-set total-deposit new-global-deposit-total)

    ;; Update rate-limiting-ops history with incremented deposit coutn and last operator's tx-sender
    (map-set rate-limiting-ops-history { campaign-id: campaign-id, block-height: block-height } 
      (merge current-rate-limiting-ops {
        deposit-count: next-deposit-count,   ;; Increment deposit count
        last-operator: tx-sender
      } 

      )
    
    )

      ;; Print log for efficient Audit trails
      (print
        {
          event: "deposit successful",
          campaign-id: campaign-id,
          depositor: tx-sender,
          amount: amount,
          new-balance: new-balance,
          block-height: block-height
        }
      
      )
    
    (ok true)
  )
)

;; TO-DO-LIST === all functions in comments will be re-visited to reflect the edge-case improvements that have been effected
  ;; in the lines of code preceding these commented-out functions


;; Core contract authorizes withdrawal
;; (define-public (authorize-withdrawal (campaign-id uint) (new-requester principal))
;;  (begin 
    ;; Ensure Only core contract can authorize withdrawals
 ;;   (asserts! (is-eq tx-sender (var-get core-contract)) ERR-NOT-AUTHORIZED)
  ;;  (map-set authorized-withdrawals { campaign-id: campaign-id, requester: new-requester } 
  ;;    authorized: bool, ;; authorization status
  ;;    authorized-at: uint, ;; authorization timestamp for audit
  ;;    expires-at: uint, ;; expiration to prevent stale authorizations
  ;;    max-amount: uint ;; maximum amount limit for security 

    
    
  ;;  )
  ;;  (ok true)  
  
  ;;)

;;)

;; Core contract authorizes fee collection
;;(define-public (authorize-fee-collection (campaign-id uint) (requester principal))
 ;; (begin 
    ;; Ensure only core contract can authorize fee collection
   ;; (asserts! (is-eq tx-sender (var-get core-contract)) ERR-NOT-AUTHORIZED)
    ;;(map-set authorized-fee-collections { campaign-id: campaign-id, requester: requester } true)
    ;;(ok true)
     
 ;; )
;;)



;; Public function: Allows the campaign owner to withdraw a specified amount from escrow
;; (define-public (withdraw-from-campaign (campaign-id uint) (amount uint))
;;  (let
 ;;   (
      ;; Retrieve current balance
 ;;     (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))

      ;; Check authorization from authorize-withdrawal map, else default to false
  ;;    (is-withdrawal-authorized (default-to true (map-get? authorized-withdrawals { campaign-id: campaign-id, requester: tx-sender })))

      ;; Calculate the new balance after withdrawal
 ;;     (new-balance (- current-balance amount))

 ;;   )
      ;; Ensure caller is authorized core for withdrawal 
 ;;     (asserts! is-withdrawal-authorized ERR-NOT-AUTHORIZED)

      ;; Ensure there are enough funds to withdraw
;;      (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
    
      ;; Update the escrow balance
;;      (map-set campaign-escrow-balances campaign-id new-balance)
    
      ;; Transfer the withdrawn amount to the authorized requester
;;      (unwrap! (stx-transfer? amount (as-contract tx-sender) tx-sender) ERR-TRANSFER-FAILED)
    
      ;; Clear authorization after successful withdrawal
 ;;     (map-delete authorized-withdrawals { campaign-id: campaign-id, requester: tx-sender })
 ;;     (ok true)
 ;; )
;;)

;; Public function: Allows the campaign owner to pay a fee from the campaign's escrowed funds to the core contract
;; (define-public (collect-campaign-fee (campaign-id uint) (fee-amount uint))
 ;; (let
  ;;  (
      ;; Retrieve current balance
  ;;    (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))

      ;; Check authorization from authorize-fee-collection map, else default to false
  ;;    (is-fee-collection-authorized (default-to false (map-get? authorized-fee-collections { campaign-id: campaign-id, requester: tx-sender })))

      ;; Calculate the new balance after fee deduction
  ;;    (new-balance (- current-balance fee-amount))

      ;;Get core-contract
   ;;   (authorized-core-contract (var-get core-contract))
   ;; )
      ;; Ensure caller is authorized core for fee-collection-authorized
   ;;   (asserts! is-fee-collection-authorized ERR-NOT-AUTHORIZED)

      ;; Ensure there are enough funds to cover the fee
    ;;  (asserts! (>= current-balance fee-amount) ERR-INSUFFICIENT-BALANCE)
    
      ;; Update the escrow balance
  ;;    (map-set campaign-escrow-balances campaign-id new-balance)
    
      ;; Transfer the fee amount to the core contract address
  ;;    (unwrap! (stx-transfer? fee-amount (as-contract tx-sender) authorized-core-contract) ERR-TRANSFER-FAILED)

      ;;  Clear authorization after successful fee collection
 ;;     (map-delete authorized-fee-collections { campaign-id: campaign-id, requester: tx-sender })
    
   ;;   (ok true)
;;  )
;;)

;; Read-only function: Fetches the current escrow balance for a given campaign
(define-read-only (get-campaign-balance (campaign-id uint))
  ;; default-to zero if optional-value of campaign-balance is none 
  (ok (default-to u0 (map-get? campaign-escrow-balances campaign-id)))
)

;; Public function: One-time initializer to set the core contract address, as well as the crowdfunding and escrow contract addresses
;; Purpose: Can only be called once by the contract owner (tx-sender at deployment) to handle initial bootstrapping
(define-public (initialize (core principal) (crowdfunding principal) (escrow principal))
  (begin
    ;; Ensure that only the contract owner can initialize
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; Set the core-contract variable
    (var-set core-contract core)
    (var-set crowdfunding-contract crowdfunding)
    (var-set escrow-contract escrow )
    (ok true)
  )
)

;; Set the crowdfunding-contract 
;; Purpose: Dynamic module replacement
(define-public (set-crowdfunding (crowdfunding principal))
  (begin 
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set crowdfunding-contract crowdfunding)
    (ok true)
  )   
)


;; Set the escrow-contract 
;; Purpose: Dynamic module replacement
(define-public (set-escrow (escrow principal))
  (begin 
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set escrow-contract escrow)
    (ok true)
  )   
)


;; ========== EMERGENCY PAUSE MANAGEMENT FUNCTIONS ==========
;; Function to allow only core contract to set pause state
(define-public (set-pause-state (pause bool))
  (let 
    (
      ;; Get hub 
      (cinex-hub (var-get core-contract))
    ) 
    ;; Only core contract can set pause state
    (asserts! (is-eq contract-caller cinex-hub) ERR-NOT-AUTHORIZED)

    ;; Ensure system is not paused
    (asserts! (check-system-not-paused) ERR-SYSTEM-PAUSED)

    ;; Set the system-paused to pause
    (var-set emergency-pause pause)

    ;; Print log for efficient Audit trails
    (print 
       {
        event: "pause-state-changed",
        new-state: pause,
        caller: contract-caller,
        block-height: block-height

       }
    
    
    )
     
    
    (ok true) 
  )
)

;; Helper function to check system-not-paused
(define-private (check-system-not-paused)
  (let 
    (
      ;; Get system-paused state
      (current-system-paused-state (var-get emergency-pause))
    ) 
    (not current-system-paused-state)
  )
)

;; Get system-paused status
(define-read-only (is-system-paused) 
  (var-get emergency-pause)
)

;; Function to implement emergency withdraw
(define-public (emergency-withdraw (amount uint) (recipient principal))
  (let 
    (
      ;; Get current contract's balance 
      (current-contract-balance (stx-get-balance (as-contract tx-sender)))

      ;; Get current emergency-ops counter, and consequently its next-emergency-ops counter to track state of a new emergency operation
      (current-emergency-ops-counter (var-get emergency-ops-counter))
      (next-emergency-ops-count (+ current-emergency-ops-counter u1))

    )

    ;; Ensure only core contract can call this emergency withdraw function
    (asserts! (is-eq contract-caller (var-get core-contract)) ERR-NOT-AUTHORIZED)

    ;; Ensure system must be paused before emergency withdrawal
    (asserts! (var-get emergency-pause) ERR-SYSTEM-NOT-PAUSED)

    ;; Ensure amount to be withdrawn is > u0
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)

    ;; Ensure amount to be withdrawn is <= current-balance, else trigger INSUFFICIENT FUNDS
    (asserts! (<= amount current-contract-balance) ERR-INSUFFICIENT-BALANCE)

    ;; Ensure contract is not BURN-ADDRESS, is not CONTRACT-OWNER, and, is not also of this contract principal
    (asserts! (and 
                (not (is-eq contract-caller BURN-ADDRESS)) 
                (not (is-eq contract-caller CONTRACT-OWNER)) 
                (not (is-eq contract-caller (as-contract tx-sender))) 
              )
                ERR-INVALID-RECIPIENT)

    ;; Update emergency-ops state map
    (map-set emergency-ops-log { ops-count-id: next-emergency-ops-count } { 
      emergency-ops-type: "emergency ops withdraw",
      campaign-id: u0, ;; no specific campaign-id foremergency withdrawal
      amount: amount,
      recipient: recipient,
      admin: contract-caller,
      block-height: block-height,
      reason: "emergency funds recovery",
      success: true 
    })

    ;; Update emergency ops counter with new emergency ops count
    (var-set emergency-ops-counter next-emergency-ops-count)

    ;; Perform emergency withdrawal
    (unwrap! (stx-transfer? amount (as-contract tx-sender) recipient) ERR-TRANSFER-FAILED)

    ;; Print log for efficient Audit trails
    (print 
        {
        event: "emergency withdrawal",
        operation-id: next-emergency-ops-count,
        amount: amount,
        recipient: recipient,
        admin: contract-caller,
        block-height: block-height

      }
    
    )

    (ok true)

  )  
    
      
)

