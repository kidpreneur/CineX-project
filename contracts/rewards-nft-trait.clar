
;; title: rewards-nft-trait;; title: rewards-nft-trait
;; version: 1.0.0
;; Author: Victor Omenai 
;; Created: 2025

;; Import the standard NFT trait
(use-trait standard-nft-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Define our extended mint trait with additional functions
(define-trait rewards-nft-trait
  (
    ;; Standard NFT functions are implicitly included
    
    ;; Our custom mint function
    (mint (principal uint uint (string-ascii 150)) (response uint uint))
    
    ;; Batch mint function
    (batch-mint ((list 50 principal) (list 50 uint) (list 50 (string-ascii 150)) uint) (response uint uint))
    
    ;; Get the last token ID counter
    (get-last-token-id () (response uint uint))
    
    ;; Get token metadata
    (get-token-metadata (uint) (response {
        campaign-id: uint,
        reward-tier: uint,
        reward-tier-description: (string-ascii 150),
        contributor: principal
      } uint))
  )
)