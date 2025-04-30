
;; title: escrow-module-trait
;; version: 1.0.0
;; summary:  Traits  of Escrow Module for Secure Fund Management of campaign funds


(define-trait escrow-trait
  (
    ;; Deposit funds to campaign
     ;; @params: 
        ;; campaign ID - uint; amount - uint
    (deposit-to-campaign (uint uint) (response bool uint))
    
    ;; Withdraw funds from campaign
        ;; @params: 
            ;; campaign ID - uint; amount - uint
    (withdraw-from-campaign (uint uint) (response bool uint))
    
    ;; Collect platform fee
        ;; @params: 
            ;; campaign ID - uint; fee amount - uint
    (collect-campaign-fee (uint uint) (response bool uint))
    
    ;; Get campaign balance
    ;; @params: 
        ;; campaign ID - uint
    (get-campaign-balance (uint) (response uint uint))
  )
)