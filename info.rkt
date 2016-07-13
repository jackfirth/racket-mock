#lang info
(define collection "mock")
(define scribblings '(("main.scrbl" () (library) "mock")))
(define version "0.8")
(define deps
  '(("base" #:version "6.4")
    "fancy-app"
    "rackunit-lib"
    "reprovide-lang"
    "scribble-lib"
    "sweet-exp"
    "unstable-lib"))
(define build-deps
  '("rackunit-lib"
    "rackunit-doc"
    "racket-doc"))
(define test-omit-paths
  '(#rx"\\.scrbl$"
    #rx"info\\.rkt$"
    #rx"util-doc\\.rkt$"))
