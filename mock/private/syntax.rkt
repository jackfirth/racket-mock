#lang sweet-exp racket/base

require racket/splicing
         for-syntax racket/base
                    syntax/parse

module+ test
  require rackunit
          "base.rkt"
          "predefined.rkt"

provide define/mock
        define/mock-as


(define-syntax-rule (define-id/mock-value-as id ([mock-id mock-value-id mock-value] ...) expr)
  (begin
    (define (make-with-mocks mock-id ...) expr)
    (define id (make-with-mocks mock-id ...))
    (module+ test
      (define mock-value-id mock-value) ...
      (define id (make-with-mocks mock-value ...)))))

(define-syntax-rule (define-id/mock-value id ([mock-id mock-value] ...) expr)
  (define-id/mock-value-as id ([mock-id mock-id mock-value] ...) expr))

(define-syntax-rule (define-id/mock id ([mock-id mock-expr] ...) expr)
  (splicing-let ([mock-value mock-expr] ...)
    (define-id/mock-value id ([mock-id mock-value] ...) expr)))

(define-syntax-rule (define-id/mock-as id ([mock-id mock-value-id mock-expr] ...) expr)
  (splicing-let ([mock-value mock-expr] ...)
    (define-id/mock-value-as id ([mock-id mock-value-id mock-value] ...) expr)))

(define-syntax define/mock
  (syntax-parser
    [(_ id:id mocks body ...)
     #'(define-id/mock id mocks (let () body ...))]
    [(_ (id:id arg ...) mocks body ...)
     #'(define-id/mock id mocks (lambda (arg ...) body ...))]
    [(_ (header arg ...) mocks body ...)
     #'(define/mock header mocks (lambda (arg ...) body ...))]))

(define-syntax define/mock-as
  (syntax-parser
    [(_ id:id mocks body ...)
     #'(define-id/mock-as id mocks (let () body ...))]
    [(_ (id:id arg ...) mocks body ...)
     #'(define-id/mock-as id mocks (lambda (arg ...) body ...))]
    [(_ (header arg ...) mocks body ...)
     #'(define/mock-as header mocks (lambda (arg ...) body ...))]))
