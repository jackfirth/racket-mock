#lang sweet-exp racket/base

provide define/mock
        with-mocks

require racket/splicing
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

(begin-for-syntax
  (struct static-val-transformer (id value)
    #:property prop:rename-transformer (struct-field-index id))
  (define (static-val static-trans-stx)
    (define-values (trans _)
      (syntax-local-value/immediate static-trans-stx))
    (static-val-transformer-value trans)))

(define-simple-macro (define-static id base-id static-expr)
  (define-syntax id (static-val-transformer #'base-id static-expr)))

(define (mock-reset-all! . mocks)
  (for-each mock-reset! mocks))

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

(begin-for-syntax
  (define (mock-bindings mock-static-infos)
    (map (match-lambda [(mock-static-info mock-id mock-impl-id)
                        (list (syntax-local-introduce mock-id) mock-impl-id)])
         mock-static-infos)))

(define-syntax-parser with-mocks
  [(_ proc:id body:expr ...)
   (match-define (mocks-syntax-info proc-id opaques mocks) (static-val #'proc))
   (with-syntax* ([(opaque-binding ...) (mock-bindings opaques)]
                  [(mock-binding ...) (mock-bindings mocks)]
                  [([mock-id mock-impl-id] ...) #'(mock-binding ...)])
     #`(let ([proc #,proc-id] opaque-binding ... mock-binding ...)
         body ...
         (mock-reset-all! mock-id ...)))])
