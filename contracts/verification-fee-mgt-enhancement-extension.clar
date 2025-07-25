
;; title: verification-fee-mgt-enhancement-extension

;; Author: Victor Omenai 
;; Created: 2025
;; version: 1.0.0

;;;; ============= Description ==============
;; Complementary enhancements to the existing film verification fee system. 
;; Does NOT duplicate existing functionality, only adds value-added features

;; Strategic Purpose: Provides Value Proposition to the campaign creators, verifiers and the platform itself:
;;  - Good campaign creators get the value of getting re-verification without incurring full re-verification costs
;;  - Verifiers get the value of a verifier's treasury - a source of financial incentives for their verifying tasks
;;  - The platform gets a sustainable revenue model both in high market and low market periods, made possible by the value 
;;    of a market-based pricing system for verification and its attendant dynamic fee adjustment multiplier  



;; ========== ADDITIONAL ERROR CONSTANTS ==========
(define-constant ERR-NOT-AUTHORIZED (err u2000))
(define-constant ERR-VERIFICATION-ADMIN-NOT-FOUND (err u2001))
(define-constant ERR-RENEWAL-TOO-EARLY (err u2002));; Trying to renew too soon
(define-constant ERR-INSUFFICIENT-BALANCE (err u2003)) 
(define-constant ERR-INVALID-FEE-ADJUSTMENT (err u2004))
(define-constant ERR-NOT-VERIFIED (err u2005))
(define-constant ERR-FILMMAKER-NOT-FOUND (err u2006))
(define-constant ERR-TRANSFER (err u2007))
(define-constant ERR-EXPIRATION-UPDATE-FAILED (err u2008))

;; ========== ADDITIONAL CONSTANTS ==========
;; Discount percentages (complementing existing fees) for renewal of verification
(define-constant VERIFICATION-RENEWAL-DISCOUNT-PERCENT u50) ;; 50% discount for renewals 

;; Fee adjustment limits (market-based pricing)
    ;; @func: charges more during busy times and less during quiet times. The system therefore can adjust verification fees based on demand
(define-constant MIN-FEE-MULTIPLIER u50) ;; 50% of base fee (minimum) when demand is high
(define-constant MAX-FEE-MULTIPLIER u20) ;; 20% of base fee (maximum) when demand is disturbingly low

;; Revenue sharing (new-feature)
(define-constant PLATFORM-SHARE u70) ;; 70% to platform treasury
(define-constant VERIFIERS-SHARE u30) ;; 30% to verification team

;; ========== ADDITIONAL DATA VARIABLES ==========
;; Dynamic Fee- Adjustment Multiplier (complements fixed verification fees in main film verification module)  
(define-data-var fee-adjustment-multiplier uint u100) ;; works as a Current price multiplier (100 = normal pricing, 150 = 50% more expensive)

;; Revenue distribution addresses
(define-data-var platform-treasury principal tx-sender)
(define-data-var verifiers-treasury principal tx-sender)

;; Reference to main verification module
(define-data-var verification-module principal tx-sender)

;; distribution revenue period counter - Keeping track of which distribution period we're on
(define-data-var distribution-revenue-period-counter uint u0)

;; ========== ADDITIONAL DATA MAPS ==========
;; Track filmmaker payment history  (complements existing fee tracking in the film-verification-module)
(define-map filmmaker-payment-history { filmmaker: principal, payment-index: uint } { 
    amount: uint,
    verification-level: uint,
    payment-type: (string-ascii 10), ;; for "initital verification" or "renewal"
    block-height: uint,
    fee-multiplier: uint ;; what multiplier was used for a unique payment 
    })

;; Payment counters per filmmaker 
        ;; @func: counts how many verfication payments each filmmaker has made
(define-map filmmaker-verification-payments-counter principal uint) ;; tracks each payment index by the tx-sender of unique filmmaker

;; Revenue distribution tracking (complements main module's total tracking)
    ;; ;; Like a financial report showing the distribution of verification payments between the CineX platform and verifiers treasury
(define-map revenue-distribution uint { 
    period-start: uint, ;; when a distribution perod started
    period-end: uint, ;; when a distribution period ended
    total-collected: uint,
    platform-amount: uint, ;; how much went to the platform
    verifier-amount: uint, ;; how much went to the verifiers
    distributed: bool ;; whether money has been sent out or not 
    })      


;; ========== ADMIN FUNCTIONS ==========
;; Set verification module reference
(define-public (set-verification-module (new-module principal))
    (begin 
    ;; ensure only platform treasury can initially set the address for the film-verification module
        (asserts! (is-eq tx-sender (var-get platform-treasury)) ERR-NOT-AUTHORIZED)
        (var-set verification-module new-module)
        (ok true)    
    )  
)

;; Set platform treasury address
(define-public (set-platform (new-platform principal))
    (begin 
        (asserts! (is-eq tx-sender 
                            (unwrap! (contract-call? .film-verification-module get-contract-admin) ERR-VERIFICATION-ADMIN-NOT-FOUND))
             ERR-NOT-AUTHORIZED)  
        (var-set platform-treasury new-platform)
        (ok new-platform)
        
    )
)

;; Set verifiers treasury address
(define-public (set-verifier (new-verifier principal)) 
    (begin 
        (asserts! (is-eq tx-sender 
                            (unwrap! (contract-call? .film-verification-module get-contract-admin) ERR-VERIFICATION-ADMIN-NOT-FOUND))
             ERR-NOT-AUTHORIZED)  
        (var-set verifiers-treasury new-verifier)
        (ok new-verifier)
    )
    
)
   

;; ========== ENHANCEMENT FUNCTIONS ==========
;; ========== Helper functions ==========
;; Enhanced fee calculation (uses main module's base fees)
    ;; Purpose: to calculate how much adjusted fee is based on multiplier 
    ;; @params: base-fee - uint starting price for verification services before any adjustments are applied
(define-private (calculate-adjusted-fee (base-fee uint)) 
    ;; calculate how much the adjusted fee is based on dynamic multiplier 
    (/ (* base-fee (var-get fee-adjustment-multiplier)) u100)
)

;; Get current fees with market adjustments
(define-read-only (get-current-verifiation-fees)
    (let 
        (
            ;; Get base fees from main module constants
            (base-basic-fee u2000000) ;; 2 STX
            (base-standard-fee u3000000) ;; 3 STX
        ) 
        {basic-fee: (calculate-adjusted-fee base-basic-fee), ;; evaluate calculate-adjusted-fee by its input new-base-basic-fee to derive basic-fee
        standard-fee: (calculate-adjusted-fee base-standard-fee), ;; same with deriving standard-fee
        basic-renewal-fee: (/ (calculate-adjusted-fee base-basic-fee) u2), ;; final adjusted price by discount of 50% (slashing basic-fee by half)
        standard-renewal-fee: (/ (calculate-adjusted-fee base-standard-fee) u2) ;; final adjusted price by discount of 50% (slashing basic-fee by half)
        }   
    )
)

;; ========== Public Functions ==========
;; Verification renewal function (complements main verification)
    ;; Strategic Purpose: Achieves added value propostion to campaign creators in the course of identity verification renewal 
        ;; this makes it easier and cheaper than getting a new one
(define-public (verification-renewal (new-filmmaker principal)) 
    (let 
        (
            ;; Check filmmaker is currently verified    
            (verified (unwrap! (contract-call? .film-verification-module is-filmmaker-currently-verified tx-sender) ERR-NOT-VERIFIED))
            
            ;; Check full verification data
            (current-verification-data (unwrap! (contract-call? .film-verification-module get-filmmaker-identity tx-sender) ERR-FILMMAKER-NOT-FOUND))

            ;; Get current-verification-level 
            (current-verification-level  (unwrap! (get choice-verification-level current-verification-data) ERR-FILMMAKER-NOT-FOUND))

            ;; Get expiration-period per unique current verified account  and calculate new-expiration-periodonce renewal is successfully processed
            (current-expiration-period  (unwrap! (get choice-verification-expiration current-verification-data) ERR-FILMMAKER-NOT-FOUND))      
            (new-expiration-period (+ current-expiration-period (if (is-eq current-verification-level u1)
                                                                            u52560
                                                                            (* u52560 u2)
                                                                )))

            ;; Get current verification registration time
            (current-registration-time  (unwrap! (get registration-time current-verification-data) ERR-FILMMAKER-NOT-FOUND))

            ;; 75% of Current verification period 
            (current-75-percent-of-verification-period  (/ (* (- current-expiration-period current-registration-time) u75) u100))

            ;; Get appropriate renewal fee corresponding to current campaign's verification level
            (appropriate-renewal-fee (if (is-eq current-verification-level u1) 
                                            (/ (calculate-adjusted-fee u2000000) u2) ;; Basic renewal
                                            (/ (calculate-adjusted-fee u3000000) u2) ;; Standard renewal
                                     ))

            ;; Get current payment count and calculate new payment count
            (current-filmmaker-payment-count (default-to u0 (map-get? filmmaker-verification-payments-counter new-filmmaker)))
            (new-filmmaker-payment-count (+ current-filmmaker-payment-count u1))

            ;;Get current-fee-multiplier
            (current-fee-multiplier (var-get fee-adjustment-multiplier))

        )
         ;; Ensure caller is the filmmaker
         (asserts! (is-eq tx-sender new-filmmaker) ERR-NOT-AUTHORIZED)

         ;; Ensure renewal isn't too early (at least 75% through current period)
            ;;by checking that current blockheight is greater than earliest allowed time for renewal 
                ;; Prevents spamming renewals so users can't renew immediately after registering, the rules therefore fair to both basic and premium verification levels
         (asserts! (> block-height (+ current-registration-time current-75-percent-of-verification-period)) ERR-RENEWAL-TOO-EARLY) 

        ;; Collect renewal fee (goes to contract, will be distributed later)
        (unwrap! (stx-transfer? appropriate-renewal-fee tx-sender (as-contract tx-sender)) ERR-TRANSFER)

        

        ;; Record payment in filmmaker-payent-history map
        (map-set filmmaker-payment-history {filmmaker: new-filmmaker, payment-index: new-filmmaker-payment-count } {
            amount: appropriate-renewal-fee,
            verification-level: current-verification-level,
            payment-type: "renewal",
            block-height: block-height,
            fee-multiplier: current-fee-multiplier ;; multiplier used for this unique payment
            })

         ;; Update payment count
         (map-set filmmaker-verification-payments-counter new-filmmaker new-filmmaker-payment-count)

        ;; Call main module to update expiration 
        (unwrap! (contract-call? .film-verification-module update-filmmaker-expiration-period new-filmmaker new-expiration-period) ERR-EXPIRATION-UPDATE-FAILED)
        
        ;; For now, we'll return success indicating renewal payment processed
        (ok {
            renewal-fee: appropriate-renewal-fee,
            new-expiration: new-expiration-period,
            payment-index: new-filmmaker-payment-count
        })
    )
)

;; Revenue distribution for a period function (complements main module's fee collection)
(define-public (distribute-revenue-for-period)
    (let 
        (
            ;; Check contract balance
            (contract-balance (stx-get-balance (as-contract tx-sender)))

            ;; Calculate distribution share between platform-treasury and verifiers-treasury
            (platform-amount (/ (* PLATFORM-SHARE contract-balance) u100)) ;; Platform-share, 70% of contract-balance
            (verifiers-amount (/ (* VERIFIERS-SHARE contract-balance) u100)) ;; Verifier share, 30% of contract-balance

            ;; Get platform-treasury
            (current-platform-treasury (var-get platform-treasury))    

            ;; Get verifiers-treasury
            (current-verifiers-treasury (var-get verifiers-treasury))

            ;; Get revenue period and calculate new-period-counter
            (current-distribution-revenue-period-counter (var-get distribution-revenue-period-counter)) 
            (new-period-counter (+ current-distribution-revenue-period-counter u1))
            
        ) 
        ;; Ensure caller is admin (check with main module)
        (asserts! (is-eq tx-sender (unwrap! 
                                        (contract-call? .film-verification-module get-contract-admin) ERR-VERIFICATION-ADMIN-NOT-FOUND))
                        ERR-NOT-AUTHORIZED)

        ;; Ensure there's balance to distribute
        (asserts! (> contract-balance u0) ERR-INSUFFICIENT-BALANCE)

        ;; Distribute to platform treasury
        (unwrap! (as-contract (stx-transfer? platform-amount tx-sender current-platform-treasury)) ERR-TRANSFER)

         ;; Distribute to verifier treasury
        (unwrap! (as-contract (stx-transfer? verifiers-amount tx-sender current-verifiers-treasury)) ERR-TRANSFER)

        ;; Record distribution in the revenue-distribution map   
        (map-set revenue-distribution new-period-counter { 
            period-start: (- block-height u144), ;; Start counting every revenue collected from the difference between 144 blocks ago and block-height 
            period-end: block-height, ;; Stop counting every revenue collected from the current block, backing up to every revenue collected 144 blocks ago
            total-collected: contract-balance,
            platform-amount: platform-amount, ;; how much went to the platform
            verifier-amount: verifiers-amount, ;; how much went to the verifiers
            distributed: true 
        })

         ;; Update period counter
        (var-set distribution-revenue-period-counter new-period-counter)
         ;; Return success details of what was distributed for the period processed
         (ok {
            period: new-period-counter,
            total-distributed: contract-balance,
            platform-share: platform-amount,
            verifiers-share: verifiers-amount
         })
    )
)



;; Market-based fee adjustment (complements fixed fees in main module)
(define-public (adjust-fee-multiplier (new-multiplier uint)) 
    (begin 
        ;; Ensure caller is admin (check with main module)
        (asserts! (is-eq tx-sender 
                            (unwrap! (contract-call? .film-verification-module get-contract-admin) ERR-VERIFICATION-ADMIN-NOT-FOUND)) 
                    ERR-NOT-AUTHORIZED)

        ;; Ensure multiplier is within acceptable range, i.e., adjustment is reasonable (between 50% and 200% of normal price)
        (asserts! (or (>= new-multiplier MIN-FEE-MULTIPLIER) (<= new-multiplier MAX-FEE-MULTIPLIER)) ERR-INVALID-FEE-ADJUSTMENT)

        ;; Update the fee multiplier
        (var-set fee-adjustment-multiplier new-multiplier)
        (ok new-multiplier)
    )
)

;; ========== READ-ONLY FUNCTIONS ==========
;; Get payment history for a filmmaker
(define-read-only (get-filmmaker-payment-history (new-filmmaker principal))
    (let 
        (
            ;; Get current-paymet-count
            (current-payment-count (default-to u0 (map-get? filmmaker-verification-payments-counter new-filmmaker)))
        ) 
        {
            total-payment: current-payment-count,
            last-payment: (map-get? filmmaker-payment-history { filmmaker: new-filmmaker, payment-index: current-payment-count})

        }
            
    )
)

;; Get current fee multiplier and adjusted fees,
    ;; @func: checking what is the fee multiplier, as well as the adjusted-fee per period that could be either peak or off-peak 
(define-read-only (get-current-adjusted-fee-status) 
    (let 
        (
            ;; Get fee-adjustment-multiplier
            (current-fee-adjustment-multiplier (var-get fee-adjustment-multiplier))
            
        ) 
        {
            fee-multiplier: current-fee-adjustment-multiplier,
            cureent-adjusted-fee: (get-current-verifiation-fees)
        }
        
    )
)

;; Get revenue distribution for a period, i.e., checking a financial report for a specific month
(define-read-only (get-revenue-distribution (period uint))
    (map-get? revenue-distribution period)
)

;; Get total contract balance available for distribution
(define-read-only (get-available-balance-for-distribution)
    (stx-get-balance (as-contract tx-sender))
)


