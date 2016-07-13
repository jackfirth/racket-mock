#lang scribble/manual
@(require "util-doc.rkt")

@title{Mocking Out Functions for Testing}

@mock-tech{Mocks} by themselves provide useful low-level building blocks, but often
to use them a function needs to be implemented twice - once using mocks for the purpose
of testing, and once using real functions to provide actual functionality. The
@racketmodname[mock] library provides a shorthand syntax for defining both implementations
at once.

@defform[#:id define/mock
         (define/mock header submod-clause mock-clause ... body ...)
         #:grammar ([header id (header arg ...) (header arg ... . rest)]
                    [submod-clause (code:line)
                     (code:line #:in-submod submod-id)]
                    [mock-clause (code:line #:mock mock-id mock-as mock-default)]
                    [mock-as (code:line)
                     (code:line #:as mock-as-id)]
                    [mock-default (code:line)
                     (code:line #:with-behavior behavior-expr)])
         #:contracts ([behavior-expr procedure?])]{
 Like @racket[define], except in @racket[submod-id] which defaults to @racket[test].
 In that submodule, a different implementation is defined which uses @mock-tech{mocks}
 for each @racket[mock-id]. Each mock uses @racket[beavhior-expr] as its
 @behavior-tech{behavior} if provided, and is bound to @racket[mock-as-id] or
 @racket[mock-id] in the mocking submodule. This allows code in the mocking submodule
 to use the mocks with testing procedures such as @racket[check-mock-called-with?].
 This form can only be used at the module level, as its expansion produces code in a
 submodule.
 @mock-examples[
 (module m racket
   (require mock)
   (define/mock (foo)
     #:in-submod foo-test
     #:mock bar #:as bar-mock #:with-behavior (const "wow!")
     (bar))
   (define (bar) "bam!")
   (foo)
   (module+ foo-test
     (foo)
     (mock-calls bar-mock)))
 (require 'm)
 (require (submod 'm foo-test))]}
