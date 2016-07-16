#lang sweet-exp racket/base

provide define-opaque

require syntax/parse/define
        for-syntax racket/base
                   racket/syntax

(begin-for-syntax
  (define (predicate-id id-stx)
    (format-id id-stx "~a?" id-stx)))

(define-syntax-parser define-single-opaque
  [(_ id:id)
   (with-syntax ([id? (predicate-id #'id)])
     #'(begin
         (struct internal ()
           #:reflection-name 'id
           #:omit-define-syntaxes
           #:constructor-name make-instance)
         (define id (make-instance))
         (define (id? v) (internal? v))))])

(define-simple-macro (define-opaque id:id ...)
  (begin (define-single-opaque id) ...))
