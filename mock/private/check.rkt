#lang racket/base

(require racket/bool
         racket/contract
         rackunit
         "base.rkt")

(provide
 (contract-out
  [called-with? (-> list? mock? boolean?)]
  [num-calls (-> mock? exact-nonnegative-integer?)]
  [check-called-with? (-> mock? list? void?)]
  [check-num-calls (-> mock? exact-nonnegative-integer? void?)]))


(define (called-with? args mock)
  (not (false? (member args (map mock-call-args (mock-calls mock))))))

(define (num-calls mock)
  (length (mock-calls mock)))

(define-simple-check (check-called-with? mock args)
  (called-with? args mock))

(define-simple-check (check-num-calls mock expected-num-calls)
  (equal? (num-calls mock) expected-num-calls))

