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

(define (make-mock-eval)
  (make-base-eval #:lang 'racket/base '(require mock racket/format)))

(define-syntax-rule (mock-examples example ...)
   (examples #:eval (make-mock-eval) example ...))
