#lang scribble/manual

@(require "util/doc.rkt")

@title{RackUnit Checks for Mocks}

@defproc[(check-mock-called-with? [mock mock?]
                                  [args list?]
                                  [kwargs (hash/c keyword? any/c)])
         void?]{
 A @racketmodname[rackunit] check that fails if @racket[mock]
 has never been called with @racket[args] and @racket[kwargs].
 @mock-examples[
 (define mock (make-mock void))
 (check-mock-called-with? mock (arguments 'foo))
 (mock 'foo)
 (check-mock-called-with? mock (arguments 'foo))]}

@defproc[(check-mock-num-calls [n exact-positive-integer?] [mock mock?])
         void?]{
 A @racketmodname[rackunit] check that fails if @racket[mock]
 hasn't been called exactly @racket[n] times.
 @mock-examples[
 (define mock (make-mock void))
 (check-mock-num-calls 1 mock)
 (mock 'foo)
 (check-mock-num-calls 1 mock)]}
