#lang racket/base

(provide histories)

(require (for-syntax racket/base)
         racket/stxparam)


(define-syntax-parameter histories #f)
