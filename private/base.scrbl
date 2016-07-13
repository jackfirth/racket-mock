#lang scribble/manual
@(require "util-doc.rkt")

@title{Basic Mock Construction}

@defproc[(mock? [v any/c]) boolean?]{
 Predicate identifying @mock-tech{mocks}.
 @mock-examples[
 (mock? (mock #:behavior void))
 (mock? void)]}

@defproc[(mock [#:behavior behavior-proc procedure? #f]
               [#:name name symbol? 'mock])
         mock?]{
 Returns a @mock-tech{mock} that records arguments its called with and results
 it returns. When called as a procedure, the mock consults its current
 @define-behavior-tech{behavior}, a procedure initalized to @racket[behavior-proc]
 that defines how the mock responds to arguments, and stores a @racket[mock-call]
 containing the give arguments and the result values of the behavior. The mock's
 list of calls can be queried with @racket[mock-calls] and erased with
 @racket[mock-reset!]. The mock's behavior can be temporarily altered using
 @racket[with-mock-behavior]. If @racket[behavior] is not provided, the mock by
 default raises an @racket[exn:fail:unexpected-arguments] with a message in terms
 of @racket[name].
 @mock-examples[
 (define quotient/remainder-mock
   (mock #:behavior quotient/remainder))
 (quotient/remainder-mock 10 3)
 (mock? quotient/remainder-mock)
 (define uncallable-mock (mock #:name 'uncallable-mock))
 (eval:error (uncallable-mock 1 2 3 #:foo 'bar #:bar "blah"))]}

@defproc[(mock-reset! [m mock?]) void?]{
 Erases the history of @racket[mock-call] values in @racket[m].
 @mock-examples[
 (define void-mock (mock #:behavior void))
 (void-mock 'foo)
 (mock-num-calls void-mock)
 (mock-reset! void-mock)
 (mock-num-calls void-mock)]}

@defform[(with-mock-behavior ([mock-expr behavior-expr] ...) body ...)
         #:contracts ([mock-expr mock?] [behavior-expr procedure?])]{
 Evaluates each @racket[mock-expr] and @racket[behavior-expr] which must
 be a @mock-tech{mock} and a @racket[procedure?] respectively, then alters
 the mock's @behavior-tech{behavior} in the dynamic extent of
 @racket[body ...] to the given behavior procedure. This allows the
 same mock to behave differently between calls, which is useful for
 testing a procedure defined with @racket[define/mock] in different ways
 for different tests.
 @mock-examples[
 (define num-mock (mock #:behavior add1))
 (num-mock 10)
 (with-mock-behavior ([num-mock sub1])
   (num-mock 10))
 (num-mock 10)
 (mock-calls num-mock)]}

@defstruct*[mock-call ([args arguments?] [results list?]) #:transparent]{
 A structure containg the @args-tech{arguments} and result values of a
 single call to a @mock-tech{mock}.
 @mock-examples[
 (mock-call (arguments 1 2 #:foo 'bar)
            (list 'value 'another-value))]}

@defproc[(mock-calls [m mock?]) (listof mock-call?)]{
 Returns a list of all the calls made so far with @racket[m] in order, as
 a list of @racket[mock-call?] structs.
 @mock-examples[
 (define void-mock (mock #:behavior void))
 (void-mock 10 3)
 (void-mock 'foo 'bar 'baz)
 (mock-calls void-mock)]}

@defproc[(mock-called-with? [m mock?] [args arguments?]) boolean?]{
 Returns @racket[#t] if @racket[m] has ever been called with @racket[args],
 returns @racket[#f] otherwise.
 @mock-examples[
 (define ~a-mock (mock #:behavior ~a))
 (~a-mock 0 #:width 3 #:align 'left)
 (mock-called-with? ~a-mock (arguments 0 #:align 'left #:width 3))]}

@defproc[(mock-num-calls [m mock?]) exact-nonnegative-integer?]{
 Returns the number of times @racket[m] has been called.
 @mock-examples[
 (define void-mock (mock #:behavior void))
 (void-mock 10 3)
 (void-mock 'foo 'bar 'baz)
 (mock-num-calls void-mock)]}