#lang scribble/manual
@(require "util-doc.rkt")

@title{Mocking Out Functions for Testing}

@mock-tech{Mocks} by themselves provide useful low-level building blocks, but often
to use them a function needs to be implemented twice - once using mocks for the purpose
of testing, and once using real functions to provide actual functionality. The
@racketmodname[mock] library provides a shorthand syntax for defining both implementations
at once.

@defform[#:id define/mock
         (define/mock header mock-clause ... body ...)
         #:grammar ([header id (header arg ...) (header arg ... . rest)]
                    [mock-clause (code:line #:mock mock-id mock-as mock-default)]
                    [mock-as (code:line) (code:line #:as mock-as-id)]
                    [mock-default (code:line) (code:line #:with-behavior behavior-expr)])
         #:contracts ([behavior-expr procedure?])]{
 Like @racket[define] except two versions of @racket[id] are defined, a normal definition
 and a definition where each @racket[mock-id] is defined as a @mock-tech{mock} within
 @racket[body ...]. This alternate definition is used whenever @racket[id] is called within
 a @racket[(with-mocks id ...)] form. Each mock uses @racket[beavhior-expr] as its
 @behavior-tech{behavior} if provided, and is bound to @racket[mock-as-id] or
 @racket[mock-id] within @racket[(with-mocks id ...)] for use with checks like
 @racket[check-mock-called-with?]. The @racket[id] is bound as a rename transformer with
 @racket[define-syntax], but also includes information used by @racket[with-mocks] to bind
 @racket[id] and each @racket[mock-id] or @racket[mock-as-id].
 @mock-examples[
 (define/mock (foo)
   #:mock bar #:as bar-mock #:with-behavior (const "wow!")
   (bar))
 (define (bar) "bam!")
 (displayln (foo))
 (with-mocks foo
   (displayln (foo))
   (displayln (mock-calls bar-mock)))]}

@defform[(with-mocks proc/mocks-id body ...)]{
 Looks up static mocking information associated with @racket[proc/mocks-id], which must
 have been defined with @racket[define/mock], and binds a few identifiers within @racket[body ...].
 The identifier @racket[proc/mocks-id] is bound to a separate implementation that calls
 @mock-tech{mocks}, and any mocked procedures defined by @racket[proc/mocks-id] are bound
 to their mocks. See @racket[define/mock] for details and an example. The @racket[body ...]
 forms are in a new internal definition context surrounded in an enclosing @racket[let].}
