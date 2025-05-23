;; Emissions Tracking Contract
;; This contract monitors carbon reduction

(define-data-var admin principal tx-sender)

;; Data map for emissions records
(define-map emissions-records (tuple (fleet-id principal) (year uint) (month uint))
  {
    distance-traveled: uint, ;; in kilometers
    energy-consumed: uint, ;; in kWh
    carbon-saved: uint, ;; in kg of CO2
    last-updated: uint
  }
)

;; Data map for fleet emission factors
(define-map fleet-emission-factors principal
  {
    baseline-emissions: uint, ;; gCO2/km for traditional vehicles
    ev-emissions: uint, ;; gCO2/km for electric vehicles (based on grid mix)
    last-updated: uint
  }
)

;; Default emission factors
(define-data-var default-baseline-emissions uint u220) ;; 220 gCO2/km for traditional vehicles
(define-data-var default-ev-emissions uint u50) ;; 50 gCO2/km for EVs (varies by region)

;; Public function to set fleet emission factors
(define-public (set-fleet-emission-factors (fleet-id principal) (baseline-emissions uint) (ev-emissions uint))
  (begin
    ;; Check if caller is the fleet owner or admin
    (asserts! (or (is-eq tx-sender fleet-id) (is-eq tx-sender (var-get admin))) (err u100))

    (map-set fleet-emission-factors fleet-id
      {
        baseline-emissions: baseline-emissions,
        ev-emissions: ev-emissions,
        last-updated: block-height
      }
    )
    (ok true)
  )
)

;; Public function to record emissions data
(define-public (record-emissions
    (fleet-id principal)
    (year uint)
    (month uint)
    (distance-traveled uint)
    (energy-consumed uint))
  (begin
    ;; Check if caller is the fleet owner or admin
    (asserts! (or (is-eq tx-sender fleet-id) (is-eq tx-sender (var-get admin))) (err u100))

    ;; Get emission factors (use defaults if not set)
    (let (
      (emission-factors (default-to
        {
          baseline-emissions: (var-get default-baseline-emissions),
          ev-emissions: (var-get default-ev-emissions),
          last-updated: u0
        }
        (map-get? fleet-emission-factors fleet-id)))
      (baseline (get baseline-emissions emission-factors))
      (ev (get ev-emissions emission-factors))
      (carbon-saved (/ (* distance-traveled (- baseline ev)) u1000)) ;; Convert from g to kg
      (current-record (map-get? emissions-records (tuple (fleet-id fleet-id) (year year) (month month))))
    )

      ;; Update or create the emissions record
      (map-set emissions-records (tuple (fleet-id fleet-id) (year year) (month month))
        (if (is-some current-record)
          (let ((existing-data (unwrap-panic current-record)))
            {
              distance-traveled: (+ (get distance-traveled existing-data) distance-traveled),
              energy-consumed: (+ (get energy-consumed existing-data) energy-consumed),
              carbon-saved: (+ (get carbon-saved existing-data) carbon-saved),
              last-updated: block-height
            }
          )
          {
            distance-traveled: distance-traveled,
            energy-consumed: energy-consumed,
            carbon-saved: carbon-saved,
            last-updated: block-height
          }
        )
      )
      (ok true)
    )
  )
)

;; Public function to get emissions data
(define-read-only (get-emissions-data (fleet-id principal) (year uint) (month uint))
  (map-get? emissions-records (tuple (fleet-id fleet-id) (year year) (month month)))
)

;; Public function to get total carbon saved for a fleet
(define-read-only (get-total-carbon-saved (fleet-id principal))
  (ok u0) ;; Placeholder - in a real implementation, this would aggregate all records
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only current admin can transfer
    (var-set admin new-admin)
    (ok true)
  )
)
