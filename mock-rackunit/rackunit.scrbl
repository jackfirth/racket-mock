#lang scribble/manual
@(require (for-label mock/rackunit)
          mock/private/util-doc
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

@defproc[(check-mock-calls [m mock] [args-list (listof arguments)]) void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has been called with each
 @racket[args] in their given order and no other times.
 @(mock-rackunit-examples
   (define void-mock (mock #:behavior void))
   (void-mock 1)
   (void-mock 'foo)
   (check-mock-calls void-mock (list (arguments 1)))
   (check-mock-calls void-mock (list (arguments 1) (arguments 'foo)))
   (check-mock-calls void-mock (list (arguments 'foo) (arguments 1)))
   (check-mock-calls
    void-mock (list (arguments 1) (arguments 'foo) (arguments #:bar "baz"))))}

@defproc[(check-mock-called-with? [m mock?] [args arguments]) void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has
 been called with @racket[args].
 @(mock-rackunit-examples
   (define void-mock (mock #:behavior void))
   (check-mock-called-with? void-mock (arguments 'foo))
   (void-mock 'foo)
   (check-mock-called-with? void-mock (arguments 'foo)))}

@defproc[(check-mock-num-calls [m mock?] [n exact-positive-integer?]) void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has
 been called exactly @racket[n] times.
 @(mock-rackunit-examples
   (define void-mock (mock #:behavior void))
   (check-mock-num-calls void-mock 1)
   (void-mock 'foo)
   (check-mock-num-calls void-mock 1))}

@defproc[(check-call-history-names [h call-history?] [names (listof symbol?)])
         void?]{
 A @racketmodname[rackunit] check that passes if @racket[h] contains a history
 of calls by mocks with @racket[names].
 @(mock-rackunit-examples
   (define h (call-history))
   (define m1 (mock #:name 'm1 #:behavior void #:external-histories (list h)))
   (define m2 (mock #:name 'm2 #:behavior void #:external-histories (list h)))
   (m1 'foo)
   (m2 'bar)
   (check-call-history-names h (list 'm1 'm2))
   (m1 'baz)
   (check-call-history-names h (list 'm1 'm2)))}
