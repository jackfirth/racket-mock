#lang scribble/manual
@(require "util-doc.rkt")

@title{Writing Stub Implementations}
@mock-tech{Mocks} and @racket[define/mock] make it possible to test procedures
before the procedures they call have been implemented. However, if the procedures
called haven't been defined, a compilation error will occur despite the fact
that they're not used in test. To assist with this, the @racketmodname[mock]
library provides syntax for defining @define-stub-tech{stubs}, procedures that
haven't been implemented and throw immediately when called. The term "stub" is
used in different ways by different languages and libraries, but that is the
definition used by this library.

@defform[(stub header ...)
         #:grammar ([header id (header arg ...) (header arg ... . rest)])]{
 Defines each @racket[header] as a @stub-tech{stub} procedure that immediately
 throws a @racket[exn:fail:not-implemented]. If @racket[header] is only an
 identifier, the procedure accepts any positional and keyword arguments.
 Otherwise, it accepts exactly the arguments specified in @racket[header].
 @mock-examples[
 (stub foo (bar v) ((baz k) #:blah v))
 (eval:error (foo 1 2 #:a 'b))
 (eval:error (bar 1))
 (eval:error (bar 1 2))
 (baz 1)
 (eval:error ((baz 1) #:blah "blahhhh"))]}

@defstruct*[(exn:fail:not-implemented exn:fail) () #:transparent]{
 An exception type thrown by @stub-tech{stubs} whenever they're called.}
