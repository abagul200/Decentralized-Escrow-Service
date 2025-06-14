(define-map escrows
  {buyer: principal, seller: principal}
  {amount: uint, approved: bool})

;; Buyer deposits funds into escrow
(define-public (deposit (seller principal) (amount uint))
  (begin
    (asserts! (> amount u0) (err u100))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set escrows {buyer: tx-sender, seller: seller}
             {amount: amount, approved: false})
    (ok true)))

;; Buyer approves payment to seller
(define-public (approve (seller principal))
  (let ((escrow (map-get? escrows {buyer: tx-sender, seller: seller})))
    (match escrow data
      (begin
        (map-set escrows {buyer: tx-sender, seller: seller}
                 {amount: (get amount data), approved: true})
        (ok true))
      (err u101)))) ;; escrow not found

;; Seller claims funds after approval
(define-public (claim (buyer principal))
  (let ((escrow (map-get? escrows {buyer: buyer, seller: tx-sender})))
    (match escrow data
      (begin
        (asserts! (is-eq (get approved data) true) (err u102))
        (try! (stx-transfer? (get amount data) (as-contract tx-sender) tx-sender))
        (map-delete escrows {buyer: buyer, seller: tx-sender})
        (ok true))
      (err u103)))) ;; escrow not found
