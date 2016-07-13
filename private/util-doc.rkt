#lang sweet-exp racket/base

provide
  args-tech
  behavior-tech
  define-args-tech
  define-behavior-tech
  define-mock-tech
  mock-examples
  mock-tech
  for-label
    all-from-out mock
                 racket/base
                 racket/contract
                 rackunit

require
  scribble/example
  scribble/manual
  for-label mock
            racket/base
            racket/contract
            rackunit

(define (mock-tech . pre-flow)
  (apply tech #:key "mock" pre-flow))

(define (behavior-tech . pre-flow)
  (apply tech #:key "behavior" pre-flow))

(define (args-tech . pre-flow)
  (apply tech #:key "arguments struct" pre-flow))

(define (define-mock-tech . pre-flow)
  (apply deftech #:key "mock" pre-flow))

(define (define-behavior-tech . pre-flow)
  (apply deftech #:key "behavior" pre-flow))

(define (define-args-tech . pre-flow)
  (apply deftech #:key "arguments struct" pre-flow))

(define (make-mock-eval)
  (make-base-eval #:lang 'racket/base '(require mock racket/format)))

(define-syntax-rule (mock-examples example ...)
   (examples #:eval (make-mock-eval) example ...))
