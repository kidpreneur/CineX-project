;; title: film-verification-module

;;;; ============= Description ==============
;; Implementation of Film verification module trait
;; Strategic Purpose: Build trust between backers and filmmakers through identity verification
;; This addresses the "Customer Relationships" component of the Business Model Canvas of CineX

;; Author: Victor Omenai 

;; ========== TRAIT REFERENCE ==========
;; Implementing the film-verification trait to ensure standard interface
(impl-trait .film-verification-module-trait.film-verification-trait)

;; ========== ERROR CONSTANTS ==========
;; Define error codes for better debugging and user feedback
(define-constant ERR-NOT-AUTHORIZED (err 1001))
(define-constant ERR-FILMMAKER-NOT-FOUND (err 1002))
(define-constant ERR-INVALID-INPUT (err 1003))
(define-constant ERR-ALREADY-REGISTERED (err 1004))
(define-constant ERR-PORTFOLIO-NOT-FOUND (err 1005))
(define-constant ERR-ENDORSEMENT-NOT-FOUND (err 1006))
(define-constant ERR-VERIFICATION-EXPIRED (err 1007))

;; ========== CONSTANTS ==========
;; Define verification levels 
(define-constant basic-verification u1) ;; level u1
(define-constant standard-verification u2) ;; level u2
(define-constant premium-verification u3) ;; level u3

;; Define verification fees (in microSTX)
(define-constant basic-verification-fee u1000000) ;; 1 STX 
(define-constant standard-verification-fee u5000000) ;; 5 STX
(define-constant premium-verification-fee u10000000) ;; 10 STX

;; Verified-id valid period (in blocks, approximately 1 year, i.e, u52560 blocks) 
    ;; (WHAT IF we make different valid periods of 1year, 2 years,and 3 years as the value for each verification )
(define-constant basic-verified-id-valid-period u52560) ;; level 1 verification validity
(define-constant standard-verified-id-valid-period (* u52560 u2)) ;; level 2 verification validity
(define-constant premium-verified-id-valid-period (* u52560 u3)) ;; level 3 verification validity

;; ========== DATA VARIABLES ==========
;; Store the contract administrator who can verify filmmakers
(define-data-var contract-admin principal tx-sender)

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
;; Helper to check if caller is admin
(define-private (is-admin) 
    (is-eq tx-sender (var-get contract-admin))
)

;; Helper to validate if a filmmaker is registered
(define-read-only (is-registered (new-filmmaker principal)) 
    (is-some (map-get? filmmaker-identities new-filmmaker))
)



;; ========== PUBLIC FUNCTIONS ==========
;; Function to register a filmmaker's identity
    ;; Strategic Purpose: Establish the foundation for filmmakers to register ther identity for verification
(define-public (register-filmmaker-id (new-filmmaker principal) (new-full-name (string-ascii 100)) (new-profile-url (string-ascii 255)) (new-identity-hash (buff 32))) 
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
            verification-level: u0, ;; not initially verified 
            verification-expiration: u0, ;; no expiration initially,sinceno initial verification level is attained validity period of verification level
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