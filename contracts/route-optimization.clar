;; Route Optimization Contract
;; This contract plans efficient electric routes

(define-data-var admin principal tx-sender)

;; Data map for optimized routes
(define-map optimized-routes (tuple (fleet-id principal) (route-id uint))
  {
    start-lat: int, ;; latitude * 10^6
    start-lng: int, ;; longitude * 10^6
    end-lat: int, ;; latitude * 10^6
    end-lng: int, ;; longitude * 10^6
    distance: uint, ;; in meters
    estimated-energy: uint, ;; in Wh
    charging-stops: (list 10 uint), ;; list of charging station IDs
    creation-date: uint,
    is-active: bool
  }
)

;; Counter for route IDs
(define-data-var next-route-id uint u1)

;; Public function to create a new optimized route
(define-public (create-route
    (fleet-id principal)
    (start-lat int)
    (start-lng int)
    (end-lat int)
    (end-lng int)
    (distance uint)
    (estimated-energy uint)
    (charging-stops (list 10 uint)))
  (let ((route-id (var-get next-route-id)))
    (begin
      ;; Check if caller is the fleet owner or admin
      (asserts! (or (is-eq tx-sender fleet-id) (is-eq tx-sender (var-get admin))) (err u100))

      ;; Create the route
      (map-set optimized-routes (tuple (fleet-id fleet-id) (route-id route-id))
        {
          start-lat: start-lat,
          start-lng: start-lng,
          end-lat: end-lat,
          end-lng: end-lng,
          distance: distance,
          estimated-energy: estimated-energy,
          charging-stops: charging-stops,
          creation-date: block-height,
          is-active: true
        }
      )

      ;; Increment the route ID counter
      (var-set next-route-id (+ route-id u1))

      (ok route-id)
    )
  )
)

;; Public function to deactivate a route
(define-public (deactivate-route (fleet-id principal) (route-id uint))
  (begin
    ;; Check if caller is the fleet owner or admin
    (asserts! (or (is-eq tx-sender fleet-id) (is-eq tx-sender (var-get admin))) (err u100))

    ;; Check if route exists
    (asserts! (is-some (map-get? optimized-routes (tuple (fleet-id fleet-id) (route-id route-id)))) (err u101))

    (let ((current-data (unwrap-panic (map-get? optimized-routes (tuple (fleet-id fleet-id) (route-id route-id))))))
      (map-set optimized-routes (tuple (fleet-id fleet-id) (route-id route-id))
        (merge current-data { is-active: false })
      )
    )
    (ok true)
  )
)

;; Public function to get route details
(define-read-only (get-route-details (fleet-id principal) (route-id uint))
  (map-get? optimized-routes (tuple (fleet-id fleet-id) (route-id route-id)))
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u100)) ;; Only current admin can transfer
    (var-set admin new-admin)
    (ok true)
  )
)
