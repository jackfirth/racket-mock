#lang scribble/manual
@(require "util-doc.rkt")

@title{Mocking Dependencies}

@mock-tech{Mocks} by themselves provide useful low-level building blocks, but often
to use them a function needs to be implemented twice - once using mocks for the purpose
of testing, and once using real functions to provide actual functionality. The
@racketmodname[mock] library provides a shorthand syntax for defining both implementations
at once.

@defform[
 #:id define/mock
 (define/mock header
   opaque-clause history-clause
   mock-clause ...
   body ...)
 #:grammar ([header id (header arg ...) (header arg ... . rest)]
            [opaque-clause (code:line)
             (code:line #:opaque opaque-id:id)
             (code:line #:opaque (opaque-id:id ...))]
            [history-clause (code:line)
             (code:line #:history history-id:id)]
            [mock-clause (code:line #:mock mock-id mock-as mock-default)
             (code:line #:mock-param param-id mock-as mock-default)]
            [mock-as (code:line) (code:line #:as mock-as-id)]
            [mock-default (code:line) (code:line #:with-behavior behavior-expr)])
 #:contracts ([behavior-expr procedure?])]{
 Like @racket[define] except two versions of @racket[id] are defined, a normal
 definition and a definition where each @racket[mock-id] is defined as a
 @mock-tech{mock} within @racket[body ...]. This alternate definition is used
 whenever @racket[id] is called within a @racket[(with-mocks id ...)] form. Each
 mock uses @racket[beavhior-expr] as its @behavior-tech{behavior} if provided,
 and is bound to @racket[mock-as-id] or @racket[mock-id] within
 @racket[(with-mocks id ...)] for use with checks like
 @racket[check-mock-called-with?]. Each @racket[opaque-id] is defined as an
 @opaque-tech{opaque-value} using @racket[define-opaque], and each
 @racket[behavior-expr] may refer to any @racket[opaque-id]. If provided,
 @racket[history-id] is bound as a @racket[call-history] and each mock uses
 @racket[history-id] as an external call history. The @racket[id] is bound as a
 rename transformer with @racket[define-syntax], but also includes information
 used by @racket[with-mocks] to bind @racket[id], each @racket[mock-id] or
 @racket[mock-as-id], and each @racket[opaque-id].
 @(mock-examples
   (define/mock (foo)
     #:mock bar #:as bar-mock #:with-behavior (const "wow!")
     (bar))
   (define (bar) "bam!")
   (displayln (foo))
   (with-mocks foo
     (displayln (foo))
     (displayln (mock-calls bar-mock))))
 
 Opaque values are bound and available in both @racket[with-mocks] forms and mock
 behavior expressions, and can be used to represent difficult to construct values like
 database connections.
 @(mock-examples
   (define/mock (foo/opaque)
     #:opaque special
     #:mock bar #:as bar-mock #:with-behavior (const special)
     (bar))
   (define (bar) "bam!")
   (eval:error special)
   (foo/opaque)
   (with-mocks foo/opaque
     (displayln special)
     (displayln (special? (foo/opaque)))))
 
 If @racket[#:as mock-as] is not provided, @racket[mock-id] is used instead. This means
 @racket[with-mocks] forms cannot reference both the mock and the mocked dependency
 simultaneously.
 @(mock-examples
   (define/mock (foo/default-binding)
     #:mock bar #:with-behavior (const "wow!")
     (bar))
   (define (bar) "bam!")
   (foo/default-binding)
   (with-mocks foo/default-binding
     (displayln (foo/default-binding))
     ;; no way to refer to real bar in here
     (displayln (mock-calls bar))))
 
 If @racket[#:with-behavior behavior-expr] is not provided, the default behavior of
 @racket[mock] is used. If a @racket[with-mocks] form expects the mock to be called,
 @racket[with-mock-behavior] must also be used within the @racket[with-mocks] form to
 setup the correct mock behavior.
 @(mock-examples
   (define/mock (foo/no-behavior)
     #:mock bar
     (bar))
   (define (bar) "bam!")
   (foo/no-behavior)
   (eval:error
    (with-mocks foo/no-behavior
      (foo/no-behavior))))

 Parameters can be mocked by using the @racket[#:mock-param] form of
 @racket[mock-clause] instead of @racket[#:mock]. When a parameter is mocked,
 the parameter is expected to contain a procedure and will be parameterized to
 a mock when the defined procedure is called within the @racket[with-mocks]
 form. If @racket[#:as mock-as-id] is provided, the mock used in the parameter
 is bound to @racket[mock-as-id]; otherwise it is available by calling the
 parameter.
 @(mock-examples
   (define current-bar (make-parameter (const "bam!")))
   (define (bar) ((current-bar)))
   (define/mock (foo/param)
     #:mock-param current-bar #:with-behavior (const "wow!")
     (bar))
   (eval:check (foo/param) "bam!")
   (with-mocks foo/param
     (displayln (foo/param))))
 @history[#:changed "2.0" "Added #:call-history option"]
 @history[#:changed "2.1" "Added #:mock-param option"]}

@defform[(with-mocks proc/mocks-id body ...)]{
 Looks up static mocking information associated with @racket[proc/mocks-id], which must
 have been defined with @racket[define/mock], and binds a few identifiers within @racket[body ...].
 The identifier @racket[proc/mocks-id] is bound to a separate implementation that calls
 @mock-tech{mocks}, and any mocked procedures defined by @racket[proc/mocks-id] are bound
 to their mocks. See @racket[define/mock] for details and an example. The @racket[body ...]
 forms are in a new internal definition context surrounded by an enclosing @racket[let].}
