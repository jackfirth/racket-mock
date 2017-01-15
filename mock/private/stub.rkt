#lang sweet-exp racket/base

provide stub
        struct-out exn:fail:not-implemented

require racket/function
        syntax/parse/define
        "not-implemented.rkt"
        for-syntax racket/base
                   "syntax-class.rkt"
                   

module+ test
  require rackunit

(define-simple-macro (stub h:stub-header ...) (begin h.definition ...))

(module+ test
  (stub foo (bar v) ((baz k) #:blah v))
  (check-exn exn:fail:not-implemented? (thunk (foo 1 2 #:a 'b)))
  (check-exn exn:fail:not-implemented? (thunk (bar 1)))
  (check-exn exn:fail:contract:arity? (thunk (bar 1 2)))
  (check-not-exn (thunk (baz 1)))
  (check-exn exn:fail:not-implemented? (thunk ((baz 1) #:blah "blahhhh"))))
