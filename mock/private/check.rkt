#lang sweet-exp racket/base

require racket/bool
        racket/contract
        rackunit
        "base.rkt"

provide
  contract-out
    check-mock-called-with? (-> mock? list? (hash/c keyword? any/c) void?)
    check-mock-num-calls (-> exact-nonnegative-integer? mock? void?)


(define-check (check-mock-called-with? mock args kwargs)
  (define result (mock-called-with? mock args kwargs))
  (with-check-info (['expected-args args]
                    ['expected-kwargs kwargs]
                    ['actual-calls (mock-calls mock)])
    (unless result
      (fail-check "No calls were made matching the expected arguments"))))

(define-simple-check (check-mock-num-calls expected-num-calls mock)
  (equal? (mock-num-calls mock) expected-num-calls))
