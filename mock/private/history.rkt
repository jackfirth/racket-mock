#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [mock-call (->* ()
                  (#:name (or/c symbol? #f) #:args arguments? #:results list?)
                  mock-call?)]
  [mock-call? predicate/c]
  [mock-call-args (-> mock-call? arguments?)]
  [mock-call-results (-> mock-call? list?)]))

(require "args.rkt")

(module+ test
  (require rackunit))


(struct mock-call (name args results)
  #:transparent #:omit-define-syntaxes #:constructor-name make-mock-call)

(define (mock-call #:name [name #f]
                   #:args [args (arguments)]
                   #:results [results (list)])
  (make-mock-call name args results))

(module+ test
  (check-equal? (mock-call)
                (mock-call #:name #f #:args (arguments) #:results (list))))
