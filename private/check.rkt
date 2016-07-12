#lang sweet-exp racket/base

require racket/contract
        rackunit
        "args.rkt"
        "base.rkt"

provide
  contract-out
    check-mock-called-with? (-> mock? arguments? void?)
    check-mock-num-calls (-> exact-nonnegative-integer? mock? void?)

module+ test
  require racket/function
          rackunit


(define (fail-unless-called mock args)
  (unless (mock-called-with? mock args)
    (fail-check no-calls-made-message)))

(module+ test
  (check-exn exn:test:check?
             (thunk (fail-unless-called (mock) (arguments 1 2 3)))))

(define no-calls-made-message
  "No calls were made matching the expected arguments")

(define-check (check-mock-called-with? mock args)
  (with-check-info (['expected-args args]
                    ['actual-calls (mock-calls mock)])
    (fail-unless-called mock args)))

(define-simple-check (check-mock-num-calls expected-num-calls mock)
  (equal? (mock-num-calls mock) expected-num-calls))
