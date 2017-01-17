#lang sweet-exp racket/base

require racket/contract/base

provide
  contract-out
    const/kw (-> any/c procedure?)
    void/kw (unconstrained-domain-> void?)

require racket/function

module+ test
  require rackunit


(define (const/kw v)
  (make-keyword-procedure (const v)))

(module+ test
  (check-equal? ((const/kw 1)) 1)
  (check-equal? ((const/kw 1) 'arg) 1)
  (check-equal? ((const/kw 1) #:foo 'arg) 1)
  (check-equal? ((const/kw 1) 'arg #:foo 'arg) 1))

(define void/kw (const/kw (void)))

(module+ test
  (check-equal? (void/kw #:foo 'arg) (void)))
