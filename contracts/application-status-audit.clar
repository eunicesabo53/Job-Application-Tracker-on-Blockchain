(define-map owners { id: uint } { owner: principal })
(define-map writers { id: uint, addr: principal } { allowed: bool })
(define-map last-seq { id: uint } { seq: uint })
(define-map history { id: uint, seq: uint } { status: uint, reason: (string-ascii 80), at: uint, by: principal })

(define-constant err-already-claimed u100)
(define-constant err-not-owner u101)
(define-constant err-not-found u102)
(define-constant err-unauthorized u103)

(define-public (claim (id uint))
  (if (is-some (map-get? owners { id: id }))
      (err err-already-claimed)
      (begin
        (map-set owners { id: id } { owner: tx-sender })
        (ok true)
      )
  )
)

(define-read-only (get-owner (id uint))
  (match (map-get? owners { id: id })
    owner-rec (some (get owner owner-rec))
    none
  )
)

(define-public (grant-writer (id uint) (addr principal))
  (match (map-get? owners { id: id })
    owner-rec (if (is-eq (get owner owner-rec) tx-sender)
                    (begin
                      (map-set writers { id: id, addr: addr } { allowed: true })
                      (ok true)
                    )
                    (err err-not-owner))
    (err err-not-found)
  )
)

(define-public (revoke-writer (id uint) (addr principal))
  (match (map-get? owners { id: id })
    owner-rec (if (is-eq (get owner owner-rec) tx-sender)
                    (begin
                      (map-delete writers { id: id, addr: addr })
                      (ok true)
                    )
                    (err err-not-owner))
    (err err-not-found)
  )
)

(define-read-only (is-writer (id uint) (addr principal))
  (match (map-get? writers { id: id, addr: addr })
    rec (get allowed rec)
    false
  )
)

(define-public (write-status (id uint) (status uint) (reason (string-ascii 80)))
  (let ((owner-opt (map-get? owners { id: id })))
    (if (is-some owner-opt)
        (let ((owner-record (unwrap-panic owner-opt))
              (writer-opt (map-get? writers { id: id, addr: tx-sender }))
              (allowed (match writer-opt rec (get allowed rec) false)))
          (if (or (is-eq (get owner owner-record) tx-sender) allowed)
              (let ((seq-record-opt (map-get? last-seq { id: id }))
                    (current-seq (match seq-record-opt seq-record (get seq seq-record) u0))
                    (new-seq (+ current-seq u1)))
                (begin
                  (map-set last-seq { id: id } { seq: new-seq })
                  (map-set history { id: id, seq: new-seq } {
                    status: status,
                    reason: reason,
                    at: stacks-block-height,
                    by: tx-sender,
                  })
                  (ok new-seq)
                )
              )
              (err err-unauthorized)
          )
        )
        (let ((new-seq u1))
          (begin
            (map-set owners { id: id } { owner: tx-sender })
            (map-set last-seq { id: id } { seq: new-seq })
            (map-set history { id: id, seq: new-seq } {
              status: status,
              reason: reason,
              at: stacks-block-height,
              by: tx-sender,
            })
            (ok new-seq)
          )
        )
    )
  )
)

(define-read-only (get-latest-status (id uint))
  (let ((seq-record-opt (map-get? last-seq { id: id })))
    (match seq-record-opt
      seq-record (let ((current-seq (get seq seq-record)))
                   (map-get? history { id: id, seq: current-seq }))
      none
    )
  )
)

(define-read-only (get-status-at (id uint) (seq uint))
  (map-get? history { id: id, seq: seq })
)

(define-read-only (get-history-length (id uint))
  (let ((seq-record-opt (map-get? last-seq { id: id })))
    (match seq-record-opt
      seq-record (get seq seq-record)
      u0
    )
  )
)
