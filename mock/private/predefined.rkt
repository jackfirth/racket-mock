#lang racket/base

(require racket/contract
         racket/function
         racket/list
         racket/sequence
         unstable/sequence
         "base.rkt")

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

(define (case-mock . cases)
  (define-values (case-vs case-results) (unzip-list cases))
  (lambda (v)
    (for/first ([case-v case-vs]
                [case-result case-results]
                #:when (equal? case-v v))
      case-result)))

