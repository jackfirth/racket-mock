#lang racket/base

(require racket/bool
         racket/contract
         rackunit
         "base.rkt")

(provide
 (contract-out
  [check-mock-called-with? (-> mock? list? void?)]
  [check-mock-num-calls (-> mock? exact-nonnegative-integer? void?)]))


(define-simple-check (check-mock-called-with? mock args)
  (mock-called-with? args mock))

(define-simple-check (check-mock-num-calls mock expected-num-calls)
  (equal? (mock-num-calls mock) expected-num-calls))

