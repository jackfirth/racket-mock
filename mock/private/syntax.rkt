#lang sweet-exp racket/base

provide define/mock
        with-mocks

require racket/splicing
        racket/stxparam
        syntax/parse/define
        "base.rkt"
        "opaque.rkt"
        for-syntax racket/base
                   racket/match
                   racket/syntax
                   syntax/parse
                   "syntax-class.rkt"

module+ mock-test-setup
  require rackunit
          "args.rkt"

(define-simple-macro (define-static id base-id static-expr)
  (define-syntax id (static-val-transformer #'base-id static-expr)))

(define-simple-macro
  (define/mock header:definition-header
    opaque:opaque-clause
    mocks:mocks-clause
    body:expr ...+)
  (begin
    (define header.fresh body ...)
    opaque.definitions
    (splicing-let opaque.bindings
      mocks.definitions)
    (splicing-let mocks.bindings
      (define header.fresh-secondary body ...))
    (define-static header.id header.fresh-id
      (mocks-syntax-info #'header.fresh-id-secondary opaque.static-info mocks.static-info))))

(define-simple-macro (with-mocks/impl proc:id/mock body:expr ...)
  (let (proc.binding ...) body ... proc.reset-expr))

(define-for-syntax (with-mocks/nested stx)
  (raise-syntax-error #f "nested use of with-mocks not allowed" stx))

(define-syntax-parameter with-mocks
  (syntax-parser
    [(_ proc:id/mock body:expr ...)
     #'(syntax-parameterize ([with-mocks with-mocks/nested])
         (with-mocks/impl proc body ...))]))
