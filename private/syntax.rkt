#lang sweet-exp racket/base

require racket/splicing
        syntax/parse/define
        "base.rkt"
        for-syntax racket/base
                   syntax/parse
                   "util-syntax.rkt"

provide define/mock

module+ mock-test-setup
  require rackunit
          "args.rkt"
          "check.rkt"

(begin-for-syntax
  (define-splicing-syntax-class submod-clause
    (pattern (~seq #:in-submod id:id)))
  (define-splicing-syntax-class mock-clause
    (pattern (~seq #:mock id:id
                   (~optional (~seq #:as given-submod-id:id))
                   (~optional (~seq #:with-behavior given-behavior:expr)))
             #:attr submod-id
             (or (attribute given-submod-id) #'id)
             #:attr mock-value
             (if (attribute given-behavior)
                 #'(mock #:name 'submod-id #:behavior given-behavior)
                 #'(mock #:name 'submod-id))
             #:attr explicit-form
             #'(id submod-id mock-value)))
  (define-syntax-class explicit-mock-clause
    (pattern (id:id submod-id:id mock-value:expr))))

(define-simple-macro
  (define/mock-explicit header:definition-header
    submod:submod-clause
    #:mocks (mock-clause:explicit-mock-clause ...)
    body ...+)
  (begin
    (define-syntax-parser inject
      [(inject id:id mock-clause.id ...)
       (with-syntax ([header (replace-header-id #'header #'id)])
         #'(define header body ...))])
    (inject header.id mock-clause.id ...)
    (module+ submod.id
      (define mock-clause.submod-id mock-clause.mock-value) ...
      (inject header.id mock-clause.submod-id ...))))

(define-syntax-parser define/mock
  [(_ header:definition-header
      (~optional submod:submod-clause)
      mock:mock-clause ...
      body ...+)
   (with-syntax ([submod-id (or (attribute submod.id)
                                (syntax/loc #'header test))])
     #'(define/mock-explicit header
         #:in-submod submod-id
         #:mocks (mock.explicit-form ...)
         body ...))])

(module+ mock-test-setup
  (define not-mock? (compose not mock?))
  
  (define/mock (bar v)
    #:in-submod mock-test
    #:mock foo #:as foo-mock #:with-behavior void
    (foo v)
    (foo v))
  
  (define (foo v)
    (displayln v))
  
  (check-pred not-mock? foo)
  
  (module+ mock-test
    (check-pred not-mock? foo)
    (check-pred mock? foo-mock)
    (bar 20)
    (check-mock-called-with? foo-mock (arguments 20))
    (check-mock-num-calls 2 foo-mock)))

(module+ test
  (require (submod ".." mock-test-setup mock-test)))
