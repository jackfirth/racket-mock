#lang sweet-exp racket/base

provide define-opaque

require syntax/parse/define
        for-syntax racket/base
                   racket/syntax
                   "syntax-util.rkt"

module+ test
  require rackunit


(define-syntax-parser define-single-opaque
  [(_ id:id (~optional (~seq #:name name-id:id)))
   (with-syntax ([id? (predicate-id #'id)]
                 [reflect-id (or (attribute name-id) #'id)])
     #'(begin
         (struct internal ()
           #:reflection-name 'reflect-id
           #:omit-define-syntaxes
           #:constructor-name make-instance)
         (define id (make-instance))
         (define id? internal?)))])

(define-simple-macro
  (define-opaque (~and (~seq id:id (~optional (~seq #:name name-id)))
                       (~seq part ...)) ...)
  (begin (define-single-opaque part ...) ...))

(module+ test
  (test-case "Single opaque definition"
    (define-single-opaque foo)
    (check-pred foo? foo)
    (check-equal? foo foo)
    (check-equal? (object-name foo) 'foo)
    (check-equal? (object-name foo?) 'foo?))
  (test-case "Single opaque definition renamed"
    (define-single-opaque barrr #:name bar)
    (check-pred barrr? barrr)
    (check-equal? (object-name barrr) 'bar)
    (check-equal? (object-name barrr?) 'bar?))
  (test-case "Multiple opaque definitions with intermixed renames"
    (define-opaque foo bar #:name Bar baz)
    (check-pred foo? foo)
    (check-pred bar? bar)
    (check-pred baz? baz)
    (check-equal? (object-name bar) 'Bar)))
