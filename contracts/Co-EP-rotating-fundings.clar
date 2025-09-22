
;; title: Co-EP-rotating-fundings
;; version: 1.0.0
;; Author: Victor Omenai 
;; Created: 2025

;; ========= Summary ==========
;; This module extends the existing CineX crowdfunding architecture to support global collaborative funding pools based on the Nigerian traditional 
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
;; => Positions CineX as a filmmaker credit union that provides reliable capital access through community-assured funding rather than absolute
;; reliance on hope-based public appeals of the crowdfunding feature; this targets professional filmmakers seeking dependable funding partnerships


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
(define-constant ERR-SCHEDULED-FUNDING-NOT-YET-COMPLETE (err u410))
(define-constant ERR-FILMMAKER-NOT-FOUND (err u411))
(define-constant ERR-IDENTITY-NOT-VERIFIED (err u412))
(define-constant ERR-PROJECT-NOT-FOUND (err u413))
(define-constant ERR-NO-MUTUAL-PROJECT (err u414))
(define-constant ERR-CONNECTION-NOT-FOUND (err u415))

;; Default configuration for opt-in crowdfunding reward-tiers and reward description
(define-constant DEFAULT-REWARD-TIERS u3)
(define-constant DEFAULT-REWARD-DESCRIPTION "Early digital access, credits, and exclusive content")


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
(define-map pool-individual-members { pool-id: uint, member-address: principal } { 
    contribution-amount: uint,
    joined-at: uint,
    member-pool-reputation-score: uint, ;; funding performance of the member in past pool rotations  
    previous-pools-count: uint, 
    has-contributed: bool,
    verification-status: (string-ascii 24) ;; this status message could be "verified", "pending" or "none"
    })

;; Esusu/Rotating funding Pool Structure
(define-map rotating-funding-pools { pool-id: uint } { 
    pool-name: (string-utf8 100),
    pool-creator: principal,
    max-members: uint,
    current-pool-members: uint,
    member-list: (list 20 principal),
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
    scheduled-date: uint, ;; block height (as a uint) when funds should be released to the beneficiary
    completion-status: (string-ascii 24),
    project-details: {
        title: (string-utf8 100),
        description: (string-ascii 500),
        expected-completion: uint,
        campaign-id: uint, ;; this links to existing crowdfunding campaigns
        enable-public-crowdfunding: bool, ;; smart opt-out, enabling filmmakers choose crowdfunding 
                                            ;; (or not in the function for updating project details), added to Co-EP
        reward-tiers: uint,
        reward-description: (string-ascii 500)
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
;; GLOBAL VARIABLES
;; ==================================================

;; Unique pool counter  
(define-data-var pool-id uint u0)

;; Contract principal as Core contract reference pointing to the CineX main contract
(define-data-var core-contract principal tx-sender)

;; Add variable to store address of Crowdfunding Module
(define-data-var crowdfunding-contract principal tx-sender)


;; Add variable to store address of Verification Module
(define-data-var verification-contract principal tx-sender)


;; Add variable to store address of Escrow Module
(define-data-var escrow-contract principal tx-sender)


;;;; ========== Emergency State ========
;; Variable to hold state of operations 'not paused (false)' until when necessary 
(define-data-var emergency-pause bool false)

;; Variable to hold state of module-version - initialized to the first version (V1) at deployment 
(define-data-var module-version uint u1)

;; Variable to hold state of module-active - initialized to true, implying module is actively running
(define-data-var module-active bool true)



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
     ;; @func: This function allows filmmakers to establish verified connections with each other in the system after verifying the collaboration 
     ;; claims by the other party in the filmmaker project stage
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
(define-read-only (get-verified-collaboration (new-filmmaker principal) (new-project-id uint)) 
    (match (map-get? filmmaker-projects { filmmaker: new-filmmaker, project-id: new-project-id }) 
        verified-collaboration (get verified verified-collaboration) 
            false)
)


;; Get filmmaker's project details
(define-read-only (get-filmmaker-project (new-filmmaker principal) (new-project-id uint))
    (map-get? filmmaker-projects { filmmaker: new-filmmaker, project-id: new-project-id })
)

;; Get filmmaker's total project count
(define-read-only (get-project-counts (new-filmmaker principal))
    (default-to u0 (map-get? filmmaker-project-counts new-filmmaker))
)

;; Get estabiished social connections
(define-read-only (get-social-connections (new-requester principal) (new-target principal)) 
    (match (map-get? member-social-connections { requester: new-requester, target: new-target }) 
        establshed-connections (ok "established-connections")
            ERR-CONNECTION-NOT-FOUND)
)


;; ==================================================
;; POOL CREATION & MANAGEMENT
;; ==================================================
;; Create new rotating funding pool
 ;; @func: this function enables an already verified filmmaker to start a pool, of course,
         ;;  automatically becoming the first member added to the pool 
(define-public (create-new-rotating-funding-pool (new-project-id uint) 
    (new-pool-name (string-utf8 100)) 
    (standard-max-members uint) 
    (standard-contribution-per-member uint) 
    (pool-cycle-duration uint)
    (pool-legal-agreement-hash (buff 32))
    (pool-category (string-ascii 30))
    (pool-geographic-focus (string-ascii 50)))
    (let 
        (
            ;; Get verified status of pool creator from 'is-filmmaker-currently-verified" read-only fucntion of filmmaker-verification module
            (pool-creator-verified-id (unwrap! 
                                            (contract-call? .film-verification-module is-filmmaker-currently-verified tx-sender) 
                                                ERR-IDENTITY-NOT-VERIFIED))

            ;; Get projects data
            (current-projects-data (unwrap! (map-get? filmmaker-projects { filmmaker: tx-sender, project-id: new-project-id }) ERR-PROJECT-NOT-FOUND))

            ;; Get verified projects data of pool creator
            (pool-creator-verified-projects (get verified current-projects-data))

            ;; Get pool counter, and calculate next pool-id
            (current-pool-counter (var-get pool-id))
            (next-pool-id (+ current-pool-counter u1))

        ) 
        ;; Ensure tx-sender has verified project connections
        (asserts! (is-eq pool-creator-verified-projects true) ERR-NOT-AUTHORIZED)

        ;; Ensure pool size is no less than 1 and no more than 20
        (asserts! (and (> standard-max-members u1) (<= standard-max-members u20)) ERR-INVALID-POOL-SIZE)

        ;; Create pool
        (map-set rotating-funding-pools { pool-id: next-pool-id } { 
            pool-name: new-pool-name,
            pool-creator: tx-sender,
            max-members: standard-max-members,
            current-pool-members: u1,
            member-list: (list tx-sender),
            contribution-per-member: standard-contribution-per-member,
            total-pool-value: (* standard-contribution-per-member standard-max-members),
            current-rotation: u0, ;; no rotation yet since pool has not gotten members besides the creator
            pool-status: "forming", ;; just "forming" 
            created-at: block-height,
            cycle-duration: pool-cycle-duration, ;; this is in blocks e.g 30 days
            legal-agreement-hash: pool-legal-agreement-hash,
            film-project-category: pool-category, ;; "short-film or 'non-feature length'", "feature length", or "documentary"
            geographic-focus: pool-geographic-focus ;; "Bollywood" , "Hollywood" , "Nollywood" , "Global",  or "Regional"
    })

        ;; Add creator as first member
        (map-set pool-individual-members { pool-id: next-pool-id, member-address: tx-sender } { 
            contribution-amount: standard-contribution-per-member,
            joined-at: block-height,
            member-pool-reputation-score: u50, ;; default score for a start
            previous-pools-count: u0, 
            has-contributed: false,
            verification-status: "verified"  ;; is already verified before being authorized to be a member of a pool, either as creator or not
    })

        ;; Update pool counter with newly created pool id
        (var-set pool-id next-pool-id)

        ;; Emit event
        (print {
            event: "pool-created",
            pool-id: next-pool-id,
            creator: tx-sender,
            max-members: standard-max-members,
            contribution: standard-contribution-per-member
        })

        (ok next-pool-id) 
    ) 

)

;; Join existing pool (requires mutual connection verification)
    ;; @func: this function enables verified mutual connections (other filmmakers) with a new pool creator, to join the pool 
(define-public (join-existing-pool (existing-pool-id uint) 
    (referrer principal) 
    (mutual-project-ids (list 10 uint))
    (new-title (string-utf8 100)) 
    (new-description (string-ascii 500)) 
    (expected-completion uint))
    (let 
        (
            ;; Get rotating-funding-pool data 
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))

            ;; Get pool status
            (current-pool-status (get pool-status current-pool-data))

            ;; Get max-members, current-pool-members and current-members-list
            (pool-max-members (get max-members current-pool-data))
            (pool-members (get current-pool-members current-pool-data))
            (current-members-list (get member-list current-pool-data))

            ;; Establish referrer as member in pool-individual-members
            (member-is-referrer (is-some (map-get? pool-individual-members { pool-id: existing-pool-id, member-address: referrer })))

            ;; filter out the presence of verified project collaborations for the requester out of the list of mutual-project-ids  
            (current-referrer-verified-collaborations (filter verify-requester-project-collaborations mutual-project-ids))

            ;; filter out the presence of verified project collaborations for the target out of the list of mutual-project-ids  
            (pool-creator-verified-collaborations (filter verify-target-project-collaborations mutual-project-ids))

            ;; Get contribution-per-member from rotating-funding-pools
            (contribution-standard (get contribution-per-member current-pool-data))

        ) 

        ;; Ensure joining conditions are validated
            ;; Check that pool-status of rotating-funding-pools is actively "forming", else, trigger error
        (asserts! (is-eq current-pool-status "forming") ERR-POOL-INACTIVE)
            
            ;; Check that current-pool-members number is lesser than max-members of rotatng-funding-pools, else pool is full
        (asserts! (> pool-members pool-max-members) ERR-POOL-FULL)

            ;; Check that is-referrer address is a member of pool-individual-members
        (asserts! member-is-referrer ERR-NOT-AUTHORIZED)

            ;; Check that referrer has verified mutual project connections with the creator, as well as the creator
        (asserts! (and (> (len current-referrer-verified-collaborations) u0) (> (len pool-creator-verified-collaborations) u0))
            ERR-NO-MUTUAL-PROJECT)
               
        ;; Add new member to pool-individual-members
        (map-set pool-individual-members { pool-id: existing-pool-id, member-address: tx-sender } { 
            contribution-amount: contribution-standard,
            joined-at: block-height,
            member-pool-reputation-score: u60, ;; sightly higher default number for referrers and referred members  
            previous-pools-count: u0, 
            has-contributed: false,
            verification-status: "verified" ;; this status message could be "verified", "pending" or "none"
        })
        ;; Update current-pool-members count in rotating-funding-pools
        (map-set rotating-funding-pools { pool-id: existing-pool-id } 
            (merge 
                current-pool-data 
                    { 
                        current-pool-members: (+ pool-members u1),
                        member-list: (unwrap! (as-max-len? 
                                                    (append current-members-list tx-sender) u20) 
                                                    ERR-POOL-FULL)     
                    }
            )
        )

        ;; Activate pool when it reaches max-members capacity
        (if (is-eq (+ pool-members u1) pool-max-members) 
            (begin 
                (try! (activate-pool existing-pool-id))
                (try! (initialize-rotation-schedule existing-pool-id new-title new-description expected-completion))
                (ok "joined and activated")
            ) 
            
            (ok "joined")
        )

    )
)

;; ==== Helper functions for Pool Creation & Management

;; Activate pool when it reaches maximum capacity
(define-private (activate-pool (existing-pool-id uint))
    (let 
        (
            ;; Get rotating-funding-pool data 
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))
            
            ;; Get current-member-list
            (current-member-list (get member-list current-pool-data))
        ) 
        ;; Set pool-status of rotating-funding-pools to "active"
        (map-set rotating-funding-pools { pool-id: existing-pool-id } 
            (merge 
                current-pool-data
                { pool-status: "active" }
            )
        )

        ;; Emit event
        (print {
            event: "pool-activated",
            pool-id: existing-pool-id,
            member-list: current-member-list

        })
        (ok true)

    )
)

;; Initialize rotation schedule for new active pool
(define-private (initialize-rotation-schedule (existing-pool-id uint) 
    (new-title (string-utf8 100)) 
    (new-description (string-ascii 500)) 
    (expected-completion uint)) 
    (let 
        (
            ;; Get rotating-funding-pools data
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))

            ;; Get member-list 
            (current-member-list (get member-list current-pool-data))

            ;; Get cycle duration from rotating-funding-pools data
            (current-cycle-duration  (get cycle-duration current-pool-data))

            ;; Get total pool value
            (current-total-funding (get total-pool-value current-pool-data))

        ) 

        ;; Ensure member-list is not empty
        (asserts! (> (len current-member-list) u0) ERR-POOL-NOT-FOUND)

        ;; Initilaize funding-rotation-schedule with first rotation (pool creator gets first funding)
        (map-set funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: u1} { 
            beneficiary: (unwrap! (element-at? current-member-list u0) ERR-POOL-NOT-FOUND),
            funding-amount: current-total-funding,
            scheduled-date: (+ block-height current-cycle-duration),
            completion-status: "pending",
            project-details: {
            title: new-title,
            description: new-description,
            expected-completion: expected-completion,
            campaign-id: u0, ;; this links to existing crowdfunding campaigns
            enable-public-crowdfunding: true,
            reward-tiers:DEFAULT-REWARD-TIERS,
            reward-description: DEFAULT-REWARD-DESCRIPTION
            }
        })

        ;; Update current-rotation of rotation-funding-pool
        (map-set rotating-funding-pools { pool-id: existing-pool-id }
            (merge 
                current-pool-data 
                    { current-rotation: u1 }
            )
        )

        (ok true)
        

        
    )
)

;; Get all members of a specific pool
(define-read-only (get-pool-members (existing-pool-id uint))
    (match (map-get? rotating-funding-pools { pool-id: existing-pool-id }) 
        pool-data (ok (get member-list pool-data)) 
        ERR-POOL-NOT-FOUND
    )
)


;; ==================================================
;; CONTRIBUTION & FUNDING MECHANICS
;; ==================================================
    ;; @func: this function enables pool members contribute to a pool
    ;; @params: (existing-pool-id uint)
(define-public (contribute-to-existing-pool (existing-pool-id uint)) 
    (let 
        (
            ;; Get rotating-funding-pools data
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))

            ;; Get current-pool-member-data
            (current-member-data (unwrap! 
                                    (map-get? pool-individual-members { pool-id: existing-pool-id, member-address: tx-sender }) 
                                        ERR-NOT-POOL-MEMBER))

            ;; Get contribution standard per member from current-pool-data
            (contribution-standard (get contribution-per-member current-pool-data))     

            ;; Get has-contributed from the pool-individual-members
            (contribution-status (get has-contributed current-member-data))  

            ;; Get current-pool-status
            (current-pool-status (get pool-status current-pool-data))
        ) 

        ;; Ensure pool status of current-pool-data is "active"
        (asserts! (is-eq current-pool-status "active") ERR-POOL-INACTIVE)

        ;; Ensure has-contributed from pool-individual-members is NOT yet contributed, else ERR-ALREADY-FUNDED
        (asserts! (is-eq contribution-status false) ERR-ALREADY-FUNDED)

        ;; Transfer STX to escrow (integrate with existing escrow module)
        (unwrap! (stx-transfer? contribution-standard tx-sender (as-contract tx-sender)) ERR-INSUFFICIENT-BALANCE)

        ;; Update has-contributed to true 
        (map-set pool-individual-members { pool-id: existing-pool-id, member-address: tx-sender }
            (merge 
                current-member-data 
                    { has-contributed: true }
                )
        )

        ;; Emit successful contribution event
        (print {
            event: "contribution-made",
            pool-id: existing-pool-id,
            contributor: tx-sender,
            contribution-amount: contribution-standard,
            recipient: "escrow"
        })
        
        (ok true)
    )
)



;; Execute rotation funding
    ;; @func: enables the rotation of funding 
    ;; @Value proposition: 
     ;; For Filmmakers: 
        ;; => Provides certainty about when they'll receive funding
        ;; => Allows project planning around known payment date

    ;; For CineX Protocol
        ;; => Enables automated rotation progression
        ;; => Creates audit trails for compliance
        ;; => Supports future features like: (i) Early completion bonuses; (ii) Late payment penalties; (iii) Grace periods
(define-public (execute-rotation-funding (existing-pool-id uint)) 
    (let 
        (
            ;; Get rotating-funding-pools data
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))

            ;; Get current-rotation from current-pool-data  
            (current-rotation (get current-rotation current-pool-data))

            ;; Get current-pool-status from rotating-funding-pools
            (current-pool-status (get pool-status current-pool-data))

            ;; Get funding-rotation-schedule data
            (funding-rotation-schedule-data (unwrap! 
                                                        (map-get? funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: current-rotation }) 
                                                            ERR-INVALID-ROTATION))

            ;; Get current-project-details from funding-rotation-schedule data
            (current-project-details (get project-details funding-rotation-schedule-data))

            ;; Get nested title of project details from funding-rotation-schedule data 
            (project-title (get title current-project-details))

            ;; Get nested description of project details from funding-rotation-schedule data 
            (project-description (get description current-project-details))

            ;; Get funding-amount from funding-rotation-schedule
            (current-funding-amount (get funding-amount funding-rotation-schedule-data))
            
            ;; Get beneficiary from funding-rotation-schedule
            (current-beneficiary (get beneficiary funding-rotation-schedule-data))

            ;; Get funding's current-completion-status from funding-rotation-schedule 
            (funding-completion-status (get completion-status funding-rotation-schedule-data ))
            
            ;; Get current-scheduled-date from fundng-rotation-schedule
            (current-scheduled-date (get scheduled-date funding-rotation-schedule-data))

            ;; Get current-all-contributions status of pool members
            (current-all-contributions (unwrap! (verify-all-contributions existing-pool-id) ERR-INSUFFICIENT-BALANCE))

            ;; Get all-contributed tuple value from the accumulator in current-all-contributions helper function
            (current-all-contributed (get all-contributed current-all-contributions))

            ;; Get linked-crowdfunding-campaign
            (linked-crowdfunding-campaign (create-linked-crowdfunding-campaign existing-pool-id current-rotation))

            ;; Get next-advance-rotation
            (next-advance-rotation (advance-rotation existing-pool-id project-title project-description ))


        ) 

        ;; Validate funding conditions
            ;; Ensure current-pool-status is same as "active"
        (asserts! (is-eq current-pool-status "active") ERR-POOL-INACTIVE)

            ;; Ensure funding's current-completion-status is "pending"
        (asserts! (is-eq funding-completion-status "pending") ERR-ALREADY-FUNDED)

            ;; Ensure current time (block-height) has either reached, or, already passed the scheduled-date for a new funding rotation, else throw 
                ;; ERR-SCHEDULED-FUNDING-NOT-YET-COMPLETE to indicate scheduled date for next funding rotation has not been reached
        (asserts! (>= block-height current-scheduled-date) ERR-SCHEDULED-FUNDING-NOT-YET-COMPLETE)

         ;; Verify all members have contributed from the current-all-contributions helper function
         (asserts! current-all-contributed ERR-INSUFFICIENT-BALANCE)

         ;; Transfer funds from as-contract to beneficiary
         (try! (as-contract (stx-transfer? current-funding-amount tx-sender current-beneficiary)))

         ;; Update completion-status of funding-rotation-schedule as 'funded"
         (map-set funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: current-rotation }
            (merge 
                funding-rotation-schedule-data 
                    { completion-status: "funded"  }
            )
         )
         ;; Through the helper function, (create-linked-crowdfunding-campaign), use (try!) as post-funding condition 
         ;; to create crowdfunding campaign for the current beneficiary; so, if campaign fails, (try!) propagates the error 
         ;; from the "create-campaign" function of the crowdfunding campaign module 
	        ;; Failed campaign creation doesn't therefore invalidate valid funding
        (try! linked-crowdfunding-campaign)

        ;; Use try! also for non-critical follow-up, advancing to next rotation without invalidating funding as well
        (try! next-advance-rotation)

        ;; Emit event
        (print {
            event: "rotation-executed",
            pool-id: existing-pool-id,
            rotation-number: current-rotation,
            beneficiary: current-beneficiary,
            amount: current-funding-amount
        })

        (ok true)
    )


)    


;; Project Details Update Function: 
    ;; @func: Allow beneficiaries to update their project details before their rotation
    ;; @params: 
        ;; pool-id: uint,
        ;; rotation-number: uint,
        ;; title: (string-utf8 100),
        ;; description: (string-ascii 500),
        ;; expected-completion: uint
(define-public (update-rotation-project-details (existing-pool-id uint) 
    (current-rotation-number uint) 
    (current-title (string-utf8 100)) 
    (current-project-description (string-ascii 500))     
    (current-expected-completion uint)
    (current-reward-tiers uint)
    (current-reward-description (string-ascii 500)))
    (let 
        (
             ;; Get rotating-funding-pools data
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))

            ;; Get current-rotation from current-pool-data  
            (current-rotation (get current-rotation current-pool-data))

            ;; Get funding-rotation-schedule data
            (funding-rotation-schedule-data (unwrap! 
                                                        (map-get? funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: current-rotation }) 
                                                            ERR-INVALID-ROTATION))   
            
            ;; Get beneficiary from funding-rotation-schedule
            (current-beneficiary (get beneficiary funding-rotation-schedule-data))

             ;; Get project-details from funding-rotation-schedule data
            (current-project-details (get project-details funding-rotation-schedule-data))

            ;; Get campaign-id from current-project-details of funding-rotation-schedule-data
            (current-campaign-id (get campaign-id current-project-details))

            ;; Get funding's current-completion-status from funding-rotation-schedule 
            (funding-completion-status (get completion-status funding-rotation-schedule-data ))

        ) 

        ;; Ensure tx-sender is beneficiary updating their project details
        (asserts! (is-eq tx-sender current-beneficiary) ERR-NOT-AUTHORIZED)

        ;; Ensure funding's current-completion-status is "pending"
        (asserts! (is-eq funding-completion-status "pending") ERR-ALREADY-FUNDED)

        ;; Update funding-rotation-schedule with new values of project-details
        (map-set funding-rotation-schedule { pool-id: existing-pool-id , rotation-number: current-rotation-number } 
            (merge 
                funding-rotation-schedule-data { 
                    project-details: { 
                        title: current-title,
                        description: current-project-description,
                        expected-completion: current-expected-completion,
                        campaign-id: current-campaign-id, ;; this links to existing crowdfunding campaigns
                        enable-public-crowdfunding: false, ;; filmmaker instead opts to not get public funding,but stickto just Co-EP funding
                        reward-tiers: current-reward-tiers, ;; filmmaker updates rewardt-tiers according to marketing plan
                        reward-description: current-reward-description
                    } 
                } 
            )
        
        )

        (ok true)
    )
            
)
    




;; ========= Helper function for the "Contribution and Funding Mechanics
;; Verify all pool members have contributed for current rotation
(define-private (verify-all-contributions (existing-pool-id uint))
    (let 
        (
            ;; Get rotating-funding-pools data
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))

            ;; Get member-list from current-pool-data
            (current-member-list (get member-list current-pool-data))

            ;; Check if all members have contributed
            (contribution-check (fold check-member-contribution current-member-list { pool-id: existing-pool-id, all-contributed: true }))

        ) 

        ;; Return the tuple from fold  
        (ok contribution-check)

    )

)

;; Helper function to check individual member contributions
    ;; This function is called for EACH member in the pool during the fold operation in verify-all-contributions helper function

(define-private (check-member-contribution (member principal) (acc { pool-id: uint, all-contributed: bool })) 
    (let 
        (
            ;; Get the pool-id from the accumulator (passed from fold operation)
            (existing-pool-id (get pool-id acc))

            ;; Get the current "all-contributed" status from previous members
            (previous-status (get all-contributed acc))

             ;; Look up this specific member's contribution data
            (current-member-data (map-get? pool-individual-members { pool-id: existing-pool-id, member-address: member }))
    
        )
        ;; Process the member data
        (match current-member-data 
                    member-current-info 
                        (let
                            (
                                ;; Get this member's contribution status
                                (member-contributed (get has-contributed member-current-info))

                                ;; Calculate new "all-contributed" status
                                ;; Logic: Keep true ONLY if both previous AND current member contributed
                                (new-status (and previous-status member-contributed))

                            ) 

                            ;; Return Updated accumulator
                            { pool-id: existing-pool-id, all-contributed: new-status  }
                            
                        )       
                        ;; CASE 2: Member data not found (error case)
                        ;; Treat as "not contributed" - this will make all-contributed false
                        { pool-id: existing-pool-id, all-contributed: false  }
        )
    )
)

;; Advance to next rotation
(define-private (advance-rotation (existing-pool-id uint) (new-title (string-utf8 100)) (new-description (string-ascii 500))) 
    (let 
        (
            ;; Get rotating-funding-pools as current-pool-data
            (current-pool-data (unwrap! (map-get? rotating-funding-pools { pool-id: existing-pool-id }) ERR-POOL-NOT-FOUND))


            ;; Get current-rotation from as current-pool-data, and calculate next-rotation
            (current-rotation (get current-rotation current-pool-data))
            (next-rotation (+ current-rotation u1))

            ;; Get member-list
            (current-member-list (get member-list current-pool-data))

            ;; Get current-max-members from current-pool-data
            (current-max-members (get max-members current-pool-data))

            ;; Get cycle-duration from current-pool-data
            (current-cycle-duration (get cycle-duration current-pool-data))

            ;; Get current-total-pool-value from current-pool-data
            (current-total-pool-value (get total-pool-value current-pool-data))
            
            ;; Get funding-rotation-schedule data
            (funding-rotation-schedule-data (unwrap! 
                                                    (map-get? funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: current-rotation }) 
                                                        ERR-INVALID-ROTATION))
            
            ;; Get project-details from funding-rotation-schedule data
            (current-project-details (get project-details funding-rotation-schedule-data))

            ;; Check if filmmaker explicitly disabled public crowdfunding or not fromthe current-project-details
            (public-funding-enabled (get enable-public-crowdfunding current-project-details))

            ;; Default to REWARD-TIERS if public-funding is enabled 
            (current-reward-tiers (if public-funding-enabled 
                                        ;; Use configured tiers
                                        DEFAULT-REWARD-TIERS 
                                        ;; Pool-only, no rewards
                                        u0
                                  )

            )

            ;; Default-to REWARD-DESCRIPTION if public-funding enabled
            (current-reward-description (if public-funding-enabled 
                                            ;; Use reward-description for configured tiers
                                            DEFAULT-REWARD-DESCRIPTION 
                                            "Co-EP Pool Funded Project"
                                        )
            )

        ) 
        ;; Check If we have completed all rotations, 
        (if (<= next-rotation current-max-members) ;; if next-rotation is <= current-max-members, that is, not fully completed round max members
            
            (begin
                ;; Create next-rotation schedule 
                (map-set funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: next-rotation } { 
                                                      
                    beneficiary: (unwrap!                     ;; zero-based indexing conversion, converting each next-rotation number 
                                                            ;; to each member's index number, by subtracting the next-rotation by u1  
                                                            ;; so, rotation num of 1 minus = u0, this accounts for member at index u0, and so on.
                                    (element-at? current-member-list (- next-rotation u1)) ERR-POOL-NOT-FOUND),
                    funding-amount: current-total-pool-value,
                    scheduled-date: (+ block-height current-cycle-duration),
                    completion-status: "pending",
                    project-details: {
                        title: new-title,
                        description: new-description,
                        expected-completion: u0,
                        campaign-id: u0, ;; this links to existing crowdfunding campaigns
                        enable-public-crowdfunding: public-funding-enabled, ;; smart opt-out, enabling filmmakers choose crowdfunding 
                                            ;; (or not in the function for updating project details), added to Co-EP
                        reward-tiers: current-reward-tiers,
                        reward-description: current-reward-description
                        
                        }
                })

                ;; Update pool's current rotation
                (map-set rotating-funding-pools { pool-id: existing-pool-id } 
                    (merge 
                        current-pool-data 
                            { current-rotation: next-rotation }
                    )
                    


                )

                ;; Go through each member in the list and reset their contribution status to false, 
                ;; carrying the pool-id along for each next-rotation operation"
                (fold reset-member-contributions current-member-list existing-pool-id)

                (ok true)

            )
            ;; Else, if all rotations are fully completed round max members
            ;; - then mark rotating-funding-pool as completed
            (begin 
                (map-set rotating-funding-pools { pool-id: existing-pool-id }
                    (merge 
                        current-pool-data 
                            { pool-status: "completed" })
                
                )

                (ok true)

            )
            
        )
    )
)

;; Reset member contributions for next rotation
    ;;@paras: member principal; existing-pool-id 
(define-private (reset-member-contributions (member principal) (existing-pool-id uint))
    (let 
        (
             ;; Get current-pool-member-data
            (current-member-data (map-get? pool-individual-members { pool-id: existing-pool-id, member-address: member }))
        ) 
        ;; Only update if member data exists
        (match current-member-data 
                member-info  
                    (map-set pool-individual-members { pool-id: existing-pool-id, member-address: member }
                        (merge 
                            member-info
                                { has-contributed: false } ;; reset has-contributed to false
                        )
                    )
               
                true ;; Return true if member not found 
        ) 
        
        ;; Return the existing-pool-id
        ;; This is crucial for the fold function - it needs to return the existing-pool-id as the accumulator
        ;; The fold passes this returned value to the next iteration
        existing-pool-id 
        
    )
)



;; ====================================================================================
;; INTEGRATION OF (execute-rotation-funding) function WITH EXISTING CROWDFUNDING MODULE
;; =====================================================================================

;; Project Details Update Function
    ;; @func: Allow beneficiaries to update their project details before their rotation
(define-private (create-linked-crowdfunding-campaign (existing-pool-id uint) 
    (current-rotation-number uint))
    (let 
        (
            ;; Get funding-rotation-schedule data
            (funding-rotation-schedule-data (unwrap! 
                                                        (map-get? funding-rotation-schedule { pool-id: existing-pool-id, rotation-number: current-rotation-number }) 
                                                            ERR-INVALID-ROTATION))
            
            ;; Get project-details from funding-rotation-schedule data
            (current-project-details (get project-details funding-rotation-schedule-data))

            ;; Get current-project-description from current-project-details
            (current-project-description (get description current-project-details))

            ;; Check if filmmaker explicitly disabled public crowdfunding or not fromthe current-project-details
            (public-funding-enabled (get enable-public-crowdfunding current-project-details))

            ;; Default to REWARD-TIERS if public-funding is enabled 
            (current-reward-tiers (if public-funding-enabled 
                                        ;; Use configured tiers
                                        DEFAULT-REWARD-TIERS 
                                        ;; Pool-only, no rewards
                                        u0
                                  )

            )

            ;; Default-to REWARD-DESCRIPTION if public-funding enabled
            (current-reward-description (if public-funding-enabled 
                                            ;; Use reward-description for configured tiers
                                            DEFAULT-REWARD-DESCRIPTION 
                                            "Co-EP Pool Funded Project"
                                        )
            )

            ;; Get beneficiary from funding-rotation-schedule data
            (current-beneficiary (get beneficiary funding-rotation-schedule-data))

            ;; Get funding-amount from funding-rotation-schedule
            (current-funding-amount (get funding-amount funding-rotation-schedule-data))

            ;; Get current-project-expected-completion from current-project-details 
            ;; of funding-rotation-schedule
            (current-project-expected-completion (get expected-completion current-project-details))

        ) 
         ;; Call existing crowdfunding module to create campaign
        ;; This integrates with your existing architecture
        (contract-call? .crowdfunding-module create-campaign 
            current-project-description ;; project description
            u0 ;; campaign-id will auto-generate from u0
            current-funding-amount ;; funding-goal
            current-project-expected-completion ;;  funding-goal
            current-reward-tiers ;; mutlitple tiers for backers
            current-reward-description) ;; reward-description
        
    )

)


;; Initialization function to set up core-contract, as well as the crowdfunding, verification and escrow contract addresses
;; Purpose: Can only be called once by the contract owner (tx-sender at deployment) to handle initial bootstrapping
(define-public (initialize (core principal) (crowdfunding principal) (verification principal) (escrow principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set crowdfunding-contract crowdfunding)
    (var-set verification-contract verification)
    (var-set escrow-contract escrow)
    (ok true)
  )
)

;; Set the crowdfunding-contract 
;; Purpose: Dynamic module replacement
(define-public (set-crowdfunding (crowdfunding principal))
  (begin 
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set crowdfunding-contract crowdfunding)
    (ok true)
  )   
)

;; Set the verification-contract 
;; Purpose: Dynamic module replacement
(define-public (set-verification (verification principal))
  (begin 
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set verification-contract verification)
    (ok true)
  )   
)


;; Get system-paused status
(define-read-only (is-system-paused) 
  (var-get emergency-pause)
)

