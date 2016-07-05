#lang scribble/manual
@(require "util/doc.rkt")

@title{Mocking Out Functions for Testing}

Mocks by themselves provide useful low-level building blocks, but often to use
them a function needs to be implemented twice - once using mocks for the purpose
of testing, and once using real functions to provide actual functionality. The
@racket[mock] library provides a shorthand syntax for defining both implementations
at once.

@defform[#:id define/mock
         (define/mock header submod-clause mock-clause ... body ...)
         #:grammar ([header id (header arg ...) (header arg ... . rest)]
                    [submod-clause (code:line)
                     (code:line #:in-submod submod-id)]
                    [mock-clause (code:line)
                     (code:line #:mock mock-id mock-as mock-default)]
                    [mock-as (code:line)
                     (code:line #:as mock-as-id)]
                    [mock-default (code:line)
                     (code:line #:with-default mock-expr)])
         #:contracts ([mock-expr mock?])]{
 Like @racket[define], except in @racket[submod-id] which defaults to @racket[test].
 In that submodule, a different implementation is defined which uses mocks for each
 @racket[mock-id]. Each mock uses @racket[mock-expr] or @racket[(void-mock)] if none
 is provided, and is bound to @racket[mock-as-id] or @racket[mock-id] in the mocking
 submodule. This allows code in the mocking submodule to use the mocks with testing
 procedures such as @racket[check-mock-called-with?]. This form can only be used at
 the module level, as its expansion produces code in a submodule.
 @mock-examples[
 (module m racket
   (require mock)
   (define/mock (my-displayln v)
     #:mock displayln
     (displayln v))
   (my-displayln "sent to real displayln")
   (mock? my-displayln)
   (module+ test
     (my-displayln "sent to mock displayln")
     (mock? my-displayln)))
 (require 'm)
 (require (submod 'm test))]
 The above example relies on default behavior. It is equivalent to the following:
 @mock-examples[
 (module m racket
   (require mock)
   (define/mock (my-displayln v)
     #:in-submod test
     #:mock displayln #:as displayln #:with-default (void-mock)
     (displayln v))
   (my-displayln "sent to real displayln")
   (mock? my-displayln)
   (module+ test
     (my-displayln "sent to mock displayln")
     (mock? my-displayln)))
 (require 'm)
 (require (submod 'm test))]}
