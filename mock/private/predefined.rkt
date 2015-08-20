#lang racket/base

(require racket/contract
         racket/function
         racket/list
         racket/sequence
         unstable/sequence
         "base.rkt")

(module+ test
  (require rackunit))

(provide
 (contract-out
  [const-mock (-> any/c mock?)]
  [void-mock (-> mock?)]
  [case-mock (->* () #:rest list? mock?)]))


(define (const-mock v) (make-mock (const v)))
(define (void-mock) (make-mock void))

(define (unzip-list vs)
  (define groups (sequence->list (in-slice 2 vs)))
  (values
   (map first groups)
   (map second groups)))

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

(define (case-mock . cases)
  (define-values (case-vs case-results) (unzip-list cases))
  (define (case-proc v)
    (define result
      (for/first ([case-v case-vs]
                  [case-result case-results]
                  #:when (equal? case-v v))
        case-result))
    (unless result
      (define expected
        (apply format (or/c-format-string (length case-vs)) case-vs))
      (raise-argument-error 'v expected v))
    result)
  (make-mock case-proc))
