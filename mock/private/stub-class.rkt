#lang racket/base

(provide stubs)

(require (for-template racket/base
                       "not-implemented.rkt")
         syntax/parse
         "syntax-util.rkt")


(define-syntax-class stub-header
  (pattern plain-id:id
           #:attr definition
           #'(define plain-id (not-implemented-proc 'plain-id)))
  (pattern header:definition-header
           #:attr definition
           #'(define header (raise-not-implemented 'header.id))))

(define-splicing-syntax-class stubs
  (pattern (~seq stubbed:stub-header ...+)
           #:attr definitions #'(begin stubbed.definition ...)))
