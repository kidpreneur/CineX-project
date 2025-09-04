;; title: film-verification-module
;; Author: Victor Omenai 
;; Created: 2025
;; version: 1.0.0

;;;; ============= Description ==============
;; Implementation of Film verification module trait
;; Strategic Purpose: Build trust between backers and filmmakers through identity verification
;; This addresses the "Customer Relationships" component of the Business Model Canvas of CineX

;; ========== TRAIT REFERENCE ==========
;; Implementing the film-verification trait to ensure standard interface
(impl-trait .film-verification-module-trait.film-verification-trait)

;; ========== ERROR CONSTANTS ==========
;; Define error codes for better debugging and user feedback
(define-constant ERR-NOT-AUTHORIZED (err u1001))
(define-constant ERR-FILMMAKER-NOT-FOUND (err u1002))
(define-constant ERR-INVALID-VERIFICATION-LEVEL-INPUT (err u1003))
(define-constant ERR-ALREADY-REGISTERED (err u1004))
(define-constant ERR-PORTFOLIO-NOT-FOUND (err u1005))
(define-constant ERR-ENDORSEMENT-NOT-FOUND (err u1006))
(define-constant ERR-VERIFICATION-EXPIRED (err u1007))
(define-constant ERR-TRANSFER (err u1008))
(define-constant ERR-NOT-VERIFIED (err u1009 ))


;; ========== CONSTANTS ==========
;; Define list of verification levels  
(define-constant basic-verification-level u1)
(define-constant standard-verification-level u2)

;; Define verification fees (in microSTX) 
(define-constant basic-verification-fee u2000000);; 2 STX 
(define-constant standard-verification-fee u3000000) ;; 3 STX


;; Verified-id valid period (in blocks, approximately 1 year, i.e, u52560 blocks) 
(define-constant basic-verified-id-valid-period u52560) ;; level 1 verification validity
(define-constant standard-verified-id-valid-period (* u52560 u2)) ;; level 2 verification validity

;; ========== DATA VARIABLES ==========

;; Store the contract administrator who can verify filmmakers
(define-data-var contract-admin principal tx-sender)

;; Store the address of any third-party endorser
(define-data-var third-party-endorser principal tx-sender)

;; Store the main hub contract reference
(define-data-var core-contract principal tx-sender)

;; Keep track of total registered filmmakers for analytics
(define-data-var total-registered-filmmakers uint u0)

;; Keep track of total verification fee collected for accounting 
(define-data-var total-verification-fee-collected uint u0)

;; Keep track of total registered filmmaker portfolios for analytics
(define-data-var total-filmmaker-portfolio-counts uint u0) 

;; Keep track of total registered endorsements for analytics 
(define-data-var total-filmmaker-endorsement-counts uint u0) 

;; Add data variable to store renewal extension contract reference
(define-data-var renewal-extension-contract principal tx-sender)

;; ========== DATA MAPS ==========
;; Store filmmaker identity information
(define-map filmmaker-identities principal { 
    full-name: (string-ascii 100), ;; full legal name
    profile-url: (string-ascii 255), ;; link to filmmaker's professional profile
    identity-hash: (buff 32), ;; hash of identity document
    choice-verification-level: uint, ;; uint to track filmmaker as level 1 or 2 verified
    choice-verification-expiration: uint, ;; validity period of verification level
    verified: bool,
    registration-time: uint
    })

;; Track portfolio items (projects) by filmmaker and portfolio ID
(define-map filmmaker-portfolios { filmmaker: principal, portfolio-id: uint } { 
    project-name: (string-ascii 100), ;; name of previous project
    project-url: (string-ascii 255), ;; link to previous project
    project-description: (string-ascii 500), ;; brief description of project
    project-completion-year: uint, ;; uint year project was completed
    added-at-time: uint ;; uint record of blockheight time when portfolio documents were added
    })

;; Track endorsements by filmmaker and endorsement ID
(define-map filmmaker-endorsements { filmmaker: principal, endorsement-id: uint } { 
    endorser-name: (string-ascii 100), ;;name of endorsing entity
    endorsement-letter: (string-ascii 255), ;; brief endorsement text
    endorsement-url: (string-ascii 255), ;; verification link for endorsement 
    added-at-time: uint ;; uint record of blockheight time when endorsement details were added
    })

;; Track portfolio counter per filmmaker
(define-map filmmaker-portfolio-counts principal uint)

;; Track endorsement counter per filmmaker
(define-map filmmaker-endorsement-counts principal uint)

;; ========== PRIVATE FUNCTIONS =========
;; Helper to validate if a filmmaker is registered
(define-private (is-registered (filmmaker principal))
  (is-some (map-get? filmmaker-identities filmmaker))
)

;; Helper to check if caller is admin
(define-private (is-admin) 
    (is-eq tx-sender (var-get contract-admin))
)

;; Helper to check if contract-caller of add-endorsement func is a third-party endorser 
(define-private (is-endorser)
    (is-eq tx-sender (var-get third-party-endorser))
) 

;; Helper to check endorsement count
(define-private (get-endorsement-count (new-filmmaker principal)) 
    (default-to u0 (map-get? filmmaker-endorsement-counts new-filmmaker))
)

;; Helper to check if filmmaker is currently verfied
(define-private (is-verification-current (new-added-filmmaker principal))
     (let 
            (
                ;; Get filmmaker data
                (existing-filmmaker-data (unwrap! (map-get? filmmaker-identities new-added-filmmaker) ERR-FILMMAKER-NOT-FOUND))
                ;; get existing verified status
                (verified-status (get verified existing-filmmaker-data))

                ;; get current verificaton expiry period
                (current-verification-expiration (get choice-verification-expiration existing-filmmaker-data))

                ;; check if new-filmmaker is registered (as input) in the read-only func
                (is-filmmaker-registered (is-registered new-added-filmmaker))
                                            
            )          
            (match (map-get? filmmaker-identities new-added-filmmaker)
                ;; bind result to verification-current
                verification-current (begin
                                        ;; check that verified is true
                                        (asserts! (is-eq  verified-status true) ERR-NOT-VERIFIED)

                                        ;; check that verification expiration is <= basic-verified-id-valid-period or <= standard-verified-id-valid-period 
                                        (asserts! (or (<= current-verification-expiration basic-verified-id-valid-period)
                                                    (<= current-verification-expiration standard-verified-id-valid-period)) ERR-NOT-VERIFIED) 
                                
                                        (ok true)       
                                     )
                                        
                ;; else, return false
                ERR-VERIFICATION-EXPIRED
            )                                            
            
     ) 
)                             
    
;; ========== PUBLIC FUNCTIONS ==========
;; Function to register a filmmaker's identity
    ;; Strategic Purpose: Establish the foundation for filmmakers to register ther identity for verification
(define-public (register-filmmaker-id (new-filmmaker principal) 
    (new-full-name (string-ascii 100)) 
    (new-profile-url (string-ascii 255)) 
    (new-identity-hash (buff 32))    
    (new-choice-verification-level uint) 
    (new-choice-verification-level-expiration uint)) 
    (let 
        (
            ;; existing total registered filmmakers and new total registred filmmakers respectively
            (existing-total-registered-filmmakers (var-get total-registered-filmmakers))
            (new-total-registered-filmmakers (+ u1 existing-total-registered-filmmakers))

            ;; check if new-filmmaker is registered (as input) in the read-only func
           ;; (is-filmmaker-registered (is-registered new-filmmaker))

        ) 
        ;; Ensure the caller is the filmmaker being registered
        (asserts! (is-eq new-filmmaker tx-sender) ERR-NOT-AUTHORIZED)

        ;; Ensure the filmmaker is not already registered
        (asserts! (not (is-registered new-filmmaker)) ERR-ALREADY-REGISTERED)

        ;; Store the filmmaker's identity information
        (map-set filmmaker-identities new-filmmaker {
            full-name: new-full-name, 
            profile-url: new-profile-url, 
            identity-hash: new-identity-hash, 
            choice-verification-level: new-choice-verification-level, ;; filmmaker chooses what level of verification level they would want to opt for 
            choice-verification-expiration: new-choice-verification-level-expiration, ;; filmmaker inputs default expiration period of their choice verification level 
            verified: false, ;; Typically false since filmmaker's identity is yet to be verified
            registration-time: block-height
        })

        ;; Initialize portfolio and endorsement counts respectively 
        (map-set filmmaker-portfolio-counts new-filmmaker u0) ;; no count yet until filmmaker identity is verified 
        (map-set filmmaker-endorsement-counts new-filmmaker u0) ;; Typically no endorsement yet

        ;; Increment count of total registered filmmakers, verified/endorsed  or not
        (var-set total-registered-filmmakers new-total-registered-filmmakers)
        (ok new-total-registered-filmmakers)
    )
)

;; Function to add filmmaker's portfolio item
 ;; Strategic Purpose: Allow filmmakers to showcase their track record
(define-public (add-filmmaker-portfolio (new-added-filmmaker principal) 
    (new-added-project-name (string-ascii 100)) 
    (new-added-project-url (string-ascii 255)) 
    (new-added-project-desc (string-ascii 500)) 
    (new-added-project-completion-year uint))
    (let 
        (
            ;; check if new-filmmaker is registered (as input) in the read-only func
            (is-filmmaker-registered (is-registered new-added-filmmaker))
            ;; current portfolio count
            (current-filmmaker-portfolio-counts (default-to u0 (map-get? filmmaker-portfolio-counts new-added-filmmaker)))
            ;; new filmmaker counts
            (new-filmmaker-counts (+ u1 current-filmmaker-portfolio-counts))
            ;; existing total filmmaker portfolio counts and new-total flimmaker portfolio counts
            (existing-total-filmmaker-portfolio-counts (var-get total-filmmaker-portfolio-counts)) 
            (new-total-filmmaker-portfolio-counts (+ u1 existing-total-filmmaker-portfolio-counts)) 
        ) 
        ;; Ensure the caller is the filmmaker 
        (asserts! (is-eq tx-sender new-added-filmmaker) ERR-NOT-AUTHORIZED)  

        ;; Ensure filmmaker is registered
        (asserts! is-filmmaker-registered ERR-FILMMAKER-NOT-FOUND)

        ;; Store the portfolio item
        (map-set filmmaker-portfolios { filmmaker: new-added-filmmaker, portfolio-id: new-filmmaker-counts } {
            project-name: new-added-project-name, 
            project-url: new-added-project-url, 
            project-description: new-added-project-desc, 
            project-completion-year: new-added-project-completion-year, 
            added-at-time: block-height 
        })
        
        ;; Update total filmmaker portfolio counts
        (var-set total-filmmaker-portfolio-counts new-total-filmmaker-portfolio-counts) 
        ;; Total filmmaker endorsement count still remains u0
        (var-set total-filmmaker-endorsement-counts u0 ) 

        ;; Update filmmaker portfolio count
        (map-set filmmaker-portfolio-counts new-added-filmmaker new-filmmaker-counts)
        (ok new-filmmaker-counts)
    )
)

;; Function to verify a filmmaker (admin only)
    ;; Strategic Purpose: Provide platform-level verification of identity
(define-public (verify-filmmaker-identity (new-added-filmmaker principal) (new-verificaion-level uint) (new-expiration-block uint)) 
    (let 
        (
            ;; Get filmmaker data
            (existing-filmmaker-data (unwrap! (map-get? filmmaker-identities new-added-filmmaker) ERR-FILMMAKER-NOT-FOUND))

            ;; Get verification-level-data and verification expiration data
            (existing-choice-verification-level-data (get choice-verification-level existing-filmmaker-data))
            (exisitng-choice-ver-level-expiration (get choice-verification-expiration existing-filmmaker-data))

            ;; Get core contract
            (current-core-contract (var-get core-contract))

            ;; Get current total fees; then calculate both new-total-basic-verification-fee-collected and new-total-standard-verification-fee-collected respectively 
            (current-total-verification-fee (var-get total-verification-fee-collected))
            (new-total-basic-verification-fee-collected (+ basic-verification-fee current-total-verification-fee))
            (new-total-standard-verification-fee-collected (+ standard-verification-fee current-total-verification-fee))
        
        ) 
        ;; Ensure caller is admin
        (asserts! (is-admin) ERR-NOT-AUTHORIZED)

        ;; Ensure existing verification level data 
        (if (is-eq existing-choice-verification-level-data basic-verification-level) 
                (begin 
                    ;; Collect basic verification fee from filmmaker
                    (unwrap! (stx-transfer? basic-verification-fee new-added-filmmaker current-core-contract) ERR-TRANSFER) 
                    ;; Update total fees collected
                    (var-set total-verification-fee-collected new-total-basic-verification-fee-collected)
                    ;; Update filmmaker verification status
                    (map-set filmmaker-identities new-added-filmmaker
                        (merge existing-filmmaker-data
                            { 
                                verified: true,
                                registration-time: block-height 
                            }
                        )
                    )
                    (ok true)
                )
                (begin 
                    ;; Collect standard verification fee from filmmaker
                    (unwrap! (stx-transfer? standard-verification-fee new-added-filmmaker current-core-contract) ERR-TRANSFER) 
                    ;; Update total fees collected
                    (var-set total-verification-fee-collected new-total-standard-verification-fee-collected)
                    ;; Update filmmaker verification status
                    (map-set filmmaker-identities  new-added-filmmaker 
                        (merge existing-filmmaker-data 
                            { 
                                verified: true,
                                registration-time: block-height
                            }
                        )
                    )   
                    (ok true)     
                )              
        )      
    )
)

;; Function to update filmmaker verification expiration (called by verification renewal function in the feeextension)
    ;; Strategic Purpose: Transforms verification from a one-time transaction into a recurring revenue stream while maintaining 
    ;;                      continuous filmmaker-backer trust relationships and reducing customer churn.
(define-public (update-filmmaker-expiration-period (new-filmmaker principal) (new-expiration-period uint)) 
    (let 
        (
            (current-filmmaker-identities-data (unwrap! (map-get? filmmaker-identities new-filmmaker) ERR-FILMMAKER-NOT-FOUND))

            ;; Get renewal-extension contract address
            (current-renewal-extension-contract (var-get renewal-extension-contract))

            ;;Get currently-verified 
            (currently-verified (is-verification-current new-filmmaker))
            

        ) 
        ;; Ensure caller is authorized (either admin or the renewal extension contract)
        (asserts! (or (is-admin) (is-eq tx-sender current-renewal-extension-contract)) ERR-NOT-AUTHORIZED)

        ;; Ensure filmmaker is currently verified
        (asserts! (is-ok currently-verified) ERR-NOT-VERIFIED)

        ;; Update the filmmaker's expiration period
        (map-set filmmaker-identities new-filmmaker
            (merge current-filmmaker-identities-data
                {
                    choice-verification-expiration: new-expiration-period,
                    registration-time: block-height  ;; Reset registration time for new 
                } 
            )
        )

        (ok new-expiration-period)
        
    )
)

;; Function to add third-party endorsements for a filmmaker
    ;; Strategic Purpose: Enhance trust through industry recognition
 (define-public (add-filmmaker-endorsement (new-added-filmmaker principal) 
    (new-endorser-name (string-ascii 100)) 
    (new-endorsement-letter (string-ascii 255)) 
    (new-endorsement-url (string-ascii 255)))
    (let 
        (
            ;; Get current endorsement count and Calculate new endorsement count
            (current-endorsement-count (get-endorsement-count new-added-filmmaker))  
            ;; Calculate new endorsement count
            (new-endorsement-count (+ u1 current-endorsement-count))

            ;; check if new-filmmaker is registered (as input) in the read-only func
            (is-filmmaker-registered (is-registered new-added-filmmaker))
            
            
        )
        
         ;; Ensure the caller is the filmmaker, admin, or from an approved endorser
         (asserts! (or (is-eq tx-sender new-added-filmmaker) (is-admin) (is-endorser)) ERR-NOT-AUTHORIZED)

        ;; Ensure filmmaker is registered
        (asserts! is-filmmaker-registered ERR-FILMMAKER-NOT-FOUND)

        ;; Store the endorsement
        (map-set filmmaker-endorsements { filmmaker: new-added-filmmaker, endorsement-id: new-endorsement-count } { 
            endorser-name: new-endorser-name, 
            endorsement-letter: new-endorsement-letter, 
            endorsement-url: new-endorsement-url,  
            added-at-time: block-height 
        })
                      
        ;; Update endorsement count
        (map-set filmmaker-endorsement-counts new-added-filmmaker new-endorsement-count)

        ;; Return result as new endorsement count
        (ok new-endorsement-count)
    )
 )
    
;; ========== ADMIN FUNCTIONS ==========
;; Function to set the contract administrator
(define-public (set-contract-admin (new-admin principal)) 
    (begin 
        (asserts! (is-admin) ERR-NOT-AUTHORIZED)
        (ok (var-set contract-admin new-admin))
    )
)

;; Function to set the core contract
(define-public (set-core-contract (new-core principal)) 
    (begin 
        (asserts! (is-admin) ERR-NOT-AUTHORIZED)
        (ok (var-set core-contract new-core))
    )
)

;; Function to set the renewal extension contract (admin only as well
(define-public (set-renewal-extension-contract (extension-contract principal))
    (begin
        (asserts! (is-admin) ERR-NOT-AUTHORIZED)
        (ok (var-set renewal-extension-contract extension-contract))
    )
)

;; ========== THIRD-PARTY FUNCTION ==========
;; Function to enable contract-admin set optional third-party endorsers
(define-public (set-third-party-endorser (new-endorser principal)) 
    (begin 
        (asserts! (is-admin) ERR-NOT-AUTHORIZED)
        (ok (var-set third-party-endorser new-endorser))
    )
)


;; ========== READ-ONLY FUNCTIONS ==========
 ;; Function to check if filmmaker has a portfolio 
(define-read-only (is-portfolio-available (new-filmmaker principal) (new-id uint))
    (match (map-get? filmmaker-portfolios { filmmaker: new-filmmaker, portfolio-id: new-id })
        portfolio-available (ok true)
        ;; If not found, return error 
        ERR-PORTFOLIO-NOT-FOUND
    )
)

;; Function to check if filmmaker's verification status is current, and not expired
(define-read-only (is-filmmaker-currently-verified (new-filmmaker principal))
  (is-verification-current new-filmmaker)
  
)

;; Function to check if filmmaker is endorsed
(define-read-only (is-endorsement-available (new-filmmaker principal) (new-id uint))
    (match (map-get? filmmaker-endorsements { filmmaker: new-filmmaker, endorsement-id: new-id })
        endorsement-available (ok true)
        ;; If not found, return error
        ERR-ENDORSEMENT-NOT-FOUND
     )
)

;; Function to get full details of filmmaker identity
(define-read-only (get-filmmaker-identity (new-filmmaker principal)) 
    (ok (map-get? filmmaker-identities new-filmmaker))
)

;; Function to get full details of filmmaker portfolio
(define-read-only (get-filmmaker-portfolio (new-filmmaker principal) (new-id uint)) 
    (map-get? filmmaker-portfolios { filmmaker: new-filmmaker,  portfolio-id: new-id })
)

;; Function to get full details of filmmaker endorsement letter
(define-read-only (get-filmmaker-endorsements (new-filmmaker principal) (new-id uint)) 
    (map-get? filmmaker-endorsements { filmmaker: new-filmmaker, endorsement-id: new-id })
    
)


;; Function to get total registered filmmakers
(define-read-only (get-total-filmmakers)
  (var-get total-registered-filmmakers)
)

;; Function to get total verification fees collected
(define-read-only (get-total-verification-fees)
  (var-get total-verification-fee-collected)
)

;; Function to get total registered filmmaker portfolios
(define-read-only (get-total-registered-filmmaker-portfolios)
    (var-get total-filmmaker-portfolio-counts)
)

;; Function to get total registered endorsements
(define-read-only (get-total-filmmaker-endorsements) 
    (var-get total-filmmaker-endorsement-counts)
)

;; Function to get the core contract
(define-read-only (get-core) 
    (var-get core-contract)
)

;; Function to get third-party endorser address
(define-read-only (get-third-party-address) 
    (var-get third-party-endorser)
)

;; Function to get the contract admin
(define-read-only (get-contract-admin)
    (ok (var-get contract-admin))
)



