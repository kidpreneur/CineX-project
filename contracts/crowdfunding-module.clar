;; title: crowdfunding-module
;; version: 1.0.0
;; implements: .crowdfunding-module-traits.crowdfunding-trait
;; Author: Victor Omenai 
;; Created: 2025

;;;; ============= Description ==============
;; Implementation of Crowdfunding module trait
;; Strategic Purpose: Standardize campaign processes as backers interact with the system, contributing funds
;; This addresses the "Revenue Streams & Customer Relationships" component of the Business Model Canvas of CineX


;; Implementing the crowdfunding trait (interface) to follow expected rules
(impl-trait .crowdfunding-module-traits.crowdfunding-trait) 

;; Import emergency module trait for proper emergency operations
(use-trait crwd-emergency-module .emergency-module-trait.emergency-module-trait)

;; Import module base trait for standardized module operations
(use-trait crwd-module-base .module-base-trait.module-base-trait)


;; ===== Core Settings for Module Contract References =====

;; Save the core contract that can control this module (e.g., for upgrades)
(define-data-var core-contract principal tx-sender) 

;; Add variable to store address of Verification Module
(define-data-var verification-contract principal tx-sender)

;; Add Variable to store address of Escrow module
(define-data-var escrow-contract principal tx-sender)

;;;; ===== CONSTANTS =====

;; Constant holding contract-owner principal - set at deployment
(define-constant CONTRACT-OWNER tx-sender)

;; Security constants aligned with main hub 
(define-constant BURN-ADDRESS 'SP000000000000000000002Q6VF78) ;; Burn address to prevent accidental burn

;; Campaign operation constants
(define-constant CAMPAIGN-FEE u50000000) ;; 5 STX - Fixed fee (in microstacks) to create a new campaign
(define-constant MIN-FUNDING u1000000) ;; 1 STX - Minimum amount that can be raised
(define-constant MAX-FUNDING u100000000000) ;; 100 000 STX - Maximum amount that can be raised
(define-constant WITHDRAWAL-FEE-PERCENT u5) ;; Platform takes a 5% fee from funds when a campaign owner withdraw 
(define-constant MAX-REWARD-TIERS u10) ;; Maximum 10 reward tiers
(define-constant MAX-TIER-DESC-LENGTH u500) ;; Maximum description length for reward tiers 
(define-constant MIN-CAMPAIGN-DURATION u4320) ;; 30 days: 43,200 min / 10 min per block = 4320 blocks
(define-constant DEFAULT-CAMPAIGN-DURATION u8640) ;; If no custom duration is set, campaigns will last about 3 months (~12960 blocks)


;;;; ===== ERROR CODE CONSTANTS =====
;; Predefined error messages for different failure situations
(define-constant ERR-NOT-AUTHORIZED (err u300)) 
(define-constant ERR-INVALID-AMOUNT (err u301)) 
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u302))
(define-constant ERR-CAMPAIGN-INACTIVE (err u303))
(define-constant ERR-FUNDING-GOAL-NOT-REACHED (err u304))
(define-constant ERR-ALREADY-CLAIMED (err u305))
(define-constant ERR-TRANSFER-FAILED (err u306))
(define-constant ERR-ESCROW-BALANCE-NOT-FOUND (err u307))
(define-constant ERR-INVALID-VERIFICATION-LEVEL-INPUT (err u308))
(define-constant ERR-NO-VERIFICATION (err u309))
(define-constant ERR-SYSTEM-PAUSED (err u310))
(define-constant ERR-SYSTEM-NOT-PAUSED (err u311))
(define-constant ERR-MODULE-INACTIVE (err u312))
(define-constant ERR-INVALID-RECIPIENT (err u313))
(define-constant ERR-INSUFFICIENT-FUNDS (err u314))
(define-constant ERR-CAMPAIGN-EXPIRED (err u315))
(define-constant ERR-INVALID-DURATION (err u316))
(define-constant ERR-INVALID-DESCRIPTION (err u317)) 
(define-constant ERR-INVALID-REWARD-TIERS (err u318)) 
(define-constant ERR-FUNDING-GOAL-EXCEEDED (err u319))
(define-constant ERR-DUPLICATE-CONTRIBUTION (err u320))
(define-constant ERR-SELF-CONTRIBUTION-NOT-ALLOWED (err u321))



;; ===== STATE VARIABLES =====

;; Counter for assigning a new unique ID to each campaign
(define-data-var unique-campaign-id uint u0)

;; Tracks all fees collected by the platform
(define-data-var total-fees-collected uint u0)

;; Emergency operations counter for audit trail 
(define-data-var emergency-ops-counter uint u0) ;; initialized to u0 at deployment - no audit of emergency operations yet

;;;; ========== Emergency State ========
;; Variable to hold state of operations 'not paused (false)' until when necessary 
(define-data-var emergency-pause bool false)

;; Variable to hold state of module-version - initialized to the first version (V1) at deployment 
(define-data-var module-version uint u1)

;; Variable to hold state of module-active - initialized to true, implying module is actively running
(define-data-var module-active bool true)



;; ===== DATA MAPS =====

;; Stores details for each crowdfunding campaign
(define-map campaigns uint {
  description: (string-ascii 500), ;; Text description of the project
  funding-goal: uint, ;; Target amount to raise
  duration: uint, ;; How long the campaign lasts (in blocks)
  created-at: uint, ;; When the campaign was created (block height)
  owner: principal, ;; Address of the campaign creator
  reward-tiers: uint, ;; Number of reward options
  reward-description: (string-ascii 150), ;; Description of rewards
  total-raised: uint, ;; Total money raised so far
  is-active: bool, ;; True if still running, false if closed
  funds-claimed: bool, ;; True if owner has withdrawn funds
  is-verified: bool, ;; verification status
  verification-level: uint, ;; uint to track filmmaker as level 1 or 2 verified
  expires-at: uint,;; for expiration tracking 
  last-activity-at: uint;; last activity monitoring 
})

;; Tracks each contributor's activity for each campaign
(define-map campaign-contributions { campaign-id: uint, contributor: principal } {
  total-contributed: uint, ;; Total amount this user gave
  contributions-count: uint, ;; Number of times they contributed
  first-contribution-at: uint, ;; backer's initial contribution (block-height)
  last-contribution-at: uint ;; When they last contributed (block-height)
})

;; Emergency operations log for audit trail
(define-map emergency-ops-log { ops-count-id: uint } { 
  emergency-ops-type: (string-ascii 150),
  recipient: principal,
  admin: principal,
  block-height: uint,
  reason: (string-ascii 100) 
  })





;; ========== SECURITY VALIDATION HELPER FUNCTIONS ==========

;; System-Pause Validation - checks that system is operational
(define-private (check-system-operational)
  (begin 
    (asserts! (not (var-get emergency-pause)) ERR-SYSTEM-PAUSED)
    (ok true)
  )
  
)

;; System-Active Validation - check that module is active
(define-private (check-module-active)
  (begin 
    (asserts! (var-get module-active) ERR-MODULE-INACTIVE)
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

;; Validate campaign creation parameters  
(define-private (validate-campaign-params (description (string-ascii 500)) 
  (funding-goal uint)
  (duration uint)
  (reward-tiers uint)
  (reward-description (string-ascii 150)))
  (begin  
    ;; Validate description len is greater than u0
    (asserts! (> (len description) u0) ERR-INVALID-DESCRIPTION)

    ;; Validate that funding goal is >= MIN-FUNDING or is <= MAX-FUNDING
    (asserts! (or (>= funding-goal MIN-FUNDING) (<= funding-goal MAX-FUNDING)) ERR-INVALID-AMOUNT)

    ;; Validate that duration is >= MIN-CAMPAIGN-DURATION or is <= DEFAULT-CAMPAIGN-DURATION, else trigger ERR-INVALID-DURATION 
    (asserts! (or (>= duration MIN-CAMPAIGN-DURATION) (<= duration DEFAULT-CAMPAIGN-DURATION)) ERR-INVALID-DURATION)

    ;; Ensure reward-tiers is > u0, and that it is also <= MAX-REWARD-TIERS, else trigger ERR-INVALID-REWARD-TIERS
    (asserts! (and (> reward-tiers u0) (<= reward-tiers MAX-REWARD-TIERS)) ERR-INVALID-REWARD-TIERS)

    (ok true)

        
  )
  
  
)
  

;; Check if campaign has expired
(define-private (is-campaign-expired (campaign-id uint)) 
  (match (map-get? campaigns campaign-id) campaign 
    (let 
      (
        ;; Get current campaign expiration time 
        (expires-at (get expires-at campaign))
      ) 

      ;; Ensure expiration is set at block-height >= expiration time of current campaign

      (>= block-height expires-at)

    ) 
  ;; else, it's false
    false
  )

)


;; ===== CORE CAMPAIGN PUBLIC FUNCTIONS =====
;;  Create a Campaign =====

(define-public (create-campaign (description (string-ascii 500)) 
  (campaign-id uint) 
  (funding-goal uint) 
  (duration uint) 
  (reward-tiers uint) 
  (reward-description (string-ascii 150)))
  (let
    (
      ;; Get current unique campaign id
      (current-unique-campaign-id (var-get unique-campaign-id))  

      ;; Set new campaign ID by adding 1 to the current counter
      (next-unique-campaign-id (+ current-unique-campaign-id u1)) 

      ;; === Duration Handling
                                ;; If campaign creator inputs a custom `duration` variable, i.e, anything >= MINIMUM DURATION and < DEFAULT DURATION 
      (effective-duration (if (and (>= duration MIN-CAMPAIGN-DURATION) 
                                  (< duration DEFAULT-CAMPAIGN-DURATION)) 
                                duration ;; let that custom duration pass
                                DEFAULT-CAMPAIGN-DURATION ;; else, use DEFAULT-CAMPAIGN-DURATION u8640 
                          )
        )

      ;; === Fee management
          ;; Get total-fees-collected
      (existing-total-fees-collected (var-get total-fees-collected))
      
      ;; Calculate updated total-fees-collected
      (new-total-fees-collected (+ existing-total-fees-collected CAMPAIGN-FEE))

      ;; === Contract references
          ;; Get core-contract
      (authorized-core-contract (var-get core-contract))

      ;; === Check verification status with proper error handling
      (verification-result (unwrap! (contract-call? .film-verification-module is-filmmaker-currently-verified tx-sender) ERR-NO-VERIFICATION))

      ;; Check existing filmmaker identities, and current verification level
      (current-identities (unwrap! (contract-call? .film-verification-module get-filmmaker-identity tx-sender) ERR-NO-VERIFICATION))
      (current-verification-level (get choice-verification-level current-identities))
      
      ;; Get is-verified, if true, return "verified", else, Default to "not verified"
      (is-verified (if (is-eq verification-result true) 
                          true 
                          false))

      ;; Default to level 0 if there's no verification level 
      (existing-verification-level (if (and (is-some current-verification-level) (is-eq is-verified true)) 
                                          (unwrap! current-verification-level ERR-INVALID-VERIFICATION-LEVEL-INPUT) 
                                          u0))

    )

    ;; Validate overall system is operational before trying to create campaigns
    (try! (check-system-operational))

    ;; Validate module is equally active 
    (try! (check-module-active)) 

    ;; Ensure module's address is not an invalid tx-sender
    (asserts! (is-valid-module tx-sender) ERR-INVALID-RECIPIENT)
    
    ;; Validate campaign creation params 
    (try! (validate-campaign-params description funding-goal duration reward-tiers reward-description))

    ;; Take the campaign creation fee from the creator and send to core contract
    (unwrap! (stx-transfer? CAMPAIGN-FEE tx-sender authorized-core-contract) ERR-TRANSFER-FAILED)
    
    ;; Add collected fee to total fees tracker
    (var-set total-fees-collected new-total-fees-collected)
    
    ;; Save the new campaign in the map
    (map-set campaigns campaign-id {
      description: description,
      funding-goal: funding-goal,
      duration: effective-duration,
      created-at: block-height, ;; block-height automatically is set 
      owner: tx-sender,
      reward-tiers: reward-tiers,
      reward-description: reward-description,
      total-raised: u0, ;; campaign just set up, hence total funds raised is zero
      is-active: true, ;; campaign now runs
      funds-claimed: false, ;; nothing yet claimed 
      is-verified: is-verified, ;; update the verification-status, whether true or false
      verification-level: existing-verification-level, ;; update the verification level whether there is-some or is-none
      expires-at: (+ block-height effective-duration),;; for expiration tracking 
      last-activity-at: block-height;; last activity monitoring 
    })
    
    ;; Update the campaign counter
    (var-set unique-campaign-id next-unique-campaign-id)

    ;; Print log for efficient Audit trail
    (print {
      event: "campaign-created",
      campaign-id: next-unique-campaign-id,
      owner: tx-sender,
      funding-goal: funding-goal,
      duration: duration,
      is-verified: is-verified,
      block-height: block-height

    })
    
    ;; Return the new campaign ID to the creator
    (ok next-unique-campaign-id)
  )
)

;; ========== CONTRIBUTE TO A CAMPAIGN ==========

(define-public (contribute-to-campaign (campaign-id uint) (amount uint))
  (let
    (
        ;; Try to fetch campaign details
        (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))
      
        ;; Get the escrow balance from the campaign-escrow-balances map of the escrow-module contract
        (escrow-balance (unwrap! (contract-call? .escrow-module get-campaign-balance campaign-id) ERR-ESCROW-BALANCE-NOT-FOUND))
      
        ;; Try to get existing contribution, or default to zero if none
        (existing-contribution (default-to 
                                  { 
                                    total-contributed: u0, 
                                    contributions-count: u0, 
                                    first-contribution-at: u0,
                                    last-contribution-at: u0 
                                  } 
                                    (map-get? campaign-contributions { campaign-id: campaign-id, contributor: tx-sender }))
        )

        ;; Get first contribution block-height from campaign contribution
        (first-contribution-time (get first-contribution-at existing-contribution))

        ;; Get current-total-raised
        (current-total-raised (get total-raised campaign))

        ;; Get funding-goal
        (current-funding-goal (get funding-goal campaign))

        ;; Calculate new total-raised
        (new-total-raised (+ current-total-raised amount)) 

        ;; Get current-total-contributed funds
        (current-total-contributed (get total-contributed existing-contribution))

        ;; Get new contributions
        (new-total-contributed (+ current-total-contributed amount))

        ;; Get current contributions-count
        (current-contributions-count (get contributions-count existing-contribution ))

        ;; Calculate new count
        (new-count (+ current-contributions-count u1))

        ;; Get initial first contribution , validly at u0, since contribution is not yet made
        (is-first-contribution (is-eq current-contributions-count u0))

    )
      ;; Validate overall system is operational before trying to create campaigns
      (try! (check-system-operational))

      ;; Validate module is equally active
      (try! (check-module-active))

      ;; Ensure module's address is not an invalid tx-sender
      (asserts! (is-valid-module tx-sender) ERR-INVALID-RECIPIENT)      

      ;; Enusre tx-sender is not contract-owner
      (asserts! (not (is-eq tx-sender CONTRACT-OWNER)) ERR-SELF-CONTRIBUTION-NOT-ALLOWED)

      ;; Make sure campaign is active, and that, consequently, campaign has not expired
      (asserts! (get is-active campaign) ERR-CAMPAIGN-INACTIVE)
      (asserts! (not (is-campaign-expired campaign-id)) ERR-CAMPAIGN-EXPIRED)
    
      ;; Make sure contribution amount is high enough - at least >= MIN-FUNDING, OR <= MAX-FUNDING
      (asserts! (or (>= amount MIN-FUNDING) (<= amount MAX-FUNDING)) ERR-INVALID-AMOUNT)

      ;; Ensure current total raised funds is <= funding-goal
      (asserts! (<= new-total-raised current-funding-goal) ERR-FUNDING-GOAL-EXCEEDED)
      
      ;; Move funds into escrow (secure temporary storage)
      (unwrap! (contract-call? .escrow-module deposit-to-campaign campaign-id amount) ERR-TRANSFER-FAILED)
    
      ;; Increase campaign's total raised amount
      (map-set campaigns campaign-id 
        (merge 
          campaign 
            { 
              total-raised: new-total-raised, 
              last-activity-at: block-height
            }
        )
      )

      ;; Update record of contributor
      (map-set campaign-contributions { campaign-id: campaign-id, contributor: tx-sender } {
        total-contributed: new-total-contributed,
        contributions-count: new-count,
        first-contribution-at: (if is-first-contribution 
                                    ;; return timestamp of this first contribution
                                  block-height 
                                  ;; else, fetch from the campaign-contributions state, the old timestamp when first contribution occured
                                  first-contribution-time
                                ),
        last-contribution-at: block-height
      })

      ;; Print log for efficient Audit trails
      (print 
        {
          event: "contribution made",
          campaign-id: campaign-id,
          contributor: tx-sender,
          amount: amount,
          new-total-raised: new-total-raised,
          contribution-count: new-count,
          block-height: block-height
        
        }
      )
    
      (ok true)
  )
)

;; ========== CLAIM FUNDS AFTER SUCCESSFUL CAMPAIGN ==========

;; Authorization by core contract to claim campaign funds 
(define-public (claim-campaign-funds (campaign-id uint))
  (let
    (
      ;; Load campaign details
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))

      ;; Verify caller is authorized core contract
      (authorized-core-contract (var-get core-contract))
      
      ;; Extract necessary details
      (current-total-raised (get total-raised campaign))
      (current-funding-goal (get funding-goal campaign))
      (current-owner (get owner campaign))
      
      ;; Calculate fee and final amount to withdraw
      (fee-amount (/ (* current-total-raised WITHDRAWAL-FEE-PERCENT) u100)) ;; deduction of 5% withdrawal-fee from total-raised money
      (withdraw-amount (- current-total-raised fee-amount)) ;; campaign-owner withdraws total-raised funds minus deduction of 7% 

      ;; Get existing total-fees-collected
      (existing-total-fees-collected (var-get total-fees-collected))

      ;; Calculate new fee added to existing total fees collected
      (new-collected-fee (+ existing-total-fees-collected fee-amount))


    )

    ;; Validate overall system is operational before trying to create campaigns
    (try! (check-system-operational))

    ;; Validate module is equally active 
    (try! (check-module-active)) 
    
    ;; Ensure only core contract can call this function
    (asserts! (is-eq tx-sender authorized-core-contract) ERR-NOT-AUTHORIZED)

    ;; Ensure campaign is still active
    (asserts! (get is-active campaign) ERR-CAMPAIGN-INACTIVE)
    
    ;; Make sure funds have not been claimed already
    (asserts! (not (get funds-claimed campaign)) ERR-ALREADY-CLAIMED)
    
    ;; Only allow claim if funding goal was reached
    (asserts! (>= current-total-raised current-funding-goal) ERR-FUNDING-GOAL-NOT-REACHED)
    
    ;; Mark campaign as completed
    (map-set campaigns campaign-id 
      (merge 
        campaign 
          { 
            funds-claimed: true,
            is-active: false,
            last-activity-at: block-height
          })
      )
    
      ;; Withdraw the earned funds minus fees since core contract already authorized these operations in escrow
      (unwrap! (contract-call? .escrow-module withdraw-from-campaign campaign-id withdraw-amount) ERR-TRANSFER-FAILED)
     
      ;; Transfer platform's fee   
      (unwrap! (contract-call? .escrow-module collect-campaign-fee campaign-id fee-amount) ERR-TRANSFER-FAILED)
    
      ;; Track the collected fee
      (var-set total-fees-collected new-collected-fee)
    
    ;; Print log for efficient Audit trails
    (print {
      event: "funds-claimed",
      campaign-id: campaign-id,
      owner: current-owner,
      total-raised: current-total-raised,
      owner-withdrawable-amount: withdraw-amount,
      commission: fee-amount,
      block-height: block-height

    })
    (ok true)
  )
)

;; ========== VIEW A CAMPAIGN'S DETAILS ==========

(define-read-only (get-campaign (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, return the campaign details
    campaign (ok {
      description: (get description campaign),
      funding-goal: (get funding-goal campaign),
      duration: (get duration campaign),
      owner: (get owner campaign),
      reward-tiers: (get reward-tiers campaign),
      reward-description: (get reward-description campaign),
      total-raised: (get total-raised campaign),
      is-active: (get is-active campaign),
      funds-claimed: (get funds-claimed campaign),
      is-verified: (get is-verified campaign),
      verification-level: (get verification-level campaign),
      expires-at: (get expires-at campaign),
      last-activity-at: (get last-activity-at campaign)
    } )
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)

;; Ensure campaign is-active
(define-read-only (is-active-campaign (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, 
    campaign (ok (and 
                      ;; return campaign active status, provided the campaign has not expired
                    (get is-active campaign) (not (is-campaign-expired campaign-id)) 
                  ))
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)

;; Get campaign funding goal
(define-read-only (get-campaign-funding-goal (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, return the campaign details
    campaign (ok (get funding-goal campaign))
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)

;; Get campaign total-raised-funds
(define-read-only (get-total-raised-funds (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, return the campaign details
    campaign (ok (get total-raised campaign))
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)

;; Get campaign owner
(define-read-only (get-campaign-owner (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, return the campaign details
    campaign (ok (get owner campaign))
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)


;; Get filmmaker verification information for a campaign
(define-read-only (get-filmmaker-verification (campaign-id uint)) 
  (match (map-get? campaigns campaign-id) 
    campaign (some (get is-verified campaign)) 
    none
  )
  
)

;; Get emergency operation details
(define-read-only (get-emergency-ops-log (ops-id uint))
  (map-get? emergency-ops-log { ops-count-id: ops-id })
)


;; Contribution details for transparency
(define-read-only (get-campaign-contributions (campaign-id uint) (contributor principal)) 
  (map-get? campaign-contributions { campaign-id: campaign-id, contributor: contributor })
)

;; Get System Status 
(define-read-only (module-status) 
  {
    version: (var-get module-version),
    active: (var-get module-active),
    paused: (var-get emergency-pause),
    total-campaigns: (var-get unique-campaign-id),
    total-fees-collected: (var-get total-fees-collected),
    emergency-ops-count: (var-get emergency-ops-counter)

  }
)


;; ========== MODULE MANAGEMENT FUNCTIONS ==========

;; Set the core contract (allowed to control this module), as well as the crowdfunding and escrow contract addresses
;; Purpose: Can only be called once by the contract owner (tx-sender at deployment) to handle initial bootstrapping
(define-public (initialize (core principal))
  (begin
    ;; Only the original contract owner can call this
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Ensure module's address is not an invalid tx-sender
    (asserts! (is-valid-module tx-sender) ERR-INVALID-RECIPIENT)  
    
    ;; Save the core contract address
    (var-set core-contract core)

    ;; Print log for efficient Audit trails
    (print {
      event: "module initialized",
      core-contract: core,
      initializer: tx-sender,
      block-height: block-height
    })
    (ok true)

  )
)

;; Set verification contract 
;; Purpose: Dynamic module replacement
(define-public (set-verification-contract (verification principal)) 
  (begin
    ;; Only the original contract-owner can call this
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Ensure module's address is not an invalid tx-sender
    (asserts! (is-valid-module tx-sender) ERR-INVALID-RECIPIENT)  

    ;; Save the verification contract address
    (var-set verification-contract verification)
    
    ;; Print log for efficient Audit trails
    (print {
      event: "verification contract updated",
      new-contract: verification,
      updater: tx-sender,
      block-height: block-height
    })
    (ok true)

  )
)

;; Set the escrow contract
;; Purpose: Dynamic module replacement
(define-public (set-escrow-contract (escrow principal))
  (begin
    ;; Only the original contract-owner can call this
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)  

     ;; Ensure module's address is not an invalid tx-sender
    (asserts! (is-valid-module tx-sender) ERR-INVALID-RECIPIENT)  

    ;; Save the escrow contract address
    (var-set escrow-contract escrow)
    
    ;; Print log for efficient Audit trails
    (print {
      event: "escrow contract updated",
      new-contract: escrow,
      updater: tx-sender,
      block-height: block-height
    })
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
    (asserts! (<= amount current-contract-balance) ERR-INSUFFICIENT-FUNDS)

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
      recipient: recipient,
      admin: contract-caller,
      block-height: block-height,
      reason: "emergency funds recovery" 
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


;; ========== BASE TRAIT IMPLEMENTATIONS ==========
;; Get module version number    
(define-read-only (get-module-version)
    (ok (var-get module-version)) ;; return module version number
) 

;; Check if module is active/currently working properly 
(define-read-only (is-module-active)
    (ok (var-get module-active)) ;; return if true or false
)

;; Get module name to identify which module this is
(define-read-only (get-module-name) 
    (ok "crowdfunding-module") ;; return current module name
)


