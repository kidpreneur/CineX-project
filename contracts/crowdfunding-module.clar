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

;; Importing the escrow-trait, for managing safe storage of funds
(use-trait cf-escrow-trait .escrow-module-trait.escrow-trait) 

;; Importing the rewards-trait, for handling reward tiers (not used directly here)
(use-trait cf-rewards-trait .rewards-module-trait.rewards-trait) 

;; ===== Core Settings =====

;; Save the core contract that can control this module (e.g., for upgrades)
(define-data-var core-contract principal tx-sender) 

;;  Contract principal variable as the escrow module contract reference pointing to the escrow contract
(define-data-var escrow-contract principal tx-sender)

;; Principal variable as the rewards module contract reference
(define-data-var rewards-contract principal tx-sender)

;; ===== Constants =====

;; Fixed fee (in microstacks) to create a new campaign
(define-constant CAMPAIGN-FEE u20000000) ;; 20 STX

;; Minimum amount someone must contribute
(define-constant MINIMUM-CONTRIBUTION u1000000) ;; 1 STX

;; Platform takes a 7% fee from funds when a campaign owner withdraws
(define-constant WITHDRAWAL-FEE-PERCENT u7)

;; If no custom duration is set, campaigns will last about 3 months (~12960 blocks)
(define-constant DEFAULT-CAMPAIGN-DURATION u12960) 

;; Constant holding contract-owner principal
(define-constant CONTRACT-OWNER tx-sender)


;; ===== Error Codes =====

;; Predefined error messages for different failure situations
(define-constant ERR-NOT-AUTHORIZED (err u2000)) 
(define-constant ERR-INVALID-AMOUNT (err u2001)) 
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u2002))
(define-constant ERR-CAMPAIGN-INACTIVE (err u2003))
(define-constant ERR-FUNDING-GOAL-NOT-REACHED (err u2004))
(define-constant ERR-ALREADY-CLAIMED (err u2005))
(define-constant ERR-TRANSFER-FAILED (err u2006))
(define-constant ERR-ESCROW-BALANCE-NOT-FOUND (err u2007))

;; ===== State Variables =====

;; Counter for assigning a new unique ID to each campaign
(define-data-var unique-campaign-id uint u0)

;; ===== Data Maps =====

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
  funds-claimed: bool ;; True if owner has withdrawn funds
})

;; Tracks each contributor's activity for each campaign
(define-map campaign-contributions { campaign-id: uint, contributor: principal } {
  total-contributed: uint, ;; Total amount this user gave
  contributions-count: uint, ;; Number of times they contributed
  last-contribution-at: uint ;; When they last contributed (block-height)
})

;; Tracks all fees collected by the platform
(define-data-var total-fees-collected uint u0)

;; ===== Public Functions =====

;; ========== CREATE A CAMPAIGN ==========

(define-public (create-campaign (description (string-ascii 500)) (campaign-id uint) (funding-goal uint) (duration uint) (reward-tiers uint) (reward-description (string-ascii 150)))
  (let
    (
      ;; Get current unique campaign id
      (current-unique-campaign-id (var-get unique-campaign-id))  

      ;; Set new campaign ID by adding 1 to the current counter
      (next-unique-campaign-id (+ current-unique-campaign-id u1)) 
      
      (effective-duration (if (> duration u0) ;; If campaign creator inputs a custom `duration` variable, i.e, anything > zero, 
                                duration ;; let it pass
                                DEFAULT-CAMPAIGN-DURATION ;; else, use DEFAULT-CAMPAIGN-DURATION 12960  
                          )
        )
      ;; Get total-fees-collected
      (existing-total-fees-collected (var-get total-fees-collected))
      
      ;; Calculate updated total-fees-collected
      (new-total-fees-collected (+ existing-total-fees-collected CAMPAIGN-FEE))

      ;; Get core-contract
      (authorized-core-contract (var-get core-contract))
    )
    
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
      funds-claimed: false ;; nothing yet claimed 
    })
    
    ;; Update the campaign counter
    (var-set unique-campaign-id next-unique-campaign-id)
    
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
        (escrow-balance (unwrap! (contract-call? (var-get escrow-contract) get-campaign-balance campaign-id) ERR-ESCROW-BALANCE-NOT-FOUND))
      
        ;; Try to get existing contribution, or default to zero if none
        (existing-contribution (default-to 
                                  { total-contributed: u0, contributions-count: u0, last-contribution-at: u0 } 
                                    (map-get? campaign-contributions { campaign-id: campaign-id, contributor: tx-sender })))

        ;; Get current-total-raised
        (current-total-raised (get total-raised campaign))

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

    )
    
      ;; Make sure campaign is active
      (asserts! (get is-active campaign) ERR-CAMPAIGN-INACTIVE)
    
      ;; Make sure contribution amount is high enough
      (asserts! (>= amount MINIMUM-CONTRIBUTION) ERR-INVALID-AMOUNT)
    
      ;; Move funds into escrow (secure temporary storage)
      (unwrap! (contract-call? (var-get escrow-contract) deposit-to-campaign campaign-id amount) ERR-TRANSFER-FAILED)
    
      ;; Increase campaign's total raised amount
      (map-set campaigns campaign-id 
        (merge 
          campaign 
            { total-raised: new-total-raised }
        )
      )
      ;; Update record of contributor
      (map-set campaign-contributions { campaign-id: campaign-id, contributor: tx-sender } {
        total-contributed: new-total-contributed,
        contributions-count: new-count,
        last-contribution-at: block-height
      })
    
      (ok true)
  )
)

;; ========== CLAIM FUNDS AFTER SUCCESSFUL CAMPAIGN ==========

(define-public (claim-campaign-funds (campaign-id uint))
  (let
    (
      ;; Load campaign details
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))
      
      ;; Get the escrow balance from the campaign-escrow-balances map of the escrow-module contract
      (escrow-balance (unwrap! (contract-call? (var-get escrow-contract) get-campaign-balance campaign-id) ERR-ESCROW-BALANCE-NOT-FOUND))
      
      ;; Extract necessary details
      (current-total-raised (get total-raised campaign))
      (current-funding-goal (get funding-goal campaign))
      (current-owner (get owner campaign))
      
      ;; Calculate fee and final amount to withdraw
      (fee-amount (/ (* current-total-raised WITHDRAWAL-FEE-PERCENT) u100)) ;; deduction of 7% withdrawal-fee from total-raised money
      (withdraw-amount (- current-total-raised fee-amount)) ;; campaign-owner withdraws total-raised funds minus deduction of 7% 

      ;; Get existing total-fees-collected
      (existing-total-fees-collected (var-get total-fees-collected))

      ;; Calculate new fee added to existing total fees collected
      (new-collected-fee (+ existing-total-fees-collected fee-amount))


    )
    
      ;; Make sure the person claiming is the owner
      (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    
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
            is-active: false
          })
      )
    
      ;; Withdraw the earned funds minus fees
      (unwrap! (contract-call? (var-get escrow-contract) withdraw-from-campaign campaign-id withdraw-amount) ERR-TRANSFER-FAILED)
     
      ;; Transfer platform's fee   
      (unwrap! (contract-call? (var-get escrow-contract) collect-campaign-fee campaign-id fee-amount tx-sender) ERR-TRANSFER-FAILED)
    
      ;; Track the collected fee
      (var-set total-fees-collected new-collected-fee)
    
      (ok true)
  )
)

;; ========== VIEW A CAMPAIGN'S DETAILS ==========

(define-read-only (get-campaign (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, return the campaign details
    campaign (ok campaign)
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)

;; ========== INITIALIZE THE MODULE ==========

;; Set the core contract (allowed to control this module) as well as escrow-trait contract
(define-public (initialize (core principal) (escrow-module <escrow-trait>))
  (begin
    ;; Only the original contract owner can call this
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    ;; Save the core contract address and others
    (var-set core-contract core)
    (var-set escrow-contract (contract-of escrow-module))
    (ok true)

  )
)
;; title: crowdfunding-module
;; version: 1.0.0
;; implements: .crowdfunding-module-trait.crowdfunding-trait

;; Implementing the crowdfunding trait (interface) to follow expected rules
(impl-trait .crowdfunding-module-traits.crowdfunding-trait) 

;; Importing the escrow-trait, for managing safe storage of funds
(use-trait escrow-trait .escrow-module-trait.escrow-trait) 

;; Importing the rewards-trait, for handling reward tiers (not used directly here)
(use-trait rewards-trait .rewards-module-trait.rewards-trait) 

;; ===== Core Settings =====

;; Save the core contract that can control this module (e.g., for upgrades)
(define-data-var core-contract principal tx-sender) 

;;  Contract principal variable as the escrow module contract reference pointing to the escrow contract
(define-data-var escrow-contract principal tx-sender)

;; ===== Constants =====

;; Fixed fee (in microstacks) to create a new campaign
(define-constant CAMPAIGN-FEE u20000000) ;; 20 STX

;; Minimum amount someone must contribute
(define-constant MINIMUM-CONTRIBUTION u1000000) ;; 1 STX

;; Platform takes a 7% fee from funds when a campaign owner withdraws
(define-constant WITHDRAWAL-FEE-PERCENT u7)

;; If no custom duration is set, campaigns will last about 3 months (~12960 blocks)
(define-constant DEFAULT-CAMPAIGN-DURATION u12960) 

;; Constant holding contract-owner principal
(define-constant CONTRACT-OWNER tx-sender)


;; ===== Error Codes =====

;; Predefined error messages for different failure situations
(define-constant ERR-NOT-AUTHORIZED (err u2000)) 
(define-constant ERR-INVALID-AMOUNT (err u2001)) 
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u2002))
(define-constant ERR-CAMPAIGN-INACTIVE (err u2003))
(define-constant ERR-FUNDING-GOAL-NOT-REACHED (err u2004))
(define-constant ERR-ALREADY-CLAIMED (err u2005))
(define-constant ERR-TRANSFER-FAILED (err u2006))
(define-constant ERR-ESCROW-BALANCE-NOT-FOUND (err u2007))

;; ===== State Variables =====

;; Counter for assigning a new unique ID to each campaign
(define-data-var unique-campaign-id uint u0)

;; ===== Data Maps =====

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
  funds-claimed: bool ;; True if owner has withdrawn funds
})

;; Tracks each contributor's activity for each campaign
(define-map campaign-contributions { campaign-id: uint, contributor: principal } {
  total-contributed: uint, ;; Total amount this user gave
  contributions-count: uint, ;; Number of times they contributed
  last-contribution-at: uint ;; When they last contributed
})

;; Tracks all fees collected by the platform
(define-data-var total-fees-collected uint u0)

;; ===== Public Functions =====

;; ========== CREATE A CAMPAIGN ==========

(define-public (create-campaign (description (string-ascii 500)) (campaign-id uint) (funding-goal uint) (duration uint) (reward-tiers uint) (reward-description (string-ascii 150)))
  (let
    (
      ;; Get current unique campaign id
      (current-unique-campaign-id (var-get unique-campaign-id))  

      ;; Set new campaign ID by adding 1 to the current counter
      (next-unique-campaign-id (+ current-unique-campaign-id u1)) 
      
      (effective-duration (if (> duration u0) ;; If campaign creator inputs a custom duration, i.e, anything > zero, 
                                duration ;; let it pass
                                DEFAULT-CAMPAIGN-DURATION ;; else, use DEFAULT-CAMPAIGN-DURATION 12960  
                          )
        )
      ;; Get total-fees-collected
      (existing-total-fees-collected (var-get total-fees-collected))
      
      ;; Calculate updated total-fees-collected
      (new-total-fees-collected (+ existing-total-fees-collected CAMPAIGN-FEE))

      ;; Get core-contract
      (authorized-core-contract (var-get core-contract))
    )
    
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
      funds-claimed: false ;; nothing yet claimed 
    })
    
    ;; Update the campaign counter
    (var-set unique-campaign-id next-unique-campaign-id)
    
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
        (escrow-balance (unwrap! (contract-call? (var-get escrow-contract) get-campaign-balance campaign-id) ERR-ESCROW-BALANCE-NOT-FOUND))
      
        ;; Try to get existing contribution, or default to zero if none
        (existing-contribution (default-to 
                                  { total-contributed: u0, contributions-count: u0, last-contribution-at: u0 } 
                                    (map-get? campaign-contributions { campaign-id: campaign-id, contributor: tx-sender })))

        ;; Get current-total-raised
        (current-total-raised (get total-raised campaign))

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

    )
    
    ;; Make sure campaign is active
    (asserts! (get is-active campaign) ERR-CAMPAIGN-INACTIVE)
    
    ;; Make sure contribution amount is high enough
    (asserts! (>= amount MINIMUM-CONTRIBUTION) ERR-INVALID-AMOUNT)
    
    ;; Move funds into escrow (secure temporary storage)
    (unwrap! (contract-call? (var-get escrow-contract) deposit-to-campaign campaign-id amount) ERR-TRANSFER-FAILED)
    
    ;; Increase campaign's total raised amount
    (map-set campaigns campaign-id 
      (merge 
        campaign 
        { total-raised: new-total-raised }
      )
    )
    ;; Update record of contributor
    (map-set campaign-contributions { campaign-id: campaign-id, contributor: tx-sender } {
        total-contributed: new-total-contributed,
        contributions-count: new-count,
        last-contribution-at: block-height
      })
    
    (ok true)
  )
)

;; ========== CLAIM FUNDS AFTER SUCCESSFUL CAMPAIGN ==========

(define-public (claim-campaign-funds (campaign-id uint))
  (let
    (
      ;; Load campaign details
      (campaign (unwrap! (map-get? campaigns campaign-id) ERR-CAMPAIGN-NOT-FOUND))
      
      ;; Get the escrow balance from the campaign-escrow-balances map of the escrow-module contract
      (escrow-balance (unwrap! (contract-call? (var-get escrow-contract) get-campaign-balance campaign-id) ERR-ESCROW-BALANCE-NOT-FOUND))
      
      ;; Extract necessary details
      (current-total-raised (get total-raised campaign))
      (current-funding-goal (get funding-goal campaign))
      (current-owner (get owner campaign))
      
      ;; Calculate fee and final amount to withdraw
      (fee-amount (/ (* current-total-raised WITHDRAWAL-FEE-PERCENT) u100)) ;; deduction of 7% withdrawal-fee from total-raised money
      (withdraw-amount (- current-total-raised fee-amount)) ;; campaign-owner withdraws total-raised funds minus deduction of 7% 

      ;; Get existing total-fees-collected
      (existing-total-fees-collected (var-get total-fees-collected))

      ;; Calculate new fee added to existing total fees collected
      (new-collected-fee (+ existing-total-fees-collected fee-amount))


    )
    
    ;; Make sure the person claiming is the owner
    (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    
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
          is-active: false
        })
    )
    
    ;; Withdraw the earned funds minus fees
    (unwrap! (contract-call? (var-get escrow-contract) withdraw-from-campaign campaign-id withdraw-amount) ERR-TRANSFER-FAILED)
     
    ;; Transfer platform's fee   
    (unwrap! (contract-call? (var-get escrow-contract) collect-campaign-fee campaign-id fee-amount tx-sender) ERR-TRANSFER-FAILED)
    
    ;; Track the collected fee
    (var-set total-fees-collected new-collected-fee)
    
    (ok true)
  )
)

;; ========== VIEW A CAMPAIGN'S DETAILS ==========

(define-read-only (get-campaign (campaign-id uint))
  (match (map-get? campaigns campaign-id)
    ;; If found, return the campaign details
    campaign (ok campaign)
    
    ;; If not found, return error
    ERR-CAMPAIGN-NOT-FOUND
  )
)

;; ========== INITIALIZE THE MODULE ==========

;; Set the core contract (allowed to control this module) as well as escrow-trait contract
(define-public (initialize (core principal) (escrow <cf-escrow-trait>) (rewards <cf-rewards-trait>))
  (begin
    ;; Only the original contract owner can call this
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    
    ;; Save the core contract address and others
    (var-set core-contract core)
    (var-set escrow-contract (contract-of escrow))
    (var-set rewards-contract (contract-of rewards))
    (ok true)

  )
)
