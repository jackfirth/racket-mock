#lang racket/base

(provide (struct-out exn:fail:not-implemented)
         not-implemented-proc
         raise-not-implemented)

(struct exn:fail:not-implemented exn:fail () #:transparent)

(define (not-implemented-proc proc-name)
  (make-keyword-procedure
   (λ (kws kw-vs . vs)
     (raise-not-implemented proc-name))))

(define (raise-not-implemented proc-name)
  (define message (format "procedure ~a hasn't been implemented" proc-name))
  (raise (exn:fail:not-implemented message (current-continuation-marks))))
