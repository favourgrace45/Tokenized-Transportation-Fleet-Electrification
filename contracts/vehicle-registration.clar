;; Vehicle Registration Contract
;; This contract records electric vehicles

(define-data-var admin principal tx-sender)

;; Data map for registered vehicles
(define-map registered-vehicles (tuple (fleet-id principal) (vehicle-id uint))
  {
    make: (string-utf8 50),
    model: (string-utf8 50),
    year: uint,
    battery-capacity: uint, ;; in kWh
    range: uint, ;; in miles
    registration-date: uint,
    is-active: bool
  }
)

;; Counter for vehicle IDs
(define-data-var next-vehicle-id uint u1)

;; Public function to register a new vehicle
(define-public (register-vehicle
    (fleet-id principal)
    (make (string-utf8 50))
    (model (string-utf8 50))
    (year uint)
    (battery-capacity uint)
    (range uint))
  (let ((vehicle-id (var-get next-vehicle-id)))
    (begin
      ;; Check if caller is the fleet owner or admin
      (asserts! (or (is-eq tx-sender fleet-id) (is-eq tx-sender (var-get admin))) (err u100))

      ;; Register the vehicle
      (map-set registered-vehicles (tuple (fleet-id fleet-id) (vehicle-id vehicle-id))
        {
          make: make,
          model: model,
          year: year,
          battery-capacity: battery-capacity,
          range: range,
          registration-date: block-height,
          is-active: true
        }
      )

      ;; Increment the vehicle ID counter
      (var-set next-vehicle-id (+ vehicle-id u1))

      (ok vehicle-id)
    )
  )
)

;; Public function to deactivate a vehicle
(define-public (deactivate-vehicle (fleet-id principal) (vehicle-id uint))
  (begin
    ;; Check if caller is the fleet owner or admin
    (asserts! (or (is-eq tx-sender fleet-id) (is-eq tx-sender (var-get admin))) (err u100))

    ;; Check if vehicle exists
    (asserts! (is-some (map-get? registered-vehicles (tuple (fleet-id fleet-id) (vehicle-id vehicle-id)))) (err u101))

    (let ((current-data (unwrap-panic (map-get? registered-vehicles (tuple (fleet-id fleet-id) (vehicle-id vehicle-id))))))
      (map-set registered-vehicles (tuple (fleet-id fleet-id) (vehicle-id vehicle-id))
        (merge current-data { is-active: false })
      )
    )
    (ok true)
  )
)

;; Public function to get vehicle details
(define-read-only (get-vehicle-details (fleet-id principal) (vehicle-id uint))
  (map-get? registered-vehicles (tuple (fleet-id fleet-id) (vehicle-id vehicle-id)))
)

;; Public function to check if a vehicle is active
(define-read-only (is-vehicle-active (fleet-id principal) (vehicle-id uint))
  (match (map-get? registered-vehicles (tuple (fleet-id fleet-id) (vehicle-id vehicle-id)))
    data (ok (get is-active data))
    (err u101) ;; Vehicle not found
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only current admin can transfer
    (var-set admin new-admin)
    (ok true)
  )
)
