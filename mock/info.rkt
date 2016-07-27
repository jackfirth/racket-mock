#lang info
(define collection "mock")
(define scribblings '(("main.scrbl" (multi-page) (library) "mock")))
(define version "1.0")
(define deps
  '(("base" #:version "6.4")
    "reprovide-lang"))
(define build-deps
  '("racket-doc"
    "scribble-lib"
    "sweet-exp"))
(define compile-omit-paths
  '("private"))
(define test-omit-paths
  '(#rx"\\.scrbl$"
    #rx"info\\.rkt$"
    #rx"util-doc\\.rkt$"))
