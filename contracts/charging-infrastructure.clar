;; Charging Infrastructure Contract
;; This contract manages charging stations

(define-data-var admin principal tx-sender)

;; Data map for charging stations
(define-map charging-stations uint
  {
    owner: principal,
    location-lat: int, ;; latitude * 10^6
    location-lng: int, ;; longitude * 10^6
    power-capacity: uint, ;; in kW
    ports-count: uint,
    is-active: bool,
    price-per-kwh: uint, ;; in microcents (1/10^6 of a cent)
    registration-date: uint
  }
)

;; Counter for station IDs
(define-data-var next-station-id uint u1)

;; Public function to register a new charging station
(define-public (register-station
    (location-lat int)
    (location-lng int)
    (power-capacity uint)
    (ports-count uint)
    (price-per-kwh uint))
  (let ((station-id (var-get next-station-id)))
    (begin
      (map-set charging-stations station-id
        {
          owner: tx-sender,
          location-lat: location-lat,
          location-lng: location-lng,
          power-capacity: power-capacity,
          ports-count: ports-count,
          is-active: true,
          price-per-kwh: price-per-kwh,
          registration-date: block-height
        }
      )

      ;; Increment the station ID counter
      (var-set next-station-id (+ station-id u1))

      (ok station-id)
    )
  )
)

;; Public function to update station details
(define-public (update-station
    (station-id uint)
    (power-capacity uint)
    (ports-count uint)
    (price-per-kwh uint)
    (is-active bool))
  (begin
    ;; Check if station exists
    (asserts! (is-some (map-get? charging-stations station-id)) (err u101))

    (let ((station-data (unwrap-panic (map-get? charging-stations station-id))))
      ;; Check if caller is the station owner or admin
      (asserts! (or (is-eq tx-sender (get owner station-data)) (is-eq tx-sender (var-get admin))) (err u100))

      (map-set charging-stations station-id
        (merge station-data
          {
            power-capacity: power-capacity,
            ports-count: ports-count,
            price-per-kwh: price-per-kwh,
            is-active: is-active
          }
        )
      )
    )
    (ok true)
  )
)

;; Public function to get station details
(define-read-only (get-station-details (station-id uint))
  (map-get? charging-stations station-id)
)

;; Public function to check if a station is active
(define-read-only (is-station-active (station-id uint))
  (match (map-get? charging-stations station-id)
    station-data (ok (get is-active station-data))
    (err u101) ;; Station not found
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
