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

;; Store the principal address of the core contract 
(define-data-var core-contract principal tx-sender)

;;  Contract principal variable as the crowdfunding module contract reference pointing to the crowdfunding contract
(define-data-var crowdfunding-contract principal tx-sender)

;;  Contract principal variable as the escrow module contract reference
(define-data-var escrow-contract principal tx-sender)

;; Define custom error codes for standardized error handling
(define-constant ERR-NOT-AUTHORIZED (err u4000))         ;; Caller is not authorized 
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u4001))      ;; Campaign ID not found
(define-constant ERR-TRANSFER-FAILED (err u4002))         ;; STX transfer failed
(define-constant ERR-INSUFFICIENT-BALANCE (err u4003))    ;; Not enough funds in escrow

;; Constant holding contract-owner principal
(define-constant CONTRACT-OWNER tx-sender)

;; Mapping to track each campaign's STX funds in escrow
(define-map campaign-escrow-balances uint uint)

;; Authorization map
(define-map authorized-withdrawals { campaign-id: uint, requester: principal } bool)

;; Authorization map for fee collection permission
(define-map authorized-fee-collections { campaign-id: uint, requester: principal } bool)


;; Public function: Allows any user to deposit funds into a campaign's escrow balance
(define-public (deposit-to-campaign (campaign-id uint) (amount uint))
  (let
    (
      ;; Retrieve current balance, defaulting to 0 if campaign does not exist yet
      (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))
      ;; Calculate the new balance after deposit
      (new-balance (+ current-balance amount))
    )
    ;; Transfer the STX from sender to contract address
    (unwrap! (stx-transfer? amount tx-sender (as-contract tx-sender)) ERR-TRANSFER-FAILED)
    
    ;; Update the escrow balance with new-balance for the campaign
    (map-set campaign-escrow-balances campaign-id new-balance)
    
    (ok true)
  )
)

;; Core contract authorizes withdrawal
(define-public (authorize-withdrawal (campaign-id uint) (new-requester principal))
  (begin 
    ;; Ensure Only core contract can authorize withdrawals
    (asserts! (is-eq tx-sender (var-get core-contract)) ERR-NOT-AUTHORIZED)
    (map-set authorized-withdrawals { campaign-id: campaign-id, requester: new-requester } true)
    (ok true)  
  
  )

)

;; Core contract authorizes fee collection
(define-public (authorize-fee-collection (campaign-id uint) (requester principal))
  (begin 
    ;; Ensure only core contract can authorize fee collection
    (asserts! (is-eq tx-sender (var-get core-contract)) ERR-NOT-AUTHORIZED)
    (map-set authorized-fee-collections { campaign-id: campaign-id, requester: requester } true)
    (ok true)
     
  )
)



;; Public function: Allows the campaign owner to withdraw a specified amount from escrow
(define-public (withdraw-from-campaign (campaign-id uint) (amount uint))
  (let
    (
      ;; Retrieve current balance
      (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))

      ;; Check authorization from authorize-withdrawal map, else default to false
      (is-withdrawal-authorized (default-to true (map-get? authorized-withdrawals { campaign-id: campaign-id, requester: tx-sender })))

      ;; Calculate the new balance after withdrawal
      (new-balance (- current-balance amount))

    )
      ;; Ensure caller is authorized core for withdrawal 
      (asserts! is-withdrawal-authorized ERR-NOT-AUTHORIZED)

      ;; Ensure there are enough funds to withdraw
      (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
    
      ;; Update the escrow balance
      (map-set campaign-escrow-balances campaign-id new-balance)
    
      ;; Transfer the withdrawn amount to the authorized requester
      (unwrap! (stx-transfer? amount (as-contract tx-sender) tx-sender) ERR-TRANSFER-FAILED)
    
      ;; Clear authorization after successful withdrawal
      (map-delete authorized-withdrawals { campaign-id: campaign-id, requester: tx-sender })
      (ok true)
  )
)

;; Public function: Allows the campaign owner to pay a fee from the campaign's escrowed funds to the core contract
(define-public (collect-campaign-fee (campaign-id uint) (fee-amount uint))
  (let
    (
      ;; Retrieve current balance
      (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))

      ;; Check authorization from authorize-fee-collection map, else default to false
      (is-fee-collection-authorized (default-to false (map-get? authorized-fee-collections { campaign-id: campaign-id, requester: tx-sender })))

      ;; Calculate the new balance after fee deduction
      (new-balance (- current-balance fee-amount))

      ;;Get core-contract
      (authorized-core-contract (var-get core-contract))
    )
      ;; Ensure caller is authorized core for fee-collection-authorized
      (asserts! is-fee-collection-authorized ERR-NOT-AUTHORIZED)

      ;; Ensure there are enough funds to cover the fee
      (asserts! (>= current-balance fee-amount) ERR-INSUFFICIENT-BALANCE)
    
      ;; Update the escrow balance
      (map-set campaign-escrow-balances campaign-id new-balance)
    
      ;; Transfer the fee amount to the core contract address
      (unwrap! (stx-transfer? fee-amount (as-contract tx-sender) authorized-core-contract) ERR-TRANSFER-FAILED)

      ;;  Clear authorization after successful fee collection
      (map-delete authorized-fee-collections { campaign-id: campaign-id, requester: tx-sender })
    
      (ok true)
  )
)

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


