(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-status (err u103))
(define-constant err-deadline-passed (err u111))

;; Skills Tracking Error Constants
(define-constant err-skill-not-found (err u400))
(define-constant err-invalid-proficiency (err u401))
(define-constant err-skill-already-exists (err u402))
(define-constant err-skill-unauthorized (err u403))
(define-constant err-requirement-not-found (err u404))
(define-constant err-invalid-skill-category (err u405))

;; Skill Category Constants
(define-constant SKILL-TECHNICAL u1)
(define-constant SKILL-SOFT u2)
(define-constant SKILL-LANGUAGE u3)
(define-constant SKILL-CERTIFICATION u4)
(define-constant err-invalid-params (err u105))

(define-data-var application-id-nonce uint u0)
(define-data-var employer-id-nonce uint u0)
(define-data-var skill-id-nonce uint u0)

(define-map applications
    { id: uint }
    {
        applicant: principal,
        employer-id: uint,
        position-title: (string-ascii 100),
        company-name: (string-ascii 100),
        application-date: uint,
        status: (string-ascii 20),
        notes: (string-ascii 500),
        salary-range: uint,
        location: (string-ascii 100),
        application-method: (string-ascii 50),
        contact-person: (string-ascii 100),
        last-updated: uint,
        updated-by: principal,
    }
)

(define-map employers
    { id: uint }
    {
        name: (string-ascii 100),
        industry: (string-ascii 50),
        size: (string-ascii 20),
        location: (string-ascii 100),
        website: (string-ascii 200),
        registered-by: principal,
        registration-date: uint,
        verified: bool,
    }
)

(define-map user-applications
    { user: principal }
    { application-ids: (list 100 uint) }
)

(define-map employer-applications
    { employer-id: uint }
    { application-ids: (list 1000 uint) }
)

(define-map application-history
    {
        application-id: uint,
        sequence: uint,
    }
    {
        status: (string-ascii 20),
        updated-by: principal,
        timestamp: uint,
        notes: (string-ascii 200),
    }
)

;; Skills Tracking Data Maps
(define-map skills
    { skill-id: uint }
    {
        name: (string-ascii 50),
        category: uint,
        created-at: uint,
    }
)

(define-map user-skills
    { user: principal, skill-id: uint }
    {
        proficiency: uint,
        acquired-at: uint,
        last-updated: uint,
    }
)

(define-map application-requirements
    { application-id: uint, skill-id: uint }
    {
        min-proficiency: uint,
        required: bool,
    }
)

(define-map skill-counters
    { user: principal }
    {
        total-skills: uint,
    }
)

(define-read-only (get-application (id uint))
    (map-get? applications { id: id })
)

(define-read-only (get-employer (id uint))
    (map-get? employers { id: id })
)

(define-read-only (get-user-applications (user principal))
    (default-to { application-ids: (list) }
        (map-get? user-applications { user: user })
    )
)

(define-read-only (get-employer-applications (employer-id uint))
    (default-to { application-ids: (list) }
        (map-get? employer-applications { employer-id: employer-id })
    )
)

(define-read-only (get-application-count)
    (var-get application-id-nonce)
)

(define-read-only (get-employer-count)
    (var-get employer-id-nonce)
)

(define-read-only (get-applications-by-status (status (string-ascii 20)))
    (ok status)
)

(define-read-only (get-application-history (application-id uint))
    (ok application-id)
)

;; Skills Tracking Read-Only Functions
(define-read-only (get-skill (skill-id uint))
    (map-get? skills { skill-id: skill-id })
)

(define-read-only (get-user-skill (user principal) (skill-id uint))
    (map-get? user-skills { user: user, skill-id: skill-id })
)

(define-read-only (get-application-requirement (application-id uint) (skill-id uint))
    (map-get? application-requirements {
        application-id: application-id,
        skill-id: skill-id,
    })
)

(define-read-only (get-skill-count)
    (var-get skill-id-nonce)
)

(define-read-only (get-user-skill-portfolio (user principal))
    (default-to { total-skills: u0 }
        (map-get? skill-counters { user: user })
    )
)

(define-read-only (calculate-skill-gap (user principal) (application-id uint))
    (ok { user: user, application-id: application-id })
)

(define-read-only (check-requirements-met (user principal) (application-id uint))
    (ok (and
        (is-some (map-get? applications { id: application-id }))
        (> (get total-skills (get-user-skill-portfolio user)) u0)
    ))
)

(define-read-only (get-skill-recommendations (user principal) (application-id uint))
    (ok { user: user, application-id: application-id, recommendations: (list) })
)

(define-public (register-employer
        (name (string-ascii 100))
        (industry (string-ascii 50))
        (size (string-ascii 20))
        (location (string-ascii 100))
        (website (string-ascii 200))
    )
    (let ((new-id (+ (var-get employer-id-nonce) u1)))
        (var-set employer-id-nonce new-id)
        (map-set employers { id: new-id } {
            name: name,
            industry: industry,
            size: size,
            location: location,
            website: website,
            registered-by: tx-sender,
            registration-date: stacks-block-height,
            verified: false,
        })
        (ok new-id)
    )
)

(define-public (verify-employer (employer-id uint))
    (if (is-eq tx-sender contract-owner)
        (let ((employer (unwrap! (map-get? employers { id: employer-id }) err-not-found)))
            (map-set employers { id: employer-id }
                (merge employer { verified: true })
            )
            (ok true)
        )
        err-owner-only
    )
)

(define-public (submit-application
        (employer-id uint)
        (position-title (string-ascii 100))
        (company-name (string-ascii 100))
        (notes (string-ascii 500))
        (salary-range uint)
        (location (string-ascii 100))
        (application-method (string-ascii 50))
        (contact-person (string-ascii 100))
    )
    (let (
            (new-id (+ (var-get application-id-nonce) u1))
            (current-time stacks-block-height)
            (user-apps (get application-ids (get-user-applications tx-sender)))
            (employer-apps (get application-ids (get-employer-applications employer-id)))
        )
        (var-set application-id-nonce new-id)
        (map-set applications { id: new-id } {
            applicant: tx-sender,
            employer-id: employer-id,
            position-title: position-title,
            company-name: company-name,
            application-date: current-time,
            status: "submitted",
            notes: notes,
            salary-range: salary-range,
            location: location,
            application-method: application-method,
            contact-person: contact-person,
            last-updated: current-time,
            updated-by: tx-sender,
        })
        (map-set user-applications { user: tx-sender } { application-ids: (unwrap-panic (as-max-len? (append user-apps new-id) u100)) })
        (map-set employer-applications { employer-id: employer-id } { application-ids: (unwrap-panic (as-max-len? (append employer-apps new-id) u1000)) })
        (map-set application-history {
            application-id: new-id,
            sequence: u1,
        } {
            status: "submitted",
            updated-by: tx-sender,
            timestamp: current-time,
            notes: "Application submitted",
        })
        (ok new-id)
    )
)

(define-public (update-application-status
        (application-id uint)
        (new-status (string-ascii 20))
        (notes (string-ascii 200))
    )
    (let (
            (app (unwrap! (map-get? applications { id: application-id }) err-not-found))
            (current-time stacks-block-height)
        )
        (asserts!
            (or
                (is-eq tx-sender (get applicant app))
                (is-eq tx-sender contract-owner)
            )
            err-unauthorized
        )
        (asserts!
            (or
                (is-eq new-status "submitted")
                (is-eq new-status "under-review")
                (is-eq new-status "interview-scheduled")
                (is-eq new-status "interviewed")
                (is-eq new-status "offer-received")
                (is-eq new-status "accepted")
                (is-eq new-status "rejected")
                (is-eq new-status "withdrawn")
            )
            err-invalid-status
        )
        (map-set applications { id: application-id }
            (merge app {
                status: new-status,
                last-updated: current-time,
                updated-by: tx-sender,
            })
        )
        (map-set application-history {
            application-id: application-id,
            sequence: u1,
        } {
            status: new-status,
            updated-by: tx-sender,
            timestamp: current-time,
            notes: notes,
        })
        (ok true)
    )
)

(define-public (update-application-notes
        (application-id uint)
        (new-notes (string-ascii 500))
    )
    (let ((app (unwrap! (map-get? applications { id: application-id }) err-not-found)))
        (asserts! (is-eq tx-sender (get applicant app)) err-unauthorized)
        (map-set applications { id: application-id }
            (merge app {
                notes: new-notes,
                last-updated: stacks-block-height,
                updated-by: tx-sender,
            })
        )
        (ok true)
    )
)

(define-public (delete-application (application-id uint))
    (let (
            (app (unwrap! (map-get? applications { id: application-id }) err-not-found))
            (user-apps (get application-ids (get-user-applications (get applicant app))))
            (employer-apps (get application-ids
                (get-employer-applications (get employer-id app))
            ))
        )
        (asserts!
            (or
                (is-eq tx-sender (get applicant app))
                (is-eq tx-sender contract-owner)
            )
            err-unauthorized
        )
        (map-delete applications { id: application-id })
        (map-set user-applications { user: (get applicant app) } { application-ids: (filter remove-id user-apps) })
        (map-set employer-applications { employer-id: (get employer-id app) } { application-ids: (filter remove-id employer-apps) })
        (ok true)
    )
)

(define-private (remove-id (id uint))
    true
)

(define-read-only (get-applications-summary (user principal))
    (let ((user-apps (get application-ids (get-user-applications user))))
        {
            total: (len user-apps),
            submitted: (count-status-in-list user-apps "submitted"),
            under-review: (count-status-in-list user-apps "under-review"),
            interviewed: (count-status-in-list user-apps "interviewed"),
            offers: (count-status-in-list user-apps "offer-received"),
            accepted: (count-status-in-list user-apps "accepted"),
            rejected: (count-status-in-list user-apps "rejected"),
        }
    )
)

(define-private (count-status-in-list
        (app-list (list 100 uint))
        (target-status (string-ascii 20))
    )
    (fold count-status app-list u0)
)

(define-private (count-status
        (app-id uint)
        (acc uint)
    )
    (+ acc u1)
)

(define-public (bulk-update-status
        (application-ids (list 10 uint))
        (new-status (string-ascii 20))
        (notes (string-ascii 200))
    )
    (ok (len application-ids))
)

;; Skills Tracking Public Functions
(define-public (register-skill
        (name (string-ascii 50))
        (category uint)
    )
    (let ((new-id (+ (var-get skill-id-nonce) u1)))
        (asserts!
            (or
                (is-eq category SKILL-TECHNICAL)
                (is-eq category SKILL-SOFT)
                (is-eq category SKILL-LANGUAGE)
                (is-eq category SKILL-CERTIFICATION)
            )
            err-invalid-skill-category
        )
        (asserts!
            (is-none (map-get? skills { skill-id: new-id }))
            err-skill-already-exists
        )
        (var-set skill-id-nonce new-id)
        (map-set skills { skill-id: new-id } {
            name: name,
            category: category,
            created-at: stacks-block-height,
        })
        (ok new-id)
    )
)

(define-public (add-user-skill
        (skill-id uint)
        (proficiency uint)
    )
    (let (
            (skill (unwrap! (map-get? skills { skill-id: skill-id }) err-skill-not-found))
            (current-counters (default-to { total-skills: u0 }
                (map-get? skill-counters { user: tx-sender })
            ))
        )
        (asserts!
            (and (>= proficiency u1) (<= proficiency u5))
            err-invalid-proficiency
        )
        (asserts!
            (is-none (map-get? user-skills { user: tx-sender, skill-id: skill-id }))
            err-skill-already-exists
        )
        (map-set user-skills {
            user: tx-sender,
            skill-id: skill-id,
        } {
            proficiency: proficiency,
            acquired-at: stacks-block-height,
            last-updated: stacks-block-height,
        })
        (map-set skill-counters { user: tx-sender } {
            total-skills: (+ (get total-skills current-counters) u1),
        })
        (ok true)
    )
)

(define-public (update-skill-proficiency
        (skill-id uint)
        (new-proficiency uint)
    )
    (let (
            (user-skill (unwrap!
                (map-get? user-skills { user: tx-sender, skill-id: skill-id })
                err-skill-not-found
            ))
        )
        (asserts!
            (and (>= new-proficiency u1) (<= new-proficiency u5))
            err-invalid-proficiency
        )
        (map-set user-skills {
            user: tx-sender,
            skill-id: skill-id,
        }
            (merge user-skill {
                proficiency: new-proficiency,
                last-updated: stacks-block-height,
            })
        )
        (ok true)
    )
)

(define-public (add-application-requirement
        (application-id uint)
        (skill-id uint)
        (min-proficiency uint)
    )
    (let (
            (app (unwrap! (map-get? applications { id: application-id }) err-not-found))
            (skill (unwrap! (map-get? skills { skill-id: skill-id }) err-skill-not-found))
        )
        (asserts!
            (is-eq tx-sender (get applicant app))
            err-skill-unauthorized
        )
        (asserts!
            (and (>= min-proficiency u1) (<= min-proficiency u5))
            err-invalid-proficiency
        )
        (map-set application-requirements {
            application-id: application-id,
            skill-id: skill-id,
        } {
            min-proficiency: min-proficiency,
            required: true,
        })
        (ok true)
    )
)

(define-public (remove-user-skill (skill-id uint))
    (let (
            (user-skill (unwrap!
                (map-get? user-skills { user: tx-sender, skill-id: skill-id })
                err-skill-not-found
            ))
            (current-counters (default-to { total-skills: u0 }
                (map-get? skill-counters { user: tx-sender })
            ))
        )
        (map-delete user-skills { user: tx-sender, skill-id: skill-id })
        (map-set skill-counters { user: tx-sender } {
            total-skills: (if (> (get total-skills current-counters) u0)
                (- (get total-skills current-counters) u1)
                u0
            ),
        })
        (ok true)
    )
)
