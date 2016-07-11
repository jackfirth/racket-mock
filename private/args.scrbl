#lang scribble/manual
@(require "util-doc.rkt")

@title{Arguments structure}
Mocks record procedure calls partly via an @racket[arguments] structure.
Various utility procedures for constructing and manipulating these structures
are provided by @racketmodname[mock].

@deftogether[
 (@defthing[#:kind "value" arguments? predicate/c]
  @defproc[(arguments-positional [arguments arguments?]) list?]
  @defproc[(arguments-keyword [arguments arguments?]) keyword-hash?])]{
 Predicate and accessors for values returned by @racket[make-arguments] and
 @racket[arguments].
}

@defproc[(make-arguments [positional list?] [keyword keyword-hash?]) arguments?]{
 Returns a value representing the arguments of a procedure call where @racket[positional]
 ontains the given positional arguments, and @racket[keyword] contains the given keyword
 arguments.
 @mock-examples[
 (make-arguments '(1 2 3) (hash '#:foo "bar"))]}

@defthing[#:kind "procedure" arguments (unconstrained-domain-> arguments?)]{
 A procedure that collects all arguments it's called with into an @racket[arguments]
 structure. Accepts both positional and keyword arguments.
 @mock-examples[
 (arguments 1 2 3 #:foo "bar")]}

@defthing[#:kind "value" keyword-hash? flat-contract?]{
 A flat contract that recognizes immutable hashes whose keys are keywords. Equivalent
 to @racket[(hash/c keyword? any/c #:flat? #t #:immutable #t)].
 @mock-examples[
 (keyword-hash? (hash '#:foo "bar"))
 (keyword-hash? (make-hash '((#:foo . "bar"))))
 (keyword-hash? (hash 'foo "bar"))]}

@defproc[(make-raise-unexpected-arguments-exn [source-name string?]) procedure?]{
 Returns a procedure that accepts any number of positional or keyword arguments
 and always @racket[raise]s @racket[exn:fail:unexpected-call] with @racket[name] as
 the name used to report the error. This is the default behavior for mocks, see
 @racket[make-mock]. The exception message details each positional and keyword
 argument given.
 @mock-examples[
 (define uncallable (make-raise-unexpected-arguments-exn "example"))
 (eval:error (uncallable 5 #:foo 'bar))]}

@defstruct*[(exn:fail:unexpected-arguments exn:fail)
            ([args list?] [kwargs (hash/c keyword? any/c)])
            #:transparent]{
 An exception type used by mocks that don't expect to be called at all.}
