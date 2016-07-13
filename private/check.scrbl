#lang scribble/manual

@(require "util-doc.rkt")

@title{RackUnit Checks for Mocks}

@defproc[(check-mock-called-with? [m mock?] [args arguments])
         void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has
 been called with @racket[args].
 @mock-examples[
 (define void-mock (mock #:behavior void))
 (check-mock-called-with? void-mock (arguments 'foo))
 (void-mock 'foo)
 (check-mock-called-with? void-mock (arguments 'foo))]}

@defproc[(check-mock-num-calls [n exact-positive-integer?] [m mock?])
         void?]{
 A @racketmodname[rackunit] check that passes if @racket[m] has
 been called exactly @racket[n] times.
 @mock-examples[
 (define void-mock (mock #:behavior void))
 (check-mock-num-calls 1 void-mock)
 (void-mock 'foo)
 (check-mock-num-calls 1 void-mock)]}
