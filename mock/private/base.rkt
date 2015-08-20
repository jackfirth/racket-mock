#lang racket/base

(require racket/bool
         racket/contract
         racket/splicing
         rackunit
         unstable/sequence)

(provide
 (contract-out
  [mock? predicate/c]
  [make-mock (-> procedure? mock?)]
  [mock-calls (-> mock? (listof mock-call?))]
  [struct mock-call ([args list?] [result any/c])]))

(struct mock (proc calls-box)
  #:property prop:procedure (struct-field-index proc))

(struct mock-call (args result) #:prefab)

(define (make-mock proc)
  (define calls (box '()))
  (define (add-call! call)
    (set-box! calls (cons call (unbox calls))))
  (define (wrapper . vs)
    (define result (apply proc vs))
    (add-call! (mock-call vs result))
    result)
  (mock wrapper calls))

(define (mock-calls mock)
  (unbox (mock-calls mock)))
