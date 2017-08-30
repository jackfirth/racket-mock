#lang info
(define collection "arguments")
(define scribblings '(("main.scrbl" () ("Data Structures") "arguments")))
(define version "1.2")
(define deps
  '("base"))
(define build-deps
  '("racket-doc"
    "rackunit-lib"
    "scribble-lib"))
