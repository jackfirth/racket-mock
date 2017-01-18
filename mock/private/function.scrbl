#lang scribble/manual
@(require "util-doc.rkt")

@title{Behavior Construction Utilities}

@defproc[(const/kw [v any/c]) procedure?]{
 Like @racket[const], but the returned procedure accepts keyword arguments.
 @(mock-examples
   ((const/kw 'a) 1)
   ((const/kw 'a) #:foo 2))}

@defthing[void/kw (unconstrained-domain-> void?)]{
 Like @racket[void], but accepts keyword arguments.
 @(mock-examples
   (void/kw 1)
   (void/kw #:foo 2))}

@defproc[(const-raise [v any/c]) procedure?]{
 Like @racket[const/kw], but instead of returning @racket[v] the returned
 procedure always @racket[raise]s @racket[v] whenever it's called.
 @(mock-examples
   (eval:error ((const-raise 'a) 1))
   (eval:error ((const-raise 'a) #:foo 2)))}

@defproc[(const-raise-exn
          [#:message msg string? "failure"]
          [#:constructor ctor
           (-> string? continuation-mark-set? any/c) make-exn:fail?])
         procedure?]{
 Like @racket[const-raise], but designed for raising exceptions. More precisely,
 the returned procedure raises the result of
 @racket[(ctor msg (current-continuation-marks))] whenever it's called.
 @(mock-examples
   (eval:error ((const-raise-exn) 1))
   (eval:error ((const-raise-exn "some other failure") #:foo 2))
   (struct exn:fail:custom exn:fail () #:transparent)
   (eval:error ((const-raise-exn #:constructor exn:fail:custom) #:bar 3)))}

@defproc[(const-series [v any/c] ... [#:reset? reset? boolean? #f]) procedure?]{
 Returns a procedure that ignores positional and keyword arguments and returns
 the first @racket[v] when called for the first time, the second @racket[v] when
 called for the second time, the third on the third time, and so on until no
 more @racket[v]s remain. Then, calls cause the procedure to fail with an
 exception if @racket[reset?] is false. Otherwise, the pattern resets.
 @(mock-examples
   (define ab-proc (const-series 'a 'b))
   (eval:check (ab-proc 1) 'a)
   (eval:check (ab-proc #:foo 2) 'b)
   (eval:error (ab-proc #:bar 3))
   (define ab-proc (const-series 'a 'b #:repeat? #t))
   (eval:check (ab-proc) 'a)
   (eval:check (ab-proc) 'b)
   (eval:check (ab-proc) 'a))}
