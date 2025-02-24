;; NexusLend: Digital Asset Lending Protocol
;; A decentralized lending protocol enabling collateralized loans on the blockchain

;; Constants
(define-constant PROTOCOL-ADMIN tx-sender)
(define-constant ERR-NOT-ENOUGH-FUNDS (err u100))
(define-constant ERR-NOT-PERMITTED (err u101))
(define-constant ERR-VAULT-NOT-FOUND (err u102))
(define-constant ERR-VAULT-EXISTS (err u103))
(define-constant ERR-REPAYMENT-FAILED (err u104))
(define-constant ERR-VAULT-HEALTHY (err u105))
(define-constant ERR-INVALID-INPUT (err u106))
(define-constant ERR-UNSAFE-RATIO (err u107))

;; Safety limits
(define-constant MAX-APR u10000) ;; 100.00%
(define-constant MAX-TERM-LENGTH u52560) ;; ~1 year in blocks
(define-constant MAX-VALUE u340282366920938463463374607431768211455)
(define-constant SAFETY-THRESHOLD u150) ;; 150% minimum collateral ratio

;; Data Storage
(define-map vaults 
  {
    vault-id: uint,
    owner: principal
  }
  {
    collateral: uint,
    debt: uint,
    apr: uint,
    creation-height: uint,
    term-length: uint,
    status: bool
  }
)

(define-map payments
  {
    vault-id: uint,
    owner: principal
  }
  {
    total-paid: uint
  }
)

;; State Variables
(define-data-var vault-counter uint u0)

;; Helper Functions
(define-private (validate-vault-params 
    (collateral uint)
    (debt uint)
    (apr uint)
    (term-length uint)
  )
  (and
    (> collateral u0)
    (<= collateral MAX-VALUE)
    (> debt u0)
    (<= debt MAX-VALUE)
    (<= apr MAX-APR)
    (> term-length u0)
    (<= term-length MAX-TERM-LENGTH)
  )
)

(define-private (verify-ownership (vault-id uint))
  (is-some 
    (map-get? vaults {
      vault-id: vault-id, 
      owner: tx-sender
    })
  )
)

(define-private (calculate-min-collateral (debt uint))
  (/ (* debt SAFETY-THRESHOLD) u100)
)

;; Query Functions
(define-read-only (get-vault-info (vault-id uint) (owner principal))
  (map-get? vaults {vault-id: vault-id, owner: owner})
)

(define-read-only (get-payment-info (vault-id uint) (owner principal))
  (map-get? payments {vault-id: vault-id, owner: owner})
)

;; Public Functions
(define-public (open-vault 
    (collateral uint)
    (debt uint)
    (apr uint)
    (term-length uint)
  )
  (let 
    (
      (current-id (var-get vault-counter))
      (new-id (+ current-id u1))
    )
    ;; Validate inputs
    (asserts! 
      (validate-vault-params 
        collateral 
        debt 
        apr 
        term-length
      ) 
      ERR-INVALID-INPUT
    )
    
    ;; Check uniqueness
    (asserts! 
      (is-none 
        (map-get? vaults {vault-id: new-id, owner: tx-sender})
      ) 
      ERR-VAULT-EXISTS
    )
    
    ;; Verify collateral adequacy
    (asserts! 
      (>= collateral (calculate-min-collateral debt)) 
      ERR-UNSAFE-RATIO
    )
    
    ;; Create vault
    (map-set vaults 
      {vault-id: new-id, owner: tx-sender}
      {
        collateral: collateral,
        debt: debt,
        apr: apr,
        creation-height: block-height,
        term-length: term-length,
        status: true
      }
    )
    
    ;; Increment counter
    (var-set vault-counter new-id)
    
    ;; Return ID
    (ok new-id)
  )
)

(define-public (deposit-collateral (vault-id uint) (amount uint))
  (let
    (
      (ownership-valid (asserts! 
        (verify-ownership vault-id) 
        ERR-NOT-PERMITTED
      ))
      
      (vault (unwrap! 
        (map-get? vaults {vault-id: vault-id, owner: tx-sender}) 
        ERR-VAULT-NOT-FOUND
      ))
    )
    ;; Check status
    (asserts! (get status vault) ERR-NOT-PERMITTED)
    
    ;; Validate amount
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    
    ;; Calculate new total
    (let
      (
        (new-collateral (+ (get collateral vault) amount))
      )
      (asserts! (<= new-collateral MAX-VALUE) ERR-INVALID-INPUT)
      
      ;; Update vault
      (map-set vaults 
        {vault-id: vault-id, owner: tx-sender}
        (merge vault {collateral: new-collateral})
      )
      
      (ok new-collateral)
    )
  )
)

(define-public (withdraw-collateral (vault-id uint) (amount uint))
  (let
    (
      (ownership-valid (asserts! 
        (verify-ownership vault-id) 
        ERR-NOT-PERMITTED
      ))
      
      (vault (unwrap! 
        (map-get? vaults {vault-id: vault-id, owner: tx-sender}) 
        ERR-VAULT-NOT-FOUND
      ))
    )
    ;; Verify active status
    (asserts! (get status vault) ERR-NOT-PERMITTED)
    
    ;; Check amount
    (asserts! (> amount u0) ERR-INVALID-INPUT)
    (asserts! (<= amount (get collateral vault)) ERR-NOT-ENOUGH-FUNDS)
    
    ;; Calculate remaining collateral
    (let
      (
        (remaining-collateral (- (get collateral vault) amount))
        (required-collateral (calculate-min-collateral (get debt vault)))
      )
      ;; Verify safety
      (asserts! (>= remaining-collateral required-collateral) ERR-UNSAFE-RATIO)
      
      ;; Update vault
      (map-set vaults 
        {vault-id: vault-id, owner: tx-sender}
        (merge vault {collateral: remaining-collateral})
      )
      
      (ok amount)
    )
  )
)

