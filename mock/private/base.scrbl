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
 (define quotient/remainder-mock (make-mock quotient/remainder))
 (quotient/remainder-mock 10 3)
 (mock? quotient/remainder-mock)
 ]}

@defform[(with-mock-behavior ([mock-expr proc-expr] ...) body ...)
         #:contracts ([mock-expr mock?] [proc-expr procedure?])]{
 Evaluates each @racket[mock-expr] and @racket[proc-expr] which must
 be a @racket[mock?] and a @racket[procedure?], then alters the mock's
 behavior in the dynamic extent of @racket[(body ...)] to the given
 procedure. This allows the same mock to behave differently between
 calls, which is useful for @racket[define/mock].
 @mock-examples[
 (define a-mock (make-mock add1))
 (a-mock 10)
 (with-mock-behavior ([a-mock sub1])
   (a-mock 10))
 (a-mock 10)
 (mock-calls a-mock)]}

@defstruct*[mock-call ([args list?] [kwargs (hash/c keyword? any/c)] [results list?]) #:transparent]{
 A structure containg the arguments and result
 values of a single call to a @racket[mock?].
}

@defproc[(mock-calls [mock mock?]) (listof mock-call?)]{
 Returns a list of all the @racket[mock-call]s made
 so far with @racket[mock], in order of when they were made.
 @mock-examples[
 (define displayln-mock (make-mock displayln))
 (mock-calls displayln-mock)
 (displayln-mock "foo")
 (mock-calls displayln-mock)
 (define quotient/remainder-mock (make-mock quotient/remainder))
 (quotient/remainder-mock 10 3)
 (quotient/remainder-mock 3 2)
 (mock-calls quotient/remainder-mock)
 ]}

@defproc[(mock-called-with? [mock mock?] [args list?] [kwargs (hash/c keyword? any/c)])
         boolean?]{
 Returns @racket[#t] if @racket[mock] has ever been
 called with positional arguments that are @racket[equal?] to
 @racket[args] and keyword arguments that are @racket[equal?]
 to @racket[kwargs], returns @racket[#f] otherwise.
 @mock-examples[
 (define ~a-mock (make-mock ~a))
 (~a-mock 0 #:width 3 #:align 'left)
 (mock-called-with? ~a-mock '(0) (hash '#:align 'left '#:width 3))]}

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
