#lang info
(define collection "mock")
(define scribblings '(("rackunit.scrbl" () (library) "mock-rackunit")))
(define version "1.2")
(define deps
  '(("base" #:version "6.4")
    ("mock" #:version "2.0")
    "rackunit-lib"))
(define build-deps
  '("racket-doc"
    "rackunit-doc"
    "scribble-lib"
    "sweet-exp"))
(define test-omit-paths
  '(#rx"\\.scrbl$"
    #rx"info\\.rkt$"))
(define cover-omit-paths
  '("rackunit.rkt"))
