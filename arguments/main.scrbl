#lang scribble/manual

@(require (for-label arguments
                     racket/base
                     racket/contract)
          scribble/example
          syntax/parse/define)

@(define (make-args-eval)
   (make-base-eval #:lang 'racket/base '(require arguments)))

@(define-simple-macro (args-examples example:expr ...)
   (examples #:eval (make-args-eval) example ...))

@(define (args-tech #:definition? [definition? #f] . pre-flow)
  (apply (if definition? deftech tech) #:key "arguments-struct" pre-flow))

@title{Arguments Structures}
@defmodule[arguments]

This library defines @args-tech[#:definition? #t]{arguments structures}, values
containing a set of positional and keyword argument values. Various utility
procedures for constructing and manipulating these structures are provided.

@defthing[#:kind "procedure" arguments (unconstrained-domain-> arguments?)]{
 Returns all arguments given, in the form of an @args-tech{arguments structure}.
 Accepts both positional and keyword arguments.
 @(args-examples
   (arguments 1 2 3 #:foo "bar"))}

@defproc[(make-arguments [positional list?] [keyword keyword-hash?])
         arguments?]{
 Returns an @args-tech{arguments structure} with @racket[positional] and
 @racket[keyword] as its arguments.
 @(args-examples
   (make-arguments '(1 2 3) (hash '#:foo "bar")))}

@deftogether[
 (@defthing[#:kind "value" arguments? predicate/c]
  @defproc[(arguments-positional [arguments arguments?]) list?]
  @defproc[(arguments-keyword [arguments arguments?]) keyword-hash?])]{
 Predicate and accessors for @args-tech{arguments structures}.}

@defproc[(apply/arguments [f procedure?] [args arguments?]) any]{
 Calls @racket[f] with @racket[args] and returns whatever values are returned by
 @racket[f].
 @(args-examples
   (apply/arguments sort
                    (arguments '("fooooo" "bar" "bazz") <
                               #:key string-length)))
 @history[#:added "1.1"]}

@defform[(lambda/arguments args-id body ...+)]{
 Constructs an anonymous function that accepts any number of arguments, collects
 them into an @args-tech{arguments structure}, and binds that structure to
 @racket[args-id] in the @racket[body] forms.
 @(args-examples
   (define pos-sum
     (lambda/arguments args
       (apply + (arguments-positional args))))
   (pos-sum 1 2 3)
   (pos-sum 1 2 3 #:foo 'bar))
 @history[#:added "1.2"]}

@defform[(define/arguments (id args-id) body ...+)]{
 Defines @racket[id] as a function that accepts any number of arguments,
 collects them into an @args-tech{arguments structure}, and binds that structure
 to @racket[args-id] in the @racket[body] forms.
 @(args-examples
   (define/arguments (keywords-product args)
     (for/product ([(k v) (in-hash (arguments-keyword args))])
       v))
   (keywords-product #:foo 2 #:bar 3)
   (keywords-product 'ignored #:baz 6 #:blah 4))
 @history[#:added "1.2"]}

@defthing[#:kind "value" empty-arguments arguments?]{
 The empty @args-tech{arguments structure}. Equivalent to @racket[(arguments)].}

@defthing[#:kind "value" keyword-hash? flat-contract?]{
 A flat contract that recognizes immutable hashes whose keys are keywords.
 Equivalent to @racket[(hash/c keyword? any/c #:flat? #t #:immutable #t)]. Used
 for the keyword arguments of an @args-tech{arguments structure}.
 @(args-examples
   (keyword-hash? (hash '#:foo "bar"))
   (keyword-hash? (make-hash '((#:foo . "bar"))))
   (keyword-hash? (hash 'foo "bar")))}
