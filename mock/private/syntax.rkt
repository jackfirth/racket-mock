#lang racket/base

(provide define-id/mock
         define-id/mock-as)


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

