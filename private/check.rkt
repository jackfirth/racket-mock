#lang sweet-exp racket/base

require racket/contract
        rackunit
        "args.rkt"
        "base.rkt"

provide check-mock-called-with?
        check-mock-num-calls

(define no-calls-made-message "No calls were made matching the expected arguments")

(define-check (check-mock-called-with? mock args)
  (with-check-info (['expected-args args]
                    ['actual-calls (mock-calls mock)])
    (unless (mock-called-with? mock args) (fail-check no-calls-made-message))))

(module+ test
  (test-case "Should check if a mock's been called with given arguments"
    (define m (mock #:behavior void))
    (m 1 2 3)
    (check-mock-called-with? m (arguments 1 2 3))))

(define-simple-check (check-mock-num-calls mock expected-num-calls)
  (equal? (mock-num-calls mock) expected-num-calls))
