#lang sweet-exp racket/base

require racket/splicing
        syntax/parse/define
        "base.rkt"
        for-syntax racket/base
                   syntax/parse

provide define/mock

module+ mock-test-setup
  require rackunit
  module+ mock-test
    require rackunit

(begin-for-syntax
  (define-syntax-class definition-header
    (pattern (~or root-id:id
                  (~or (subheader:definition-header (~or arg-clause kwarg-clause) ...)
                       (subheader:definition-header (~or arg-clause kwarg-clause) ... . rest-arg:id)))
             #:attr id
             (or (attribute root-id) (attribute subheader.id))))
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
                 #'(mock #:name (symbol->string 'submod-id) #:behavior given-behavior)
                 #'(mock #:name (symbol->string 'submod-id)))
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
    (define (mock-constructor mock-clause.id ...)
      (define header body ...)
      header.id)
    (define header.id (mock-constructor mock-clause.id ...))
    (module+ submod.id
      (define mock-clause.submod-id mock-clause.mock-value) ...
      (define header.id (mock-constructor mock-clause.submod-id ...)))))

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
  
  (define/mock (displayln-test v)
    #:in-submod mock-test
    #:mock displayln #:as displayln-mock
    (displayln v)
    (displayln v))
  
  (check-pred not-mock? displayln)
  
  (module+ mock-test
    (check-pred not-mock? displayln)
    (check-pred mock? displayln-mock)))

(module+ test
  (require (submod ".." mock-test-setup mock-test)))
