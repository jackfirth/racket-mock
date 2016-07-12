#lang sweet-exp racket/base

require
  scribble/example
  for-label mock
            racket/base
            racket/contract
            rackunit

provide
  mock-examples
  for-label
    all-from-out mock
                 racket/base
                 racket/contract
                 rackunit

module+ test
  require rackunit
          "base.rkt"


(define (make-mock-eval)
  (make-base-eval #:lang 'racket/base '(require mock racket/format)))

(module+ test
  (define (mock-call-expr expected-result)
    `((mock #:behavior (λ () ,expected-result))))
  (check-equal? ((make-mock-eval) (mock-call-expr 10)) 10))

(define-syntax-rule (mock-examples example ...)
   (examples #:eval (make-mock-eval) example ...))
