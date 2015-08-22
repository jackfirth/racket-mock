#lang sweet-exp racket

require rackunit
        mock


(define/mock (displayln-twice v)
  ([displayln (void-mock)])
  (displayln v)
  (displayln v))

(check-false (mock? displayln))

(module+ test
  (check-true (mock? displayln)))
