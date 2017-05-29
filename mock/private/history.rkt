#lang racket/base

(require racket/contract/base)

(provide
 (contract-out
  [mock-call
   (->* () (#:name (or/c symbol? #f) #:args arguments? #:results list?)
        mock-call?)]
  [mock-call? predicate/c]
  [mock-call-args (-> mock-call? arguments?)]
  [mock-call-name (-> mock-call? (or/c symbol? #f))]
  [mock-call-results (-> mock-call? list?)]
  [call-history (-> call-history?)]
  [call-history? predicate/c]
  [call-history-record! (-> call-history? mock-call? void?)]
  [call-history-reset! (-> call-history? void?)]
  [call-history-reset-all! (->* () #:rest (listof call-history?) void?)]
  [call-history-calls (-> call-history? (listof mock-call?))]
  [call-history-count (-> call-history? exact-nonnegative-integer?)]))

(require arguments
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

(struct call-history (calls-box)
  #:transparent #:omit-define-syntaxes #:constructor-name make-call-history)

(define (call-history) (make-call-history (box '())))

(define (call-history-record! history call)
  (box-cons-end! (call-history-calls-box history) call))

(define (call-history-reset! history)
  (set-box! (call-history-calls-box history) '()))

(define (call-history-reset-all! . histories)
  (for-each call-history-reset! histories))

(define (call-history-calls history)
  (unbox (call-history-calls-box history)))

(define (call-history-count history) (length (call-history-calls history)))

(module+ test
  (define (foo-call n)
    (mock-call #:name 'foo #:args (arguments 'a 'b 'c) #:results (list n)))
  (define (bar-call n)
    (mock-call #:name 'bar #:args (arguments 'a 'b 'c) #:results (list n)))
  (define test-history (call-history))
  (check-pred call-history? test-history)
  (check-pred void? (call-history-record! test-history (foo-call 1)))
  (check-pred void? (call-history-record! test-history (bar-call 1)))
  (check-pred void? (call-history-record! test-history (foo-call 2)))
  (check-equal? (call-history-calls test-history)
                (list (foo-call 1) (bar-call 1) (foo-call 2)))
  (check-equal? (call-history-count test-history) 3))
