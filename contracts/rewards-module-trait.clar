
;; title: rewards-module-trait
;; version: 1.0.0


(define-trait rewards-trait
  (
    ;; Award reward to contributor
        ;; @params:
            ;; campaign ID - uint; contributor - principal; reward-tier - uint; reward-description - (string-ascii 150); 
    (award-campaign-reward (uint principal uint (string-ascii 150)) (response uint uint))
    
    ;; Batch award rewards
        ;; @params:
            ;; campaign ID - uint; contributors - (list 50 principal); reward-tiers - (list 50 uint); reward-descriptions - (string-ascii 150)
    (batch-award-campaign-rewards (uint (list 50 principal) (list 50 uint) (list 50 (string-ascii 150))) (response uint uint))
    
    ;; Get reward details
        ;;@prams:
            ;; campaign-ID - uint
            ;; contributor - principal
    (get-contributor-reward (uint principal) (response {
        tier: uint,
        description: (string-ascii 150),
        token-id: (optional uint)
      } uint))
  )
)

