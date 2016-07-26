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
          "check.rkt"

(begin-for-syntax
  (struct static-val-transformer (id value)
    #:property prop:rename-transformer (struct-field-index id))
  (define (static-val static-trans-stx)
    (define-values (trans _)
      (syntax-local-value/immediate static-trans-stx))
    (static-val-transformer-value trans))
  (struct mocks-syntax-info (proc-id mocks) #:transparent))

(define-simple-macro (define-static id base-id static-expr)
  (define-syntax id (static-val-transformer #'base-id static-expr)))

(define (mock-reset-all! . mocks)
  (for-each mock-reset! mocks))

(define-simple-macro
  (define/mock header:definition-header
    mocks:mocks-clause
    body:expr ...+)
  (begin
    (define header.fresh body ...)
    mocks.definitions
    (splicing-let mocks.bindings
      (define header.fresh-secondary body ...))
    (define-static header.id header.fresh-id
      (mocks-syntax-info #'header.fresh-id-secondary mocks.static-info))))

(define-syntax-parser with-mocks
  [(_ proc:id body:expr ...)
   (match-define (mocks-syntax-info proc/mocks-id mocks) (static-val #'proc))
   (define mock-bindings
     (map (match-lambda [(mock-static-info mock-id mock-impl-id)
                         (list (syntax-local-introduce mock-id) mock-impl-id)])
          mocks))
   (with-syntax* ([(binding ...) mock-bindings]
                  [([mock-id mock-impl-id] ...) #'(binding ...)])
     #`(let ([proc #,proc/mocks-id] binding ...)
         body ...
         (mock-reset-all! mock-id ...)))])
