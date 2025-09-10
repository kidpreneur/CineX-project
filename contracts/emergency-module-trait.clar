
;; title: emergency-module-trait
;; version: 1.0.0
;; Purpose: Emergency operations trait, as a standard evacuation plan for modules that handle funds
;; Functions: Emergency withdraw, pause state management
;; Author: Victor Omenai 
;; Created: 2025



(define-trait emergency-module-trait 
    (
        ;; EMERGENCY ONLY: Pull money out when something goes wrong 
        (emergency-withdraw (uint principal) (response bool uint))

        ;; EMERGENCY ONLY: Pause/unpause this module
        (set-pause-state (bool) (response bool uint))

    )
)


