#lang scribble/manual
@(require "util-doc.rkt")

@title{Basic Mock Construction}

@defproc[(mock? [v any/c]) boolean?]{
 Predicate identifying mocks.
 @mock-examples[
 (mock? (mock #:behavior void))
 (mock? void)]}

@defproc[(mock [#:behavior behavior procedure?
                (make-raise-unexpected-arguments-exn name)]
               [#:name name string? "mock"])
         mock?]{
 Returns a mock that records arguments its called with and results it returns.
 When called as a procedure, the returned @racket[mock?] forwards the arguments
 it's given to @racket[behavior] and records a @racket[mock-call] containing
 the arguments and result values in hidden mutable storage which can be queried
 later with @racket[mock-calls]. The mock's list of calls can be erased with
 @racket[mock-reset!], and it's behavior temporarily altered with
 @racket[with-mock-behavior]. If @racket[behavior] is not provided, the mock
 by default raises an error message in terms of @racket[name] whenever it's called.
 @mock-examples[
 (define quotient/remainder-mock
   (mock #:behavior quotient/remainder))
 (quotient/remainder-mock 10 3)
 (mock? quotient/remainder-mock)
 (define uncallable-mock (mock #:name "uncallable-mock"))
 (eval:error (uncallable-mock 1 2 3 #:foo 'bar #:bar "blah"))]}

@defproc[(mock-reset! [mock mock?]) void?]{
 Removes the history of procedure calls in @racket[mock].
 @mock-examples[
 (define m (mock #:behavior void))
 (m 'foo)
 (mock-num-calls m)
 (mock-reset! m)
 (mock-num-calls m)]}

@defform[(with-mock-behavior ([mock-expr behavior-expr] ...) body ...)
         #:contracts ([mock-expr mock?] [behavior-expr procedure?])]{
 Evaluates each @racket[mock-expr] and @racket[behavior-expr] which must
 be a @racket[mock?] and a @racket[procedure?], then alters the mock's
 behavior in the dynamic extent of @racket[(body ...)] to the given
 procedure. This allows the same mock to behave differently between
 calls, which is useful for testing a procedure defined with
 @racket[define/mock] in different ways for different tests.
 @mock-examples[
 (define a-mock (mock #:behavior add1))
 (a-mock 10)
 (with-mock-behavior ([a-mock sub1])
   (a-mock 10))
 (a-mock 10)
 (mock-calls a-mock)]}

@defstruct*[mock-call ([args arguments?] [results list?]) #:transparent]{
 A structure containg the arguments and result values of a single call
 to a @racket[mock?].}

@defproc[(mock-calls [mock mock?]) (listof mock-call?)]{
 Returns a list of all the @racket[mock-call]s made so far with @racket[mock],
 in order of when they were made.
 @mock-examples[
 (define a-mock (mock #:behavior void))
 (a-mock 10 3)
 (a-mock 'foo 'bar 'baz)
 (mock-calls a-mock)]}

@defproc[(mock-called-with? [mock mock?] [args arguments?])
         boolean?]{
 Returns @racket[#t] if @racket[mock] has ever been called with @racket[args],
 returns @racket[#f] otherwise.
 @mock-examples[
 (define ~a-mock (mock #:behavior ~a))
 (~a-mock 0 #:width 3 #:align 'left)
 (mock-called-with? ~a-mock (arguments 0 #:align 'left #:width 3))]}

@defproc[(mock-num-calls [mock mock?])
         exact-nonnegative-integer?]{
 Returns the number of times @racket[mock] has been
 called.
 @mock-examples[
 (define a-mock (mock #:behavior void))
 (a-mock 10 3)
 (a-mock 'foo 'bar 'baz)
 (mock-num-calls a-mock)]}
