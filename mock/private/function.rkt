#lang sweet-exp racket/base

require racket/contract/base

provide
  contract-out
    const/kw (-> any/c procedure?)
    void/kw (unconstrained-domain-> void?)

require racket/function

module+ test
  require rackunit


(define (const/kw v)
  (make-keyword-procedure (const v)))

(module+ test
  (check-equal? ((const/kw 1)) 1)
  (check-equal? ((const/kw 1) 'arg) 1)
  (check-equal? ((const/kw 1) #:foo 'arg) 1)
  (check-equal? ((const/kw 1) 'arg #:foo 'arg) 1))

(define void/kw (const/kw (void)))

(module+ test
  (check-equal? (void/kw #:foo 'arg) (void)))

(define (const-raise v)
  (thunk* (raise v)))

(module+ test
  (struct foo ())
  (check-exn foo? (const-raise (foo)))
  (check-exn foo? (thunk ((const-raise (foo)) 'arg)))
  (check-exn foo? (thunk ((const-raise (foo)) #:foo 'arg))))

(define (const-raise-exn #:message [msg "failure"]
                         #:constructor [exn-constructor make-exn:fail])
  (thunk* (raise (exn-constructor msg (current-continuation-marks)))))

(module+ test
  (check-exn #rx"failure" (const-raise-exn))
  (check-exn exn:fail? (const-raise-exn))
  (check-exn #rx"custom message" (const-raise-exn #:message "custom message"))
  (struct custom-exn exn:fail () #:transparent)
  (check-exn custom-exn? (const-raise-exn #:constructor custom-exn)))
