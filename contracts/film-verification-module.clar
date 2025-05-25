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
(define-constant ERR-FILMMKAER-NOT-FOUND (err 1002))
(define-constant ERR-INVALID-INPUT (err 1003))
(define-constant ERR-NOT-REGISTERED (err 1004))
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

;; Keep track of total verification fee collected
(define-data-var total-verification-fee-collected uint u0)

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
(define-map filmmaker-portfolio-counts principal uint) ;; key - principal of the filmmaker; value - uint ID of the portfolio item 

;; Track endorsement counter per filmmaker
(define-map filmmaker-endorsement-counts principal uint) ;; key - principal of the filmmaker; value -uint ID of the portfolio item 

;; ========== PRIVATE FUNCTIONS ==========