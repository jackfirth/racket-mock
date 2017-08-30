#lang racket/base

(require arguments
         rackunit)

(define/arguments (get-positional args)
  (arguments-positional args))

(check-equal? (get-positional 1 2 3) '(1 2 3))
(check-equal? (get-positional) '())
(check-equal? (get-positional 1 2 3 #:foo 'bar) (get-positional 1 2 3))
