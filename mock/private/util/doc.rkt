#lang sweet-exp racket/base

require
  scribble/eval
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


(define-syntax-rule (define-examples-form id require-spec ...)
  (begin
    (define (eval-factory)
      (define base-eval (make-base-eval))
      (base-eval '(require require-spec)) ...
      base-eval)
    (define-syntax-rule (id datum (... ...))
      (examples #:eval (eval-factory) datum (... ...)))))


(define-examples-form mock-examples mock)
