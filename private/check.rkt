#lang sweet-exp racket/base

require racket/contract
        rackunit
        "args.rkt"
        "base.rkt"

provide
  contract-out
    check-mock-called-with? (-> mock? arguments? void?)
    check-mock-num-calls (-> exact-nonnegative-integer? mock? void?)


(define-check (check-mock-called-with? mock args)
  (with-check-info (['expected-args args]
                    ['actual-calls (mock-calls mock)])
    (unless (mock-called-with? mock args)
      (fail-check "No calls were made matching the expected arguments"))))

(define-simple-check (check-mock-num-calls expected-num-calls mock)
  (equal? (mock-num-calls mock) expected-num-calls))
