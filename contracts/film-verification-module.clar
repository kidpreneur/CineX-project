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
(define-constant ERR-NOT-AUTHORIZED (err 1001))
(define-constant ERR-FILMMAKER-NOT-FOUND (err 1002))
(define-constant ERR-INVALID-VERIFICATION-LEVEL-INPUT (err 1003))
(define-constant ERR-ALREADY-REGISTERED (err 1004))
(define-constant ERR-PORTFOLIO-NOT-FOUND (err 1005))
(define-constant ERR-ENDORSEMENT-NOT-FOUND (err 1006))
(define-constant ERR-VERIFICATION-EXPIRED (err 1007))
(define-constant ERR-TRANSFER (err 1008))


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

;; ========== DATA MAPS ==========
;; Store filmmaker identity information
(define-map filmmaker-identities principal { 
    full-name: (string-ascii 100), ;; full legal name
    profile-url: (string-ascii 255), ;; link to filmmaker's professional profile
    identity-hash: (buff 32), ;; hash of identity document
    verification-level: uint, ;; uint to track filmmaker as level 1, 2 or 3 verified
    verification-expiration: uint, ;; validity period of verification level
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

;; ========== PUBLIC FUNCTIONS ==========
;; Function to register a filmmaker's identity
    ;; Strategic Purpose: Establish the foundation for filmmakers to register ther identity for verification
(define-public (register-filmmaker-id (new-filmmaker principal) (new-full-name (string-ascii 100)) (new-profile-url (string-ascii 255)) (new-identity-hash (buff 32)) (choice-verification-level uint) (choice-verification-level-expiration uint)) 
    (let 
        (
            ;; existing total registered filmmakers and new total registred filmmakers respectively
            (existing-total-registered-filmmakers (var-get total-registered-filmmakers))
            (new-total-registered-filmmakers (+ u1 existing-total-registered-filmmakers))

            ;; check if new-filmmaker is registered (as input) in the read-only func
            (is-filmmaker-registered (is-registered new-filmmaker))
                 
        ) 
        ;; Ensure the caller is the filmmaker being registered
        (asserts! (is-eq new-filmmaker tx-sender) ERR-NOT-AUTHORIZED)

        ;; Ensure the filmmaker is not already registered
        (asserts! (not is-filmmaker-registered) ERR-ALREADY-REGISTERED)

        ;; Store the filmmaker's identity information
        (map-set filmmaker-identities new-filmmaker {
            full-name: new-full-name, 
            profile-url: new-profile-url, 
            identity-hash: new-identity-hash, 
            verification-level: choice-verification-level, ;; filmmaker chooses what level of verification level they would want to opt for 
            verification-expiration: choice-verification-level-expiration, ;; filmmaker inputs default expiration period of their choice verification level 
            verified: false, ;; Typically false since filmmaker's identity is yet to be verified
            registration-time: block-height
        })

        ;; Initialize portfolio and endorsement counts respectively 
        (map-set filmmaker-portfolio-counts new-filmmaker u0) ;; no count yet until filmmaker identity is verified 
        (map-set filmmaker-endorsement-counts new-filmmaker u0) ;; Typically no endorsement yet

        ;; Initialize total-registered filmmaker portfolio and total-filmmaker endorsement counts respectively
        (var-set total-filmmaker-portfolio-counts u0)
        (var-set total-filmmaker-endorsement-counts u0 ) 

        ;; Increment count of total registered filmmakers, verified/endorsed  or not
        (ok (var-set total-registered-filmmakers new-total-registered-filmmakers))
    )
)

;; Function to add filmmaker's portfolio item
 ;; Strategic Purpose: Allow filmmakers to showcase their track record
(define-public (add-filmmaker-portfolio (new-added-filmmaker principal) (new-added-project-name (string-ascii 100)) (new-added-project-url (string-ascii 255)) (new-added-project-desc (string-ascii 500)) (new-added-project-completion-year uint))
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
        ;; Ensure the caller is the filmmaker or admin
        (asserts! (or (is-eq tx-sender new-added-filmmaker) (is-admin)) ERR-NOT-AUTHORIZED)  

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
        (ok (map-set filmmaker-portfolio-counts new-added-filmmaker new-filmmaker-counts))
    )
)

;; Function to verify a filmmaker (admin only)
    ;; Strategic Purpose: Provide platform-level verification of identity
            ;; @params:
                ;;   filmmaker-principal - principal of the filmmaker
                ;;   verification-level - uint level of verification (1-basic, 2-standard, 3-premium)
                ;;   expiration-block - uint block height when verification expires
(define-public (verify-filmmaker-identity (new-added-filmmaker principal) (new-verificaion-level uint) (new-expiration-block uint)) 
    (let 
        (
            ;; Get filmmaker data
            (existing-filmmaker-data (unwrap! (map-get? filmmaker-identities new-added-filmmaker) ERR-FILMMAKER-NOT-FOUND))

            ;; Get verification-level-data and verification expiration data
            (existing-choice-verification-level-data (get verification-level existing-filmmaker-data))
            (exisitng-choice-ver-level-expiration (get verification-expiration existing-filmmaker-data))

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

;; Function to add third-party endorsements for a filmmaker
    ;; Strategic Purpose: Enhance trust through industry recognition
        ;; @params:
            ;;   filmmaker-principal - principal of the filmmaker
            ;;   endorser-name - (string-ascii 100) name of endorsing entity
            ;;   endorsement-letter - (string-ascii 255) brief endorsement
            ;;   endorsement-url - (string-ascii 255) verification link for endorsement
 (define-public (add-filmmaker-endorsement (new-added-filmmaker principal) (new-endorser-name (string-ascii 100)) (new-endorsement-letter (string-ascii 255)) (new-endorsement-url (string-ascii 255)))
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

;; ========== THIRD-PARTY FUNCTION ==========
;; Function to enable contract-admin set optional third-party endorsers
(define-public (set-third-party-endorser (new-endorser principal)) 
    (begin 
        (asserts! (is-admin) ERR-NOT-AUTHORIZED)
        (ok (var-set third-party-endorser new-endorser))
    )
)
