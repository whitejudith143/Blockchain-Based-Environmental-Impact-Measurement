;; Activity Verification Contract
;; Validates environmental activities and maintains activity records

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ACTIVITY_NOT_FOUND (err u101))
(define-constant ERR_INVALID_DATA (err u102))

;; Data structures
(define-map activities
  { activity-id: uint }
  {
    verifier: principal,
    activity-type: (string-ascii 50),
    location: (string-ascii 100),
    timestamp: uint,
    verified: bool,
    metadata: (string-ascii 500)
  }
)

(define-map verifiers
  { verifier: principal }
  { authorized: bool, reputation-score: uint }
)

(define-data-var next-activity-id uint u1)

;; Public functions
(define-public (register-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set verifiers { verifier: verifier } { authorized: true, reputation-score: u100 })
    (ok true)
  )
)

(define-public (submit-activity
  (activity-type (string-ascii 50))
  (location (string-ascii 100))
  (metadata (string-ascii 500))
)
  (let ((activity-id (var-get next-activity-id)))
    (map-set activities
      { activity-id: activity-id }
      {
        verifier: tx-sender,
        activity-type: activity-type,
        location: location,
        timestamp: block-height,
        verified: false,
        metadata: metadata
      }
    )
    (var-set next-activity-id (+ activity-id u1))
    (ok activity-id)
  )
)

(define-public (verify-activity (activity-id uint))
  (let ((activity (unwrap! (map-get? activities { activity-id: activity-id }) ERR_ACTIVITY_NOT_FOUND))
        (verifier-data (unwrap! (map-get? verifiers { verifier: tx-sender }) ERR_UNAUTHORIZED)))
    (asserts! (get authorized verifier-data) ERR_UNAUTHORIZED)
    (map-set activities
      { activity-id: activity-id }
      (merge activity { verified: true })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-activity (activity-id uint))
  (map-get? activities { activity-id: activity-id })
)

(define-read-only (is-verifier (verifier principal))
  (default-to { authorized: false, reputation-score: u0 }
    (map-get? verifiers { verifier: verifier }))
)
