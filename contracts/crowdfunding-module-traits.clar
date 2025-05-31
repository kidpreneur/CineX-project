;; title: crowdfunding-module-trait
;; version: 1.0.0
;; Author: Victor Omenai 
;; Created: 2025

;; Strategic Purpose: Define the "Revenue Streams & Customer Relationships" component interface of the Business Model Canvas of CineX
;; This trait ensures campaign processes and backer interactions are well handled 

(define-trait crowdfunding-trait
  (
    ;; Create a new campaign
     ;; parameters: 
        ;; project-description - (string-ascii 500); campaign-id - uint 
        ;; funding goal - uint; duration - uint;  reward-tiers-count - uint; reward-description -(string-ascii 150) 
    (create-campaign ((string-ascii 500) uint uint uint uint) (response uint uint))
    
    ;; Contribute funds to a campaign
        ;; paramters: 
            ;; campaign ID - uint; amount - uint; 
    (contribute-to-campaign (uint uint) (response bool uint))
    
    ;; Claim contributed funds as campaign owner
        ;; paramters: 
            ;; campaign ID - uint;
     (claim-campaign-funds (uint) (response bool uint))
    
    ;; Get campaign details
        ;; parameters:
            ;; campaign ID - uint
    (get-campaign (uint) (response {
        description: (string-ascii 500),
        funding-goal: uint,
        duration: uint,
        owner: principal,
        reward-tiers: uint,
        reward-description: (string-ascii 150),
        total-raised: uint,
        active: bool
      } uint))
    )
)
