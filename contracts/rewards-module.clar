;; title: rewards-module
;; version: 1.0.0
;; Author: Victor Omenai 
;; Created: 2025

;; ========= Summary ==========
;; This rewards-module acts like a "Reward Manager" 
;;    => collecting minting fees, 
;;    => ensuring only the right people can give rewards, recording who earned what, 
;;    => and organizing mass (batch) reward distribution; the actual NFT minting is done separately by the NFT contract.


;; ========= Description ==========
;; Implementation of Rewards module trait
;; This Rewards Module in CineX handles the secure distribution of campaign rewards to contributors. It allows campaign owners to mint 
;; and assign NFT rewards based on contribution tiers, tracks each reward issued, and collects minting fees to support platform sustainability. 
;; The module ensures that rewards are properly authorized, recorded, and linked to the correct campaigns through direct interaction 
;; with the core CineX platform and a separate NFT rewards contract.

;; Strategic Purpose: Manages backer incentives and value delivery
;; This addresses the "Value Proposition component of the Business Model of CineX

;; Implements the Rewards Trait interface
(impl-trait .rewards-module-trait.rewards-trait)

;; Contract principal as Core contract reference pointing to the CineX main contract
(define-data-var core-contract principal tx-sender)

;; Contract principal as Rewards-NFT contract reference pointing to the NFT contract that mints rewards
(define-data-var rewards-contract principal tx-sender)

;;  Contract principal variable as the crowdfunding module contract reference pointing to the crowdfunding contract
(define-data-var crowdfunding-contract principal tx-sender)

;; Constant holding contract-owner principal
(define-constant CONTRACT-OWNER tx-sender)

;; Constant fee required to mint a reward NFT (in microSTX, 1 STX = 1_000_000 microSTX)
(define-constant REWARD-MINTING-FEE u1000000)

;; Define custom error codes for better debugging
(define-constant ERR-NOT-AUTHORIZED (err u3000))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u3001))
(define-constant ERR-INVALID-REWARD-TIER (err u3002))
(define-constant ERR-TRANSFER-FAILED (err u3003))
(define-constant ERR-REWARD-MINT-FAILED (err u3004))
(define-constant ERR-LISTS-UNEQUAL-LENGTH (err u3005))
(define-constant ERR-REWARD-NOT-FOUND (err u3006))

;; Map to track each contributor's reward for each campaign
(define-map contributor-rewards { campaign-id: uint, contributor: principal } {
    tier: uint,                                 ;; Tier of reward received
    description: (string-ascii 150),             ;; Description of the reward
    token-id: (optional uint)                    ;; Token ID of the minted NFT reward
  }
)

;; Tracks the total minting fees collected across all rewards
(define-data-var total-minting-fees uint u0)

;; --- Core functionality begins ---

;; Awards a single campaign reward to a contributor
(define-public (award-campaign-reward (campaign-id uint) (new-contributor principal) (new-reward-tier uint) (new-reward-desc (string-ascii 150)))
  (let
    (

      ;; Fetch the campaign details from the crowdfunding module
      (campaign (unwrap! (contract-call? .crowdfunding-module get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))

      ;; Get current-owner of campaign
      (current-owner  (get owner campaign))

      ;; Get current-reward-tiers of the campaign
      (current-reward-tiers (get reward-tiers campaign))

      ;; Get core-contract
      (authorized-core-contract (var-get core-contract))

      ;; Get current-total-minting-fees
      (current-total-minting-fees (var-get total-minting-fees))

      ;; Calculate new-total-minting-fees
      (new-total-minting-fees (+ current-total-minting-fees REWARD-MINTING-FEE))

      ;; Track contributor-token-id to unwrapped minting details of exact contributor's token 
      (contributor-token-id (unwrap! (contract-call?  .CineX-rewards-sip09  mint new-contributor campaign-id new-reward-tier new-reward-desc) 
            ERR-REWARD-MINT-FAILED))


    )
      ;; Ensure that the caller is the owner of the campaign
      (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    
      ;; Ensure that the reward tier is within valid range
      (asserts! (and (> new-reward-tier u0) (<= new-reward-tier current-reward-tiers)) ERR-INVALID-REWARD-TIER)
    
      ;; Collect minting fee from caller and send to the core contract
      (unwrap! (stx-transfer? REWARD-MINTING-FEE tx-sender authorized-core-contract) ERR-TRANSFER-FAILED)
    
      ;; Update the total minting fees counter
      (var-set total-minting-fees new-total-minting-fees)

      
      ;; Save the contributor's reward details in the map
      (map-set contributor-rewards { campaign-id: campaign-id, contributor: new-contributor } {
          tier: new-reward-tier,
          description: new-reward-desc,
          token-id: (some contributor-token-id)
        })
      
      ;; Return the minted token ID
      (ok contributor-token-id)
    
  )
)

;; Awards multiple campaign rewards at once (batch processing)
(define-public (batch-award-campaign-rewards (campaign-id uint) (contributors (list 50 principal)) (reward-tiers (list 50 uint)) (reward-descriptions (list 50 (string-ascii 150))))
  (let
    (
      ;; Fetch the campaign details
      (campaign (unwrap! (contract-call? .crowdfunding-module get-campaign campaign-id) ERR-CAMPAIGN-NOT-FOUND))

      ;; get owner of campaign
      (current-owner (get owner campaign)) 

      ;; Get core-contract
      (authorized-core-contract (var-get core-contract))

      ;; Get number of contributors
      (contributors-count (len contributors))
      
      ;; Calculate total minting fee based on number of contributors
      (total-batch-minting-fee (* contributors-count REWARD-MINTING-FEE))

      ;; Get current-total-minting-fees
      (current-total-minting-fees (var-get total-minting-fees))

      ;; Calculate new-total-minting-fees
      (new-batch-total-minting-fees (+ current-total-minting-fees total-batch-minting-fee))

      ;; Use the variable to call the contract and Batch mint NFT rewards
      (mint-result (unwrap! (contract-call? .CineX-rewards-sip09 batch-mint contributors reward-tiers reward-descriptions campaign-id)
                      ERR-REWARD-MINT-FAILED))

    )
      ;; Validate caller is the campaign owner
      (asserts! (is-eq tx-sender current-owner) ERR-NOT-AUTHORIZED)
    
      ;; Ensure input lists (contributors, tiers, descriptions) are the same length
      (asserts! (and 
                  (is-eq contributors-count (len reward-tiers)) 
                  (is-eq contributors-count (len reward-descriptions)))
             ERR-LISTS-UNEQUAL-LENGTH)
    
      ;; Collect total minting fees
      (unwrap! (stx-transfer? total-batch-minting-fee tx-sender authorized-core-contract) ERR-TRANSFER-FAILED)
    
      ;; Update total collected fees
      (var-set total-minting-fees new-batch-total-minting-fees)
    
      ;; Note: This simple version does not store individual token IDs for batch mints
      (ok mint-result)
    
  )
)

;; Fetch the reward information of a contributor for a specific campaign
(define-read-only (get-contributor-reward (campaign-id uint) (contributor principal))
  (match (map-get? contributor-rewards { campaign-id: campaign-id, contributor: contributor })
    reward (ok reward)             ;; If reward exists, return it
    ERR-REWARD-NOT-FOUND                    ;; Else, return reward-not-found error
  )
)

;; Initialization function to set up core-contract, as well as the crowdfunding and escrow contract addresses
;; Purpose: Can only be called once by the contract owner (tx-sender at deployment) to handle initial bootstrapping
(define-public (initialize (core principal) (crowdfunding principal) (rewards principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set core-contract core)
    (var-set crowdfunding-contract crowdfunding)
    (var-set rewards-contract rewards)
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

;; Set the rewards-contract 
;; Purpose: Dynamic module replacement
(define-public (set-rewards (rewards principal))
  (begin 
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set rewards-contract rewards)
    (ok true)
  )   
)

