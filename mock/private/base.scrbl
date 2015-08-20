#lang scribble/manual

@(require "util/doc.rkt")

@title{Basic Mock Construction}

@defproc[(mock? [v any/c]) boolean?]{
  Predicate identifying mocks.
  @mock-examples[
    (mock? (make-mock void))
    (mock? void?)
]}

@defproc[(make-mock [proc procedure?]) mock?]{
  Returns a mocked version of @racket[proc]. The
  mock may be used in place of @racket[proc] anywhere
  and behaves just like @racket[proc]. When used
  as a procedure, the returned @racket[mock?] forwards
  the arguments it's given to @racket[proc] and records
  the argument list and the result @racket[proc] returned
  in hidden mutable storage. This allows tests to verify
  that a mock was called with the right arguments.
  @mock-examples[
    (define displayln-mock (make-mock displayln))
    (displayln-mock "foo")
    (mock? displayln-mock)
]}

@defstruct*[mock-call ([args list?] [result any/c])
            #:prefab]{
  A prefab structure containg the arguments and result
  of a single call to a @racket[mock?].
}

@defproc[(mock-calls [mock mock?]) (listof mock-call?)]{
  Returns a list of all the @racket[mock-call]s made
  so far with @racket[mock].
  @mock-examples[
    (define displayln-mock (make-mock displayln))
    (mock-calls displayln-mock)
    (displayln-mock "foo")
    (mock-calls displayln-mock)
]}

@defproc[(mock-called-with? [args list?] [mock mock?])
         boolean?]{
  Returns @racket[#t] if @racket[mock] has ever been
  called with arguments that are @racket[equal?] to
  @racket[args], returns @racket[#f] otherwise.
  @mock-examples[
    (define displayln-mock (make-mock displayln))
    (mock-called-with? '("foo") displayln-mock)
    (displayln-mock "foo")
    (mock-called-with? '("foo") displayln-mock)
]}

@defproc[(mock-num-calls [mock mock?])
         exact-nonnegative-integer?]{
  Returns the number of times @racket[mock] has been
  called.
  @mock-examples[
    (define displayln-mock (make-mock displayln))
    (mock-num-calls displayln-mock)
    (displayln-mock "foo")
    (mock-num-calls displayln-mock)
]}
