#lang racket/base

(module+ test
  (require doc-coverage
           mock)

  (check-all-documented 'mock))
