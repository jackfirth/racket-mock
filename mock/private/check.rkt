#lang sweet-exp racket/base

require racket/bool
        racket/contract
        rackunit
        "base.rkt"

provide
  contract-out
    check-mock-called-with? (-> list? mock? void?)
    check-mock-num-calls (-> exact-nonnegative-integer? mock? void?)


(define-check (check-mock-called-with? args mock)
  (let ([result (mock-called-with? args mock)])
    (with-check-info
      [('expected args) ('actual (mock-calls mock))]
      (unless result
        (fail-check "Actual arguments did not match expected")))))


(define-simple-check (check-mock-num-calls expected-num-calls mock)
  (equal? (mock-num-calls mock) expected-num-calls))

