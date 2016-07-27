#lang scribble/manual
@(require mock/private/util-doc
          scribble/example)
@(define (make-mock-eval)
   (make-base-eval #:lang 'racket/base
                   '(require mock mock/rackunit racket/format racket/function racket/file)))

@(define-syntax-rule (mock-rackunit-examples example ...)
   (examples #:eval (make-mock-eval) example ...))

@title{Mock RackUnit Checks}
@defmodule[mock/rackunit #:packages ("mock-rackunit")]

This package provides @racketmodname[rackunit] checks for working with @mock-tech{mocks}
from the @racketmodname[mock] library.

@defproc[(check-mock-called-with? [m mock?] [args arguments]) void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has
 been called with @racket[args].
 @mock-rackunit-examples[
 (define void-mock (mock #:behavior void))
 (check-mock-called-with? void-mock (arguments 'foo))
 (void-mock 'foo)
 (check-mock-called-with? void-mock (arguments 'foo))]}

@defproc[(check-mock-num-calls [m mock?] [n exact-positive-integer?]) void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has
 been called exactly @racket[n] times.
 @mock-rackunit-examples[
 (define void-mock (mock #:behavior void))
 (check-mock-num-calls void-mock 1)
 (void-mock 'foo)
 (check-mock-num-calls void-mock 1)]}
