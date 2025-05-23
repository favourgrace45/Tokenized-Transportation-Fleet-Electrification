;; Fleet Verification Contract
;; This contract validates transportation operators

(define-data-var admin principal tx-sender)

;; Data map for verified fleet operators
(define-map verified-operators principal
  {
    company-name: (string-utf8 100),
    license-number: (string-utf8 50),
    verification-date: uint,
    is-active: bool
  }
)

;; Public function to verify a new fleet operator
(define-public (verify-operator (operator principal) (company-name (string-utf8 100)) (license-number (string-utf8 50)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only admin can verify
    (asserts! (is-none (map-get? verified-operators operator)) (err u101)) ;; Operator not already verified

    (map-set verified-operators operator
      {
        company-name: company-name,
        license-number: license-number,
        verification-date: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

;; Public function to deactivate an operator
(define-public (deactivate-operator (operator principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only admin can deactivate
    (asserts! (is-some (map-get? verified-operators operator)) (err u102)) ;; Operator must exist

    (let ((current-data (unwrap-panic (map-get? verified-operators operator))))
      (map-set verified-operators operator
        (merge current-data { is-active: false })
      )
    )
    (ok true)
  )
)

;; Public function to check if an operator is verified
(define-read-only (is-verified (operator principal))
  (match (map-get? verified-operators operator)
    data (ok (get is-active data))
    (err u102) ;; Operator not found
  )
)

;; Public function to get operator details
(define-read-only (get-operator-details (operator principal))
  (map-get? verified-operators operator)
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only current admin can transfer
    (var-set admin new-admin)
    (ok true)
  )
)
