#lang sweet-exp racket/base

provide predicate-id

require racket/syntax

(define (predicate-id id-stx)
  (format-id id-stx "~a?" id-stx))
