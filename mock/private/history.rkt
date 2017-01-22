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

(require "args.rkt"
         "util.rkt")

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

(struct mock-history (calls-box)
  #:transparent #:omit-define-syntaxes #:constructor-name make-mock-history)

(define (mock-history) (make-mock-history (box '())))

(define (mock-history-record-call! history call)
  (box-cons-end! (mock-history-calls-box history) call))

(define (mock-history-calls history)
  (unbox (mock-history-calls-box history)))

(define (mock-history-calls/name history name)
  (filter (λ (call) (equal? (mock-call-name call) name))
          (mock-history-calls history)))

(define (mock-history-num-calls history) (length (mock-history-calls history)))
(define (mock-history-num-calls/name history name)
  (length (mock-history-calls/name history name)))

(module+ test
  (define (foo-call n)
    (mock-call #:name 'foo #:args (arguments 'a 'b 'c) #:results (list n)))
  (define (bar-call n)
    (mock-call #:name 'bar #:args (arguments 'a 'b 'c) #:results (list n)))
  (define test-history (mock-history))
  (check-pred mock-history? test-history)
  (check-pred void? (mock-history-record-call! test-history (foo-call 1)))
  (check-pred void? (mock-history-record-call! test-history (bar-call 1)))
  (check-pred void? (mock-history-record-call! test-history (foo-call 2)))
  (check-equal? (mock-history-calls test-history)
                (list (foo-call 1) (bar-call 1) (foo-call 2)))
  (check-equal? (mock-history-calls/name test-history 'foo)
                (list (foo-call 1) (foo-call 2)))
  (check-equal? (mock-history-num-calls test-history) 3)
  (check-equal? (mock-history-num-calls/name test-history 'bar) 1))
