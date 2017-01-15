#lang racket/base

(provide box-transform!
         with-values-as-list
         box-cons-end!)

(require fancy-app
         racket/function)


(define (box-transform! a-box f)
  (set-box! a-box (f (unbox a-box))))

(define-syntax-rule (with-values-as-list body ...)
  (call-with-values (thunk body ...) list))

(define (box-cons-end! a-box v)
  (box-transform! a-box (append _ (list v))))
