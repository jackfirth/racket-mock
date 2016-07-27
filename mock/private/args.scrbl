#lang scribble/manual
@(require "util-doc.rkt")

@title{Arguments Structures}
@mock-tech{Mocks} record procedure calls partly via an @define-args-tech{arguments structure},
a value containing a set of positional and keyword argument values. Various utility procedures
for constructing and manipulating these structures are provided by @racketmodname[mock].

@deftogether[
 (@defthing[#:kind "value" arguments? predicate/c]
  @defproc[(arguments-positional [arguments arguments?]) list?]
  @defproc[(arguments-keyword [arguments arguments?]) keyword-hash?])]{
 Predicate and accessors for @args-tech{arguments structures}.}

@defproc[(make-arguments [positional list?] [keyword keyword-hash?]) arguments?]{
 Returns an @args-tech{arguments structure} with @racket[positional] and
 @racket[keyword] as its arguments.
 @mock-examples[
 (make-arguments '(1 2 3) (hash '#:foo "bar"))]}

@defthing[#:kind "procedure" arguments (unconstrained-domain-> arguments?)]{
 Returns all arguments given, in the form of an @args-tech{arguments structure}. Accepts
 both positional and keyword arguments.
 @mock-examples[
 (arguments 1 2 3 #:foo "bar")]}

@defthing[#:kind "value" keyword-hash? flat-contract?]{
 A flat contract that recognizes immutable hashes whose keys are keywords. Equivalent
 to @racket[(hash/c keyword? any/c #:flat? #t #:immutable #t)]. Used for the keyword
 arguments of an @args-tech{arguments structure}.
 @mock-examples[
 (keyword-hash? (hash '#:foo "bar"))
 (keyword-hash? (make-hash '((#:foo . "bar"))))
 (keyword-hash? (hash 'foo "bar"))]}

@defstruct*[(exn:fail:unexpected-arguments exn:fail) ([args arguments?]) #:transparent]{
 An exception type used by @mock-tech{mocks} that don't expect to be called at all.}
