
;; title: Co-EP-rotating-fundings
;; version: 1.0.0
;; Author: Victor Omenai 
;; Created: 2025

;; ========= Summary ==========
;; This module extends the existing CineX crowdfunding architecture to support global collaborative funding pools based on the Nigeriantraditional 
;; co-operative collaborative rotating savings model called Ajo or Esusu, which is typical of credit unions providing capital access to 
;; persons with mutual society relationships.


;; ========= Description ==========
;; The Co-EP feature [short for Co-Executive Producer(s)] leverages the traditional Nigerian Esusu/Ajo rotating savings system, 
;; adapting it for film production where:
;; => Pooled Funding: Multiple filmmakers with real-world mutual film career networks, establish CineX social connections and 
;; contribute equal amounts to fund one project
;; => Rotating Beneficiary: Each filmmaker gets their turn to receive full funding
;; => Shared Credits: All contributors become co-executive producers
;; => Profit Sharing: Revenue is distributed among all pool members
;; => Community Trust: Built on mutual recognition and legal agreements

;; Strategic Business Purpose:
;; => Transforms CineX from a traditional crowdfunding platform into a professional filmmaker cooperative through rotating funding pools 
;; where established filmmakers collectively fund each other's projects
;; => Complements the public crowdfunding uncertainties with more guaranteed, predictable funding cycles based on vetted professional networks 
;; and mutual recognition within the filmmaker community
;; => Diversifies risk across multiple projects while aligning incentives through co-producer credits and profit sharing, creating sustainable 
;; funding infrastructure with recurring revenue streams
;; => Positions CineX as a filmmaker credit union that provides reliable capital access through community-assured funding rather than abslute
;; reliance on hope-based public appeals of the crowdfunding feature; this targets professional filmmakers seeking dependable funding partnerships



;; Import existing traits for consistency
 ;; crowdfunding-trait
(use-trait co-ep-crowdfunding-trait .crowdfunding-module-traits.crowdfunding-trait) 

 ;; reward-trait
 (use-trait co-ep-rewards-trait .rewards-module-trait.rewards-trait)

 ;; escrow-trait
(use-trait co-ep-escrow-trait .escrow-module-trait.escrow-trait)

;; ========================
;; CONSTANTS & ERROR CODES
;; ========================

(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-CONNECTION-ALREADY-EXISTS (err u401))
(define-constant ERR-POOL-NOT-FOUND (err u402))
(define-constant ERR-INSUFFICIENT-BALANCE (err u403))
(define-constant ERR-INVALID-POOL-SIZE (err u404))
(define-constant ERR-POOL-FULL (err u405))
(define-constant ERR-NOT-POOL-MEMBER (err u406))
(define-constant ERR-ALREADY-FUNDED (err u407))
(define-constant ERR-POOL-INACTIVE (err u408))
(define-constant ERR-INVALID-ROTATION (err u409))
(define-constant ERR-COMMITMENT-EXPIRED (err u410))
(define-constant ERR-FILMMAKER-NOT-FOUND (err u411))
(define-constant ERR-IDENTITY-NOT-VERIFIED (err u412))
(define-constant ERR-PROJECT-NOT-FOUND (err u413))
(define-constant ERR-NO-MUTUAL-PROJECT (err u414))


;; ========================
;; DATA STRUCTURES
;; ========================

;; Film Maker Projects Entry 
(define-map filmmaker-projects { filmmaker: principal, project-id: uint } { 
    project-name: (string-utf8 100),
    project-type: (string-ascii 30), ;; "short-film or non-feature film", "feature-film", "documentary","web-series"
    role: (string-ascii 50), ;; "director", "producer", "cinematographer", "editor", etc.
    collaborators: (list 50 principal), ;; list of other filmmakers on the project
    start-date: uint,
    end-date: uint,
    project-url: (string-ascii 255), ;; link to project filmmography details
    verified: bool, ;; whether this project collaboration is verified or not
    added-at: uint, ;; this is in blocks, time when this project details was added
    })

;; Map to track project counter per filmmaker
(define-map filmmaker-project-counts principal uint)

;; Social Connections for Trust Building
(define-map member-social-connections { requester: principal, target: principal } { 
    connection-type: (string-ascii 30), ;; this status message could be "colleague" "friend", or "collaborator";
    mutual-projects: (list 10 uint), ;; list of project IDs they've worked on together
    mutual-projects-count: uint, ;; Count for easier access to each mutual project/quick collaboration count tracking
    endorsement-score: uint,
    last-collaboration: uint, ;; block-height of most recent collaboration
    verified-at: uint,
    })

;; Pool Member Structure
(define-map pool-individual-member-structure { pool-id: uint, member-address: principal } { 
    contribution-amount: uint,
    joined-at: uint,
    member-reputation-score: uint,
    previous-pools-count: uint, 
    has-contributed: bool,
    verification-status: (string-ascii 24) ;; this status message could be "verified", "pending" or "none"
    })

;; Esusu/Rotating funding Pool Structure
(define-map rotating-funding-pool-structure { pool-id: uint } { 
    pool-name: (string-utf8 100),
    pool-creator: principal,
    max-members: uint,
    current-pool-members: uint,
    contribution-per-member: uint,
    total-pool-value: uint,
    current-rotation: uint,
    pool-status: (string-ascii 24), ;; this status message could be "forming", "active", "completed", or "paused"
    created-at: uint,
    cycle-duration: uint, ;; this is in blocks e.g 30 days
    legal-agreement-hash: (buff 32),
    film-project-category:(string-ascii 30), ;; "short-film or 'non-feature length'", "feature length", or "documentary"
    geographic-focus: (string-ascii 50) ;; "Bollywood" , "Hollywood" , "Nollywood" , "Global",  or "Regional"
    })
    

;; Fundng rotation Schedule
(define-map funding-rotation-schedule { pool-id: uint, rotation-number: uint } { 
    beneficiary: principal,
    funding-amount: uint,
    scheduled-date: uint,
    completion-status: (string-ascii 24),
    project-details: {
        title: (string-utf8 100),
        description: (string-utf8 500),
        expected-completion: uint,
        campaign-id: uint ;; this links to existing crowdfunding campaigns
    }
     })


;; Pool Analytics & Performance
(define-map pool-performance { pool-id: uint } { 
    successful-rotations: uint,
    total-funded-amount: uint,
    average-project-completion: uint,
    member-satisfaction-score: uint,
    dispute-count: uint
    })


;; ==================================================
;; PROJECT ENTRY FUNCTIONS
;; ================================================


;; Add project to filmmaker's portfolio
    ;; @func: This function allows filmmakers to make a single new project entry 
(define-public (add-filmmaker-project (new-project-name (string-utf8 100)) 
    (new-project-type (string-ascii 30)) 
    (new-role (string-ascii 50)) 
    (new-collaborators (list 50 principal)) 
    (project-start-date uint) 
    (project-end-date uint) 
    (new-project-url (string-ascii 255)))  
    (let 
        (
            ;; get current project count, and calculate new count
            (current-project-count (default-to u0 (map-get? filmmaker-project-counts tx-sender)))
            (new-project-count (+ current-project-count u1))

            ;; Get filmmaker verified status from 'is-filmmaker-currently-verified" read-only fucntion of filmmaker-verification module
            (identity-is-verified  (unwrap! (contract-call? .film-verification-module is-filmmaker-currently-verified tx-sender) ERR-IDENTITY-NOT-VERIFIED))
        ) 

        ;; Ensure filmmaker is verified
        (asserts! identity-is-verified ERR-IDENTITY-NOT-VERIFIED)

        ;; Store the new project with verified stating "false" in the interim until quoted collaborators 
        (map-set filmmaker-projects {filmmaker: tx-sender, project-id: new-project-count } {
            project-name: new-project-name,
            project-type: new-project-type, ;; "short-film or non-feature film", "feature-film", "documentary","web-series"
            role: new-role,
            collaborators: new-collaborators, ;; list of other filmmakers on the project
            start-date: project-start-date, 
            end-date: project-end-date, 
            project-url: new-project-url,
            verified: false,
            added-at: block-height

        })

        ;; Update project count
        (map-set filmmaker-project-counts tx-sender new-project-count)
        
        (ok new-project-count)
        
    )

)

;; Verify mutual project collaboration
    ;; @func: This function allows a prospective requester or target to verify the claims of collaboration on a project entry by the other party 
        ;;@params: 
            ;; new-project-id: uint,
            ;; new-collaborator: principal
(define-public (verify-mutual-project (new-project-id uint) (new-collaborator principal))
    (let 
        (
            ;;  Get/unwrap current-filmmaker-project-data
            (current-project-data (unwrap! (map-get? filmmaker-projects { filmmaker: tx-sender, project-id: new-project-id }) ERR-PROJECT-NOT-FOUND))

            ;; Get current-collaborators-list from the current-filmmaker-project-data
            (current-collaborators-list (get collaborators current-project-data))
            
            ;; Verify a collaborator's principal exists (is-some) at any index location in the current-collaborators-list 
            (is-collaborator (is-some (index-of? current-collaborators-list new-collaborator)))

        )
        ;; Ensure caller is indeed a collaborator
        (asserts! is-collaborator ERR-NOT-AUTHORIZED)

        ;; Update project as verified
        (map-set filmmaker-projects {filmmaker: tx-sender, project-id: new-project-id } 
            (merge current-project-data 
                { verified: true }))

        (ok true)
    )
)



;; ==================================================
;; SOCIAL TRUST & VERIFICATION FUNCTIONS
;; ==================================================

;; Create mutual connection between filmmakers
     ;; @func: This function allows filmmakers to establish verified connections with each other in the system.
(define-public (create-mutual-connection (new-requester principal) (new-target principal) (new-connection-type (string-ascii 30)) (new-mutual-project-ids (list 10 uint))) 
    (let 
        (
            ;; get requester's current verified status from 'is-filmmaker-currently-verified" read-only fucntion of filmmaker-verification module
            (requester-identity-is-verified (unwrap! 
                                                (contract-call? .film-verification-module is-filmmaker-currently-verified tx-sender) 
                                                    ERR-IDENTITY-NOT-VERIFIED))

            ;; get target's current verified status
            (target-identity-is-verified (unwrap! 
                                                (contract-call? .film-verification-module is-filmmaker-currently-verified new-target) 
                                                    ERR-IDENTITY-NOT-VERIFIED))

            ;; filter out the presence of verified project collaborations for the requester out of the list of mutual-project-ids  
            (current-requester-verified-collaborations (filter verify-requester-project-collaborations new-mutual-project-ids))

            ;; filter out the presence of verified project collaborations for the target out of the list of mutual-project-ids  
            (current-target-verified-collaborations (filter verify-target-project-collaborations new-mutual-project-ids))
 

            ;; get current requester mutual projects count
            (requester-mutual-verified-projects-count (len current-requester-verified-collaborations))

            ;; get current target mutual projects count
            (target-mutual-verified-projects-count (len current-target-verified-collaborations))
            
            ;; get requester-mutual-projects-endorsement-score
            (requester-mutual-projects-endorsement-score (calculate-endorsement-score requester-mutual-verified-projects-count))

            ;; get target-mutual-projects-endorsement-score
            (target-mutual-projects-endorsement-score (calculate-endorsement-score target-mutual-verified-projects-count))
        ) 
        (asserts! (or (is-eq tx-sender new-requester) (is-eq tx-sender new-target)) ERR-NOT-AUTHORIZED)

        ;; Ensure at least one mutual project count exists
        (asserts! (or (>= requester-mutual-verified-projects-count u0) (>= target-mutual-verified-projects-count u0)) ERR-INVALID-ROTATION)

        ;; Create bi-directional connection
            ;; for requester
        (map-set member-social-connections { requester: tx-sender, target: new-target } {
            connection-type: new-connection-type, ;; this status message could be "colleague" "friend", or "collaborator";
            mutual-projects: current-target-verified-collaborations, ;; list of project IDs verified by targets as mutual collaborations
            mutual-projects-count: requester-mutual-verified-projects-count, ;; Count for easier access to each mutual project/quick collaboration count tracking
            endorsement-score: requester-mutual-projects-endorsement-score,
            last-collaboration: block-height, ;; block-height of most recent collaboration
            verified-at: block-height,
         })


        ;; for target 
        (map-set member-social-connections { requester: new-target, target: tx-sender } {
            connection-type: new-connection-type, ;; this status message could be "colleague" "friend", or "collaborator";
            mutual-projects: current-requester-verified-collaborations, ;; list of project IDs verified by requester as mutual collaborations
            mutual-projects-count: target-mutual-verified-projects-count, ;; Count for easier access to each mutual project/quick collaboration count tracking
            endorsement-score: target-mutual-projects-endorsement-score,
            last-collaboration: block-height, ;; block-height of most recent collaboration
            verified-at: block-height,

         })

        (ok true)

    )

)


;; Helper function to verify project collaboration claims by requester
(define-private (verify-requester-project-collaborations (new-project-id uint))
    (match (map-get? filmmaker-projects { filmmaker: tx-sender, project-id: new-project-id }) 
            project (get verified project) 
            false
    )
)


;; Helper function to verify project collaboration claims by target
(define-private (verify-target-project-collaborations (new-project-id uint))
    (match (map-get? filmmaker-projects { filmmaker: tx-sender, project-id: new-project-id }) 
            project (get verified project) 
            false
    )
)

;; Calculate endorsement score based on mutual projects and connection strength
(define-private (calculate-endorsement-score (mutual-projects-count uint))
    (if (>= mutual-projects-count u10) ;; mutual projects count is >= u10
        u100 ;; Exceptional collaboration history
        (if (>= mutual-projects-count u7) ;; else, if it is >= u7
                u85  ;; Strong collaboration history
            (if (>= mutual-projects-count u5) ;; else, if it is >= u5
                u70 ;; Good collaboration history 
                (if (>= mutual-projects-count u3) ;; else, if it is >= u3
                    u55 ;; Basic collaboration history 
                    u30 ;; ELSE, RETURN 'No verified collaboration history' 
                )
            )    
        )
    )
)


;; Get mutual projects relationship between two filmmakers



;; Get filmmaker's project details



;; Get filmmaker's total project count



