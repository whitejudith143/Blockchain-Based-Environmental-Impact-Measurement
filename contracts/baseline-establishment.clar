;; Baseline Establishment Contract
;; Records pre-activity environmental conditions

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_BASELINE_EXISTS (err u201))
(define-constant ERR_BASELINE_NOT_FOUND (err u202))

;; Data structures
(define-map baselines
  { baseline-id: uint }
  {
    location: (string-ascii 100),
    measurer: principal,
    timestamp: uint,
    air-quality-index: uint,
    water-quality-score: uint,
    soil-ph-level: uint,
    biodiversity-index: uint,
    carbon-level: uint,
    metadata: (string-ascii 500)
  }
)

(define-map location-baselines
  { location: (string-ascii 100) }
  { baseline-id: uint, established: bool }
)

(define-data-var next-baseline-id uint u1)

;; Public functions
(define-public (establish-baseline
  (location (string-ascii 100))
  (air-quality-index uint)
  (water-quality-score uint)
  (soil-ph-level uint)
  (biodiversity-index uint)
  (carbon-level uint)
  (metadata (string-ascii 500))
)
  (let ((baseline-id (var-get next-baseline-id))
        (existing-baseline (map-get? location-baselines { location: location })))
    (asserts! (is-none existing-baseline) ERR_BASELINE_EXISTS)

    (map-set baselines
      { baseline-id: baseline-id }
      {
        location: location,
        measurer: tx-sender,
        timestamp: block-height,
        air-quality-index: air-quality-index,
        water-quality-score: water-quality-score,
        soil-ph-level: soil-ph-level,
        biodiversity-index: biodiversity-index,
        carbon-level: carbon-level,
        metadata: metadata
      }
    )

    (map-set location-baselines
      { location: location }
      { baseline-id: baseline-id, established: true }
    )

    (var-set next-baseline-id (+ baseline-id u1))
    (ok baseline-id)
  )
)

(define-public (update-baseline
  (baseline-id uint)
  (air-quality-index uint)
  (water-quality-score uint)
  (soil-ph-level uint)
  (biodiversity-index uint)
  (carbon-level uint)
)
  (let ((baseline (unwrap! (map-get? baselines { baseline-id: baseline-id }) ERR_BASELINE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get measurer baseline)) ERR_UNAUTHORIZED)

    (map-set baselines
      { baseline-id: baseline-id }
      (merge baseline {
        air-quality-index: air-quality-index,
        water-quality-score: water-quality-score,
        soil-ph-level: soil-ph-level,
        biodiversity-index: biodiversity-index,
        carbon-level: carbon-level,
        timestamp: block-height
      })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-baseline (baseline-id uint))
  (map-get? baselines { baseline-id: baseline-id })
)

(define-read-only (get-location-baseline (location (string-ascii 100)))
  (map-get? location-baselines { location: location })
)
