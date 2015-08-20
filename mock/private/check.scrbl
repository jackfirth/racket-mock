#lang scribble/manual

@(require "util/doc.rkt")

@title{RackUnit Checks for Mocks}

@defproc[(check-mock-called-with? [args list?] [mock mock?])
         void?]{
  A @racketmodname[rackunit] check that fails if @racket[mock]
  has never been called with @racket[args].
  @mock-examples[
    (check-mock-called-with? '(some args) (void-mock))
]}

@defproc[(check-mock-num-calls [n exact-positive-integer?] [mock mock?])
         void?]{
  A @racketmodname[rackunit] check that fails if @racket[mock]
  hasn't been called exactly @racket[n] times.
  @mock-examples[
    (check-mock-num-calls 1 (void-mock))
]}
