#lang sweet-exp racket/base

require racket/contract/base

provide
  contract-out
    const/kw (-> any/c procedure?)
    void/kw (unconstrained-domain-> void?)

require racket/function
        "util.rkt"

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

(define (const-series #:repeat? [repeat? #f] . vs)
  (define vec (vector->immutable-vector (list->vector vs)))
  (define vec-len (vector-length vec))
  (define repeat?/len (and repeat? (not (zero? vec-len))))

  (define index-box (box 0))
  (define (cycle-index i) (if repeat?/len (modulo i vec-len) i))
  (define (index)
    (define i (cycle-index (unbox index-box)))
    (unless (< i (vector-length vec))
      (raise-arguments-error
       'const-series "called more times than number of arguments"
       'num-calls i))
    i)
  (define (index++!) (box-transform! index-box add1))

  (make-keyword-procedure
   (lambda (kws kw-args . rest)
     (begin0 (vector-ref vec (index)) (index++!)))))

(module+ test
  (define a-b-c-proc (const-series 'a 'b 'c))
  (check-equal? (a-b-c-proc 'arg) 'a)
  (check-equal? (a-b-c-proc #:foo 'arg) 'b)
  (check-equal? (a-b-c-proc 'arg #:foo 'arg) 'c)
  (check-exn exn:fail:contract? a-b-c-proc)
  (check-exn #rx"called more times than number of arguments" a-b-c-proc)
  (check-exn #rx"num-calls" a-b-c-proc)
  (define a-b-c-proc/repeat (const-series 'a 'b 'c #:repeat? #t))
  (void
   (a-b-c-proc/repeat)
   (a-b-c-proc/repeat)
   (a-b-c-proc/repeat))
  (check-equal? (a-b-c-proc/repeat) 'a))
