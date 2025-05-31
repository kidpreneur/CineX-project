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

;; Use Crowdfunding Trait - for crowdfunding module functions
(use-trait esc-crowdfunding-trait .crowdfunding-module-traits.crowdfunding-trait)

;; Store the principal address of the core contract 
(define-data-var core-contract principal tx-sender)

;;  Contract principal variable as the crowdfunding module contract reference pointing to the crowdfunding contract
(define-data-var crowdfunding-contract principal tx-sender)

;; Define custom error codes for standardized error handling
(define-constant ERR-NOT-AUTHORIZED (err u4000))         ;; Caller is not authorized 
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u4001))      ;; Campaign ID not found
(define-constant ERR-TRANSFER-FAILED (err u4002))         ;; STX transfer failed
(define-constant ERR-INSUFFICIENT-BALANCE (err u4003))    ;; Not enough funds in escrow

;; Constant holding contract-owner principal
(define-constant CONTRACT-OWNER tx-sender)

;; Mapping to track each campaign's STX funds in escrow
(define-map campaign-escrow-balances uint uint)

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

;; Public function: Allows the campaign owner to withdraw a specified amount from escrow
(define-public (withdraw-from-campaign (campaign-id uint) (amount uint))
  (let
    (
      ;; Retrieve current balance
      (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))

      ;; Fetch campaign details from the crowdfunding module
      (campaign (unwrap! (contract-call? (var-get crowdfunding-contract) get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))

      ;; Calculate the new balance after withdrawal
      (new-balance (- current-balance amount))

      ;; Get campaign-owner
      (owner (get owner campaign))

    )
      ;; Ensure that the caller is the campaign owner
      (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)

      ;; Ensure there are enough funds to withdraw
      (asserts! (>= current-balance amount) ERR-INSUFFICIENT-BALANCE)
    
      ;; Update the escrow balance
      (map-set campaign-escrow-balances campaign-id new-balance)
    
      ;; Transfer the withdrawn amount to the campaign owner
      (unwrap! (stx-transfer? amount (as-contract tx-sender) owner) ERR-TRANSFER-FAILED)
    
      (ok true)
  )
)

;; Public function: Allows the campaign owner to pay a fee from the campaign's escrowed funds to the core contract
(define-public (collect-campaign-fee (campaign-id uint) (fee-amount uint))
  (let
    (
      ;; Retrieve current balance
      (current-balance (default-to u0 (map-get? campaign-escrow-balances campaign-id)))

      ;; Fetch campaign details from the crowdfunding module
      (campaign (unwrap! (contract-call? (var-get crowdfunding-contract) get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))

      ;; Calculate the new balance after fee deduction
      (new-balance (- current-balance fee-amount))

      ;; Get campaign-owner
      (owner (get owner campaign))

      ;;Get core-contract
      (authorized-core-contract (var-get core-contract))
    )
      ;; Ensure that the caller is the campaign owner
      (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)

      ;; Ensure there are enough funds to cover the fee
      (asserts! (>= current-balance fee-amount) ERR-INSUFFICIENT-BALANCE)
    
      ;; Update the escrow balance
      (map-set campaign-escrow-balances campaign-id new-balance)
    
      ;; Transfer the fee amount to the core contract address
      (unwrap! (stx-transfer? fee-amount (as-contract tx-sender) authorized-core-contract) ERR-TRANSFER-FAILED)
    
      (ok true)
  )
)

;; Read-only function: Fetches the current escrow balance for a given campaign
(define-read-only (get-campaign-balance (campaign-id uint))
  ;; default-to zero if optional-value of campaign-balance is none 
  (ok (default-to u0 (map-get? campaign-escrow-balances campaign-id)))
)

;; Public function: One-time initializer to set the core contract address, as well as the crowfunding contract address
;; Only the contract owner can initialize this
(define-public (initialize (core principal) (funding-core-contract <esc-crowdfunding-trait>))
  (begin
    ;; Ensure that only the contract owner can initialize
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; Set the core-contract variable
    (var-set core-contract core)
    (var-set crowdfunding-contract (contract-of funding-core-contract))
    (ok true)
  )
)
