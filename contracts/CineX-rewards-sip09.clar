
;; title: CineX-rewards-sip09
;; Author: Victor Omenai 
;; Created: 2025

;; version: 1.0.0
;; summary: NFT token representing tiers of privileges & rewards for filmmakers to reward contributors

;;;; ============= Description ==============
;; Implementation of SIP-09 compliant NFT for the CineX platform's reward system
;; Strategic Purpose: Standardize and Implements technical rewards infrastructure
;; This addresses the "Key Activities - to deliver the value proposition to backers as customers" component of the Business Model Canvas 
;; of CineX

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Define the NFT
(define-non-fungible-token CineX-rewards uint)

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant COLLECTION-MAX-SUPPLY u1000)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SUPPLY-EXCEEDED (err u101))
(define-constant ERR-TRANSFER-FAILED (err u102))
(define-constant ERR-MINT-FAILED (err u103))
(define-constant ERR-TOKEN-NOT-FOUND (err u105))
(define-constant ERR-INVALID-BATCH-SIZE (err u106))
(define-constant ERR-BATCH-MINT-FAILED (err u107))

;; State variables
(define-data-var last-token-id uint u0)
(define-data-var authorized-minter principal tx-sender)

;; Token metadata
(define-map token-metadata uint { 
    campaign-id: uint,
    reward-tier: uint,
    reward-tier-description: (string-ascii 150),
    contributor: principal
})

;; Read-only function to get the current token ID counter
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

;; Set authorized minter
(define-public (set-authorized-minter (new-minter principal))
    (let 
        (
            ;; Get authorized-minter
            (existing-authorized-minter (var-get authorized-minter))
        ) 
        (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender existing-authorized-minter)) ERR-NOT-AUTHORIZED)
        (ok (var-set authorized-minter new-minter))
        
    )

)

;; Get the owner of a token
(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? CineX-rewards token-id))
)

;; Read-only function to get metadata for a specific token
(define-read-only (get-token-metadata (token-id uint))
    (match (map-get? token-metadata token-id)
        reward-data (ok reward-data)
        ERR-TOKEN-NOT-FOUND
    )
)

;; Get the token URI
(define-read-only (get-token-uri (token-id uint))
    (ok none)
)

;; Individual mint function with authorization check
(define-public (mint (recipient principal) (campaign-id uint) (new-reward-tier uint) (new-reward-desc (string-ascii 150)))
    (let 
        (
            ;; Get the current token ID counter, and set its next-token 
            (current-token-id (var-get last-token-id))
            (next-token-id (+ current-token-id u1))
            ;; Get authorized-minter 
            (current-authorized-minter (var-get authorized-minter))
            
        ) 
            
            ;; Authorization check
            (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq recipient current-authorized-minter)) ERR-NOT-AUTHORIZED)
            
            ;; Supply check
            (asserts! (< next-token-id COLLECTION-MAX-SUPPLY) ERR-SUPPLY-EXCEEDED)
            
            ;; Mint the NFT
            (unwrap! (nft-mint? CineX-rewards next-token-id recipient) ERR-MINT-FAILED)
            
            ;; Store the reward metadata
            (map-set token-metadata next-token-id {
                campaign-id: campaign-id,
                reward-tier: new-reward-tier, 
                reward-tier-description: new-reward-desc,
                contributor: recipient
            })
            
            ;; Increment token ID counter
            (var-set last-token-id next-token-id)

            ;; Return the minted token ID
            (ok next-token-id)
    )
)

;; Helper function for batch minting
(define-private (process-mint (recipient principal) (result {token-id: uint, success: bool, count: uint, index: uint, reward-tiers: (list 50 uint), reward-descriptions: (list 50 (string-ascii 150)), campaign-id: uint}))
    (if (not (get success result)) ;; if minting process success fails (not successful)
        result ;; return the failed result
        ;; else, if it is successful, evaluate the process
        (let
            (
                ;; Get the current token ID from our accumulator
                (token-id (get token-id result))
                ;; Next token-id
                (next-token-id (+ token-id u1))
                ;; Get position we're at in all three lists
                (index (get index result))
                 ;; Next index 
                (next-index (+ index u1))
                ;; Get list of reward-tiers, reward-descriptions from the result accumulator
                (reward-tiers (get reward-tiers result))
                (reward-descriptions (get reward-descriptions result))
                ;; Get counts
                (counts (get count result))
                ;; Next count incrementing counts
                (next-count (+ counts u1))
                ;; Get campaign-id from result
                (campaign-id (get campaign-id result))
                ;; Get the index corresponding to the reward tier and description indices of each contributor from each list of reward-tier and reward-description  
                ;; else trigger fallback value
                (reward-tier (unwrap! (element-at reward-tiers index) {
                    token-id: token-id, 
                    success: false, 
                    count: counts, 
                    index: index, 
                    reward-tiers: reward-tiers, 
                    reward-descriptions: reward-descriptions, 
                    campaign-id: campaign-id}))
                (reward-desc (unwrap! (element-at reward-descriptions index) {
                    token-id: token-id, 
                    success: false, 
                    count: counts, 
                    index: index, 
                    reward-tiers: reward-tiers, 
                    reward-descriptions: reward-descriptions, 
                    campaign-id: campaign-id}))
                (mint-result (nft-mint? CineX-rewards token-id recipient))
            )
                (if (is-ok mint-result) ;; if response-value of mint-result is `ok`, return `true`
                        (begin
                            ;; then process the reward meta-data for the contributor
                            (map-set token-metadata token-id {
                                campaign-id: (get campaign-id result),
                                reward-tier: reward-tier, ;; index of reward tier that corresponds with the contributor
                                reward-tier-description: reward-desc, ;; index of reward-description of index of reward-tier that corresponds with the contributor
                                contributor: recipient
                                })
                    
                            {
                                ;; return the result 
                                token-id: next-token-id, 
                                success: true, 
                                count: next-count,
                                index: next-index,
                                reward-tiers: reward-tiers,
                                reward-descriptions: reward-descriptions,
                                campaign-id: campaign-id
                            }
                        )
                            {token-id: token-id, success: false, count: counts, index: index, reward-tiers: reward-tiers, reward-descriptions: reward-descriptions, campaign-id: campaign-id}
            )
        )
    )
)

;; Batch mint function with authorization check
(define-public (batch-mint (recipients (list 50 principal)) (reward-tiers (list 50 uint)) (reward-descriptions (list 50 (string-ascii 150))) (campaign-id uint))
    (let
        (
            ;; Calculate how many NFTs we're minting by extracting the length of the list of recipients (len recipients)
            (batch-size (len recipients))

            ;; Get the current token ID counter
            (current-token-id (var-get last-token-id))
            
            ;; Get authorized-minter 
            (current-authorized-minter (var-get authorized-minter))

            ;; Process the batch by folding over the recipients list only
            (mint-result (fold process-mint recipients {
                token-id: current-token-id, 
                success: true, 
                count: u0, 
                index: u0, 
                reward-tiers: reward-tiers, 
                reward-descriptions: reward-descriptions, 
                campaign-id: campaign-id
            }))
        )
            ;; Authorization check
            (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender current-authorized-minter)) ERR-NOT-AUTHORIZED)

            ;; Validate batch size, making sure the batch size is not more than 50 
            (asserts! (and (> batch-size u0) (<= batch-size u50)) ERR-INVALID-BATCH-SIZE)
        
            ;; Check equal lengths
            ;; Every recipient should have a reward tier and description matching the len of the batch
            (asserts! (and (is-eq batch-size (len reward-tiers)) (is-eq batch-size (len reward-descriptions))) ERR-INVALID-BATCH-SIZE)
    
            ;; Supply check
            (asserts! (<= (+ current-token-id batch-size) COLLECTION-MAX-SUPPLY) ERR-SUPPLY-EXCEEDED)

            ;; Update the token ID counter
            (var-set last-token-id (+ current-token-id batch-size))
        
            ;; Return success or error based on the final result
            (if (get success mint-result)
                ;; If successful, return OK with count - number of tokens minted
                (ok (get count mint-result))
                ;; If any mint failed, return an error
                ERR-BATCH-MINT-FAILED
            )
    )
)

;; Transfer function with ownership check
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (nft-transfer? CineX-rewards token-id sender recipient)
    )
)



