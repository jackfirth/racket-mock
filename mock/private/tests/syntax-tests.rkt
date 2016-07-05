#lang sweet-exp racket

require rackunit
        mock


(define not-mock? (compose not mock?))

(define/mock (displayln-test v)
  #:in-submod mock-test
  #:mock displayln #:as displayln-mock
  (displayln v)
  (displayln v))

(check-pred not-mock? displayln)
(module+ mock-test
  (check-pred not-mock? displayln)
  (check-pred mock? displayln-mock))
(module+ test
  (require (submod ".." mock-test)))
