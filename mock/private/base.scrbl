#lang scribble/manual
@(require "util-doc.rkt")

@title{Core Mock API}

@defproc[(mock? [v any/c]) boolean?]{
 Predicate identifying @mock-tech{mocks}.
 @(mock-examples
   (mock? (mock #:behavior void))
   (mock? void))}

@defproc[(mock [#:behavior behavior-proc procedure? #f]
               [#:name name symbol? #f]
               [#:external-histories histories (listof call-history?) (list)])
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
 @(mock-examples
   (define quotient/remainder-mock
     (mock #:behavior quotient/remainder))
   (quotient/remainder-mock 10 3)
   (mock? quotient/remainder-mock)
   (define uncallable-mock (mock #:name 'uncallable-mock))
   (eval:error (uncallable-mock 1 2 3 #:foo 'bar #:bar "blah")))
 In addition to recording calls itself, the returned mock records calls in each
 of the given @racket[histories]. The call histories in @racket[histories] are
 not reset with @racket[call-history-reset!] when the returned mock is reset
 with @racket[mock-reset!]. External histories can be shared between mocks,
 allowing tests to verify the order in which a set of mocks is called.
 @(mock-examples
   (define h (call-history))
   (define m1 (mock #:name 'm1 #:behavior void #:external-histories (list h)))
   (define m2 (mock #:name 'm2 #:behavior void #:external-histories (list h)))
   (m1 'foo)
   (m2 'bar)
   (m1 'baz)
   (call-history h))}

@defproc[(mock-name [a-mock mock?]) (or/c symbol? #f)]{
 Returns the name of @racket[a-mock] if present.
 @(mock-examples
   (mock-name (mock #:name 'foo))
   (mock-name (mock)))
 @history[#:added "2.0"]}

@define-persistent-mock-examples[mock-name-examples]
@defproc[(current-mock-name) (or/c symbol? #f)]{
 Returns the name of the current @mock-tech{mock} being called. This is for use
 in @behavior-tech{behaviors}, for example to raise an error with a message in
 terms of the mock currently being called.
 @(mock-name-examples
   (define (log-call . vs)
     (printf "Mock ~a called with ~a args"
             (or (current-mock-name) 'anonymous)
             (length vs)))
   (define log-mock (mock #:name 'log-mock #:behavior log-call))
   (log-mock 1 2 3)
   (log-mock 'foo 'bar))

 If called outside the context of a mock behavior call, raises @racket[exn:fail].
 @(mock-name-examples
   (eval:error (current-mock-name)))

 If the mock being called is anonymous, returns @racket[#f].
 @(mock-name-examples
   (define log-mock-anon (mock #:behavior log-call))
   (log-mock-anon 1 2 3)
   (log-mock-anon 'foo 'bar))
 @history[#:added "1.1"]}

@defproc[(current-mock-calls) (listof mock-call?)]{
 Returns a list of all the previous calls of the current @mock-tech{mock} being
 called. This is for use in @behavior-tech{behaviors}, for example to implement
 a behavior that returns a set of all keywords its ever been called with.
 @(mock-examples
   (define keyword-set
     (make-keyword-procedure
      (λ (kws _)
        (define (call-kws call)
          (hash-keys (arguments-keyword (mock-call-args call))))
        (define prev-kws
          (append-map call-kws (current-mock-calls)))
        (apply set (append kws prev-kws)))))
   (define kw-set-mock (mock #:behavior keyword-set))
   (kw-set-mock #:foo 'bar)
   (kw-set-mock #:baz "blah"))

 If called outside the context of a mock behavior call, raises @racket[exn:fail].
 @(mock-examples
   (eval:error (current-mock-calls)))
 @history[#:added "1.2"]}

@defproc[(current-mock-num-calls) exact-nonnegative-integer?]{
 Returns the number of times the current @mock-tech{mock} being called has already
 been called. This is for use in @behavior-tech{beahviors}, for example to log the
 number of times this mock has been called.
 @(mock-examples
   (define (log-count)
     (printf "Mock called ~a times previously" (current-mock-num-calls)))
   (define count-mock (mock #:behavior log-count))
   (count-mock)
   (count-mock)
   (mock-reset! count-mock)
   (count-mock))

 If called outside the context of a mock behavior call, raises @racket[exn:fail].
 @(mock-examples
   (eval:error (current-mock-num-calls)))
 @history[#:added "1.3"]}

@defproc[(mock-reset! [m mock?]) void?]{
 Erases the history of @racket[mock-call] values in @racket[m].
 @(mock-examples
   (define void-mock (mock #:behavior void))
   (void-mock 'foo)
   (mock-num-calls void-mock)
   (mock-reset! void-mock)
   (mock-num-calls void-mock))}

@defform[(with-mock-behavior ([mock-expr behavior-expr] ...) body ...)
         #:contracts ([mock-expr mock?] [behavior-expr procedure?])]{
 Evaluates each @racket[mock-expr] and @racket[behavior-expr] which must
 be a @mock-tech{mock} and a @racket[procedure?] respectively, then alters
 the mock's @behavior-tech{behavior} in the dynamic extent of
 @racket[body ...] to the given behavior procedure. This allows the
 same mock to behave differently between calls, which is useful for
 testing a procedure defined with @racket[define/mock] in different ways
 for different tests.
 @(mock-examples
   (define num-mock (mock #:behavior add1))
   (num-mock 10)
   (with-mock-behavior ([num-mock sub1])
     (num-mock 10))
   (num-mock 10)
   (mock-calls num-mock))}

@deftogether[
 (@defproc[(mock-call [#:name name (or/c symbol? #f) #f]
                      [#:args args arguments? (arguments)]
                      [#:results results list? (list)])
           mock-call?]
   @defproc[(mock-call? [v any/c]) boolean?]
   @defproc[(mock-call-args [call mock-call?]) arguments?]
   @defproc[(mock-call-results [call mock-call?]) list?])]{
 Constructor, predicate, and accessors of a structure containing the
 @args-tech{arguments} and result values of a single call to a @mock-tech{mock}
 with name @racket[name].
 @(mock-examples
   (mock-call #:name 'magnificent-mock
              #:args (arguments 1 2 #:foo 'bar)
              #:results (list 'value 'another-value)))
 @history[#:changed "2.0" @elem{Changed from a plain struct to a keyword-based
            constructor and added a name field.}]}

@defproc[(mock-calls [m mock?]) (listof mock-call?)]{
 Returns a list of all the calls made so far with @racket[m] in order, as
 a list of @racket[mock-call?] structs.
 @(mock-examples
   (define void-mock (mock #:behavior void))
   (void-mock 10 3)
   (void-mock 'foo 'bar 'baz)
   (mock-calls void-mock))}

@defproc[(mock-called-with? [m mock?] [args arguments?]) boolean?]{
 Returns @racket[#t] if @racket[m] has ever been called with @racket[args],
 returns @racket[#f] otherwise.
 @(mock-examples
   (define ~a-mock (mock #:behavior ~a))
   (~a-mock 0 #:width 3 #:align 'left)
   (mock-called-with? ~a-mock (arguments 0 #:align 'left #:width 3)))}

@defproc[(mock-num-calls [m mock?]) exact-nonnegative-integer?]{
 Returns the number of times @racket[m] has been called.
 @(mock-examples
   (define void-mock (mock #:behavior void))
   (void-mock 10 3)
   (void-mock 'foo 'bar 'baz)
   (mock-num-calls void-mock))}
