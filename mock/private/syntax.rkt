#lang sweet-exp racket/base

provide define/mock
        with-mocks

require racket/splicing
        racket/stxparam
        syntax/parse/define
        "base.rkt"
        "opaque.rkt"
        for-syntax racket/base
                   syntax/parse
                   "syntax-class.rkt"

module+ mock-test-setup
  require rackunit
          "args.rkt"

(define-simple-macro
  (define/mock header:definition-header/mock body:expr ...+)
  (begin
    (define header.header/plain body ...)
    header.definitions
    (splicing-let header.override-bindings (define header.header/mock body ...))
    header.static-definition))

(define-simple-macro (with-mocks/impl proc:id/mock body:expr ...)
  (let (proc.binding ...) body ... proc.reset-expr))

(define-for-syntax (with-mocks/nested stx)
  (raise-syntax-error #f "nested use of with-mocks not allowed" stx))

(define-syntax-parameter with-mocks
  (syntax-parser
    [(_ proc:id/mock body:expr ...)
     #'(syntax-parameterize ([with-mocks with-mocks/nested])
         (with-mocks/impl proc body ...))]))
