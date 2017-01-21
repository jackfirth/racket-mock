#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [mock-call (->* () (#:args arguments? #:results list?) mock-call?)]
  [mock-call? predicate/c]
  [mock-call-args (-> mock-call? arguments?)]
  [mock-call-results (-> mock-call? list?)]))

(require "args.rkt")


(struct mock-call (args results)
  #:transparent #:omit-define-syntaxes #:constructor-name make-mock-call)

(define (mock-call #:args [args (arguments)] #:results [results (list)])
  (make-mock-call args results))
