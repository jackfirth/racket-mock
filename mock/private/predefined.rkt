#lang sweet-exp racket/base

require racket/contract
        racket/function
        racket/list
        racket/sequence
        unstable/sequence
        "base.rkt"

module+ test
  require rackunit

provide
  contract-out
    const-mock (-> any/c mock?)
    void-mock (-> mock?)
    case-mock (->* () #:rest list? mock?)


(define (const-mock v) (make-mock (const v)))
(define (void-mock) (make-mock void))

(module+ test
  (check-equal? ((const-mock 1) 'foo) 1)
  (check-equal? ((void-mock)) (void)))


(define (unzip-list vs)
  (define groups (sequence->list (in-slice 2 vs)))
  (values
   (map first groups)
   (map second groups)))

(module+ test
  (define-values (syms nums) (unzip-list '(a 1 b 2)))
  (check-equal? syms '(a b))
  (check-equal? nums '(1 2)))


(define (repeat n v)
  (build-list n (const v)))

(define (or/c-format-string num-contracts)
  (string-append
   (apply string-append
          "(or/c"
          (repeat num-contracts " ~v"))
   ")"))

(module+ test
  (check-equal? (repeat 3 'foo) '(foo foo foo))
  (check-equal? (or/c-format-string 3) "(or/c ~v ~v ~v)"))


(define (raise-unexpected-case-error argument expected-cases actual)
  (define format-string (or/c-format-string (length expected-cases)))
  (define expected (apply format format-string expected-cases))
  (raise-argument-error argument expected actual))


(define (case-mock . cases)
  (define-values (case-vs case-results) (unzip-list cases))
  (define (case-proc v)
    (let loop ([case-vs case-vs] [case-results case-results])
      (cond [(empty? case-vs)
             (raise-unexpected-case-error 'v case-vs v)]
            [(equal? (first case-vs) v)
             (first case-results)]
            [else (loop (rest case-vs) (rest case-results))])))
  (make-mock case-proc))

(module+ test
  (define a-case-mock (case-mock 'a 1 'b 2))
  (check-equal? (a-case-mock 'a) 1)
  (check-equal? (a-case-mock 'b) 2)
  (check-exn exn:fail:contract? (thunk (a-case-mock 'c))))
