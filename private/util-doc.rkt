#lang sweet-exp racket/base

provide
  args-tech
  behavior-tech
  define-args-tech
  define-behavior-tech
  define-mock-tech
  define-stub-tech
  mock-examples
  mock-tech
  stub-tech
  for-label
    all-from-out mock
                 mock/rackunit
                 racket/base
                 racket/contract
                 rackunit

require
  scribble/example
  scribble/manual
  syntax/parse/define
  for-label mock
            mock/rackunit
            racket/base
            racket/contract
            rackunit

(define-simple-macro (define-techs [key:str use-id:id def-id:id] ...)
  (begin
    (begin
      (define (def-id . pre-flow) (apply deftech #:key key pre-flow))
      (define (use-id . pre-flow) (apply tech #:key key pre-flow)))
    ...))

(define-techs
  ["mock" mock-tech define-mock-tech]
  ["behavior" behavior-tech define-behavior-tech]
  ["arguments struct" args-tech define-args-tech]
  ["stub" stub-tech define-stub-tech])

(define (make-mock-eval)
  (make-base-eval #:lang 'racket/base
                  '(require mock mock/rackunit racket/format racket/function)))

(define-syntax-rule (mock-examples example ...)
   (examples #:eval (make-mock-eval) example ...))
