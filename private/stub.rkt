#lang sweet-exp racket/base

provide stub
        struct-out exn:fail:not-implemented

require syntax/parse/define
        for-syntax racket/base
                   "util-syntax.rkt"

(begin-for-syntax
  (define-syntax-class stub-header
    (pattern plain-id:id
             #:attr definition
             #'(define plain-id (not-implemented-proc 'plain-id)))
    (pattern header:definition-header
             #:attr definition
             #'(define header (raise-not-implemented 'header.id)))))

(define (not-implemented-proc proc-name)
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (raise-not-implemented proc-name))))

(define (raise-not-implemented proc-name)
  (define message (format "procedure ~a hasn't been implemented" proc-name))
  (raise (exn:fail:not-implemented message (current-continuation-marks))))

(define-simple-macro (stub header:stub-header ...)
  (begin header.definition ...))

(struct exn:fail:not-implemented exn:fail () #:transparent)
