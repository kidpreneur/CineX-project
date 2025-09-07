;; title: module-base-trait
;; Purpose: General module validation and versioning
;; Functions: Version info, activity status
;; Author: Victor Omenai 
;; Created: 2025

(define-trait module-base-trait 
    (
        ;; Get version number info (like "v1.0", "v2.0") - helps for tracking module updates
        (get-module-version () (response uint uint))

        ;; Check if module is currently active/currently working properly?
        (is-module-active () (response bool uint))

        ;; Get module name for identification - helps identify which module this is
        (get-module-name () (response (string-ascii 50) uint))
    )
)




