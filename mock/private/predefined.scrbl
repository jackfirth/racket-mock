#lang scribble/manual

@(require "util/doc.rkt")

@title{Mock Constructors}

@defproc[(void-mock) mock?]{
  Constructs a mock that acts like @racket[void]. Useful
  for mocking procedures called only for their side effects
  like @racket[display].
  @mock-examples[
    (define a-void-mock (void-mock))
    (a-void-mock)
    (a-void-mock 1 2 3)
    (mock-num-calls a-void-mock)
]}

@defproc[(const-mock [v any/c]) mock?]{
  Constructs a mock that acts like @racket[(const v)].
  Useful for making an IO reading operation return a
  test-defined value without actually doing any IO.
  @mock-examples[
    (define foo-mock (const-mock 'foo))
    (foo-mock 'bar)
]}

@defproc[(case-mock [case-v any/c] [case-result any/c] ... ...)
         mock?]{
  Constructs a mock that accepts a single value and
  compares it to each @racket[case-v] with @racket[equal?],
  then returns the corresponding @racket[case-result] for
  the first @racket[case-v] that is @racket[equal?] to
  the given value. If no @racket[case-v] matches, an
  exception is thrown.
  @mock-examples[
    (define foo-bar-mock (case-mock 'foo 1 'bar 2))
    (foo-bar-mock 'foo)
    (foo-bar-mock 'bar)
    (eval:error (foo-bar-mock 'unexpected))
]}
